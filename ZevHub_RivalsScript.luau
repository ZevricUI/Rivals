-- ============================================================================
-- [ 1 ] SERVICES
-- ============================================================================
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local CoreGui           = game:GetService("CoreGui")
local CollectionService = game:GetService("CollectionService")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

local has_hookfunction = type(hookfunction) == "function"
local has_newcclosure  = type(newcclosure) == "function"
local has_drawing      = pcall(function() return Drawing.new("Circle") end)

repeat task.wait() until game:IsLoaded()

-- ============================================================================
-- [ 2 ] MODULE LOADER
-- ============================================================================
local function SafeRequire(instance)
    if not instance then return nil end
    local ok, res = pcall(require, instance)
    return ok and res or nil
end

local Modules       = ReplicatedStorage:WaitForChild("Modules", 15)
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts", 15)
local Controllers   = PlayerScripts and PlayerScripts:WaitForChild("Controllers", 15)

local FighterController = Controllers and SafeRequire(Controllers:FindFirstChild("FighterController"))
local CameraController  = Controllers and SafeRequire(Controllers:FindFirstChild("CameraController"))

-- ============================================================================
-- [ 3 ] CONFIG
-- ============================================================================
getgenv().RivalsConfig = {
    Aimbot            = false,
    AimbotSpeed       = 35,
    AimbotKey         = "E",
    AimbotFOV         = 200,
    AimbotPart        = "Head",

    Triggerbot        = false,
    TriggerbotDelay   = 50,
    TriggerbotVisible = true,

    ESP               = true,
    ESPShowName       = true,
    ESPShowHealth     = true,
    ESPShowDistance   = true,
    ESPShowBox        = true,
    ESPShowTracer     = false,
    ESPShowHeadDot    = false,
    ESPMaxDistance    = 1000,
    ESPVisibleColor   = Color3.fromRGB(0, 255, 0),
    ESPHiddenColor    = Color3.fromRGB(255, 0, 0),
    ESPTeamCheck      = true,
    ESPTextSize       = 14,

    SpeedHack         = false,
    SpeedValue        = 32,
    InfiniteJump      = false,

    SelfNameSpoof     = false,
    SelfSpoofedName   = "ILikeFeet",
    EnemyNameSpoof    = false,
    EnemySpoofedName  = "IDontLikeFeet",

    WinstreakSpoof    = false,
    SpoofedWinstreak  = 56,
}
local Config = getgenv().RivalsConfig

local DEFAULT_WALKSPEED = 16

-- ============================================================================
-- [ 4 ] UI LIBRARY
-- ============================================================================
local Library = {}
Library.__index = Library

local Theme = {
    Background  = Color3.fromRGB(13, 13, 18),
    Panel       = Color3.fromRGB(22, 22, 30),
    PanelDark   = Color3.fromRGB(16, 16, 22),
    Outline     = Color3.fromRGB(35, 35, 45),
    Text        = Color3.fromRGB(240, 240, 245),
    TextDim     = Color3.fromRGB(140, 140, 155),
    Accent      = Color3.fromRGB(125, 85, 255),
    AccentSoft  = Color3.fromRGB(160, 130, 255),
    Success     = Color3.fromRGB(80, 220, 130),
    Danger      = Color3.fromRGB(255, 90, 90),
    CardBg      = Color3.fromRGB(26, 26, 36),
    CardOutline = Color3.fromRGB(45, 45, 60),
    Font        = Enum.Font.Gotham,
    FontBold    = Enum.Font.GothamBold,
    FontMedium  = Enum.Font.GothamMedium,
}

local function Create(cls, props)
    local i = Instance.new(cls)
    for k, v in pairs(props or {}) do i[k] = v end
    return i
end
local function Corner(r) return Create("UICorner", {CornerRadius = UDim.new(0, r or 8)}) end
local function Stroke(c, t)
    return Create("UIStroke", {
        Color = c or Theme.Outline, Thickness = t or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    })
end

local function GetParent()
    if gethui then
        local ok, hui = pcall(gethui)
        if ok and hui then return hui end
    end
    return CoreGui
end

