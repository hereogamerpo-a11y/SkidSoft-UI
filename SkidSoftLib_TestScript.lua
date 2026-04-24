--[[
    ╔══════════════════════════════════════════╗
    ║     SkidSoft — Rivals Test Script        ║
    ║     Paste this into Xeno / Synapse etc.  ║
    ╚══════════════════════════════════════════╝

    Dieses Script zeigt alle Features der SkidSoft UI Library.
    Einfach in Xeno einfügen und ausführen.
]]

-- ──────────────────────────────────────────
--  LIBRARY LADEN
-- ──────────────────────────────────────────
-- (Ersetze die URL mit deinem echten GitHub Raw Link)
local SS = loadstring(game:HttpGet("https://raw.githubusercontent.com/YourUser/SkidSoftLib/main/SkidSoftLib.lua"))()

-- ──────────────────────────────────────────
--  WINDOW ERSTELLEN (mit Key System)
-- ──────────────────────────────────────────
local Window = SS:CreateWindow({
    Title     = "Rivals Script",       -- Titel oben links
    Game      = "Rivals",              -- Spielname (neben Logo)
    Version   = "v1.0",               -- Version
    ToggleKey = Enum.KeyCode.Insert,   -- Taste zum Auf/Zuklappen der UI

    -- KEY SYSTEM (auf false setzen um es zu deaktivieren)
    KeySystem = true,
    KeyConfig = {
        Keys       = {                  -- Liste gültiger Keys
            "SS-FREE-TEST-0000",
            "SS-PRO-DEMO-1234",
            "RIVALS2024",
        },
        GetKeyURL  = "https://linkvertise.com/yourlink",   -- Link zum Key holen
        DiscordURL = "https://discord.gg/yourinvite",      -- Discord Invite
        Note       = "Join our Discord for a free key!",   -- Text im Key Fenster
    },
})

-- ══════════════════════════════════════════
--  TAB 1 — PLAYER / MOVEMENT
-- ══════════════════════════════════════════
local PlayerTab = Window:AddTab({ Name = "Player" })

-- Section: Movement
local MovSection = PlayerTab:AddSection({ Name = "Movement" })

local WalkSpeedSlider = MovSection:AddSlider({
    Name     = "Walk Speed",
    Desc     = "Default: 16",
    Min      = 1,
    Max      = 500,
    Default  = 16,
    Flag     = "WalkSpeed",
    Callback = function(value)
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = value
        end
    end,
})

local JumpSlider = MovSection:AddSlider({
    Name     = "Jump Power",
    Desc     = "Default: 50",
    Min      = 1,
    Max      = 500,
    Default  = 50,
    Flag     = "JumpPower",
    Callback = function(value)
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.JumpPower = value
        end
    end,
})

local GravitySlider = MovSection:AddSlider({
    Name     = "Gravity",
    Min      = 0,
    Max      = 300,
    Default  = 196,
    Suffix   = "",
    Flag     = "Gravity",
    Callback = function(value)
        workspace.Gravity = value
    end,
})

-- Section: Toggles
local TogSection = PlayerTab:AddSection({ Name = "Toggles" })

