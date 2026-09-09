# Quickshell Desktop Configuration

[English](README.md) | [Deutsch](README.de.md)

Desktop shell setup for Hyprland built on [Quickshell](https://quickshell.outfoxxed.me/) with the Rosé Pine Moon palette. Features organic morphing panels with concave corner transitions, native PipeWire audio switcher, MPRIS media control, notification daemon, interactive month calendar, and custom DBusMenu system tray.

---

## Installation and Setup

### 1. Prerequisites and Dependencies

Install the required packages on your system (Arch Linux / CachyOS package names):

- **Shell Engine:** `quickshell` (or `quickshell-git`)
- **Qt 6 Modules:** `qt6-base`, `qt6-declarative`, `qt6-svg`
- **Audio & Media:** `pipewire`, `wireplumber`, `libpipewire`, `pactl` (from `libpulse`)
- **Secret Service (for calendar):** `libsecret` (provides `secret-tool`), and a Secret Service provider like `keepassxc`
- **Fonts & Icons:** `ttf-jetbrains-mono-nerd`, `rose-pine-moon-icons` (or any Nerd Font and icon theme)
- **Optional / Recommended:** `bluez`, `bluez-utils`, `lm_sensors`, `grim`

### 2. Clone Repository

Clone this repository into your user configuration directory:

```bash
git clone https://github.com/<your-user>/quickshell.git ~/.config/quickshell
```

If you already have files there, ensure the entry point is at `~/.config/quickshell/default/shell.qml`.

### 3. Adjust System Specific Settings

Before launching, check and adjust the following files to match your hardware and preferences:

1. **Distro Icon in TopBar (`default/bar/Bar.qml`):**
   - The topbar button looks for `/usr/share/icons/cachyos.svg` by default.
   - If using Arch, Fedora, or another distribution, change the path to your distro logo SVG or use a Nerd Font character.

2. **Corner Rounding and Dimensions (`default/theme/Theme.qml`):**
   - Adjust `rounding: 5` to match your Hyprland `decoration.rounding` setting.
   - Adjust `barHeight: 34` and `borderThickness: 12` if you want different topbar or screen margin sizes.

3. **Audio Soft-Mixer (WirePlumber):**
   - If your monitor (e.g. DisplayPort / HDMI) does not support hardware mute, create `~/.config/wireplumber/wireplumber.conf.d/50-alsa-soft-mixer.conf`:
     ```spa-json
     monitor.alsa.rules = [
       {
         matches = [ { node.name = "~alsa_output.*" } ]
         actions = { update-props = { api.alsa.soft-mixer = true } }
       }
     ]
     ```

4. **Qt 6 Icon Theme (`~/.config/qt6ct/qt6ct.conf`):**
   - Set `icon_theme=rose-pine-moon-icons` (or your preferred theme) to ensure tray and app icons render properly.

---

## Calendar Configuration and Secrets Setup

The calendar dropdown reads iCal (`.ics`) feeds from Google Calendar, Nextcloud, or any standard iCalendar URL. To prevent private URLs and access tokens from being committed to Git, configuration and secrets are decoupled.

### 1. Create Calendar Config

Copy the example configuration:

```bash
cp ~/.config/quickshell/default/calendar/calendars.example.json ~/.config/quickshell/default/calendar/calendars.json
```

`default/calendar/calendars.json` is ignored by Git. Edit it to list your calendars:

```json
[
  {
    "name": "Holidays",
    "url": "https://calendar.google.com/calendar/ical/de.german%23holiday%40group.v.calendar.google.com/public/basic.ics",
    "color": "#c4a7e7",
    "enabled": true
  },
  {
    "name": "Work",
    "keyring": "google-calendar-work",
    "color": "#9ccfd8",
    "enabled": true
  },
  {
    "name": "Private",
    "keyring": "google-calendar-private",
    "color": "#eb6f92",
    "enabled": true
  }
]
```

- Public feeds: provide direct `url`.
- Private feeds: omit `url` and set `keyring` to an identifier (e.g. `google-calendar-work`).

### 2. Store Secrets in Keyring / KeePassXC

Choose one of the following methods to store private `.ics` URLs:

#### Option A: KeePassXC (Recommended)
1. In KeePassXC Settings, enable **Secret Service Integration**.
2. Create an entry in your database:
   - **Title:** Match the `keyring` name from `calendars.json` (e.g. `google-calendar-work`).
   - **Password** or **URL:** Paste your private Google Calendar iCal URL (the secret address ending in `.ics`).
3. During startup, the calendar fetcher will query the secret once per login session and cache it in volatile memory (`$XDG_RUNTIME_DIR/quickshell/`, tmpfs) with 0600 permissions. No prompts occur on subsequent refreshes.

#### Option B: Terminal via `secret-tool`
Store the secret directly into your FreeDesktop Secret Service keyring:

```bash
secret-tool store --label="Google Calendar Work" Title google-calendar-work
# Enter your private .ics URL when prompted
```

Test the lookup:

```bash
secret-tool lookup Title google-calendar-work
```

#### Option C: Local Overrides File
Create `~/.config/quickshell/default/calendar/calendars.local.json` (gitignored):

```json
{
  "Work": "https://calendar.google.com/calendar/ical/<private-token>/basic.ics",
  "Private": "https://calendar.google.com/calendar/ical/<private-token>/basic.ics"
}
```

---

## Directory Structure

```text
~/.config/quickshell/
├── default/
│   ├── shell.qml                # Entry point (ShellRoot, loads all modules)
│   ├── Border.qml               # 12px outer borders and 4 concave screen corners
│   ├── bar/
│   │   ├── Bar.qml              # 34px TopBar
│   │   ├── Workspaces.qml       # 10 Workspaces with active underlines
│   │   ├── SysInfo.qml          # CPU, RAM, and temperature monitor
│   │   ├── Volume.qml           # PipeWire volume indicator
│   │   ├── Clock.qml            # Clock and date (click toggles calendar)
│   │   ├── Tray.qml             # System tray (DBus StatusNotifierItem)
│   │   ├── NotificationButton.qml # Bell icon with unread badge and DND
│   │   └── Separator.qml        # Visual divider
│   ├── tray/
│   │   ├── TrayMenu.qml         # Custom themed morphing tray menu and submenus
│   │   ├── TrayMenuState.qml    # Singleton state for tray anchor and visibility
│   │   └── qmldir               # QML module registry
│   ├── calendar/
│   │   ├── CalendarDropdown.qml # Month grid and agenda dropdown
│   │   ├── CalendarState.qml    # Calendar state and sync listener
│   │   ├── calendars.example.json # Anonymous template configuration
│   │   ├── calendars.json       # Local user calendar config (gitignored)
│   │   └── qmldir               # QML module registry
│   ├── notifications/
│   │   ├── NotificationState.qml # DBus notification server daemon and state
│   │   ├── NotificationPanel.qml # Slide-in control center (MPRIS, toggles, history)
│   │   ├── NotificationPopup.qml # Toast popups (top right)
│   │   ├── NotificationCard.qml  # Notification card with actions
│   │   ├── MprisPlayerWidget.qml # MPRIS player with cover art and timeline seekbar
│   │   ├── AudioControlWidget.qml # PipeWire sink switcher and mic controls
│   │   ├── BluetoothWidget.qml  # Bluetooth quick toggle and device manager
│   │   └── qmldir               # QML module registry
│   ├── power_menu/
│   │   ├── PowerMenu.qml        # Power menu (top left, slide-in)
│   │   ├── PowerMenuState.qml   # Power menu singleton
│   │   └── qmldir               # QML module registry
│   ├── app_launcher/
│   │   ├── AppLauncher.qml      # App launcher (bottom centered, slide-up)
│   │   ├── AppLauncherState.qml # App launcher singleton
│   │   └── qmldir               # QML module registry
│   ├── osd/
│   │   ├── OsdState.qml         # PipeWire volume and mute listener
│   │   ├── VolumeOsd.qml        # Centered floating pill OSD
│   │   └── qmldir               # QML module registry
│   ├── components/
│   │   └── ConcaveCurves.qml    # ShapePath concave corner transition component
│   ├── theme/
│   │   ├── Colors.qml           # Rosé Pine Moon palette
│   │   ├── Theme.qml            # Dimensions, roundings, and borders
│   │   └── qmldir               # Theme singleton registry
│   └── scripts/
│       ├── cycle_audio.py       # Middle-click audio sink cycle script
│       └── fetch_calendar.py    # iCal/Google calendar parser and cache daemon
├── README.md                    # English documentation
└── README.de.md                 # German documentation
```

---

## Components

### 1. TopBar (`default/bar/Bar.qml`)
- **Height:** 34px (`exclusiveZone: 34`, reserves space in Hyprland).
- **Left:** Distribution logo (click toggles power menu) and System Tray.
- **Center:** 10 Workspaces with active window indicators and active workspace underline.
- **Right:** SysInfo (CPU, RAM, Sensors), Volume, Clock, and Notification Bell.
- **Click Behavior:** Clicking empty bar space closes open panels.

### 2. System Tray (`default/bar/Tray.qml` & `default/tray/`)
- Implements StatusNotifierItem (SNI) via DBus.
- Replaces native Qt popup menus with a custom styled QML menu adhering to Rosé Pine Moon colors.
- Seamless morphing from the topbar with concave curves anchored to the clicked tray icon.
- Full input click-through on the topbar: clicking another tray icon while a menu is open switches directly to the new icon; clicking the same icon toggles it closed.
- Supports nested submenus, checkable items, separators, and dynamic width calculation.

### 3. Audio & Volume (`default/bar/Volume.qml`)
- **Left click:** Opens control center audio section.
- **Right click:** Toggles mute.
- **Middle click:** Cycles to the next audio output device via `default/scripts/cycle_audio.py`.
- **Scroll wheel:** Changes volume in 2% steps.

### 4. Control Center & Notifications (`default/notifications/`)
- **Notification Daemon:** Built-in `org.freedesktop.Notifications` implementation. Replaces `swaync` or `dunst`.
- **Toast Popups:** Top right toasts with app icons, summaries, body text, and interactive action buttons. Pauses on hover.
- **Control Center Panel:** Slides in from the right edge with concave morphing corners.
- **Quick Toggles:**
  - Do Not Disturb (DND) toggle.
  - Native Bluetooth manager with scan, power, and device connect buttons.
  - Microphone mute toggle and volume slider.
- **Audio Output Switcher:** Select any PipeWire audio sink with a single click.
- **MPRIS Media Player:** Album artwork, song details, clickable seekbar (`mm:ss`), and full playback controls.

### 5. Calendar Dropdown (`default/calendar/`)
- Anchored to the topbar clock.
- 42-day month grid with ISO 8601 calendar weeks (CW 1-53) and Mo-Su columns.
- Highlights today and selected dates; displays colored dots on days with upcoming events.
- Filterable agenda list showing start time, event title, and colored calendar badge.
- Decoupled secrets management via KeePassXC or `secret-tool`.

### 6. Volume OSD (`default/osd/VolumeOsd.qml`)
- Floating pill overlay centered at the bottom of the screen.
- Listens to PipeWire volume changes directly (`wpctl`, keyboard keys, mouse wheel).
- Displays volume percentage, animated level bar, and dynamic audio icon.
- Smooth fade-out after 1.5 seconds of inactivity. Input-transparent (`Region { item: null }`).

### 7. Power Menu (`default/power_menu/PowerMenu.qml`)
- Slides in from top-left, seamlessly connecting to the topbar and screen edge via concave curves.
- Options: Suspend (`systemctl suspend`), Log out, Reboot, Power off (`hyprshutdown`).
- Keyboard navigable with Escape to close.

### 8. App Launcher (`default/app_launcher/AppLauncher.qml`)
- Slides up centered above the bottom margin.
- Search filter for desktop applications with icons and category tags.

### 9. Screen Borders & Concave Corners (`default/Border.qml`)
- 12px margins around bottom, left, and right screen edges.
- 4 concave corner transitions connecting the shell frame smoothly into Hyprland client windows.

---

## Hyprland Integration (`~/.config/hypr/hyprland.conf` or `hyprland.lua`)

Example Lua integration:

```lua
-- Autostart
hl.on("hyprland.start", function()
    hl.exec_cmd("quickshell -d & keepassxc & hyprpaper")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
end)

-- IPC Keybindings
local menu = "qs ipc call applauncher toggle"
local powerMenu = "qs ipc call powermenu toggle"
local notificationPanel = "qs ipc call notifications toggle"
local calendar = "qs ipc call calendar toggle"

hl.bind(mainMod .. " + " .. "R", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + " .. "Escape", hl.dsp.exec_cmd(powerMenu))
hl.bind(mainMod .. " + " .. "I", hl.dsp.exec_cmd(notificationPanel))
hl.bind(mainMod .. " + " .. "C", hl.dsp.exec_cmd(calendar))

-- Match rounding
hl.config({
    decoration = {
        rounding = 5,
        rounding_power = 1,
    },
})
```

---

## Useful Commands

```bash
# Start quickshell as background daemon
quickshell -d

# Show running instances
quickshell list

# View live logs
quickshell log -f

# IPC calls
qs ipc call powermenu toggle
qs ipc call applauncher toggle
qs ipc call notifications toggle
qs ipc call notifications toggleDnd
qs ipc call notifications dismissAll
qs ipc call calendar toggle
qs ipc call calendar today
qs ipc call osd show

# Clear in-RAM calendar secrets cache
python3 ~/.config/quickshell/default/scripts/fetch_calendar.py --clear-session-secrets
```

---

## License

MIT License.
