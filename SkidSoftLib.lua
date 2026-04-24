--[[
    ╔══════════════════════════════════════════╗
    ║         SkidSoft UI Library v1.0         ║
    ║     Professional Roblox UI Framework     ║
    ║   github.com/SkidSoft/SkidSoftLib        ║
    ╚══════════════════════════════════════════╝

    Usage (in your script):
        local SS = loadstring(game:HttpGet("https://raw.githubusercontent.com/YourUser/SkidSoftLib/main/SkidSoftLib.lua"))()
        local Window = SS:CreateWindow({ Title = "My Script", Game = "Rivals" })
]]

-- ════════════════════════════════════════════
--  SERVICES
-- ════════════════════════════════════════════
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")
local HttpService      = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

-- ════════════════════════════════════════════
--  LIBRARY TABLE
-- ════════════════════════════════════════════
local SkidSoft = {}
SkidSoft.__index = SkidSoft
SkidSoft.Version = "1.0.0"
SkidSoft.Flags = {}         -- stores all toggle/slider values by flag name
SkidSoft._connections = {}  -- cleanup connections
SkidSoft._windows = {}

-- ════════════════════════════════════════════
--  THEME
-- ════════════════════════════════════════════
SkidSoft.Theme = {
    -- Backgrounds
    Background       = Color3.fromRGB(10,  12,  18),
    BackgroundSecond = Color3.fromRGB(14,  18,  28),
    Panel            = Color3.fromRGB(12,  16,  24),
    TopBar           = Color3.fromRGB(11,  14,  22),

    -- Accent
    Accent           = Color3.fromRGB(59,  130, 246),
    AccentLight      = Color3.fromRGB(96,  165, 250),
    AccentDark       = Color3.fromRGB(37,  99,  235),

    -- Text
    TextPrimary      = Color3.fromRGB(226, 232, 240),
    TextSecondary    = Color3.fromRGB(100, 116, 139),
    TextAccent       = Color3.fromRGB(96,  165, 250),

    -- UI Elements
    Border           = Color3.fromRGB(30,  50,  90),
    Toggle_ON        = Color3.fromRGB(59,  130, 246),
    Toggle_OFF       = Color3.fromRGB(30,  41,  59),
    SliderFill       = Color3.fromRGB(59,  130, 246),
    SliderBG         = Color3.fromRGB(20,  30,  50),
    Divider          = Color3.fromRGB(20,  35,  65),

    -- Key System
    KeyBackground    = Color3.fromRGB(8,   12,  20),
    KeyBorder        = Color3.fromRGB(59,  130, 246),

    -- Status
    Success          = Color3.fromRGB(34,  197, 94),
    Warning          = Color3.fromRGB(245, 158, 11),
    Danger           = Color3.fromRGB(239, 68,  68),
}

-- ════════════════════════════════════════════
--  UTILITY FUNCTIONS
-- ════════════════════════════════════════════
local function Tween(obj, props, t, style, dir)
    t     = t or 0.18
    style = style or Enum.EasingStyle.Quart
    dir   = dir   or Enum.EasingDirection.Out
    local info = TweenInfo.new(t, style, dir)
    local tw = TweenService:Create(obj, info, props)
    tw:Play()
    return tw
end

local function Create(class, props, children)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then obj[k] = v end
    end
    for _, child in ipairs(children or {}) do
        child.Parent = obj
    end
    if props and props.Parent then obj.Parent = props.Parent end
    return obj
end

local function MakeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragInput, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = input.Position
            startPos  = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

local function RoundedCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = parent
    return corner
end

local function Stroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color     = color or SkidSoft.Theme.Border
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function Padding(parent, top, right, bottom, left)
    local p = Instance.new("UIPadding")
    p.PaddingTop    = UDim.new(0, top    or 0)
    p.PaddingRight  = UDim.new(0, right  or 0)
    p.PaddingBottom = UDim.new(0, bottom or 0)
    p.PaddingLeft   = UDim.new(0, left   or 0)
    p.Parent = parent
    return p
end

-- ════════════════════════════════════════════
--  ROOT GUI
-- ════════════════════════════════════════════
local function GetGui()
    -- Remove existing to avoid duplicates on re-execute
    local existing = CoreGui:FindFirstChild("SkidSoftUI")
    if existing then existing:Destroy() end

    local ScreenGui = Create("ScreenGui", {
        Name             = "SkidSoftUI",
        ResetOnSpawn     = false,
        ZIndexBehavior   = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset   = true,
        Parent           = CoreGui,
    })
    return ScreenGui
end