local InfJumpToggle = TogSection:AddToggle({
    Name     = "Infinite Jump",
    Default  = false,
    Flag     = "InfJump",
    Callback = function(value)
        -- Infinite Jump Logic (Beispiel)
        if value then
            _G.InfJumpConn = game:GetService("UserInputService").JumpRequest:Connect(function()
                local char = game.Players.LocalPlayer.Character
                if char and char:FindFirstChild("Humanoid") then
                    char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        else
            if _G.InfJumpConn then _G.InfJumpConn:Disconnect() end
        end
    end,
})

local FlyToggle = TogSection:AddToggle({
    Name     = "Fly Mode",
    Desc     = "Toggle: F",
    Default  = false,
    Flag     = "FlyMode",
    Callback = function(value)
        -- Deine Fly Logic hier
        print("Fly:", value)
    end,
})

local NoClipToggle = TogSection:AddToggle({
    Name     = "No Clip",
    Default  = false,
    Flag     = "NoClip",
    Callback = function(value)
        if value then
            _G.NoClipConn = game:GetService("RunService").Stepped:Connect(function()
                local char = game.Players.LocalPlayer.Character
                if char then
                    for _, part in pairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end)
        else
            if _G.NoClipConn then _G.NoClipConn:Disconnect() end
        end
    end,
})

-- Section: Buttons
local BtnSection = PlayerTab:AddSection({ Name = "Teleport" })

BtnSection:AddButton({
    Name     = "Teleport to Spawn",
    Desc     = "Gehe zu Spawn zurück",
    Callback = function()
        local char = game.Players.LocalPlayer.Character
        local spawn = workspace:FindFirstChild("SpawnLocation")
        if char and spawn then
            char:SetPrimaryPartCFrame(spawn.CFrame + Vector3.new(0, 5, 0))
        end
        SS:Notify({ Title = "Teleport", Desc = "Zu Spawn teleportiert!", Type = "success", Duration = 3 })
    end,
})

local TargetInput = BtnSection:AddTextBox({
    Name        = "Target Player",
    Placeholder = "Spielername eingeben...",
    Flag        = "TargetPlayer",
})

BtnSection:AddButton({
    Name     = "Teleport to Player",
    Callback = function()
        local targetName = SS.Flags.TargetPlayer or ""
        local target = game.Players:FindFirstChild(targetName)
        if target and target.Character then
            game.Players.LocalPlayer.Character:SetPrimaryPartCFrame(
                target.Character.PrimaryPart.CFrame + Vector3.new(0, 3, 0)
            )
            SS:Notify({ Title = "Teleport", Desc = "Zu " .. targetName .. " teleportiert!", Type = "info", Duration = 3 })
        else
            SS:Notify({ Title = "Fehler", Desc = "Spieler nicht gefunden.", Type = "error", Duration = 3 })
        end
    end,
})

-- ══════════════════════════════════════════
--  TAB 2 — COMBAT / AIMBOT
-- ══════════════════════════════════════════
local CombatTab = Window:AddTab({ Name = "Combat" })

local AimSection = CombatTab:AddSection({ Name = "Aimbot" })

local AimToggle = AimSection:AddToggle({
    Name     = "Aimbot",
    Default  = false,
    Flag     = "AimbotEnabled",
    Callback = function(value)
        print("Aimbot:", value)
        SS:Notify({ Title = "Aimbot", Desc = value and "Aktiviert" or "Deaktiviert", Type = value and "success" or "warning", Duration = 2 })
    end,
})

AimSection:AddSlider({
    Name     = "Smoothness",
    Desc     = "Höher = humaner",
    Min      = 1,
    Max      = 100,
    Default  = 40,
    Flag     = "AimSmooth",
    Callback = function(v) print("Smooth:", v) end,
})

AimSection:AddSlider({
    Name     = "FOV Size",
    Min      = 10,
    Max      = 360,
    Default  = 90,
    Suffix   = "°",
    Flag     = "AimFOV",
    Callback = function(v) print("FOV:", v) end,
})

AimSection:AddDropdown({
    Name     = "Target Part",
    Options  = { "Head", "Neck", "Torso", "Nearest Part" },
    Default  = "Head",
    Flag     = "AimPart",
    Callback = function(v) print("Target:", v) end,
})

AimSection:AddToggle({
    Name     = "Show FOV Circle",
    Default  = true,
    Flag     = "ShowFOV",
    Callback = function(v) print("FOV Circle:", v) end,
})

local DmgSection = CombatTab:AddSection({ Name = "Damage" })

DmgSection:AddToggle({
    Name     = "No Fall Damage",
    Default  = true,
    Flag     = "NoFallDmg",
    Callback = function(v) print("NoFallDmg:", v) end,
})

DmgSection:AddSlider({
    Name     = "Damage Multiplier",
    Min      = 1,
    Max      = 20,
    Default  = 1,
    Suffix   = "x",
    Flag     = "DmgMult",
    Callback = function(v) print("DmgMult:", v) end,
})

-- ══════════════════════════════════════════
--  TAB 3 — VISUALS / ESP
-- ══════════════════════════════════════════
local VisualTab = Window:AddTab({ Name = "Visuals" })

local ESPSection = VisualTab:AddSection({ Name = "ESP" })

ESPSection:AddToggle({
    Name     = "Player ESP",
    Default  = false,
    Flag     = "PlayerESP",
    Callback = function(v) print("ESP:", v) end,
})

ESPSection:AddToggle({
    Name     = "Name Tags",
    Default  = true,
    Flag     = "NameTags",
    Callback = function(v) print("Names:", v) end,
})

ESPSection:AddToggle({
    Name     = "Health Bars",
    Default  = true,
    Flag     = "HealthBars",
    Callback = function(v) print("HP Bars:", v) end,
})

ESPSection:AddSlider({
    Name     = "ESP Distance",
    Min      = 50,
    Max      = 2000,
    Default  = 500,
    Suffix   = "m",
    Flag     = "ESPDist",
    Callback = function(v) print("ESPDist:", v) end,
})

local WorldSection = VisualTab:AddSection({ Name = "World" })

WorldSection:AddToggle({
    Name     = "Fullbright",
    Default  = false,
    Flag     = "Fullbright",
    Callback = function(value)
        game:GetService("Lighting").Brightness = value and 10 or 1
        game:GetService("Lighting").ClockTime  = value and 14 or 14
    end,
})

WorldSection:AddToggle({
    Name     = "Remove Fog",
    Default  = false,
    Flag     = "NoFog",
    Callback = function(value)
        game:GetService("Lighting").FogEnd = value and 100000 or 1000
    end,
})

-- ══════════════════════════════════════════
--  TAB 4 — MISC / UTILITY
-- ══════════════════════════════════════════
local MiscTab = Window:AddTab({ Name = "Misc" })

local AntiSection = MiscTab:AddSection({ Name = "Anti" })

AntiSection:AddToggle({
    Name     = "Anti-AFK",
    Default  = true,
    Flag     = "AntiAFK",
    Callback = function(value)
        if value then
            _G.AFKConn = game:GetService("RunService").Heartbeat:Connect(function()
                game:GetService("VirtualUser"):Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            end)
        else
            if _G.AFKConn then _G.AFKConn:Disconnect() end
        end
    end,
})

AntiSection:AddToggle({
    Name     = "Anti-Ragdoll",
    Default  = false,
    Flag     = "AntiRagdoll",
    Callback = function(v) print("AntiRagdoll:", v) end,
})

local UtilSection = MiscTab:AddSection({ Name = "Utility" })

UtilSection:AddDropdown({
    Name     = "Auto Rejoin Speed",
    Options  = { "Slow (10s)", "Normal (5s)", "Fast (2s)", "Instant" },
    Default  = "Normal (5s)",
    Flag     = "RejoinSpeed",
    Callback = function(v) print("Rejoin:", v) end,
})

UtilSection:AddButton({
    Name     = "Copy Player ID",
    Desc     = "Kopiert deine Player ID",
    Callback = function()
        setclipboard(tostring(game.Players.LocalPlayer.UserId))
        SS:Notify({ Title = "Kopiert!", Desc = "Player ID in Zwischenablage.", Type = "success", Duration = 2 })
    end,
})

UtilSection:AddButton({
    Name     = "Rejoin Server",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, game.Players.LocalPlayer)
    end,
})

-- ══════════════════════════════════════════
--  TAB 5 — SETTINGS
-- ══════════════════════════════════════════
local SettingsTab = Window:AddTab({ Name = "Settings" })

local UISection = SettingsTab:AddSection({ Name = "UI" })

UISection:AddLabel("Toggle Key: INSERT — Öffnet/Schließt die UI")
UISection:AddDivider()

UISection:AddToggle({
    Name     = "Notifications",
    Default  = true,
    Flag     = "NotifEnabled",
    Callback = function(v) print("Notifs:", v) end,
})

UISection:AddToggle({
    Name     = "Auto Execute on Join",
    Default  = true,
    Flag     = "AutoExec",
    Callback = function(v) print("AutoExec:", v) end,
})

-- ──────────────────────────────────────────
--  START NOTIFICATION
-- ──────────────────────────────────────────
task.delay(1.5, function()
    SS:Notify({
        Title    = "SkidSoft geladen!",
        Desc     = "Rivals Script v1.0 ist aktiv.",
        Type     = "success",
        Duration = 4,
    })
end)

-- ──────────────────────────────────────────
--  DEBUG: Aktuelle Flags ausgeben
-- ──────────────────────────────────────────
-- print(SS.Flags)  -- Kommentar entfernen zum Debuggen
