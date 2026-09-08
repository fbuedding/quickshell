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
│   │   └── Separator.qml        # Trennelemente
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
- **Mitte:** 10 Workspaces mit aktiver Unterstreichung und Fenstermarkierung.
- **Rechts:**
  - **SysInfo:** CPU-Last (via `/proc/stat`), RAM-Verbrauch (via `/proc/meminfo`), CPU-Temperatur (via `sensors`).
  - **Volume:** Lautstärkeanzeige mit Audio-Gerätename.
  - **Clock:** Uhrzeit mit Wochentag.
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

### 5. Bildschirmränder & Konkave Innenecken (`default/Border.qml`)
- **Ränder:** 12px dicke Balken unten, links und rechts (`WlrLayer.Top`). Oben fungiert die TopBar als Begrenzung.
- **Innenecken:** Ein vollkommen klickdurchlässiges Overlay (`quickshell-corners`) spannt die 4 konkaven Übergänge auf:
  - Oben links, oben rechts, unten links, unten rechts.
  - Verbindet die Leisten fließend mit dem Hyprland-Fensterbereich.

---

### 6. Design & Metriken (`default/theme/`)

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
}
```

#### [`Colors.qml`](default/theme/Colors.qml)
Rosé Pine Moon Farbpalette:
- Hintergrund (`colBg`): `#232136`
- Vordergrund (`colFg`): `#e0def4`
- Overlay (`colBlack`): `#393552`
- Akzente: Rose (`colCyan`), Gold (`colYellow`), Pine (`colGreen`), Foam (`colBlue`), Iris (`colPurple`), Love (`colRed`).

---

## 🔧 Hyprland-Integration (`~/.config/hypr/hyprland.lua`)

In Hyprland (ab 0.55 Lua-Syntax) ist Quickshell wie folgt eingebunden:

```lua
-- Autostart
hl.on("hyprland.start", function()
    hl.exec_cmd("hyprpaper & firefox & quickshell & swaync & keepassxc")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
end)

-- AppLauncher & PowerMenu
local menu = "qs ipc call applauncher toggle"
local powerMenu = "qs ipc call powermenu toggle"

hl.bind(mainMod .. " + " .. "R", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + " .. "Escape", hl.dsp.exec_cmd(powerMenu))

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

# Live-Logs ansehen
tail -f /run/user/1000/quickshell/by-id/*/log.log
```