local ScreenGui = Create("ScreenGui", {
    Name = "ZevHubUI", ResetOnSpawn = false,
    IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
if syn and syn.protect_gui then pcall(syn.protect_gui, ScreenGui) end
ScreenGui.Parent = GetParent()

local function MakeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

function Library:CreateWindow(cfg)
    cfg = cfg or {}
    local title    = cfg.Title or "Axonic"
    local subtitle = cfg.Subtitle or "RIVALS"
    local size     = cfg.Size or UDim2.fromOffset(820, 620)

    local Main = Create("Frame", {
        Name = "Main", Parent = ScreenGui, Size = size,
        Position = UDim2.new(0.5, -size.X.Offset/2, 0.5, -size.Y.Offset/2),
        BackgroundColor3 = Theme.Background, BorderSizePixel = 0, Active = false,
    })
    Corner(14).Parent = Main
    Stroke(Theme.Outline, 1).Parent = Main

    local TopBar = Create("Frame", {
        Name = "TopBar", Parent = Main, Size = UDim2.new(1, 0, 0, 64),
        BackgroundColor3 = Theme.Background, BorderSizePixel = 0, ZIndex = 2, Active = true,
    })
    Corner(14).Parent = TopBar
    Create("Frame", {
        Parent = TopBar, Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = Theme.Outline,
        BorderSizePixel = 0
    })

    local TitleFrame = Create("Frame", {
        Parent = TopBar, Size = UDim2.new(0, 300, 1, 0),
        Position = UDim2.fromOffset(20, 0), BackgroundTransparency = 1
    })
    Create("TextLabel", {
        Parent = TitleFrame, Size = UDim2.new(1, 0, 0, 22), Position = UDim2.fromOffset(0, 12),
        BackgroundTransparency = 1, Text = title, Font = Theme.FontBold, TextSize = 18,
        TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, Active = false,
    })
    Create("TextLabel", {
        Parent = TitleFrame, Size = UDim2.new(1, 0, 0, 14), Position = UDim2.fromOffset(0, 32),
        BackgroundTransparency = 1, Text = subtitle, Font = Theme.Font, TextSize = 12,
        TextColor3 = Theme.TextDim, TextXAlignment = Enum.TextXAlignment.Left, Active = false,
    })

    local fpsPill = Create("Frame", {
        Parent = TopBar, Size = UDim2.fromOffset(80, 24),
        Position = UDim2.new(1, -180, 0, 20),
        BackgroundColor3 = Theme.Panel, BorderSizePixel = 0, Active = false,
    })
    Corner(6).Parent = fpsPill
    Stroke(Theme.CardOutline, 1).Parent = fpsPill
    local fpsLbl = Create("TextLabel", {
        Parent = fpsPill, Size = UDim2.new(1, -12, 1, 0), Position = UDim2.fromOffset(6, 0),
        BackgroundTransparency = 1, Text = "FPS --", Font = Theme.FontMedium, TextSize = 12,
        TextColor3 = Theme.Success, TextXAlignment = Enum.TextXAlignment.Center, Active = false,
    })
    spawn(function()
        local frames, last = 0, tick()
        RunService.RenderStepped:Connect(function()
            frames = frames + 1
            if tick() - last >= 1 then
                fpsLbl.Text = "FPS " .. frames
                frames = 0
                last = tick()
            end
        end)
    end)

    local CloseBtn = Create("TextButton", {
        Parent = TopBar, Size = UDim2.fromOffset(24, 24),
        Position = UDim2.new(1, -40, 0, 20),
        BackgroundTransparency = 1, Text = "✕", Font = Theme.FontBold,
        TextSize = 16, TextColor3 = Theme.Danger, AutoButtonColor = false
    })
    CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

    MakeDraggable(Main, TopBar)

    local Body = Create("Frame", {
        Name = "Body", Parent = Main, Size = UDim2.new(1, 0, 1, -64),
        Position = UDim2.fromOffset(0, 64), BackgroundTransparency = 1, Active = false,
    })

    local Sidebar = Create("Frame", {
        Parent = Body, Size = UDim2.new(0, 190, 1, -20),
        Position = UDim2.fromOffset(15, 10), BackgroundTransparency = 1,
    })
    Create("UIListLayout", {
        Parent = Sidebar, Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    local Content = Create("Frame", {
        Parent = Body, Size = UDim2.new(1, -220, 1, -20),
        Position = UDim2.fromOffset(215, 10), BackgroundTransparency = 1,
    })

    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.RightControl then
            Main.Visible = not Main.Visible
        end
    end)

    local Window = {Main = Main, Tabs = {}, ActiveTab = nil}

    function Window:AddTab(name, icon)
        icon = icon or "•"

        local TabBtn = Create("TextButton", {
            Parent = Sidebar, Size = UDim2.new(1, 0, 0, 40),
            BackgroundColor3 = Theme.Panel, BackgroundTransparency = 1,
            Text = "", AutoButtonColor = false, Active = true,
        })
        Corner(8).Parent = TabBtn

        Create("TextLabel", {
            Parent = TabBtn, Size = UDim2.fromOffset(20, 20), Position = UDim2.fromOffset(14, 10),
            BackgroundTransparency = 1, Text = icon, Font = Theme.FontBold, TextSize = 14,
            TextColor3 = Theme.TextDim, TextXAlignment = Enum.TextXAlignment.Center,
            Active = false,
        })
        local NameLbl = Create("TextLabel", {
            Parent = TabBtn, Size = UDim2.new(1, -50, 1, 0), Position = UDim2.fromOffset(42, 0),
            BackgroundTransparency = 1, Text = name, Font = Theme.FontMedium, TextSize = 13,
            TextColor3 = Theme.TextDim, TextXAlignment = Enum.TextXAlignment.Left,
            Active = false,
        })
        local Indicator = Create("Frame", {
            Parent = TabBtn, Size = UDim2.new(0, 3, 0.6, 0),
            Position = UDim2.new(0, 0, 0.2, 0), BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0, Visible = false, Active = false,
        })
        Corner(2).Parent = Indicator

        local Page = Create("ScrollingFrame", {
            Parent = Content,
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.fromOffset(0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = Theme.Accent,
            ScrollBarImageTransparency = 0.3,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            Visible = false,
        })
        Create("UIListLayout", {
            Parent = Page, Padding = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder
        })

        local Tab = {
            Name = name,
            Button = TabBtn,
            Page = Page,
            Sections = {},
            Icon = icon,
            NameLabel = NameLbl,
            Indicator = Indicator,
        }

        function Tab:Select()
            if Window.ActiveTab == Tab then return end
            for _, otherTab in ipairs(Window.Tabs) do
                if otherTab ~= Tab then
                    TweenService:Create(otherTab.Button, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
                    if otherTab.NameLabel then
                        otherTab.NameLabel.TextColor3 = Theme.TextDim
                    end
                    if otherTab.Indicator then
                        otherTab.Indicator.Visible = false
                    end
                    otherTab.Page.Visible = false
                end
            end
            Window.ActiveTab = Tab
            TweenService:Create(TabBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
            NameLbl.TextColor3 = Theme.Text
            Indicator.Visible = true
            Page.Visible = true
        end

        TabBtn.MouseButton1Click:Connect(function() Tab:Select() end)
        table.insert(Window.Tabs, Tab)
        if #Window.Tabs == 1 then Tab:Select() end
        return Tab
    end

    function Window:AddSection(tab, name)
        local Section = Create("Frame", {
            Parent = tab.Page,
            Size = UDim2.new(1, 0, 0, 40),
            BackgroundColor3 = Theme.CardBg, BorderSizePixel = 0,
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = #tab.Sections + 1,
        })
        Corner(10).Parent = Section
        Stroke(Theme.CardOutline, 1).Parent = Section
        Create("UIPadding", {
            PaddingBottom = UDim.new(0, 12),
            PaddingLeft = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 12),
            PaddingTop = UDim.new(0, 12),
            Parent = Section,
        })
        Create("TextLabel", {
            Parent = Section, Size = UDim2.new(1, 0, 0, 16), Position = UDim2.fromOffset(0, 0),
            BackgroundTransparency = 1, Text = name, Font = Theme.FontBold, TextSize = 11,
            TextColor3 = Theme.TextDim, TextXAlignment = Enum.TextXAlignment.Left,
            Active = false,
        })
        local Inner = Create("Frame", {
            Parent = Section, Size = UDim2.new(1, 0, 0, 0), Position = UDim2.fromOffset(0, 24),
            BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y,
        })
        Create("UIListLayout", {
            Parent = Inner, Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder
        })
        local obj = {Frame = Section, Inner = Inner, Name = name}
        table.insert(tab.Sections, obj)
        return obj
    end

    function Window:AddButton(section, text, callback)
        local Btn = Create("TextButton", {
            Parent = section.Inner, Size = UDim2.new(1, 0, 0, 28),
            BackgroundColor3 = Theme.Panel, BorderSizePixel = 0,
            Text = "", AutoButtonColor = false, Active = true,
        })
        Corner(6).Parent = Btn
        Stroke(Theme.CardOutline, 1).Parent = Btn
        Create("TextLabel", {
            Parent = Btn, Size = UDim2.new(1, -20, 1, 0), Position = UDim2.fromOffset(10, 0),
            BackgroundTransparency = 1, Text = text, Font = Theme.FontMedium, TextSize = 12,
            TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
            Active = false,
        })
        Btn.MouseEnter:Connect(function()
            TweenService:Create(Btn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.CardBg}):Play()
        end)
        Btn.MouseLeave:Connect(function()
            TweenService:Create(Btn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Panel}):Play()
        end)
        Btn.MouseButton1Click:Connect(function()
            if callback then
                local ok, err = pcall(callback)
                if not ok then warn("[UI Button] " .. tostring(err)) end
            end
        end)
        return Btn
    end

    function Window:AddToggle(section, text, default, callback)
        local state = default == true
        local Holder = Create("TextButton", {
            Parent = section.Inner, Size = UDim2.new(1, 0, 0, 26),
            BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Active = true,
        })
        local Label = Create("TextLabel", {
            Parent = Holder, Size = UDim2.new(1, -55, 1, 0), Position = UDim2.fromOffset(0, 0),
            BackgroundTransparency = 1, Text = text, Font = Theme.FontMedium, TextSize = 12,
            TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, Active = false,
        })
        local Switch = Create("Frame", {
            Parent = Holder, Size = UDim2.fromOffset(40, 20),
            Position = UDim2.new(1, -40, 0.5, -10),
            BackgroundColor3 = state and Theme.Accent or Theme.PanelDark,
            BorderSizePixel = 0,
        })
        Corner(10).Parent = Switch
        local SwitchStroke = Stroke(state and Theme.Accent or Theme.CardOutline, 1)
        SwitchStroke.Parent = Switch
        local Knob = Create("Frame", {
            Parent = Switch, Size = UDim2.fromOffset(14, 14),
            Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.fromOffset(3, 3),
            BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
        })
        Corner(7).Parent = Knob

        local function SetVisual(v)
            state = v == true
            TweenService:Create(Switch, TweenInfo.new(0.15), {
                BackgroundColor3 = state and Theme.Accent or Theme.PanelDark
            }):Play()
            TweenService:Create(SwitchStroke, TweenInfo.new(0.15), {
                Color = state and Theme.Accent or Theme.CardOutline
            }):Play()
            TweenService:Create(Knob, TweenInfo.new(0.15), {
                Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.fromOffset(3, 3)
            }):Play()
        end

        local function Update(v)
            SetVisual(v)
            if callback then
                local ok, err = pcall(callback, state)
                if not ok then warn("[UI Toggle] " .. tostring(err)) end
            end
        end

        Holder.MouseButton1Click:Connect(function()
            Update(not state)
        end)

        return { Set = Update, Get = function() return state end }
    end

    function Window:AddSlider(section, text, default, min, max, callback)
        local value = default or min
        local Holder = Create("Frame", {
            Parent = section.Inner, Size = UDim2.new(1, 0, 0, 36),
            BackgroundTransparency = 1,
        })
        Create("TextLabel", {
            Parent = Holder, Size = UDim2.new(1, -50, 0, 16), Position = UDim2.fromOffset(0, 0),
            BackgroundTransparency = 1, Text = text, Font = Theme.FontMedium, TextSize = 12,
            TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, Active = false,
        })
        local ValueLbl = Create("TextLabel", {
            Parent = Holder, Size = UDim2.fromOffset(50, 16), Position = UDim2.new(1, -50, 0, 0),
            BackgroundTransparency = 1, Text = tostring(value), Font = Theme.FontBold,
            TextSize = 12, TextColor3 = Theme.AccentSoft, TextXAlignment = Enum.TextXAlignment.Right,
            Active = false,
        })
        local Bar = Create("TextButton", {
            Parent = Holder, Size = UDim2.new(1, 0, 0, 8), Position = UDim2.fromOffset(0, 22),
            BackgroundColor3 = Theme.PanelDark, BorderSizePixel = 0,
            Text = "", AutoButtonColor = false, Active = true,
        })
        Corner(4).Parent = Bar
        local Fill = Create("Frame", {
            Parent = Bar, Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
            BackgroundColor3 = Theme.Accent, BorderSizePixel = 0,
        })
        Corner(4).Parent = Fill
        local dragging = false

        local function SetValue(newVal, fireCallback)
            newVal = math.clamp(math.floor(newVal + 0.5), min, max)
            if newVal == value and fireCallback ~= true then return end
            value = newVal
            Fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
            ValueLbl.Text = tostring(value)
            if fireCallback and callback then
                local ok, err = pcall(callback, value)
                if not ok then warn("[UI Slider] " .. tostring(err)) end
            end
        end

        local function UpdateFromX(x)
            local rel = math.clamp((x - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
            SetValue(min + (max - min) * rel, true)
        end

        Bar.MouseButton1Down:Connect(function(x, y)
            dragging = true
            UpdateFromX(x)
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch) then
                UpdateFromX(input.Position.X)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)

        return {
            Set = function(v) SetValue(v, true) end,
            Get = function() return value end,
        }
    end

    function Window:AddInput(section, text, default, callback)
        local value = default or ""
        local Holder = Create("Frame", {
            Parent = section.Inner, Size = UDim2.new(1, 0, 0, 40),
            BackgroundTransparency = 1,
        })
        Create("TextLabel", {
            Parent = Holder, Size = UDim2.new(1, 0, 0, 14), Position = UDim2.fromOffset(0, 0),
            BackgroundTransparency = 1, Text = text, Font = Theme.FontMedium, TextSize = 12,
            TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, Active = false,
        })
        local Box = Create("TextBox", {
            Parent = Holder, Size = UDim2.new(1, 0, 0, 22), Position = UDim2.fromOffset(0, 16),
            BackgroundColor3 = Theme.PanelDark, BorderSizePixel = 0,
            Text = value, Font = Theme.FontMedium, TextSize = 12,
            TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
            PlaceholderText = "Enter name...", PlaceholderColor3 = Theme.TextDim,
            ClearTextOnFocus = false, Active = true,
        })
        Corner(6).Parent = Box
        Stroke(Theme.CardOutline, 1).Parent = Box
        Create("UIPadding", {
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            Parent = Box,
        })

        Box.FocusLost:Connect(function()
            value = Box.Text
            if callback then
                local ok, err = pcall(callback, value)
                if not ok then warn("[UI Input] " .. tostring(err)) end
            end
        end)

        return {
            Set = function(v) value = v; Box.Text = v end,
            Get = function() return value end,
        }
    end

    return Window
end

-- ============================================================================
-- [ 5 ] WINDOW
-- ============================================================================
local Window = Library:CreateWindow({
    Title = "ZevHub", Subtitle = "Rivals Script",
    Size = UDim2.fromOffset(820, 620),
})

-- ============================================================================
-- [ 6 ] HELPERS
-- ============================================================================
local function GetLocalCharacter()
    local char = LocalPlayer.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return nil end
    return char, hrp, hum
end

local function IsAlive(character)
    if not character then return false end
    local hum = character:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function IsEnemy(player)
    if not player or player == LocalPlayer then return false end
    if Config.ESPTeamCheck then
        local myTeam = LocalPlayer:GetAttribute("TeamID")
        local theirTeam = player:GetAttribute("TeamID")
        if myTeam and theirTeam then
            return myTeam ~= theirTeam
        end
    end
    return true
end

-- ============================================================================
-- [ 7 ] AIMBOT
-- ============================================================================
local AimbotState = { Holding = false }

local function GetAimbotTarget()
    if not Camera then return nil end
    local char, hrp = GetLocalCharacter()
    if not char or not hrp then return nil end

    local center = Camera.ViewportSize / 2
    local fovRadius = Config.AimbotFOV or 200
    local bestTarget, bestDist = nil, fovRadius
    local seen = {}

    local function ConsiderModel(model)
        if not model or seen[model] then return end
        seen[model] = true
        if not model:IsA("Model") then return end

        local player = Players:GetPlayerFromCharacter(model)
        if not player or player == LocalPlayer then return end
        if not IsEnemy(player) then return end
        if not IsAlive(model) then return end

        local partName = Config.AimbotPart or "Head"
        local part = nil
        if partName == "Head" then
            part = model:FindFirstChild("HitboxHead", true) or model:FindFirstChild("Head")
        else
            part = model:FindFirstChild("HitboxBody", true) or model:FindFirstChild("HumanoidRootPart")
        end
        if not part or not part:IsA("BasePart") then return end

        local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen or sp.Z <= 0 then return end

        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
        if d < bestDist then
            bestDist = d
            bestTarget = part
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            ConsiderModel(player.Character)
        end
    end

    return bestTarget
end

local function ApplyAimbotToCamera(dt)
    if not Config.Aimbot or not AimbotState.Holding then return end
    if not Camera then return end

    local target = GetAimbotTarget()
    if not target then return end

    local aimSpeed = Config.AimbotSpeed or 35
    local alpha = math.clamp(1 - math.exp(-dt * aimSpeed * 0.3), 0, 1)

    local camPos = Camera.CFrame.Position
    local targetPos = target.Position

    local currentLook = Camera.CFrame.LookVector
    local desiredLook = (targetPos - camPos).Unit
    local newLook = currentLook:Lerp(desiredLook, alpha).Unit

    Camera.CFrame = CFrame.lookAt(camPos, camPos + newLook)
end

if RunService and RunService.BindToRenderStep then
    pcall(function() RunService:UnbindFromRenderStep("AxonicAimbot") end)
    pcall(function()
        RunService:BindToRenderStep("AxonicAimbot", Enum.RenderPriority.Camera.Value + 1, function(dt)
            ApplyAimbotToCamera(dt)
        end)
    end)
end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if not Config.Aimbot then return end
    if input.KeyCode and input.KeyCode.Name == "E" then
        AimbotState.Holding = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode and input.KeyCode.Name == "E" then
        AimbotState.Holding = false
    end
end)

-- ============================================================================
-- [ 8 ] TRIGGERBOT
-- ============================================================================
local TriggerbotState = { LastShotAt = 0 }

local function FireTriggerbotShot()
    local now = tick()
    local delay = (Config.TriggerbotDelay or 50) / 1000
    if now - TriggerbotState.LastShotAt < delay then return end
    TriggerbotState.LastShotAt = now

    local vim = game:GetService("VirtualInputManager")
    local mousePos = UserInputService:GetMouseLocation()
    pcall(function()
        vim:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, true, game, 1)
        task.defer(function()
            vim:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, false, game, 1)
        end)
    end)
end

RunService.Heartbeat:Connect(function()
    if not Config.Triggerbot then return end
    local char = GetLocalCharacter()
    if not char or not Camera then return end

    local mousePos = UserInputService:GetMouseLocation()
    local ray = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    rp.FilterDescendantsInstances = {char}
    local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, rp)
    if not result then return end

    local hitModel = result.Instance:FindFirstAncestorOfClass("Model")
    if not hitModel then return end

    local player = Players:GetPlayerFromCharacter(hitModel)
    if not player or player == LocalPlayer then return end
    if not IsEnemy(player) then return end
    if Config.TriggerbotVisible and not IsAlive(hitModel) then return end

    FireTriggerbotShot()
end)

