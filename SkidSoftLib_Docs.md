# SkidSoft UI Library — Dokumentation

> **Version:** 1.0.0 | **Engine:** Roblox LuaU | **Executor:** Xeno, Synapse X, KRNL, etc.

---

## Inhaltsverzeichnis

1. [Installation](#1-installation)
2. [Window erstellen](#2-window-erstellen)
3. [Key System](#3-key-system)
4. [Tabs & Sections](#4-tabs--sections)
5. [Elemente / Controls](#5-elemente--controls)
   - [Toggle](#toggle)
   - [Slider](#slider)
   - [Dropdown](#dropdown)
   - [Button](#button)
   - [TextBox](#textbox)
   - [Label](#label)
   - [Divider](#divider)
6. [Notifications](#6-notifications)
7. [Flags System](#7-flags-system)
8. [Theme anpassen](#8-theme-anpassen)
9. [Destroy / Cleanup](#9-destroy--cleanup)
10. [Komplettes Beispiel](#10-komplettes-beispiel)
11. [Häufige Fehler](#11-häufige-fehler)

---

## 1. Installation

Lade die Library über `loadstring` und `HttpGet`. Füge das am **Anfang** deines Scripts ein:

```lua
local SS = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/DeinUser/SkidSoftLib/main/SkidSoftLib.lua"
))()
```

> Ersetze die URL mit deinem echten GitHub Raw Link nach dem Upload.

---

## 2. Window erstellen

```lua
local Window = SS:CreateWindow({
    Title     = "Mein Script",          -- (string)  Text oben links neben Logo
    Game      = "Rivals",               -- (string)  Spielname, z.B. "Rivals", "Blox Fruits"
    Version   = "v1.0",                -- (string)  Wird neben dem Spielnamen angezeigt
    ToggleKey = Enum.KeyCode.Insert,    -- (KeyCode) Taste zum Auf-/Zuklappen (Standard: Insert)

    KeySystem = false,                  -- (bool)    true = Key System aktivieren
    KeyConfig = { ... },               -- (table)   Key Einstellungen (siehe Abschnitt 3)
})
```

### Parameter Übersicht

| Parameter   | Typ       | Standard         | Beschreibung                            |
|-------------|-----------|------------------|-----------------------------------------|
| `Title`     | `string`  | `"Script"`       | Titel neben dem Logo                    |
| `Game`      | `string`  | `""`             | Spielname                               |
| `Version`   | `string`  | `"v1.0"`         | Versionsnummer                          |
| `ToggleKey` | `KeyCode` | `Insert`         | Taste zum Verstecken/Zeigen der UI      |
| `KeySystem` | `bool`    | `false`          | Key System aktivieren?                  |
| `KeyConfig` | `table`   | `nil`            | Konfiguration für das Key System        |

---

## 3. Key System

Das Key System blendet die UI aus und zeigt ein Login-Fenster, bis ein gültiger Key eingegeben wird.

```lua
local Window = SS:CreateWindow({
    Title     = "Mein Script",
    KeySystem = true,
    KeyConfig = {
        Keys       = {                          -- Liste aller gültigen Keys (Großschreibung egal)
            "SS-FREE-0000",
            "SS-PRO-1234-ABCD",
            "MEINKEY2024",
        },
        GetKeyURL  = "https://linkvertise.com/yourlink", -- Link für "Get Key" Button
        DiscordURL = "https://discord.gg/xyz",           -- Link für "Discord" Button
        Note       = "Tritt unserem Discord bei!",       -- Kleiner Text im Key-Fenster
    },
})
```

### Was passiert:
1. Die UI ist unsichtbar
2. Das Key-Fenster erscheint (verschwommener Hintergrund)
3. Nutzer gibt einen Key ein und klickt "Continue"
4. Bei richtigem Key → UI wird sichtbar + Notification
5. Bei falschem Key → Fehlermeldung, kein Zugang

### Keys verwalten:
- Keys werden in der `Keys`-Liste als **Strings** gespeichert
- Groß-/Kleinschreibung wird automatisch ignoriert
- Beliebig viele Keys möglich

---

## 4. Tabs & Sections

### Tab erstellen

```lua
local MeinTab = Window:AddTab({
    Name = "Player",    -- (string) Name des Tabs (im Sidebar + Top Quick Bar)
})
```

### Section erstellen

Sections sind Gruppen von Controls innerhalb eines Tabs. Sie haben einen Rahmen und optionalen Titel.

```lua
local MeineSection = MeinTab:AddSection({
    Name = "Movement",  -- (string) Überschrift der Section. "" = kein Header
})
```

> Tipp: Du kannst beliebig viele Sections pro Tab und beliebig viele Elemente pro Section erstellen.

---

## 5. Elemente / Controls

Alle Elemente werden auf einer **Section** erstellt, nicht direkt auf dem Tab.

---

### Toggle

Ein Ein/Aus-Schalter.

```lua
local MeinToggle = MeineSection:AddToggle({
    Name     = "Fly Mode",              -- (string)   Anzeigename
    Desc     = "Ermöglicht Fliegen",   -- (string?)  Optionale Beschreibung (klein darunter)
    Default  = false,                   -- (bool)     Startwert
    Flag     = "FlyMode",              -- (string?)  Schlüssel in SS.Flags (optional)
    Callback = function(value)          -- (function) Wird bei Änderung aufgerufen
        print("Fly ist:", value)        --            value = true oder false
    end,
})
```

**Wert lesen:**
```lua
print(MeinToggle.Value)     -- true oder false
print(SS.Flags["FlyMode"])  -- gleicher Wert, wenn Flag gesetzt
```

**Wert setzen (von Code aus):**
```lua
MeinToggle:Set(true)
```

---

### Slider

Ein Schieberegler für Zahlenwerte.

```lua
local MeinSlider = MeineSection:AddSlider({
    Name     = "Walk Speed",
    Desc     = "Standard: 16",     -- (string?)  Optionale Beschreibung
    Min      = 0,                   -- (number)   Minimalwert
    Max      = 500,                 -- (number)   Maximalwert
    Default  = 16,                  -- (number)   Startwert
    Suffix   = "",                  -- (string?)  Einheit, z.B. "x", "%", "m", "°"
    Flag     = "WalkSpeed",        -- (string?)  Schlüssel in SS.Flags
    Callback = function(value)      -- (function) Wird beim Ziehen aufgerufen
        -- value ist immer eine gerundete Ganzzahl
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = value
    end,
})
```

**Wert lesen:**
```lua
print(MeinSlider.Value)
print(SS.Flags["WalkSpeed"])
```

**Wert setzen:**
```lua
MeinSlider:Set(100)
```

---

### Dropdown

Ein Auswahlmenü mit mehreren Optionen.

```lua
local MeinDrop = MeineSection:AddDropdown({
    Name     = "Target Part",
    Options  = { "Head", "Neck", "Torso", "Nearest" },  -- (table)  Optionen-Liste
    Default  = "Head",                                    -- (string) Standardoption
    Flag     = "TargetPart",
    Callback = function(value)                            -- (function)
        print("Ausgewählt:", value)
    end,
})
```

**Wert lesen:**
```lua
print(MeinDrop.Value)
```

**Wert setzen:**
```lua
MeinDrop:Set("Torso")
```

---

### Button

Ein klickbarer Button der eine Funktion ausführt.

```lua
MeineSection:AddButton({
    Name     = "Teleport zu Spawn",
    Desc     = "Bringt dich zum Spawn zurück",  -- (string?) Optional
    Callback = function()
        -- Code der beim Klick ausgeführt wird
        game.Players.LocalPlayer.Character:SetPrimaryPartCFrame(
            workspace.SpawnLocation.CFrame + Vector3.new(0, 5, 0)
        )
    end,
})
```

> Buttons haben keinen Rückgabewert und kein Flag.

---

### TextBox

Ein Texteingabefeld. Callback wird ausgelöst wenn der Nutzer Enter drückt oder das Feld verlässt.

```lua
local MeinInput = MeineSection:AddTextBox({
    Name        = "Spieler Name",
    Default     = "",                      -- (string?) Vorausgefüllter Text
    Placeholder = "Name eingeben...",     -- (string?) Platzhaltertext
    Flag        = "TargetPlayer",
    Callback    = function(value)
        print("Eingabe:", value)
    end,
})
```

**Wert lesen:**
```lua
print(MeinInput.Value)
print(SS.Flags["TargetPlayer"])
```

**Wert setzen:**
```lua
MeinInput:Set("Spielername")
```

---

### Label

Ein einfacher Info-Text ohne Interaktion.

```lua
MeineSection:AddLabel("Toggle Key: INSERT um die UI zu öffnen/schließen")
```

---

### Divider

Eine horizontale Trennlinie zwischen Controls.

```lua
MeineSection:AddDivider()
```

---

## 6. Notifications

Zeigt eine Benachrichtigung unten rechts im Bildschirm (4 Typen).

```lua
SS:Notify({
    Title    = "Erfolg!",           -- (string)  Fetter Titeltext
    Desc     = "Script geladen.",   -- (string)  Kleinerer Beschreibungstext
    Type     = "success",           -- (string)  Typ (siehe unten)
    Duration = 4,                   -- (number)  Anzeigedauer in Sekunden
})
```

### Typen

| Typ        | Farbe  | Verwendung                    |
|------------|--------|-------------------------------|
| `"info"`   | Blau   | Allgemeine Infos (Standard)   |
| `"success"`| Grün   | Erfolgreiche Aktionen         |
| `"warning"`| Orange | Warnungen                     |
| `"error"`  | Rot    | Fehler                        |

Du kannst Notify auch über das Window-Objekt aufrufen:
```lua
Window:Notify({ Title = "Hi", Desc = "Test", Type = "info", Duration = 3 })
```

---

## 7. Flags System

Alle Elemente mit einem `Flag`-Parameter speichern ihren Wert automatisch in `SS.Flags`.

```lua
-- Flag-Wert lesen
local speed = SS.Flags["WalkSpeed"]    -- number
local fly   = SS.Flags["FlyMode"]     -- bool
local part  = SS.Flags["TargetPart"]  -- string

-- In einem Heartbeat z.B.:
game:GetService("RunService").Heartbeat:Connect(function()
    if SS.Flags["FlyMode"] then
        -- fly logic
    end
end)
```

> Flags werden **nicht** zwischen Script-Neustarts gespeichert. Für persistente Einstellungen nutze `writefile`/`readfile`.

---

## 8. Theme anpassen

Du kannst das Theme **vor** dem Erstellen des Windows ändern:

```lua
-- Accent Farbe auf Lila ändern
SS.Theme.Accent      = Color3.fromRGB(139, 92, 246)
SS.Theme.AccentLight = Color3.fromRGB(167, 139, 250)
SS.Theme.AccentDark  = Color3.fromRGB(109, 40, 217)
SS.Theme.Toggle_ON   = Color3.fromRGB(139, 92, 246)
SS.Theme.SliderFill  = Color3.fromRGB(139, 92, 246)

local Window = SS:CreateWindow({ ... })
```

### Alle Theme-Farben

| Key               | Standard RGB       | Beschreibung                  |
|-------------------|--------------------|-------------------------------|
| `Background`      | `10, 12, 18`       | Haupt-Hintergrund             |
| `BackgroundSecond`| `14, 18, 28`       | Section-Hintergrund           |
| `Panel`           | `12, 16, 24`       | Sidebar-Hintergrund           |
| `TopBar`          | `11, 14, 22`       | Obere Leiste                  |
| `Accent`          | `59, 130, 246`     | Akzentfarbe (Blau)            |
| `AccentLight`     | `96, 165, 250`     | Helles Akzent (Text/Glow)     |
| `AccentDark`      | `37, 99, 235`      | Dunkles Akzent (Hover)        |
| `TextPrimary`     | `226, 232, 240`    | Haupt-Textfarbe               |
| `TextSecondary`   | `100, 116, 139`    | Sekundäre/Grau-Textfarbe      |
| `Border`          | `30, 50, 90`       | Rahmenfarbe                   |
| `Toggle_ON`       | `59, 130, 246`     | Toggle an-Farbe               |
| `Toggle_OFF`      | `30, 41, 59`       | Toggle aus-Farbe              |
| `SliderFill`      | `59, 130, 246`     | Slider-Füllfarbe              |
| `Success`         | `34, 197, 94`      | Grün (Erfolg)                 |
| `Warning`         | `245, 158, 11`     | Orange (Warnung)              |
| `Danger`          | `239, 68, 68`      | Rot (Fehler)                  |

---

## 9. Destroy / Cleanup

Entfernt die komplette UI und alle Verbindungen. Nützlich für Re-Execute oder Script-Ende.

```lua
SS:Destroy()
```

> Beim erneuten Ausführen des Scripts (`loadstring...`) wird die alte UI automatisch gelöscht.

---

## 10. Komplettes Beispiel

```lua
-- Library laden
local SS = loadstring(game:HttpGet("https://raw.githubusercontent.com/.../SkidSoftLib.lua"))()

-- Theme (optional)
SS.Theme.Accent = Color3.fromRGB(59, 130, 246)  -- Standard Blau

-- Window
local Window = SS:CreateWindow({
    Title     = "Mein Script",
    Game      = "Rivals",
    Version   = "v1.0",
    ToggleKey = Enum.KeyCode.Insert,
    KeySystem = true,
    KeyConfig = {
        Keys       = { "MEINKEY123" },
        GetKeyURL  = "https://linkvertise.com/...",
        DiscordURL = "https://discord.gg/...",
        Note       = "Kostenloser Key im Discord!",
    },
})

-- Tab 1
local Tab1 = Window:AddTab({ Name = "Player" })
local S1   = Tab1:AddSection({ Name = "Movement" })

S1:AddSlider({
    Name     = "Walk Speed",
    Min = 1, Max = 500, Default = 16,
    Flag     = "WalkSpeed",
    Callback = function(v)
        local hum = game.Players.LocalPlayer.Character and
                    game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = v end
    end,
})

S1:AddToggle({
    Name     = "Infinite Jump",
    Default  = false,
    Flag     = "InfJump",
    Callback = function(v)
        if v then
            _G.IJConn = game:GetService("UserInputService").JumpRequest:Connect(function()
                local hum = game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            end)
        else
            if _G.IJConn then _G.IJConn:Disconnect() end
        end
    end,
})

-- Tab 2
local Tab2 = Window:AddTab({ Name = "Misc" })
local S2   = Tab2:AddSection({ Name = "Utility" })

S2:AddButton({
    Name     = "Notification Test",
    Callback = function()
        SS:Notify({ Title = "Test!", Desc = "Button geklickt.", Type = "success", Duration = 3 })
    end,
})

-- Start-Notification
SS:Notify({ Title = "Script geladen!", Desc = "Mein Script v1.0 ist aktiv.", Type = "success", Duration = 4 })
```

---

## 11. Häufige Fehler

### UI erscheint nicht
- Prüfe ob CoreGui-Zugriff erlaubt ist (manche Executor benötigen `syn.protect_gui`)
- Bei Synapse X: `syn.protect_gui(ScreenGui)` vor `Parent = game:GetService("CoreGui")`

### `game:HttpGet` schlägt fehl
- Executor hat kein HTTP-Recht → In den Executor-Einstellungen aktivieren
- URL prüfen → muss ein **Raw** GitHub Link sein (raw.githubusercontent.com)

### Key wird nicht erkannt
- Leerzeichen vor/nach dem Key? → Werden automatisch entfernt
- Groß-/Kleinschreibung? → Wird ignoriert, funktioniert immer

### UI flackert / Lag
- Zu viele `RunService`-Verbindungen in Callbacks → Verbindungen bei Toggle-OFF immer disconnecten
- Callbacks sollten möglichst kurz sein

### `setclipboard` funktioniert nicht
- Nicht alle Executors unterstützen `setclipboard` → Try/Catch um den Aufruf

---

> **SkidSoft UI Library** — Gebaut für Roblox LuaU | Kompatibel mit Xeno, Synapse X, KRNL, AWP-X
