#!/usr/bin/env python3
import json
import subprocess
import shutil
import sys

IGNORED_DESCRIPTIONS = {
    "Easy Effects Sink",
}

def get_sinks():
    try:
        out = subprocess.check_output(
            ["pactl", "-f", "json", "list", "sinks"],
            stderr=subprocess.DEVNULL
        ).decode("utf-8")
        sinks = json.loads(out)
        valid = []
        for s in sinks:
            desc = s.get("description", "")
            name = s.get("name", "")
            if desc in IGNORED_DESCRIPTIONS or "easyeffects" in name.lower() or name.endswith(".monitor"):
                continue
            valid.append(s)
        return valid
    except Exception:
        # Fallback to pactl list short sinks
        try:
            out = subprocess.check_output(
                ["pactl", "list", "short", "sinks"],
                stderr=subprocess.DEVNULL
            ).decode("utf-8")
            valid = []
            for line in out.strip().splitlines():
                parts = line.split()
                if len(parts) >= 2:
                    name = parts[1]
                    if not name.endswith(".monitor") and "easyeffects" not in name.lower():
                        valid.append({"name": name, "description": name, "properties": {}})
            return valid
        except Exception:
            return []

def get_default_sink():
    try:
        out = subprocess.check_output(
            ["pactl", "get-default-sink"],
            stderr=subprocess.DEVNULL
        ).decode("utf-8").strip()
        return out
    except Exception:
        return None

def set_default_sink(sink_name):
    # Set default sink
    subprocess.run(["pactl", "set-default-sink", sink_name], check=False, stderr=subprocess.DEVNULL)
    
    # Move active sink-inputs to the new sink
    try:
        inputs_out = subprocess.check_output(
            ["pactl", "list", "short", "sink-inputs"],
            stderr=subprocess.DEVNULL
        ).decode("utf-8")
        for line in inputs_out.strip().splitlines():
            if not line:
                continue
            input_id = line.split()[0]
            subprocess.run(
                ["pactl", "move-sink-input", input_id, sink_name],
                check=False,
                stderr=subprocess.DEVNULL
            )
    except Exception:
        pass

def send_notification(sink):
    if not shutil.which("notify-send"):
        return

    name = sink.get("name", "")
    desc = sink.get("description", "")
    props = sink.get("properties", {})
    nick = props.get("node.nick") or props.get("device.description") or desc or name

    # Determine appropriate icon
    text_check = f"{name} {desc} {nick}".lower()
    if any(w in text_check for w in ["headphone", "headset", "earphone", "cloud", "buds", "airpods", "iec958"]):
        icon = "audio-headphones"
    elif any(w in text_check for w in ["hdmi", "displayport", "tv", "monitor", "ultragear"]):
        icon = "video-display"
    else:
        icon = "audio-speakers"

    subprocess.run([
        "notify-send",
        "-h", "string:x-canonical-private-synchronous:audio-out",
        "-i", icon,
        "-u", "low",
        "-t", "2000",
        "Audio Output",
        nick
    ], check=False, stderr=subprocess.DEVNULL)

def main():
    sinks = get_sinks()
    if not sinks:
        return

    if len(sinks) == 1:
        send_notification(sinks[0])
        return

    current_default = get_default_sink()
    current_index = -1
    for i, s in enumerate(sinks):
        if s.get("name") == current_default:
            current_index = i
            break

    if current_index == -1:
        next_index = 0
    else:
        next_index = (current_index + 1) % len(sinks)

    target_sink = sinks[next_index]
    target_name = target_sink.get("name")

    if target_name:
        set_default_sink(target_name)
        send_notification(target_sink)

if __name__ == "__main__":
    main()
