import os
import re
from datetime import datetime, timedelta, timezone
from typing import Dict, List, Optional

import httpx
from bs4 import BeautifulSoup
from sqlalchemy.orm import Session

AFISHA_CHANNELS = {"afisha_noyabrsk", "art_mikser"}
OFFICIAL_CHANNELS = {"noyabrsk_adm", "yanao_ru"}

STRONG_EVENT_KEYWORDS = (
    "афиша", "билеты", "вход свободный", "приглашаем на",
    "мастер-класс", "кинопоказ", "спектакль", "концерт", "выставка", "фестиваль", "ярмарка", "турнир", "приглашаем",
)

PAST_TENSE_STOPWORDS = (
    "состоялся", "состоялась", "состоялись", "прошёл", "прошел",
    "прошла", "прошли", "завершился", "завершилась", "подвели итоги",
    "приняли участие", "победител", "наградили", "вчера ",
)

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
    raw = os.getenv("TG_CHANNELS", "afisha_noyabrsk,noyabrsk_info,mig_noyabrsk")
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


def _extract_bg_url(el) -> Optional[str]:
    if not el:
        return None
    style = el.get("style", "")
    m = re.search(r"url\(['\"]?(https?://[^'\")]+)['\"]?\)", style)
    return m.group(1) if m else None


def _is_event_post(channel: str, text_lower: str) -> bool:
    if any(sw in text_lower for sw in PAST_TENSE_STOPWORDS):
        return False
    if channel.lower() in AFISHA_CHANNELS:
        return True
    return any(k in text_lower for k in STRONG_EVENT_KEYWORDS)


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
        for br in text_el.find_all("br"):
            br.replace_with("\n")
        raw_text = text_el.get_text("", strip=False).strip()
        if len(raw_text) < 20:
            continue

        lines = [re.sub(r"\s+", " ", ln).strip() for ln in raw_text.splitlines()]
        text_lines = [ln for ln in lines if re.search(r"[А-Яа-яЁёA-Za-z0-9]{3,}", ln)]
        title = (text_lines[0] if text_lines else raw_text)[:110]

        # Фото, обложки видео и превью ссылок
        cover_url = None
        gallery = []
        for photo in msg.select(".tgme_widget_message_photo_wrap"):
            u = _extract_bg_url(photo)
            if u:
                if not cover_url:
                    cover_url = u
                else:
                    gallery.append(u)

        if not cover_url:
            for selector in (
                ".tgme_widget_message_video_thumb",
                ".tgme_widget_message_roundvideo_thumb",
                ".link_preview_image",
            ):
                u = _extract_bg_url(msg.select_one(selector))
                if u:
                    cover_url = u
                    break

        # Видео
        video_el = msg.select_one("video[src]")
        video_url = video_el.get("src") if video_el else None
        if not cover_url and video_el and video_el.get("poster"):
            cover_url = video_el.get("poster")

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
    return posts[-15:]


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
            is_event = _is_event_post(channel, text_lower)

            if is_event:
                exists = db.query(EventDB).filter(EventDB.source_url == p["url"]).first()
                if exists:
                    if not exists.cover_url and p["cover_url"]:
                        exists.cover_url = p["cover_url"]
                    if p["video_url"]:
                        exists.video_url = p["video_url"]
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
                    if not exists.content:
                        exists.content = p["text"]
                    if not exists.cover_url and p["cover_url"]:
                        exists.cover_url = p["cover_url"]
                    if p["video_url"]:
                        exists.video_url = p["video_url"]
                    continue
                news = NewsDB(
                    title=p["title"],
                    content=p["text"],
                    category="official" if channel in OFFICIAL_CHANNELS else "city",
                    published_at_label=_format_ru_time(p["iso_dt"]),
                    external_url=p["url"],
                    cover_url=p["cover_url"],
                    video_url=p["video_url"],
                )
                db.add(news)
                added_news += 1

    db.commit()
    return {"added_events": added_events, "added_news": added_news}