-- ============================================================================
-- [ 9 ] ESP
-- ============================================================================
local ESPCache = {}

local function CreateESPEntry(player)
    if ESPCache[player] then return ESPCache[player] end
    if not has_drawing then return nil end

    local entry = {
        Player = player,
        Box = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        Health = Drawing.new("Text"),
        Distance = Drawing.new("Text"),
        Tracer = Drawing.new("Line"),
        HeadDot = Drawing.new("Circle"),
    }
    entry.Box.Thickness = 1
    entry.Box.Transparency = 1
    entry.Box.Filled = false
    entry.Box.Visible = false
    entry.Name.Center = true
    entry.Name.Outline = true
    entry.Name.Font = 2
    entry.Name.Visible = false
    entry.Health.Center = true
    entry.Health.Outline = true
    entry.Health.Visible = false
    entry.Distance.Center = true
    entry.Distance.Outline = true
    entry.Distance.Visible = false
    entry.Tracer.Thickness = 1
    entry.Tracer.Transparency = 1
    entry.Tracer.Visible = false
    entry.HeadDot.Filled = true
    entry.HeadDot.NumSides = 12
    entry.HeadDot.Visible = false

    ESPCache[player] = entry
    return entry
end

local function HideESPEntry(entry)
    if not entry then return end
    if entry.Box then entry.Box.Visible = false end
    if entry.Name then entry.Name.Visible = false end
    if entry.Health then entry.Health.Visible = false end
    if entry.Distance then entry.Distance.Visible = false end
    if entry.Tracer then entry.Tracer.Visible = false end
    if entry.HeadDot then entry.HeadDot.Visible = false end