-- ════════════════════════════════════════════
--  KEY SYSTEM
-- ════════════════════════════════════════════
local function CreateKeySystem(ScreenGui, config, callback)
    local T = SkidSoft.Theme

    -- Blur background frame
    local Blur = Create("Frame", {
        Name            = "KeyBlur",
        Size            = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.45,
        Parent          = ScreenGui,
        ZIndex          = 10,
    })

    -- Center panel (with round border using inset frame technique)
    local Panel = Create("Frame", {
        Name              = "KeyPanel",
        Size              = UDim2.fromOffset(400, 310),
        Position          = UDim2.fromScale(0.5, 0.5),
        AnchorPoint       = Vector2.new(0.5, 0.5),
        BackgroundColor3  = T.KeyBorder,   -- border color
        Parent            = ScreenGui,
        ZIndex            = 11,
    })
    RoundedCorner(Panel, 12)

    local PanelInner = Create("Frame", {
        Size             = UDim2.new(1, -2, 1, -2),
        Position         = UDim2.fromOffset(1, 1),
        BackgroundColor3 = T.KeyBackground,
        Parent           = Panel,
        ZIndex           = 11,
    })
    RoundedCorner(PanelInner, 11)  -- slightly smaller to show border

    MakeDraggable(Panel)

    -- Top accent line
    local TopLine = Create("Frame", {
        Size             = UDim2.new(0.7, 0, 0, 2),
        Position         = UDim2.new(0.15, 0, 0, 0),
        BackgroundColor3 = T.Accent,
        BorderSizePixel  = 0,
        Parent           = PanelInner,
        ZIndex           = 12,
    })
    RoundedCorner(TopLine, 2)

    Padding(PanelInner, 24, 24, 24, 24)

    -- Logo Row (centered)
    local LogoRow = Create("Frame", {
        Size             = UDim2.new(1, 0, 0, 36),
        BackgroundTransparency = 1,
        Parent           = PanelInner,
        ZIndex           = 12,
    })
    Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 8), Parent = LogoRow })

    -- S icon
    local IconBG = Create("Frame", {
        Size             = UDim2.fromOffset(30, 30),
        BackgroundColor3 = T.Accent,
        Parent           = LogoRow,
        ZIndex           = 12,
    })
    RoundedCorner(IconBG, 6)
    Create("TextLabel", {
        Size             = UDim2.fromScale(1,1),
        BackgroundTransparency = 1,
        Text             = "S",
        Font             = Enum.Font.GothamBold,
        TextSize         = 18,
        TextColor3       = Color3.new(1,1,1),
        Parent           = IconBG,
        ZIndex           = 13,
    })

    Create("TextLabel", {
        Size             = UDim2.fromOffset(160, 30),
        BackgroundTransparency = 1,
        Text             = "Skid<font color='#60a5fa'>Soft</font>",
        RichText         = true,
        Font             = Enum.Font.GothamBold,
        TextSize         = 22,
        TextColor3       = T.TextPrimary,
        TextXAlignment   = Enum.TextXAlignment.Left,
        Parent           = LogoRow,
        ZIndex           = 12,
    })

    -- Subtitle
    Create("TextLabel", {
        Size             = UDim2.new(1, 0, 0, 18),
        Position         = UDim2.fromOffset(0, 46),
        BackgroundTransparency = 1,
        Text             = "Authentication Required",
        Font             = Enum.Font.GothamSemibold,
        TextSize         = 14,
        TextColor3       = T.TextPrimary,
        TextXAlignment   = Enum.TextXAlignment.Center,
        Parent           = PanelInner,
        ZIndex           = 12,
    })

    Create("TextLabel", {
        Size             = UDim2.new(1, 0, 0, 16),
        Position         = UDim2.fromOffset(0, 66),
        BackgroundTransparency = 1,
        Text             = config.Note or "Enter your license key to continue",
        Font             = Enum.Font.Gotham,
        TextSize         = 11,
        TextColor3       = T.TextSecondary,
        TextXAlignment   = Enum.TextXAlignment.Center,
        Parent           = PanelInner,
        ZIndex           = 12,
    })

    -- Input Box
    local InputBG = Create("Frame", {
        Size             = UDim2.new(1, 0, 0, 36),
        Position         = UDim2.fromOffset(0, 98),
        BackgroundColor3 = Color3.fromRGB(16, 22, 36),
        Parent           = PanelInner,
        ZIndex           = 12,
    })
    RoundedCorner(InputBG, 7)
    Stroke(InputBG, T.Border, 1)

    local KeyInput = Create("TextBox", {
        Size             = UDim2.new(1, -16, 1, 0),
        Position         = UDim2.fromOffset(8, 0),
        BackgroundTransparency = 1,
        PlaceholderText  = "SS-XXXX-XXXX-XXXX-XXXX",
        PlaceholderColor3 = T.TextSecondary,
        Text             = "",
        Font             = Enum.Font.Code,
        TextSize         = 13,
        TextColor3       = T.TextPrimary,
        ClearTextOnFocus = false,
        Parent           = InputBG,
        ZIndex           = 13,
    })

    -- Input focus glow
    KeyInput.Focused:Connect(function()
        Tween(InputBG, { BackgroundColor3 = Color3.fromRGB(20, 30, 55) }, 0.15)
        local s = InputBG:FindFirstChildOfClass("UIStroke")
        if s then Tween(s, { Color = T.Accent }, 0.15) end
    end)
    KeyInput.FocusLost:Connect(function()
        Tween(InputBG, { BackgroundColor3 = Color3.fromRGB(16, 22, 36) }, 0.15)
        local s = InputBG:FindFirstChildOfClass("UIStroke")
        if s then Tween(s, { Color = T.Border }, 0.15) end
    end)

    -- Status label
    local StatusLabel = Create("TextLabel", {
        Size             = UDim2.new(1, 0, 0, 14),
        Position         = UDim2.fromOffset(0, 140),
        BackgroundTransparency = 1,
        Text             = "",
        Font             = Enum.Font.Gotham,
        TextSize         = 11,
        TextColor3       = T.Danger,
        TextXAlignment   = Enum.TextXAlignment.Center,
        Parent           = PanelInner,
        ZIndex           = 12,
    })

    -- Buttons row (centered)
    local BtnRow = Create("Frame", {
        Size             = UDim2.new(1, 0, 0, 36),
        Position         = UDim2.fromOffset(0, 162),
        BackgroundTransparency = 1,
        Parent           = PanelInner,
        ZIndex           = 12,
    })
    Create("UIListLayout", {
        FillDirection    = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,  -- centered now
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding          = UDim.new(0, 8),
        Parent           = BtnRow,
    })

    local function MakeBtn(text, color, w)
        local b = Create("TextButton", {
            Size             = UDim2.fromOffset(w or 118, 36),
            BackgroundColor3 = color or Color3.fromRGB(20, 30, 50),
            Text             = text,
            Font             = Enum.Font.GothamSemibold,
            TextSize         = 13,
            TextColor3       = T.TextPrimary,
            AutoButtonColor  = false,
            Parent           = BtnRow,
            ZIndex           = 13,
        })
        RoundedCorner(b, 7)
        Stroke(b, T.Border, 1)
        b.MouseEnter:Connect(function()
            Tween(b, { BackgroundColor3 = Color3.fromRGB(30, 50, 90) }, 0.12)
        end)
        b.MouseLeave:Connect(function()
            Tween(b, { BackgroundColor3 = color or Color3.fromRGB(20, 30, 50) }, 0.12)
        end)
        return b
    end

    local GetKeyBtn  = MakeBtn("⬡ Get Key",    Color3.fromRGB(20, 30, 50), 118)
    local DiscordBtn = MakeBtn("# Discord",     Color3.fromRGB(20, 30, 50), 118)

    -- Continue button (full width)
    local ContinueBtn = Create("TextButton", {
        Size             = UDim2.new(1, 0, 0, 36),
        Position         = UDim2.fromOffset(0, 206),
        BackgroundColor3 = T.Accent,
        Text             = "Continue →",
        Font             = Enum.Font.GothamBold,
        TextSize         = 14,
        TextColor3       = Color3.new(1,1,1),
        AutoButtonColor  = false,
        Parent           = PanelInner,
        ZIndex           = 12,
    })
    RoundedCorner(ContinueBtn, 7)
    ContinueBtn.MouseEnter:Connect(function() Tween(ContinueBtn, { BackgroundColor3 = T.AccentLight }, 0.12) end)
    ContinueBtn.MouseLeave:Connect(function() Tween(ContinueBtn, { BackgroundColor3 = T.Accent }, 0.12) end)

    -- Footer
    Create("TextLabel", {
        Size             = UDim2.new(1, 0, 0, 14),
        Position         = UDim2.fromOffset(0, 248),
        BackgroundTransparency = 1,
        Text             = "SkidSoft — Secure Key System v1.0",
        Font             = Enum.Font.Gotham,
        TextSize         = 10,
        TextColor3       = Color3.fromRGB(40, 60, 90),
        TextXAlignment   = Enum.TextXAlignment.Center,
        Parent           = PanelInner,
        ZIndex           = 12,
    })

    -- Button logic
    GetKeyBtn.MouseButton1Click:Connect(function()
        if config.GetKeyURL then
            setclipboard(config.GetKeyURL)
            StatusLabel.TextColor3 = T.Warning
            StatusLabel.Text = "Link copied to clipboard!"
            task.delay(2, function() StatusLabel.Text = "" end)
        end
    end)

    DiscordBtn.MouseButton1Click:Connect(function()
        if config.DiscordURL then
            setclipboard(config.DiscordURL)
            StatusLabel.TextColor3 = T.Warning
            StatusLabel.Text = "Discord link copied!"
            task.delay(2, function() StatusLabel.Text = "" end)
        end
    end)

    local function TryKey()
        local val = KeyInput.Text:upper():gsub("%s+", "")
        if val == "" then
            StatusLabel.TextColor3 = T.Danger
            StatusLabel.Text = "Please enter a key."
            return
        end
        local valid = false
        for _, k in ipairs(config.Keys or {}) do
            if val == k:upper() then valid = true break end
        end
        if valid then
            StatusLabel.TextColor3 = T.Success
            StatusLabel.Text = "✓ Access granted!"
            task.delay(0.6, function()
                Tween(Panel, { BackgroundTransparency = 1 }, 0.35)
                Tween(Blur,  { BackgroundTransparency = 1 }, 0.35)
                task.delay(0.4, function()
                    Panel:Destroy()
                    Blur:Destroy()
                    callback()
                end)
            end)
        else
            StatusLabel.TextColor3 = T.Danger
            StatusLabel.Text = "✗ Invalid key. Get one in our Discord."
            Tween(InputBG, { BackgroundColor3 = Color3.fromRGB(40, 16, 16) }, 0.1)
            task.delay(0.5, function()
                Tween(InputBG, { BackgroundColor3 = Color3.fromRGB(16, 22, 36) }, 0.2)
            end)
        end
    end

    ContinueBtn.MouseButton1Click:Connect(TryKey)
    KeyInput.FocusLost:Connect(function(enter) if enter then TryKey() end end)
