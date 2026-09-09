# Quickshell Desktop-Konfiguration

[English](README.md) | [Deutsch](README.de.md)

Desktop-Shell-Setup für Hyprland auf Basis von [Quickshell](https://quickshell.outfoxxed.me/) mit der Rosé Pine Moon Farbpalette. Bietet organisch morphende Menüs und Panels mit konkaven Eckenübergängen, nativen PipeWire-Audio-Umschalter, MPRIS-Mediensteuerung, Benachrichtigungs-Daemon, interaktiven Monatskalender und System-Tray mit DBusMenu-Unterstützung.

---

## Installation und Einrichtung

### 1. Voraussetzungen und Abhängigkeiten

Installiere die benötigten Pakete auf deinem System (Paketnamen für Arch Linux / CachyOS):

- **Shell Engine:** `quickshell` (oder `quickshell-git`)
- **Qt 6 Module:** `qt6-base`, `qt6-declarative`, `qt6-svg`
- **Audio & Medien:** `pipewire`, `wireplumber`, `libpipewire`, `pactl` (aus `libpulse`)
- **Secret Service (für Kalender):** `libsecret` (stellt `secret-tool` bereit) und ein Secret-Service-Provider wie `keepassxc`
- **Schriften & Icons:** `ttf-jetbrains-mono-nerd`, `rose-pine-moon-icons` (oder beliebige Nerd Font / Icon-Themes)
- **Optional / Empfohlen:** `bluez`, `bluez-utils`, `lm_sensors`, `grim`

### 2. Repository klonen

Klone das Repository in dein Konfigurationsverzeichnis:

```bash
git clone https://github.com/<dein-user>/quickshell.git ~/.config/quickshell
```

Der Haupteinstiegspunkt liegt unter `~/.config/quickshell/default/shell.qml`.

### 3. Notwendige und empfohlene Anpassungen

Passe vor dem ersten Start folgende Stellen an deine Hardware und dein System an:

1. **Distributions-Logo in der TopBar (`default/bar/Bar.qml`):**
   - Die linke Taste sucht standardmäßig nach `/usr/share/icons/cachyos.svg`.
   - Bei Arch, Fedora oder anderen Distributionen: Passe den Pfad zu deinem Distro-SVG an oder verwende ein Nerd-Font-Icon.

2. **Eckenrundung und Maße (`default/theme/Theme.qml`):**
   - `rounding: 5` sollte mit deiner Hyprland-Einstellung `decoration.rounding` übereinstimmen.
   - `barHeight: 34` und `borderThickness: 12` steuern Leistenhöhe und Bildschirmränder.

3. **Audio Soft-Mixer (WirePlumber):**
   - Falls dein Monitor (z. B. über DisplayPort / HDMI) keine Hardware-Stummschaltung unterstützt, erstelle `~/.config/wireplumber/wireplumber.conf.d/50-alsa-soft-mixer.conf`:
     ```spa-json
     monitor.alsa.rules = [
       {
         matches = [ { node.name = "~alsa_output.*" } ]
         actions = { update-props = { api.alsa.soft-mixer = true } }
       }
     ]
     ```

4. **Qt 6 Icon-Theme (`~/.config/qt6ct/qt6ct.conf`):**
   - Setze `icon_theme=rose-pine-moon-icons`, damit Tray- und App-Icons korrekt aufgelöst werden.

---

## Kalender-Konfiguration und Secrets

Das Kalender-Dropdown liest iCal-Feeds (`.ics`) von Google Calendar, Nextcloud oder beliebigen iCalendar-URLs. Um zu verhindern, dass private URLs und Zugriffs-Token in Git landen, sind Konfiguration und Geheimnisse entkoppelt.

### 1. Kalender-Konfiguration anlegen

Kopiere die Beispiel-Konfiguration:

```bash
cp ~/.config/quickshell/default/calendar/calendars.example.json ~/.config/quickshell/default/calendar/calendars.json
```

`default/calendar/calendars.json` wird von Git ignoriert. Passe die Liste an deine Kalender an:

```json
[
  {
    "name": "Feiertage",
    "url": "https://calendar.google.com/calendar/ical/de.german%23holiday%40group.v.calendar.google.com/public/basic.ics",
    "color": "#c4a7e7",
    "enabled": true
  },
  {
    "name": "Arbeit",
    "keyring": "google-calendar-work",
    "color": "#9ccfd8",
    "enabled": true
  },
  {
    "name": "Privat",
    "keyring": "google-calendar-private",
    "color": "#eb6f92",
    "enabled": true
  }
]
```

- Öffentliche Feeds: Direkte `url` angeben.
- Private Feeds: `url` weglassen und `keyring` mit einem Bezeichner setzen (z. B. `google-calendar-work`).

### 2. Secrets im Keyring / KeePassXC hinterlegen

Wähle eine der folgenden Methoden zur Speicherung der privaten `.ics`-URLs:

#### Option A: KeePassXC (Empfohlen)
1. In den KeePassXC-Einstellungen die **Secret-Service-Integration** aktivieren.
2. Einen Eintrag in der Datenbank anlegen:
   - **Titel:** Muss exakt dem `keyring`-Namen aus `calendars.json` entsprechen (z. B. `google-calendar-work`).
   - **Passwort** oder **URL:** Die geheime Google-Calendar iCal-URL einfügen (endet auf `.ics`).
3. Beim Start fragt der Kalender-Daemon das Secret einmalig pro Login-Sitzung ab und cacht es im flüchtigen Arbeitsspeicher (`$XDG_RUNTIME_DIR/quickshell/`, tmpfs) mit Rechten 0600. Nachfolgende Abfragen laufen ohne Passwort-Prompt.

#### Option B: Terminal via `secret-tool`
Speichere das Secret direkt in den FreeDesktop Secret Service Keyring:

```bash
secret-tool store --label="Google Calendar Arbeit" Title google-calendar-work
# Bei Aufforderung die private .ics URL eingeben
```

Abfrage testen:

```bash
secret-tool lookup Title google-calendar-work
```

#### Option C: Lokale Overrides-Datei
Erstelle `~/.config/quickshell/default/calendar/calendars.local.json` (wird von Git ignoriert):

```json
{
  "Arbeit": "https://calendar.google.com/calendar/ical/<privates-token>/basic.ics",
  "Privat": "https://calendar.google.com/calendar/ical/<privates-token>/basic.ics"
}
```

---

## Verzeichnisstruktur

```text
~/.config/quickshell/
├── default/
│   ├── shell.qml                # Haupteinstiegspunkt (ShellRoot)
│   ├── Border.qml               # 12px Ränder und 4 konkave Innenecken
│   ├── bar/
│   │   ├── Bar.qml              # 34px TopBar
│   │   ├── Workspaces.qml       # 10 Workspaces mit aktiver Unterstreichung
│   │   ├── SysInfo.qml          # CPU, RAM und Temperaturüberwachung
│   │   ├── Volume.qml           # PipeWire Lautstärke-Widget
│   │   ├── Clock.qml            # Uhrzeit und Datum (Klick öffnet Kalender)
│   │   ├── Tray.qml             # System-Tray (DBus StatusNotifierItem)
│   │   ├── NotificationButton.qml # Glocken-Icon mit Unread-Badge und DND
│   │   └── Separator.qml        # Trennelemente
│   ├── tray/
│   │   ├── TrayMenu.qml         # Themed Tray-Menü mit Morphen und Submenüs
│   │   ├── TrayMenuState.qml    # Singleton für Tray-Status und Position
│   │   └── qmldir               # QML-Modulregistrierung
│   ├── calendar/
│   │   ├── CalendarDropdown.qml # Monatskalender und Termin-Agenda
│   │   ├── CalendarState.qml    # Kalender-Status und Sync-Verwaltung
│   │   ├── calendars.example.json # Neutrale Konfigurationsvorlage
│   │   ├── calendars.json       # Lokale Kalenderliste (gitignored)
│   │   └── qmldir               # QML-Modulregistrierung
│   ├── notifications/
│   │   ├── NotificationState.qml # DBus Notification-Server Daemon
│   │   ├── NotificationPanel.qml # Slide-in Kontrollzentrum (MPRIS, Toggles, Historie)
│   │   ├── NotificationPopup.qml # Toast-Popups oben rechts
│   │   ├── NotificationCard.qml  # Benachrichtigungskarte mit Aktionen
│   │   ├── MprisPlayerWidget.qml # MPRIS-Player mit Artwork und Seekbar
│   │   ├── AudioControlWidget.qml # PipeWire Sink-Switcher und Mic-Steuerung
│   │   ├── BluetoothWidget.qml  # Bluetooth Schnellschalter und Gerätemanager
│   │   └── qmldir               # QML-Modulregistrierung
│   ├── power_menu/
│   │   ├── PowerMenu.qml        # Energie-Menü (oben links, slide-in)
│   │   ├── PowerMenuState.qml   # Power-Menü Singleton
│   │   └── qmldir               # QML-Modulregistrierung
│   ├── app_launcher/
│   │   ├── AppLauncher.qml      # App-Launcher (unten zentriert, slide-up)
│   │   ├── AppLauncherState.qml # App-Launcher Singleton
│   │   └── qmldir               # QML-Modulregistrierung
│   ├── osd/
│   │   ├── OsdState.qml         # PipeWire Lautstärke-Listener
│   │   ├── VolumeOsd.qml        # Zentriertes Pill-OSD für Lautstärke und Mute
│   │   └── qmldir               # QML-Modulregistrierung
│   ├── components/
│   │   └── ConcaveCurves.qml    # ShapePath-Komponente für konkave Rundungen
│   ├── theme/
│   │   ├── Colors.qml           # Rosé Pine Moon Farbpalette
│   │   ├── Theme.qml            # Maße, Eckenradien und Rahmen
│   │   └── qmldir               # Theme-Singleton-Registrierung
│   └── scripts/
│       ├── cycle_audio.py       # Audio-Sink Durchwechsel-Skript (Mittelklick)
│       └── fetch_calendar.py    # iCal-Parser und Cache-Daemon
├── README.md                    # Englische Dokumentation
└── README.de.md                 # Deutsche Dokumentation
```

---

## Komponenten im Überblick

### 1. TopBar (`default/bar/Bar.qml`)
- **Höhe:** 34px (`exclusiveZone: 34`, reserviert Platz in Hyprland).
- **Links:** Distributions-Logo (Klick schaltet Power-Menü um) und System-Tray.
- **Mitte:** 10 Workspaces mit Fensterstatus und aktiver Unterstreichung.
- **Rechts:** SysInfo (CPU, RAM, Sensoren), Lautstärke, Uhrzeit und Benachrichtigungs-Glocke.
- **Klick-Verhalten:** Klicks auf freie Flächen der Bar schließen offene Menüs.

### 2. System-Tray (`default/bar/Tray.qml` & `default/tray/`)
- Verwendet StatusNotifierItem (SNI) über DBus.
- Ersetzt native Qt-Popups durch ein voll thematisierbares QML-Menü in Rosé Pine Moon Farben.
- Nahtloses Morphen aus der TopBar mit konkaven Kurven direkt am jeweiligen Icon.
- Klick-Durchlässigkeit auf der Leiste: Klicks auf andere Tray-Icons öffnen sofort das neue Menü; erneuter Klick auf dasselbe Icon schließt das Menü.
- Unterstützt Untermenüs, Checkboxen, Trennstriche und dynamische Breitenberechnung.

### 3. Audio & Lautstärke (`default/bar/Volume.qml`)
- **Linksklick:** Öffnet Audio-Bereich im Kontrollzentrum.
- **Rechtsklick:** Schaltet Stummschaltung um (Mute).
- **Mittelklick:** Wechselt zum nächsten Audio-Ausgabegerät via `default/scripts/cycle_audio.py`.
- **Mausrad:** Ändert die Lautstärke in 2%-Schritten.

### 4. Kontrollzentrum & Benachrichtigungen (`default/notifications/`)
- **Notification-Server:** Nativer DBus-Daemon (`org.freedesktop.Notifications`). Ersetzt `swaync` oder `dunst`.
- **Toast-Popups:** Popups oben rechts mit App-Icon, Betreff, Text und Aktions-Buttons. Pausiert bei Hover.
- **Kontrollzentrum-Panel:** Fährt von rechts ein mit morphenden konkaven Kurven.
- **Quick-Toggles:**
  - Nicht Stören (DND) Schalter.
  - Nativer Bluetooth-Manager mit Gerätesuche, Power und Connect.
  - Mikrofon-Mute und Lautstärkeregler.
- **Audio-Sink-Umschalter:** Direkte Auswahl des aktiven Ausgabegeräts mit einem Klick.
- **MPRIS-Player:** Album-Cover, Titel, klickbare Timeline (`mm:ss`) und Mediensteuerung.

### 5. Kalender-Dropdown (`default/calendar/`)
- Angedockt an die Uhrzeit der TopBar.
- 42-Tage-Monatsraster mit ISO 8601 Kalenderwochen (KW 1-53) und Mo-So Spalten.
- Heutiger und ausgewählter Tag hervorgehoben; Termintage tragen Farbpunkte.
- Termin-Agenda mit Startzeit, Titel und farbiger Kalender-Kennzeichnung.
- Sichere Secrets-Verwaltung über KeePassXC oder `secret-tool`.

### 6. Lautstärke-OSD (`default/osd/VolumeOsd.qml`)
- Zentriertes Pill-Overlay am unteren Bildschirmrand.
- Reagiert sofort auf Lautstärke-Änderungen in PipeWire (`wpctl`, Tasten, Mausrad).
- Zeigt Prozentwert, animierten Balken und dynamisches Lautsprecher-Icon an.
- Blendet nach 1,5 Sekunden Inaktivität aus. Vollständig klickdurchlässig (`Region { item: null }`).

### 7. Power-Menü (`default/power_menu/PowerMenu.qml`)
- Fährt oben links ein und schließt über konkave Kurven bündig an Leiste und Rand an.
- Aktionen: Bereitschaft (`systemctl suspend`), Abmelden, Neustart, Herunterfahren (`hyprshutdown`).
- Mit Tastatur bedienbar; Schließen mit Escape.

### 8. App-Launcher (`default/app_launcher/AppLauncher.qml`)
- Fährt unten zentriert über dem Bildschirmrand nach oben.
- Durchsucht Desktop-Anwendungen mit Icons und Kategorien.

### 9. Bildschirmränder & Konkave Innenecken (`default/Border.qml`)
- 12px Ränder unten, links und rechts.
- 4 konkave Ecken verbinden die Außenränder fließend mit den Hyprland-Fenstern.

---

## Hyprland-Integration (`~/.config/hypr/hyprland.conf` oder `hyprland.lua`)

Beispiel-Integration für Hyprland (Lua):

```lua
-- Autostart
hl.on("hyprland.start", function()
    hl.exec_cmd("quickshell -d & keepassxc & hyprpaper")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
end)

-- IPC Tastenkombinationen
local menu = "qs ipc call applauncher toggle"
local powerMenu = "qs ipc call powermenu toggle"
local notificationPanel = "qs ipc call notifications toggle"
local calendar = "qs ipc call calendar toggle"

hl.bind(mainMod .. " + " .. "R", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + " .. "Escape", hl.dsp.exec_cmd(powerMenu))
hl.bind(mainMod .. " + " .. "I", hl.dsp.exec_cmd(notificationPanel))
hl.bind(mainMod .. " + " .. "C", hl.dsp.exec_cmd(calendar))

-- Rundung synchronisieren
hl.config({
    decoration = {
        rounding = 5,
        rounding_power = 1,
    },
})
```

---

## Nützliche Befehle

```bash
# Quickshell als Hintergrund-Daemon starten
quickshell -d

# Laufende Instanzen anzeigen
quickshell list

# Live-Logs ansehen
quickshell log -f

# IPC Aufrufe
qs ipc call powermenu toggle
qs ipc call applauncher toggle
qs ipc call notifications toggle
qs ipc call notifications toggleDnd
qs ipc call notifications dismissAll
qs ipc call calendar toggle
qs ipc call calendar today
qs ipc call osd show

# Flüchtigen Kalender-Secrets-Cache im RAM leeren
python3 ~/.config/quickshell/default/scripts/fetch_calendar.py --clear-session-secrets
```

---

## Lizenz

MIT License.