end

local function UpdateESP()
    if not has_drawing then return end
    if not Config.ESP then
        for _, entry in pairs(ESPCache) do HideESPEntry(entry) end
        return
    end
    if not Camera then return end

    local char, hrp = GetLocalCharacter()
    local localRoot = hrp and hrp.Position or nil
    local textSize = Config.ESPTextSize or 14

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local pchar = player.Character
        local entry = ESPCache[player]

        if not pchar or not IsAlive(pchar) or not IsEnemy(player) then
            if entry then HideESPEntry(entry) end
            continue
        end

        local root = pchar:FindFirstChild("HumanoidRootPart")
        local head = pchar:FindFirstChild("Head")
        local hum = pchar:FindFirstChildOfClass("Humanoid")
        if not root or not head or not hum then
            if entry then HideESPEntry(entry) end
            continue
        end

        local dist = localRoot and (root.Position - localRoot).Magnitude or 0
        if dist > Config.ESPMaxDistance then
            if entry then HideESPEntry(entry) end
            continue
        end

        entry = entry or CreateESPEntry(player)
        if not entry then continue end

        local visible = true
        if localRoot then
            local rp = RaycastParams.new()
            rp.FilterType = Enum.RaycastFilterType.Exclude
            rp.FilterDescendantsInstances = {char, pchar}
            local hit = workspace:Raycast(localRoot, head.Position - localRoot, rp)
            visible = hit == nil
        end
        local color = visible and Config.ESPVisibleColor or Config.ESPHiddenColor

        local headScreen, headOn = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
        local rootScreen, rootOn = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
        if not headOn or not rootOn or headScreen.Z <= 0 then
            HideESPEntry(entry)
            continue
        end

        local boxHeight = math.abs(rootScreen.Y - headScreen.Y)
        local boxWidth = math.max(boxHeight * 0.55, 30)
        local boxX = headScreen.X - boxWidth / 2
        local boxY = headScreen.Y

        if Config.ESPShowBox and entry.Box then
            entry.Box.Position = Vector2.new(boxX, boxY)
            entry.Box.Size = Vector2.new(boxWidth, boxHeight)
            entry.Box.Color = color
            entry.Box.Visible = true
        elseif entry.Box then
            entry.Box.Visible = false
        end

        if Config.ESPShowName and entry.Name then
            entry.Name.Size = textSize
            entry.Name.Text = player.Name
            entry.Name.Position = Vector2.new(headScreen.X, boxY - textSize - 2)
            entry.Name.Color = color
            entry.Name.Visible = true
        elseif entry.Name then
            entry.Name.Visible = false
        end

        if Config.ESPShowHealth and entry.Health then
            entry.Health.Size = textSize - 2
            entry.Health.Text = tostring(math.floor(hum.Health)) .. " HP"
            entry.Health.Position = Vector2.new(headScreen.X, boxY + boxHeight + 2)
            entry.Health.Color = color
            entry.Health.Visible = true
        elseif entry.Health then
            entry.Health.Visible = false
        end

        if Config.ESPShowDistance and entry.Distance then
            entry.Distance.Size = textSize - 2
            entry.Distance.Text = tostring(math.floor(dist)) .. "m"
            entry.Distance.Position = Vector2.new(headScreen.X, boxY + boxHeight + textSize - 2)
            entry.Distance.Color = color
            entry.Distance.Visible = true
        elseif entry.Distance then
            entry.Distance.Visible = false
        end

        if Config.ESPShowTracer and entry.Tracer then
            entry.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            entry.Tracer.To = Vector2.new(headScreen.X, headScreen.Y)
            entry.Tracer.Color = color
            entry.Tracer.Visible = true
        elseif entry.Tracer then
            entry.Tracer.Visible = false
        end

        if Config.ESPShowHeadDot and entry.HeadDot then
            entry.HeadDot.Position = Vector2.new(headScreen.X, headScreen.Y)
            entry.HeadDot.Radius = 4
            entry.HeadDot.Color = color
            entry.HeadDot.Visible = true
        elseif entry.HeadDot then
            entry.HeadDot.Visible = false
        end
    end
