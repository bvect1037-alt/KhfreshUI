-- KhfreshUI - Khfresh Hub Bento Grid / Lucide
-- Standalone UI library built for the Khfresh Hub API.
-- The supplied BentoGridStyle source is used only as structural inspiration.
-- No assets, feature logic, theme objects, or floating-button visuals are copied from it.


local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local KhfreshLib = {
    _windows = {},
    _themeName = "Bento",
    __KhfreshHubUIVersion = "2.0.0",
}

local themes = {
    Bento = {
        Canvas = Color3.fromRGB(4, 5, 7),
        Shell = Color3.fromRGB(8, 10, 13),
        Rail = Color3.fromRGB(6, 8, 11),
        Card = Color3.fromRGB(11, 14, 18),
        CardRaised = Color3.fromRGB(14, 18, 23),
        Hover = Color3.fromRGB(18, 23, 30),
        Pressed = Color3.fromRGB(24, 30, 39),
        Border = Color3.fromRGB(30, 37, 47),
        BorderSoft = Color3.fromRGB(20, 25, 32),
        Text = Color3.fromRGB(241, 244, 248),
        Secondary = Color3.fromRGB(158, 168, 183),
        Muted = Color3.fromRGB(89, 99, 114),
        Accent = Color3.fromRGB(96, 183, 255),
        AccentSoft = Color3.fromRGB(28, 55, 80),
        Success = Color3.fromRGB(91, 218, 156),
        Danger = Color3.fromRGB(255, 105, 122),
        Warning = Color3.fromRGB(255, 188, 84),
    },
}

local THEME = themes.Bento
local function theme()
    return THEME
end

local function getParent()
    local ok, hui = pcall(function()
        return (type(gethui) == "function" and gethui()) or game:GetService("CoreGui")
    end)
    if ok and hui then return hui end
    return LocalPlayer and LocalPlayer:WaitForChild("PlayerGui")
end

local function protectGui(gui)
    pcall(function()
        if syn and syn.protect_gui then syn.protect_gui(gui) end
    end)
end

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 12)
    c.Parent = parent
    return c
end

local function stroke(parent, color, transparency, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or theme().Border
    s.Transparency = transparency or 0
    s.Thickness = thickness or 1
    s.Parent = parent
    return s
end

local function padding(parent, l, r, t, b)
    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0, l or 0)
    p.PaddingRight = UDim.new(0, r or 0)
    p.PaddingTop = UDim.new(0, t or 0)
    p.PaddingBottom = UDim.new(0, b or 0)
    p.Parent = parent
    return p
end

local function tween(obj, info, props)
    local ok, result = pcall(function()
        return TweenService:Create(obj, info, props)
    end)
    if ok and result then result:Play() end
    return result
end

local function sanitizeName(text)
    text = tostring(text or "Icon")
    return text:gsub("%s+", "-")
end

-- Lucide Roblox asset IDs. These are Lucide icons, independent from the supplied UI base.
-- Older Lucide asset packs do not contain volleyball, so that one is rendered below as a
-- small native vector reconstruction of the Lucide volleyball geometry.
local LUCIDE = {
    ["layout-dashboard"] = "rbxassetid://10723424646",
    ["house"] = "rbxassetid://10723407389",
    ["history"] = "rbxassetid://10723407335",
    ["info"] = "rbxassetid://10723415903",
    ["copy"] = "rbxassetid://10709812159",
    ["external-link"] = "rbxassetid://10723346684",
    ["eye-off"] = "rbxassetid://10723346871",
    ["hand-heart"] = "rbxassetid://10723406480",
    ["message-circle"] = "rbxassetid://10734888000",
    ["play"] = "rbxassetid://10734923549",
    ["music-2"] = "rbxassetid://10734900215",
    ["shapes"] = "rbxassetid://10734965702", -- safe shape fallback
    ["sparkles"] = "rbxassetid://10734966248", -- safe star fallback
    ["user-round"] = "rbxassetid://10747373176",
    ["users-round"] = "rbxassetid://10747373426",
    ["zap"] = "rbxassetid://10709781460", -- safe bolt fallback
    ["panel-left"] = "rbxassetid://10734954301",
    ["panels-top-left"] = "rbxassetid://10723424838",
    ["badge-check"] = "rbxassetid://10747374131",
    ["check"] = "rbxassetid://10709790644",
    ["chevron-down"] = "rbxassetid://10709790948",
    ["chevron-up"] = "rbxassetid://10709791523",
    ["x"] = "rbxassetid://10747384394",
    ["minus"] = "rbxassetid://10734896206",
    ["settings"] = "rbxassetid://10734950309",
    ["search"] = "rbxassetid://10734943674",
    ["fish"] = "rbxassetid://10723397788",
    ["shopping-bag"] = "rbxassetid://10734952273",
    ["repeat"] = "rbxassetid://10734933966",
    ["list-checks"] = "rbxassetid://10734884548",
    ["map"] = "rbxassetid://10734886202",
    ["gamepad-2"] = "rbxassetid://10723416527",
    ["shield"] = "rbxassetid://10734951847",
    ["users"] = "rbxassetid://10747373426",
    ["circle"] = "rbxassetid://10709798174",
    ["circle-check"] = "rbxassetid://10709790387",
    ["alert-triangle"] = "rbxassetid://10709753149",
    ["bell"] = "rbxassetid://10709775704",
    ["arrow-up-right"] = "rbxassetid://10723368787",
}

local tabIconDefaults = {
    Overview = "house",
    Home = "house",
    Routine = "zap",
    Shop = "shopping-bag",
    Exchange = "repeat",
    Quests = "list-checks",
    Upgrade = "sparkles",
    Teleport = "map",
    Settings = "settings",
}

local function parseIconName(icon)
    if type(icon) == "number" then
        return "" -- intentionally not a bundled image
    end
    icon = tostring(icon or "")
    icon = icon:gsub("^lucide%-", "")
    return icon
