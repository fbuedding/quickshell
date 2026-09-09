#!/usr/bin/env python3
"""
Quickshell Calendar Fetcher
Fetches and parses iCalendar (.ics) feeds configured in calendars.json.
Supports secret URL retrieval from FreeDesktop Secret Service / KeePassXC,
session caching in volatile RAM ($XDG_RUNTIME_DIR, tmpfs),
local gitignored overrides (calendars.local.json), and disk caching.
Outputs a clean JSON structure grouped by date (YYYY-MM-DD).
"""

import sys
import os
import re
import json
import urllib.request
import hashlib
import subprocess
from datetime import datetime, date, time, timedelta, timezone

CONFIG_PATH = os.path.expanduser("~/.config/quickshell/default/calendar/calendars.json")
LOCAL_CONFIG_PATH = os.path.expanduser("~/.config/quickshell/default/calendar/calendars.local.json")
CACHE_DIR = os.path.expanduser("~/.cache/quickshell/calendar")
OUTPUT_CACHE = os.path.join(CACHE_DIR, "events.json")

# In-RAM volatile session cache (never written to disk or git, cleared on reboot)
RUNTIME_DIR = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
SESSION_CACHE_DIR = os.path.join(RUNTIME_DIR, "quickshell")
SESSION_SECRETS_FILE = os.path.join(SESSION_CACHE_DIR, "calendar_secrets.json")

os.makedirs(CACHE_DIR, exist_ok=True)

def load_session_secrets():
    """Loads cached secret URLs from volatile RAM (tmpfs) to prevent repeated KeePassXC prompts."""
    if os.path.exists(SESSION_SECRETS_FILE):
        try:
            with open(SESSION_SECRETS_FILE, "r", encoding="utf-8") as f:
                data = json.load(f)
                if isinstance(data, dict):
                    return data
        except Exception:
            pass
    return {}

def save_session_secrets(secrets):
    """Saves secret URLs to volatile RAM (tmpfs) with strict 0600 (owner-only) permissions."""
    try:
        os.makedirs(SESSION_CACHE_DIR, exist_ok=True)
        try:
            os.chmod(SESSION_CACHE_DIR, 0o700)
        except Exception:
            pass
        flags = os.O_WRONLY | os.O_CREAT | os.O_TRUNC
        fd = os.open(SESSION_SECRETS_FILE, flags, 0o600)
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            json.dump(secrets, f, indent=2)
    except Exception:
        pass

def lookup_keyring_secret(keyring_spec, cal_name=""):
    """
    Looks up a secret URL from FreeDesktop Secret Service (KeePassXC) via secret-tool.
    Supports string shorthand (matching Title or service/calendar attributes)
    or a dictionary of exact key-value attributes.
    """
    if not keyring_spec:
        return ""

    candidates = []
    if isinstance(keyring_spec, dict):
        args = []
        for k, v in keyring_spec.items():
            args.extend([str(k), str(v)])
        candidates.append(args)
    elif isinstance(keyring_spec, str):
        # 1. Match KeePassXC entry Title
        candidates.append(["Title", keyring_spec])
        candidates.append(["title", keyring_spec])
        # 2. Match service/calendar attributes
        candidates.append(["service", "quickshell-calendar", "calendar", keyring_spec])
        candidates.append(["service", "quickshell-calendar", "name", keyring_spec])
        if cal_name and cal_name != keyring_spec:
            candidates.append(["service", "quickshell-calendar", "calendar", cal_name])

    for args in candidates:
        try:
            cmd = ["secret-tool", "lookup"] + args
            res = subprocess.run(cmd, capture_output=True, text=True, timeout=3.5)
            if res.returncode == 0 and res.stdout.strip():
                val = res.stdout.strip()
                if val.startswith("http"):
                    return val
        except (subprocess.TimeoutExpired, FileNotFoundError, Exception):
            pass

    return ""

def parse_ics_datetime(val, params=""):
    """Parses an iCalendar DTSTART/DTEND string into (date_str, time_str, is_all_day, datetime_obj)."""
    val = val.strip()
    # All-day date (YYYYMMDD)
    if "VALUE=DATE" in params or len(val) == 8:
        try:
            d = datetime.strptime(val[:8], "%Y%m%d").date()
            return d.strftime("%Y-%m-%d"), "Ganztägig", True, datetime.combine(d, time.min)
        except Exception:
            return None, None, False, None

    # DateTime format: YYYYMMDDTHHMMSS or YYYYMMDDTHHMMSSZ
    try:
        is_utc = val.endswith("Z")
        clean_val = val.rstrip("Z")
        dt = datetime.strptime(clean_val, "%Y%m%dT%H%M%S")
        if is_utc:
            dt = dt.replace(tzinfo=timezone.utc).astimezone()
        d_str = dt.strftime("%Y-%m-%d")
        t_str = dt.strftime("%H:%M")
        return d_str, t_str, False, dt
    except Exception:
        # Fallback to date only
        if len(val) >= 8:
            try:
                d = datetime.strptime(val[:8], "%Y%m%d").date()
                return d.strftime("%Y-%m-%d"), "Ganztägig", True, datetime.combine(d, time.min)
            except Exception:
                pass
        return None, None, False, None