end

RunService.RenderStepped:Connect(UpdateESP)

Players.PlayerRemoving:Connect(function(player)
    local entry = ESPCache[player]
    if entry then
        for _, obj in pairs(entry) do
            if typeof(obj) == "Instance" and obj.Remove then
                pcall(function() obj:Remove() end)
            end
        end
        ESPCache[player] = nil
    end
end)

-- ============================================================================
-- [ 10 ] SPEED HACK
-- ============================================================================
local SpeedState = {
    CurrentHumanoid = nil,
    SpeedConnection = nil,
}

local function ApplySpeedNow()
    local _, _, hum = GetLocalCharacter()
    if not hum then return end

    if Config.SpeedHack then
        if hum.WalkSpeed ~= Config.SpeedValue then
            hum.WalkSpeed = Config.SpeedValue
        end
    else
        if hum.WalkSpeed ~= DEFAULT_WALKSPEED then
            hum.WalkSpeed = DEFAULT_WALKSPEED
        end
    end
end

local function BindSpeedToHumanoid(hum)
    if SpeedState.SpeedConnection then
        SpeedState.SpeedConnection:Disconnect()
        SpeedState.SpeedConnection = nil
    end
    SpeedState.CurrentHumanoid = hum

    SpeedState.SpeedConnection = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if Config.SpeedHack then
            if hum.WalkSpeed ~= Config.SpeedValue then
                hum.WalkSpeed = Config.SpeedValue
            end
        else
            if hum.WalkSpeed ~= DEFAULT_WALKSPEED then
                hum.WalkSpeed = DEFAULT_WALKSPEED
            end
        end
    end)