end

local function makeMiniVector(parent, name, tint)
    -- Native vector fallback used only for unsupported/missing raster IDs.
    -- Volleyball is intentionally drawn in native GuiObjects so it does not depend on
    -- any image/logo from the old library.
    local holder = Instance.new("Frame")
    holder.Name = sanitizeName(name) .. "-Vector"
    holder.Size = UDim2.fromOffset(22, 22)
    holder.BackgroundTransparency = 1
    holder.Parent = parent

    local function line(a, b, thickness)
        local f = Instance.new("Frame")
        f.BorderSizePixel = 0
        f.BackgroundColor3 = tint
        f.AnchorPoint = Vector2.new(0.5, 0.5)
        local dx, dy = b.X - a.X, b.Y - a.Y
        local len = math.sqrt(dx * dx + dy * dy)
        f.Size = UDim2.fromOffset(len, thickness or 1.5)
        f.Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2)
        f.Rotation = math.deg(math.atan2(dy, dx))
        f.Parent = holder
        return f
    end

    if name == "volleyball" then
        local cx, cy, r = 11, 11, 9
        local pts = {}
        for i = 0, 31 do
            local a = (i / 32) * math.pi * 2
            pts[i + 1] = Vector2.new(cx + math.cos(a) * r, cy + math.sin(a) * r)
        end
        for i = 1, #pts do
            line(pts[i], pts[(i % #pts) + 1], 1.25)
        end
        -- Lucide volleyball's characteristic curved seams, approximated as short arcs.
        local seams = {
            {Vector2.new(11.1, 7.1), Vector2.new(18, 8.4), Vector2.new(22, 11.1)},
            {Vector2.new(12, 12), Vector2.new(7.4, 14.7), Vector2.new(3.3, 17)},
            {Vector2.new(16.8, 13.6), Vector2.new(13.7, 18), Vector2.new(7.8, 21.1)},
            {Vector2.new(20.7, 17), Vector2.new(17.5, 14), Vector2.new(12, 12), Vector2.new(12, 2)},
            {Vector2.new(6.3, 3.8), Vector2.new(6.9, 8.6), Vector2.new(8.2, 15.3)},
        }
        for _, segs in ipairs(seams) do
            for i = 1, #segs - 1 do line(segs[i], segs[i + 1], 1.35) end
        end
        return holder
    end

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = "•"
    label.Font = Enum.Font.GothamBold
    label.TextSize = 18
    label.TextColor3 = tint
    label.Parent = holder
    return holder
end

local function addIcon(parent, name, size, color, z)
    name = parseIconName(name)
    size = size or 18
    color = color or theme().Secondary

    if name == "volleyball" then
        local vector = makeMiniVector(parent, "volleyball", color)
        vector.Size = UDim2.fromOffset(size, size)
        vector.ZIndex = z or 1
        return vector
    end

    local asset = LUCIDE[name]
    if not asset then
        asset = LUCIDE["circle"]
        name = "circle"
    end

    local img = Instance.new("ImageLabel")
    img.Name = sanitizeName(name)
    img.Size = UDim2.fromOffset(size, size)
    img.BackgroundTransparency = 1
    img.Image = asset
    img.ImageColor3 = color
    img.ScaleType = Enum.ScaleType.Fit
    img.ZIndex = z or 1
    img.Parent = parent
    return img
end

local function createText(parent, text, size, color, font, align)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Text = tostring(text or "")
    label.TextColor3 = color or theme().Text
    label.TextSize = size or 14
    label.Font = font or Enum.Font.Gotham
    label.TextXAlignment = align or Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.RichText = false
    label.Parent = parent
    return label
end

local function makeButton(parent, size, bg, radius)
    local b = Instance.new("TextButton")
    b.Size = size
    b.AutoButtonColor = false
    b.Text = ""
    b.BackgroundColor3 = bg or theme().Card
    b.BorderSizePixel = 0
    corner(b, radius or 10)
    b.Parent = parent
    return b
end

local function canCallback(fn, value)
    if type(fn) ~= "function" then return end
    task.spawn(function()
        local ok, err = pcall(fn, value)
        if not ok then warn("[KhfreshUI] Callback error: " .. tostring(err)) end
    end)
end

-- Notification service ------------------------------------------------------
local notificationHolder
local function ensureNotifications()
    if notificationHolder and notificationHolder.Parent then return notificationHolder end
    local sg = Instance.new("ScreenGui")
    sg.Name = "KhfreshNotifications"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 2147483646
    protectGui(sg)
    sg.Parent = getParent()

    local holder = Instance.new("Frame")
    holder.Name = "Holder"
    holder.BackgroundTransparency = 1
    holder.Size = UDim2.fromOffset(340, 0)
    holder.Position = UDim2.new(1, -354, 0, 20)
    holder.AutomaticSize = Enum.AutomaticSize.Y
    holder.Parent = sg

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = holder

    notificationHolder = holder
    return holder
end

function KhfreshLib:Notify(cfg)
    cfg = cfg or {}
    local holder = ensureNotifications()
    local t = theme()
    local card = Instance.new("Frame")
    card.BackgroundColor3 = t.CardRaised
    card.BackgroundTransparency = 0.02
    card.BorderSizePixel = 0
    card.Size = UDim2.fromOffset(330, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    corner(card, 14)
    stroke(card, t.Border, 0.05, 1)
    card.Parent = holder

    padding(card, 12, 12, 11, 11)
    local row = Instance.new("Frame")
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1, 0, 0, 38)
    row.Parent = card

    local iconWrap = Instance.new("Frame")
    iconWrap.BackgroundColor3 = t.AccentSoft
    iconWrap.BorderSizePixel = 0
    iconWrap.Size = UDim2.fromOffset(34, 34)
    corner(iconWrap, 10)
    iconWrap.Parent = row
    addIcon(iconWrap, cfg.Icon or "info", 17, t.Accent, 3).Position = UDim2.fromOffset(8.5, 8.5)

    local textWrap = Instance.new("Frame")
    textWrap.BackgroundTransparency = 1
    textWrap.Position = UDim2.new(0, 46, 0, 0)
    textWrap.Size = UDim2.new(1, -46, 1, 0)
    textWrap.Parent = row

    local title = createText(textWrap, cfg.Title or "Khfresh", 14, t.Text, Enum.Font.GothamBold)
    title.Size = UDim2.new(1, 0, 0, 19)
    local message = cfg.Message or cfg.Content or ""
    local body = createText(textWrap, message, 12, t.Secondary, Enum.Font.Gotham)
    body.Position = UDim2.fromOffset(0, 19)
    body.Size = UDim2.new(1, 0, 0, 40)
    body.TextWrapped = true
    body.AutomaticSize = Enum.AutomaticSize.Y

    card.BackgroundTransparency = 1
    card.Position = UDim2.fromOffset(24, 0)
    tween(card, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.02,
        Position = UDim2.fromOffset(0, 0),
    })

    local duration = tonumber(cfg.Duration) or 3
    task.delay(math.max(duration, 0.25), function()
        if card and card.Parent then
            tween(card, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(26, 0),
            })
            task.wait(0.2)
            if card.Parent then card:Destroy() end
        end
    end)
    return card
end

-- Window --------------------------------------------------------------------
local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local Section = {}
Section.__index = Section

local Control = {}
Control.__index = Control

function KhfreshLib:SetTheme(name)
    name = tostring(name or "Bento")
    THEME = themes[name] or themes.Bento
    self._themeName = (themes[name] and name) or "Bento"
    for _, win in ipairs(self._windows) do
        pcall(function() win:_applyTheme() end)
    end
    return self
end

function Window:_applyTheme()
    local t = theme()
    if self._gui then
        local root = self._gui:FindFirstChild("Root")
        if root then root.BackgroundColor3 = t.Canvas end
    end
    if self._shell then self._shell.BackgroundColor3 = t.Shell end
    if self._rail then self._rail.BackgroundColor3 = t.Rail end
end

function Window:_makeRoot(config)
    local t = theme()
    local parent = getParent()
    local gui = Instance.new("ScreenGui")
    gui.Name = "KhfreshPanel"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 2147483645
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    protectGui(gui)
    gui.Parent = parent

    local root = Instance.new("Frame")
    root.Name = "Root"
    root.BackgroundColor3 = t.Canvas
    root.BackgroundTransparency = 0
    root.BorderSizePixel = 0
    root.Size = UDim2.fromScale(1, 1)
    root.Parent = gui

    local size = config.Size or UDim2.fromOffset(780, 560)
    local shell = Instance.new("CanvasGroup")
    shell.Name = "Shell"
    shell.Size = size
    shell.Position = UDim2.fromScale(0.5, 0.5)
    shell.AnchorPoint = Vector2.new(0.5, 0.5)
    shell.BackgroundColor3 = t.Shell
    shell.BorderSizePixel = 0
    shell.GroupTransparency = 0
    shell.Parent = root
    corner(shell, 20)
    stroke(shell, t.Border, 0.02, 1)

    local shadow = Instance.new("Frame")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 10, 1, 10)
    shadow.Position = UDim2.fromOffset(-5, 8)
    shadow.BackgroundColor3 = Color3.new(0, 0, 0)
    shadow.BackgroundTransparency = 0.72
    shadow.BorderSizePixel = 0
    corner(shadow, 23)
    shadow.ZIndex = 0
    shadow.Parent = shell
    shell.ZIndex = 2

    local rail = Instance.new("Frame")
    rail.Name = "Rail"
    rail.Size = UDim2.new(0, 168, 1, 0)
    rail.BackgroundColor3 = t.Rail
    rail.BorderSizePixel = 0
    rail.ZIndex = 3
    rail.Parent = shell

    local railTop = Instance.new("Frame")
    railTop.BackgroundTransparency = 1
    railTop.Size = UDim2.new(1, -24, 0, 64)
    railTop.Position = UDim2.fromOffset(12, 12)
    railTop.Parent = rail

    local mark = Instance.new("Frame")
    mark.Size = UDim2.fromOffset(34, 34)
    mark.BackgroundColor3 = t.AccentSoft
    mark.BorderSizePixel = 0
    corner(mark, 11)
    mark.Parent = railTop
    addIcon(mark, config.Icon or "layout-dashboard", 18, t.Accent, 4).Position = UDim2.fromOffset(8, 8)

    local title = createText(railTop, config.Title or "Khfresh Hub", 14, t.Text, Enum.Font.GothamBold)
    title.Position = UDim2.fromOffset(46, 2)
    title.Size = UDim2.new(1, -46, 0, 20)
    local author = createText(railTop, config.Author or "Bento UI", 10, t.Muted, Enum.Font.Gotham)
    author.Position = UDim2.fromOffset(46, 24)
    author.Size = UDim2.new(1, -46, 0, 18)

    local nav = Instance.new("ScrollingFrame")
    nav.Name = "Nav"
    nav.BackgroundTransparency = 1
    nav.BorderSizePixel = 0
    nav.Position = UDim2.fromOffset(10, 86)
    nav.Size = UDim2.new(1, -20, 1, -98)
    nav.CanvasSize = UDim2.new()
    nav.AutomaticCanvasSize = Enum.AutomaticSize.Y
    nav.ScrollBarThickness = 0
    nav.Parent = rail
    local navLayout = Instance.new("UIListLayout")
    navLayout.Padding = UDim.new(0, 6)
    navLayout.SortOrder = Enum.SortOrder.LayoutOrder
    navLayout.Parent = nav

    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Position = UDim2.fromOffset(168, 0)
    main.Size = UDim2.new(1, -168, 1, 0)
    main.BackgroundColor3 = t.Canvas
    main.BorderSizePixel = 0
    main.ZIndex = 3
    main.Parent = shell

    local top = Instance.new("Frame")
    top.Name = "Topbar"
    top.Size = UDim2.new(1, -24, 0, 60)
    top.Position = UDim2.fromOffset(12, 10)
    top.BackgroundColor3 = t.Card
    top.BorderSizePixel = 0
    top.Active = true
    corner(top, 14)
    stroke(top, t.BorderSoft, 0.1, 1)
    top.ZIndex = 5
    top.Parent = main

    local pageTitle = createText(top, "Overview", 17, t.Text, Enum.Font.GothamBold)
    pageTitle.Position = UDim2.fromOffset(16, 7)
    pageTitle.Size = UDim2.new(1, -120, 0, 22)

    local context = createText(top, config.Subtitle or "Khfresh Hub", 10, t.Muted, Enum.Font.Gotham)
    context.Position = UDim2.fromOffset(16, 31)
    context.Size = UDim2.new(1, -120, 0, 16)

    local mini = makeButton(top, UDim2.fromOffset(34, 34), t.CardRaised, 10)
    mini.Position = UDim2.new(1, -80, 0.5, -17)
    mini.Parent = top
    addIcon(mini, "minus", 16, t.Secondary, 4).Position = UDim2.fromOffset(9, 9)

    local close = makeButton(top, UDim2.fromOffset(34, 34), t.CardRaised, 10)
    close.Position = UDim2.new(1, -40, 0.5, -17)
    close.Parent = top
    addIcon(close, "x", 16, t.Secondary, 4).Position = UDim2.fromOffset(9, 9)

    local body = Instance.new("Frame")
    body.Name = "Body"
    body.BackgroundTransparency = 1
    body.Active = true
    body.Position = UDim2.fromOffset(12, 80)
    body.Size = UDim2.new(1, -24, 1, -92)
    body.ZIndex = 5
    body.Parent = main

    local bg = Instance.new("ImageLabel")
    bg.Name = "Background"
    bg.BackgroundTransparency = 1
    bg.ImageTransparency = 1
    bg.ImageColor3 = Color3.new(1, 1, 1)
    bg.ScaleType = Enum.ScaleType.Crop
    bg.Size = UDim2.fromScale(1, 1)
    bg.ZIndex = 1
    bg.Visible = false
    bg.Parent = main

    local bgShade = Instance.new("Frame")
    bgShade.Name = "BackgroundShade"
    bgShade.Size = UDim2.fromScale(1, 1)
    bgShade.BackgroundColor3 = Color3.fromRGB(2, 3, 5)
    bgShade.BackgroundTransparency = 1
    bgShade.BorderSizePixel = 0
    bgShade.ZIndex = 2
    bgShade.Visible = false
    bgShade.Parent = main

    -- input drag layer: the topbar itself is the drag handle
    local dragging = false
    local dragStart, startPos
    top.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = shell.Position
        end
    end)
    top.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            shell.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    mini.Activated:Connect(function() self:Minimize() end)
    close.Activated:Connect(function() self:Close() end)

    self._gui = gui
    self._root = root
    self._shell = shell
    self._shadow = shadow
    self._rail = rail
    self._nav = nav
    self._main = main
    self._body = body
    self._top = top
    self._pageTitle = pageTitle
    self._context = context
    self._background = bg
    self._backgroundShade = bgShade
    self._dragTop = top