end

-- ════════════════════════════════════════════
--  NOTIFICATION
-- ════════════════════════════════════════════
local NotifHolder

local function InitNotifHolder(ScreenGui)
    NotifHolder = Create("Frame", {
        Name             = "NotifHolder",
        Size             = UDim2.fromOffset(280, 0),
        Position         = UDim2.new(1, -290, 1, -10),
        AnchorPoint      = Vector2.new(0, 1),
        BackgroundTransparency = 1,
        Parent           = ScreenGui,
        ZIndex           = 20,
    })
    Create("UIListLayout", {
        FillDirection    = Enum.FillDirection.Vertical,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        Padding          = UDim.new(0, 6),
        Parent           = NotifHolder,
    })
end

function SkidSoft:Notify(config)
    if not NotifHolder then return end
    local T = self.Theme
    local typeColors = {
        info    = T.Accent,
        success = T.Success,
        warning = T.Warning,
        error   = T.Danger,
    }
    local barColor = typeColors[config.Type or "info"] or T.Accent

    local Notif = Create("Frame", {
        Size             = UDim2.new(1, 0, 0, 62),
        BackgroundColor3 = T.BackgroundSecond,
        ClipsDescendants = true,
        Parent           = NotifHolder,
        ZIndex           = 21,
    })
    RoundedCorner(Notif, 8)
    Stroke(Notif, T.Border, 1)

    -- Left color bar
    Create("Frame", {
        Size             = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = barColor,
        BorderSizePixel  = 0,
        Parent           = Notif,
        ZIndex           = 22,
    })

    -- Title
    Create("TextLabel", {
        Size             = UDim2.new(1, -16, 0, 20),
        Position         = UDim2.fromOffset(12, 10),
        BackgroundTransparency = 1,
        Text             = config.Title or "Notification",
        Font             = Enum.Font.GothamBold,
        TextSize         = 13,
        TextColor3       = T.TextPrimary,
        TextXAlignment   = Enum.TextXAlignment.Left,
        Parent           = Notif,
        ZIndex           = 22,
    })

    Create("TextLabel", {
        Size             = UDim2.new(1, -16, 0, 24),
        Position         = UDim2.fromOffset(12, 30),
        BackgroundTransparency = 1,
        Text             = config.Desc or "",
        Font             = Enum.Font.Gotham,
        TextSize         = 11,
        TextColor3       = T.TextSecondary,
        TextXAlignment   = Enum.TextXAlignment.Left,
        TextWrapped      = true,
        Parent           = Notif,
        ZIndex           = 22,
    })

    -- Slide in
    Notif.Position = UDim2.new(1, 10, 0, 0)
    Tween(Notif, { Position = UDim2.new(0, 0, 0, 0) }, 0.25)

    task.delay(config.Duration or 4, function()
        Tween(Notif, { Position = UDim2.new(1, 10, 0, 0) }, 0.25)
        task.delay(0.3, function() Notif:Destroy() end)
    end)
end

