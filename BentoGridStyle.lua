
--// UI library rebuilt specifically for Khfresh Hub.
--// The old UI source is used only as an API/layout reference.
--// No old hub features/assets are embedded here.

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

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
    _version = "4.0.0-khfresh-hub",
    _windows = {},
    _notifyGui = nil,
    _iconPack = nil,
    _iconReady = false,
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
-- LUCIDE API
--==============================================================
-- Footagesus Icons exposes the Lucide catalog through Icon()/GetIcon().
-- This is loaded at runtime so the library can use the large Lucide catalog
-- rather than embedding a small hard-coded icon table.
local function loadLucide()
    if UI._iconReady then return UI._iconPack end
    local urls = {
        "https://raw.githubusercontent.com/Footagesus/Icons/main/Main-v2.lua",
        "https://raw.githubusercontent.com/Footagesus/Icons/main/Main.lua",
    }
    for _, url in ipairs(urls) do
        local ok, body = pcall(function()
            if game.HttpGetAsync then return game:HttpGetAsync(url) end
            return game:HttpGet(url)
        end)
        if ok and type(body) == "string" and #body > 1000 and type(loadstring) == "function" then
            local okChunk, fn = pcall(loadstring, body, "@KhfreshLucide")
            if okChunk and type(fn) == "function" then
                local okRun, pack = pcall(fn)
                if okRun and type(pack) == "table" then
                    pcall(function() if pack.SetIconsType then pack.SetIconsType("lucide") end end)
                    UI._iconPack = pack
                    UI._iconReady = true
                    return pack
                end
            end
        end
    end
    return nil
end

task.spawn(loadLucide)

local function iconResult(name)
    local pack = UI._iconPack or loadLucide()
    if not pack then return nil end
    local candidates = { tostring(name or "circle"), tostring(name or "circle"):lower() }
    for _, n in ipairs(candidates) do
        local ok, result = pcall(function()
            if pack.GetIcon then return pack.GetIcon(n) end
            if pack.Icon then return pack.Icon(n, "lucide", false) end
        end)
        if ok and result then return result end
    end
    return nil
end

local function drawLine(parent, x1, y1, x2, y2, color, thickness, z)
    local dx, dy = x2 - x1, y2 - y1
    local length = math.sqrt(dx * dx + dy * dy)
    local midX, midY = (x1 + x2) / 2, (y1 + y2) / 2
    local line = make("Frame", {
        BorderSizePixel = 0, BackgroundColor3 = color or C.secondary,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, midX, 0, midY),
        Size = UDim2.new(0, length, 0, thickness or 2),
        Rotation = math.deg(math.atan2(dy, dx)),
        ZIndex = z or 5,
    }, parent)
    return line
end