end

function KhfreshLib:CreateWindow(config)
    config = config or {}
    self:DestroyAll()

    local win = setmetatable({
        _tabs = {},
        _active = nil,
        _tabSerial = 0,
        _minimized = false,
        _floating = nil,
        _logo = nil,
        _raw = nil,
    }, Window)

    win._raw = win
    win._config = config
    win:_makeRoot(config)

    local initialTab
    if config.CreateInitialTab ~= false then
        initialTab = win:CreateTab({
            Title = config.InitialTab or "Overview",
            Icon = config.InitialIcon or config.Icon or "layout-dashboard",
        })
    end

    table.insert(KhfreshLib._windows, win)
    if config.Floating ~= false then
        pcall(function() win:CreateFloatingToggle() end)
    end
    return win
end

function Window:CreateTab(input)
    local config
    if type(input) == "table" then
        config = input
    else
        config = { Title = tostring(input or "Tab") }
    end

    local name = tostring(config.Title or config.Name or "Tab")
    if self:GetTab(name) then return self:GetTab(name) end

    self._tabSerial += 1
    local t = theme()
    local button = makeButton(self._nav, UDim2.new(1, 0, 0, 42), t.Rail, 11)
    button.LayoutOrder = self._tabSerial
    button.BackgroundTransparency = 1

    local iconHolder = Instance.new("Frame")
    iconHolder.Size = UDim2.fromOffset(28, 28)
    iconHolder.Position = UDim2.fromOffset(7, 7)
    iconHolder.BackgroundTransparency = 1
    iconHolder.Parent = button
    addIcon(iconHolder, config.Icon or tabIconDefaults[name] or "layout-dashboard", 17, t.Muted, 5).Position = UDim2.fromOffset(5, 5)

    local lbl = createText(button, name, 12, t.Secondary, Enum.Font.GothamMedium)
    lbl.Position = UDim2.fromOffset(43, 0)
    lbl.Size = UDim2.new(1, -50, 1, 0)

    local page = Instance.new("ScrollingFrame")
    page.Name = "Page-" .. sanitizeName(name)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.Size = UDim2.fromScale(1, 1)
    page.CanvasSize = UDim2.new()
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.ScrollBarThickness = 4
    page.ScrollBarImageColor3 = t.Border
    page.ScrollBarImageTransparency = 0.15
    page.Visible = false
    page.ZIndex = 5
    page.Parent = self._body

    local header = Instance.new("Frame")
    header.BackgroundTransparency = 1
    header.Size = UDim2.new(1, 0, 0, 1)
    header.Parent = page

    local grid = Instance.new("Frame")
    grid.Name = "BentoGrid"
    grid.BackgroundTransparency = 1
    grid.Position = UDim2.fromOffset(2, 2)
    grid.Size = UDim2.new(1, -6, 0, 0)
    grid.AutomaticSize = Enum.AutomaticSize.Y
    grid.ZIndex = 5
    grid.Parent = page

    local left = Instance.new("Frame")
    left.Name = "ColumnA"
    left.BackgroundTransparency = 1
    left.Position = UDim2.fromOffset(0, 0)
    left.Size = UDim2.new(0.5, -6, 0, 0)
    left.AutomaticSize = Enum.AutomaticSize.Y
    left.Parent = grid
    local leftLayout = Instance.new("UIListLayout")
    leftLayout.Padding = UDim.new(0, 10)
    leftLayout.SortOrder = Enum.SortOrder.LayoutOrder
    leftLayout.Parent = left

    local right = Instance.new("Frame")
    right.Name = "ColumnB"
    right.BackgroundTransparency = 1
    right.Position = UDim2.new(0.5, 6, 0, 0)
    right.Size = UDim2.new(0.5, -6, 0, 0)
    right.AutomaticSize = Enum.AutomaticSize.Y
    right.Parent = grid
    local rightLayout = Instance.new("UIListLayout")
    rightLayout.Padding = UDim.new(0, 10)
    rightLayout.SortOrder = Enum.SortOrder.LayoutOrder
    rightLayout.Parent = right

    local tab = setmetatable({
        _window = self,
        _name = name,
        _icon = config.Icon or tabIconDefaults[name],
        _button = button,
        _label = lbl,
        _page = page,
        _grid = grid,
        _left = left,
        _right = right,
        _sectionCount = 0,
        _currentSection = nil,
        _defaultSection = nil,
        _headerHeight = 0,
    }, Tab)

    table.insert(self._tabs, tab)

    button.Activated:Connect(function()
        self:SelectTab(#self._tabs)
    end)

    if #self._tabs == 1 then self:SelectTab(1) end
    return tab
end

function Window:GetTab(name)
    name = tostring(name or "")
    for _, tab in ipairs(self._tabs) do
        if tab._name == name then return tab end
    end
    return nil
end

function Window:SelectTab(indexOrName)
    local target
    if type(indexOrName) == "number" then
        target = self._tabs[indexOrName]
    else
        target = self:GetTab(indexOrName)
    end
    if not target then return false end

    local t = theme()
    for i, tab in ipairs(self._tabs) do
        local active = (tab == target)
        tab._page.Visible = active
        tab._button.BackgroundColor3 = active and t.Hover or t.Rail
        tab._button.BackgroundTransparency = active and 0 or 1
        tab._label.TextColor3 = active and t.Text or t.Secondary
        for _, obj in ipairs(tab._button:GetChildren()) do
            if obj:IsA("Frame") then
                for _, icon in ipairs(obj:GetChildren()) do
                    if icon:IsA("ImageLabel") then
                        icon.ImageColor3 = active and t.Accent or t.Muted
                    end
                end
            end
        end
    end
    self._active = target
    self._pageTitle.Text = target._name
    self._context.Text = self._config and (self._config.Subtitle or "Khfresh Hub") or "Khfresh Hub"
    return true
end

function Window:Toggle()
    if not self._shell then return end
    if self._gui then self._gui.Enabled = true end
    self._shell.Visible = not self._shell.Visible
    self._minimized = not self._shell.Visible
end

function Window:Open()
    if self._gui then self._gui.Enabled = true end
    if self._shell then self._shell.Visible = true end
    self._minimized = false
end

function Window:Minimize()
    self._minimized = true
    if self._shell then self._shell.Visible = false end
end

function Window:Close()
    -- Close the panel but keep the library-owned floating toggle alive so the panel can reopen.
    self._minimized = true
    if self._shell then self._shell.Visible = false end
    if self._floating then self._floating.Enabled = true end
    if self._gui then self._gui.Enabled = true end
end

function Window:SetLogo(asset)
    if not self._top then return end
    if self._logo then self._logo:Destroy(); self._logo = nil end
    if asset == nil or asset == "" then return end
    local logo = Instance.new("ImageLabel")
    logo.Name = "Logo"
    logo.BackgroundTransparency = 1
    logo.Image = tostring(asset)
    logo.ImageColor3 = Color3.new(1, 1, 1)
    logo.ScaleType = Enum.ScaleType.Fit
    logo.Size = UDim2.fromOffset(22, 22)
    logo.Position = UDim2.new(1, -120, 0.5, -11)
    logo.ZIndex = 5
    logo.Parent = self._top
    self._logo = logo
end

function Window:SetBackground(asset, imageTransparency, shadeTransparency)
    if not self._background then return end
    if not asset or asset == "" then
        self._background.Visible = false
        if self._backgroundShade then self._backgroundShade.Visible = false end
        return
    end
    self._background.Image = tostring(asset)
    self._background.ImageTransparency = tonumber(imageTransparency) or 0.30
    self._background.Visible = true
    self._background.ZIndex = 1
    self._background.ImageColor3 = Color3.fromRGB(165, 178, 205)
    if self._backgroundShade then
        self._backgroundShade.BackgroundTransparency = tonumber(shadeTransparency) or 0.35
        self._backgroundShade.Visible = true
        self._backgroundShade.ZIndex = 2
    end
end
function Window:CreateFloatingToggle(cfg)
    cfg = cfg or {}
    if self._floating then self._floating:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = "KhfreshFloatingGui"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 2147483647
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    protectGui(sg)
    sg.Parent = getParent()

    local btn = makeButton(sg, UDim2.fromOffset(58, 58), theme().CardRaised, 18)
    btn.Position = UDim2.new(1, -70, 1, -112)
    btn.ZIndex = 3
    stroke(btn, theme().Border, 0.02, 1.2)

    local icon = addIcon(btn, "volleyball", 26, theme().Accent, 5)
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.Position = UDim2.fromScale(0.5, 0.5)

    local scale = Instance.new("UIScale")
    scale.Scale = 1
    scale.Parent = btn

    local dragging, moved = false, false
    local dragStart, startPos
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            moved = false
            dragStart = input.Position
            startPos = btn.Position
        end
    end)
    btn.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local d = input.Position - dragStart
            if math.abs(d.X) + math.abs(d.Y) > 6 then moved = true end
            btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
    btn.MouseEnter:Connect(function()
        tween(scale, TweenInfo.new(0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Scale = 1.06})
    end)
    btn.MouseLeave:Connect(function()
        tween(scale, TweenInfo.new(0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Scale = 1})
    end)
    btn.Activated:Connect(function()
        if not moved then self:Toggle() end
    end)

    self._floating = sg
    return sg
