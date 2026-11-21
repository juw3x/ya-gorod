import asyncio
import json
import os
import re
import uuid
from contextlib import asynccontextmanager
from datetime import datetime
from typing import Any, List, Optional

from fastapi import Depends, FastAPI, File, Form, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
from sqlalchemy import JSON, Boolean, Column, DateTime, Integer, String, Text, create_engine, text
from sqlalchemy.orm import Session, declarative_base, sessionmaker

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://yagorod:yagorod@db:5432/yagorod")
MEDIA_DIR = "/app/media"
PRIVATE_PROPOSALS_DIR = "/app/private_proposals"
os.makedirs(MEDIA_DIR, exist_ok=True)
os.makedirs(PRIVATE_PROPOSALS_DIR, exist_ok=True)

ALLOWED_CATEGORIES = {
    "Концерт", "Спектакль", "Кинопоказ", "Выставка", "Экскурсия",
    "Мастер-класс", "Обучение", "Фестиваль", "Ярмарка", "Спорт", "Другое",
}
ALLOWED_AGE_RATINGS = {"0+", "6+", "12+", "16+", "18+"}
ALLOWED_EXTS = {
    ".pdf", ".docx", ".doc", ".xlsx", ".xls",
    ".jpeg", ".jpg", ".png", ".zip", ".rar", ".7z",
}
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10 MB
MAX_FILES_COUNT = 10
TIME_RE = re.compile(r"^([01]\d|2[0-3]):([0-5]\d)$")
URL_RE = re.compile(r"^https?://\S+$", re.IGNORECASE)

engine = create_engine(DATABASE_URL, pool_pre_ping=True)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


class StoryDB(Base):
    __tablename__ = "stories"
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    title = Column(String, nullable=False)
    preview_url = Column(String, nullable=True)
    media_url = Column(String, nullable=True)
    is_video = Column(Boolean, default=False)
    description = Column(Text, nullable=True)


class BannerDB(Base):
    __tablename__ = "banners"
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    title = Column(String, nullable=False)
    subtitle = Column(String, nullable=False)
    image_url = Column(String, nullable=True)
    target_url = Column(String, nullable=True)


class EventDB(Base):
    __tablename__ = "events"
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    title = Column(String, nullable=False)
    category = Column(String, nullable=False)
    age_rating = Column(String, default="0+")
    venue_name = Column(String, nullable=False)
    venue_address = Column(String, nullable=False)
    map_url = Column(String, nullable=True)
    ticket_url = Column(String, nullable=True)
    description = Column(Text, nullable=False)
    cover_url = Column(String, nullable=True)
    video_url = Column(String, nullable=True)
    gallery_urls = Column(JSON, default=list)
    is_free = Column(Boolean, default=False)
    min_price = Column(Integer, nullable=True)
    schedule_type = Column(String, default="single")
    sessions = Column(JSON, default=list)
    period_start = Column(String, nullable=True)
    period_end = Column(String, nullable=True)
    source_url = Column(String, nullable=True, unique=True)
    created_at = Column(DateTime, default=datetime.utcnow)


class NewsDB(Base):
    __tablename__ = "news"
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    title = Column(String, nullable=False)
    content = Column(Text, nullable=True)
    category = Column(String, default="city")
    published_at_label = Column(String, nullable=False)
    external_url = Column(String, nullable=False)
    cover_url = Column(String, nullable=True)
    video_url = Column(String, nullable=True)


class ProposalDB(Base):
    __tablename__ = "proposals"
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    payload = Column(JSON, nullable=False)
    file_urls = Column(JSON, default=list)
    created_at = Column(DateTime, default=datetime.utcnow)