-- Vector fallbacks for controls that appear most frequently in this hub.
-- The Lucide API remains the first choice; this fallback makes core controls
-- readable even when an executor cannot load the remote icon pack.
local function drawVectorFallback(parent, name, size, color, z)
    local holder = make("Frame", {
        BackgroundTransparency = 1,
        Size = size or UDim2.fromOffset(20, 20),
        ZIndex = z or 5,
    }, parent)
    local w, h = 20, 20
    local n = tostring(name or "circle"):lower()
    if n == "x" or n == "close" then
        drawLine(holder, 5, 5, 15, 15, color, 2, z)
        drawLine(holder, 15, 5, 5, 15, color, 2, z)
    elseif n == "minus" then
        drawLine(holder, 4, 10, 16, 10, color, 2, z)
    elseif n == "plus" then
        drawLine(holder, 4, 10, 16, 10, color, 2, z)
        drawLine(holder, 10, 4, 10, 16, color, 2, z)
    elseif n == "chevron-down" then
        drawLine(holder, 5, 7, 10, 12, color, 2, z)
        drawLine(holder, 10, 12, 15, 7, color, 2, z)
    elseif n == "chevron-right" then
        drawLine(holder, 7, 5, 13, 10, color, 2, z)
        drawLine(holder, 13, 10, 7, 15, color, 2, z)
    elseif n == "search" then
        local c = make("Frame", {BackgroundTransparency=1, Position=UDim2.fromOffset(3,3), Size=UDim2.fromOffset(12,12), ZIndex=z or 5}, holder)
        corner(c, 99); outline(c,color,0,2)
        drawLine(holder, 13, 13, 18, 18, color, 2, z)
    elseif n == "check" or n == "circle-check" then
        local c = make("Frame", {BackgroundTransparency=1, Position=UDim2.fromOffset(2,2), Size=UDim2.fromOffset(16,16), ZIndex=z or 5}, holder)
        corner(c,99); outline(c,color,0,2)
        drawLine(holder, 5, 10, 9, 14, color, 2, z)
        drawLine(holder, 9, 14, 15, 7, color, 2, z)
    elseif n == "play" then
        local tri = make("TextLabel", {BackgroundTransparency=1, Size=UDim2.fromScale(1,1), Text="▶", TextSize=13, Font=Enum.Font.GothamBold, TextColor3=color, ZIndex=z or 5}, holder)
        tri.TextXAlignment = Enum.TextXAlignment.Center
        tri.TextYAlignment = Enum.TextYAlignment.Center
    elseif n == "settings" then
        local c = make("Frame", {BackgroundTransparency=1, Position=UDim2.fromOffset(4,4), Size=UDim2.fromOffset(12,12), ZIndex=z or 5}, holder)
        corner(c,99); outline(c,color,0,2)
        local dot = make("Frame", {BackgroundColor3=color, BorderSizePixel=0, Position=UDim2.fromOffset(7,7), Size=UDim2.fromOffset(6,6), ZIndex=(z or 5)+1}, holder)
        corner(dot,99)
        for _, seg in ipairs({{10,1,2,5},{10,14,2,5},{1,9,5,2},{14,9,5,2}}) do drawLine(holder, seg[1],seg[2],seg[1]+seg[3],seg[2]+seg[4],color,2,z) end
    elseif n == "volleyball" then
        -- Procedural volleyball: circle + curved seams.
        local ball = make("Frame", {BackgroundTransparency=1, Position=UDim2.fromOffset(2,2), Size=UDim2.fromOffset(16,16), ZIndex=z or 5}, holder)
        corner(ball,99); outline(ball,color,0,1.8)
        drawLine(holder, 5, 3, 7, 17, color, 1.6, z)
        drawLine(holder, 3, 6, 17, 13, color, 1.6, z)
        drawLine(holder, 4, 16, 16, 4, color, 1.6, z)
    else
        local c = make("Frame", {BackgroundTransparency=1, Position=UDim2.fromOffset(3,3), Size=UDim2.fromOffset(14,14), ZIndex=z or 5}, holder)
        corner(c,99); outline(c,color,0,1.7)
        local d = make("Frame", {BackgroundColor3=color, BorderSizePixel=0, Position=UDim2.fromOffset(6,6), Size=UDim2.fromOffset(6,6), ZIndex=(z or 5)+1}, holder)
        corner(d,99)
    end
    return holder
end

local function renderIcon(parent, iconName, position, size, color, z)
    local holder = make("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = position or UDim2.fromOffset(0, 0),
        Size = size or UDim2.fromOffset(20, 20),
        ZIndex = z or 5,
    }, parent)

    local result = iconResult(iconName)
    if result then
        local imageId = result[1]
        local meta = result[2]
        if type(imageId) == "string" then
            local img = make("ImageLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Image = imageId,
                ImageColor3 = color or C.secondary,
                ScaleType = Enum.ScaleType.Fit,
                ZIndex = z or 5,
            }, holder)
            if type(meta) == "table" then
                if meta.ImageRectSize then img.ImageRectSize = meta.ImageRectSize end
                if meta.ImageRectPosition then img.ImageRectOffset = meta.ImageRectPosition end
            end
            if meta and type(meta.Parts) == "table" then
                for index, part in ipairs(meta.Parts) do
                    local partResult = iconResult(part)
                    if partResult then
                        make("ImageLabel", {
                            BackgroundTransparency = 1,
                            Size = UDim2.fromScale(1, 1),
                            Image = partResult[1],
                            ImageRectSize = partResult[2] and partResult[2].ImageRectSize or Vector2.zero,
                            ImageRectOffset = partResult[2] and partResult[2].ImageRectPosition or Vector2.zero,
                            ImageColor3 = color or C.secondary,
                            ZIndex = (z or 5) + index,
                        }, holder)
                    end
                end
            end
            return holder
        end
    end

    holder:ClearAllChildren()
    local fallback = drawVectorFallback(holder, iconName, size, color, z)
    fallback.Position = UDim2.fromScale(0, 0)
    return holder
end

