--// Khfresh BentoGridStyle
--// UI library rebuilt specifically for Khfresh Hub.
--// The old UI source is used only as an API/layout reference.
--// No old hub features/assets are embedded here.

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local function resolveParent()
    local ok, parent = pcall(function()
        if type(gethui) == "function" then
            local h = gethui()
            if h then return h end
        end
        return game:GetService("CoreGui")
    end)
    if ok and parent then return parent end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local GuiParent = resolveParent()

local UI = {
    _version = "5.1.0-khfresh-pixel",
    _windows = {},
    _notifyGui = nil,

}

--==============================================================
-- THEME
--==============================================================
local THEMES = {
    Bento = {
        canvas = Color3.fromRGB(15, 17, 21),
        shell = Color3.fromRGB(20, 23, 29),
        rail = Color3.fromRGB(17, 20, 25),
        header = Color3.fromRGB(24, 27, 34),
        card = Color3.fromRGB(25, 29, 36),
        row = Color3.fromRGB(29, 33, 41),
        rowHover = Color3.fromRGB(35, 40, 49),
        rowPressed = Color3.fromRGB(43, 49, 60),
        line = Color3.fromRGB(53, 60, 73),
        lineSoft = Color3.fromRGB(39, 44, 53),
        text = Color3.fromRGB(242, 245, 250),
        secondary = Color3.fromRGB(181, 188, 201),
        muted = Color3.fromRGB(118, 127, 143),
        accent = Color3.fromRGB(105, 190, 255),
        accentSoft = Color3.fromRGB(38, 74, 106),
        success = Color3.fromRGB(102, 215, 155),
        danger = Color3.fromRGB(244, 112, 123),
        warning = Color3.fromRGB(243, 193, 103),
    },
    Dark = {
        canvas = Color3.fromRGB(12, 13, 16), shell = Color3.fromRGB(18, 20, 24),
        rail = Color3.fromRGB(15, 16, 20), header = Color3.fromRGB(21, 24, 29),
        card = Color3.fromRGB(22, 25, 30), row = Color3.fromRGB(26, 29, 35),
        rowHover = Color3.fromRGB(32, 36, 43), rowPressed = Color3.fromRGB(39, 44, 53),
        line = Color3.fromRGB(47, 52, 62), lineSoft = Color3.fromRGB(35, 39, 47),
        text = Color3.fromRGB(238, 241, 247), secondary = Color3.fromRGB(171, 177, 190),
        muted = Color3.fromRGB(108, 115, 130), accent = Color3.fromRGB(96, 182, 247),
        accentSoft = Color3.fromRGB(33, 63, 91), success = Color3.fromRGB(98, 206, 148),
        danger = Color3.fromRGB(238, 102, 115), warning = Color3.fromRGB(236, 184, 92),
    },
}

local currentTheme = "Bento"
local C = {}

local function applyTheme(name)
    if not THEMES[name] then name = "Bento" end
    currentTheme = name
    for k, v in pairs(THEMES[name]) do C[k] = v end
end
applyTheme("Bento")

local Motion = {
    fast = TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    base = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    smooth = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    spring = TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
}

--==============================================================
-- COMMON HELPERS
--==============================================================
local function make(className, props, parent)
    local obj = Instance.new(className)
    if props then
        for k, v in pairs(props) do
            local ok = pcall(function() obj[k] = v end)
            if not ok then end
        end
    end
    if parent then obj.Parent = parent end
    return obj
end

local function corner(parent, radius)
    return make("UICorner", { CornerRadius = UDim.new(0, radius or 12) }, parent)
end