end

if RunService.PreSimulation then
    RunService.PreSimulation:Connect(ApplySpeedNow)
end
RunService.Heartbeat:Connect(ApplySpeedNow)
RunService.RenderStepped:Connect(ApplySpeedNow)

local function OnCharacterSpawn(char)
    task.wait(0.5)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        BindSpeedToHumanoid(hum)
        if Config.SpeedHack then
            hum.WalkSpeed = Config.SpeedValue
        else
            hum.WalkSpeed = DEFAULT_WALKSPEED
        end
    end
end

LocalPlayer.CharacterAdded:Connect(OnCharacterSpawn)
if LocalPlayer.Character then
    task.spawn(function()
        task.wait(1)
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then BindSpeedToHumanoid(hum) end
    end)
end

-- ============================================================================
-- [ 11 ] INFINITE JUMP
-- ============================================================================
local JumpState = { Connection = nil }

local function SetupInfiniteJump(character)
    if JumpState.Connection then
        JumpState.Connection:Disconnect()
        JumpState.Connection = nil
    end
    local hum = character:WaitForChild("Humanoid", 10)
    if not hum then return end

    JumpState.Connection = UserInputService.JumpRequest:Connect(function()
        if not Config.InfiniteJump then return end
        local currentChar = LocalPlayer.Character
        if not currentChar then return end
        local currentHum = currentChar:FindFirstChildOfClass("Humanoid")
        if not currentHum then return end
        currentHum:ChangeState(Enum.HumanoidStateType.Jumping)
    end)