class EventCreate(BaseModel):
    title: str
    category: str
    age_rating: str = "0+"
    venue_name: str
    venue_address: str
    map_url: Optional[str] = None
    ticket_url: Optional[str] = None
    description: str
    cover_url: Optional[str] = None
    video_url: Optional[str] = None
    gallery_urls: List[str] = []
    is_free: bool = False
    min_price: Optional[int] = None
    schedule_type: str = "single"
    sessions: List[dict[str, Any]] = []
    period_start: Optional[str] = None
    period_end: Optional[str] = None


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def _validate_proposal_payload(data: dict) -> dict[str, str]:
    errors: dict[str, str] = {}

    def get_str(*keys: str) -> str:
        for k in keys:
            if k in data and data[k] is not None:
                return str(data[k]).strip()
        return ""

    if not get_str("title"):
        errors["title"] = "Укажите название мероприятия"
    if not get_str("organizer"):
        errors["organizer"] = "Укажите организатора"
    if not get_str("description"):
        errors["description"] = "Заполните описание"
    if not get_str("address", "venue_address", "venueAddress"):
        errors["address"] = "Укажите адрес проведения"
    if not get_str("contact_name", "contactName", "fio"):
        errors["contact_name"] = "Укажите ФИО контактного лица"
    if not get_str("phone", "contact_phone", "contactPhone"):
        errors["phone"] = "Укажите номер телефона"

    cat = get_str("category")
    if cat not in ALLOWED_CATEGORIES:
        errors["category"] = "Выберите категорию из списка"

    age = get_str("age_rating", "ageRating")
    if age not in ALLOWED_AGE_RATINGS:
        errors["age_rating"] = "Выберите возрастное ограничение"

    for field, keys in (
        ("venue_url", ("venue_url", "venueUrl", "map_url", "mapUrl")),
        ("ticket_url", ("ticket_url", "ticketUrl")),
    ):
        val = get_str(*keys)
        if val and not URL_RE.match(val):
            errors[field] = "Ссылка должна начинаться с http:// или https://"

    is_free = bool(data.get("is_free", data.get("isFree", False)))
    if not is_free:
        raw_price = data.get("price", data.get("min_price", data.get("minPrice")))
        try:
            price_val = int(raw_price)
            if price_val <= 0:
                errors["price"] = "Стоимость должна быть больше 0"
        except (TypeError, ValueError):
            errors["price"] = "Укажите корректную стоимость в рублях"

    stype = get_str("schedule_type", "scheduleType") or "single"
    if stype not in ("single", "multiple", "period"):
        errors["schedule_type"] = "Некорректный тип расписания"
    elif stype == "period":
        p_start = get_str("period_start", "periodStart")
        p_end = get_str("period_end", "periodEnd")
        try:
            d1 = datetime.strptime(p_start, "%Y-%m-%d").date()
            d2 = datetime.strptime(p_end, "%Y-%m-%d").date()
            if d2 < d1:
                errors["period"] = "Дата окончания не может быть раньше даты начала"
        except ValueError:
            errors["period"] = "Укажите корректные даты начала и окончания (ГГГГ-ММ-ДД)"
    else:
        sessions = data.get("sessions") or []
        if not isinstance(sessions, list) or len(sessions) == 0:
            errors["sessions"] = "Добавьте хотя бы одну дату"
        else:
            for idx, s in enumerate(sessions):
                if not isinstance(s, dict):
                    errors[f"sessions.{idx}"] = "Некорректный формат сеанса"
                    continue
                d_str = str(s.get("date") or "").strip()
                try:
                    datetime.strptime(d_str, "%Y-%m-%d")
                except ValueError:
                    errors[f"sessions.{idx}.date"] = "Укажите корректную дату"
                st = str(s.get("startTime") or s.get("start_time") or "").strip()
                et = str(s.get("endTime") or s.get("end_time") or "").strip()
                if st and not TIME_RE.match(st):
                    errors[f"sessions.{idx}.startTime"] = "Формат времени: ЧЧ:ММ"
                if et:
                    if not TIME_RE.match(et):
                        errors[f"sessions.{idx}.endTime"] = "Формат времени: ЧЧ:ММ"
                    elif not st:
                        errors[f"sessions.{idx}.startTime"] = "При указании времени окончания нужно время начала"
                    elif et <= st:
                        errors[f"sessions.{idx}.endTime"] = "Время окончания должно быть позже начала"

    return errors


from parser import run_parse_cycle


async def _parser_background_loop():
    interval = int(os.getenv("PARSE_INTERVAL_SECONDS", "300"))
    while True:
        db = SessionLocal()
        try:
            await run_parse_cycle(db, EventDB, NewsDB)
        except Exception as exc:
            print("Parser error:", exc)
        finally:
            db.close()
        await asyncio.sleep(interval)


@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(bind=engine)
    with engine.begin() as conn:
        conn.execute(text("ALTER TABLE events ADD COLUMN IF NOT EXISTS source_url VARCHAR"))
        conn.execute(text("ALTER TABLE news ADD COLUMN IF NOT EXISTS content TEXT"))
        conn.execute(text("ALTER TABLE news ADD COLUMN IF NOT EXISTS video_url VARCHAR"))
        conn.execute(text("ALTER TABLE stories ADD COLUMN IF NOT EXISTS description TEXT"))
        conn.execute(text("DELETE FROM stories WHERE preview_url LIKE '%picsum.photos%'"))
        conn.execute(text("DELETE FROM banners WHERE image_url LIKE '%picsum.photos%'"))
        conn.execute(text("DELETE FROM events WHERE source_url IS NULL AND cover_url LIKE '%picsum.photos%'"))
        conn.execute(text("DELETE FROM news WHERE external_url LIKE '%example.com%'"))
    task = asyncio.create_task(_parser_background_loop())
    yield
    task.cancel()