end

function Window:Destroy()
    if self._floating then self._floating:Destroy(); self._floating = nil end
    if self._gui then self._gui:Destroy(); self._gui = nil end
end

function KhfreshLib:DestroyAll()
    for _, win in ipairs(self._windows) do pcall(function() win:Destroy() end) end
    table.clear(self._windows)
    return self
end

-- Helpers shared by every Tab / Section ------------------------------------
local function normalizeSectionInput(input)
    if type(input) == "table" then return input end
    return { Title = tostring(input or "Section") }
end

function Tab:CreateHeader(cfg)
    cfg = type(cfg) == "table" and cfg or {Title = tostring(cfg or "Header")}
    local t = theme()
    local card = Instance.new("Frame")
    card.BackgroundColor3 = t.CardRaised
    card.BorderSizePixel = 0
    card.Size = UDim2.new(1, 0, 0, 68)
    self._headerHeight = self._headerHeight + 74
    card.Position = UDim2.fromOffset(0, self._headerHeight - 74 + 2)
    self._grid.Position = UDim2.fromOffset(2, self._headerHeight + 2)
    card.LayoutOrder = -100 + self._sectionCount
    corner(card, 14)
    stroke(card, t.BorderSoft, 0.05, 1)
    card.Parent = self._page

    local iconBox = Instance.new("Frame")
    iconBox.Size = UDim2.fromOffset(42, 42)
    iconBox.Position = UDim2.fromOffset(13, 13)
    iconBox.BackgroundColor3 = t.AccentSoft
    iconBox.BorderSizePixel = 0
    corner(iconBox, 12)
    iconBox.Parent = card
    local icon = addIcon(iconBox, cfg.Icon or "sparkles", 19, t.Accent, 5)
    icon.Position = UDim2.fromOffset(11.5, 11.5)

    local title = createText(card, cfg.Title or "Khfresh Hub", 14, t.Text, Enum.Font.GothamBold)
    title.Position = UDim2.fromOffset(68, 10)
    title.Size = UDim2.new(1, -84, 0, 20)
    local sub = createText(card, cfg.Subtitle or cfg.Description or "", 11, t.Secondary, Enum.Font.Gotham)
    sub.Position = UDim2.fromOffset(68, 32)
    sub.Size = UDim2.new(1, -84, 0, 26)
    sub.TextWrapped = true
    return {Instance = card, SetTitle = function(_, v) title.Text = tostring(v) end}