end

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    SetupInfiniteJump(char)
end)
if LocalPlayer.Character then
    task.spawn(function()
        task.wait(1)
        SetupInfiniteJump(LocalPlayer.Character)
    end)
end

-- ============================================================================
-- [ 12 ] NAME SPOOFER
-- ============================================================================
local NameSpoofState = {
    OriginalNames = {},        -- [player] = original name
    OriginalDisplayNames = {}, -- [player] = original display name
    SelfApplied = false,
    EnemyApplied = false,
}

local function CaptureOriginalName(player)
    if not NameSpoofState.OriginalNames[player] then
        NameSpoofState.OriginalNames[player] = player.Name
        NameSpoofState.OriginalDisplayNames[player] = player.DisplayName
    end
end

local function ApplyNameToPlayer(player, spoofName)
    if not player or not spoofName or spoofName == "" then return end
    CaptureOriginalName(player)
    pcall(function()
        player.Name = spoofName
        player.DisplayName = spoofName
    end)
end

local function RestorePlayerName(player)
    if not player then return end
    local origName = NameSpoofState.OriginalNames[player]
    local origDisplay = NameSpoofState.OriginalDisplayNames[player]
    if origName then
        pcall(function()
            player.Name = origName
            player.DisplayName = origDisplay or origName
        end)
        NameSpoofState.OriginalNames[player] = nil
        NameSpoofState.OriginalDisplayNames[player] = nil
    end
end

local function ApplyNameSpoofs()
    if Config.SelfNameSpoof then
        ApplyNameToPlayer(LocalPlayer, Config.SelfSpoofedName)
    end
    if Config.EnemyNameSpoof then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                ApplyNameToPlayer(player, Config.EnemySpoofedName)
            end
        end
    end
end

local function RestoreSelfName()
    RestorePlayerName(LocalPlayer)
end

local function RestoreEnemyNames()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            RestorePlayerName(player)
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    if Config.EnemyNameSpoof then
        task.wait(0.5) -- let the player load
        ApplyNameToPlayer(player, Config.EnemySpoofedName)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    NameSpoofState.OriginalNames[player] = nil
    NameSpoofState.OriginalDisplayNames[player] = nil
end)

task.spawn(function()
    task.wait(1)
    ApplyNameSpoofs()
end)

-- ============================================================================
-- [ 13 ] WINSTREAK SPOOF
-- ============================================================================
local function ApplyWinstreakSpoof()
    if not Config.WinstreakSpoof then return end
    local p = LocalPlayer

    pcall(function()
        p:SetAttribute("StatisticDuelsWinStreak", Config.SpoofedWinstreak)
    end)

    local ls = p:FindFirstChild("CustomLeaderstats")
    if ls then
        local ws = ls:FindFirstChild("Win Streak")
        if ws then
            if ws:IsA("Folder") then
                local v = ws:FindFirstChildWhichIsA("IntValue")
                if v then v.Value = Config.SpoofedWinstreak end
            elseif ws:IsA("IntValue") then
                ws.Value = Config.SpoofedWinstreak
            end
        end
        for _, name in ipairs({"WinStreak", "DuelWinStreak", "Streak"}) do
            local other = ls:FindFirstChild(name)
            if other and other:IsA("IntValue") then
                other.Value = Config.SpoofedWinstreak
            end
        end
    end

    local leaderstats = p:FindFirstChild("leaderstats")
    if leaderstats then
        for _, name in ipairs({"Win Streak", "WinStreak", "Streak"}) do
            local v = leaderstats:FindFirstChild(name)
            if v and v:IsA("IntValue") then
                v.Value = Config.SpoofedWinstreak
            end
        end
    end
end

task.spawn(function()
    while task.wait(0.5) do
        if Config.WinstreakSpoof then
            ApplyWinstreakSpoof()
        end
    end
end)

-- ============================================================================
-- [ 14 ] UI TABS
-- ============================================================================

-- COMBAT
local CombatTab = Window:AddTab("Combat", "⚔")

local AimbotSection = Window:AddSection(CombatTab, "Aimbot")
Window:AddToggle(AimbotSection, "Enable Aimbot (Hold E to use)", false, function(state)
    Config.Aimbot = state
end)
Window:AddSlider(AimbotSection, "Aim Speed", 35, 1, 100, function(v)
    Config.AimbotSpeed = v
end)
Window:AddSlider(AimbotSection, "Aimbot FOV", 200, 50, 800, function(v)
    Config.AimbotFOV = v
end)
Window:AddButton(AimbotSection, "Aimbot Part: Head", function() Config.AimbotPart = "Head" end)
Window:AddButton(AimbotSection, "Aimbot Part: Body", function() Config.AimbotPart = "Body" end)

local TriggerSection = Window:AddSection(CombatTab, "TRIGGERBOT")
Window:AddToggle(TriggerSection, "Enable Triggerbot", false, function(state)
    Config.Triggerbot = state
end)
Window:AddSlider(TriggerSection, "Delay (ms)", 50, 0, 500, function(v)
    Config.TriggerbotDelay = v
end)
Window:AddToggle(TriggerSection, "Visible Targets Only", true, function(state)
    Config.TriggerbotVisible = state
end)

