# Quickshell Desktop Configuration

Elegantes Desktop-Shell-Setup für **Hyprland** auf Basis von [Quickshell](https://quickshell.outfoxxed.me/) mit **Rosé Pine Moon**-Theme.

---

## 📁 Struktur

```text
~/.config/quickshell/
├── default/
│   ├── shell.qml                # Einstiegspunkt (ShellRoot, lädt alle Komponenten)
│   ├── Border.qml               # 12px Bildschirmränder & 4 konkave Innenecken
│   ├── bar/
│   │   ├── Bar.qml              # Horizontale 34px TopBar
│   │   ├── Workspaces.qml       # 10 Workspaces (zentriert)
│   │   ├── SysInfo.qml          # CPU, RAM & Temperaturanzeige
│   │   ├── Volume.qml           # Lautstärke-Widget (WirePlumber)
│   │   ├── Clock.qml            # Uhrzeit & Datum
│   │   ├── Tray.qml             # System-Tray (StatusNotifierItem & QsMenu)
│   │   ├── NotificationButton.qml # Glocken-Button mit Unread-Badge & DND
│   │   └── Separator.qml        # Trennelemente
│   ├── notifications/
│   │   ├── NotificationState.qml # Singleton (NotificationServer-Daemon & State)
│   │   ├── NotificationPanel.qml # Slide-in Kontrollzentrum (MPRIS + Notif-Historie)
│   │   ├── NotificationPopup.qml # Toast-Popups oben rechts
│   │   ├── NotificationCard.qml  # Benachrichtigungskarte mit Aktionen
│   │   ├── MprisPlayerWidget.qml # MPRIS-Player mit Cover-Art & Timeline
│   │   └── qmldir               # QML-Modulregistrierung
│   ├── power_menu/
│   │   ├── PowerMenu.qml        # Energie-Menü (oben links, slide-in)
│   │   ├── PowerMenuState.qml   # Singleton-Statusverwaltung
│   │   └── qmldir               # QML-Modulregistrierung
│   ├── app_launcher/
│   │   ├── AppLauncher.qml      # App-Launcher (unten zentriert, slide-up)
│   │   ├── AppLauncherState.qml # Singleton-Statusverwaltung
│   │   └── qmldir               # QML-Modulregistrierung
│   ├── components/
│   │   └── ConcaveCurves.qml    # Universelle konkave Kurven-Komponente (ShapePath)
│   ├── theme/
│   │   ├── Colors.qml           # Rosé Pine Moon Farbpalette
│   │   ├── Theme.qml            # Globale Metriken (rounding = 5, Border-Dicken)
│   │   └── qmldir               # Singleton-Registrierung (Colors, Theme)
│   └── scripts/
│       └── cycle_audio.py       # Skript zum Durchwechseln des Audio-Ausgabegeräts
└── README.md                    # Diese Dokumentation
```

---

## 🖥️ Komponenten im Detail

### 1. TopBar (`default/bar/Bar.qml`)
- **Höhe:** 34px (`exclusiveZone: 34`, reserviert Platz in Hyprland).
- **Links:** CachyOS-Symbol (`/usr/share/icons/cachyos.svg` oder NerdFont-Fallback).
  - Linksklick öffnet/schließt das Power-Menü (`PowerMenuState.toggle()`).
  - Wird visuell hervorgehoben, solange das Menü offen ist.
  - **System Tray (`Tray.qml`):** StatusNotifierItem (SNI) für Hintergrund-Apps (Telegram, KeePassXC etc.) mit nativen Rechtsklick-Menüs (`QsMenuAnchor`).
- **Mitte:** 10 Workspaces mit aktiver Unterstreichung und Fenstermarkierung.
- **Rechts:**
  - **SysInfo:** CPU-Last (via `/proc/stat`), RAM-Verbrauch (via `/proc/meminfo`), CPU-Temperatur (via `sensors`).
  - **Volume:** Lautstärkeanzeige mit Audio-Gerätename.
  - **Clock:** Uhrzeit mit Wochentag.
  - **Notification-Button (`NotificationButton.qml`):** Glocken-Icon mit Unread-Badge-Punkt. Linksklick toggelt Kontrollzentrum, Rechtsklick schaltet DND (Do Not Disturb) um.
- **Klick-Verhalten:** Klicks auf freie Flächen der TopBar schließen geöffnete Menüs.

---

### 2. Audio & Lautstärke (`default/bar/Volume.qml`)
| Aktion | Verhalten |
|---|---|
| **Linksklick** | Öffnet `pwvucontrol` (PipeWire Volume Control GUI) |
| **Rechtsklick** | Schaltet Stummschaltung um (`mute toggle`) |
| **Mittelklick** | Wechselt zum nächsten Audio-Ausgabegerät via [`default/scripts/cycle_audio.py`](scripts/cycle_audio.py) |
| **Mausrad** | Lautstärke in 2%-Schritten anpassen |

> [!NOTE]
> **WirePlumber Soft-Mixer Fix:**
> Manche Monitore (z. B. LG UltraGear über DisplayPort) unterstützen keinen Hardware-Mute.
> Die Lösung liegt in `~/.config/wireplumber/wireplumber.conf.d/50-alsa-soft-mixer.conf`:
> ```spa-json
> monitor.alsa.rules = [
>   {
>     matches = [ { node.name = "~alsa_output.*" } ]
>     actions = { update-props = { api.alsa.soft-mixer = true } }
>   }
> ]
> ```

---

### 3. Power-Menü (`default/power_menu/PowerMenu.qml`)
- **Position:** Oben links, schließt nahtlos (`topMargin: 0`) an die TopBar an.
- **Ecken-Design:**
  - **Oben rechts:** Konkave Kurve (`Theme.cornerRadius`) leitet weich in die TopBar über.
  - **Unten links:** Konkave Kurve (`Theme.cornerRadius`) leitet weich in den 12px linken Bildschirmrand über.
  - **Unten rechts:** Konvex abgerundet (`Theme.cornerRadius`).
  - **Oben links:** Bündig anliegend (Radius 0).
- **Tastaturfokus:** `WlrKeyboardFocus.OnDemand` (kein exklusiver Modal-Grab, Klicks auf TopBar und Desktop bleiben möglich).
- **Aktionen:** Bereitschaft (`systemctl suspend`), Abmelden, Neustart, Herunterfahren (über `hyprshutdown`).
- **Shortcuts & IPC:**
  - Hyprland-Keybind: `SUPER + Escape`
  - IPC: `qs ipc call powermenu toggle`

---

### 4. App-Launcher (`default/app_launcher/AppLauncher.qml`)
- **Position:** Unten zentriert, slidet über der 12px Bodenleiste nach oben.
- **Features:** Desktop-Entries-Suche mit App-Icons, Verlauf der zuletzt geöffneten Apps, Tastaturnavigation.
- **Shortcuts & IPC:**
  - Hyprland-Keybind: `SUPER + R`
  - IPC: `qs ipc call applauncher toggle`

---

### 5. Kontrollzentrum & Benachrichtigungen (`default/notifications/`)
- **Notification-Server (`NotificationState.qml`):** Nativer DBus-Daemon für `org.freedesktop.Notifications` (vollständiger Ersatz für `swaync`).
- **Toast-Popups (`NotificationPopup.qml` & [`NotificationCard.qml`](default/notifications/NotificationCard.qml)):** Auto-dismissing Toasts oben rechts mit App-Icon, Titel, Body und interaktiven Action-Buttons. Pausiert bei Maus-Hover.
- **Slide-in Kontrollzentrum (`NotificationPanel.qml`):**
  - Fährt weich von der rechten Bildschirmkante ein.
  - **Organisches Morphing:** Konkave Kurven (`Theme.cornerRadius`) leiten oben nahtlos in die TopBar und unten in den Bodenrand über.
  - **DND (Do Not Disturb):** Unterdrückt Toast-Popups temporär.
  - **Historie & Löschen:** Übersicht aller eingegangenen Benachrichtigungen inklusive Verwerfen- und „Alles Löschen“-Button.
- **MPRIS-Mediensteuerung ([`MprisPlayerWidget.qml`](default/notifications/MprisPlayerWidget.qml)):**
  - Vollwertige Mediensteuerung für Spotify, Firefox, MPV & Co.
  - Album-Artwork, Track-Titel, Künstler, klickbare Timeline-Seekbar (`mm:ss`) und Playback-Buttons (Play/Pause, Prev, Next, Shuffle, Loop).
- **Shortcuts & IPC:**
  - Hyprland-Keybind: `SUPER + I`
  - IPC: `qs ipc call notifications toggle`

---

### 6. Bildschirmränder & Konkave Innenecken (`default/Border.qml`)
- **Ränder:** 12px dicke Balken unten, links und rechts (`WlrLayer.Top`). Oben fungiert die TopBar als Begrenzung.
- **Innenecken:** Ein vollkommen klickdurchlässiges Overlay (`quickshell-corners`) spannt die 4 konkaven Übergänge auf:
  - Oben links, oben rechts, unten links, unten rechts.
  - Verbindet die Leisten fließend mit dem Hyprland-Fensterbereich.

---

### 7. Design & Metriken (`default/theme/`)

#### [`Theme.qml`](default/theme/Theme.qml)
Zentraler Singleton für konsistente Maße, synchronisiert mit Hyprland:
```qml
pragma Singleton
import QtQuick

QtObject {
    readonly property int rounding: 5        // Entspricht Hyprland decoration.rounding
    readonly property int cornerRadius: rounding
    readonly property int borderThickness: 12
    readonly property int barHeight: 34
    readonly property int borderWidth: 1
    readonly property color borderColor: "#393552"
}
```

#### [`Colors.qml`](default/theme/Colors.qml)
Rosé Pine Moon Farbpalette:
- Hintergrund (`colBg`): `#232136`
- Vordergrund (`colFg`): `#e0def4`
- Overlay (`colBlack`): `#393552`
- Akzente: Rose (`colCyan` / `colRose`), Gold (`colYellow` / `colGold`), Pine (`colGreen` / `colPine`), Foam (`colBlue` / `colFoam`), Iris (`colPurple` / `colIris`), Love (`colRed` / `colLove`).

---

## 🔧 Hyprland-Integration (`~/.config/hypr/hyprland.lua`)

In Hyprland (ab 0.55 Lua-Syntax) ist Quickshell wie folgt eingebunden:

```lua
-- Autostart
hl.on("hyprland.start", function()
    hl.exec_cmd("hyprpaper & firefox & quickshell & keepassxc")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
end)

-- Quickshell Module
local menu = "qs ipc call applauncher toggle"
local powerMenu = "qs ipc call powermenu toggle"
local notificationPanel = "qs ipc call notifications toggle"

hl.bind(mainMod .. " + " .. "R", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + " .. "Escape", hl.dsp.exec_cmd(powerMenu))
hl.bind(mainMod .. " + " .. "I", hl.dsp.exec_cmd(notificationPanel))

-- Rundung (wird von Quickshell Theme übernommen)
hl.config({
    decoration = {
        rounding = 5,
        rounding_power = 1,
    },
})
```

---

## 🎨 Wichtig: Qt 6 Icon-Theme Konfiguration

Da Quickshell eine **Qt 6**-Anwendung ist, verwendet es `QIcon::fromTheme(...)` zum Laden von App-Icons.
Wenn unter Hyprland `QT_QPA_PLATFORMTHEME=qt5ct:qt6ct` gesetzt ist, benötigt Qt die Information über das Icon-Theme:

1. **`~/.config/qt6ct/qt6ct.conf`** & **`~/.config/qt5ct/qt5ct.conf`**:
   ```ini
   [Appearance]
   icon_theme=rose-pine-moon-icons
   ```

2. **`~/.config/kdeglobals`**:
   ```ini
   [Icons]
   Theme=rose-pine-moon-icons
   ```

3. **Lokale Icon-Fallbacks**:
   Apps ohne mitgeliefertes Icon (z. B. `lstopo` / `hwloc`) können unter `~/.local/share/icons/hicolor/scalable/apps/<icon-name>.svg` hinterlegt werden.

---

## 🚀 Nützliche Befehle

```bash
# Quickshell im Hintergrund starten
qs -d

# Quickshell-Instanzen anzeigen
qs list

# IPC: Power-Menü umschalten
qs ipc call powermenu toggle

# IPC: App-Launcher umschalten
qs ipc call applauncher toggle

# IPC: Kontrollzentrum / Benachrichtigungen umschalten
qs ipc call notifications toggle

# IPC: DND umschalten oder Benachrichtigungen leeren
qs ipc call notifications toggleDnd
qs ipc call notifications dismissAll

# Live-Logs ansehen
tail -f /run/user/1000/quickshell/by-id/*/log.log
```

---

## 📋 Roadmap & TODO

Geordnet nach Auswirkungs- und Umsetzungspriorität:

### 🥇 Priorität 1: Direktes Desktop-Feintuning (High Impact / Quick Wins)
Kernelemente für ein geschliffenes Alltags-Desktop-Gefühl, die visuelles Feedback geben und bestehende Workflows vereinfachen:

- [ ] **Visuelles OSD (On-Screen Display für Lautstärke & Helligkeit)**
  - Zentriertes, dezentes Floating-Pill-Overlay auf dem Bildschirm.
  - Reagiert sofort auf Tasten wie `XF86AudioRaiseVolume`, `XF86AudioLowerVolume`, `XF86AudioMute` und Helligkeitstasten.
  - Zeigt Pegel-Balken, Prozentwert und dynamisches Icon an; fadet nach 1,5s weich aus.
  - *Ersetzt:* `swayosd`, `avizo`, `wob`.
- [ ] **Interaktiver Monatskalender bei Klick auf die Uhr**
  - Klick auf die Uhrzeit in der TopBar ([`default/bar/Clock.qml`](default/bar/Clock.qml)) öffnet ein Dropdown-Panel.
  - Monatsübersicht, hervorgehobener heutiger Tag, Wochentage und Kalenderwochen im Rosé-Pine-Stil.
- [ ] **Nativer Audio-Sink-Umschalter & Volume-Slider**
  - Schnelle Lautstärkeregelung per Schieberegler und 1-Klick-Umschaltung des Audio-Ausgabegeräts (z. B. Kopfhörer ↔ Lautsprecher ↔ Monitor).
  - Nativ über `Quickshell.Services.Pipewire` direkt im Kontrollzentrum oder als Popover an der Leiste.
  - *Ersetzt:* Das externe GTK-Tool `pwvucontrol` für alltägliche Pegelanpassungen.

---

### 🥈 Priorität 2: Ausbau des Kontrollzentrums (Quick Toggles)
Zusätzliche Schnellzugriffe im oberen Bereich des ausfahrbaren Kontrollzentrums ([`default/notifications/NotificationPanel.qml`](default/notifications/NotificationPanel.qml)):

- [ ] **Bluetooth Quick-Toggle & Gerätemanager**
  - Adapter an/aus und 1-Klick-Verbindungsaufbau zu gepaarten Audiogeräten (Kopfhörer, Headsets).
  - Vollständig nativ über `Quickshell.Bluetooth`.
  - *Ersetzt:* `blueman-applet` / `blueman-manager`.
- [ ] **Night Light / Blaulichtfilter-Toggle**
  - Schneller Umschalter für wärmere Bildschirm-Farbtemperaturen in den Abendstunden.
  - Anbindung an `hyprsunset` oder `wlsunset`.
- [ ] **Mikrofon-Stummschaltung (Mic Mute)**
  - Schnelle optische Statusanzeige und 1-Klick-Stummschaltung des Mikrofons via PipeWire.
- [ ] **Netzwerk / WLAN-Statusanzeige**
  - Schnelle Anzeige des aktuellen WLAN-Namens (SSID) bzw. Verbindungsstatus im Header des Panels.

---

### 🥉 Priorität 3: Größere System-Bausteine
Umfassendere Systemkomponenten zur Vereinheitlichung des Gesamtsystems:

- [ ] **Clipboard-Manager (Zwischenablage-Historie)**
  - Durchsuchbarer Verlauf kürzlich kopierter Texte und Bilder.
  - Integration entweder als separater Sub-Modus im App-Launcher (`SUPER + V`) oder als eigener Tab/Reiter.
  - Anbindung an `cliphist` / `wl-clipboard`.
- [ ] **Nativer Quickshell-Lockscreen**
  - Vollwertiger Sperrbildschirm im exakt selben Rosé-Pine-Design mit konkaven Elementen und Animationen.
  - Nativ realisierbar über `Quickshell.Wayland.WlSessionLock` und `Quickshell.Services.Pam`.
  - *Ersetzt:* `hyprlock` oder `swaylock`.