end

function Tab:_default()
    if self._defaultSection and self._defaultSection._card and self._defaultSection._card.Parent then return self._defaultSection end
    self._defaultSection = self:CreateSection({Title = "Controls", Icon = "panel-left"})
    self._currentSection = self._defaultSection
    return self._defaultSection
end

function Tab:CreateSection(input)
    local cfg = normalizeSectionInput(input)
    local t = theme()
    self._sectionCount += 1

    local card = Instance.new("Frame")
    card.BackgroundColor3 = t.Card
    card.BorderSizePixel = 0
    card.Size = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    corner(card, 16)
    stroke(card, t.BorderSoft, 0.05, 1)

    local right = self._right
    local left = self._left
    if cfg.Column == 2 or (cfg.Column ~= 1 and (self._sectionCount % 2 == 0)) then right = self._right else left = self._left end
    card.Parent = (cfg.Column == 2 or (cfg.Column ~= 1 and (self._sectionCount % 2 == 0))) and right or left
    card.LayoutOrder = self._sectionCount

    local titleRow = Instance.new("Frame")
    titleRow.BackgroundTransparency = 1
    titleRow.Size = UDim2.new(1, -24, 0, 43)
    titleRow.Position = UDim2.fromOffset(12, 10)
    titleRow.Parent = card

    local iconBox = Instance.new("Frame")
    iconBox.Size = UDim2.fromOffset(32, 32)
    iconBox.Position = UDim2.fromOffset(0, 1)
    iconBox.BackgroundColor3 = t.CardRaised
    iconBox.BorderSizePixel = 0
    corner(iconBox, 9)
    iconBox.Parent = titleRow
    local titleIcon = addIcon(iconBox, cfg.Icon or "shapes", 16, t.Accent, 4)
    titleIcon.Position = UDim2.fromOffset(8, 8)

    local title = createText(titleRow, cfg.Title or "Section", 13, t.Text, Enum.Font.GothamBold)
    title.Position = UDim2.fromOffset(42, 0)
    title.Size = UDim2.new(1, -42, 0, 19)
    local desc = createText(titleRow, cfg.Description or "", 10, t.Muted, Enum.Font.Gotham)
    desc.Position = UDim2.fromOffset(42, 19)
    desc.Size = UDim2.new(1, -42, 0, 19)
    desc.TextWrapped = true

    local controls = Instance.new("Frame")
    controls.Name = "Controls"
    controls.BackgroundTransparency = 1
    controls.Position = UDim2.fromOffset(12, 58)
    controls.Size = UDim2.new(1, -24, 0, 0)
    controls.AutomaticSize = Enum.AutomaticSize.Y
    controls.Parent = card

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 7)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = controls

    local bottom = Instance.new("Frame")
    bottom.BackgroundTransparency = 1
    bottom.Size = UDim2.new(1, -24, 0, 10)
    bottom.Position = UDim2.fromOffset(12, 58)
    bottom.Parent = card
    controls:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        bottom.Position = UDim2.fromOffset(12, 58 + controls.AbsoluteSize.Y)
    end)

    local section = setmetatable({
        _tab = self,
        _card = card,
        _title = title,
        _controls = controls,
        _cfg = cfg,
    }, Section)
    self._currentSection = section
    return section
