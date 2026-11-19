import os
import re
from datetime import datetime, timedelta, timezone
from typing import Dict, List, Optional

import httpx
from bs4 import BeautifulSoup
from sqlalchemy.orm import Session

EVENT_KEYWORDS = (
    "афиша", "концерт", "выставка", "спектакль", "мастер-класс",
    "фестиваль", "кинопоказ", "турнир", "соревнован", "ярмарка",
    "билеты", "вход свободный", "приглашаем", "состоится",
)

OFFICIAL_CHANNELS = {"noyabrsk_adm", "yanao_ru"}

CATEGORY_MAP = {
    "концерт": "Концерт",
    "спектакль": "Спектакль",
    "кино": "Кинопоказ",
    "выставк": "Выставка",
    "экскурси": "Экскурсия",
    "мастер-класс": "Мастер-класс",
    "фестивал": "Фестиваль",
    "ярмарк": "Ярмарка",
    "спорт": "Спорт",
    "турнир": "Спорт",
}


def get_channels() -> List[str]:
    raw = os.getenv("TG_CHANNELS", "noyabrsk_adm,noyabrsk24")
    return [c.strip().lstrip("@") for c in raw.split(",") if c.strip()]


def _detect_category(text_lower: str) -> str:
    for key, cat in CATEGORY_MAP.items():
        if key in text_lower:
            return cat
    return "Другое"


def _extract_time(text: str) -> Optional[str]:
    m = re.search(r"\b([01]?\d|2[0-3]):([0-5]\d)\b", text)
    if not m:
        return None
    return f"{int(m.group(1)):02d}:{m.group(2)}"


def _format_ru_time(iso_str: Optional[str]) -> str:
    tz = timezone(timedelta(hours=5))
    try:
        dt = datetime.fromisoformat(iso_str.replace("Z", "+00:00")).astimezone(tz) if iso_str else datetime.now(tz)
    except Exception:
        dt = datetime.now(tz)
    return dt.strftime("%d.%m в %H:%M")


async def fetch_channel_posts(channel: str) -> List[Dict]:
    url = f"https://t.me/s/{channel}"
    headers = {"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36"}
    async with httpx.AsyncClient(timeout=20.0, follow_redirects=True) as client:
        resp = await client.get(url, headers=headers)
        if resp.status_code != 200:
            return []

    soup = BeautifulSoup(resp.text, "html.parser")
    posts = []
    for msg in soup.select(".tgme_widget_message_wrap"):
        link_el = msg.select_one("a.tgme_widget_message_date")
        text_el = msg.select_one(".tgme_widget_message_text")
        if not link_el or not text_el:
            continue

        post_url = link_el.get("href", "")
        raw_text = text_el.get_text("\n", strip=True)
        if len(raw_text) < 20:
            continue

        lines = [ln.strip() for ln in raw_text.splitlines() if ln.strip()]
        title = lines[0][:110] if lines else raw_text[:110]

        # Фото
        cover_url = None
        gallery = []
        for photo in msg.select(".tgme_widget_message_photo_wrap"):
            style = photo.get("style", "")
            m = re.search(r"url\(['\"]?(https?://[^'\")]+)['\"]?\)", style)
            if m:
                if not cover_url:
                    cover_url = m.group(1)
                else:
                    gallery.append(m.group(1))

        # Видео
        video_el = msg.select_one("video[src]")
        video_url = video_el.get("src") if video_el else None

        time_el = msg.select_one("time[datetime]")
        iso_dt = time_el.get("datetime") if time_el else None

        posts.append({
            "channel": channel,
            "url": post_url,
            "title": title,
            "text": raw_text,
            "cover_url": cover_url,
            "video_url": video_url,
            "gallery_urls": gallery,
            "iso_dt": iso_dt,
        })
    return posts[-15:]  # берём последние 15 постов с канала


async def run_parse_cycle(db: Session, EventDB, NewsDB) -> Dict[str, int]:
    added_events = 0
    added_news = 0
    tz = timezone(timedelta(hours=5))
    today_str = datetime.now(tz).strftime("%Y-%m-%d")

    for channel in get_channels():
        try:
            posts = await fetch_channel_posts(channel)
        except Exception:
            continue

        for p in posts:
            text_lower = p["text"].lower()
            is_event = any(k in text_lower for k in EVENT_KEYWORDS)

            if is_event:
                exists = db.query(EventDB).filter(EventDB.source_url == p["url"]).first()
                if exists:
                    continue
                start_time = _extract_time(p["text"])
                ev = EventDB(
                    title=p["title"],
                    category=_detect_category(text_lower),
                    age_rating="0+",
                    venue_name=f"Канал @{channel}",
                    venue_address="г. Ноябрьск (подробности в описании)",
                    ticket_url=p["url"],
                    description=p["text"],
                    cover_url=p["cover_url"],
                    video_url=p["video_url"],
                    gallery_urls=p["gallery_urls"],
                    is_free="бесплатн" in text_lower or "вход свободный" in text_lower,
                    schedule_type="single",
                    sessions=[{"date": today_str, "startTime": start_time, "endTime": "23:59"}],
                    source_url=p["url"],
                )
                db.add(ev)
                added_events += 1
            else:
                exists = db.query(NewsDB).filter(NewsDB.external_url == p["url"]).first()
                if exists:
                    continue
                news = NewsDB(
                    title=p["title"],
                    category="official" if channel in OFFICIAL_CHANNELS else "city",
                    published_at_label=_format_ru_time(p["iso_dt"]),
                    external_url=p["url"],
                    cover_url=p["cover_url"],
                )
                db.add(news)
                added_news += 1

    db.commit()
    return {"added_events": added_events, "added_news": added_news}