def fetch_feed(url, cal_id):
    """Fetches feed from URL with caching and offline fallback."""
    cache_file = os.path.join(CACHE_DIR, f"feed_{cal_id}.ics")
    content = ""
    if url and url.startswith("http"):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "Quickshell-Calendar/1.0"})
            with urllib.request.urlopen(req, timeout=6) as resp:
                content = resp.read().decode("utf-8", errors="replace")
            with open(cache_file, "w", encoding="utf-8") as f:
                f.write(content)
        except Exception:
            pass

    # Fallback to local cache if network or secret lookup failed
    if not content and os.path.exists(cache_file):
        try:
            with open(cache_file, "r", encoding="utf-8") as f:
                content = f.read()
        except Exception:
            pass

    return content

def expand_rrule(start_dt, end_dt, rrule_str, is_all_day, win_start, win_end):
    """Simple recurring event expansion for common rules."""
    instances = []
    rule_parts = dict(part.split("=", 1) for part in rrule_str.split(";") if "=" in part)
    freq = rule_parts.get("FREQ", "").upper()
    until_str = rule_parts.get("UNTIL")
    until_dt = None
    if until_str:
        try:
            if len(until_str) == 8:
                until_dt = datetime.strptime(until_str, "%Y%m%d").replace(tzinfo=start_dt.tzinfo)
            else:
                until_dt = datetime.strptime(until_str.rstrip("Z"), "%Y%m%dT%H%M%S").replace(tzinfo=start_dt.tzinfo)
        except Exception:
            pass

    duration = (end_dt - start_dt) if end_dt else timedelta(hours=1)
    cur = start_dt

    if freq == "YEARLY":
        for y in range(win_start.year - 1, win_end.year + 2):
            try:
                inst_start = cur.replace(year=y)
                inst_end = inst_start + duration
                if until_dt and inst_start > until_dt:
                    continue
                if win_start <= inst_start.date() <= win_end:
                    instances.append((inst_start, inst_end))
            except ValueError:
                pass
    elif freq == "MONTHLY":
        interval = int(rule_parts.get("INTERVAL", 1))
        m_dt = start_dt
        while m_dt.date() <= win_end:
            if until_dt and m_dt > until_dt:
                break
            if win_start <= m_dt.date() <= win_end:
                instances.append((m_dt, m_dt + duration))
            month = m_dt.month - 1 + interval
            year = m_dt.year + month // 12
            month = month % 12 + 1
            day = min(m_dt.day, 28)
            m_dt = m_dt.replace(year=year, month=month, day=day)
    elif freq == "WEEKLY":
        interval = int(rule_parts.get("INTERVAL", 1))
        w_dt = start_dt
        while w_dt.date() <= win_end:
            if until_dt and w_dt > until_dt:
                break
            if win_start <= w_dt.date() <= win_end:
                instances.append((w_dt, w_dt + duration))
            w_dt += timedelta(weeks=interval)
    elif freq == "DAILY":
        interval = int(rule_parts.get("INTERVAL", 1))
        d_dt = start_dt
        while d_dt.date() <= win_end:
            if until_dt and d_dt > until_dt:
                break
            if win_start <= d_dt.date() <= win_end:
                instances.append((d_dt, d_dt + duration))
            d_dt += timedelta(days=interval)

    return instances