end

function Tab:_current()
    return self._currentSection or self:_default()
end

function Tab:CreateButton(cfg) return self:_current():CreateButton(cfg) end
function Tab:CreateToggle(cfg) return self:_current():CreateToggle(cfg) end
function Tab:CreateDropdown(cfg) return self:_current():CreateDropdown(cfg) end
function Tab:CreateMultiDropdown(cfg) return self:_current():CreateMultiDropdown(cfg) end
function Tab:CreateTextbox(cfg) return self:_current():CreateTextbox(cfg) end
function Tab:CreateLabel(cfg) return self:_current():CreateLabel(cfg) end

function Control:GetValue()
    return self._value
end
function Control:SetValue(value, silent)
    self._value = value
    if self._setVisual then pcall(self._setVisual, value) end
    if not silent then canCallback(self._callback, value) end
end
Control.Set = Control.SetValue
function Control:SetDisabled(disabled)
    self._disabled = disabled == true
    if self._row then
        self._row.Active = not self._disabled
        self._row.AutoButtonColor = false
    end
end

local function controlRow(section, height)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, height or 42)
    row.BackgroundColor3 = theme().CardRaised
    row.BorderSizePixel = 0
    corner(row, 11)
    row.Parent = section._controls
    stroke(row, theme().BorderSoft, 0.12, 1)
    return row
