import asyncio
import os
import uuid
from contextlib import asynccontextmanager
from datetime import datetime
from typing import Any, List, Optional

from fastapi import Depends, FastAPI, File, Form, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
from sqlalchemy import JSON, text, Boolean, Column, DateTime, Integer, String, Text, create_engine
from sqlalchemy.orm import Session, declarative_base, sessionmaker

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://yagorod:yagorod@db:5432/yagorod")
MEDIA_DIR = "/app/media"
os.makedirs(MEDIA_DIR, exist_ok=True)

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
        # Удаляем старые заглушки (picsum / example.com)
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
    return {
        "stories": db.query(StoryDB).all(),
        "banners": db.query(BannerDB).all(),
        "events": db.query(EventDB).order_by(EventDB.created_at.desc()).all(),
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
    ext = os.path.splitext(file.filename or "")[1]
    filename = f"{uuid.uuid4().hex}{ext}"
    path = os.path.join(MEDIA_DIR, filename)
    content = await file.read()
    with open(path, "wb") as f:
        f.write(content)
    return {"url": f"/media/{filename}", "filename": filename, "size": len(content)}


@app.post("/api/proposals")
async def create_proposal(
    payload: str = Form(...),
    files: List[UploadFile] = File(default=[]),
    db: Session = Depends(get_db),
):
    import json
    try:
        data = json.loads(payload)
    except json.JSONDecodeError:
        raise HTTPException(status_code=400, detail="Invalid JSON in payload")

    saved_urls = []
    for file in files:
        ext = os.path.splitext(file.filename or "")[1]
        filename = f"{uuid.uuid4().hex}{ext}"
        with open(os.path.join(MEDIA_DIR, filename), "wb") as f:
            f.write(await file.read())
        saved_urls.append(f"/media/{filename}")

    proposal = ProposalDB(payload=data, file_urls=saved_urls)
    db.add(proposal)
    db.commit()
    db.refresh(proposal)
    return {"id": proposal.id, "files": saved_urls}


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