-- Retry icons after async pack initialization.
task.spawn(function()
    for _ = 1, 30 do
        task.wait(0.2)
        if UI._iconReady then break end
        pcall(loadLucide)
    end
end)

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
    local w = math.clamp(requested and requested.X.Offset or 760, 520, math.max(520, vp.X - 24))
    local h = math.clamp(requested and requested.Y.Offset or 540, 420, math.max(420, vp.Y - 24))
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
            win._shell.Size = UDim2.new(1, -16, 1, -16)
            win._shell.Position = UDim2.fromScale(0.5, 0.5)
            win._rail.Size = UDim2.new(0, 66, 1, -win._topHeight)
            win._content.Position = UDim2.fromOffset(66, win._topHeight)
            win._content.Size = UDim2.new(1, -66, 1, -win._topHeight)
            if win._logo then
                win._logo.Size = UDim2.fromOffset(38, 38)
                win._logo.Position = UDim2.fromOffset(10, 8)
            end
            if win._brandText then win._brandText.Visible = false end
            if win._authorText then win._authorText.Visible = false end
            for _, tab in ipairs(win._tabs) do
                if tab._label then tab._label.Visible = false end
                if tab._icon then tab._icon.Position = UDim2.new(0.5, -10, 0.5, -10) end
            end
        else
            local requested = win._requestedSize or UDim2.fromOffset(760, 540)
            win._shell.Size = computeSize(requested)
            win._rail.Size = UDim2.fromOffset(win._railWidth, 1)
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
    win._top.InputBegan:Connect(startMove)

    table.insert(win._connections, UserInputService.InputChanged:Connect(function(input)
        if win._moving and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - win._moveStart
            shell.Position = UDim2.new(win._moveBase.X.Scale, win._moveBase.X.Offset + delta.X, win._moveBase.Y.Scale, win._moveBase.Y.Offset + delta.Y)
        end
        if win._resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - win._resizeStart
            local old = win._resizeBase
            local vp = viewport()
            local w = math.clamp(old.X.Offset + delta.X, 520, math.max(520, vp.X - 24))
            local h = math.clamp(old.Y.Offset + delta.Y, 420, math.max(420, vp.Y - 24))
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
function UI:GetIcon(name)
    return iconResult(name) ~= nil
end
function UI:GetIconPack() return self._iconPack end
function UI:IsMobile() return viewport().X < 700 or UserInputService.TouchEnabled and viewport().X < 850 end

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
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
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
        local tint = make("Frame", {BackgroundColor3=C.canvas, BackgroundTransparency=0.55, Size=UDim2.fromScale(1,1), BorderSizePixel=0, ZIndex=1}, shell)
        win._backgroundTint = tint
    end

    local top = make("Frame", {
        Name="TopBar", BackgroundColor3=C.header, BorderSizePixel=0,
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
        Name="Rail", BackgroundColor3=C.rail, BorderSizePixel=0,
        Position=UDim2.fromOffset(0,82), Size=UDim2.new(0,178,1,-82),
        CanvasSize=UDim2.new(), AutomaticCanvasSize=Enum.AutomaticSize.Y,
        ScrollBarThickness=2, ScrollBarImageColor3=C.muted, ScrollingDirection=Enum.ScrollingDirection.Y,
        ZIndex=14,
    }, shell)
    list(rail,7); padding(rail,10,10,12,36); win._rail=rail
    local divider=make("Frame",{BackgroundColor3=C.lineSoft,BorderSizePixel=0,Position=UDim2.new(1,-1,0,0),Size=UDim2.new(0,1,1,0),ZIndex=15},rail)

    local content = make("Frame", {
        Name="Content", BackgroundColor3=C.canvas, BackgroundTransparency=0.12, BorderSizePixel=0,
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

    local page=make("ScrollingFrame",{Name="Page_"..cleanName(title),BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromScale(1,1),CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=4,ScrollBarImageColor3=C.muted,ScrollingDirection=Enum.ScrollingDirection.Y,Visible=false,ZIndex=11},self._content)
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
        if t._icon and t._icon:IsA("GuiObject") then
            local img=t._icon:FindFirstChildWhichIsA("ImageLabel",true)
            if img then img.ImageColor3=on and C.accent or C.muted end
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
    local sg=make("ScreenGui",{Name="KhfreshFloatingGui",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=2147483630,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},GuiParent)
    self._floatingGui=sg
    local btn=make("TextButton",{Text="",BackgroundColor3=C.shell,BorderSizePixel=0,Size=UDim2.fromOffset(58,58),Position=UDim2.new(0,16,0.5,-29),AutoButtonColor=false,Active=true,ZIndex=10},sg)
    corner(btn,19); outline(btn,C.line,0.2,1)
    renderIcon(btn,"volleyball",UDim2.fromOffset(14,14),UDim2.fromOffset(30,30),C.accent,12)
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
    if self._settingsBento then
        local side=section._side
        if side=="left" then section._parent=self._columns[1]
        elseif side=="right" then section._parent=self._columns[2]
        else
            self._settingsCounter += 1
            section._parent=self._columns[(((self._settingsCounter-1)%2)+1)]
        end
        section._frame.Parent=section._parent
    else
        section._frame.Parent=self._columns[1]
    end
    section._frame.LayoutOrder=#section._parent:GetChildren()
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