app = FastAPI(title="Ya-Gorod API", version="1.0.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount("/media", StaticFiles(directory=MEDIA_DIR), name="media")


@app.get("/api/health")
def health():
    return {"status": "ok"}


@app.get("/api/home")
def get_home(db: Session = Depends(get_db)):
    events = db.query(EventDB).order_by(EventDB.created_at.desc()).all()
    stories = db.query(StoryDB).all()
    banners = db.query(BannerDB).all()

    if not stories:
        news_media = db.query(NewsDB).filter(NewsDB.cover_url.isnot(None)).limit(6).all()
        stories = [
            {
                "id": n.id,
                "title": n.title[:28] + ("…" if len(n.title) > 28 else ""),
                "preview_url": n.cover_url,
                "media_url": n.video_url or n.cover_url,
                "is_video": bool(n.video_url),
                "description": n.content or n.title,
            }
            for n in news_media
        ]

    if not banners:
        src = [e for e in events if e.cover_url][:3]
        if not src:
            src = db.query(NewsDB).filter(NewsDB.cover_url.isnot(None)).limit(3).all()
        banners = [
            {
                "id": item.id,
                "title": item.title[:50],
                "subtitle": getattr(item, "venue_name", None) or getattr(item, "published_at_label", "Ноябрьск"),
                "image_url": item.cover_url,
                "target_url": getattr(item, "ticket_url", None) or getattr(item, "external_url", None),
            }
            for item in src
        ]

    return {
        "stories": stories,
        "banners": banners,
        "events": events,
    }


@app.get("/api/events")
def list_events(offset: int = 0, limit: int = 20, db: Session = Depends(get_db)):
    items = db.query(EventDB).order_by(EventDB.created_at.desc()).offset(offset).limit(limit).all()
    total = db.query(EventDB).count()
    return {"total": total, "items": items}


@app.post("/api/events")
def create_event(event: EventCreate, db: Session = Depends(get_db)):
    obj = EventDB(**event.model_dump())
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj


@app.get("/api/news")
def list_news(category: str = "all", offset: int = 0, limit: int = 20, db: Session = Depends(get_db)):
    q = db.query(NewsDB)
    if category in ("official", "city"):
        q = q.filter(NewsDB.category == category)
    total = q.count()
    items = q.offset(offset).limit(limit).all()
    return {"total": total, "items": items}


@app.post("/api/upload")
async def upload_media(file: UploadFile = File(...)):
    ext = os.path.splitext(file.filename or "")[1].lower()
    if ext not in ALLOWED_EXTS:
        raise HTTPException(status_code=400, detail=f"Неподдерживаемый формат файла: {ext}")
    content = await file.read()
    if len(content) > MAX_FILE_SIZE:
        raise HTTPException(status_code=400, detail="Размер файла превышает 10 МБ")
    filename = f"{uuid.uuid4().hex}{ext}"
    with open(os.path.join(MEDIA_DIR, filename), "wb") as f:
        f.write(content)
    return {"url": f"/media/{filename}", "filename": filename, "size": len(content)}


@app.post("/api/proposals")
async def create_proposal(
    payload: str = Form(...),
    files: List[UploadFile] = File(default=[]),
    db: Session = Depends(get_db),
):
    try:
        data = json.loads(payload)
    except json.JSONDecodeError:
        raise HTTPException(status_code=400, detail="Некорректный JSON в заявке")

    if not isinstance(data, dict):
        raise HTTPException(status_code=400, detail="Некорректный формат заявки")

    errors = _validate_proposal_payload(data)
    if len(files) > MAX_FILES_COUNT:
        errors["files"] = f"Максимум {MAX_FILES_COUNT} вложений"

    validated_files = []
    for file in files:
        ext = os.path.splitext(file.filename or "")[1].lower()
        if ext not in ALLOWED_EXTS:
            errors["files"] = f"Неподдерживаемый формат файла: {file.filename}"
            break
        content = await file.read()
        if len(content) > MAX_FILE_SIZE:
            errors["files"] = f"Файл {file.filename} превышает 10 МБ"
            break
        validated_files.append((ext, content))

    if errors:
        raise HTTPException(status_code=422, detail={"message": "Ошибка валидации заявки", "errors": errors})

    saved_paths = []
    for ext, content in validated_files:
        filename = f"{uuid.uuid4().hex}{ext}"
        with open(os.path.join(PRIVATE_PROPOSALS_DIR, filename), "wb") as f:
            f.write(content)
        saved_paths.append(f"private_proposals/{filename}")

    proposal = ProposalDB(payload=data, file_urls=saved_paths)
    db.add(proposal)
    db.commit()
    db.refresh(proposal)
    return {"id": proposal.id, "files": saved_paths}


@app.post("/api/parser/run")
async def trigger_parser(db: Session = Depends(get_db)):
    result = await run_parse_cycle(db, EventDB, NewsDB)
    return {"status": "ok", **result}


@app.post("/api/parser/reset")
async def reset_and_reparse(db: Session = Depends(get_db)):
    db.query(EventDB).filter(EventDB.source_url.isnot(None)).delete()
    db.query(NewsDB).delete()
    db.commit()
    result = await run_parse_cycle(db, EventDB, NewsDB)
    return {"status": "ok", **result}

from admin import create_admin_router
app.include_router(
    create_admin_router(
        get_db=get_db,
        StoryDB=StoryDB,
        BannerDB=BannerDB,
        EventDB=EventDB,
        NewsDB=NewsDB,
        ProposalDB=ProposalDB,
        private_dir=PRIVATE_PROPOSALS_DIR,
        run_parse_cycle=run_parse_cycle,
    )
)
