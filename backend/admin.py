import hashlib
import hmac
import html
import os
import uuid
from datetime import datetime, timedelta, timezone
from typing import Callable

from fastapi import APIRouter, Cookie, Depends, File, Form, HTTPException, UploadFile
from fastapi.responses import FileResponse, HTMLResponse, RedirectResponse
from sqlalchemy.orm import Session

ADMIN_USER = os.getenv("ADMIN_USERNAME", "admin")
ADMIN_PASS = os.getenv("ADMIN_PASSWORD", "yagorod2026")
ADMIN_SECRET = os.getenv("ADMIN_SECRET", "ya-gorod-admin-secret-change-me")
PUBLIC_BASE_URL = os.getenv("PUBLIC_BASE_URL", "https://ya-gorod-api.onrender.com").rstrip("/")
COOKIE_NAME = "yg_admin_session"


def _make_token(username: str) -> str:
    sig = hmac.new(ADMIN_SECRET.encode(), username.encode(), hashlib.sha256).hexdigest()
    return f"{username}:{sig}"


def _is_auth(token: str | None) -> bool:
    if not token or ":" not in token:
        return False
    user, _ = token.split(":", 1)
    expected = _make_token(user)
    return user == ADMIN_USER and hmac.compare_digest(token, expected)


def _esc(val) -> str:
    return html.escape(str(val or ""))


async def _save_upload(file: UploadFile | None, db: Session, MediaFileDB) -> str | None:
    if not file or not file.filename:
        return None
    content = await file.read()
    if not content:
        return None
    ext = os.path.splitext(file.filename)[1].lower() or ".jpg"
    file_id = f"{uuid.uuid4().hex}{ext}"
    db.add(MediaFileDB(
        id=file_id,
        filename=file.filename,
        content_type=file.content_type or "application/octet-stream",
        data=content,
    ))
    db.commit()
    return f"{PUBLIC_BASE_URL}/media/{file_id}"


