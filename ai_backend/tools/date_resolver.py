import re
import datetime
from zoneinfo import ZoneInfo
from typing import Tuple, Optional

IST = ZoneInfo("Asia/Kolkata")

WEEKDAYS = {
    "monday": 0,
    "tuesday": 1,
    "wednesday": 2,
    "thursday": 3,
    "friday": 4,
    "saturday": 5,
    "sunday": 6
}

MONTHS = {
    "january": 1, "jan": 1,
    "february": 2, "feb": 2,
    "march": 3, "mar": 3,
    "april": 4, "apr": 4,
    "may": 5,
    "june": 6, "jun": 6,
    "july": 7, "jul": 7,
    "august": 8, "aug": 8,
    "september": 9, "sep": 9, "sept": 9,
    "october": 10, "oct": 10,
    "november": 11, "nov": 11,
    "december": 12, "dec": 12
}

def resolve_relative_date(message: str, timezone_str: str = "Asia/Kolkata") -> Tuple[Optional[str], Optional[str]]:
    """
    Deterministically resolves relative or explicit date references in user message.
    Returns (iso_date_string, date_label) or (None, None).
    Example:
      "What was my yesterday score?" -> ("2026-09-12", "yesterday")
      "How did I sleep on September 10?" -> ("2026-09-10", "September 10")
    """
    try:
        tz = ZoneInfo(timezone_str)
    except Exception:
        tz = IST

    now = datetime.datetime.now(tz).date()
    text = message.lower().strip()

    # 1. "Day before yesterday"
    if "day before yesterday" in text:
        target = now - datetime.timedelta(days=2)
        return (target.isoformat(), "day before yesterday")

    # 2. "Yesterday"
    if "yesterday" in text:
        target = now - datetime.timedelta(days=1)
        return (target.isoformat(), "yesterday")

    # 3. "Today"
    if "today" in text:
        return (now.isoformat(), "today")

    # 4. "Last [weekday]" e.g. "last monday", "last friday"
    for day_name, day_num in WEEKDAYS.items():
        if f"last {day_name}" in text or f"previous {day_name}" in text:
            # Days back to that weekday
            days_ago = (now.weekday() - day_num) % 7
            if days_ago == 0:
                days_ago = 7
            target = now - datetime.timedelta(days=days_ago)
            return (target.isoformat(), f"last {day_name.capitalize()}")

    # 5. ISO date format: YYYY-MM-DD
    iso_match = re.search(r'\b(20\d\d)-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])\b', text)
    if iso_match:
        return (iso_match.group(0), iso_match.group(0))

    # 6. "on Month Day" or "Month Day" e.g. "September 10", "Sep 12", "10 September"
    # Format: Month Day (e.g. September 12 or Sep 12 or September 10)
    m_day_match = re.search(r'\b(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|jun|jul|aug|sep|sept|oct|nov|dec)\s+([12]\d|3[01]|0?[1-9])(?:st|nd|rd|th)?\b', text)
    if m_day_match:
        m_str = m_day_match.group(1)
        day_int = int(m_day_match.group(2))
        month_int = MONTHS.get(m_str, now.month)
        year_int = now.year
        try:
            target = datetime.date(year_int, month_int, day_int)
            # If date is in the future, might refer to last year
            if target > now:
                target = datetime.date(year_int - 1, month_int, day_int)
            return (target.isoformat(), f"{m_str.capitalize()} {day_int}")
        except ValueError:
            pass

    # Format: Day Month (e.g. 12 September or 10th September or 10 September)
    day_m_match = re.search(r'\b([12]\d|3[01]|0?[1-9])(?:st|nd|rd|th)?\s+(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|jun|jul|aug|sep|sept|oct|nov|dec)\b', text)
    if day_m_match:
        day_int = int(day_m_match.group(1))
        m_str = day_m_match.group(2)
        month_int = MONTHS.get(m_str, now.month)
        year_int = now.year
        try:
            target = datetime.date(year_int, month_int, day_int)
            if target > now:
                target = datetime.date(year_int - 1, month_int, day_int)
            return (target.isoformat(), f"{day_int} {m_str.capitalize()}")
        except ValueError:
            pass

    return (None, None)

def get_today_ist() -> str:
    return datetime.datetime.now(IST).date().isoformat()

def get_yesterday_ist() -> str:
    return (datetime.datetime.now(IST).date() - datetime.timedelta(days=1)).isoformat()