end

local function addControlTitle(row, cfg, icon)
    local iconBox = Instance.new("Frame")
    iconBox.Size = UDim2.fromOffset(28, 28)
    iconBox.Position = UDim2.fromOffset(8, 7)
    iconBox.BackgroundTransparency = 1
    iconBox.Parent = row
    local im = addIcon(iconBox, icon or cfg.Icon or "circle", 16, theme().Muted, 4)
    im.Position = UDim2.fromOffset(6, 6)

    local name = createText(row, cfg.Name or cfg.Title or "Control", 12, theme().Text, Enum.Font.GothamMedium)
    name.Position = UDim2.fromOffset(43, 0)
    name.Size = UDim2.new(1, -120, 1, 0)
    name.TextTruncate = Enum.TextTruncate.AtEnd
    return name
end

function Section:CreateToggle(cfg)
    cfg = cfg or {}
    local row = controlRow(self, 44)
    addControlTitle(row, cfg, cfg.Icon or "check")

    local switch = makeButton(row, UDim2.fromOffset(42, 24), theme().Border, 12)
    switch.Position = UDim2.new(1, -52, 0.5, -12)
    switch.Parent = row

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(18, 18)
    knob.Position = UDim2.fromOffset(3, 3)
    knob.BackgroundColor3 = Color3.fromRGB(185, 191, 202)
    knob.BorderSizePixel = 0
    corner(knob, 9)
    knob.Parent = switch

    local c = setmetatable({
        _row = row,
        _switch = switch,
        _knob = knob,
        _value = cfg.Default == true,
        _callback = cfg.Callback,
    }, Control)

    c._setVisual = function(value)
        local on = value == true
        switch.BackgroundColor3 = on and theme().Accent or theme().Border
        knob.BackgroundColor3 = on and Color3.new(1, 1, 1) or Color3.fromRGB(185, 191, 202)
        tween(knob, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = on and UDim2.new(1, -21, 0, 3) or UDim2.fromOffset(3, 3)
        })
    end
    c._setVisual(c._value)
    row.InputBegan:Connect(function(input)
        if c._disabled then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then c:SetValue(not c._value) end
    end)
    return c
end

function Section:CreateButton(cfg)
    cfg = cfg or {}
    local row = controlRow(self, 44)
    local title = addControlTitle(row, cfg, cfg.Icon or "play")
    title.Size = UDim2.new(1, -70, 1, 0)
    local arrow = addIcon(row, cfg.IconRight or "arrow-up-right", 14, theme().Muted, 4)
    arrow.Position = UDim2.new(1, -28, 0.5, -7)

    row.InputBegan:Connect(function(input)
        if cfg.Disabled then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            tween(row, TweenInfo.new(0.08), {BackgroundColor3 = theme().Pressed})
            task.delay(0.09, function() if row.Parent then tween(row, TweenInfo.new(0.12), {BackgroundColor3 = theme().CardRaised}) end end)
            canCallback(cfg.Callback)
        end
    end)
    return setmetatable({_row = row, _callback = cfg.Callback, _value = false}, Control)
end