def main():
    if "--clear-session-secrets" in sys.argv:
        if os.path.exists(SESSION_SECRETS_FILE):
            try:
                os.remove(SESSION_SECRETS_FILE)
            except Exception:
                pass

    today = date.today()
    win_start = today - timedelta(days=45)
    win_end = today + timedelta(days=120)

    calendars = []
    if os.path.exists(CONFIG_PATH):
        try:
            with open(CONFIG_PATH, "r", encoding="utf-8") as f:
                calendars = json.load(f)
        except Exception as e:
            print(f"Error loading config: {e}", file=sys.stderr)

    # Load optional gitignored local overrides
    local_overrides = {}
    if os.path.exists(LOCAL_CONFIG_PATH):
        try:
            with open(LOCAL_CONFIG_PATH, "r", encoding="utf-8") as f:
                data = json.load(f)
                if isinstance(data, dict):
                    local_overrides = data
                elif isinstance(data, list):
                    for item in data:
                        if "name" in item and "url" in item:
                            local_overrides[item["name"]] = item["url"]
        except Exception:
            pass

    # Load in-RAM session cache
    session_secrets = load_session_secrets()
    session_secrets_updated = False

    events_by_date = {}
    cal_summaries = []

    for idx, cal in enumerate(calendars):
        if not cal.get("enabled", True):
            continue
        name = cal.get("name", f"Calendar {idx+1}")
        color = cal.get("color", "#9ccfd8")
        cal_id = hashlib.md5(name.encode()).hexdigest()[:8]

        # Resolution hierarchy:
        # 1. Direct URL in calendars.json (e.g. public Feiertage)
        # 2. Gitignored local override calendars.local.json
        # 3. In-RAM session cache ($XDG_RUNTIME_DIR/quickshell/calendar_secrets.json)
        # 4. KeePassXC / FreeDesktop Secret Service (prompts once per session)
        url = cal.get("url", "").strip()
        if not url and name in local_overrides:
            url = local_overrides[name].strip()

        keyring_spec = cal.get("keyring")
        if not url and keyring_spec:
            cache_key = str(keyring_spec)
            if cache_key in session_secrets and session_secrets[cache_key].startswith("http"):
                url = session_secrets[cache_key]
            else:
                url = lookup_keyring_secret(keyring_spec, name)
                if url:
                    session_secrets[cache_key] = url
                    session_secrets_updated = True

        cal_event_count = 0
        raw_ics = fetch_feed(url, cal_id)
        if raw_ics:
            # Unfold lines according to RFC 5545
            unfolded = re.sub(r"\r?\n[ \t]", "", raw_ics)
            for match in re.finditer(r"BEGIN:VEVENT(.*?)END:VEVENT", unfolded, re.DOTALL):
                block = match.group(1)
                
                sum_m = re.search(r"^SUMMARY:(.*)$", block, re.M)
                if not sum_m:
                    continue
                summary = sum_m.group(1).strip().replace(r"\,", ",").replace(r"\;", ";").replace(r"\\", "\\")

                dtstart_m = re.search(r"^DTSTART(;[^:]*)?:(.*)$", block, re.M)
                if not dtstart_m:
                    continue
                dtstart_params = dtstart_m.group(1) or ""
                dtstart_val = dtstart_m.group(2)
                d_str, t_str, is_all_day, start_dt = parse_ics_datetime(dtstart_val, dtstart_params)
                if not d_str or not start_dt:
                    continue

                dtend_m = re.search(r"^DTEND(;[^:]*)?:(.*)$", block, re.M)
                end_dt = None
                end_t_str = None
                if dtend_m:
                    dtend_params = dtend_m.group(1) or ""
                    dtend_val = dtend_m.group(2)
                    _, end_t_str, _, end_dt = parse_ics_datetime(dtend_val, dtend_params)

                rrule_m = re.search(r"^RRULE:(.*)$", block, re.M)

                if is_all_day:
                    time_display = "Ganztägig"
                elif end_t_str and end_t_str != t_str:
                    time_display = f"{t_str} – {end_t_str}"
                else:
                    time_display = t_str

                # Check for RRULE
                if rrule_m:
                    rrule_str = rrule_m.group(1).strip()
                    instances = expand_rrule(start_dt, end_dt, rrule_str, is_all_day, win_start, win_end)
                    for inst_start, inst_end in instances:
                        inst_date_str = inst_start.strftime("%Y-%m-%d")
                        if is_all_day:
                            inst_time = "Ganztägig"
                        elif inst_end:
                            inst_time = f"{inst_start.strftime('%H:%M')} – {inst_end.strftime('%H:%M')}"
                        else:
                            inst_time = inst_start.strftime("%H:%M")

                        ev_obj = {
                            "title": summary,
                            "time": inst_time,
                            "allDay": is_all_day,
                            "calendar": name,
                            "color": color
                        }
                        events_by_date.setdefault(inst_date_str, []).append(ev_obj)
                        cal_event_count += 1
                else:
                    # Non-recurring event: check if inside window
                    ev_date = start_dt.date()
                    if win_start <= ev_date <= win_end:
                        ev_obj = {
                            "title": summary,
                            "time": time_display,
                            "allDay": is_all_day,
                            "calendar": name,
                            "color": color
                        }
                        events_by_date.setdefault(d_str, []).append(ev_obj)
                        cal_event_count += 1

        cal_summaries.append({
            "name": name,
            "color": color,
            "hasUrl": bool(url or os.path.exists(os.path.join(CACHE_DIR, f"feed_{cal_id}.ics"))),
            "eventCount": cal_event_count
        })

    if session_secrets_updated:
        save_session_secrets(session_secrets)

    # Sort events on each day: all-day first, then by time
    for d_key in events_by_date:
        events_by_date[d_key].sort(key=lambda x: (not x["allDay"], x["time"]))

    result = {
        "lastUpdated": datetime.now().strftime("%Y-%m-%d %H:%M"),
        "calendars": cal_summaries,
        "events": events_by_date
    }

    output_json = json.dumps(result, ensure_ascii=False, indent=2)
    try:
        with open(OUTPUT_CACHE, "w", encoding="utf-8") as f:
            f.write(output_json)
    except Exception:
        pass

    print(output_json)

if __name__ == "__main__":
    main()