local function outline(parent, color, transparency, thickness)
    return make("UIStroke", {
        Color = color or C.line,
        Transparency = transparency == nil and 0.45 or transparency,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

local function padding(parent, l, r, t, b)
    return make("UIPadding", {
        PaddingLeft = UDim.new(0, l or 0),
        PaddingRight = UDim.new(0, r or 0),
        PaddingTop = UDim.new(0, t or 0),
        PaddingBottom = UDim.new(0, b or 0),
    }, parent)
end

local function list(parent, gap)
    return make("UIListLayout", {
        Padding = UDim.new(0, gap or 8),
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, parent)
end

local function tween(obj, info, props)
    if not obj or not obj.Parent then return end
    local ok, t = pcall(function()
        return TweenService:Create(obj, info or Motion.base, props)
    end)
    if ok and t then t:Play() return t end
end

local function text(parent, value, size, color, bold)
    return make("TextLabel", {
        BackgroundTransparency = 1,
        Text = tostring(value or ""),
        TextColor3 = color or C.text,
        TextSize = size or 13,
        Font = bold and Enum.Font.GothamMedium or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextWrapped = false,
    }, parent)
end

local function button(parent, z)
    return make("TextButton", {
        Text = "",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Size = UDim2.fromScale(1, 1),
        ZIndex = z or 50,
    }, parent)
end

local function hoverRow(frame)
    local base = frame.BackgroundColor3
    frame.MouseEnter:Connect(function() tween(frame, Motion.fast, {BackgroundColor3 = C.rowHover}) end)
    frame.MouseLeave:Connect(function() tween(frame, Motion.fast, {BackgroundColor3 = base}) end)
end

local function cleanName(s)
    return tostring(s or "Element"):gsub("[^%w_]+", "_")
end

--==============================================================
-- PROCEDURAL PIXEL ICON ENGINE
--==============================================================
-- No external icon library, no icon asset ids. Icons are rendered from
-- tiny ASCII/pixel matrices using Roblox Frames, so they are deterministic
-- and work offline once the UI library itself has loaded.
local PIXEL_ICONS = {
    ["x"] = {"10001","01010","00100","01010","10001"},
    ["minus"] = {"00000","00000","11111","00000","00000"},
    ["plus"] = {"00100","00100","11111","00100","00100"},
    ["chevron-down"] = {"10001","01010","00100","00000","00000"},
    ["chevron-right"] = {"10000","11000","01100","00110","00011"},
    ["check"] = {"00001","00010","10100","01000","00000"},
    ["circle-check"] = {"01110","10001","10101","10011","01110"},
    ["play"] = {"10000","11000","11100","11000","10000"},
    ["settings"] = {"00100","10101","01110","10101","00100"},
    ["search"] = {"01110","10001","10001","01010","00011"},
    ["info"] = {"01110","00100","00100","01110","00000"},
    ["house"] = {"00100","01110","11111","10001","10001"},
    ["layout-dashboard"] = {"11111","10001","10101","10001","11111"},
    ["panel-left"] = {"11111","11001","11001","11001","11111"},
    ["panels-top-left"] = {"11111","10001","10111","10111","11111"},
    ["fish"] = {"00100","01110","11111","01110","00101"},
    ["fish-symbol"] = {"00100","01010","11111","01010","00100"},
    ["fishing-rod"] = {"11000","01100","00110","00011","00001"},
    ["hand-heart"] = {"00100","01110","11111","01110","00100"},
    ["flame"] = {"00100","01110","11011","10101","01110"},
    ["swords"] = {"10001","01010","00100","01010","10001"},
    ["sword"] = {"00001","00010","00100","01000","10000"},
    ["shopping-cart"] = {"10000","11110","10001","01110","00000"},
    ["shopping-bag"] = {"01110","01010","11111","10001","11111"},
    ["store"] = {"11111","10101","11111","10001","11111"},
    ["repeat-2"] = {"11110","00001","11110","10000","01111"},
    ["scroll-text"] = {"11111","10101","10101","10101","11111"},
    ["trending-up"] = {"10000","11000","01100","00110","00011"},
    ["map-pin"] = {"00100","01110","01110","00100","00000"},
    ["ship"] = {"10001","11011","11111","01110","00100"},
    ["user"] = {"01110","11111","01110","00100","01010"},
    ["user-round"] = {"01110","10101","01110","00100","01010"},
    ["users-round"] = {"10101","11111","01110","10101","10101"},
    ["lock"] = {"01110","01010","11111","10001","11111"},
    ["shield-alert"] = {"01110","11111","10101","00100","01010"},
    ["shield"] = {"01110","11111","10101","10101","01110"},
    ["scan-search"] = {"11011","10001","10111","10001","11011"},
    ["sliders-horizontal"] = {"10101","00100","11111","00100","10101"},
    ["hammer"] = {"11100","00111","00100","01100","11000"},
    ["dices"] = {"11100","10100","11100","00111","00101"},
    ["refresh-cw"] = {"01110","11001","00111","10001","01110"},
    ["shuffle"] = {"10001","01010","00100","01010","10001"},
    ["cloud-sun"] = {"00100","01110","10111","11111","00100"},
    ["toggle-right"] = {"11111","10001","10101","10001","11111"},
    ["type"] = {"11111","00100","00100","00100","00100"},
    ["list"] = {"10111","00100","10111","00100","10111"},
    ["palette"] = {"01110","11011","10101","11010","01100"},
    ["keyboard"] = {"11111","10101","11111","10001","11111"},
    ["history"] = {"01110","11001","10101","10011","01110"},
    ["message-circle"] = {"01110","10001","10111","10001","01110"},
    ["music-2"] = {"00111","00100","00100","11100","11000"},
    ["external-link"] = {"10000","10111","10101","11101","00001"},
    ["badge-check"] = {"01110","10101","11111","10101","01110"},
    ["copy"] = {"00111","00101","11101","10101","11111"},
    ["eye-off"] = {"10101","01010","00100","01010","10101"},
    ["sparkles"] = {"00100","11111","00100","01010","10001"},
    ["zap"] = {"00110","01100","11000","01100","00110"},
    ["shapes"] = {"01110","10101","01110","10001","11111"},
    ["volleyball"] = {"0011100","0111110","1110111","1101011","1110111","0111110","0011100"},
    ["circle"] = {"01110","10001","10001","10001","01110"},
}

local PIXEL_ALIASES = {
    dashboard="layout-dashboard", layout="layout-dashboard", overview="layout-dashboard",
    home="house", config="sliders-horizontal", tune="sliders-horizontal",
    close="x", remove="minus", add="plus", next="chevron-right",
    expand="chevron-down", cancel="x", back="chevron-right",
    warning="shield-alert", success="circle-check",
}

local function normalizePixelIcon(name)
    local key = string.lower(tostring(name or "circle")):gsub("%s+", "-")
    return PIXEL_ALIASES[key] or key
end

local function renderPixelIcon(parent, iconName, position, size, color, z)
    local holder = make("Frame", {
        Name="PixelIcon_"..cleanName(iconName), BackgroundTransparency=1, BorderSizePixel=0,
        Position=position or UDim2.fromOffset(0,0), Size=size or UDim2.fromOffset(20,20), ZIndex=z or 5,
    }, parent)
    local map = PIXEL_ICONS[normalizePixelIcon(iconName)] or PIXEL_ICONS.circle
    local rows = #map
    local cols = #map[1]
    local gap = 1
    local cellX = 1 / math.max(1, cols)
    local cellY = 1 / math.max(1, rows)
    for y,row in ipairs(map) do
        for x = 1,#row do
            if row:sub(x,x) ~= "0" then
                local px = make("Frame", {
                    BackgroundColor3=color or C.secondary, BorderSizePixel=0,
                    Position=UDim2.new((x-1)*cellX, gap/2, (y-1)*cellY, gap/2),
                    Size=UDim2.new(cellX, -gap, cellY, -gap), ZIndex=z or 5,
                }, holder)
            end
        end
    end
    return holder
end

local function renderIcon(parent, iconName, position, size, color, z)
    return renderPixelIcon(parent, iconName, position, size, color, z)
end

local function pixelIconSetColor(holder, color)
    if not holder then return end
    for _,child in ipairs(holder:GetDescendants()) do
        if child:IsA("Frame") and child ~= holder then
            child.BackgroundColor3=color
        end
    end
end

--==============================================================
-- WINDOW / TAB / SECTION
--==============================================================
local Window = {}
Window.__index = Window
local Tab = {}
Tab.__index = Tab
local Section = {}
Section.__index = Section

local function viewport()
    local cam = workspace.CurrentCamera
    return cam and cam.ViewportSize or Vector2.new(1280, 720)
end

local function computeSize(requested)
    local vp = viewport()
    local mobile = vp.X < 700 or (UserInputService.TouchEnabled and vp.X < 900)
    local minW = mobile and 300 or 520
    local minH = mobile and 340 or 420
    local maxW = math.max(minW, vp.X - (mobile and 12 or 24))
    local maxH = math.max(minH, vp.Y - (mobile and 12 or 24))
    local w = math.clamp(requested and requested.X.Offset or 760, minW, maxW)
    local h = math.clamp(requested and requested.Y.Offset or 540, minH, maxH)
    return UDim2.fromOffset(w, h)
end

local function installResponsive(win)
    local camera = workspace.CurrentCamera
    local function update()
        if not win._shell or not win._shell.Parent then return end
        local vp = viewport()
        local mobile = vp.X < 700 or UserInputService.TouchEnabled and vp.X < 850
        win._mobile = mobile
        if mobile then
            local vpW, vpH = vp.X, vp.Y
            win._shell.Size = UDim2.fromOffset(math.max(300, vpW-12), math.max(340, vpH-12))
            win._shell.Position = UDim2.fromScale(0.5, 0.5)
            win._topHeight = vpW < 520 and 68 or 76
            win._top.Size = UDim2.new(1,0,0,win._topHeight)
            win._rail.Size = UDim2.new(0, 62, 1, -win._topHeight)
            win._rail.Position = UDim2.fromOffset(0, win._topHeight)
            win._content.Position = UDim2.fromOffset(62, win._topHeight)
            win._content.Size = UDim2.new(1, -62, 1, -win._topHeight)
            if win._logo then
                win._logo.Size = UDim2.fromOffset(34,34)
                win._logo.Position = UDim2.fromOffset(10,9)
            end
            if win._logoHolder then
                win._logoHolder.Size=UDim2.fromOffset(52,52)
                win._logoHolder.Position=UDim2.fromOffset(8,8)
            end
            if win._brandText then win._brandText.Visible = false end
            if win._authorText then win._authorText.Visible = false end
            for _, tab in ipairs(win._tabs) do
                if tab._label then tab._label.Visible = false end
                if tab._btn then tab._btn.Size=UDim2.new(1,0,0,44) end
                if tab._icon then tab._icon.Position = UDim2.new(0.5, -11, 0.5, -11) end
            end
        else
            local requested = win._requestedSize or UDim2.fromOffset(760, 540)
            win._topHeight = 82
            win._top.Size = UDim2.new(1,0,0,82)
            win._shell.Size = computeSize(requested)
            win._rail.Size = UDim2.new(0,win._railWidth,1,-win._topHeight)
            win._rail.Position = UDim2.fromOffset(0,win._topHeight)
            win._content.Position = UDim2.fromOffset(win._railWidth, win._topHeight)
            win._content.Size = UDim2.new(1, -win._railWidth, 1, -win._topHeight)
            if win._brandText then win._brandText.Visible = true end
            if win._authorText then win._authorText.Visible = true end
            for _, tab in ipairs(win._tabs) do
                if tab._label then tab._label.Visible = true end
                if tab._icon then tab._icon.Position = UDim2.fromOffset(12, 12) end
            end
        end
        if win._settingsTab then win:_layoutSettings() end
    end
    if camera then
        table.insert(win._connections, camera:GetPropertyChangedSignal("ViewportSize"):Connect(update))
    end
    update()
end

local function installDragAndResize(win)
    local shell = win._shell
    local function startMove(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        win._moving = true
        win._moveStart = input.Position
        win._moveBase = shell.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then win._moving = false end
        end)
    end

    win._dragHandle.InputBegan:Connect(startMove)
    win._top.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then startMove(input) end
    end)

    table.insert(win._connections, UserInputService.InputChanged:Connect(function(input)
        if win._moving and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - win._moveStart
            shell.Position = UDim2.new(win._moveBase.X.Scale, win._moveBase.X.Offset + delta.X, win._moveBase.Y.Scale, win._moveBase.Y.Offset + delta.Y)
        end
        if win._resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - win._resizeStart
            local old = win._resizeBase
            local vp = viewport()
            local mobile = vp.X < 700 or (UserInputService.TouchEnabled and vp.X < 900)
            local minW = mobile and 300 or 520
            local minH = mobile and 340 or 420
            local w = math.clamp(old.X.Offset + delta.X, minW, math.max(minW, vp.X - (mobile and 12 or 24)))
            local h = math.clamp(old.Y.Offset + delta.Y, minH, math.max(minH, vp.Y - (mobile and 12 or 24)))
            shell.Size = UDim2.fromOffset(w, h)
            win._requestedSize = UDim2.fromOffset(w, h)
        end
    end))
    win._resizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        win._resizing = true
        win._resizeStart = input.Position
        win._resizeBase = shell.Size
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then win._resizing = false end
        end)
    end)