local function dropdownPopup(control, multiple)
    local row = control._row
    local window = control._window
    local existing = control._popup
    if existing then existing:Destroy(); control._popup = nil; return end

    local t = theme()
    local popup = Instance.new("Frame")
    popup.BackgroundColor3 = t.CardRaised
    popup.BorderSizePixel = 0
    popup.Size = UDim2.fromOffset(math.max(row.AbsoluteSize.X, 220), math.min(220, 32 + (#control._options * 30)))
    popup.ZIndex = 100
    corner(popup, 12)
    stroke(popup, t.Border, 0.02, 1)
    popup.Parent = window._gui

    local abs = row.AbsolutePosition
    local shellPos = window._shell.AbsolutePosition
    popup.Position = UDim2.fromOffset(abs.X - shellPos.X, abs.Y - shellPos.Y + row.AbsoluteSize.Y + 5)

    local sc = Instance.new("ScrollingFrame")
    sc.BackgroundTransparency = 1
    sc.BorderSizePixel = 0
    sc.Position = UDim2.fromOffset(6, 6)
    sc.Size = UDim2.new(1, -12, 1, -12)
    sc.ScrollBarThickness = 3
    sc.CanvasSize = UDim2.new()
    sc.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sc.ZIndex = 101
    sc.Parent = popup
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 4)
    layout.Parent = sc

    for _, option in ipairs(control._options) do
        local choice = makeButton(sc, UDim2.new(1, 0, 0, 30), t.Card, 8)
        choice.ZIndex = 102
        local checked = false
        if multiple then
            checked = control._selected[option] == true
        else
            checked = control._value == option
        end
        local txt = createText(choice, tostring(option), 11, checked and t.Accent or t.Text, Enum.Font.GothamMedium)
        txt.Position = UDim2.fromOffset(10, 0)
        txt.Size = UDim2.new(1, -20, 1, 0)
        txt.ZIndex = 103
        choice.Activated:Connect(function()
            if multiple then
                control._selected[option] = not control._selected[option]
                local vals = {}
                for _, o in ipairs(control._options) do if control._selected[o] then table.insert(vals, o) end end
                control._value = vals
                txt.TextColor3 = control._selected[option] and t.Accent or t.Text
                canCallback(control._callback, vals)
            else
                control._value = option
                canCallback(control._callback, option)
                popup:Destroy(); control._popup = nil
                if control._valueLabel then control._valueLabel.Text = tostring(option) end
            end
        end)
    end

    control._popup = popup
end

function Section:_createDropdownBase(cfg, multiple)
    cfg = cfg or {}
    local row = controlRow(self, 48)
    addControlTitle(row, cfg, cfg.Icon or (multiple and "shapes" or "chevron-down"))
    local valueLabel = createText(row, "", 10, theme().Muted, Enum.Font.Gotham)
    valueLabel.Position = UDim2.new(0, 43, 0, 25)
    valueLabel.Size = UDim2.new(1, -62, 0, 16)
    valueLabel.TextTruncate = Enum.TextTruncate.AtEnd
    valueLabel.ZIndex = 12

    local button = makeButton(row, UDim2.new(1, -52, 1, -10), theme().Hover, 9)
    button.Position = UDim2.fromOffset(43, 5)
    button.ZIndex = 10
    button.Text = ""
    -- overlay button covers the content area while leaving the left icon area visible
    local arrow = addIcon(row, multiple and "chevron-down" or "chevron-down", 14, theme().Secondary, 13)
    arrow.Position = UDim2.new(1, -27, 0.5, -7)

    local options = cfg.Options or {}
    local c = setmetatable({
        _row = row,
        _window = self._tab._window,
        _options = options,
        _callback = cfg.Callback,
        _selected = {},
        _value = cfg.Default,
        _valueLabel = valueLabel,
    }, Control)

    if multiple then
        local defaults = type(cfg.Default) == "table" and cfg.Default or {}
        for _, v in ipairs(defaults) do c._selected[v] = true end
        local text = {}
        for _, v in ipairs(options) do if c._selected[v] then table.insert(text, tostring(v)) end end
        valueLabel.Text = #text > 0 and table.concat(text, ", ") or (cfg.Placeholder or "Select options")
    else
        valueLabel.Text = cfg.Default ~= nil and tostring(cfg.Default) or (cfg.Placeholder or "Select an option")
    end

    button.Activated:Connect(function()
        if cfg.Disabled then return end
        dropdownPopup(c, multiple)
    end)
    return c
end

function Section:CreateDropdown(cfg) return self:_createDropdownBase(cfg, false) end
function Section:CreateMultiDropdown(cfg) return self:_createDropdownBase(cfg, true) end

function Section:CreateTextbox(cfg)
    cfg = cfg or {}
    local row = controlRow(self, 48)
    local title = addControlTitle(row, cfg, cfg.Icon or "search")
    title.Position = UDim2.fromOffset(43, 0)
    title.Size = UDim2.fromOffset(92, 48)

    local box = Instance.new("TextBox")
    box.BackgroundColor3 = theme().Hover
    box.BorderSizePixel = 0
    box.TextColor3 = theme().Text
    box.PlaceholderColor3 = theme().Muted
    box.TextSize = 11
    box.Font = Enum.Font.Gotham
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.ClearTextOnFocus = false
    box.Text = cfg.Default ~= nil and tostring(cfg.Default) or ""
    box.PlaceholderText = cfg.Placeholder or "Enter value..."
    box.Size = UDim2.new(1, -148, 0, 32)
    box.Position = UDim2.new(0, 140, 0.5, -16)
    corner(box, 9)
    padding(box, 9, 8, 0, 0)
    box.Parent = row

    local c = setmetatable({_row = row, _box = box, _value = box.Text, _callback = cfg.Callback}, Control)
    box.FocusLost:Connect(function()
        c._value = box.Text
        canCallback(c._callback, box.Text)
    end)
    c._setVisual = function(value)
        box.Text = tostring(value or "")
        c._value = box.Text
    end
    return c
end
function Section:CreateLabel(cfg)
    cfg = type(cfg) == "table" and cfg or {Text = tostring(cfg or "")}
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 30)
    row.BackgroundTransparency = 1
    row.Parent = self._controls
    local txt = createText(row, cfg.Text or cfg.Name or "", cfg.TextSize or 11, cfg.TextColor or theme().Secondary, Enum.Font.Gotham)
    txt.Size = UDim2.fromScale(1, 1)
    txt.TextWrapped = true
    return {Instance = row, Label = txt}
end

-- Compatibility aliases commonly used by older hub code.
Section.CreateInput = Section.CreateTextbox
Section.CreateTextbox = Section.CreateTextbox

function KhfreshLib:CreateIcon(parent, name, size, color, z)
    assert(parent, "CreateIcon requires a parent")
    return addIcon(parent, name, size or 18, color or theme().Secondary, z or 1)
end

return KhfreshLib