-- ════════════════════════════════════════════
--  WINDOW
-- ════════════════════════════════════════════
function SkidSoft:CreateWindow(config)
    config = config or {}

    local T = self.Theme
    local ScreenGui = GetGui()
    InitNotifHolder(ScreenGui)

    local Window = {
        _tabs = {},
        _activeTab = nil,
        _visible = true,
        SkidSoft = self
    }

    -- ─── Shell (main container) ──────────────
    local Shell = Create("Frame", {
        Name             = "Shell",
        Size             = UDim2.fromOffset(780, 500),
        Position         = UDim2.fromScale(0.5, 0.5),
        AnchorPoint      = Vector2.new(0.5, 0.5),
        BackgroundColor3 = T.Border,   -- border color
        ClipsDescendants = true,
        Parent           = ScreenGui,
        ZIndex           = 2,
    })
    RoundedCorner(Shell, 12)

    -- Inner container to create rounded border
    local Container = Create("Frame", {
        Size             = UDim2.new(1, -2, 1, -2),
        Position         = UDim2.fromOffset(1, 1),
        BackgroundColor3 = T.Background,
        ClipsDescendants = true,
        Parent           = Shell,
        ZIndex           = 2,
    })
    RoundedCorner(Container, 11)

    MakeDraggable(Shell)

    -- ─── Top Bar (inside Container) ──────────
    local TopBar = Create("Frame", {
        Name             = "TopBar",
        Size             = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = T.TopBar,
        Parent           = Container,
        ZIndex           = 3,
    })

    -- Centered logo group
    local TitleGroup = Create("Frame", {
        Size             = UDim2.fromOffset(0, 26),
        AutomaticSize    = Enum.AutomaticSize.X,
        Position         = UDim2.fromScale(0.5, 0.5),
        AnchorPoint      = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Parent           = TopBar,
        ZIndex           = 4,
    })
    Create("UIListLayout", {
        FillDirection    = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding          = UDim.new(0, 8),
        Parent           = TitleGroup,
    })

    -- Logo icon
    local LogoBG = Create("Frame", {
        Size             = UDim2.fromOffset(26, 26),
        BackgroundColor3 = T.Accent,
        Parent           = TitleGroup,
        ZIndex           = 4,
    })
    RoundedCorner(LogoBG, 6)
    Create("TextLabel", {
        Size             = UDim2.fromScale(1,1),
        BackgroundTransparency = 1,
        Text             = "S",
        Font             = Enum.Font.GothamBold,
        TextSize         = 16,
        TextColor3       = Color3.new(1,1,1),
        Parent           = LogoBG,
        ZIndex           = 5,
    })

    Create("TextLabel", {
        Size             = UDim2.fromOffset(120, 26),
        BackgroundTransparency = 1,
        Text             = "Skid<font color='#60a5fa'>Soft</font>",
        RichText         = true,
        Font             = Enum.Font.GothamBold,
        TextSize         = 16,
        TextColor3       = T.TextPrimary,
        TextXAlignment   = Enum.TextXAlignment.Left,
        Parent           = TitleGroup,
        ZIndex           = 4,
    })

    -- Game + version badge (right aligned)
    Create("TextLabel", {
        Size             = UDim2.fromOffset(200, 26),
        Position         = UDim2.new(1, -210, 0.5, -13),
        BackgroundTransparency = 1,
        Text             = (config.Game or "") .. "  |  " .. (config.Version or "v1.0"),
        Font             = Enum.Font.Gotham,
        TextSize         = 11,
        TextColor3       = T.TextSecondary,
        TextXAlignment   = Enum.TextXAlignment.Right,
        Parent           = TopBar,
        ZIndex           = 4,
    })

    -- Thin separator line below TopBar
    Create("Frame", {
        Size             = UDim2.new(1, 0, 0, 1),
        Position         = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = T.Border,
        BorderSizePixel  = 0,
        Parent           = TopBar,
        ZIndex           = 4,
    })

    -- Quick Tab Bar (center of topbar)
    local QuickTabBar = Create("Frame", {
        Name             = "QuickTabBar",
        Size             = UDim2.fromOffset(340, 28),
        Position         = UDim2.new(0.5, -170, 0.5, -14),
        BackgroundTransparency = 1,
        Parent           = TopBar,
        ZIndex           = 4,
    })
    local QuickLayout = Create("UIListLayout", {
        FillDirection    = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding          = UDim.new(0, 3),
        Parent           = QuickTabBar,
    })

    -- Close / Minimize dots
    local DotClose = Create("TextButton", {
        Size             = UDim2.fromOffset(12, 12),
        Position         = UDim2.new(1, -14, 0.5, -6),
        BackgroundColor3 = T.Danger,
        Text             = "",
        AutoButtonColor  = false,
        Parent           = TopBar,
        ZIndex           = 4,
    })
    RoundedCorner(DotClose, 6)

    local DotMin = Create("TextButton", {
        Size             = UDim2.fromOffset(12, 12),
        Position         = UDim2.new(1, -30, 0.5, -6),
        BackgroundColor3 = T.Warning,
        Text             = "",
        AutoButtonColor  = false,
        Parent           = TopBar,
        ZIndex           = 4,
    })
    RoundedCorner(DotMin, 6)

    DotClose.MouseButton1Click:Connect(function()
        Tween(Shell, { Size = UDim2.fromOffset(780, 0) }, 0.25)
        task.delay(0.3, function() Shell:Destroy() end)
    end)

    DotMin.MouseButton1Click:Connect(function()
        Window._visible = not Window._visible
        if Window._visible then
            Tween(Shell, { Size = UDim2.fromOffset(780, 500) }, 0.25)
        else
            Tween(Shell, { Size = UDim2.fromOffset(780, 42) }, 0.25)
        end
    end)

    -- ─── Body (inside Container) ────────────
    local Body = Create("Frame", {
        Name             = "Body",
        Size             = UDim2.new(1, 0, 1, -42),
        Position         = UDim2.fromOffset(0, 42),
        BackgroundTransparency = 1,
        Parent           = Container,
        ZIndex           = 3,
    })

    -- Sidebar
    local Sidebar = Create("ScrollingFrame", {
        Name             = "Sidebar",
        Size             = UDim2.fromOffset(150, 458),
        BackgroundColor3 = T.Panel,
        BorderSizePixel  = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = T.Border,
        CanvasSize       = UDim2.fromScale(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent           = Body,
        ZIndex           = 3,
    })

    -- right border
    Create("Frame", {
        Size             = UDim2.new(0, 1, 1, 0),
        Position         = UDim2.new(1, -1, 0, 0),
        BackgroundColor3 = T.Border,
        BorderSizePixel  = 0,
        Parent           = Sidebar,
        ZIndex           = 4,
    })

    local SidebarLayout = Create("UIListLayout", {
        FillDirection    = Enum.FillDirection.Vertical,
        Padding          = UDim.new(0, 2),
        Parent           = Sidebar,
    })
    Padding(Sidebar, 8, 6, 8, 6)

    -- Content area
    local ContentArea = Create("Frame", {
        Name             = "ContentArea",
        Size             = UDim2.new(1, -150, 1, 0),
        Position         = UDim2.fromOffset(150, 0),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent           = Body,
        ZIndex           = 3,
    })

    -- Toggle key (show/hide)
    local toggleKey = config.ToggleKey or Enum.KeyCode.Insert
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == toggleKey then
            Window._visible = not Window._visible
            if Window._visible then
                Tween(Shell, { Size = UDim2.fromOffset(780, 500) }, 0.25)
            else
                Tween(Shell, { Size = UDim2.fromOffset(780, 42) }, 0.25)
            end
        end
    end)

    -- ─── Sidebar section label helper ────────
    function Window:AddSidebarSection(name)
        local lbl = Create("TextLabel", {
            Size             = UDim2.new(1, 0, 0, 20),
            BackgroundTransparency = 1,
            Text             = name:upper(),
            Font             = Enum.Font.GothamBold,
            TextSize         = 9,
            TextColor3       = T.TextSecondary,
            TextXAlignment   = Enum.TextXAlignment.Left,
            Parent           = Sidebar,
            ZIndex           = 4,
        })
        Padding(lbl, 6, 0, 0, 4)
        return lbl
    end

    -- ════════════════════════════════════════
    --  ADD TAB
    -- ════════════════════════════════════════
    function Window:AddTab(tabConfig)
        tabConfig = tabConfig or {}
        local tabName = tabConfig.Name or "Tab"
        local Tab = { _sections = {}, _name = tabName }

        -- Sidebar button
        local SideBtn = Create("TextButton", {
            Size             = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = Color3.fromRGB(16, 22, 36),
            BackgroundTransparency = 1,
            Text             = "",
            AutoButtonColor  = false,
            Parent           = Sidebar,
            ZIndex           = 4,
        })
        RoundedCorner(SideBtn, 7)

        Create("TextLabel", {
            Size             = UDim2.new(1, -10, 1, 0),
            Position         = UDim2.fromOffset(10, 0),
            BackgroundTransparency = 1,
            Text             = tabName,
            Font             = Enum.Font.GothamSemibold,
            TextSize         = 13,
            TextColor3       = T.TextSecondary,
            TextXAlignment   = Enum.TextXAlignment.Left,
            Parent           = SideBtn,
            ZIndex           = 5,
        })

        -- Quick tab button
        local QBtn = Create("TextButton", {
            Size             = UDim2.fromOffset(0, 24),
            AutomaticSize    = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            Text             = tabName,
            Font             = Enum.Font.GothamSemibold,
            TextSize         = 12,
            TextColor3       = T.TextSecondary,
            AutoButtonColor  = false,
            Parent           = QuickTabBar,
            ZIndex           = 5,
        })
        Padding(QBtn, 0, 8, 0, 8)
        RoundedCorner(QBtn, 5)

        -- Content frame for this tab
        local TabFrame = Create("ScrollingFrame", {
            Size             = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = T.Border,
            CanvasSize       = UDim2.fromScale(0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible          = false,
            Parent           = ContentArea,
            ZIndex           = 4,
        })
        Padding(TabFrame, 14, 18, 14, 18)
        local FrameLayout = Create("UIListLayout", {
            FillDirection    = Enum.FillDirection.Vertical,
            Padding          = UDim.new(0, 10),
            Parent           = TabFrame,
        })

        Tab._frame  = TabFrame
        Tab._sideBtn = SideBtn
        Tab._qBtn   = QBtn

        local function ActivateTab()
            -- Deactivate all
            for _, t in ipairs(Window._tabs) do
                t._frame.Visible = false
                local lbl = t._sideBtn:FindFirstChildOfClass("TextLabel")
                if lbl then
                    Tween(lbl, { TextColor3 = T.TextSecondary }, 0.12)
                end
                Tween(t._sideBtn, { BackgroundTransparency = 1 }, 0.12)
                Tween(t._qBtn, { BackgroundTransparency = 1 }, 0.1)
                local qs = t._qBtn:FindFirstChildOfClass("UIStroke")
                if qs then qs:Destroy() end
                t._qBtn.TextColor3 = T.TextSecondary
            end

            -- Activate this tab
            TabFrame.Visible = true
            local lbl = SideBtn:FindFirstChildOfClass("TextLabel")
            if lbl then Tween(lbl, { TextColor3 = T.AccentLight }, 0.12) end
            Tween(SideBtn, { BackgroundColor3 = Color3.fromRGB(20, 35, 65), BackgroundTransparency = 0 }, 0.12)
            Tween(QBtn, { BackgroundColor3 = Color3.fromRGB(20, 40, 80), BackgroundTransparency = 0 }, 0.1)
            QBtn.TextColor3 = T.AccentLight
            Stroke(QBtn, T.Border, 1)
            Window._activeTab = Tab
        end

        SideBtn.MouseButton1Click:Connect(ActivateTab)
        QBtn.MouseButton1Click:Connect(ActivateTab)

        SideBtn.MouseEnter:Connect(function()
            if Window._activeTab ~= Tab then
                Tween(SideBtn, { BackgroundColor3 = Color3.fromRGB(18, 28, 48), BackgroundTransparency = 0 }, 0.1)
            end
        end)
        SideBtn.MouseLeave:Connect(function()
            if Window._activeTab ~= Tab then
                Tween(SideBtn, { BackgroundTransparency = 1 }, 0.1)
            end
        end)

        -- Auto-activate first tab (only once, when _tabs is empty)
        if #Window._tabs == 0 then
            task.defer(ActivateTab)
        end

        table.insert(Window._tabs, Tab)

        -- ════════════════════════════════
        --  ADD SECTION
        -- ════════════════════════════════
        function Tab:AddSection(sectionConfig)
            sectionConfig = sectionConfig or {}
            local Section = {}

            local SectionFrame = Create("Frame", {
                Size             = UDim2.new(1, 0, 0, 0),
                AutomaticSize    = Enum.AutomaticSize.Y,
                BackgroundColor3 = T.BackgroundSecond,
                Parent           = TabFrame,
                ZIndex           = 5,
            })
            RoundedCorner(SectionFrame, 8)
            Stroke(SectionFrame, T.Border, 1)
            Padding(SectionFrame, 8, 12, 10, 12)

            local SectionInner = Create("Frame", {
                Size             = UDim2.new(1, 0, 0, 0),
                AutomaticSize    = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Parent           = SectionFrame,
                ZIndex           = 5,
            })
            Create("UIListLayout", {
                FillDirection    = Enum.FillDirection.Vertical,
                Padding          = UDim.new(0, 0),
                Parent           = SectionInner,
            })

            if sectionConfig.Name and sectionConfig.Name ~= "" then
                local SectionHeader = Create("Frame", {
                    Size             = UDim2.new(1, 0, 0, 24),
                    BackgroundTransparency = 1,
                    Parent           = SectionInner,
                    ZIndex           = 6,
                })
                Create("TextLabel", {
                    Size             = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    Text             = sectionConfig.Name:upper(),
                    Font             = Enum.Font.GothamBold,
                    TextSize         = 10,
                    TextColor3       = T.TextSecondary,
                    TextXAlignment   = Enum.TextXAlignment.Left,
                    Parent           = SectionHeader,
                    ZIndex           = 7,
                })
                -- Divider below header
                Create("Frame", {
                    Size             = UDim2.new(1, 0, 0, 1),
                    BackgroundColor3 = T.Divider,
                    BorderSizePixel  = 0,
                    Parent           = SectionInner,
                    ZIndex           = 6,
                })
            end

            Section._inner = SectionInner
            Section._frame = SectionFrame

            -- ────────────────────────────────
            --  CONTROL ROW HELPER
            -- ────────────────────────────────
            local function MakeRow(labelText, descText)
                local Row = Create("Frame", {
                    Size             = UDim2.new(1, 0, 0, descText and 46 or 36),
                    BackgroundTransparency = 1,
                    Parent           = SectionInner,
                    ZIndex           = 6,
                })
                -- Bottom divider
                Create("Frame", {
                    Size             = UDim2.new(1, 0, 0, 1),
                    Position         = UDim2.new(0, 0, 1, -1),
                    BackgroundColor3 = T.Divider,
                    BorderSizePixel  = 0,
                    Parent           = Row,
                    ZIndex           = 6,
                })

                local LabelStack = Create("Frame", {
                    Size             = UDim2.new(0.55, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Parent           = Row,
                    ZIndex           = 6,
                })

                Create("TextLabel", {
                    Size             = UDim2.new(1, 0, 0, 18),
                    Position         = UDim2.fromOffset(0, descText and 8 or 9),
                    BackgroundTransparency = 1,
                    Text             = labelText or "",
                    Font             = Enum.Font.GothamSemibold,
                    TextSize         = 13,
                    TextColor3       = T.TextPrimary,
                    TextXAlignment   = Enum.TextXAlignment.Left,
                    Parent           = LabelStack,
                    ZIndex           = 7,
                })

                if descText then
                    Create("TextLabel", {
                        Size             = UDim2.new(1, 0, 0, 14),
                        Position         = UDim2.fromOffset(0, 26),
                        BackgroundTransparency = 1,
                        Text             = descText,
                        Font             = Enum.Font.Gotham,
                        TextSize         = 10,
                        TextColor3       = T.TextSecondary,
                        TextXAlignment   = Enum.TextXAlignment.Left,
                        Parent           = LabelStack,
                        ZIndex           = 7,
                    })
                end

                local ControlArea = Create("Frame", {
                    Size             = UDim2.new(0.45, 0, 1, 0),
                    Position         = UDim2.fromScale(0.55, 0),
                    BackgroundTransparency = 1,
                    Parent           = Row,
                    ZIndex           = 6,
                })

                return Row, ControlArea
            end

            -- ════════════════════════════
            --  TOGGLE
            -- ════════════════════════════
            function Section:AddToggle(toggleConfig)
                toggleConfig = toggleConfig or {}
                local val = toggleConfig.Default or false
                if toggleConfig.Flag then
                    SkidSoft.Flags[toggleConfig.Flag] = val
                end

                local _, CtrlArea = MakeRow(toggleConfig.Name, toggleConfig.Desc)

                local TrackBG = Create("Frame", {
                    Size             = UDim2.fromOffset(38, 20),
                    Position         = UDim2.new(1, -38, 0.5, -10),
                    BackgroundColor3 = val and T.Toggle_ON or T.Toggle_OFF,
                    Parent           = CtrlArea,
                    ZIndex           = 7,
                })
                RoundedCorner(TrackBG, 10)

                local Knob = Create("Frame", {
                    Size             = UDim2.fromOffset(14, 14),
                    Position         = UDim2.fromOffset(val and 21 or 3, 3),
                    BackgroundColor3 = val and Color3.new(1,1,1) or Color3.fromRGB(100,116,139),
                    Parent           = TrackBG,
                    ZIndex           = 8,
                })
                RoundedCorner(Knob, 7)

                local Toggle = { Value = val }

                local function SetToggle(newVal, skipCallback)
                    Toggle.Value = newVal
                    if toggleConfig.Flag then
                        SkidSoft.Flags[toggleConfig.Flag] = newVal
                    end
                    Tween(TrackBG, { BackgroundColor3 = newVal and T.Toggle_ON or T.Toggle_OFF }, 0.15)
                    Tween(Knob, {
                        Position         = UDim2.fromOffset(newVal and 21 or 3, 3),
                        BackgroundColor3 = newVal and Color3.new(1,1,1) or Color3.fromRGB(100,116,139),
                    }, 0.15)
                    if not skipCallback and toggleConfig.Callback then
                        pcall(toggleConfig.Callback, newVal)
                    end
                end

                TrackBG.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        SetToggle(not Toggle.Value)
                    end
                end)

                function Toggle:Set(v) SetToggle(v) end
                return Toggle
            end

            -- ════════════════════════════
            --  SLIDER
            -- ════════════════════════════
            function Section:AddSlider(sliderConfig)
                sliderConfig = sliderConfig or {}
                local min   = sliderConfig.Min     or 0
                local max   = sliderConfig.Max     or 100
                local def   = sliderConfig.Default or min
                local suf   = sliderConfig.Suffix  or ""

                if sliderConfig.Flag then
                    SkidSoft.Flags[sliderConfig.Flag] = def
                end

                local _, CtrlArea = MakeRow(sliderConfig.Name, sliderConfig.Desc)

                local ValLabel = Create("TextLabel", {
                    Size             = UDim2.fromOffset(40, 20),
                    Position         = UDim2.new(1, -40, 0.5, -10),
                    BackgroundTransparency = 1,
                    Text             = tostring(def) .. suf,
                    Font             = Enum.Font.GothamBold,
                    TextSize         = 12,
                    TextColor3       = T.AccentLight,
                    TextXAlignment   = Enum.TextXAlignment.Right,
                    Parent           = CtrlArea,
                    ZIndex           = 7,
                })

                local TrackBG = Create("Frame", {
                    Size             = UDim2.new(1, -48, 0, 4),
                    Position         = UDim2.new(0, 0, 0.5, -2),
                    BackgroundColor3 = T.SliderBG,
                    ClipsDescendants = true,
                    Parent           = CtrlArea,
                    ZIndex           = 7,
                })
                RoundedCorner(TrackBG, 2)

                local pct = (def - min) / (max - min)
                local Fill = Create("Frame", {
                    Size             = UDim2.new(pct, 0, 1, 0),
                    BackgroundColor3 = T.SliderFill,
                    BorderSizePixel  = 0,
                    Parent           = TrackBG,
                    ZIndex           = 8,
                })
                RoundedCorner(Fill, 2)

                local Thumb = Create("Frame", {
                    Size             = UDim2.fromOffset(12, 12),
                    Position         = UDim2.new(pct, -6, 0.5, -6),
                    BackgroundColor3 = T.AccentLight,
                    Parent           = TrackBG,
                    ZIndex           = 9,
                })
                RoundedCorner(Thumb, 6)

                local Slider = { Value = def }
                local dragging = false

                local function SetSlider(x)
                    local abs = TrackBG.AbsolutePosition.X
                    local sz  = TrackBG.AbsoluteSize.X
                    local p   = math.clamp((x - abs) / sz, 0, 1)
                    local v   = math.round(min + (max - min) * p)
                    Slider.Value = v
                    if sliderConfig.Flag then SkidSoft.Flags[sliderConfig.Flag] = v end
                    Tween(Fill,  { Size = UDim2.new(p, 0, 1, 0) }, 0.05)
                    Tween(Thumb, { Position = UDim2.new(p, -6, 0.5, -6) }, 0.05)
                    ValLabel.Text = tostring(v) .. suf
                    if sliderConfig.Callback then pcall(sliderConfig.Callback, v) end
                end

                TrackBG.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        SetSlider(i.Position.X)
                    end
                end)
                TrackBG.InputEnded:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
                end)
                UserInputService.InputChanged:Connect(function(i)
                    if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                        SetSlider(i.Position.X)
                    end
                end)

                function Slider:Set(v)
                    local p = math.clamp((v - min) / (max - min), 0, 1)
                    Slider.Value = v
                    if sliderConfig.Flag then SkidSoft.Flags[sliderConfig.Flag] = v end
                    Fill.Size     = UDim2.new(p, 0, 1, 0)
                    Thumb.Position = UDim2.new(p, -6, 0.5, -6)
                    ValLabel.Text  = tostring(v) .. suf
                end

                return Slider
            end

            -- ════════════════════════════
            --  DROPDOWN
            -- ════════════════════════════
            function Section:AddDropdown(dropConfig)
                dropConfig = dropConfig or {}
                local options = dropConfig.Options or {}
                local selected = dropConfig.Default or (options[1] or "")
                if dropConfig.Flag then SkidSoft.Flags[dropConfig.Flag] = selected end

                local Row, CtrlArea = MakeRow(dropConfig.Name)
                local isOpen = false

                local BtnFrame = Create("TextButton", {
                    Size             = UDim2.new(1, 0, 0, 22),
                    Position         = UDim2.new(0, 0, 0.5, -11),
                    BackgroundColor3 = Color3.fromRGB(16, 24, 40),
                    Text             = "",
                    AutoButtonColor  = false,
                    Parent           = CtrlArea,
                    ZIndex           = 7,
                })
                RoundedCorner(BtnFrame, 5)
                Stroke(BtnFrame, T.Border, 1)

                local BtnLabel = Create("TextLabel", {
                    Size             = UDim2.new(1, -20, 1, 0),
                    Position         = UDim2.fromOffset(8, 0),
                    BackgroundTransparency = 1,
                    Text             = selected,
                    Font             = Enum.Font.GothamSemibold,
                    TextSize         = 11,
                    TextColor3       = T.TextPrimary,
                    TextXAlignment   = Enum.TextXAlignment.Left,
                    Parent           = BtnFrame,
                    ZIndex           = 8,
                })

                Create("TextLabel", {
                    Size             = UDim2.fromOffset(14, 22),
                    Position         = UDim2.new(1, -16, 0, 0),
                    BackgroundTransparency = 1,
                    Text             = "▾",
                    Font             = Enum.Font.GothamBold,
                    TextSize         = 11,
                    TextColor3       = T.TextSecondary,
                    Parent           = BtnFrame,
                    ZIndex           = 8,
                })

                local DropList = Create("Frame", {
                    Size             = UDim2.new(1, 0, 0, 0),
                    Position         = UDim2.new(0, 0, 1, 2),
                    BackgroundColor3 = Color3.fromRGB(12, 18, 32),
                    ClipsDescendants = true,
                    Visible          = false,
                    Parent           = BtnFrame,
                    ZIndex           = 20,
                })
                RoundedCorner(DropList, 5)
                Stroke(DropList, T.Border, 1)

                local ListLayout = Create("UIListLayout", {
                    FillDirection    = Enum.FillDirection.Vertical,
                    Parent           = DropList,
                })

                local Dropdown = { Value = selected }

                for _, opt in ipairs(options) do
                    local OptBtn = Create("TextButton", {
                        Size             = UDim2.new(1, 0, 0, 24),
                        BackgroundTransparency = 1,
                        Text             = opt,
                        Font             = Enum.Font.Gotham,
                        TextSize         = 11,
                        TextColor3       = T.TextSecondary,
                        AutoButtonColor  = false,
                        Parent           = DropList,
                        ZIndex           = 21,
                    })
                    Padding(OptBtn, 0, 0, 0, 8)
                    OptBtn.MouseEnter:Connect(function()
                        Tween(OptBtn, { BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(20, 35, 65) }, 0.1)
                        OptBtn.TextColor3 = T.TextPrimary
                    end)
                    OptBtn.MouseLeave:Connect(function()
                        Tween(OptBtn, { BackgroundTransparency = 1 }, 0.1)
                        OptBtn.TextColor3 = T.TextSecondary
                    end)
                    OptBtn.MouseButton1Click:Connect(function()
                        Dropdown.Value = opt
                        BtnLabel.Text = opt
                        if dropConfig.Flag then SkidSoft.Flags[dropConfig.Flag] = opt end
                        if dropConfig.Callback then pcall(dropConfig.Callback, opt) end
                        isOpen = false
                        Tween(DropList, { Size = UDim2.new(1, 0, 0, 0) }, 0.15)
                        task.delay(0.15, function() DropList.Visible = false end)
                    end)
                end

                local totalH = #options * 24
                BtnFrame.MouseButton1Click:Connect(function()
                    isOpen = not isOpen
                    if isOpen then
                        DropList.Visible = true
                        Tween(DropList, { Size = UDim2.new(1, 0, 0, totalH) }, 0.18)
                    else
                        Tween(DropList, { Size = UDim2.new(1, 0, 0, 0) }, 0.15)
                        task.delay(0.15, function() DropList.Visible = false end)
                    end
                end)

                function Dropdown:Set(v)
                    Dropdown.Value = v
                    BtnLabel.Text = v
                    if dropConfig.Flag then SkidSoft.Flags[dropConfig.Flag] = v end
                end

                return Dropdown
            end

            -- ════════════════════════════
            --  BUTTON
            -- ════════════════════════════
            function Section:AddButton(btnConfig)
                btnConfig = btnConfig or {}
                local Row, CtrlArea = MakeRow(btnConfig.Name, btnConfig.Desc)

                local Btn = Create("TextButton", {
                    Size             = UDim2.fromOffset(80, 24),
                    Position         = UDim2.new(1, -80, 0.5, -12),
                    BackgroundColor3 = T.Accent,
                    Text             = "Execute",
                    Font             = Enum.Font.GothamBold,
                    TextSize         = 12,
                    TextColor3       = Color3.new(1,1,1),
                    AutoButtonColor  = false,
                    Parent           = CtrlArea,
                    ZIndex           = 7,
                })
                RoundedCorner(Btn, 5)
                Btn.MouseEnter:Connect(function() Tween(Btn, { BackgroundColor3 = T.AccentLight }, 0.12) end)
                Btn.MouseLeave:Connect(function() Tween(Btn, { BackgroundColor3 = T.Accent }, 0.12) end)
                Btn.MouseButton1Click:Connect(function()
                    Tween(Btn, { BackgroundColor3 = T.AccentDark }, 0.05)
                    task.delay(0.1, function() Tween(Btn, { BackgroundColor3 = T.Accent }, 0.12) end)
                    if btnConfig.Callback then pcall(btnConfig.Callback) end
                end)

                return Btn
            end

            -- ════════════════════════════
            --  TEXTBOX (input)
            -- ════════════════════════════
            function Section:AddTextBox(tbConfig)
                tbConfig = tbConfig or {}
                local Row, CtrlArea = MakeRow(tbConfig.Name)

                local TBFrame = Create("Frame", {
                    Size             = UDim2.new(1, 0, 0, 22),
                    Position         = UDim2.new(0, 0, 0.5, -11),
                    BackgroundColor3 = Color3.fromRGB(16, 24, 40),
                    Parent           = CtrlArea,
                    ZIndex           = 7,
                })
                RoundedCorner(TBFrame, 5)
                Stroke(TBFrame, T.Border, 1)

                local TB = Create("TextBox", {
                    Size             = UDim2.new(1, -8, 1, 0),
                    Position         = UDim2.fromOffset(4, 0),
                    BackgroundTransparency = 1,
                    Text             = tbConfig.Default or "",
                    PlaceholderText  = tbConfig.Placeholder or "",
                    PlaceholderColor3 = T.TextSecondary,
                    Font             = Enum.Font.Gotham,
                    TextSize         = 11,
                    TextColor3       = T.TextPrimary,
                    ClearTextOnFocus = false,
                    Parent           = TBFrame,
                    ZIndex           = 8,
                })

                TB.Focused:Connect(function()
                    Stroke(TBFrame, T.Accent, 1)
                end)
                TB.FocusLost:Connect(function(enter)
                    Stroke(TBFrame, T.Border, 1)
                    if tbConfig.Flag then SkidSoft.Flags[tbConfig.Flag] = TB.Text end
                    if tbConfig.Callback then pcall(tbConfig.Callback, TB.Text) end
                end)

                local TBObj = { Value = TB.Text }
                function TBObj:Set(v) TB.Text = v end
                return TBObj
            end

            -- ════════════════════════════
            --  LABEL (info row)
            -- ════════════════════════════
            function Section:AddLabel(text)
                local lbl = Create("TextLabel", {
                    Size             = UDim2.new(1, 0, 0, 20),
                    BackgroundTransparency = 1,
                    Text             = text or "",
                    Font             = Enum.Font.Gotham,
                    TextSize         = 11,
                    TextColor3       = T.TextSecondary,
                    TextXAlignment   = Enum.TextXAlignment.Left,
                    TextWrapped      = true,
                    Parent           = SectionInner,
                    ZIndex           = 6,
                })
                return lbl
            end

            -- ════════════════════════════
            --  DIVIDER
            -- ════════════════════════════
            function Section:AddDivider()
                Create("Frame", {
                    Size             = UDim2.new(1, 0, 0, 1),
                    BackgroundColor3 = T.Divider,
                    BorderSizePixel  = 0,
                    Parent           = SectionInner,
                    ZIndex           = 6,
                })
            end

            table.insert(Tab._sections, Section)
            return Section
        end

        -- ════════════════════════════════════════
        --  KEY SYSTEM INTEGRATION (after all tabs added, ensure first tab visible)
        -- ════════════════════════════════════════
        if config.KeySystem and config.KeyConfig then
            Shell.Visible = false
            CreateKeySystem(ScreenGui, config.KeyConfig, function()
                Shell.Visible = true
                -- if no active tab (e.g., key system got called before tabs), activate first
                if not Window._activeTab and Window._tabs[1] then
                    local firstTab = Window._tabs[1]
                    firstTab._frame.Visible = true
                    Window._activeTab = firstTab
                    local sideLbl = firstTab._sideBtn:FindFirstChildOfClass("TextLabel")
                    if sideLbl then Tween(sideLbl, { TextColor3 = T.AccentLight }, 0.12) end
                    Tween(firstTab._sideBtn, { BackgroundColor3 = Color3.fromRGB(20, 35, 65), BackgroundTransparency = 0 }, 0.12)
                    Tween(firstTab._qBtn, { BackgroundColor3 = Color3.fromRGB(20, 40, 80), BackgroundTransparency = 0 }, 0.1)
                    firstTab._qBtn.TextColor3 = T.AccentLight
                    Stroke(firstTab._qBtn, T.Border, 1)
                end
                SkidSoft:Notify({ Title = "SkidSoft", Desc = "Authenticated successfully!", Type = "success", Duration = 3 })
            end)
        end

        return Tab
    end

    -- Expose notify on window too
    function Window:Notify(c) SkidSoft.Notify(SkidSoft, c) end

    table.insert(SkidSoft._windows, Window)
    return Window
end

-- ════════════════════════════════════════════
--  DESTROY / CLEANUP
-- ════════════════════════════════════════════
function SkidSoft:Destroy()
    local gui = CoreGui:FindFirstChild("SkidSoftUI")
    if gui then gui:Destroy() end
    for _, conn in ipairs(self._connections) do conn:Disconnect() end
    self._connections = {}
    self._windows = {}
    self.Flags = {}
end

return SkidSoft
