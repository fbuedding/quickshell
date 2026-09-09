# Quickshell Desktop Configuration

[English](README.md) | [Deutsch](README.de.md)

Desktop shell setup for Hyprland built on [Quickshell](https://quickshell.outfoxxed.me/) with the Rosé Pine Moon palette. Features organic morphing panels with concave corner transitions, native PipeWire audio switcher, MPRIS media control, notification daemon, interactive month calendar, and custom DBusMenu system tray.

---

## High-Level Feature Overview

This shell acts as a unified desktop environment for Hyprland, replacing several standalone background daemons and status bars with a single, resource-efficient Qt 6/QML process.

### What the Shell Provides

1. **TopBar:**
   - 34px horizontal bar with exclusive zone reservation.
   - 10 Workspaces with active window indicators and current workspace underline.
   - Live hardware monitor: CPU usage (`/proc/stat`), RAM utilization (`/proc/meminfo`), and CPU temperature (`sensors`).
   - PipeWire volume widget with audio sink name and scroll-wheel volume adjustment.
   - Clock with weekday and time; clicking opens the calendar dropdown.
   - Notification button with unread count badge and Do Not Disturb (DND) state.
   - Distribution button toggling the power menu.

2. **Custom Themed System Tray:**
   - DBus StatusNotifierItem (SNI) implementation for background apps (Steam, Heroic, KeePassXC, Bluetooth, etc.).
   - Replaces unstylable native Qt popup menus with custom QML menus styled in the Rosé Pine Moon palette.
   - Morphs seamlessly from the topbar with concave curves anchored to the active icon.
   - Transparent topbar input mask: other tray icons remain fully hoverable and clickable while a menu is open.
   - Nested submenus, checkable items, separators, and dynamic width calculation.

3. **Slide-In Control Center & Notification Daemon:**
   - Full DBus `org.freedesktop.Notifications` implementation. Replaces external notification daemons.
   - Interactive toast popups (top right) with action buttons and hover pause.
   - Slide-in side panel from the right screen edge with concave corner morphing.
   - Quick toggles row: Bluetooth manager, Do Not Disturb, Microphone mute, and Theme switcher.
   - Integrated Bluetooth manager: adapter toggle, device scan, and one-click connect/disconnect.
   - Audio output sink switcher: select output devices directly without external tools.
   - Microphone control: live input level slider and toggle.
   - MPRIS media player: album art, song title, artist, seekbar (`mm:ss`), and playback controls.
   - Notification history with dismiss and clear-all actions.

4. **Interactive Calendar & Agenda:**
   - Month view with a 42-day grid and ISO 8601 calendar weeks (CW 1-53).
   - Highlights current day and selected date; dot indicators for days with events.
   - Agenda list displaying start time, summary, and colored calendar category badges.
   - Background Python daemon fetching `.ics` feeds directly from Google Calendar or Nextcloud.
   - Secure keyring integration via KeePassXC or `secret-tool` to prevent exposing private tokens.

5. **Volume & Mute OSD:**
   - Centered floating pill overlay at the bottom of the screen.
   - Reacts automatically via PipeWire service to volume keys, `wpctl`, and bar scrolling.
   - Visual volume percentage, dynamic speaker/mute icon, and animated level bar.
   - Input-transparent (`mask: Region { item: null }`), never steals mouse focus or blocks windows.

6. **Power Menu:**
   - Top-left slide-in panel connecting into the bar and screen edge via concave curves.
   - Options for Suspend (`systemctl suspend`), Logout, Reboot, and Shutdown (`hyprshutdown`).
   - Keyboard accessible with Escape to dismiss.

7. **App Launcher:**
   - Bottom-centered slide-up application menu with real-time desktop entry search and icon support.

8. **Outer Screen Margins & Concave Corners:**
   - 12px borders along the bottom, left, and right screen edges.
   - 4 concave corner transitions connecting the shell frame into Hyprland window tiling areas.

### Replaced External Tools

Running this shell eliminates the need for:
- `waybar` or `polybar` (Status bar)
- `swaync`, `dunst`, or `mako` (Notification daemon and notification center)
- `swayosd`, `avizo`, or `wob` (Volume OSD)
- `wlogout` or power scripts (Power menu)
- `rofi` or `wofi` (App launcher)
- `blueman-applet` or `blueman-manager` (Bluetooth status and device connection)
- `pavucontrol` or `pwvucontrol` for daily audio output switching

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

## Localization (i18n)

The shell automatically adapts to your system language based on your locale (`Qt.locale().name` / `$LANG`). It currently ships with English (`en`) and German (`de`).

### Overriding Language
To force a specific language regardless of your system locale, start Quickshell with the `QS_LANG` environment variable:

```bash
QS_LANG=en quickshell -d
```

### Adding a New Language
To add a new language (e.g. French `fr`, Spanish `es`, Italian `it`):
1. Open `default/i18n/I18n.qml`.
2. Copy the `"en"` dictionary inside the `locales` property.
3. Rename the key to your language code (e.g. `"fr"`).
4. Translate the string values. Any missing keys automatically fall back to English.
5. Month names and weekdays format automatically via `Qt.locale()`.

### Time and Date Formats
Format strings are automatically set by the active language to sensible defaults:
- **German (`de`):** 24-hour clock (`HH:mm`, e.g. `18:30`), date header with day first (`dddd, d. MMMM`).
- **English (`en`):** 12-hour clock (`h:mm AP`, e.g. `6:30 PM`), date header with month first (`dddd, MMMM d`).

If desired, formats can be customized per language in `default/i18n/I18n.qml` or overridden globally:
```bash
QS_CLOCK_FORMAT="HH:mm:ss" QS_DATE_FORMAT="ddd, MMM d" quickshell -d
```
Or directly in `default/i18n/I18n.qml` (`clockFormatOverride: "HH:mm:ss"`).

---

## Theme System and Switcher

The shell supports instant theme switching at runtime across all components without restarting Quickshell.

### Included Themes
- `rose-pine-moon` (Rosé Pine Moon - default)
- `tokyo-night` (Tokyo Night)
- `catppuccin-mocha` (Catppuccin Mocha)

### Switching Themes
- **Control Center:** Click the theme toggle button in the quick toggles row of the notification panel.
- **Quickshell IPC:**
  ```bash
  qs ipc call theme next                # Cycle to the next theme
  qs ipc call theme set tokyo-night     # Switch directly to a theme
  qs ipc call theme current             # Print the active theme key
  qs ipc call theme list                # List available themes
  ```
- **Hyprland Keybinding:**
  ```ini
  bind = SUPER, T, exec, qs ipc call theme next
  ```

### State Persistence
The active theme is automatically saved to `~/.config/quickshell/current_theme` and reloaded on startup.

### External Listener Hook (`on_theme_change.sh`)
External programs (such as Hyprland window borders, terminal emulators, or wallpaper daemons) can react to theme changes via a hook script:
1. Copy the example hook script:
   ```bash
   cp ~/.config/quickshell/default/scripts/on_theme_change.sh.example ~/.config/quickshell/on_theme_change.sh
   chmod +x ~/.config/quickshell/on_theme_change.sh
   ```
2. When the theme changes, Quickshell executes `~/.config/quickshell/on_theme_change.sh <theme-name>`.
3. The provided example updates Hyprland active border colors dynamically via `hyprctl keyword general:col.active_border`. External tools can also monitor `~/.config/quickshell/current_theme` using `inotifywait` or systemd path units.

### Gotchas and Integration Tips
- **Window Borders:** Window border colors are managed by Hyprland, not Quickshell. Use `on_theme_change.sh` to keep Hyprland active border colors synchronized with the shell palette.
- **Icon Themes and GTK/Qt Apps:** System tray and app launcher icons follow the installed system icon theme (e.g. `rose-pine-moon-icons` or `Papirus`). Quickshell palette switching adjusts the shell UI, but does not alter standalone GTK/Qt application theme configurations unless scripted in `on_theme_change.sh`.
- **Adding Custom Themes:** Open `default/theme/Colors.qml`, add your theme key to `availableThemes`, and define your color palette dictionary in `themes`.

---

## Hyprland Integration

### 1. Traditional Syntax (`~/.config/hypr/hyprland.conf`)

Add these lines to your `hyprland.conf`:

```ini
# Autostart Quickshell daemon
exec-once = quickshell -d
exec-once = keepassxc
exec-once = systemctl --user start hyprpolkitagent

# Corner rounding synchronization
decoration {
    rounding = 5
}

# Keybindings for Quickshell IPC
bind = SUPER, R, exec, qs ipc call applauncher toggle
bind = SUPER, Escape, exec, qs ipc call powermenu toggle
bind = SUPER, I, exec, qs ipc call notifications toggle
bind = SUPER, C, exec, qs ipc call calendar toggle
bind = SUPER, T, exec, qs ipc call theme next

# Disable animations on static border overlays
layerrule = noanim, quickshell-corners
```

### 2. Modern Lua Syntax (`~/.config/hypr/hyprland.lua`, Hyprland 0.55+)

If you use the Lua configuration format:

```lua
-- Autostart
hl.on("hyprland.start", function()
    hl.exec_cmd("quickshell -d & keepassxc")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
end)

-- Keybindings
local launcher = "qs ipc call applauncher toggle"
local powerMenu = "qs ipc call powermenu toggle"
local controlCenter = "qs ipc call notifications toggle"
local calendar = "qs ipc call calendar toggle"
local themeNext = "qs ipc call theme next"

hl.bind(mainMod .. " + " .. "R", hl.dsp.exec_cmd(launcher))
hl.bind(mainMod .. " + " .. "Escape", hl.dsp.exec_cmd(powerMenu))
hl.bind(mainMod .. " + " .. "I", hl.dsp.exec_cmd(controlCenter))
hl.bind(mainMod .. " + " .. "C", hl.dsp.exec_cmd(calendar))
hl.bind(mainMod .. " + " .. "T", hl.dsp.exec_cmd(themeNext))

-- Corner rounding synchronization
hl.config({
    decoration = {
        rounding = 5,
        rounding_power = 1,
    },
})
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
│   │   ├── Colors.qml           # Multi-theme palettes and switcher logic
│   │   ├── Theme.qml            # Dimensions, roundings, and borders
│   │   └── qmldir               # Theme singleton registry
│   └── scripts/
│       ├── cycle_audio.py       # Middle-click audio sink cycle script
│       ├── fetch_calendar.py    # iCal/Google calendar parser and cache daemon
│       └── on_theme_change.sh.example # Example hook script for theme changes
├── README.md                    # English documentation
└── README.de.md                 # German documentation
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

# Theme switching
qs ipc call theme next
qs ipc call theme set tokyo-night
qs ipc call theme current
qs ipc call theme list

# Clear in-RAM calendar secrets cache
python3 ~/.config/quickshell/default/scripts/fetch_calendar.py --clear-session-secrets
```

---

## Acknowledgments and Credits

This configuration is based on and inspired by:
- [Caelestia shell rebuild tutorial](https://github.com/kartik317/Caelestia_shell_rebuild_tutorial) by kartik317 (used as the foundational codebase)
- [Caelestia Shell](https://github.com/caelestia-dots/shell) (original aesthetic design, organic concave curves, and desktop layout)

---

## License

MIT License.