end

function UI:SetTheme(name)
    applyTheme(name)
    for _, win in ipairs(self._windows) do
        if win and win.ApplyTheme then pcall(function() win:ApplyTheme() end) end
    end
end
function UI:GetTheme() return currentTheme end
function UI:GetThemes()
    local out = {}
    for k in pairs(THEMES) do out[#out+1] = k end
    return out
end
function UI:GetIcon(name) return PIXEL_ICONS[normalizePixelIcon(name)] ~= nil end
function UI:GetIconPack() return nil end
function UI:IsMobile() return viewport().X < 700 or UserInputService.TouchEnabled and viewport().X < 850 end
function UI:RenderIcon(parent, name, position, size, color, z) return renderPixelIcon(parent, name, position, size, color, z) end

function UI:Notify(config)
    config = config or {}
    local host = self._notifyGui
    if not host or not host.Parent then
        host = make("ScreenGui", {
            Name = "KhfreshNotify",
            ResetOnSpawn = false,
            IgnoreGuiInset = true,
            DisplayOrder = 2147483640,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        }, GuiParent)
        self._notifyGui = host
    end
    local wrapper = host:FindFirstChild("Wrapper")
    if not wrapper then
        wrapper = make("Frame", {BackgroundTransparency=1, Size=UDim2.fromScale(1,1)}, host)
        local lay = list(wrapper, 8)
        lay.HorizontalAlignment = Enum.HorizontalAlignment.Right
        lay.VerticalAlignment = Enum.VerticalAlignment.Bottom
        padding(wrapper, 0, 16, 0, 16)
    end
    local card = make("Frame", {
        BackgroundColor3 = C.shell, BorderSizePixel=0, Size=UDim2.fromOffset(320, 72), LayoutOrder=-math.floor(os.clock()*1000),
    }, wrapper)
    corner(card, 14); outline(card,C.line,0.25,1)
    renderIcon(card, config.Icon or "info", UDim2.fromOffset(14,18), UDim2.fromOffset(26,26), C.accent, 5)
    local title = text(card, config.Title or "Khfresh", 13, C.text, true)
    title.Position = UDim2.fromOffset(50,9); title.Size = UDim2.new(1,-60,0,20)
    local desc = text(card, config.Content or config.Message or "", 11, C.secondary, false)
    desc.Position = UDim2.fromOffset(50,31); desc.Size = UDim2.new(1,-60,0,32); desc.TextWrapped = true
    task.delay(tonumber(config.Duration) or 3, function()
        if card.Parent then
            tween(card, Motion.fast, {BackgroundTransparency=1})
            task.wait(0.12)
            pcall(function() card:Destroy() end)
        end
    end)
end

function UI:CreateWindow(config)
    config = config or {}
    local requested = config.Size or UDim2.fromOffset(760, 540)
    local win = setmetatable({
        _requestedSize = requested,
        _railWidth = 178,
        _topHeight = 82,
        _tabs = {},
        _connections = {},
        _open = true,
        _tabSequence = 0,
        _settingsTab = nil,
    }, Window)

    local old = GuiParent:FindFirstChild("KhfreshBentoUI")
    if old then pcall(function() old:Destroy() end) end

    local gui = make("ScreenGui", {
        Name = "KhfreshBentoUI",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 2147483645,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
    }, GuiParent)
    pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
    win._gui = gui

    local shell = make("Frame", {
        Name="Shell", BackgroundColor3=C.canvas, BorderSizePixel=0,
        Size=computeSize(requested), Position=UDim2.fromScale(0.5,0.5), AnchorPoint=Vector2.new(0.5,0.5),
        ClipsDescendants=true, Active=true,
    }, gui)
    corner(shell, 24); outline(shell,C.line,0.25,1)
    win._shell = shell

    if type(config.Background) == "string" and config.Background ~= "" then
        local bg = make("ImageLabel", {
            Name="Background", BackgroundTransparency=1, BorderSizePixel=0,
            Size=UDim2.fromScale(1,1), Image=config.Background,
            ImageTransparency=tonumber(config.BackgroundImageTransparency) or 0.62,
            ScaleType=Enum.ScaleType.Crop, ZIndex=0,
        }, shell)
        win._background = bg
        local tint = make("Frame", {BackgroundColor3=C.canvas, BackgroundTransparency=0.32, Size=UDim2.fromScale(1,1), BorderSizePixel=0, ZIndex=1}, shell)
        win._backgroundTint = tint
    end

    local top = make("Frame", {
        Name="TopBar", BackgroundColor3=C.header, BackgroundTransparency=0.06, BorderSizePixel=0,
        Size=UDim2.new(1,0,0,82), Position=UDim2.new(), ZIndex=20,
    }, shell)
    corner(top, 22); win._top = top

    local logoHolder = make("Frame", {BackgroundColor3=C.accentSoft, BorderSizePixel=0, Position=UDim2.fromOffset(14,14), Size=UDim2.fromOffset(54,54), ZIndex=22}, top)
    corner(logoHolder, 16)
    win._logoHolder = logoHolder
    if type(config.Logo) == "string" and config.Logo ~= "" then
        local image = make("ImageLabel", {BackgroundTransparency=1, Size=UDim2.fromScale(1,1), Image=config.Logo, ScaleType=Enum.ScaleType.Fit, ZIndex=23}, logoHolder)
        win._logo = image
    else
        win._logo = renderIcon(logoHolder, config.Icon or "layout-dashboard", UDim2.fromOffset(16,16), UDim2.fromOffset(22,22), C.accent, 23)
    end

    local brand = text(top, config.Title or "Khfresh Hub", 18, C.text, true)
    brand.Position=UDim2.fromOffset(82,14); brand.Size=UDim2.new(1,-190,0,28); brand.ZIndex=22
    win._brandText = brand
    local author = text(top, config.Author or "Khfresh Bento UI", 11, C.muted, false)
    author.Position=UDim2.fromOffset(82,43); author.Size=UDim2.new(1,-190,0,20); author.ZIndex=22
    win._authorText = author

    local close = make("TextButton", {Text="", BackgroundColor3=C.row, BorderSizePixel=0, Size=UDim2.fromOffset(42,42), Position=UDim2.new(1,-54,0,20), AutoButtonColor=false, ZIndex=25}, top)
    corner(close,13); renderIcon(close,"x",UDim2.fromOffset(11,11),UDim2.fromOffset(20,20),C.secondary,26)
    close.Activated:Connect(function() win:Destroy() end)
    local min = make("TextButton", {Text="", BackgroundColor3=C.row, BorderSizePixel=0, Size=UDim2.fromOffset(42,42), Position=UDim2.new(1,-104,0,20), AutoButtonColor=false, ZIndex=25}, top)
    corner(min,13); renderIcon(min,"minus",UDim2.fromOffset(11,11),UDim2.fromOffset(20,20),C.secondary,26)
    min.Activated:Connect(function() win:Toggle() end)

    local rail = make("ScrollingFrame", {
        Name="Rail", BackgroundColor3=C.rail, BackgroundTransparency=0.08, BorderSizePixel=0,
        Position=UDim2.fromOffset(0,82), Size=UDim2.new(0,178,1,-82),
        CanvasSize=UDim2.new(), AutomaticCanvasSize=Enum.AutomaticSize.Y,
        ScrollBarThickness=2, ScrollBarImageColor3=C.muted, ScrollingDirection=Enum.ScrollingDirection.Y,
        ZIndex=14,
    }, shell)
    list(rail,7); padding(rail,10,10,12,36); win._rail=rail
    local divider=make("Frame",{BackgroundColor3=C.lineSoft,BorderSizePixel=0,Position=UDim2.new(1,-1,0,0),Size=UDim2.new(0,1,1,0),ZIndex=15},rail)

    local content = make("Frame", {
        Name="Content", BackgroundColor3=C.canvas, BackgroundTransparency=0.52, BorderSizePixel=0,
        Position=UDim2.fromOffset(178,82), Size=UDim2.new(1,-178,1,-82), ClipsDescendants=true, ZIndex=10,
    }, shell)
    win._content=content

    -- Bottom drag strip requested by the user.
    local drag = make("TextButton", {Text="", BackgroundTransparency=1, BorderSizePixel=0, Position=UDim2.new(0.5,-90,1,-19), Size=UDim2.fromOffset(180,16), AutoButtonColor=false, ZIndex=40}, shell)
    local dragLine = make("Frame", {BackgroundColor3=C.muted, BackgroundTransparency=0.22, BorderSizePixel=0, Size=UDim2.fromOffset(76,3), Position=UDim2.new(0.5,-38,0.5,-1), ZIndex=41}, drag)
    corner(dragLine, 99); win._dragHandle=drag
    -- Bottom-right resize grip, similar to desktop UI libraries.
    local grip = make("TextButton", {Text="", BackgroundTransparency=1, BorderSizePixel=0, AnchorPoint=Vector2.new(1,1), Position=UDim2.new(1,0,1,0), Size=UDim2.fromOffset(28,28), AutoButtonColor=false, ZIndex=45}, shell)
    for i=1,3 do drawLine(grip, 28-(i*6), 28, 28, 28-(i*6), C.muted, 1.5, 46) end
    win._resizeHandle=grip

    function win:ApplyTheme()
        pcall(function() shell.BackgroundColor3=C.canvas; top.BackgroundColor3=C.header; rail.BackgroundColor3=C.rail end)
        for _, t in ipairs(self._tabs) do
            if t._btn then t._btn.BackgroundColor3 = (t == self._selected and C.accentSoft or C.row) end
            if t._icon then pixelIconSetColor(t._icon, (t == self._selected and C.accent or C.muted)) end
        end
    end

    table.insert(UI._windows, win)
    installDragAndResize(win)
    installResponsive(win)

    gui.Enabled=true
    shell.Visible=true
    return win
end

function Window:CreateTab(nameOrConfig, icon)
    local config = type(nameOrConfig)=="table" and nameOrConfig or {Title=nameOrConfig,Icon=icon}
    local title=tostring(config.Title or config.Name or "Tab")
    local iconName=config.Icon or "circle"
    self._tabSequence += 1

    local tabBtn=make("TextButton",{Name="Tab_"..cleanName(title),Text="",BackgroundColor3=C.row,BorderSizePixel=0,Size=UDim2.new(1,0,0,48),AutoButtonColor=false,LayoutOrder=self._tabSequence,ZIndex=16},self._rail)
    corner(tabBtn,15)
    local ico=renderIcon(tabBtn,iconName,UDim2.fromOffset(12,12),UDim2.fromOffset(24,24),C.muted,18)
    local lbl=text(tabBtn,title,12,C.secondary,true); lbl.Position=UDim2.fromOffset(46,0); lbl.Size=UDim2.new(1,-54,1,0); lbl.ZIndex=18

    local page=make("ScrollingFrame",{Name="Page_"..cleanName(title),BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromScale(1,1),CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=4,ScrollBarImageColor3=C.muted,ScrollingDirection=Enum.ScrollingDirection.Y,Visible=false,ZIndex=11,ClipsDescendants=false},self._content)
    padding(page,16,16,16,30)

    local tab=setmetatable({_window=self,_btn=tabBtn,_icon=ico,_label=lbl,_page=page,_title=title,_iconName=iconName,_order=0,_sections={},_controls={},_settingsBento=(string.lower(title)=="settings")},Tab)
    table.insert(self._tabs,tab)
    if tab._settingsBento then self._settingsTab=tab end

    tabBtn.Activated:Connect(function() self:SelectTab(#self._tabs) end)
    if #self._tabs==1 then self:SelectTab(1) end
    return tab
end

function Window:GetTab(title)
    local wanted=string.lower(tostring(title or ""))
    for _,t in ipairs(self._tabs) do if string.lower(t._title)==wanted then return t end end
end

function Window:SelectTab(index)
    local tab=type(index)=="table" and index or self._tabs[tonumber(index) or 1]
    if not tab then return end
    self._selected=tab
    for _,t in ipairs(self._tabs) do
        local on=t==tab
        t._page.Visible=on
        t._btn.BackgroundColor3=on and C.accentSoft or C.row
        t._label.TextColor3=on and C.text or C.secondary
        if t._icon then
            pixelIconSetColor(t._icon,on and C.accent or C.muted)
        end
    end
end

function Window:Toggle()
    self._open=not self._open
    if self._open then
        self._shell.Visible=true
        tween(self._shell,Motion.smooth,{Position=UDim2.fromScale(0.5,0.5)})
    else
        self._shell.Visible=false
    end
end
function Window:Minimize() self._open=false; self._shell.Visible=false end
function Window:Open() self._open=true; self._shell.Visible=true end
function Window:Destroy()
    for _,c in ipairs(self._connections or {}) do pcall(function() c:Disconnect() end) end
    for i,v in ipairs(UI._windows) do if v==self then table.remove(UI._windows,i) break end end
    if self._floatingGui then pcall(function() self._floatingGui:Destroy() end) end
    if self._gui then pcall(function() self._gui:Destroy() end) end
end
function Window:ToggleAcrylic() end
function Window:SetBackground(asset, transparency)
    if not self._background then
        self._background=make("ImageLabel",{Name="Background",BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromScale(1,1),ScaleType=Enum.ScaleType.Crop,ZIndex=0},self._shell)
        self._backgroundTint=make("Frame",{BackgroundColor3=C.canvas,BackgroundTransparency=0.55,BorderSizePixel=0,Size=UDim2.fromScale(1,1),ZIndex=1},self._shell)
    end
    self._background.Image=tostring(asset or "")
    self._background.ImageTransparency=tonumber(transparency) or 0.62
end
function Window:SetLogo(asset)
    if self._logo then self._logo:Destroy() end
    self._logo=make("ImageLabel",{BackgroundTransparency=1,Size=UDim2.fromScale(1,1),Image=tostring(asset or ""),ScaleType=Enum.ScaleType.Fit,ZIndex=23},self._logoHolder)
end
function Window:SetFloatingVisible(v)
    if self._floatingGui then self._floatingGui.Enabled = v ~= false end
end
function Window:CreateFloatingToggle(config)
    config=config or {}
    if self._floatingGui then pcall(function() self._floatingGui:Destroy() end) end
    local sg=make("ScreenGui",{Name="KhfreshFloatingGui",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=2147483630,ZIndexBehavior=Enum.ZIndexBehavior.Global},GuiParent)
    self._floatingGui=sg
    local btn=make("TextButton",{Text="",BackgroundColor3=C.shell,BorderSizePixel=0,Size=UDim2.fromOffset(58,58),Position=UDim2.new(0,16,0.5,-29),AutoButtonColor=false,Active=true,ZIndex=10},sg)
    corner(btn,19); outline(btn,C.line,0.2,1)
    renderPixelIcon(btn,"volleyball",UDim2.fromOffset(13,13),UDim2.fromOffset(32,32),C.accent,12)
    btn.Activated:Connect(function() self:Toggle() end)
    local scale=make("UIScale",{Scale=1},btn)
    btn.MouseEnter:Connect(function() tween(scale,Motion.fast,{Scale=1.06}) end)
    btn.MouseLeave:Connect(function() tween(scale,Motion.fast,{Scale=1}) end)
    return sg
end

local function makePageLayout(tab)
    if tab._settingsBento then
        local wrap=make("Frame",{Name="SettingsGrid",BackgroundTransparency=1,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y},tab._page)
        local columns={
            make("Frame",{Name="Left",BackgroundTransparency=1,Size=UDim2.new(0.5,-6,0,0),AutomaticSize=Enum.AutomaticSize.Y},wrap),
            make("Frame",{Name="Right",BackgroundTransparency=1,Size=UDim2.new(0.5,-6,0,0),AutomaticSize=Enum.AutomaticSize.Y,Position=UDim2.new(0.5,6,0,0)},wrap),
        }
        list(columns[1],10); list(columns[2],10)
        return wrap, columns
    end
    local direct=make("Frame",{Name="Elements",BackgroundTransparency=1,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y},tab._page)
    list(direct,10)
    return direct, {direct}
end

function Tab:_ensureHost()
    if self._host then return end
    self._host,self._columns=makePageLayout(self)
    self._settingsCounter=0
    self._settingsWrap=self._host
    self._settingsColumns=self._columns
end

function Tab:_layoutSettings()
    if not self._settingsBento or not self._settingsColumns then return end
    local vp=viewport()
    local mobile=vp.X < 700 or UserInputService.TouchEnabled and vp.X < 850
    local left,right=self._settingsColumns[1],self._settingsColumns[2]
    if mobile then
        left.Size=UDim2.new(1,0,0,0)
        right.Size=UDim2.new(1,0,0,0)
        right.Position=UDim2.new(0,0,0,left.AbsoluteSize.Y+10)
    else
        left.Size=UDim2.new(0.5,-6,0,0)
        right.Size=UDim2.new(0.5,-6,0,0)
        right.Position=UDim2.new(0.5,6,0,0)
    end
end

function Tab:_insertSection(section)
    self:_ensureHost()
    local parent
    if self._settingsBento then
        local columns=self._settingsColumns or self._columns
        if not columns or not columns[1] then
            self._host,self._columns=makePageLayout(self)
            self._settingsColumns=self._columns
            columns=self._columns
        end
        local side=section._side
        if side=="left" then
            parent=columns[1]
        elseif side=="right" then
            parent=columns[2] or columns[1]
        else
            self._settingsCounter=(self._settingsCounter or 0)+1
            parent=columns[(((self._settingsCounter-1)%2)+1)] or columns[1]
        end
    else
        parent=(self._columns and self._columns[1]) or self._host or self._page
    end
    if not parent then
        parent=self._page
    end
    section._parent=parent
    section._frame.Parent=parent
    section._frame.LayoutOrder=section._order or 1
    self:_layoutSettings()
end

function Tab:CreateHeader(config)
    config=type(config)=="table" and config or {Title=tostring(config or "")}
    self:_ensureHost()
    local frame=make("Frame",{Name="Header",BackgroundTransparency=1,Size=UDim2.new(1,0,0,52),LayoutOrder=#self._host:GetChildren()+1},self._columns[1])
    if config.Icon then renderIcon(frame,config.Icon,UDim2.fromOffset(0,10),UDim2.fromOffset(22,22),C.accent,5) end
    local x=config.Icon and 30 or 0
    local t=text(frame,config.Title or "",17,C.text,true); t.Position=UDim2.fromOffset(x,0); t.Size=UDim2.new(1,-x,0,27)
    local s=text(frame,config.Subtitle or config.Desc or "",11,C.muted,false); s.Position=UDim2.fromOffset(x,28); s.Size=UDim2.new(1,-x,0,20)
    return frame
end

function Tab:CreateSection(nameOrConfig, side)
    local config=type(nameOrConfig)=="table" and nameOrConfig or {Title=nameOrConfig}
    local name=tostring(config.Title or config.Name or "Section")
    local sideName=type(side)=="string" and string.lower(side) or (type(config.Side)=="string" and string.lower(config.Side) or nil)
    self:_ensureHost()
    local frame=make("Frame",{Name="Section_"..cleanName(name),BackgroundColor3=C.card,BorderSizePixel=0,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=1,ClipsDescendants=false,ZIndex=30},nil)
    if not self._settingsBento then
        frame.BackgroundTransparency = 1
    else
        corner(frame,18); outline(frame,C.lineSoft,0.18,1)
    end
    local header=make("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,43),ZIndex=31},frame)
    renderIcon(header,config.Icon or "layers",UDim2.fromOffset(14,12),UDim2.fromOffset(18,18),C.accent,33)
    local title=text(header,name,13,C.text,true); title.Position=UDim2.fromOffset(40,0); title.Size=UDim2.new(1,-52,1,0); title.ZIndex=33
    local body=make("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,Position=UDim2.fromOffset(0,43),ZIndex=32},frame)
    padding(body,10,10,0,12); list(body,8)
    local section=setmetatable({_tab=self,_frame=frame,_body=body,_name=name,_side=sideName,_order=0},Section)
    table.insert(self._sections,section)
    self:_insertSection(section)
    return section
end

-- Direct tab controls create clean single rows outside a section.
function Tab:_directSection()
    if self._direct then return self._direct end
    local s=self:CreateSection({Title=""})
    local header=s._frame:FindFirstChild("Frame")
    if header then header.Visible=false; s._body.Position=UDim2.fromOffset(0,0) end
    self._direct=s
    return s
end

function Tab:CreateButton(config) return self:_directSection():CreateButton(config) end
function Tab:CreateToggle(config) return self:_directSection():CreateToggle(config) end
function Tab:CreateDropdown(config) return self:_directSection():CreateDropdown(config) end
function Tab:CreateMultiDropdown(config) return self:_directSection():CreateMultiDropdown(config) end
function Tab:CreateTextbox(config) return self:_directSection():CreateTextbox(config) end
function Tab:CreateSlider(config) return self:_directSection():CreateSlider(config) end
function Tab:CreateColorpicker(config) return self:_directSection():CreateColorpicker(config) end
function Tab:CreateStatRow() end
function Tab:CreateFeaturedCard() end
function Tab:CreateActionRow() end
function Tab:CreateCardGroup() end

local function attachRow(section, name, iconName, height)
    section._order+=1
    local row=make("Frame",{Name="Row_"..cleanName(name),BackgroundColor3=C.row,BorderSizePixel=0,Size=UDim2.new(1,0,0,height or 48),LayoutOrder=section._order,ClipsDescendants=false,ZIndex=60},section._body)
    corner(row,13); outline(row,C.lineSoft,0.35,1)
    if iconName then renderIcon(row,iconName,UDim2.fromOffset(12,12),UDim2.fromOffset(22,22),C.muted,63) end
    return row
end

function Section:CreateLabel(value)
    local row=attachRow(self,"Label",nil,36)
    local t=text(row,value,12,C.secondary,false); t.Position=UDim2.fromOffset(12,0); t.Size=UDim2.new(1,-24,1,0)
    return row
end

function Section:CreateButton(config)
    config=config or {}
    local row=attachRow(self,config.Name or config.Title or "Button",config.Icon,48)
    local t=text(row,config.Name or config.Title or "Button",13,C.text,true)
    t.Position=UDim2.fromOffset(config.Icon and 42 or 14,0); t.Size=UDim2.new(1,-58,1,0); t.ZIndex=63
    renderIcon(row,"chevron-right",UDim2.new(1,-31,0.5,-9),UDim2.fromOffset(18,18),C.muted,63)
    local hit=button(row,90)
    hit.Activated:Connect(function() if config.Callback then task.spawn(config.Callback) end end)
    hoverRow(row)
    return {_frame=row,Activate=function() if config.Callback then config.Callback() end end}
end

function Section:CreateToggle(config)
    config=config or {}
    local state=config.Default==true or config.Value==true
    local row=attachRow(self,config.Name or config.Title or "Toggle",config.Icon,48)
    local t=text(row,config.Name or config.Title or "Toggle",13,C.text,true)
    t.Position=UDim2.fromOffset(config.Icon and 42 or 14,0); t.Size=UDim2.new(1,-92,1,0); t.ZIndex=63
    local track=make("Frame",{BackgroundColor3=state and C.accent or Color3.fromRGB(48,54,65),BorderSizePixel=0,AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-12,0.5,0),Size=UDim2.fromOffset(48,28),ZIndex=64},row)
    corner(track,99)
    local knob=make("Frame",{BackgroundColor3=C.text,BorderSizePixel=0,Size=UDim2.fromOffset(22,22),Position=state and UDim2.new(1,-25,0.5,-11) or UDim2.fromOffset(3,3),ZIndex=65},track)
    corner(knob,99)
    local hit=button(row,95)
    local function set(v,emit)
        state=v==true
        tween(track,Motion.base,{BackgroundColor3=state and C.accent or Color3.fromRGB(48,54,65)})
        tween(knob,Motion.base,{Position=state and UDim2.new(1,-25,0.5,-11) or UDim2.fromOffset(3,3)})
        if emit and config.Callback then task.spawn(config.Callback,state) end
    end
    hit.Activated:Connect(function() set(not state,true) end)
    hoverRow(row)
    return {Set=function(_,v) set(v,true) end, SetValue=function(_,v) set(v,true) end, Get=function() return state end, GetValue=function() return state end, _frame=row}
end

local function optionList(options)
    local out={}
    if type(options)~="table" then return out end
    for _,v in ipairs(options) do
        if type(v)=="table" then v=v.Title or v.Name or v.Value or v.Text or v[1] end
        if v~=nil then out[#out+1]=tostring(v) end
    end
    return out
end

function Section:CreateDropdown(config)
    config=config or {}
    local options=optionList(config.Options or config.Values or {})
    local selected=tostring(config.Default or config.Value or options[1] or "Select")
    local open=false
    local baseH=52
    local row=attachRow(self,config.Name or config.Title or "Dropdown",config.Icon,baseH)
    local t=text(row,config.Name or config.Title or "Dropdown",12,C.secondary,true); t.Position=UDim2.fromOffset(config.Icon and 42 or 14,0); t.Size=UDim2.new(0.48,-42,0,48); t.ZIndex=63
    local value=text(row,selected,12,C.text,false); value.Position=UDim2.new(0.48,0,0,0); value.Size=UDim2.new(0.52,-48,0,48); value.TextXAlignment=Enum.TextXAlignment.Right; value.ZIndex=63
    renderIcon(row,"chevron-down",UDim2.new(1,-34,0.5,-8),UDim2.fromOffset(16,16),C.muted,64)

    local menu=make("ScrollingFrame",{Name="DropdownMenu",BackgroundColor3=C.shell,BorderSizePixel=0,Position=UDim2.fromOffset(8,48),Size=UDim2.new(1,-16,0,0),CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,Visible=false,ScrollBarThickness=2,ScrollBarImageColor3=C.muted,ZIndex=2000},row)
    corner(menu,12); outline(menu,C.line,0.15,1); padding(menu,5,5,5,5); list(menu,4)
    local hit=button(row,100)
    local function closeMenu()
        open=false; menu.Visible=false
    end
    local function choose(v)
        selected=v; value.Text=v; closeMenu()
        if config.Callback then task.spawn(config.Callback,v) end
    end
    for _,opt in ipairs(options) do
        local ob=make("TextButton",{Name="Option_"..cleanName(opt),Text="",BackgroundColor3=C.row,BorderSizePixel=0,Size=UDim2.new(1,0,0,34),AutoButtonColor=false,ZIndex=2010},menu)
        corner(ob,9)
        local ot=text(ob,opt,11,C.secondary,false); ot.Position=UDim2.fromOffset(10,0); ot.Size=UDim2.new(1,-20,1,0); ot.ZIndex=2012
        ob.Activated:Connect(function() choose(opt) end); hoverRow(ob)
    end
    hit.Activated:Connect(function()
        open=not open
        menu.Visible=open
        row.ZIndex=open and 1200 or 60
        if open then menu.CanvasPosition=Vector2.zero end
    end)
    hoverRow(row)
    return {Set=function(_,v) choose(tostring(v)) end,SetValue=function(_,v) choose(tostring(v)) end,Get=function() return selected end,_frame=row,_menu=menu}
end

function Section:CreateMultiDropdown(config)
    config=config or {}
    local options=optionList(config.Options or config.Values or {})
    local selected={}
    if type(config.Default)=="table" then for _,v in ipairs(config.Default) do selected[tostring(v)]=true end end
    local row=attachRow(self,config.Name or config.Title or "Multi Dropdown",config.Icon,52)
    local t=text(row,config.Name or config.Title or "Multi Dropdown",12,C.secondary,true); t.Position=UDim2.fromOffset(config.Icon and 42 or 14,0); t.Size=UDim2.new(0.45,-42,1,0); t.ZIndex=63
    local val=text(row,"None",11,C.text,false); val.Position=UDim2.new(0.45,0,0,0); val.Size=UDim2.new(0.55,-46,1,0); val.TextXAlignment=Enum.TextXAlignment.Right; val.ZIndex=63
    renderIcon(row,"chevron-down",UDim2.new(1,-34,0.5,-8),UDim2.fromOffset(16,16),C.muted,64)
    local menu=make("ScrollingFrame",{Name="MultiDropdownMenu",BackgroundColor3=C.shell,BorderSizePixel=0,Position=UDim2.fromOffset(8,48),Size=UDim2.new(1,-16,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),Visible=false,ScrollBarThickness=2,ScrollBarImageColor3=C.muted,ZIndex=2000},row)
    corner(menu,12); outline(menu,C.line,0.15,1); padding(menu,5,5,5,5); list(menu,4)
    local open=false
    local function updateLabel()
        local arr={}; for _,v in ipairs(options) do if selected[v] then arr[#arr+1]=v end end
        val.Text=(#arr==0 and "None" or (#arr<=2 and table.concat(arr,", ") or tostring(#arr).." selected"))
    end
    for _,opt in ipairs(options) do
        local ob=make("TextButton",{Name="Option_"..cleanName(opt),Text="",BackgroundColor3=C.row,BorderSizePixel=0,Size=UDim2.new(1,0,0,34),AutoButtonColor=false,ZIndex=2010},menu)
        corner(ob,9)
        local ot=text(ob,opt,11,C.secondary,false); ot.Position=UDim2.fromOffset(10,0); ot.Size=UDim2.new(1,-46,1,0); ot.ZIndex=2012
        local mark=make("Frame",{BackgroundTransparency=1,Size=UDim2.fromOffset(18,18),Position=UDim2.new(1,-26,0.5,-9),ZIndex=2012},ob)
        local function updateMark() mark:ClearAllChildren(); if selected[opt] then local c=make("Frame",{BackgroundTransparency=1,Size=UDim2.fromScale(1,1)},mark); drawLine(c,4,9,8,13,C.accent,2,2014); drawLine(c,8,13,15,5,C.accent,2,2014) end end
        updateMark()
        ob.Activated:Connect(function()
            selected[opt]=not selected[opt]; updateMark(); updateLabel()
            local arr={}; for _,v in ipairs(options) do if selected[v] then arr[#arr+1]=v end end
            if config.Callback then task.spawn(config.Callback,arr) end
        end)
        hoverRow(ob)
    end
    local hit=button(row,100)
    hit.Activated:Connect(function() open=not open; menu.Visible=open; row.ZIndex=open and 1200 or 60 end)
    updateLabel(); hoverRow(row)
    return {Set=function(_,v) if type(v)=="table" then selected={};for _,x in ipairs(v) do selected[tostring(x)]=true end; updateLabel() end end,Get=function() local out={};for _,v in ipairs(options) do if selected[v] then out[#out+1]=v end end;return out end,_frame=row,_menu=menu}
end

function Section:CreateTextbox(config)
    config=config or {}
    local row=attachRow(self,config.Name or config.Title or "Input",config.Icon,50)
    local t=text(row,config.Name or config.Title or "Input",12,C.secondary,true); t.Position=UDim2.fromOffset(config.Icon and 42 or 14,0); t.Size=UDim2.new(0.40,-42,1,0); t.ZIndex=63
    local box=make("TextBox",{BackgroundColor3=C.shell,BorderSizePixel=0,Text=tostring(config.Default or config.Value or ""),PlaceholderText=tostring(config.Placeholder or ""),TextColor3=C.text,PlaceholderColor3=C.muted,TextSize=12,Font=Enum.Font.Gotham,ClearTextOnFocus=false,TextXAlignment=Enum.TextXAlignment.Left,Size=UDim2.new(0.58,-8,0,34),Position=UDim2.new(0.40,0,0.5,-17),ZIndex=65},row)
    corner(box,10); outline(box,C.lineSoft,0.2,1); padding(box,10,10,0,0)
    local function emit() if config.Callback then task.spawn(config.Callback,box.Text) end end
    box.FocusLost:Connect(emit)
    hoverRow(row)
    return {Set=function(_,v) box.Text=tostring(v or "");emit() end,SetValue=function(_,v) box.Text=tostring(v or "");emit() end,Get=function() return box.Text end,_frame=row,_input=box}
end

function Section:CreateSlider(config)
    config=config or {}
    local min=tonumber(config.Min or config.Minimum or 0) or 0
    local max=tonumber(config.Max or config.Maximum or 100) or 100
    local current=tonumber(config.Default or config.Value or min) or min
    current=math.clamp(current,min,max)
    local row=attachRow(self,config.Name or config.Title or "Slider",config.Icon,64)
    local t=text(row,config.Name or config.Title or "Slider",12,C.secondary,true); t.Position=UDim2.fromOffset(config.Icon and 42 or 14,5); t.Size=UDim2.new(0.48,-42,0,22); t.ZIndex=63
    local value=text(row,tostring(current),11,C.text,true); value.Position=UDim2.new(1,-72,0,5); value.Size=UDim2.fromOffset(58,22); value.TextXAlignment=Enum.TextXAlignment.Right; value.ZIndex=63
    local track=make("Frame",{BackgroundColor3=C.shell,BorderSizePixel=0,Position=UDim2.new(0,14,1,-22),Size=UDim2.new(1,-28,0,6),ZIndex=63},row);corner(track,99)
    local fill=make("Frame",{BackgroundColor3=C.accent,BorderSizePixel=0,Size=UDim2.new((current-min)/math.max(1,max-min),0,1,0),ZIndex=64},track);corner(fill,99)
    local hit=button(track,70)
    local function setFromX(x,emit)
        local pct=math.clamp((x-track.AbsolutePosition.X)/math.max(1,track.AbsoluteSize.X),0,1)
        current=math.floor((min+(max-min)*pct)+0.5)
        value.Text=tostring(current); fill.Size=UDim2.new(pct,0,1,0)
        if emit and config.Callback then task.spawn(config.Callback,current) end
    end
    hit.Activated:Connect(function() end)
    hit.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            setFromX(input.Position.X,true)
            local con
            con=UserInputService.InputChanged:Connect(function(move)
                if move.UserInputType==Enum.UserInputType.MouseMovement or move.UserInputType==Enum.UserInputType.Touch then setFromX(move.Position.X,true) end
            end)
            input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End and con then con:Disconnect() end end)
        end
    end)
    return {Set=function(_,v) current=math.clamp(tonumber(v) or min,min,max);local pct=(current-min)/math.max(1,max-min);value.Text=tostring(current);fill.Size=UDim2.new(pct,0,1,0);if config.Callback then config.Callback(current) end end,Get=function() return current end,_frame=row}
end

function Section:CreateColorpicker(config)
    config=config or {}
    -- Compact color control. Kept intentionally dependency-free.
    local row=attachRow(self,config.Name or config.Title or "Color",config.Icon,48)
    local t=text(row,config.Name or config.Title or "Color",13,C.text,true); t.Position=UDim2.fromOffset(config.Icon and 42 or 14,0); t.Size=UDim2.new(1,-86,1,0); t.ZIndex=63
    local swatch=make("Frame",{BackgroundColor3=config.Default or Color3.new(1,1,1),BorderSizePixel=0,AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-14,0.5,0),Size=UDim2.fromOffset(36,24),ZIndex=64},row);corner(swatch,9);outline(swatch,C.line,0.2,1)
    return {Set=function(_,v)if typeof(v)=="Color3" then swatch.BackgroundColor3=v end end,Get=function()return swatch.BackgroundColor3 end,_frame=row}
end

return UI