-- MOVEMENT
local MovementTab = Window:AddTab("Movement", "🏃")

local SpeedSection = Window:AddSection(MovementTab, "SPEED HACK")

local SpeedSlider
local function SetSpeedPreset(value)
    if SpeedSlider then
        SpeedSlider.Set(value)
    else
        Config.SpeedValue = value
        if Config.SpeedHack then
            local _, _, hum = GetLocalCharacter()
            if hum then hum.WalkSpeed = value end
        end
    end
end

Window:AddToggle(SpeedSection, "Enable Speed Hack", false, function(state)
    Config.SpeedHack = state
    local _, _, hum = GetLocalCharacter()
    if hum then
        if state then
            hum.WalkSpeed = Config.SpeedValue
        else
            hum.WalkSpeed = DEFAULT_WALKSPEED
        end
    end
end)

SpeedSlider = Window:AddSlider(SpeedSection, "Speed", 32, 16, 200, function(v)
    Config.SpeedValue = v
    if Config.SpeedHack then
        local _, _, hum = GetLocalCharacter()
        if hum then hum.WalkSpeed = v end
    end
end)

Window:AddButton(SpeedSection, "Set to 16 (normal)", function() SetSpeedPreset(16) end)
Window:AddButton(SpeedSection, "Set to 32 (fast)", function() SetSpeedPreset(32) end)
Window:AddButton(SpeedSection, "Set to 60 (very fast)", function() SetSpeedPreset(60) end)
Window:AddButton(SpeedSection, "Set to 100 (extreme)", function() SetSpeedPreset(100) end)

local JumpSection = Window:AddSection(MovementTab, "JUMP")
Window:AddToggle(JumpSection, "Enable Infinite Jump", false, function(state)
    Config.InfiniteJump = state
end)

-- ESP
local ESPTab = Window:AddTab("ESP", "👁")

local ESPMainSection = Window:AddSection(ESPTab, "ESP OPTIONS")
Window:AddToggle(ESPMainSection, "Enable ESP", true, function(state) Config.ESP = state end)
Window:AddToggle(ESPMainSection, "Box", true, function(state) Config.ESPShowBox = state end)
Window:AddToggle(ESPMainSection, "Name", true, function(state) Config.ESPShowName = state end)
Window:AddToggle(ESPMainSection, "Health", true, function(state) Config.ESPShowHealth = state end)
Window:AddToggle(ESPMainSection, "Distance", true, function(state) Config.ESPShowDistance = state end)
Window:AddToggle(ESPMainSection, "Tracer (bottom line)", false, function(state) Config.ESPShowTracer = state end)
Window:AddToggle(ESPMainSection, "Head Dot", false, function(state) Config.ESPShowHeadDot = state end)
Window:AddToggle(ESPMainSection, "Team Check", true, function(state) Config.ESPTeamCheck = state end)

local ESPSettingsSection = Window:AddSection(ESPTab, "ESP SETTINGS")
Window:AddSlider(ESPSettingsSection, "Max Distance", 1000, 100, 5000, function(v) Config.ESPMaxDistance = v end)
Window:AddSlider(ESPSettingsSection, "Text Size", 14, 8, 24, function(v) Config.ESPTextSize = v end)

-- MISC
local MiscTab = Window:AddTab("Misc", "🔧")

-- SELF Name Spoof
local SelfNameSection = Window:AddSection(MiscTab, "SELF NAME SPOOF")
Window:AddToggle(SelfNameSection, "Enable Self Name Spoof", false, function(state)
    Config.SelfNameSpoof = state
    if state then
        ApplyNameToPlayer(LocalPlayer, Config.SelfSpoofedName)
    else
        RestoreSelfName()
    end
end)
Window:AddInput(SelfNameSection, "Your Spoofed Name", Config.SelfSpoofedName, function(v)
    Config.SelfSpoofedName = v
    if Config.SelfNameSpoof then
        ApplyNameToPlayer(LocalPlayer, v)
    end
end)

-- ENEMY Name Spoof
local EnemyNameSection = Window:AddSection(MiscTab, "ENEMY NAME SPOOF")
Window:AddToggle(EnemyNameSection, "Enable Enemy Name Spoof", false, function(state)
    Config.EnemyNameSpoof = state
    if state then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                ApplyNameToPlayer(player, Config.EnemySpoofedName)
            end
        end
    else
        RestoreEnemyNames()
    end
end)
Window:AddInput(EnemyNameSection, "Enemy Spoofed Name", Config.EnemySpoofedName, function(v)
    Config.EnemySpoofedName = v
    if Config.EnemyNameSpoof then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                ApplyNameToPlayer(player, v)
            end
        end
    end
end)

-- WINSTREAK Spoof
local WinstreakSection = Window:AddSection(MiscTab, "WINSTREAK SPOOF")
Window:AddToggle(WinstreakSection, "Enable Winstreak Spoof", false, function(state)
    Config.WinstreakSpoof = state
    if state then ApplyWinstreakSpoof() end
end)
Window:AddSlider(WinstreakSection, "Winstreak", 56, 0, 500, function(v)
    Config.SpoofedWinstreak = v
    if Config.WinstreakSpoof then ApplyWinstreakSpoof() end
end)

-- ============================================================================
-- [ 15 ] INIT
-- ============================================================================
print("========================================")
print("Rivals Script loaded")
print("========================================")