def create_admin_router(
    get_db: Callable,
    StoryDB,
    BannerDB,
    EventDB,
    NewsDB,
    ProposalDB,
    MediaFileDB,
    media_dir: str,
    private_dir: str,
    run_parse_cycle: Callable,
) -> APIRouter:
    router = APIRouter(prefix="/admin", tags=["admin"])

    @router.get("/login", response_class=HTMLResponse)
    def login_page(err: str = ""):
        err_html = f'<p style="color:#dc2626;margin-bottom:12px;">{_esc(err)}</p>' if err else ""
        return f"""<!doctype html>
<html lang="ru"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Вход — Я-Город Админ</title>
<style>
  body{{font-family:system-ui,sans-serif;background:#f5f6f8;display:flex;align-items:center;justify-content:center;min-height:100vh;margin:0}}
  .card{{background:#fff;padding:28px;border-radius:14px;box-shadow:0 4px 20px rgba(0,0,0,.06);width:320px}}
  h1{{margin:0 0 18px;font-size:20px;color:#2B3A67}}
  input{{width:100%;box-sizing:border-box;padding:10px 12px;margin-bottom:12px;border:1px solid #d1d5db;border-radius:8px;font-size:14px}}
  button{{width:100%;padding:11px;background:#2B3A67;color:#fff;border:0;border-radius:8px;font-weight:600;cursor:pointer}}
</style></head><body>
<div class="card">
  <h1>Я-Город · Админка</h1>
  {err_html}
  <form method="post" action="/admin/login">
    <input name="username" placeholder="Логин" required>
    <input name="password" type="password" placeholder="Пароль" required>
    <button type="submit">Войти</button>
  </form>
</div></body></html>"""

    @router.post("/login")
    def do_login(username: str = Form(...), password: str = Form(...)):
        if username == ADMIN_USER and password == ADMIN_PASS:
            resp = RedirectResponse("/admin", status_code=303)
            resp.set_cookie(COOKIE_NAME, _make_token(username), httponly=True, samesite="lax", max_age=86400 * 7)
            return resp
        return RedirectResponse("/admin/login?err=Неверный+логин+или+пароль", status_code=303)

    @router.post("/logout")
    def do_logout():
        resp = RedirectResponse("/admin/login", status_code=303)
        resp.delete_cookie(COOKIE_NAME)
        return resp

    @router.get("", response_class=HTMLResponse)
    def dashboard(
        yg_admin_session: str | None = Cookie(default=None),
        db: Session = Depends(get_db),
    ):
        if not _is_auth(yg_admin_session):
            return RedirectResponse("/admin/login", status_code=303)

        stories = db.query(StoryDB).all()
        banners = db.query(BannerDB).all()
        events = db.query(EventDB).order_by(EventDB.created_at.desc()).limit(30).all()
        news = db.query(NewsDB).limit(30).all()
        proposals = db.query(ProposalDB).order_by(ProposalDB.created_at.desc()).limit(20).all()

        tz = timezone(timedelta(hours=5))
        today = datetime.now(tz).strftime("%Y-%m-%d")
        in_7 = (datetime.now(tz) + timedelta(days=7)).strftime("%Y-%m-%d")

        stories_rows = "".join(
            f"<tr><td><b>{_esc(s.title)}</b><br><span class='muted'>{_esc((s.description or '')[:80])}</span></td>"
            f"<td>{'Видео' if s.is_video else 'Фото'}</td>"
            f"<td><form method='post' action='/admin/stories/{_esc(s.id)}/delete'><button class='del'>Удалить</button></form></td></tr>"
            for s in stories
        ) or "<tr><td colspan='3' class='muted'>Своих сторис нет (показываются авто-сторис из новостей)</td></tr>"

        banners_rows = "".join(
            f"<tr><td><b>{_esc(b.title)}</b><br><span class='muted'>{_esc(b.subtitle)}</span></td>"
            f"<td><form method='post' action='/admin/banners/{_esc(b.id)}/delete'><button class='del'>Удалить</button></form></td></tr>"
            for b in banners
        ) or "<tr><td colspan='2' class='muted'>Своих баннеров нет (показываются авто-баннеры)</td></tr>"

        events_rows = "".join(
            f"<tr><td><b>{_esc(e.title)}</b><br><span class='muted'>{_esc(e.category)} · {_esc(e.venue_name)}</span></td>"
            f"<td><form method='post' action='/admin/events/{_esc(e.id)}/delete'><button class='del'>Удалить</button></form></td></tr>"
            for e in events
        ) or "<tr><td colspan='2' class='muted'>Нет мероприятий</td></tr>"

        news_rows = "".join(
            f"<tr><td><b>{_esc(n.title)}</b><br><span class='muted'>{_esc(n.category)} · {_esc(n.published_at_label)}</span></td>"
            f"<td><form method='post' action='/admin/news/{_esc(n.id)}/delete'><button class='del'>Удалить</button></form></td></tr>"
            for n in news
        ) or "<tr><td colspan='2' class='muted'>Нет новостей</td></tr>"

        prop_rows = ""
        for p in proposals:
            data = p.payload or {}
            files_links = " ".join(
                f"<a href='/admin/proposals/file/{_esc(os.path.basename(f))}' target='_blank'>📎 {_esc(os.path.basename(f))}</a>"
                for f in (p.file_urls or [])
            )
            prop_rows += (
                f"<tr><td><b>{_esc(data.get('title', 'Без названия'))}</b><br>"
                f"<span class='muted'>{_esc(data.get('organizer'))} · {_esc(data.get('phone'))}</span><br>{files_links}</td></tr>"
            )
        if not prop_rows:
            prop_rows = "<tr><td class='muted'>Заявок пока нет</td></tr>"

        return f"""<!doctype html>
<html lang="ru"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Я-Город — Админ-панель</title>
<style>
  body{{font-family:system-ui,sans-serif;background:#f5f6f8;margin:0;color:#111827}}
  header{{background:#fff;padding:14px 24px;display:flex;justify-content:space-between;align-items:center;border-bottom:1px solid #e5e7eb}}
  header h1{{margin:0;font-size:18px;color:#2B3A67}}
  .wrap{{max-width:1000px;margin:20px auto;padding:0 16px;display:grid;gap:20px}}
  .card{{background:#fff;padding:18px;border-radius:12px;box-shadow:0 2px 10px rgba(0,0,0,.04)}}
  h2{{margin:0 0 12px;font-size:16px;color:#2B3A67}}
  form.grid{{display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:8px;margin-bottom:14px;align-items:center}}
  input,select,textarea{{padding:8px 10px;border:1px solid #d1d5db;border-radius:8px;font-size:13px;font-family:inherit}}
  label.file-lbl{{font-size:12px;color:#374151;display:flex;flex-direction:column;gap:4px}}
  button{{padding:8px 14px;background:#2B3A67;color:#fff;border:0;border-radius:8px;cursor:pointer;font-size:13px;font-weight:600}}
  button.del{{background:#ef4444;padding:5px 10px;font-size:12px}}
  button.sec{{background:#4b5563}}
  table{{width:100%;border-collapse:collapse;font-size:13px}}
  td{{padding:8px 6px;border-top:1px solid #f3f4f6;vertical-align:middle}}
  .muted{{color:#6b7280;font-size:12px}}
  .top-actions{{display:flex;gap:8px}}
</style></head><body>
<header>
  <h1>Я-Город · Админ-панель</h1>
  <div class="top-actions">
    <form method="post" action="/admin/parser/run"><button class="sec" type="submit">🔄 Запустить парсер</button></form>
    <form method="post" action="/admin/logout"><button class="del" type="submit">Выйти</button></form>
  </div>
</header>
<div class="wrap">
  <div class="card">
    <h2>Сторис ({len(stories)} своих + авто из новостей)</h2>
    <form class="grid" method="post" action="/admin/stories" enctype="multipart/form-data">
      <input name="title" placeholder="Название" required>
      <input name="description" placeholder="Текст описания (под кнопкой «Ещё»)">
      <select name="is_video"><option value="false">Фото</option><option value="true">Видео</option></select>
      <label class="file-lbl">Файл медиа (фото/видео)<input type="file" name="media_file" accept="image/*,video/*"></label>
      <input name="media_url" placeholder="или URL медиа (https://...)">
      <label class="file-lbl">Файл обложки (необязательно)<input type="file" name="preview_file" accept="image/*"></label>
      <input name="preview_url" placeholder="или URL обложки (необязательно)">
      <button type="submit">+ Добавить сторис</button>
    </form>
    <table>{stories_rows}</table>
  </div>

  <div class="card">
    <h2>Баннеры ({len(banners)} своих + авто)</h2>
    <form class="grid" method="post" action="/admin/banners" enctype="multipart/form-data">
      <input name="title" placeholder="Заголовок" required>
      <input name="subtitle" placeholder="Подпись" required>
      <label class="file-lbl">Файл картинки<input type="file" name="image_file" accept="image/*"></label>
      <input name="image_url" placeholder="или URL картинки (https://...)">
      <input name="target_url" placeholder="Ссылка (необязательно)">
      <button type="submit">+ Добавить баннер</button>
    </form>
    <table>{banners_rows}</table>
  </div>

  <div class="card">
    <h2>Афиша мероприятий ({len(events)})</h2>
    <form class="grid" method="post" action="/admin/events" enctype="multipart/form-data">
      <input name="title" placeholder="Название" required>
      <select name="category">
        <option>Концерт</option><option>Спектакль</option><option>Кинопоказ</option>
        <option>Выставка</option><option>Экскурсия</option><option>Мастер-класс</option>
        <option>Обучение</option><option>Фестиваль</option><option>Ярмарка</option>
        <option>Спорт</option><option>Другое</option>
      </select>
      <input name="venue_name" placeholder="Площадка" required>
      <input name="venue_address" placeholder="Адрес" value="г. Ноябрьск" required>
      <label class="file-lbl">Файл обложки<input type="file" name="cover_file" accept="image/*"></label>
      <input name="cover_url" placeholder="или URL обложки">
      <input name="description" placeholder="Описание" required>
      <input name="period_start" type="date" value="{today}" required>
      <input name="period_end" type="date" value="{in_7}" required>
      <button type="submit">+ Добавить событие</button>
    </form>
    <table>{events_rows}</table>
  </div>

  <div class="card">
    <h2>Новости ({len(news)})</h2>
    <table>{news_rows}</table>
  </div>

  <div class="card">
    <h2>Заявки пользователей ({len(proposals)})</h2>
    <table>{prop_rows}</table>
  </div>
</div></body></html>"""

    @router.post("/stories")
    async def add_story(
        title: str = Form(...),
        description: str = Form(""),
        preview_url: str = Form(""),
        media_url: str = Form(""),
        is_video: str = Form("false"),
        preview_file: UploadFile | None = File(default=None),
        media_file: UploadFile | None = File(default=None),
        yg_admin_session: str | None = Cookie(default=None),
        db: Session = Depends(get_db),
    ):
        if not _is_auth(yg_admin_session):
            raise HTTPException(status_code=401)
        saved_media = await _save_upload(media_file, db, MediaFileDB)
        saved_preview = await _save_upload(preview_file, db, MediaFileDB)
        final_media = saved_media or media_url.strip() or None
        final_preview = saved_preview or preview_url.strip() or final_media
        if not final_media:
            raise HTTPException(status_code=400, detail="Загрузите файл или укажите URL")
        db.add(StoryDB(
            title=title.strip(),
            description=description.strip() or None,
            preview_url=final_preview,
            media_url=final_media,
            is_video=(is_video == "true"),
        ))
        db.commit()
        return RedirectResponse("/admin", status_code=303)

    @router.post("/stories/{item_id}/delete")
    def del_story(item_id: str, yg_admin_session: str | None = Cookie(default=None), db: Session = Depends(get_db)):
        if not _is_auth(yg_admin_session):
            raise HTTPException(status_code=401)
        db.query(StoryDB).filter(StoryDB.id == item_id).delete()
        db.commit()
        return RedirectResponse("/admin", status_code=303)

    @router.post("/banners")
    async def add_banner(
        title: str = Form(...),
        subtitle: str = Form(...),
        image_url: str = Form(""),
        target_url: str = Form(""),
        image_file: UploadFile | None = File(default=None),
        yg_admin_session: str | None = Cookie(default=None),
        db: Session = Depends(get_db),
    ):
        if not _is_auth(yg_admin_session):
            raise HTTPException(status_code=401)
        saved_img = await _save_upload(image_file, db, MediaFileDB)
        final_img = saved_img or image_url.strip() or None
        db.add(BannerDB(
            title=title.strip(),
            subtitle=subtitle.strip(),
            image_url=final_img,
            target_url=target_url.strip() or None,
        ))
        db.commit()
        return RedirectResponse("/admin", status_code=303)

    @router.post("/banners/{item_id}/delete")
    def del_banner(item_id: str, yg_admin_session: str | None = Cookie(default=None), db: Session = Depends(get_db)):
        if not _is_auth(yg_admin_session):
            raise HTTPException(status_code=401)
        db.query(BannerDB).filter(BannerDB.id == item_id).delete()
        db.commit()
        return RedirectResponse("/admin", status_code=303)

    @router.post("/events")
    async def add_event(
        title: str = Form(...),
        category: str = Form(...),
        venue_name: str = Form(...),
        venue_address: str = Form(...),
        description: str = Form(...),
        cover_url: str = Form(""),
        period_start: str = Form(...),
        period_end: str = Form(...),
        cover_file: UploadFile | None = File(default=None),
        yg_admin_session: str | None = Cookie(default=None),
        db: Session = Depends(get_db),
    ):
        if not _is_auth(yg_admin_session):
            raise HTTPException(status_code=401)
        saved_cover = await _save_upload(cover_file, db, MediaFileDB)
        db.add(EventDB(
            title=title.strip(),
            category=category.strip(),
            venue_name=venue_name.strip(),
            venue_address=venue_address.strip(),
            description=description.strip(),
            cover_url=saved_cover or cover_url.strip() or None,
            schedule_type="period",
            period_start=period_start,
            period_end=period_end,
            is_free=True,
        ))
        db.commit()
        return RedirectResponse("/admin", status_code=303)

    @router.post("/events/{item_id}/delete")
    def del_event(item_id: str, yg_admin_session: str | None = Cookie(default=None), db: Session = Depends(get_db)):
        if not _is_auth(yg_admin_session):
            raise HTTPException(status_code=401)
        db.query(EventDB).filter(EventDB.id == item_id).delete()
        db.commit()
        return RedirectResponse("/admin", status_code=303)

    @router.post("/news/{item_id}/delete")
    def del_news(item_id: str, yg_admin_session: str | None = Cookie(default=None), db: Session = Depends(get_db)):
        if not _is_auth(yg_admin_session):
            raise HTTPException(status_code=401)
        db.query(NewsDB).filter(NewsDB.id == item_id).delete()
        db.commit()
        return RedirectResponse("/admin", status_code=303)

    @router.post("/parser/run")
    async def admin_run_parser(yg_admin_session: str | None = Cookie(default=None), db: Session = Depends(get_db)):
        if not _is_auth(yg_admin_session):
            raise HTTPException(status_code=401)
        await run_parse_cycle(db, EventDB, NewsDB)
        return RedirectResponse("/admin", status_code=303)

    @router.get("/proposals/file/{filename}")
    def download_proposal_file(filename: str, yg_admin_session: str | None = Cookie(default=None)):
        if not _is_auth(yg_admin_session):
            raise HTTPException(status_code=401)
        safe_name = os.path.basename(filename)
        path = os.path.join(private_dir, safe_name)
        if not os.path.isfile(path):
            raise HTTPException(status_code=404, detail="Файл не найден")
        return FileResponse(path, filename=safe_name)

    return router
