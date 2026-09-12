-- Khfresh BentoGridStyle
-- Dedicated UI library for Khfresh Hub.
-- Visual direction: material-like dark surfaces, soft 18px corners, neutral iconography,
-- smooth state transitions, responsive desktop/mobile layout.
-- Icon bitmaps are independently rasterized for this library (48x48 alpha masks).
-- Khfresh BentoGridStyle v10
-- Dedicated UI layer for Khfresh Hub.
-- Built from scratch around the Hub API; the visual direction is only informed by
-- modern Material/Bento UI principles. No external icon pack or external image API.

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local AssetService = game:GetService("AssetService")

local LocalPlayer = Players.LocalPlayer

local function resolveGuiParent()
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

local GuiParent = resolveGuiParent()

local UI = {
    _windows = {},
    _version = "10.0.0-khfresh-bento",
    _notificationGui = nil,
}

local THEMES = {
    Bento = {
        canvas = Color3.fromRGB(16, 18, 22),
        shell = Color3.fromRGB(23, 26, 31),
        rail = Color3.fromRGB(19, 22, 27),
        header = Color3.fromRGB(27, 30, 36),
        raised = Color3.fromRGB(33, 37, 44),
        row = Color3.fromRGB(29, 33, 39),
        rowHover = Color3.fromRGB(36, 41, 48),
        rowPressed = Color3.fromRGB(43, 48, 56),
        line = Color3.fromRGB(72, 78, 88),
        lineSoft = Color3.fromRGB(51, 57, 66),
        text = Color3.fromRGB(240, 242, 246),
        secondary = Color3.fromRGB(182, 188, 198),
        muted = Color3.fromRGB(125, 133, 145),
        accent = Color3.fromRGB(211, 216, 224),
        accentSoft = Color3.fromRGB(62, 68, 77),
        success = Color3.fromRGB(160, 204, 174),
        danger = Color3.fromRGB(224, 145, 143),
        warning = Color3.fromRGB(218, 190, 126),
        whiteSoft = Color3.fromRGB(228, 231, 236),
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
    fast = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    hover = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    base = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    enter = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    exit = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
    pop = TweenInfo.new(0.30, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
}

local function make(className, props, parent)
    local obj = Instance.new(className)
    for k, v in pairs(props or {}) do
        pcall(function() obj[k] = v end)
    end
    obj.Parent = parent
    return obj
end

local function corner(parent, radius)
    return make("UICorner", {CornerRadius = UDim.new(0, radius or 12)}, parent)
end

local function stroke(parent, color, transparency, thickness)
    return make("UIStroke", {
        Color = color or C.line,
        Transparency = transparency == nil and 0.40 or transparency,
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

local function label(parent, text, size, color, bold)
    return make("TextLabel", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = tostring(text or ""),
        TextColor3 = color or C.text,
        TextSize = size or 13,
        Font = bold and Enum.Font.GothamMedium or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 20,
    }, parent)
end

local function tween(obj, info, props)
    if not obj or not obj.Parent then return end
    local ok, animation = pcall(function()
        return TweenService:Create(obj, info or Motion.base, props)
    end)
    if ok and animation then animation:Play(); return animation end
end

local function bindActivated(gui, callback)
    if not gui or type(callback) ~= "function" then return end
    if gui:IsA("GuiButton") then
        gui.Activated:Connect(function() task.spawn(callback) end)
    else
        local hit = make("TextButton", {
            Text = "",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1),
            AutoButtonColor = false,
            ZIndex = 90,
        }, gui)
        hit.Activated:Connect(function() task.spawn(callback) end)
    end
end

local function viewportSize()
    local cam = workspace.CurrentCamera
    return cam and cam.ViewportSize or Vector2.new(1280, 720)
end

local function isMobileViewport()
    local vp = viewportSize()
    return vp.X <= 740 or (UserInputService.TouchEnabled and vp.X <= 920)
end

local function safeClamp(n, a, b)
    if b < a then return a end
    return math.clamp(n, a, b)
end

-- ============================================================
-- Procedural anti-aliased icon rasterizer
-- ============================================================
-- Icons are described as geometry instead of copied icon/image data. The geometry is
-- sampled at 4x4 per output pixel and written into an EditableImage alpha channel.

local ICONS = {}

local function seg(x1, y1, x2, y2, w)
    return {kind = "seg", x1=x1, y1=y1, x2=x2, y2=y2, w=w or 2.2}
end
local function circ(cx, cy, r, fill, w)
    return {kind = "circ", cx=cx, cy=cy, r=r, fill=fill ~= false, w=w or 2.2}
end
local function rect(x1, y1, x2, y2, fill, w, radius)
    return {kind = "rect", x1=x1, y1=y1, x2=x2, y2=y2, fill=fill ~= false, w=w or 2.2, radius=radius or 2.0}
end

local function path(points, w, closed)
    local out = {}
    for i = 1, #points - 1 do
        out[#out+1] = seg(points[i][1], points[i][2], points[i+1][1], points[i+1][2], w)
    end
    if closed and #points > 2 then
        local a,b = points[#points], points[1]
        out[#out+1] = seg(a[1], a[2], b[1], b[2], w)
    end
    return out
end

ICONS["layout-dashboard"] = {
    rect(4,4,18,18,false,2.2,2), rect(26,4,44,18,false,2.2,2),
    rect(4,26,18,44,false,2.2,2), rect(26,26,44,44,false,2.2,2),
}
ICONS["house"] = {
    path({{6,22},{24,7},{42,22}},2.4), rect(10,21,38,43,false,2.4,2),
    seg(21,43,21,30,2.2), seg(27,43,27,30,2.2), seg(21,30,27,30,2.2),
}
ICONS["fishing-rod"] = {
    seg(10,10,34,34,2.2), seg(10,10,8,7,2.2), seg(34,34,40,34,2.2),
    path({{40,34},{41,39},{37,43},{34,41}},2.0), seg(34,34,34,39,1.7),
}
ICONS["fish"] = {
    path({{7,24},{15,14},{31,13},{41,24},{31,35},{15,34},{7,24}},2.2),
    path({{7,24},{2,18},{2,30},{7,24}},2.2), circ(30,20,1.8,true),
    seg(18,14,18,34,1.8),
}
ICONS["hand-heart"] = {
    path({{8,31},{12,21},{17,21},{19,17},{23,19},{28,17},{32,21},{34,30}},2.2),
    path({{17,11},{20,8},{24,11},{27,8},{30,11},{30,15},{24,21},{17,15},{17,11}},2.0),
    seg(8,31,34,31,2.0),
}
ICONS["flame"] = {
    path({{24,43},{15,38},{13,29},{18,22},{19,12},{24,18},{28,9},{35,20},{36,29},{33,38},{24,43}},2.3),
    path({{24,37},{20,34},{20,29},{24,24},{28,29},{28,34},{24,37}},1.9),
}
ICONS["fish-symbol"] = ICONS["fish"]
ICONS["gamepad-2"] = {
    rect(8,15,40,37,false,2.3,6),
    seg(14,26,22,26,2.2), seg(18,22,18,30,2.2),
    circ(32,25,2.2,false,2), circ(37,30,2.2,false,2),
}
ICONS["swords"] = {
    seg(10,38,36,12,2.2), seg(14,10,39,35,2.2),
    seg(31,11,36,12,2.2), seg(10,38,16,38,2.2),
    seg(14,10,10,10,2.2), seg(34,35,39,35,2.2),
}
ICONS["sword"] = { seg(11,39,37,13,2.3), seg(31,12,37,13,2.2), seg(11,39,18,39,2.2), seg(18,32,25,39,2.0) }
ICONS["badge-dollar-sign"] = { circ(24,24,17,false,2.3), seg(24,14,24,34,2.0), path({{30,18},{26,16},{21,17},{18,20},{19,23},{27,25},{29,28},{27,31},{22,32},{18,30}},2.0) }
ICONS["shopping-cart"] = { seg(7,10,12,10,2.2), seg(12,10,16,29,2.2), seg(16,29,35,29,2.2), seg(35,29,40,17,2.2), seg(14,16,39,16,2.2), circ(18,36,2.2,true), circ(34,36,2.2,true) }
ICONS["store"] = { rect(7,20,41,42,false,2.1,2), path({{5,20},{9,11},{39,11},{43,20},{43,23},{5,23},{5,20}},2.1), seg(14,23,14,42,1.8), seg(34,23,34,42,1.8) }
ICONS["repeat-2"] = { path({{9,18},{14,13},{38,13},{34,9}},2.2), path({{39,30},{34,35},{10,35},{14,39}},2.2), seg(38,13,39,19,1.8), seg(10,35,9,29,1.8) }
ICONS["scroll-text"] = { rect(11,6,37,42,false,2.2,3), seg(17,17,31,17,2.0), seg(17,24,31,24,2.0), seg(17,31,27,31,2.0) }
ICONS["trending-up"] = { path({{7,35},{18,25},{24,30},{39,14}},2.3), seg(31,14,39,14,2.2), seg(39,14,39,22,2.2) }
ICONS["map-pin"] = { path({{24,43},{14,29},{14,21},{17,14},{24,10},{31,14},{34,21},{34,29},{24,43}},2.2), circ(24,22,4,false,2.0) }
ICONS["ship"] = { path({{6,27},{11,37},{24,40},{37,37},{42,27},{35,29},{13,29},{6,27}},2.2), seg(14,27,14,12,2.0), seg(14,12,30,12,2.0), path({{17,13},{17,24},{30,24},{30,18}},2.0) }
ICONS["user-round"] = { circ(24,16,8,false,2.2), path({{10,42},{12,35},{18,31},{24,30},{30,31},{36,35},{38,42}},2.2) }
ICONS["users-round"] = { circ(18,18,6,false,2.0), circ(31,20,5,false,2.0), path({{8,40},{10,35},{15,31},{21,31},{25,34},{26,39}},2.0), path({{26,40},{29,35},{35,34},{40,37},{41,41}},2.0) }
ICONS["lock"] = { rect(12,21,36,40,false,2.2,3), path({{17,21},{17,15},{20,11},{24,10},{28,11},{31,15},{31,21}},2.2), circ(24,30,1.5,true) }
ICONS["shield-alert"] = { path({{24,7},{39,13},{37,29},{31,38},{24,43},{17,38},{11,29},{9,13},{24,7}},2.3), seg(24,16,24,27,2.2), circ(24,33,1.6,true) }
ICONS["scan-search"] = { path({{8,18},{8,11},{15,11}},2), path({{40,18},{40,11},{33,11}},2), path({{8,30},{8,37},{15,37}},2), path({{40,30},{40,37},{33,37}},2), circ(24,22,8,false,2.0), seg(30,28,38,36,2.2) }
ICONS["settings"] = { circ(24,24,8,false,2.2), circ(24,24,18,false,2.2), path({{24,4},{24,9},{28,10},{31,7},{35,11},{32,14},{34,18},{40,18},{40,23},{35,23},{34,28},{38,31},{34,35},{31,32},{27,34},{27,40},{22,40},{22,34},{18,33},{14,37},{10,33},{13,29},{10,25},{4,25},{4,20},{10,20},{12,16},{8,12},{12,8},{16,12},{20,10},{20,4}},1.6) }
ICONS["sliders-horizontal"] = { seg(8,14,40,14,2), circ(17,14,4,true,1.5), seg(8,24,40,24,2), circ(30,24,4,true,1.5), seg(8,34,40,34,2), circ(22,34,4,true,1.5) }
ICONS["hammer"] = { seg(12,38,31,19,2.4), rect(24,9,39,18,false,2.2,2), seg(30,18,37,25,2.2) }
ICONS["dices"] = { rect(7,9,28,30,false,2.2,3), rect(21,25,41,44,false,2.2,3), circ(13,15,1.5,true), circ(22,24,1.5,true), circ(31,34,1.5,true), circ(36,39,1.5,true) }
ICONS["refresh-cw"] = { path({{39,20},{35,13},{28,9},{19,9},{12,13},{8,20}},2.2), path({{9,28},{13,35},{20,39},{29,39},{36,35},{40,28}},2.2), seg(39,20,39,12,2.0), seg(39,20,31,20,2.0) }
ICONS["shuffle"] = { path({{8,14},{14,14},{34,34},{40,34}},2.2), path({{8,34},{14,34},{34,14},{40,14}},2.2), seg(34,34,34,29,1.8), seg(34,34,29,34,1.8), seg(34,14,34,19,1.8), seg(34,14,29,14,1.8) }
ICONS["cloud-sun"] = { circ(16,16,7,false,1.9), seg(16,5,16,9,1.6), seg(8,9,11,11,1.6), seg(24,9,21,11,1.6), path({{12,37},{17,31},{24,31},{29,27},{35,28},{40,34},{39,39},{12,39}},2.2) }
ICONS["play"] = { path({{17,10},{17,38},{38,24},{17,10}},2.3) }
ICONS["toggle-right"] = { rect(7,14,41,34,false,2.1,10), circ(31,24,6,true,1.4) }
ICONS["type"] = { seg(9,12,39,12,2.0), seg(24,12,24,39,2.0), seg(16,39,32,39,2.0) }
ICONS["list"] = { seg(17,13,40,13,2.0), seg(17,24,40,24,2.0), seg(17,35,40,35,2.0), rect(8,10,11,13,true,1.2,1), rect(8,21,11,24,true,1.2,1), rect(8,32,11,35,true,1.2,1) }
ICONS["palette"] = { path({{24,7},{13,9},{7,17},{7,27},{13,37},{23,42},{33,39},{40,32},{40,24},{34,15},{24,7}},2.2), circ(17,19,2,true), circ(25,15,2,true), circ(32,18,2,true), circ(35,26,2,true) }
ICONS["keyboard"] = { rect(5,12,43,36,false,2.2,3), seg(11,20,14,20,2), seg(18,20,21,20,2), seg(25,20,28,20,2), seg(32,20,35,20,2), seg(12,29,36,29,2) }
ICONS["info"] = { circ(24,24,17,false,2.2), seg(24,21,24,34,2.2), circ(24,15,1.5,true) }
ICONS["history"] = { path({{39,21},{36,15},{30,11},{23,10},{16,12},{11,17},{8,24},{10,31},{15,36},{22,38},{29,37}},2.2), path({{8,16},{8,25},{15,25}},2.0), seg(24,17,24,25,1.9), seg(24,25,30,28,1.9) }
ICONS["message-circle"] = { path({{8,24},{10,17},{16,11},{24,9},{32,11},{38,17},{40,24},{38,31},{32,37},{24,39},{16,37},{11,32},{8,24}},2.2), seg(15,24,33,24,1.8) }
ICONS["music-2"] = { seg(31,9,31,31,2.2), seg(31,9,40,7,2.2), circ(24,33,6,false,2.0), path({{30,28},{25,26},{21,29},{21,35}},2.0) }
ICONS["external-link"] = { rect(8,14,32,39,false,2.1,2), path({{24,8},{39,8},{39,23}},2.2), seg(39,8,23,24,2.2) }
ICONS["shield-check"] = { path({{24,7},{39,13},{37,28},{31,38},{24,43},{17,38},{11,28},{9,13},{24,7}},2.2), path({{17,25},{22,30},{32,20}},2.2) }
ICONS["code"] = { path({{19,14},{9,24},{19,34}},2.2), path({{29,14},{39,24},{29,34}},2.2) }
ICONS["languages"] = { circ(17,17,9,false,2.0), seg(11,33,40,33,2.0), seg(26,28,26,40,2.0), path({{22,28},{30,28},{35,24}},1.8) }
ICONS["copy"] = { rect(13,13,36,39,false,2.1,2), rect(8,8,31,34,false,2.1,2) }
ICONS["sparkles"] = { path({{24,6},{27,18},{39,21},{27,24},{24,38},{21,25},{9,21},{21,18},{24,6}},1.9), path({{39,32},{40,36},{44,37},{40,38},{39,43},{38,38},{34,37},{38,36},{39,32}},1.7) }
ICONS["panels-top-left"] = { rect(5,5,43,43,false,2.2,3), seg(24,5,24,43,1.9), seg(5,24,24,24,1.9) }
ICONS["shapes"] = { circ(15,17,7,false,2.0), rect(27,10,40,23,false,2.0,2), path({{16,31},{23,41},{9,41},{16,31}},2.0) }
ICONS["badge-check"] = { path({{24,6},{31,10},{38,10},{39,18},{43,24},{39,30},{38,38},{31,38},{24,42},{17,38},{10,38},{9,30},{5,24},{9,18},{10,10},{17,10},{24,6}},2.0), path({{15,25},{21,31},{34,18}},2.1) }
ICONS["chevron-down"] = { path({{12,18},{24,30},{36,18}},2.3) }
ICONS["chevron-right"] = { path({{20,12},{32,24},{20,36}},2.3) }
ICONS["x"] = { seg(14,14,34,34,2.4), seg(34,14,14,34,2.4) }
ICONS["minus"] = { seg(12,24,36,24,2.4) }
ICONS["plus"] = { seg(12,24,36,24,2.4), seg(24,12,24,36,2.4) }
ICONS["panel-left"] = { rect(7,8,41,40,false,2.1,3), seg(18,8,18,40,2.1) }
ICONS["volleyball"] = {
    circ(24,24,18,false,2.1),
    path({{13,10},{17,17},{16,24},{12,31},{7,33}},1.7),
    path({{31,9},{29,16},{32,22},{39,26},{42,24}},1.7),
    path({{12,38},{18,32},{25,31},{32,35},{34,41}},1.7),
    path({{9,22},{16,20},{21,15},{22,8}},1.6),
}

local ALIASES = {
    dashboard="layout-dashboard", home="house", fish="fish", fishing="fishing-rod",
    tune="sliders-horizontal", config="sliders-horizontal", settings="settings",
    close="x", remove="minus", add="plus", next="chevron-right", back="chevron-left",
    update="history", community="users-round", discord="message-circle", youtube="play",
    tiktok="music-2", copy="copy", link="external-link", info="info", warning="shield-alert",
    safety="shield-check", player="user-round", players="users-round", secret="lock",
    boss="swords", combat="sword", sell="badge-dollar-sign", buy="shopping-cart",
    shop="store", exchange="repeat-2", quest="scroll-text", quests="scroll-text",
    upgrade="trending-up", teleport="map-pin", boat="ship", weather="cloud-sun",
    auto="play", toggle="toggle-right", input="type", dropdown="list", color="palette",
    keybind="keyboard", language="languages", code="code", volleyball="volleyball",
    sparkle="sparkles", shapes="shapes", panels="panels-top-left",
}

local function resolveIconName(name)
    local key = string.lower(tostring(name or "info")):gsub("%s+", "-")
    return ALIASES[key] or key
end

local function distanceToSegment(px, py, x1, y1, x2, y2)
    local vx, vy = x2-x1, y2-y1
    local wx, wy = px-x1, py-y1
    local vv = vx*vx + vy*vy
    local t = vv > 0 and math.clamp((wx*vx + wy*vy)/vv, 0, 1) or 0
    local dx, dy = px-(x1+vx*t), py-(y1+vy*t)
    return math.sqrt(dx*dx + dy*dy)
end

local function primitiveCoverage(p, x, y)
    if p.kind == "seg" then
        local d = distanceToSegment(x,y,p.x1,p.y1,p.x2,p.y2)
        local edge = math.max(0.15, p.w * 0.5)
        return math.clamp(1 - (d-edge)*1.65, 0, 1)
    elseif p.kind == "circ" then
        local d = math.sqrt((x-p.cx)^2 + (y-p.cy)^2)
        if p.fill then
            return math.clamp(1 - (d-p.r+1.2)*1.25, 0, 1)
        end
        local edge = math.max(0.15, p.w*0.5)
        return math.clamp(1 - (math.abs(d-p.r)-edge)*1.7, 0, 1)
    elseif p.kind == "rect" then
        if p.fill then
            local dx = math.max(p.x1-x, 0, x-p.x2)
            local dy = math.max(p.y1-y, 0, y-p.y2)
            local d = math.sqrt(dx*dx+dy*dy)
            return math.clamp(1-d*1.8, 0, 1)
        end
        local outer = math.min(math.abs(x-p.x1),math.abs(x-p.x2),math.abs(y-p.y1),math.abs(y-p.y2))
        local inside = x >= p.x1 and x <= p.x2 and y >= p.y1 and y <= p.y2
        if not inside then return 0 end
        return math.clamp(1-(outer-p.w*0.5)*1.6,0,1)
    end
    return 0
end

local iconCache = {}
local function rasterIcon(name)
    local resolved = resolveIconName(name)
    if iconCache[resolved] then return iconCache[resolved] end
    local geometry = ICONS[resolved] or ICONS.info
    if not geometry or not buffer or not buffer.create or not AssetService.CreateEditableImage then
        return nil
    end
    local size = 64
    local ok, editable = pcall(function()
        return AssetService:CreateEditableImage({Size = Vector2.new(size,size)})
    end)
    if not ok or not editable then return nil end
    local px = buffer.create(size*size*4)
    local samples = {{-0.28,-0.28},{0.28,-0.28},{-0.28,0.28},{0.28,0.28}}
    for y=0,size-1 do
        for x=0,size-1 do
            local alpha = 0
            for _, s in ipairs(samples) do
                local sx = (x+0.5+s[1])*48/64 + 8
                local sy = (y+0.5+s[2])*48/64 + 8
                local cov = 0
                for _, p in ipairs(geometry) do
                    cov = math.max(cov, primitiveCoverage(p,sx,sy))
                end
                alpha = alpha + cov
            end
            alpha = math.floor(math.clamp(alpha/#samples,0,1)*255 + 0.5)
            local off=(y*size+x)*4
            buffer.writeu8(px,off,255)
            buffer.writeu8(px,off+1,255)
            buffer.writeu8(px,off+2,255)
            buffer.writeu8(px,off+3,alpha)
        end
    end
    local okWrite = pcall(function() editable:WritePixelsBuffer(Vector2.zero,Vector2.new(size,size),px) end)
    if not okWrite then return nil end
    iconCache[resolved]=editable
    return editable
end

local function fallbackIcon(parent, name, pos, size, color, z)
    local holder = make("Frame", {BackgroundTransparency=1,BorderSizePixel=0,Position=pos,Size=size,ZIndex=z or 20}, parent)
    local geometry = ICONS[resolveIconName(name)] or ICONS.info
    local sx, sy = size.X.Offset/48, size.Y.Offset/48
    local ox, oy = 4, 4
    for _, p in ipairs(geometry) do
        if p.kind == "seg" then
            local dx,dy=p.x2-p.x1,p.y2-p.y1
            local len=math.sqrt(dx*dx+dy*dy)
            local line=make("Frame",{BackgroundColor3=color or C.muted,BorderSizePixel=0,AnchorPoint=Vector2.new(0,0.5),Position=UDim2.fromOffset((p.x1-ox)*sx,(p.y1-oy)*sy),Size=UDim2.fromOffset(len*sx,math.max(1,p.w*sy)),Rotation=math.deg(math.atan2(dy,dx)),ZIndex=(z or 20)+1},holder)
            corner(line,math.max(1,p.w*sy/2))
        elseif p.kind == "circ" then
            local s=p.r*2*sx
            local c=make("Frame",{BackgroundColor3=p.fill and (color or C.muted) or Color3.new(1,1,1),BackgroundTransparency=p.fill and 0 or 1,BorderSizePixel=0,Position=UDim2.fromOffset((p.cx-p.r-ox)*sx,(p.cy-p.r-oy)*sy),Size=UDim2.fromOffset(s,s),ZIndex=(z or 20)+1},holder)
            corner(c,s/2)
            if not p.fill then stroke(c,color or C.muted,0,math.max(1,p.w*sy)) end
        elseif p.kind == "rect" then
            local w=(p.x2-p.x1)*sx; local h=(p.y2-p.y1)*sy
            local f=make("Frame",{BackgroundColor3=color or C.muted,BackgroundTransparency=p.fill and 0 or 1,BorderSizePixel=0,Position=UDim2.fromOffset((p.x1-ox)*sx,(p.y1-oy)*sy),Size=UDim2.fromOffset(w,h),ZIndex=(z or 20)+1},holder)
            corner(f,p.radius*sx)
            if not p.fill then stroke(f,color or C.muted,0,math.max(1,p.w*sy)) end
        end
    end
    return holder
end

local function icon(parent, name, pos, size, color, z)
    local resolved = resolveIconName(name)
    local img = make("ImageLabel", {
        Name="Icon_"..resolved, BackgroundTransparency=1, BorderSizePixel=0,
        Position=pos or UDim2.fromOffset(0,0), Size=size or UDim2.fromOffset(20,20),
        ImageColor3=color or C.muted, ImageTransparency=0, ScaleType=Enum.ScaleType.Fit,
        ZIndex=z or 20,
    }, parent)
    local editable = rasterIcon(resolved)
    if editable and Content and Content.fromObject then
        local ok = pcall(function() img.ImageContent = Content.fromObject(editable) end)
        if ok then return img end
    end
    img.Visible=false
    local fallback=fallbackIcon(parent,resolved,pos or UDim2.fromOffset(0,0),size or UDim2.fromOffset(20,20),color or C.muted,z or 20)
    return fallback
end

local function tintIcon(img,color)
    if img and img:IsA("ImageLabel") then img.ImageColor3=color end
end

-- ============================================================
-- Layout
-- ============================================================

local Window = {}; Window.__index = Window
local Tab = {}; Tab.__index = Tab
local Section = {}; Section.__index = Section

local function listLayout(parent, gap)
    return make("UIListLayout", {
        Padding=UDim.new(0,gap or 8),
        FillDirection=Enum.FillDirection.Vertical,
        SortOrder=Enum.SortOrder.LayoutOrder,
        HorizontalAlignment=Enum.HorizontalAlignment.Left,
    }, parent)
end

local function updateScrollCanvas(scroll, host)
    if not scroll or not host then return end
    task.defer(function()
        if scroll.Parent and host.Parent then
            local h=host.AbsoluteSize.Y
            local layout=host:FindFirstChildOfClass("UIListLayout")
            if layout then h=layout.AbsoluteContentSize.Y end
            scroll.CanvasSize=UDim2.new(0,0,0,h+28)
        end
    end)
end

local function refreshSection(section)
    if not section or not section._frame or not section._body then return end
    task.defer(function()
        if not section._frame.Parent then return end
        local layout=section._body:FindFirstChildOfClass("UIListLayout")
        local bodyH=layout and layout.AbsoluteContentSize.Y or section._body.AbsoluteSize.Y
        local extra=section._settings and 14 or 6
        section._body.Size=UDim2.new(1,0,0,math.max(bodyH,1))
        section._frame.Size=UDim2.new(1,0,0,31+bodyH+extra)
        local parent=section._tab
        if parent then updateScrollCanvas(parent._scroll,parent._settings and parent._settingsHost or parent._listHost) end
    end)
end

function Section:_addRow(name,height)
    local row=make("Frame",{
        Name="Row_"..tostring(name or "Control"):gsub("[^%w_]+","_"),
        BackgroundColor3=C.row,
        BorderSizePixel=0,
        Size=UDim2.new(1,0,0,height or 42),
        LayoutOrder=self._tab:_nextOrder(),
        ClipsDescendants=false,
        ZIndex=20,
    },self._body)
    corner(row,13)
    stroke(row,C.lineSoft,0.40,1)
    local hover=make("Frame",{BackgroundColor3=C.whiteSoft,BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromScale(1,1),ZIndex=21},row)
    corner(hover,13)
    local hit=make("TextButton",{Text="",BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromScale(1,1),AutoButtonColor=false,ZIndex=80},row)
    hit.MouseEnter:Connect(function() tween(hover,Motion.hover,{BackgroundTransparency=0.96}) end)
    hit.MouseLeave:Connect(function() tween(hover,Motion.hover,{BackgroundTransparency=1}) end)
    return row, hit
end

function Tab:_nextOrder()
    self._order=self._order+1
    return self._order
end

function Tab:_isSettingsMode()
    return self._settings == true
end

function Tab:_contentParent()
    if self._settings then return nil end
    return self._listHost
end

function Tab:_refreshLayout()
    if self._settings then
        task.defer(function()
            local lh=self._leftLayout and self._leftLayout.AbsoluteContentSize.Y or 0
            local rh=self._rightLayout and self._rightLayout.AbsoluteContentSize.Y or 0
            local hostH=math.max(lh,rh,1)
            if self._settingsHost then
                self._settingsHost.Size=UDim2.new(1,0,0,hostH)
                updateScrollCanvas(self._scroll,self._settingsHost)
            end
        end)
    else
        updateScrollCanvas(self._scroll,self._listHost)
    end
end

function Tab:_reflowSettings()
    if not self._settings then return end
    local mobile=isMobileViewport()
    self._rightColumn.Visible=not mobile
    local list=self._settingsSections
    for i,section in ipairs(list) do
        local target
        if mobile then target=self._leftColumn
        elseif section._side=="Right" then target=self._rightColumn
        elseif section._side=="Left" then target=self._leftColumn
        else target=(i%2==1) and self._leftColumn or self._rightColumn end
        if section._frame.Parent~=target then section._frame.Parent=target end
    end
    self:_refreshLayout()
end

function UI:SetTheme(name)
    applyTheme(name)
    for _,win in ipairs(self._windows) do pcall(function() win:ApplyTheme() end) end
end
function UI:GetTheme() return currentTheme end

function UI:Notify(config)
    config=config or {}
    local root=self._notificationGui
    if not root or not root.Parent then
        root=make("ScreenGui",{Name="KhfreshNotify",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=2147483000,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},GuiParent)
        self._notificationGui=root
        local host=make("Frame",{BackgroundTransparency=1,Size=UDim2.fromScale(1,1),BorderSizePixel=0},root)
        local layout=listLayout(host,8)
        layout.HorizontalAlignment=Enum.HorizontalAlignment.Right
        layout.VerticalAlignment=Enum.VerticalAlignment.Bottom
        padding(host,0,14,0,14)
        self._notificationHost=host
    end
    local card=make("CanvasGroup",{BackgroundColor3=C.header,BorderSizePixel=0,Size=UDim2.fromOffset(304,66),GroupTransparency=1,LayoutOrder=-math.floor(os.clock()*100)},self._notificationHost)
    corner(card,15); stroke(card,C.lineSoft,0.26,1)
    icon(card,config.Icon or "info",UDim2.fromOffset(13,20),UDim2.fromOffset(24,24),C.muted,30)
    local t=label(card,config.Title or "Khfresh",13,C.text,true); t.Position=UDim2.fromOffset(48,9); t.Size=UDim2.new(1,-60,0,20)
    local d=label(card,config.Content or config.Message or "",11,C.secondary,false); d.Position=UDim2.fromOffset(48,30); d.Size=UDim2.new(1,-60,0,28); d.TextWrapped=true
    tween(card,Motion.pop,{GroupTransparency=0})
    task.delay(tonumber(config.Duration) or 3,function()
        if card.Parent then tween(card,Motion.exit,{GroupTransparency=1}); task.delay(0.20,function() pcall(function() card:Destroy() end) end) end
    end)
end

function UI:CreateWindow(config)
    config=config or {}
    applyTheme(config.Theme or "Bento")
    for _,old in ipairs(self._windows) do pcall(function() old:Destroy() end) end
    self._windows={}

    local vp=viewportSize()
    local requested=config.Size or UDim2.fromOffset(760,540)
    local initialW=math.clamp(requested.X.Offset or 760,520,900)
    local initialH=math.clamp(requested.Y.Offset or 540,420,760)
    local mobile=isMobileViewport()
    if mobile then
        initialW=math.min(initialW,math.max(330,vp.X-10))
        initialH=math.min(initialH,math.max(400,vp.Y-12))
    end

    local sg=make("ScreenGui",{Name="KhfreshPanel",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=2147483645,ZIndexBehavior=Enum.ZIndexBehavior.Global},GuiParent)
    pcall(function() if syn and syn.protect_gui then syn.protect_gui(sg) end end)
    local shell=make("CanvasGroup",{Name="Panel",BackgroundColor3=C.shell,BorderSizePixel=0,AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(initialW,initialH),GroupTransparency=1,ClipsDescendants=true,ZIndex=10},sg)
    corner(shell,20); stroke(shell,C.line,0.18,1)

    local bg
    if type(config.Background)=="string" and config.Background~="" then
        bg=make("ImageLabel",{Name="Background",BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromScale(1,1),Image=config.Background,ImageTransparency=tonumber(config.BackgroundImageTransparency) or 0.58,ScaleType=Enum.ScaleType.Crop,ZIndex=11},shell)
    end
    local shade=make("Frame",{Name="BackgroundShade",BackgroundColor3=C.canvas,BackgroundTransparency=0.78,BorderSizePixel=0,Size=UDim2.fromScale(1,1),ZIndex=12},shell)

    local topH=68
    local bottomH=22
    local railW=mobile and 68 or 190

    local rail=make("Frame",{Name="Rail",BackgroundColor3=C.rail,BorderSizePixel=0,Size=UDim2.new(0,railW,1,0),ZIndex=20,ClipsDescendants=true},shell)
    corner(rail,20)
    make("Frame",{BackgroundColor3=C.lineSoft,BackgroundTransparency=0.4,BorderSizePixel=0,Position=UDim2.new(1,-1,0,0),Size=UDim2.new(0,1,1,0),ZIndex=21},rail)

    local brand=make("ImageLabel",{Name="BrandMark",BackgroundColor3=C.raised,BorderSizePixel=0,Position=UDim2.fromOffset(mobile and 17 or 16,16),Size=UDim2.fromOffset(38,38),Image=type(config.Logo)=="string" and config.Logo or "",ImageTransparency=type(config.Logo)=="string" and 0 or 1,ScaleType=Enum.ScaleType.Fit,ZIndex=25},rail)
    corner(brand,12); stroke(brand,C.lineSoft,0.24,1)
    if type(config.Logo)~="string" then icon(rail,config.Icon or "layout-dashboard",UDim2.fromOffset(mobile and 25 or 25,24),UDim2.fromOffset(20,20),C.muted,26) end

    local brandTitle=label(rail,config.Title or "Khfresh Hub",13,C.text,true); brandTitle.Position=UDim2.fromOffset(62,10); brandTitle.Size=UDim2.new(1,-72,0,23); brandTitle.Visible=not mobile
    local brandSub=label(rail,config.Author or "Khfresh",9,C.muted,false); brandSub.Position=UDim2.fromOffset(62,34); brandSub.Size=UDim2.new(1,-72,0,18); brandSub.Visible=not mobile

    local nav=make("ScrollingFrame",{Name="Navigation",BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(9,mobile and 76 or 74),Size=UDim2.new(1,-18,1,-88),CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=2,ScrollBarImageTransparency=1,ZIndex=25},rail)
    local navLayout=listLayout(nav,6); navLayout.HorizontalAlignment=Enum.HorizontalAlignment.Center
    padding(nav,0,0,0,8)

    local top=make("Frame",{Name="TopBar",BackgroundColor3=C.header,BorderSizePixel=0,Position=UDim2.fromOffset(railW,0),Size=UDim2.new(1,-railW,0,topH),ZIndex=30},shell)
    corner(top,20); stroke(top,C.lineSoft,0.38,1)
    local headerIcon=icon(top,config.Icon or "layout-dashboard",UDim2.fromOffset(16,22),UDim2.fromOffset(22,22),C.muted,35)
    local pageTitle=label(top,config.Title or "Khfresh Hub",18,C.text,true); pageTitle.Position=UDim2.fromOffset(48,9); pageTitle.Size=UDim2.new(1,-126,0,27)
    local pageSub=label(top,config.Author or "Khfresh Hub",10,C.muted,false); pageSub.Position=UDim2.fromOffset(48,37); pageSub.Size=UDim2.new(1,-126,0,18)

    local function topButton(name,x,glyph)
        local b=make("TextButton",{Name=name,BackgroundColor3=C.raised,BorderSizePixel=0,AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,x,0.5,0),Size=UDim2.fromOffset(31,31),Text="",AutoButtonColor=false,ZIndex=40},top)
        corner(b,10); stroke(b,C.lineSoft,0.34,1); icon(b,glyph,UDim2.fromOffset(7,7),UDim2.fromOffset(17,17),C.secondary,42)
        return b
    end
    local minBtn=topButton("MinimizeButton",-47,"minus")
    local closeBtn=topButton("CloseButton",-9,"x")

    local content=make("Frame",{Name="ContentViewport",BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(railW,topH),Size=UDim2.new(1,-railW,1,-(topH+bottomH)),ClipsDescendants=true,ZIndex=24},shell)
    local overlay=make("Frame",{Name="OverlayLayer",BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromScale(1,1),ZIndex=3000},sg)

    local bottom=make("Frame",{Name="BottomDock",BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.new(0,railW,1,-bottomH),Size=UDim2.new(1,-railW,0,bottomH),ZIndex=50},shell)
    local drag=make("TextButton",{Name="DragHandle",BackgroundColor3=C.raised,BorderSizePixel=0,AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(96,16),Text="",AutoButtonColor=false,ZIndex=55},bottom)
    corner(drag,8)
    make("Frame",{BackgroundColor3=C.muted,BackgroundTransparency=0.06,BorderSizePixel=0,AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(42,3),ZIndex=56},drag)

    local resize=make("TextButton",{Name="ResizeHandle",BackgroundTransparency=1,BorderSizePixel=0,AnchorPoint=Vector2.new(1,1),Position=UDim2.fromScale(1,1),Size=UDim2.fromOffset(36,36),Text="",AutoButtonColor=false,ZIndex=70},shell)
    for i=0,2 do
        local d=make("Frame",{BackgroundColor3=C.muted,BackgroundTransparency=0.16+i*0.12,BorderSizePixel=0,AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-7-i*6,1,-8-i*6),Size=UDim2.fromOffset(11+i*4,2),Rotation=-45,ZIndex=71},resize)
        corner(d,1)
    end

    local floating=make("CanvasGroup",{Name="KhfreshFloating",BackgroundTransparency=1,BorderSizePixel=0,AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-18,1,-18),Size=UDim2.fromOffset(52,52),Visible=false,GroupTransparency=1,ZIndex=5000},sg)
    local floatingBtn=make("TextButton",{Name="Button",BackgroundColor3=C.raised,BorderSizePixel=0,Size=UDim2.fromScale(1,1),Text="",AutoButtonColor=false,ZIndex=5001},floating)
    corner(floatingBtn,16); stroke(floatingBtn,C.lineSoft,0.22,1); icon(floatingBtn,"volleyball",UDim2.fromOffset(13,13),UDim2.fromOffset(26,26),C.secondary,5003)

    local window=setmetatable({
        _gui=sg,_shell=shell,_panel=shell,_rail=rail,_nav=nav,_top=top,_content=content,_overlay=overlay,
        _bottomBar=bottom,_dragHandle=drag,_resizeHandle=resize,_floating=floating,_floatingButton=floatingBtn,
        _brandMark=brand,_brandTitle=brandTitle,_brandSub=brandSub,_background=bg,_backgroundShade=shade,
        _headerIcon=headerIcon,_pageTitle=pageTitle,_context=pageSub,_tabs={},_active=nil,_open=true,
        _connections={},_order=0,_floatingVisible=true,_keybind=config.Keybind or Enum.KeyCode.RightAlt,
        _width=initialW,_height=initialH,_mobile=mobile,_railExpanded=not mobile,_minimized=false,
    },Window)
    table.insert(self._windows,window)

    local function beginDrag(input)
        if input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch then return end
        local start=input.Position
        local startPos=shell.Position
        local finished=false
        local c1,c2
        c1=UserInputService.InputChanged:Connect(function(move)
            if finished then return end
            if move.UserInputType~=Enum.UserInputType.MouseMovement and move.UserInputType~=Enum.UserInputType.Touch then return end
            local d=move.Position-start
            local vp2=viewportSize()
            local halfW=shell.AbsoluteSize.X/2; local halfH=shell.AbsoluteSize.Y/2
            local nx=startPos.X.Offset+d.X; local ny=startPos.Y.Offset+d.Y
            nx=safeClamp(nx,-vp2.X/2+16-halfW,vp2.X/2-16+halfW)
            ny=safeClamp(ny,-vp2.Y/2+16-halfH,vp2.Y/2-16+halfH)
            shell.Position=UDim2.new(0.5,nx,0.5,ny)
        end)
        c2=UserInputService.InputEnded:Connect(function(endInput)
            if endInput.UserInputType==Enum.UserInputType.MouseButton1 or endInput.UserInputType==Enum.UserInputType.Touch then
                finished=true; c1:Disconnect(); c2:Disconnect()
            end
        end)
        table.insert(window._connections,c1); table.insert(window._connections,c2)
    end
    drag.InputBegan:Connect(beginDrag)
    top.InputBegan:Connect(beginDrag)

    resize.InputBegan:Connect(function(input)
        if input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch then return end
        local start=input.Position
        local startW=shell.AbsoluteSize.X; local startH=shell.AbsoluteSize.Y
        local done=false
        local c1,c2
        c1=UserInputService.InputChanged:Connect(function(move)
            if done then return end
            if move.UserInputType~=Enum.UserInputType.MouseMovement and move.UserInputType~=Enum.UserInputType.Touch then return end
            local vp3=viewportSize()
            local mob=isMobileViewport()
            local minW=mob and 330 or 520
            local minH=mob and 400 or 420
            local maxW=math.min(900,vp3.X-(mob and 10 or 26))
            local maxH=math.min(760,vp3.Y-(mob and 12 or 42))
            window._width=safeClamp(startW+(move.Position.X-start.X),minW,maxW)
            window._height=safeClamp(startH+(move.Position.Y-start.Y),minH,maxH)
            window:_applyResponsive()
        end)
        c2=UserInputService.InputEnded:Connect(function(endInput)
            if endInput.UserInputType==Enum.UserInputType.MouseButton1 or endInput.UserInputType==Enum.UserInputType.Touch then
                done=true; c1:Disconnect(); c2:Disconnect()
            end
        end)
        table.insert(window._connections,c1); table.insert(window._connections,c2)
    end)

    if workspace.CurrentCamera then
        table.insert(window._connections,workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function() window:_applyResponsive() end))
    end
    bindActivated(closeBtn,function() window:Destroy() end)
    bindActivated(minBtn,function() window:Toggle() end)
    bindActivated(floatingBtn,function() window:Open() end)

    table.insert(window._connections,UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode==window._keybind and not UserInputService:GetFocusedTextBox() then window:Toggle() end
    end))

    window:_applyResponsive()
    window:_animateIn()
    return window
end

function Window:_animateIn()
    self._shell.GroupTransparency=1
    self._shell.Position=UDim2.fromScale(0.5,0.5)+UDim2.fromOffset(0,8)
    tween(self._shell,Motion.enter,{GroupTransparency=0,Position=UDim2.fromScale(0.5,0.5)})
end

function Window:_applyResponsive()
    if not self._shell or not self._shell.Parent then return end
    local vp=viewportSize()
    local mobile=isMobileViewport()
    self._mobile=mobile
    if mobile then
        self._width=math.min(self._width,math.max(330,vp.X-10))
        self._height=math.min(self._height,math.max(400,vp.Y-12))
    else
        self._width=math.clamp(self._width,520,math.min(900,math.max(520,vp.X-26)))
        self._height=math.clamp(self._height,420,math.min(760,math.max(420,vp.Y-42)))
    end
    local railW=mobile and 68 or 190
    self._shell.Size=UDim2.fromOffset(self._width,self._height)
    self._rail.Size=UDim2.new(0,railW,1,0)
    self._top.Position=UDim2.fromOffset(railW,0)
    self._top.Size=UDim2.new(1,-railW,0,68)
    self._content.Position=UDim2.fromOffset(railW,68)
    self._content.Size=UDim2.new(1,-railW,1,-90)
    self._bottomBar.Position=UDim2.new(0,railW,1,-22)
    self._bottomBar.Size=UDim2.new(1,-railW,0,22)
    self._nav.Position=UDim2.fromOffset(9,mobile and 72 or 74)
    self._nav.Size=UDim2.new(1,-18,1,mobile and -84 or -88)
    self._brandTitle.Visible=not mobile; self._brandSub.Visible=not mobile
    for _,tab in ipairs(self._tabs) do
        tab._button.Size=UDim2.new(1,0,0,mobile and 44 or 38)
        tab._label.Visible=not mobile
        if mobile then
            tab._iconHolder.Position=UDim2.new(0.5,-10,0.5,-10)
        else
            tab._iconHolder.Position=UDim2.fromOffset(10,9)
        end
        tab._page.Size=UDim2.fromScale(1,1)
        tab._scroll.Size=UDim2.new(1,-4,1,0)
        if tab._settings then tab:_reflowSettings() end
    end
end

function Window:CreateTab(nameOrConfig, iconName)
    local title,iconKey
    if type(nameOrConfig)=="table" then title=tostring(nameOrConfig.Title or nameOrConfig.Name or "Tab"); iconKey=nameOrConfig.Icon or iconName
    else title=tostring(nameOrConfig or "Tab"); iconKey=iconName end
    iconKey=iconKey or "info"

    local button=make("TextButton",{Name="Tab_"..title:gsub("[^%w_]+","_"),BackgroundColor3=C.raised,BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.new(1,0,0,38),Text="",AutoButtonColor=false,LayoutOrder=#self._tabs+1,ZIndex=28},self._nav)
    corner(button,13)
    local iconHolder=make("Frame",{Name="IconHolder",BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(10,9),Size=UDim2.fromOffset(20,20),ZIndex=30},button)
    local iconImage=icon(iconHolder,iconKey,UDim2.fromScale(0,0),UDim2.fromScale(1,1),C.muted,32)
    local tabLabel=label(button,title,12,C.secondary,true); tabLabel.Position=UDim2.fromOffset(40,0); tabLabel.Size=UDim2.new(1,-48,1,0); tabLabel.ZIndex=31

    local page=make("CanvasGroup",{Name="Page_"..title:gsub("[^%w_]+","_"),BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(8,0),Size=UDim2.fromScale(1,1),GroupTransparency=1,Visible=false,ZIndex=25},self._content)
    local scroll=make("ScrollingFrame",{Name="Scroll",BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(0,0),Size=UDim2.new(1,-4,1,0),CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.None,ScrollBarThickness=4,ScrollBarImageColor3=C.muted,ScrollBarImageTransparency=0.35,ScrollingDirection=Enum.ScrollingDirection.Y,ElasticBehavior=Enum.ElasticBehavior.Always,ZIndex=26},page)
    padding(scroll,isMobileViewport() and 10 or 16,isMobileViewport() and 8 or 12,12,18)

    local settings=string.lower(title)=="settings"
    local tab=setmetatable({
        _window=self,_name=title,_button=button,_icon=iconImage,_iconHolder=iconHolder,_label=tabLabel,_page=page,_scroll=scroll,
        _order=0,_settings=settings,_settingsSections={},_direct=nil,
    },Tab)

    if settings then
        local host=make("Frame",{Name="SettingsHost",BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.new(1,0,0,1),ZIndex=27},scroll)
        local left=make("Frame",{Name="LeftColumn",BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.new(0.5,-6,0,1),ZIndex=27},host)
        local right=make("Frame",{Name="RightColumn",BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.new(0.5,6,0,0),Size=UDim2.new(0.5,-6,0,1),ZIndex=27},host)
        local ll=listLayout(left,10); local rl=listLayout(right,10)
        tab._settingsHost=host; tab._leftColumn=left; tab._rightColumn=right; tab._leftLayout=ll; tab._rightLayout=rl
        ll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() tab:_refreshLayout() end)
        rl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() tab:_refreshLayout() end)
    else
        local host=make("Frame",{Name="ListHost",BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.new(1,0,0,1),ZIndex=27},scroll)
        local lay=listLayout(host,10)
        lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() tab:_refreshLayout() end)
        tab._listHost=host; tab._listLayout=lay
    end

    table.insert(self._tabs,tab)
    bindActivated(button,function() self:_select(tab) end)
    button.MouseEnter:Connect(function() if self._active~=tab then tween(button,Motion.hover,{BackgroundTransparency=0.86}) end end)
    button.MouseLeave:Connect(function() if self._active~=tab then tween(button,Motion.hover,{BackgroundTransparency=1}) end end)
    if not self._active then self:_select(tab,true) end
    self:_applyResponsive()
    return tab
end

function Window:GetTab(title)
    local wanted=string.lower(tostring(title or ""))
    for _,tab in ipairs(self._tabs) do if string.lower(tab._name)==wanted then return tab end end
end

function Window:_select(tab,instant)
    if not tab then return end
    self._active=tab
    self._pageTitle.Text=tab._name
    self._context.Text=string.upper(tab._name).."  /  KHFRESH"
    for _,other in ipairs(self._tabs) do
        local selected=other==tab
        other._page.Visible=true
        if selected then
            other._page.GroupTransparency=instant and 0 or 1
            other._page.Position=instant and UDim2.fromOffset(0,0) or UDim2.fromOffset(10,0)
            if not instant then tween(other._page,Motion.enter,{GroupTransparency=0,Position=UDim2.fromOffset(0,0)}) end
        else
            other._page.Visible=false
            other._page.GroupTransparency=1
            other._page.Position=UDim2.fromOffset(10,0)
        end
        other._button.BackgroundColor3=selected and C.accentSoft or C.raised
        other._button.BackgroundTransparency=selected and 0 or 1
        tintIcon(other._icon,selected and C.accent or C.muted)
        other._label.TextColor3=selected and C.text or C.secondary
    end
    if tab._settings then tab:_reflowSettings() end
end

function Window:SelectTab(indexOrName)
    if type(indexOrName)=="string" then local t=self:GetTab(indexOrName); if t then self:_select(t) end; return end
    local idx=tonumber(indexOrName); if idx then self:_select(self._tabs[idx]) end
end

function Window:SetBackground(asset,transparency)
    if type(asset)~="string" or asset=="" then return end
    if self._background and self._background.Parent then self._background.Image=asset; self._background.ImageTransparency=tonumber(transparency) or 0.58; return end
    self._background=make("ImageLabel",{Name="Background",BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromScale(1,1),Image=asset,ImageTransparency=tonumber(transparency) or 0.58,ScaleType=Enum.ScaleType.Crop,ZIndex=11},self._shell)
end

function Window:SetLogo(asset)
    if self._brandMark and type(asset)=="string" and asset~="" then self._brandMark.Image=asset; self._brandMark.ImageTransparency=0 end
end

function Window:CreateFloatingToggle(config)
    config=config or {}
    local wanted=resolveIconName(config.Icon or "volleyball")
    if self._floatingButton then
        for _,child in ipairs(self._floatingButton:GetChildren()) do
            if child.Name:sub(1,5)=="Icon_" or child.Name=="IconFallback" then pcall(function() child:Destroy() end) end
        end
        icon(self._floatingButton,wanted,UDim2.fromOffset(13,13),UDim2.fromOffset(26,26),C.secondary,5003)
    end
    self._floatingVisible=true
    return self._floating
end

function Window:SetFloatingVisible(value)
    self._floatingVisible=value==true
    if self._floatingVisible and not self._open then self:_showFloating() elseif not self._floatingVisible then self:_hideFloating() end
end

function Window:_showFloating()
    if not self._floating or not self._floatingVisible or self._open then return end
    self._floating.Visible=true
    self._floating.GroupTransparency=1
    local scale=self._floating:FindFirstChildOfClass("UIScale")
    if not scale then scale=make("UIScale",{Scale=0.86},self._floating) end
    scale.Scale=0.86
    tween(self._floating,Motion.pop,{GroupTransparency=0})
    tween(scale,Motion.pop,{Scale=1})
end

function Window:_hideFloating()
    if not self._floating then return end
    tween(self._floating,Motion.exit,{GroupTransparency=1})
    task.delay(0.20,function() if self._floating and self._floating.Parent and self._open then self._floating.Visible=false end end)
end

function Window:Minimize()
    if not self._open then return end
    self._open=false
    self._minimized=true
    tween(self._shell,Motion.exit,{GroupTransparency=1,Position=UDim2.fromScale(0.5,0.5)+UDim2.fromOffset(0,8)})
    task.delay(0.19,function() if not self._open and self._shell then self._shell.Visible=false; self:_showFloating() end end)
end

function Window:Open()
    if self._open then return end
    self._open=true
    self._minimized=false
    self:_hideFloating()
    self._shell.Visible=true
    self._shell.GroupTransparency=1
    self._shell.Position=UDim2.fromScale(0.5,0.5)+UDim2.fromOffset(0,8)
    tween(self._shell,Motion.enter,{GroupTransparency=0,Position=UDim2.fromScale(0.5,0.5)})
end

function Window:Toggle()
    if self._open then self:Minimize() else self:Open() end
end

function Window:Destroy()
    for _,c in ipairs(self._connections) do pcall(function() c:Disconnect() end) end
    self._connections={}
    if self._gui then pcall(function() self._gui:Destroy() end) end
    if self._floating and self._floating.Parent then pcall(function() self._floating:Destroy() end) end
    self._open=false
end
function Window:ToggleAcrylic() end

function Window:ApplyTheme()
    self._shell.BackgroundColor3=C.shell
    self._rail.BackgroundColor3=C.rail
    self._top.BackgroundColor3=C.header
    self._backgroundShade.BackgroundColor3=C.canvas
    for _,tab in ipairs(self._tabs) do
        local sel=tab==self._active
        tab._button.BackgroundColor3=sel and C.accentSoft or C.raised
        tintIcon(tab._icon,sel and C.accent or C.muted)
        tab._label.TextColor3=sel and C.text or C.secondary
    end
end

function Tab:CreateHeader(config)
    config=type(config)=="table" and config or {Title=tostring(config or "")}
    local parent=self._settings and self._leftColumn or self._listHost
    local frame=make("Frame",{Name="Header_"..tostring(config.Title or "Header"):gsub("[^%w_]+","_"),BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.new(1,0,0,60),LayoutOrder=self:_nextOrder(),ZIndex=27},parent)
    local title=label(frame,config.Title or "Overview",20,C.text,true); title.Position=UDim2.fromOffset(0,6); title.Size=UDim2.new(1,-8,0,26); title.ZIndex=29
    local sub=label(frame,config.Subtitle or config.Desc or "",11,C.muted,false); sub.Position=UDim2.fromOffset(0,34); sub.Size=UDim2.new(1,-8,0,18); sub.ZIndex=29
    return frame
end

function Tab:CreateSection(nameOrConfig,side)
    local cfg=type(nameOrConfig)=="table" and nameOrConfig or {}
    local name=type(nameOrConfig)=="table" and tostring(nameOrConfig.Title or nameOrConfig.Name or "Section") or tostring(nameOrConfig or "Section")
    local settings=self._settings
    side=side or cfg.Side
    local parent=settings and self._leftColumn or self._listHost
    local frame=make("Frame",{Name="Section_"..name:gsub("[^%w_]+","_"),BackgroundColor3=settings and C.raised or C.raised,BackgroundTransparency=settings and 0.08 or 0.14,BorderSizePixel=0,Size=UDim2.new(1,0,0,40),LayoutOrder=self:_nextOrder(),ClipsDescendants=false,ZIndex=27},parent)
    corner(frame,16); stroke(frame,C.line,0.36,1)
    local header=make("Frame",{Name="SectionHeader",BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.new(1,0,0,31),ZIndex=28},frame)
    icon(header,cfg.Icon or "layers",UDim2.fromOffset(11,7),UDim2.fromOffset(17,17),C.muted,30)
    local ht=label(header,name,12,C.secondary,true); ht.Position=UDim2.fromOffset(34,0); ht.Size=UDim2.new(1,-45,1,0); ht.ZIndex=31
    local body=make("Frame",{Name="Body",BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(10,34),Size=UDim2.new(1,-20,0,1),ZIndex=29},frame)
    local bodyLayout=listLayout(body,7)
    local section=setmetatable({_tab=self,_window=self._window,_name=name,_frame=frame,_body=body,_bodyLayout=bodyLayout,_side=side,_settings=settings},Section)
    bodyLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() refreshSection(section) end)
    if settings then table.insert(self._settingsSections,section); self:_reflowSettings() end
    refreshSection(section)
    return section
end

function Tab:_directSection()
    if not self._direct then self._direct=self:CreateSection("Controls") end
    return self._direct
end
function Tab:CreateButton(c) return self:_directSection():CreateButton(c) end
function Tab:CreateToggle(c) return self:_directSection():CreateToggle(c) end
function Tab:CreateDropdown(c) return self:_directSection():CreateDropdown(c) end
function Tab:CreateMultiDropdown(c) return self:_directSection():CreateMultiDropdown(c) end
function Tab:CreateTextbox(c) return self:_directSection():CreateTextbox(c) end
function Tab:CreateSlider(c) return self:_directSection():CreateSlider(c) end
function Tab:CreateColorpicker(c) return self:_directSection():CreateColorpicker(c) end
function Tab:CreateLabel(c) return self:_directSection():CreateLabel(c) end

local function leadingIcon(row,config)
    if not config.Icon then return 14 end
    icon(row,config.Icon,UDim2.fromOffset(12,11),UDim2.fromOffset(20,20),C.muted,35)
    return 42
end

function Section:CreateLabel(value)
    local row=self:_addRow("Label",34)
    local t=label(row,tostring(value or ""),11,C.secondary,false); t.Position=UDim2.fromOffset(14,0); t.Size=UDim2.new(1,-28,1,0); t.ZIndex=36
    return {_frame=row}
end

function Section:CreateButton(config)
    config=config or {}
    local row,hit=self:_addRow(config.Name or "Button",42)
    local start=leadingIcon(row,config)
    local t=label(row,config.Name or config.Title or "Action",12,C.text,true); t.Position=UDim2.fromOffset(start,0); t.Size=UDim2.new(1,-start-48,1,0); t.ZIndex=36
    local chip=make("Frame",{BackgroundColor3=C.raised,BorderSizePixel=0,AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-10,0.5,0),Size=UDim2.fromOffset(24,24),ZIndex=37},row)
    corner(chip,8); icon(chip,"chevron-right",UDim2.fromOffset(4,4),UDim2.fromOffset(16,16),C.muted,39)
    hit.Activated:Connect(function() if config.Callback then task.spawn(config.Callback) end end)
    hit.MouseEnter:Connect(function() tween(chip,Motion.hover,{BackgroundColor3=C.rowHover}) end)
    hit.MouseLeave:Connect(function() tween(chip,Motion.hover,{BackgroundColor3=C.raised}) end)
    return {_frame=row}
end

function Section:CreateToggle(config)
    config=config or {}
    local row,hit=self:_addRow(config.Name or "Toggle",42)
    local start=leadingIcon(row,config)
    local t=label(row,config.Name or config.Title or "Toggle",12,C.text,true); t.Position=UDim2.fromOffset(start,0); t.Size=UDim2.new(1,-start-74,1,0); t.ZIndex=36
    local state=config.Default==true or config.Value==true
    local track=make("Frame",{BackgroundColor3=state and C.accentSoft or Color3.fromRGB(52,57,65),BorderSizePixel=0,AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-11,0.5,0),Size=UDim2.fromOffset(44,24),ZIndex=37},row)
    corner(track,12); stroke(track,C.lineSoft,0.24,1)
    local knob=make("Frame",{BackgroundColor3=state and C.accent or Color3.fromRGB(198,203,211),BorderSizePixel=0,AnchorPoint=Vector2.new(0.5,0.5),Position=state and UDim2.new(1,-12,0.5,0) or UDim2.new(0,12,0.5,0),Size=UDim2.fromOffset(state and 18 or 16,state and 18 or 16),ZIndex=38},track)
    corner(knob,10)
    local function set(v,emit)
        state=v==true
        tween(track,Motion.base,{BackgroundColor3=state and C.accentSoft or Color3.fromRGB(52,57,65)})
        tween(knob,Motion.base,{Position=state and UDim2.new(1,-12,0.5,0) or UDim2.new(0,12,0.5,0),Size=UDim2.fromOffset(state and 18 or 16,state and 18 or 16),BackgroundColor3=state and C.accent or Color3.fromRGB(198,203,211)})
        if emit and config.Callback then task.spawn(config.Callback,state) end
    end
    hit.Activated:Connect(function() set(not state,true) end)
    return {_frame=row,Set=function(_,v)set(v,true)end,SetValue=function(_,v)set(v,true)end,Get=function()return state end}
end

local function optionValue(v)
    if type(v)=="table" then return tostring(v.Title or v.Name or v.Value or v.Text or v[1] or "") end
    return tostring(v or "")
end

function Section:CreateDropdown(config)
    config=config or {}
    local row,hit=self:_addRow(config.Name or "Dropdown",44)
    local start=leadingIcon(row,config)
    local title=label(row,config.Name or config.Title or "Select",11,C.secondary,true); title.Position=UDim2.fromOffset(start,0); title.Size=UDim2.new(0.50,-start,1,0); title.ZIndex=36
    local options=config.Options or config.Values or {}
    local selected=config.Default or config.Value or options[1] or "Select"
    selected=optionValue(selected)
    local val=label(row,selected,11,C.text,false); val.Position=UDim2.new(0.50,0,0,0); val.Size=UDim2.new(0.50,-40,1,0); val.TextXAlignment=Enum.TextXAlignment.Right; val.ZIndex=36
    icon(row,"chevron-down",UDim2.new(1,-29,0.5,-8),UDim2.fromOffset(16,16),C.muted,38)
    local open=false
    local menu
    local function closeMenu()
        if menu and menu.Parent then menu:Destroy() end
        menu=nil; open=false
    end
    local function showMenu()
        closeMenu(); open=true
        menu=make("Frame",{Name="DropdownMenu",BackgroundColor3=C.header,BorderSizePixel=0,ClipsDescendants=true,ZIndex=3100},self._window._overlay)
        corner(menu,14); stroke(menu,C.line,0.16,1)
        local scroll=make("ScrollingFrame",{BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromScale(1,1),CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=3,ScrollBarImageColor3=C.muted,ZIndex=3101},menu)
        padding(scroll,6,6,6,6); local lay=listLayout(scroll,4)
        for i,opt in ipairs(options) do
            local value=optionValue(opt)
            local b=make("TextButton",{Name="Option_"..i,BackgroundColor3=C.row,BorderSizePixel=0,Size=UDim2.new(1,0,0,34),Text="",AutoButtonColor=false,ZIndex=3102},scroll)
            corner(b,9); icon(b,"chevron-right",UDim2.fromOffset(8,8),UDim2.fromOffset(18,18),C.muted,3104)
            local tx=label(b,value,11,C.secondary,false); tx.Position=UDim2.fromOffset(32,0); tx.Size=UDim2.new(1,-40,1,0); tx.ZIndex=3105
            b.MouseEnter:Connect(function() tween(b,Motion.hover,{BackgroundColor3=C.rowHover}) end)
            b.MouseLeave:Connect(function() tween(b,Motion.hover,{BackgroundColor3=C.row}) end)
            b.Activated:Connect(function()
                selected=value; val.Text=value; closeMenu()
                if config.Callback then task.spawn(config.Callback,value) end
            end)
        end
        local p=row.AbsolutePosition; local s=row.AbsoluteSize; local vp=viewportSize()
        local w=math.clamp(s.X,210,math.min(360,vp.X-16)); local h=math.min(250,math.max(40,#options*38+12))
        local x=safeClamp(p.X,8,vp.X-w-8); local y=p.Y+s.Y+4
        if y+h>vp.Y-8 then y=math.max(8,p.Y-h-4) end
        menu.Position=UDim2.fromOffset(x,y); menu.Size=UDim2.fromOffset(w,h)
    end
    hit.Activated:Connect(function() if open then closeMenu() else showMenu() end end)
    return {_frame=row,Get=function()return selected end,Set=function(_,v)selected=optionValue(v);val.Text=selected end,SetValue=function(_,v)selected=optionValue(v);val.Text=selected end}
end

function Section:CreateMultiDropdown(config)
    config=config or {}
    local row,hit=self:_addRow(config.Name or "Multi-select",44)
    local start=leadingIcon(row,config)
    local title=label(row,config.Name or config.Title or "Select",11,C.secondary,true); title.Position=UDim2.fromOffset(start,0); title.Size=UDim2.new(0.46,-start,1,0); title.ZIndex=36
    local options=config.Options or config.Values or {}; local selected={}
    for _,v in ipairs(config.Default or {}) do selected[optionValue(v)]=true end
    local function summary()
        local out={}; for _,v in ipairs(options) do local s=optionValue(v); if selected[s] then out[#out+1]=s end end
        return #out>0 and table.concat(out,", ") or "None"
    end
    local val=label(row,summary(),11,C.text,false); val.Position=UDim2.new(0.46,0,0,0); val.Size=UDim2.new(0.54,-40,1,0); val.TextXAlignment=Enum.TextXAlignment.Right; val.ZIndex=36
    icon(row,"chevron-down",UDim2.new(1,-29,0.5,-8),UDim2.fromOffset(16,16),C.muted,38)
    local open=false; local menu
    local function closeMenu() if menu and menu.Parent then menu:Destroy() end; menu=nil;open=false end
    local function showMenu()
        closeMenu(); open=true
        menu=make("Frame",{Name="MultiDropdownMenu",BackgroundColor3=C.header,BorderSizePixel=0,ClipsDescendants=true,ZIndex=3100},self._window._overlay)
        corner(menu,14); stroke(menu,C.line,0.16,1)
        local scroll=make("ScrollingFrame",{BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromScale(1,1),CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=3,ScrollBarImageColor3=C.muted,ZIndex=3101},menu)
        padding(scroll,6,6,6,6); listLayout(scroll,4)
        for i,opt in ipairs(options) do
            local s=optionValue(opt)
            local b=make("TextButton",{Name="Option_"..i,BackgroundColor3=C.row,BorderSizePixel=0,Size=UDim2.new(1,0,0,34),Text="",AutoButtonColor=false,ZIndex=3102},scroll)
            corner(b,9)
            local mark=icon(b,selected[s] and "check" or "chevron-right",UDim2.fromOffset(8,8),UDim2.fromOffset(18,18),selected[s] and C.accent or C.muted,3104)
            local tx=label(b,s,11,C.secondary,false); tx.Position=UDim2.fromOffset(32,0); tx.Size=UDim2.new(1,-40,1,0); tx.ZIndex=3105
            b.Activated:Connect(function()
                selected[s]=not selected[s]; tintIcon(mark,selected[s] and C.accent or C.muted); mark.ImageContent=mark.ImageContent
                if config.Callback then local out={}; for _,o in ipairs(options) do local q=optionValue(o); if selected[q] then out[#out+1]=q end end; task.spawn(config.Callback,out) end
                val.Text=summary()
            end)
        end
        local p=row.AbsolutePosition; local s=row.AbsoluteSize; local vp=viewportSize()
        local w=math.clamp(s.X,210,math.min(360,vp.X-16)); local h=math.min(260,math.max(40,#options*38+12))
        local x=safeClamp(p.X,8,vp.X-w-8); local y=p.Y+s.Y+4
        if y+h>vp.Y-8 then y=math.max(8,p.Y-h-4) end
        menu.Position=UDim2.fromOffset(x,y); menu.Size=UDim2.fromOffset(w,h)
    end
    hit.Activated:Connect(function() if open then closeMenu() else showMenu() end end)
    return {_frame=row,Get=function()local out={};for k,v in pairs(selected)do if v then out[#out+1]=k end end;return out end}
end

function Section:CreateTextbox(config)
    config=config or {}
    local row=self:_addRow(config.Name or "Input",42)
    local start=leadingIcon(row,config)
    local title=label(row,config.Name or config.Title or "Input",11,C.secondary,true); title.Position=UDim2.fromOffset(start,0); title.Size=UDim2.new(0.42,-start,1,0); title.ZIndex=36
    local box=make("TextBox",{BackgroundColor3=C.raised,BorderSizePixel=0,ClearTextOnFocus=false,PlaceholderText=tostring(config.Placeholder or ""),Text=tostring(config.Default or config.Value or ""),TextColor3=C.text,PlaceholderColor3=C.muted,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-10,0.5,0),Size=UDim2.new(0.56, -12,0,32),ZIndex=40},row)
    corner(box,10); stroke(box,C.lineSoft,0.26,1)
    box.FocusLost:Connect(function(enter) if config.Callback and (enter or config.UpdateOnFocusLost~=false) then task.spawn(config.Callback,box.Text) end end)
    return {_frame=row,Set=function(_,v)box.Text=tostring(v or "")end,SetValue=function(_,v)box.Text=tostring(v or "")end,Get=function()return box.Text end}
end

function Section:CreateSlider(config)
    config=config or {}
    local row=self:_addRow(config.Name or "Slider",52)
    local start=leadingIcon(row,config)
    local title=label(row,config.Name or config.Title or "Slider",11,C.secondary,true); title.Position=UDim2.fromOffset(start,0); title.Size=UDim2.new(1,-start-70,0,24); title.ZIndex=36
    local min=tonumber(config.Min or config.Minimum or 0) or 0; local max=tonumber(config.Max or config.Maximum or 100) or 100; if max<=min then max=min+1 end
    local value=tonumber(config.Default or config.Value or min) or min; value=math.clamp(value,min,max)
    local read=label(row,tostring(value),11,C.text,true); read.Position=UDim2.new(1,-54,0,0); read.Size=UDim2.fromOffset(44,24); read.TextXAlignment=Enum.TextXAlignment.Right; read.ZIndex=36
    local bar=make("Frame",{BackgroundColor3=C.raised,BorderSizePixel=0,Position=UDim2.fromOffset(start,31),Size=UDim2.new(1,-start-28,0,6),ZIndex=37},row); corner(bar,4)
    local fill=make("Frame",{BackgroundColor3=C.accent,BorderSizePixel=0,Size=UDim2.new((value-min)/(max-min),0,1,0),ZIndex=38},bar); corner(fill,4)
    local knob=make("Frame",{BackgroundColor3=C.accent,BorderSizePixel=0,AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new((value-min)/(max-min),0,0.5,0),Size=UDim2.fromOffset(12,12),ZIndex=39},bar); corner(knob,6)
    local hit=make("TextButton",{Text="",BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(start-4,24),Size=UDim2.new(1,-start-20,0,20),AutoButtonColor=false,ZIndex=60},row)
    local function setFromX(x,emit)
        local ratio=math.clamp((x-bar.AbsolutePosition.X)/math.max(1,bar.AbsoluteSize.X),0,1); value=min+(max-min)*ratio
        if config.Round then local r=tonumber(config.Round) or 1; value=math.floor(value/r+0.5)*r end
        fill.Size=UDim2.new((value-min)/(max-min),0,1,0); knob.Position=UDim2.new((value-min)/(max-min),0,0.5,0); read.Text=tostring(math.floor(value*100+0.5)/100)
        if emit and config.Callback then task.spawn(config.Callback,value) end
    end
    hit.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then setFromX(input.Position.X,true) end end)
    return {_frame=row,Set=function(_,v)setFromX(bar.AbsolutePosition.X+bar.AbsoluteSize.X*math.clamp((tonumber(v) or min-min)/(max-min),0,1),true)end,SetValue=function(_,v)setFromX(bar.AbsolutePosition.X+bar.AbsoluteSize.X*math.clamp(((tonumber(v) or min)-min)/(max-min),0,1),true)end,Get=function()return value end}
end

function Section:CreateColorpicker(config)
    config=config or {}
    local row,hit=self:_addRow(config.Name or "Color",42)
    local start=leadingIcon(row,config)
    local t=label(row,config.Name or config.Title or "Color",12,C.text,true); t.Position=UDim2.fromOffset(start,0); t.Size=UDim2.new(1,-74,1,0); t.ZIndex=36
    local color=typeof(config.Default)=="Color3" and config.Default or C.accentSoft
    local sw=make("Frame",{BackgroundColor3=color,BorderSizePixel=0,AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-12,0.5,0),Size=UDim2.fromOffset(38,22),ZIndex=38},row); corner(sw,8); stroke(sw,C.lineSoft,0.24,1)
    hit.Activated:Connect(function() if config.Callback then task.spawn(config.Callback,sw.BackgroundColor3) end end)
    return {_frame=row,Set=function(_,v)if typeof(v)=="Color3"then color=v;sw.BackgroundColor3=v end end,SetValue=function(_,v)if typeof(v)=="Color3"then color=v;sw.BackgroundColor3=v end end,Get=function()return color end}
end

function Tab:CreateStatRow(items)
    local parent=self._settings and self._leftColumn or self._listHost
    local row=make("Frame",{BackgroundColor3=C.raised,BorderSizePixel=0,Size=UDim2.new(1,0,0,46),LayoutOrder=self:_nextOrder(),ZIndex=27},parent)
    corner(row,14); stroke(row,C.lineSoft,0.28,1)
    local x=12
    for _,item in ipairs(items or {}) do
        local txt=type(item)=="table" and (item.Value or item[2] or item.Title) or item
        local l=label(row,tostring(txt or "-"),11,C.text,true); l.Position=UDim2.fromOffset(x,0); l.Size=UDim2.fromOffset(90,46); x=x+94
    end
    return row
end
function Tab:CreateFeaturedCard(config)
    config=config or {}
    local parent=self._settings and self._leftColumn or self._listHost
    local row=make("Frame",{BackgroundColor3=C.raised,BorderSizePixel=0,Size=UDim2.new(1,0,0,72),LayoutOrder=self:_nextOrder(),ZIndex=27},parent)
    corner(row,15); stroke(row,C.lineSoft,0.28,1)
    local t=label(row,config.Title or "Featured",14,C.text,true); t.Position=UDim2.fromOffset(14,9); t.Size=UDim2.new(1,-28,0,24)
    local d=label(row,config.Subtitle or config.Desc or "",11,C.muted,false); d.Position=UDim2.fromOffset(14,36); d.Size=UDim2.new(1,-28,0,23)
    if config.Callback then bindActivated(row,config.Callback) end
    return row
end
function Tab:CreateActionRow(c)return self:CreateFeaturedCard(c)end
function Tab:CreateCardGroup(c)return self:CreateFeaturedCard(c)end

return UI
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local AssetService = game:GetService("AssetService")

local LocalPlayer = Players.LocalPlayer

local function resolveGuiParent()
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

local GuiParent = resolveGuiParent()

local UI = {
    _windows = {},
    _version = "7.0.0-khfresh-material-bento",
    _notificationGui = nil,
}

local THEMES = {
    Bento = {
        canvas = Color3.fromRGB(18, 20, 24),
        shell = Color3.fromRGB(24, 27, 33),
        rail = Color3.fromRGB(20, 22, 27),
        header = Color3.fromRGB(29, 32, 38),
        raised = Color3.fromRGB(32, 36, 43),
        row = Color3.fromRGB(28, 32, 39),
        rowHover = Color3.fromRGB(35, 40, 48),
        rowPressed = Color3.fromRGB(42, 47, 56),
        line = Color3.fromRGB(70, 77, 88),
        lineSoft = Color3.fromRGB(48, 54, 63),
        text = Color3.fromRGB(241, 243, 247),
        secondary = Color3.fromRGB(181, 187, 198),
        muted = Color3.fromRGB(126, 134, 147),
        accent = Color3.fromRGB(205, 210, 218),
        accentSoft = Color3.fromRGB(64, 69, 78),
        success = Color3.fromRGB(160, 203, 175),
        danger = Color3.fromRGB(226, 145, 143),
        warning = Color3.fromRGB(216, 189, 126),
        whiteSoft = Color3.fromRGB(226, 229, 235),
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
    fast = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    hover = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    base = TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    enter = TweenInfo.new(0.30, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    exit = TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
    pop = TweenInfo.new(0.34, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
}

local function make(className, props, parent)
    local obj = Instance.new(className)
    for k, v in pairs(props or {}) do
        local ok = pcall(function() obj[k] = v end)
        if not ok then
            -- Ignore optional properties unsupported by a particular Roblox build.
        end
    end
    obj.Parent = parent
    return obj
end

local function corner(parent, radius)
    return make("UICorner", { CornerRadius = UDim.new(0, radius or 12) }, parent)
end

local function stroke(parent, color, transparency, thickness)
    return make("UIStroke", {
        Color = color or C.line,
        Transparency = transparency == nil and 0.38 or transparency,
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

local function label(parent, value, size, color, bold)
    return make("TextLabel", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = tostring(value or ""),
        TextColor3 = color or C.text,
        TextSize = size or 13,
        Font = bold and Enum.Font.GothamMedium or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 10,
    }, parent)
end

local function tween(obj, info, props)
    if not obj or not obj.Parent then return nil end
    local ok, tw = pcall(function()
        return TweenService:Create(obj, info or Motion.base, props)
    end)
    if ok and tw then tw:Play(); return tw end
end

local function bindActivated(gui, callback)
    if not gui or type(callback) ~= "function" then return end
    if gui:IsA("GuiButton") then
        gui.Activated:Connect(function()
            task.spawn(callback)
        end)
    else
        local hit = make("TextButton", {
            Text = "",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1),
            AutoButtonColor = false,
            ZIndex = 90,
        }, gui)
        hit.Activated:Connect(function()
            task.spawn(callback)
        end)
    end
end

local function viewportSize()
    local cam = workspace.CurrentCamera
    return cam and cam.ViewportSize or Vector2.new(1280, 720)
end

local function mobileNow()
    local vp = viewportSize()
    return vp.X <= 720 or (UserInputService.TouchEnabled and vp.X <= 900)
end

-- ============================================================
-- Independently generated 48x48 alpha bitmap icons.
-- ============================================================
local BASE64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local PACKED_ICONS = {
    ["layout-dashboard"] = "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",
    ["house"] = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEBAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgAABAADAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEABm61zoABQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAUANeX///llAAMBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAgBW7P/58f//gAAAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIBAHD///pcLeb//50NAAMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAwAEmv//7TsAABnK///JGQAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEABHE///OMQAEAwARqf//5TUABQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAMc7//7gRAAQAAAIAAI///+xWAAIBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAwBH7f//mAAAAwAAAAABAwBl+f//cAABAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAIDAGf///9nAAMCAAAAAAAAAAQAO+3//5oEAAMAAAAAAAAAAAAAAAAAAAAAAAAAAwAAmP//7FYAAwEAAAAAAAAAAAAEADHO///EEQAEAAAAAAAAAAAAAAAAAAAAAAAEABGp///aNQAEAAAAAAAAAAAAAAAABAARuP//zjEABAAAAAAAAAAAAAAAAAAAAAMAJcr//8QSAAQAAAAAAAAAAAAAAAAAAAMAAJj//+1HAAMAAAAAAAAAAAAAAAAABQA76///mgQAAwAAAAAAAAAAAAAAAAAAAAACAwBn////ZwADAgAAAAAAAAAAAAEDAGX5//+AAAEDAQEBAQEBAQEBAQEBAQEBAQEBAgQAVuz//5gAAAMAAAAAAAAAAQAAgP//8GIABgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHADXa//+pEQABAAAAAAABAhuc///lNgAFAAkREBEREREREREREREREREREREQEA8AAQASxP//yC4CAQAAAAADAHz//8kZAAUCfODp6urq6urq6urq6urq6urq6urq6eieEwMABJr//7wEAwAAAAABAgfJsxEABwB7////////////////////////////////uQIEAQCD4iMAAgAAAAAAAQANAAADAA3n/Mt+gH5+fn5+fn5+fn5+fn5+fn6Afq77/zYAAwEAEwAAAAAAAAAAAAEAAAEBABLr/3YAAAAAAAAAAAAAAAAAAAAAAAAAADX//kMAAwACAAEAAAAAAAAAAAABAQABABHp/4AECAQEBAQEBAQEBAQEBAQEBAQHBET//0AAAwAAAQAAAAAAAAAAAAAAAAABABHq/34ABAAAAAAAAAEBAQEAAAAAAAADAEH//0EAAwAAAAAAAAAAAAAAAAAAAAABABHq/34ABAAAAAAAAgAAAAADAAAAAAADAEH//0EAAwAAAAAAAAAAAAAAAAAAAAABABHq/34ABAAAAAABAAIREQkAAQAAAAADAEH//0EAAwAAAAAAAAAAAAAAAAAAAAABABHq/34ABAAAAAIANdLq6OJiAAIAAAADAEH//0EAAwAAAAAAAAAAAAAAAAAAAAABABHq/34ABAAAAQEI2v/////+KAACAAADAEH//0EAAwAAAAAAAAAAAAAAAAAAAAABABHq/34ABAAAAQAS7/23lvz/RQADAAADAEH//0EAAwAAAAAAAAAAAAAAAAAAAAABABHq/34ABAAAAQAR6f9mHv/+QAADAAADAEH//0EAAwAAAAAAAAAAAAAAAAAAAAABABHq/34ABAAAAQAR6v9zMv//QQADAAADAEH//0EAAwAAAAAAAAAAAAAAAAAAAAABABHq/34ABAAAAQAR6v9xLv//QQADAAADAEH//0EAAwAAAAAAAAAAAAAAAAAAAAABABHq/34ABAAAAQAR6v9xLv//QQADAAADAEH//0EAAwAAAAAAAAAAAAAAAAAAAAABABHq/34ABAAAAQAR6v9xLv//QQADAAADAEH//0EAAwAAAAAAAAAAAAAAAAAAAAABABHq/4ADBwMDBAMU6v9zMf//QwMGAwMGA0T//0EAAwAAAAAAAAAAAAAAAAAAAAABABHp/3YAAAAAAAAE6f9pI///NwAAAAAAADX//kIAAwAAAAAAAAAAAAAAAAAAAAABABDt/K5BREFBQkFO7/+VY///ckFDQUFEQYH9/z8AAwAAAAAAAAAAAAAAAAAAAAAAAwGi/////////////v3///39////////////2gsBAQAAAAAAAAAAAAAAAAAAAAAAAQEUtv/////////////////////////////UNQACAAAAAAAAAAAAAAAAAAAAAAAAAAAAADVBQUFBQUFBQUFBQUFBQUFBQUFBQT4FAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAABAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMDAwMDAwMDAwMDAwMDAwMDAwMDAwMBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    ["settings"] = "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/4AABAAAAAAABABmPwACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAAAAAAAABABHp/n0ABAAAAAAAAAIAAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAABAwAAAAAAAAABABHq/34ABAAAAAAAAAADAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABHo/X0ABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABL1/4QABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQ8QSAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAwIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    ["sliders-horizontal"] = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAAADAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEABAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEBAQEBAQEBAwBi2OSLAgMCAQEBAQEBAQEBAQEBAQEBAQEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAED/////ewAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQ8REBERERETELf+49X86RwREREREREREREREREREREREBEEAAAAAAAAAAAAAAEAENvq6erq6urq6vv/9e7//uzq6urq6urq6urq6urq6urq6Oo8AAMAAAAAAAAAAAEAE/////////////////////////////////////////////9HAAMAAAAAAAAAAAAACHZ+fn5+fn6Aft/99vL9+IZ+f35+fn5+fn5+fn5+fn5+fX4gAAEAAAAAAAAAAAAAAAAAAAAAAAAAAF3//Pn/oAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQEBAQEBAQFBgOY/v/CFAUGBAQEBAQEBAQEBAQEBAQEBAQBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAALDkBAAEAAAAAAAAAAQEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAQAAAAAAAAADAAADAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgMBAAAAAAAAAAEABAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEBAQEBAQEBAQEBAQEBAQEBAQEBAwBi2OSLAgMCAQEBAQEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAED/////ewAAAAAAAAAAAAAAAAAAAAAAAAAAAQ8REBERERERERERERERERERERETELf+49X86RwREREREBEEAAAAAAAAAAAAAAEAENvq6erq6urq6urq6urq6urq6urq6vv/9e7//uzq6urq6Oo8AAMAAAAAAAAAAAEAE/////////////////////////////////////////////9HAAMAAAAAAAAAAAAACHZ+fn5+fn5+fn5+fn5+fn5+fn6Aft/99vL9+IZ+f35+fX4gAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAF3//Pn/oAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQEBAQEBAQEBAQEBAQEBAQEBAQFBgOY/v/CFAUGBAQEBAQBAAAAAAAAAAAAAAAAAAAAAAAAAAABAQAAAAAAAAAAAAAAAAAALDkBAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMAAAMAAAAAAAAAAAAAAAABAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAEDAAAAAAAAAAAAAAAAAAAAgMBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEBAQEDAGLY5IsCAwIBAQEBAQEBAQEBAQEBAQEBAQEBAQEAAAAAAAAAAAAAAAAAAAAAAAAAQP////97AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQ8REBMQt/7j1fzpHBEREREREREREREREREREREREREREBEEAAAAAAAAAAAAAAEAENvq6erq+//17v/+7Orq6urq6urq6urq6urq6urq6urq6Oo8AAMAAAAAAAAAAAEAE/////////////////////////////////////////////9HAAMAAAAAAAAAAAAACHZ+foB+3/328v34hn5/fn5+fn5+fn5+fn5+fn5+fn5+fX4gAAEAAAAAAAAAAAAAAAAAAAAAXf/8+f+gAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQEBAUGA5j+/8IUBQYEBAQEBAQEBAQEBAQEBAQEBAQEBAQBAAAAAAAAAAAAAAAAAAAAAAAAAAAsOQEAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAwEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    ["panel-left"] = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEAAAAAAAAAAAAAAAAAAAAAAAABAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAgAAAAAAAAAAAAAAAAAAAAEAAAoQEBEREREREREREREREREREREREREREREQEA8AAAEAAAAAAAAAAAAAAAAAAQAamt7p6urq7u7s6urq6urq6urq6urq6urq6urq6eawNwACAAAAAAAAAAAAAAABARnh////////////////////////////////////////+0QAAwAAAAAAAAAAAAADAJz/9qB+gH6H8/69foB+fn5+fn5+fn5+fn5+fn5/f47q/9YGAQAAAAAAAAAAAAEADeP+nwAAAAAA6P90AAAAAAAAAAAAAAAAAAAAAAAAAABh/v02AAMAAAAAAAAAAAEAEuv/eQMJBQQV6v+ABAgEBAQEBAQEBAQEBAQEBAQEBwQ8//9DAAMAAAAAAAAAAAEAEen/fwAEAQAR6v9+AAQAAAAAAAAAAAAAAAAAAAAAAwBC//9AAAMAAAAAAAAAAAEAEer/fgAEAQAR6v9+AAQAAAAAAAAAAAAAAAAAAAAAAwBB//9BAAMAAAAAAAAAAAEAEer/fgAEAQAR6v9+AAQAAAAAAAAAAAAAAAAAAAAAAwBB//9BAAMAAAAAAAAAAAEAEer/fgAEAQAR6v9+AAQAAAAAAAAAAAAAAAAAAAAAAwBB//9BAAMAAAAAAAAAAAEAEer/fgAEAQAR6v9+AAQAAAAAAAAAAAAAAAAAAAAAAwBB//9BAAMAAAAAAAAAAAEAEer/fgAEAQAR6v9+AAQAAAAAAAAAAAAAAAAAAAAAAwBB//9BAAMAAAAAAAAAAAEAEer/fgAEAQAR6v9+AAQAAAAAAAAAAAAAAAAAAAAAAwBB//9BAAMAAAAAAAAAAAEAEer/fgAEAQAR6v9+AAQAAAAAAAAAAAAAAAAAAAAAAwBB//9BAAMAAAAAAAAAAAEAEer/fgAEAQAR6v9+AAQAAAAAAAAAAAAAAAAAAAAAAwBB//9BAAMAAAAAAAAAAAEAEer/fgAEAQAR6v9+AAQAAAAAAAAAAAAAAAAAAAAAAwBB//9BAAMAAAAAAAAAAAEAEer/fgAEAQAR6v9+AAQAAAAAAAAAAAAAAAAAAAAAAwBB//9BAAMAAAAAAAAAAAEAEer/fgAEAQAR6v9+AAQAAAAAAAAAAAAAAAAAAAAAAwBB//9BAAMAAAAAAAAAAAEAEer/fgAEAQAR6v9+AAQAAAAAAAAAAAAAAAAAAAAAAwBB//9BAAMAAAAAAAAAAAEAEer/fgAEAQAR6v9+AAQAAAAAAAAAAAAAAAAAAAAAAwBB//9BAAMAAAAAAAAAAAEAEer/fgAEAQAR6v9+AAQAAAAAAAAAAAAAAAAAAAAAAwBB//9BAAMAAAAAAAAAAAEAEer/fgAEAQAR6v9+AAQAAAAAAAAAAAAAAAAAAAAAAwBB//9BAAMAAAAAAAAAAAEAEer/fgAEAQAR6v9+AAQAAAAAAAAAAAAAAAAAAAAAAwBB//9BAAMAAAAAAAAAAAEAEer/fgAEAQAR6v9+AAQAAAAAAAAAAAAAAAAAAAAAAwBB//9BAAMAAAAAAAAAAAEAEer/fgAEAQAR6v9+AAQAAAAAAAAAAAAAAAAAAAAAAwBB//9BAAMAAAAAAAAAAAEAEer/fgAEAQAR6v9+AAQAAAAAAAAAAAAAAAAAAAAAAwBB//9BAAMAAAAAAAAAAAEAEer/fgAEAQAR6v9+AAQAAAAAAAAAAAAAAAAAAAAAAwBB//9BAAMAAAAAAAAAAAEAEer/fwAEAQAR6v9+AAQAAAAAAAAAAAAAAAAAAAAAAwBC//9BAAMAAAAAAAAAAAEAEer/ewQHBAMU6v+AAwcDAwMDAwMDAwMDAwMDAwMDBgM///9CAAMAAAAAAAAAAAEAEOn+iwAAAAAE6f93AAAAAAAAAAAAAAAAAAAAAAAAAABJ//4/AAMAAAAAAAAAAAADAbf/6GRCQ0FO7/+fQURBQUFBQUFBQUFBQUFBQUFCQ1HO/OoQAQEAAAAAAAAAAAACADT9/////////v3//////////////////////////////2wAAwAAAAAAAAAAAAAAAQBH0f/////////////////////////////////////ibQACAAAAAAAAAAAAAAAAAAIAAjVBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQT4NAAEAAAAAAAAAAAAAAAAAAAADAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAwAAAAAAAAAAAAAAAAAAAAAAAQMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    ["fish"] = "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AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    ["fishing-rod"] = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEDAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAwAAHXcBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAICAAV58P8+AAMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAwAAVtX/7moSAgEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAADe5//+PFQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQELrfv/tCoAAAMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABACf//pJAAADAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAFAHD//34ABAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAU/7/oAEFAwEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAwAt7f/LCgEDAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAhHR/+shAAQAMBoAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEFAKv//0QABgAz/s0RAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAUAj///ZwAEAQEgy//HEQACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABf//+YAAMAAAEAEMf/xxEAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADADTz/8UCAwEAAAACABHH/8gSAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAICEt3/6BYBAgAAAAAAAgARxv/FDAIBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQMCxv/zNgADAQEBAAAAAAIAEdb/PQADAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABACY//9gAAcAAAAAAwMBAAADALb+PgADAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAGf//5AAAAAADw8CAAAAAAACAbz/PgADAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMAOfv/vQAARZvI8vLWqlsRAQACALv/PgADAAAAAAAAAAAAAAAAAAAAAAAAAAAAAwAh7P/TDBu0////8/P///97AAMCALv/PgADAAAAAAAAAAAAAAAAAAAAAAAAAAACABHK/+8mLuf/53wzEREnY78YAAECALv/PgADAAAAAAAAAAAAAAAAAAAAAAAAAAIAEcn//1AJ7P+lGgAAAAAAAAAAAAACALv/PgADAAAAAAAAAAAAAAAAAAAAAAAAAgARyf//ZwC5/6cAAAQCAQECBAEAAAACALv/PgADAAAAAAAAAAAAAAAAAAAAAAACABHJ//9oAET/6BUBAwAAAAAAAAAAAAACALv/PgADAAAAAAAAAAAAAAAAAAAAAAIAEcn//2UAAp3/ewAEAAAAAAAAAAAAAAACALv/PgADAAAAAAAAAAAAAAAAAAAAAgARyf//ZQAGBMv5LAEDAAAAAAAAAAAAAAACALn9PQADAAAAAAAAAAAAAAAAAAACABHJ//9lAAYAEP/9DwABAAAAAAAAAAAAAAACAMP/QQADAAAAAAAAAAAAAAAAAAIAEcn//2UABAAABD4+BAAAAAAAAAAAAAAAAAABADBBEAABAAAAAAAAAAAAAAAAAgARyf//ZQAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACABHJ//9lAAQAAAAAAAMDAAAAAAAAAAAAAAAAAAAAAAIDAQAAAAAAAAAAAAAAAAIAEcn//2UABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQARyf//ZQAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAh/H//9lAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAHv//2UABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgOdcAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    ["hand-heart"] = "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PUF4fX2BvMPCzv+7AAMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMAGMP/+fz8/v////////////z8+NEjAQIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAASY0MDCwo19fX1NPT09Gg0ODgIAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEBAAICAgQEBAQDAwMDAgEBAQEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    ["flame"] = "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AAAAAAACAwBn///9PwECAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABACW4///XOwACAwMDAwQAAJj//+1WAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgAAf/f/938AAAAAAAARuP//2jUABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAICADvX//+1RUJCQ1HN///EEgAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAPm////////////5oEAAMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMAAF219P/////3cQABAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAgAAPEFBQEEnAAEBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMAAAAAAAAAAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAwMDAwMCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    ["fish-symbol"] = "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AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    ["gamepad-2"] = "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AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    ["swords"] = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIDAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgAAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAD9mAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIBQ+//ZAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMAZv/5/2UABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAGT/+v9lAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABl//r/ZQAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAZf/9/2UABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAF30+/9lAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEACvt+/r/ZQAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQANfD////8/2UABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAA17v3/j2D/+v9lAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEADXu/f+aAABm//r/ZQABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQANe79/5oAAwYAZf/7/2kEAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAA17v3/mgADAQAFAGX///AXAQEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEADXu/f+aAAMBAAAABABo5DIAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQANe79/5oAAwEAAAAAAAIAEwABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAA17v3/mgADAQAAAAAAAAABAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEADXu/f+aAAMBAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQANe79/5oAAwEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAA17v3/mgADAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEADXu/f+aAAMBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQANe79/5oAAwEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAA17v//mgADAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEADXu//6NAAMBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQANe7/+NlYAAUAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAA17v//2ub/ZQAFAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEADXu/f+OWv/6/2UABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQANe79/5oAAGX/+v9lAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAA17v3/mgADBQBl//r/ZQAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEADXu/f+aAAMBAAUAZf/6/2UABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQANe79/5oAAwEAAAAEAGX/+v9lAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgA17v3/mgADAQAAAAAABABl//r/ZQAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAT7s/f+aAAMBAAAAAAAAAAQAZf/6/2UAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAADBLz//5oAAwEAAAAAAAAAAAAEAGX/+/9pBAIAAAAAAAAAAAAAAAAAAAAAAAAAAAABARPRowADAQAAAAAAAAAAAAAABABl///wFwEBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAMAgEBAAAAAAAAAAAAAAAAAAQAaOQyAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAACABMAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAQAAAAAAAAAAAAAAAAAAAAAAAQACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    ["badge-dollar-sign"] = "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",
    ["shopping-cart"] = "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AAAAAAAAAwBf+/+VAgIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAKTgAAAAAAAAAAAAAAAEAKTgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAAABAAAAAAAAAAAAAAACAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgMAAAAAAAAAAAAAAAAAAgMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    ["store"] = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAhAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBEBAAAAAAAAAAAAAAAAAAAAAAEGve7q7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs6u3CEgIBAAAAAAAAAAAAAAAAAwA2////////////////////////////////////////dAAEAAAAAAAAAAAAAAAAAwCY/chAQkBAQEBAQEBAQEBAQEBAQEBAQEBAQEBDQJv90QYBAAAAAAAAAAAAAAABAAzk/3EAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADL8/jUAAwAAAAAAAAAAAAAEAFr/7xkDBAMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDBQPE/5gAAwAAAAAAAAAAAAADALH+sAADAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABy/+QMAQEAAAAAAAAAAAICJPT/TQMGAgICAgICAgICAgICAgICAgICAgICAgICBAMb8f9ZAgQAAAAAAAAAAAMAcv/cAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAp/+yAAAAAAAAAAABAA2v6f3rvb69vr6+vr6+vr6+vr6+vr6+vr6+vr6+vr6+vr++2//1vjAAAgAAAAABABP//////////////////////////////////////////////////0cAAwAAAAAAAAQ9QK7+/////////////////////////////////////////9pDPxAAAQAAAAAAAAAAANv/nkFEQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQ0F0+vkoAAAAAAAAAAAAAAEDFO//NQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC6/9FAwQAAAAAAAAAAAEAEOv/QgMGAAACAwMDAwMDAAACAwMDAwMDAAACAwMDBAMT7P8/AAMAAAAAAAAAAAEAEOz/QAADDBEEAAAAAAAADBEEAAAAAAAADBEEAAAAAQAQ7P9AAAMAAAAAAAAAAAEAEOz/QAAAr+46AAMAAAIAr+46AAMAAAIAr+46AAMAAQAQ7P9AAAMAAAAAAAAAAAEAEOz/QAAAvv8/AAMAAAIAvv8/AAMAAAIAvv8/AAMAAQAQ7P9AAAMAAAAAAAAAAAEAEOz/QAAAuv4+AAMAAAIAuv4+AAMAAAIAuv4+AAMAAQAQ7P9AAAMAAAAAAAAAAAEAEOz/QAAAu/8+AAMAAAIAu/8+AAMAAAIAu/8+AAMAAQAQ7P9AAAMAAAAAAAAAAAEAEOz/QAAAu/8+AAMAAAIAu/8+AAMAAAIAu/8+AAMAAQAQ7P9AAAMAAAAAAAAAAAEAEOz/QAAAu/8+AAMAAAIAu/8+AAMAAAIAu/8+AAMAAQAQ7P9AAAMAAAAAAAAAAAEAEOz/QAAAu/8+AAMAAAIAu/8+AAMAAAIAu/8+AAMAAQAQ7P9AAAMAAAAAAAAAAAEAEOz/QAAAu/8+AAMAAAIAu/8+AAMAAAIAu/8+AAMAAQAQ7P9AAAMAAAAAAAAAAAEAEOz/QAAAu/8+AAMAAAIAu/8+AAMAAAIAu/8+AAMAAQAQ7P9AAAMAAAAAAAAAAAEAEOz/QAAAu/8+AAMAAAIAu/8+AAMAAAIAu/8+AAMAAQAQ7P9AAAMAAAAAAAAAAAEAEOz/QAAAu/8+AAMAAAIAu/8+AAMAAAIAu/8+AAMAAQAQ7P9AAAMAAAAAAAAAAAEAEOz/QAAAu/8+AAMAAAIAu/8+AAMAAAIAu/8+AAMAAQAQ7P9AAAMAAAAAAAAAAAEAEOz/QgEBu/8/AQQBAQMBu/8/AQQBAQMBu/8/AQQBAgES7P9AAAMAAAAAAAAAAAEAEOz/NwAAuv87AAAAAAAAuv87AAAAAAAAuv87AAAAAAAH6/5AAAMAAAAAAAAAAAEAD+38cxAQv/9KEBMQEBIQv/9KEBMQEBIQv/9KEBMQEhBB8/8/AAMAAAAAAAAAAAADAaH//uzs+P3w7Ozs7Ozs+P3w7Ozs7Ozs+P3w7Ozs7ez5/9oMAQEAAAAAAAAAAAABARS2////////////////////////////////////////1DUAAgAAAAAAAAAAAAAAAAAANUBAQUFBQEBAQEBAQUFBQEBAQEBAQUFBQEBAQEA+BQABAAAAAAAAAAAAAAAAAAEBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAAAAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    ["repeat-2"] = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgBlQAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAGX/7jUABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAQEBAQEBAQEBAQEBAQEBAQEDAkTt/+01AAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAx6P/uNQACAAAAAAAAAAAAAAAAAAAAAAAAAAEPEBAQEBAQEBAQEBAQEBAQEBAQEBQJRu3/7jYAAgAAAAAAAAAAAAAAAAAAAAABABDc7Ovs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozu5fj9/+UNAQEAAAAAAAAAAAAAAAAAAAABABL9///////////////////////////////9/ewNAQEAAAAAAAAAAAAAAAAAAAAAAAQ8QEBAQEBAQEBAQEBAQEBAQEBAQEM9Uur+/2QBAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEvP//ZQACAAAAAAAAAAAAAAAAAAAAAAAAAAADAwMDAwMDAwMDAwMDAwMDAwMEBSLK//9lAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAwAAAAAAAAAAAAAAAAADAHv//2UABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAgOdcAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgAXeQAAAQAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACABLI/54DAgAAAAAAAAAAAAAAAAACAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAEcr//3IDAwEBAQEBAQEBAQEBAQEBAQEBAQAAAAAAAAAAAAAAAAAAAAAAAAAAAgARyv/8YQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABHK//p2BxUQEBAQEBAQEBAQEBAQEBAQEBAQEAQAAAAAAAAAAAAAAAAAAAAAAAEBCsn/+/3k7uzs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozq7DwAAwAAAAAAAAAAAAAAAAAAAAEBCuH//P///////////////////////////////0UAAwAAAAAAAAAAAAAAAAAAAAACADPu//p2OERAQEBAQEBAQEBAQEBAQEBAQEBAQBAAAQAAAAAAAAAAAAAAAAAAAAAAAgA17v/fKAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQANe3/7kEEBQMDAwMDAwMDAwMDAwMDAwMDAwEAAAAAAAAAAAAAAAAAAAAAAAAAAAAEADXq/7sEAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAA6sxMAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAQEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    ["scroll-text"] = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEDAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgIAAAAAAAAAAAAAAAAAAAAAAAAAAQAACRAQEBAQEBAQEBAQEBAQEBAQEBAQEBAPAAABAAAAAAAAAAAAAAAAAAAAAAABABqa3uvr7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7OvnrzcAAgAAAAAAAAAAAAAAAAAAAAEBGeH///////////////////////////////////tEAAMAAAAAAAAAAAAAAAAAAAMAm//lY0FBQEBAQEBAQEBAQEBAQEBAQEBAQUJQyf/VBgEAAAAAAAAAAAAAAAAAAQAM4/5fAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJfX9NQADAAAAAAAAAAAAAAAAAQAR7f87BAYDAwMDAwMDAwMDAwMDAwMDAwMDAwQDDev/QgADAAAAAAAAAAAAAAAAAQAQ6/9BAAMAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEez/PwADAAAAAAAAAAAAAAAAAQAQ7P9AAAMAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEOz/QAADAAAAAAAAAAAAAAAAAQAQ7P9AAAMAAAICAgICAgICAgICAgICAgIBAAEAEOz/QAADAAAAAAAAAAAAAAAAAQAQ7P9AAAMAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEOz/QAADAAAAAAAAAAAAAAAAAQAQ7P9AAAQADK+7uru7u7u7u7u7u7u7urswAAMAEOz/QAADAAAAAAAAAAAAAAAAAQAQ7P9AAAQAE/////////////////////9HAAQAEOz/QAADAAAAAAAAAAAAAAAAAQAQ7P9AAAMABDo+Pj4+Pj4+Pj4+Pj4+Pj4QAAIAEOz/QAADAAAAAAAAAAAAAAAAAQAQ7P9AAAMAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEOz/QAADAAAAAAAAAAAAAAAAAQAQ7P9AAAMAAAMDAwMDAwMDAwMDAwMDAwMBAAEAEOz/QAADAAAAAAAAAAAAAAAAAQAQ7P9AAAMAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEOz/QAADAAAAAAAAAAAAAAAAAQAQ7P9AAAMAAAICAgICAgICAgICAgICAgIBAAEAEOz/QAADAAAAAAAAAAAAAAAAAQAQ7P9AAAMAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEOz/QAADAAAAAAAAAAAAAAAAAQAQ7P9AAAQADK+7uru7u7u7u7u7u7u7urswAAMAEOz/QAADAAAAAAAAAAAAAAAAAQAQ7P9AAAQAE/////////////////////9HAAQAEOz/QAADAAAAAAAAAAAAAAAAAQAQ7P9AAAMABDo+Pj4+Pj4+Pj4+Pj4+Pj4QAAIAEOz/QAADAAAAAAAAAAAAAAAAAQAQ7P9AAAMAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEOz/QAADAAAAAAAAAAAAAAAAAQAQ7P9AAAMAAAMDAwMDAwMDAwMDAwMDAwMBAAEAEOz/QAADAAAAAAAAAAAAAAAAAQAQ7P9AAAMAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEOz/QAADAAAAAAAAAAAAAAAAAQAQ7P9AAAMAAAICAgICAgICAgICAgEAAAAAAAEAEOz/QAADAAAAAAAAAAAAAAAAAQAQ7P9AAAMAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEOz/QAADAAAAAAAAAAAAAAAAAQAQ7P9AAAQADK+7uru7u7u7u7u6uzAAAgAAAAEAEOz/QAADAAAAAAAAAAAAAAAAAQAQ7P9AAAQAE////////////////0cAAwAAAAEAEOz/QAADAAAAAAAAAAAAAAAAAQAQ7P9AAAMABDo+Pj4+Pj4+Pj4+PhAAAQAAAAEAEOz/QAADAAAAAAAAAAAAAAAAAQAQ7P9AAAMAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEOz/QAADAAAAAAAAAAAAAAAAAQAQ7P9AAAMAAAMDAwMDAwMDAwMDAwEAAAAAAAEAEOz/QAADAAAAAAAAAAAAAAAAAQAQ7P9BAAMAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEez/QAADAAAAAAAAAAAAAAAAAQAQ7P8+AgQBAQEBAQEBAQEBAQEBAQEBAQEBAQICEOv/QQADAAAAAAAAAAAAAAAAAQAP6v5IAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEfH+PgADAAAAAAAAAAAAAAAAAAMBtv/ILRIREBAQEBAQEBAQEBAQEBAQEBAQERMdn/3pEAEBAAAAAAAAAAAAAAAAAAIANf3//Ozt7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozz//9sAAMAAAAAAAAAAAAAAAAAAAABAEfQ////////////////////////////////4W0AAgAAAAAAAAAAAAAAAAAAAAAAAgACNEBAQEBAQEBAQEBAQEBAQEBAQEBAQEA9DQABAAAAAAAAAAAAAAAAAAAAAAAAAAMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMAAAAAAAAAAAAAAAAAAAAAAAAAAAABAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    ["trending-up"] = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEBAQEBAQEBAQEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQ8REBEREREQEQIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAENvq6erq7O7t7s4dAQEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAE/////////////9/AAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACHZ+foJ2sP76+v2AAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAi2/v//P+AAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQIADny//+q5P9/AAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQANe79/5YE6f9+AAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAA17v3/mwAR6/9+AAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEADXu/f+aAAET6v9+AAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQANe79/5oABAAR6P19AAQAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAABAA17v3/mgADAgAS9f+EAAQAAAAAAAAAAAAAAAAAAAAAAAACAAADAAAAAAAAAAAEADXu/f+aAAMBAAAEPEEgAAEAAAAAAAAAAAAAAAAAAAAAAAIAAAMAAwEAAAAAAAQANe79/5oAAwEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAA1y9RHAAACAAAABAA17v3/mgADAQAAAAAAAwMCAAAAAAAAAAAAAAAAAAAAAAAEADXu////jgQABAAEADXu/f+aAAMBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQANe7//+T//8cyAAYANe79/5oAAwEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAA17v3/mhCQ/v/ubwA07v3/mgADAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEADXu/f+aAAAAR+P//6zl//+aAAMBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQANe79/5oAAwIDABqo/////5oAAwEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAA17v3/mgADAQAAAwAAbe3/mAADAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACADXu/f+aAAMBAAAAAAECACM2AAEBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIBPuz9/5oAAwEAAAAAAAAAAwAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMEvP//mgADAQAAAAAAAAAAAAIDAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEBE9GjAAMBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAwCAQEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    ["map-pin"] = "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nf/4KQECAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMAXv/59v6fAAMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEBC+j9+/80AQMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAID//8ACAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABARPR2joBAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEBQABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    ["ship"] = "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7Ozs7Ozs7Ozs7Ozs8v/tNAADAAAAAAAAAAAAAAAAAAIAId///////////////////////////////////+ZSAAQAAAAAAAAAAAAAAAAAAAACAAw+QEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQRQAAwAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAEDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    ["user-round"] = "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AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    ["user"] = "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AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    ["users-round"] = "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AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    ["lock"] = "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AAAAAAAAAAAAAAAAEfH+PgADAAAAAAAAAAAAAAAAAAMBtv/ILRIREBAQEBAQEBAQEBAQEBAQEBAQERMdn/3pEAEBAAAAAAAAAAAAAAAAAAIANf3//Ozt7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozz//9sAAMAAAAAAAAAAAAAAAAAAAABAEfQ////////////////////////////////4W0AAgAAAAAAAAAAAAAAAAAAAAAAAgACNEBAQEBAQEBAQEBAQEBAQEBAQEBAQEA9DQABAAAAAAAAAAAAAAAAAAAAAAAAAAMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMAAAAAAAAAAAAAAAAAAAAAAAAAAAABAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    ["shield-alert"] = "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AAMAj///yREAAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQIAj///yREABQCa//+4EQADAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEDAGX//8kXAJr//5oAAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABQBl///cx///mgADAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAVuv///9/AAIBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEADXe4GMAAwEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAwAKCQADAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    ["scan-search"] = "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AgICAgICAgICBgA47v/x8PQcAAEAAAAAAAAAAAADAF7/5DsAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAALOv7/6EAAwAAAAAAAAAAAAAAAgOa///IvLy7u7u7u7u7u7u7u7u7u7u7u7u7u7u+tvX/yRMCAQAAAAAAAAAAAAAAAQEAe+T///////////////////////////////////SeEgABAAAAAAAAAAAAAAAAAAABAAw8Pj4+Pj4+Pj4+Pj4+Pj4+Pj4+Pj4+Pj4+PhsAAAEAAAAAAAAAAAAAAAAAAAAAAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAQAAAAAAAAAAAAAAAAAAAAAAAAEDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    ["hammer"] = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQEBAQEBAQEBAQEBAQEBAQEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAADAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAhEQEBAQEBAQEBAQEBAQEQkAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgA10uvr7Ozs7Ozs7Ozs7Ozs6uJiAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAQjZ///////////////////////+KgICAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABLw/XBAQkBAQEBAQEBAQEFATO7/OAAFAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABDr/zcAAAAAAAAAAAAAAAAABO39njYABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABDr/z8AAgAAAAAAAAAAAAAAEO7//+01AAQAAAAAAAAAAAAAAAAAAAAAAAAAAAABABHs/kwQExAQEBAQEBAQEBEQIO/8///sNQAEAAAAAAAAAAAAAAAAAAAAAAAAAAABAQzs/+/s7Ozs7Ozs7Ozs7Ozs7f3/auf/7TUABAAAAAAAAAAAAAAAAAAAAAAAAAAAAgBh+f////////////////////+ZADXu/+41AAQAAAAAAAAAAAAAAAAAAAAAAAAAAAEAJ0E/QEBAQEBAQEBAQEBAQDUABQAt5v/tNQAEAAAAAAAAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAABBAAt5/r/7TUABAAAAAAAAAAAAAAAAAAAAAAAAAAAAgMDAwMDAwMDAwMDAwMDAwIEADXw///9/+w1AAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQANe79/5M57v/sNQAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAA17v3/mgAANuz/7DUAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEADXu/f+aAAIFADXs/+s+AQIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQANe79/5oAAwEABAA16v+7BAMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAA17v3/mgADAQAAAAQAOrMTAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEADXu/f+aAAMBAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQANe79/5oAAwEAAAAAAAAAAgEBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAA17v3/mgADAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEADXu/f+aAAMBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQANe79/5oAAwEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAA17v3/mgADAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEADXu/f+aAAMBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQANe79/5oAAwEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAA17v3/mgADAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEADXu/f+aAAMBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIANe79/5oAAwEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgE+7P3/mgADAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAwS8//+aAAMBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQET0aMAAwEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEADAIBAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    ["dices"] = "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AAAAAAAAAAAAAAA2BADJ/z0AAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAwGg/9i7vLu7u7u7u7u7u7yuuMj/2gsBAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQEUtv/////////////////////UNQACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADM+Pj4+Pj4+Pj4+Pj4+PjwFAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAQAAAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMDAwMDAwMDAwMDAwMDAwMBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    ["refresh-cw"] = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQEBAQEAAAAAAAAAAAAAAQEBAQEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAwQDAAAAAAACBAMBAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQMAAAAAAxAQEAkAAAAAAwEAAAABDxAQEQIAAAAAAAAAAAAAAAAAAAAAAAAAAAADAAACOX210uzr7N65jE0NAAADAQAQ3Ozp7r8MAQEAAAAAAAAAAAAAAAAAAAAAAQIABmHO///////////////ffhYAAQIS/f////8/AAMAAAAAAAAAAAAAAAAAAAACAABY0P//+8WNbkFCQF+BuPD//+V8BQAHPEBM7/1BAAMAAAAAAAAAAAAAAAAAAAIADpv//+yJLgAAAAAAAAAAABxy1f//wiYAAAAD6f0/AAMAAAAAAAAAAAAAAAAAAgARyP//pSYAAAEEBAMDAwQEAgAAD4L2/+s1AAQT9/9DAAMAAAAAAAAAAAAAAAABAhHJ//hnAAAEAgAAAAAAAAAAAAEEAAA74//sNAAHPEEQAAEAAAAAAAAAAAAAAAADAKn/8jsAAwIAAAAAAAAAAAAAAAAAAQQAGc//3RIBAAAAAAAAAAAAAAAAAAAAAAMAef/7XwAFAAAAAAAAAAAAAAAAAAAAAAAEAC3r/6gABgMBAAAAAAAAAAAAAAAAAAIBWd+YAAUAAAAAAAAAAAAAAAAAAAAAAAAABABV/f9AAAMAAAAAAAAAAAAAAAAAAAABABINAgEAAAAAAAAAAAAAAAAAAAAAAAAAAAQAvP+8AgIAAAAAAAAAAAAAAAAAAAAAAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMBQP3+NwADAAAAAAAAAAAAAAAAAAAAAAEBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAML/iAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAHr/yQUBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAEb/7A8AAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABzx+jQAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAA7r/0IAAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABDs/0AAAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABTt/T0AAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADADv+8BQAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAWv/1gcBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAK7+mwADAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIBJ/T/SwADAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAnv/VCQEBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgAv9v9eAAMAAAAAAAAAAAAAAAAAAQEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAR/X/80HAgEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABASTV/i0AAgAAAAAAAAAAAAAAAAABDxEEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAZTQACAAAAAAAAAAAAAAAAAQAP3e49AQQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAIAAAAAAAAAAAAAAAAAAQAQ8P8+AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAwAAAAAAAAAAAAAAAAAAAQAQ6f5MEBMEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAS9/3v6uw8AAMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQEJwP////9FAAMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEABT5AP0AQAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQMDAwMBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    ["shuffle"] = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQEBAQEBAQEBAAAAAAAAAAAAAAAAAAEBAQEBAQEBAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABDxAQEBAQEBECAAIAAAAAAAAAAAAAAQ8QEBAQEBARAQABAAAAAAAAAAAAAAAAAQAQ3Ozr7Ozs6+rRNQADAAAAAAAAAAEAENzs6+zt7+3uvQkBAQAAAAAAAAAAAAAAAQAS/f//////////7SEAAwAAAAAAAAEAEv3/////////8w0BAQAAAAAAAAAAAAAAAAAEPEBAQEBBQVTo/8oRAAIAAAAAAAAABDxAQUI9zPv9YwACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABE///JEgICAAAAAAAAAAAAAACM/P+AAAMAAAAAAAAAAAAAAAAAAAAAAwMDAwMDAwYAZf//xgECAQAAAAAAAAMIAJL//5oABAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAGX8/5oAAgEAAAAAAAQAZf7/mgACAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABQCA//+aAAQBAAAABABl//+7AAMBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQQAmv//jwAFAAAFAFT//8kTAgIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAECAJr//mUABAMANez/yREAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAwC7//9lAAA17P/pFgADAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgITyf//SxXu/+w2AAMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAEcn/483/7DUAAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADABbb///zQAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAwDI//7sHQADAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAECAJv/+PD/zBEAAgAAAAABAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQQAmv//czn//8kSAgIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABQCP//+aAQBm///GAQIBAAEPEQQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAGX+/5oAAgQAZfz/mgADAA/d7jwAAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAZf//uwADAQAFAID//5oAAhHw/0EAAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABQBU///JEwICAAABBQDA//+QABXr/kAAAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAADADXs/8kRAAIAAAAAAgE07f//YQDu/0AAAwAAAAAAAAAAAAAAAAAAAQEBAQEBAQQANez/6RYAAwAAAAAAAAIANe7//3Xi/0AAAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAh7f/sNgADAAAAAAAAAAAEADXt///7/0EAAwAAAAAAAAAAAAAAAAABDxAQEBAREiHJ/+o1AAMAAAAAAAAAAAAABAA17f/6/UAAAwAAAAAAAAAAAAAAAQAQ3Ozr7Ozs7PP//0QABQAAAAAAAAAAAAAAAAQANe7//0QAAwAAAAAAAAAAAAAAAQAS/f/////////lZAAEAAAAAAAAAAAAAAAAAAAEADTlxRUBAQAAAAAAAAAAAAAAAAAEPEBAQEBAQEEUAAIAAAAAAAAAAAAAAAAAAAAAAgALAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAAAAAIAAAEAAAAAAAAAAAAAAAAAAAAAAwMDAwMDAwMBAAAAAAAAAAAAAAAAAAAAAAAAAAABAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    ["cloud-sun"] = "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q7O+vLu7u7u7u7u7urswAAIAAAAAAAAAAAAAAAABABP///////////////////////////////////////9HAAMAAAAAAAAAAAAAAAAAAAQ6Pj4+Pj4+Pj4/QEFBQUA/Pj4+Pj4+Pj4+Pj4+Pj4QAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    ["play"] = "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AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQEIvuZrAAAEAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAwsAAQIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    ["toggle-right"] = "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AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    ["type"] = "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AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAwEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    ["list"] = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAAQAAAAAAAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwEAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAWHvlAcCAQAEOj4+Pj4+Pj4+Pj4+Pj4+Pj4+Pj4+Pj4+PhAAAQAAAAAAAAAAAAEAEP/z/0MABAAT/////////////////////////////////0cAAwAAAAAAAAAAAAACBZX/xRYCAgAMr7u6u7u7u7u7u7u7u7u7u7u7u7u7u7u6uzAAAgAAAAAAAAAAAAABAABBDgABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAEAAAAAAgICAgICAgICAgICAgICAgICAgICAgICAgEAAAAAAAAAAAAAAAAAAAADAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAAQAAAAAAAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwEAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAWHvlAcCAQAEOj4+Pj4+Pj4+Pj4+Pj4+Pj4+Pj4+Pj4+PhAAAQAAAAAAAAAAAAEAEP/z/0MABAAT/////////////////////////////////0cAAwAAAAAAAAAAAAACBZX/xRYCAgAMr7u6u7u7u7u7u7u7u7u7u7u7u7u7u7u6uzAAAgAAAAAAAAAAAAABAABBDgABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAEAAAAAAgICAgICAgICAgICAgICAgICAgICAgICAgEAAAAAAAAAAAAAAAAAAAADAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAAQAAAAAAAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwEAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAWHvlAcCAQAEOj4+Pj4+Pj4+Pj4+Pj4+Pj4+Pj4+Pj4+PhAAAQAAAAAAAAAAAAEAEP/z/0MABAAT/////////////////////////////////0cAAwAAAAAAAAAAAAACBZX/xRYCAgAMr7u6u7u7u7u7u7u7u7u7u7u7u7u7u7u6uzAAAgAAAAAAAAAAAAABAABBDgABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAEAAAAAAgICAgICAgICAgICAgICAgICAgICAgICAgEAAAAAAAAAAAAAAAAAAAADAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAAQAAAAAAAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwEAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAWHvlAcCAQAEOj4+Pj4+Pj4+Pj4+Pj4+Pj4+Pj4+Pj4+PhAAAQAAAAAAAAAAAAEAEP/z/0MABAAT/////////////////////////////////0cAAwAAAAAAAAAAAAACBZX/xRYCAgAMr7u6u7u7u7u7u7u7u7u7u7u7u7u7u7u6uzAAAgAAAAAAAAAAAAABAABBDgABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAEAAAAAAgICAgICAgICAgICAgICAgICAgICAgICAgEAAAAAAAAAAAAAAAAAAAADAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    ["palette"] = "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",
    ["keyboard"] = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQAAAAAAAAAAAAAAAAAAAQMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAICAAAAAAAAAAAAAAABAAAJEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQDwAAAQAAAAAAAAAAAAEAGpre6+vs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozr5683AAIAAAAAAAAAAQEZ4f/////////////////////////////////////////////7RAADAAAAAAAAAwCb/+VjQUFAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEFCUMn/1QYBAAAAAAABAAzj/l8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACX1/TUAAwAAAAABABHt/zsEBgMEBAQDAwMEBAQDAwMEBAQDAwMEBAQDAwMEBAQEAw3r/0IAAwAAAAABABDr/0EAAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABHs/z8AAwAAAAABABDs/0AAAwAKEA4AAAAKEA4AAAAKEA4AAAAKEA4AAAAKEA4AABDs/0AAAwAAAAABABDs/0AAAQ3U7Ok1AA/U7Ok1AA/U7Ok1AA/U7Ok1AA/U7Ok1ABPs/0AAAwAAAAABABDs/0AAABH5//9DABT5//9DABT5//9DABT5//9DABT5//9DABPs/0AAAwAAAAABABDs/0AAAwEyQDwHAAEyQDwHAAEyQDwHAAEyQDwHAAEyQDwIABHs/0AAAwAAAAABABDs/0AAAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABDs/0AAAwAAAAABABDs/0AAAwACAwMAAAACAwMAAAACAwMAAAACAwMAAAACAwMBABDs/0AAAwAAAAABABDs/0AAAwABAQEAAAABAQEAAAABAQEAAAABAQEAAAABAQEBABDs/0AAAwAAAAABABDs/0AAAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABDs/0AAAwAAAAABABDs/0AAAwAKEA4AAAAKEA4AAAAKEA4AAAAKEA4AAAAKEA4AABDs/0AAAwAAAAABABDs/0AAAQ3U7Ok1AA/U7Ok1AA/U7Ok1AA/U7Ok1AA/U7Ok1ABPs/0AAAwAAAAABABDs/0AAABH5//9DABT5//9DABT5//9DABT5//9DABT5//9DABPs/0AAAwAAAAABABDs/0AAAwEyQDwHAAEyQDwHAAEyQDwHAAEyQDwHAAEyQDwIABHs/0AAAwAAAAABABDs/0AAAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABDs/0AAAwAAAAABABDs/0AAAwACAwMAAAACAwMAAAACAwMAAAACAwMAAAACAwMBABDs/0AAAwAAAAABABDs/0EAAwABAQEAAAABAQEAAAABAQEAAAABAQEAAAABAQEBABHs/0AAAwAAAAABABDs/z4CBAEAAAABAQEAAAABAQEAAAABAQEAAAABAQEAAAACAhDr/0EAAwAAAAABAA/q/kgAAAAKEQ4AAAAKEQ4AAAAKEQ4AAAAKEQ4AAAAKEQ4AABLx/j4AAwAAAAAAAwG2/8gtEh3W7utAEB7W7utAEB7W7utAEB7W7utAEB7W7utAGqH96RABAQAAAAAAAgA1/f/87O/////z7O7////z7O7////z7O7////z7O7////y8v//bAADAAAAAAAAAAEAR9D//////////////////////////////////////////+FtAAIAAAAAAAAAAAACAAI1QEBBQUFBQEBBQUFBQEBBQUFBQEBBQUFBQEBBQUFAPQ0AAQAAAAAAAAAAAAAAAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAAAAAAAAAAAAAAAAAAEDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    ["info"] = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEBAQEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgQDAgAAAAABAwQCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMDAAAAAA4QEBAAAAAAAQMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAwAAHF+bvOfs6+vFqW4pAAABAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMAAEOf7v/////////////6t10AAAMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAwAanf///+CqfVBAQEV6nNL///+6NwACAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEfj//+2XQ4AAAAAAAAAAARFn/b/+HAAAgEAAAAAAAAAAAAAAAAAAAAAAAAAAAMAZf//4VgAAAADBAMEBAMEAwAAADfF//+ZAAIBAAAAAAAAAAAAAAAAAAAAAAAAAwBl//+3GQACAwEAAAIAAAMAAAEDBAAEj///mgEDAAAAAAAAAAAAAAAAAAAAAAADAET//5kAAAQAAAAAAQADCwABAAAAAAMBAGX7/38ABAAAAAAAAAAAAAAAAAAAAAICGOb/uQADAgAAAAACADTV52EAAgAAAAABBQB///1EAAMAAAAAAAAAAAAAAAAAAAMAnv/mFwECAAAAAAEBCdr//f0qAAIAAAAAAQQBuv/WBgIBAAAAAAAAAAAAAAAAAwA++/1VAAMAAAAAAAEADvH68P85AAMAAAAAAAIAI+3/eAADAAAAAAAAAAAAAAAAAwCj/7sAAwAAAAAAAAADAF/7/5UCAgAAAAAAAAAEAH7/2gkBAQAAAAAAAAAAAAABABjw/1gBBAAAAAAAAAAAAQApOAAAAAAAAAAAAAACASL0/0sAAwAAAAAAAAAAAAAEAF3/4wwBAQAAAAAAAAAAAAIAAAIAAAAAAAAAAAAAAgCv/psAAwAAAAAAAAAAAAADAJ7/pwADAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAFp/9YHAQAAAAAAAAAAAAACAcD/fQAEAAAAAAAAAAAAAAEPEQgAAAAAAAAAAAAAAwBA//AUAAEAAAAAAAAAAAEAD+f/UAADAAAAAAAAAAABABDb7nYABAAAAAAAAAAAAgAd8f09AAMAAAAAAAAAAAEAEO3/PQADAAAAAAAAAAABABHu/4AABAAAAAAAAAAAAQAO6/9BAAMAAAAAAAAAAAEAEOv/QAADAAAAAAAAAAABABHp/n0ABAAAAAAAAAAAAQAQ7P8/AAMAAAAAAAAAAAEAEe3/RQADAAAAAAAAAAABABHq/34ABAAAAAAAAAAAAQAU7f9CAAMAAAAAAAAAAAABBMj/dQAEAAAAAAAAAAABABHq/34ABAAAAAAAAAAAAwA6/vMdAAIAAAAAAAAAAAADAKr/mAADAAAAAAAAAAABABHq/34ABAAAAAAAAAAABAFb/+AKAAEAAAAAAAAAAAAEAG7/1gQBAAAAAAAAAAABABHq/34ABAAAAAAAAAAAAwCc/qwAAwAAAAAAAAAAAAACACf5/UABAwAAAAAAAAABABHq/34ABAAAAAAAAAABARTn/2AABAAAAAAAAAAAAAAAAgG6/qIABAAAAAAAAAABABHq/34ABAAAAAAAAAAEAGH/6BUAAQAAAAAAAAAAAAAABABY//QxAAMAAAAAAAABABHq/34ABAAAAAAAAAEDDdj/mAADAAAAAAAAAAAAAAAAAAIEwP/LBAQBAAAAAAABABHo/X0ABAAAAAAAAAUAk//sGQEBAAAAAAAAAAAAAAAAAAIAMvr/jgAGAQAAAAABABL1/4QABAAAAAAABgBT/P9qAAMAAAAAAAAAAAAAAAAAAAADAG///WUAAwIAAAAAAAQ8QSAAAQAAAAEFADXr/6sABAAAAAAAAAAAAAAAAAAAAAAAAwCa//9/AAAEAgAAAAAAAAAAAAABBAAAV+r/yRECAQAAAAAAAAAAAAAAAAAAAAAAAQIAmf//tiYAAAMEAwIEBAMDBAMAAA+R///JEQACAAAAAAAAAAAAAAAAAAAAAAAAAAECAH/+/+x9KAAAAAAAAAAAAAAXY9T//6gSAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAABAgBH0f//9q1uQR0QEBU+YJvl///mbQAAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQABnzU//////Ts7O7/////5ZkbAAIBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAAAHTpvS7f/////z3qpgFgAAAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQMAAAADFD1AP0AdCQAAAAMBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAwMAAAAAAAAAAAMEAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAQMDAwMCAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    ["history"] = "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ESlRjNT//+1tAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAD3/l/////+zt7P3////1nCcAAgEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAAAWYKre9P////3ouHInAAADAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQMAAAAJHUA/QCgPAAAAAwIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABBAMAAAAAAAAAAgQCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAgMDAwIBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    ["message-circle"] = "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",
    ["music-2"] = "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/8QNAgEAAAECAwMBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAWc/6///efAUAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAAIoPzMJAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAwAAAAAAAwEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAECAwMBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    ["external-link"] = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAQEBAQEBAQEBAQEBAQEBAQEBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEPEBAQEBAQEBAQEBAQEBAQEBECAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABDc7Ovs7Ozs7Ozs7Ozs7O3v7e6/DAEBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABL9////////////////////////PwADAAAAAAAAAAAAAAAAAQEBAQEBAQEBAQEBAQU9QUFBQUFAQEBAQEBDPVLp+/v9QgADAAAAAAAAAAAAAAADAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABLz///r/QQADAAAAAAAAAAAAAAAACQ8PDw8PDw8PDw8PDxASEhISEhEAAAQDBgEUzP//deL/QAADAAAAAAAAAAAAAQJ84/Hy8/Pz8/Pz8/Pz8/Pz8/Pz8u2dFAAEABHJ//9hAO7/QAADAAAAAAAAAAADAHr///Pz8/Pz8/Pz8/Pz8/Pz8/Pz8/j/uQYBEsn//2YAFez/QAADAAAAAAAAAAEBC+r2PQ8RDw8PDw8PDw8PDw8PDw8QEB/V/ysJy///ZQACEOz/QAADAAAAAAAAAAEAEPXyBgAAAAAAAAAAAAAAAAAAAAAAAAC4/k++//9lAAYAEOz/QAADAAAAAAAAAAEAD/LzEQECAQEBAQEBAQEBAQEBAQEBAwPB/+v//2UABAEAEOz/QAADAAAAAAAAAAEAD/PzDwABAAAAAAAAAAAAAAAAAAAAAwC5//7/ZQAEAAEAEOz/QAADAAAAAAAAAAEAD/PzDwABAAAAAAAAAAAAAAAAAAACABLb//5lAAQAAAEAEOz/QAADAAAAAAAAAAEAD/PzDwABAAAAAAAAAAAAAAAAAAIAEcn//3MABQAAAAEAEOz/QAADAAAAAAAAAAEAD/PzDwABAAAAAAAAAAAAAAAAAgARyf/9/zgCAwAAAAEAEOz/QAADAAAAAAAAAAEAD/PzDwABAAAAAAAAAAAAAAACABHJ//vu/0IAAwAAAAEAEOz/QAADAAAAAAAAAAEAD/PzDwABAAAAAAAAAAAAAAIAEcn//1qv/z4AAwAAAAEAEOz/QAADAAAAAAAAAAEAD/PzDwABAAAAAAAAAAAAAgARyf//aAC+/z4AAwAAAAEAEOz/QAADAAAAAAAAAAEAD/PzDwABAAAAAAAAAAABABHJ//9lAAK7/z4AAwAAAAEAEOr9PwADAAAAAAAAAAEAD/PzDwABAAAAAAAAAAECH8f//2UABwC7/z4AAwAAAAEAEff/QwADAAAAAAAAAAEAD/PzDwABAAAAAAAAAAMAe///ZQAFAgC7/z4AAwAAAAAABDxBEAABAAAAAAAAAAEAD/PzDwABAAAAAAAAAAACA51wAAQAAgC7/z4AAwAAAAAAAAAAAAAAAAAAAAAAAAEAD/PzDwABAAAAAAAAAAAAAAAAAgAAAgC7/z4AAwAAAAAAAAMDAQAAAAAAAAAAAAEAD/PzDwABAAAAAAAAAAAAAAICAAAAAgC7/z4AAwAAAAAAAAAAAAAAAAAAAAAAAAEAD/PzDwABAAAAAAAAAAAAAAAAAAAAAgC7/z4AAwAAAAAAAAAAAAAAAAAAAAAAAAEAD/PzDwABAAAAAAAAAAAAAAAAAAAAAgC7/z4AAwAAAAAAAAAAAAAAAAAAAAAAAAEAD/PzDwABAAAAAAAAAAAAAAAAAAAAAgC7/z4AAwAAAAAAAAAAAAAAAAAAAAAAAAEAD/PzDwABAAAAAAAAAAAAAAAAAAAAAgC7/z4AAwAAAAAAAAAAAAAAAAAAAAAAAAEAD/PzDwABAAAAAAAAAAAAAAAAAAAAAgC7/z4AAwAAAAAAAAAAAAAAAAAAAAAAAAEAD/PzDwABAAAAAAAAAAAAAAAAAAAAAgC7/z4AAwAAAAAAAAAAAAAAAAAAAAAAAAEAD/PzDwABAAAAAAAAAAAAAAAAAAAAAgC7/z4AAwAAAAAAAAAAAAAAAAAAAAAAAAEAD/PzEAABAAAAAAAAAAAAAAAAAAAAAgC8/z4AAwAAAAAAAAAAAAAAAAAAAAAAAAEAD/PyDQIDAgICAgICAgICAgICAgICBQC4/j4AAwAAAAAAAAAAAAAAAAAAAAAAAAEADvPzGQAAAAAAAAAAAAAAAAAAAAAAAADH/z0AAwAAAAAAAAAAAAAAAAAAAAAAAAADAaD/2Lu8u7u7u7u7u7u7u7u7u7u8u8j/2gsBAQAAAAAAAAAAAAAAAAAAAAAAAAABARS2///////////////////////////UNQACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMz4+Pj4+Pj4+Pj4+Pj4+Pj4+PjwFAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAwMDAwMDAwMDAwMDAwMDAwMDAwMBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    ["shield-check"] = "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AQIAj///yREAAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQIAj///yREAAgCa//+4EQADAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEDAGX//8kXAJr//5oAAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABQBl///cx///mgADAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAVuv///9/AAIBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEADXe4GMAAwEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAwAKCQADAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    ["code"] = "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TQADAAEAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAQICAMf/PgADAAADAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAC9BEQABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIDAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    ["languages"] = "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AAAAAAABAgMDAgEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    ["copy"] = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAQEBAQEBAQEBAQEBAQEBAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMAAAAAAAAAAAAAAAAAAAAAAAMBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJDw8PDw8PDw8PDw8PDw8PDgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAnzj8fLz8/Pz8/Pz8/Pz8/Py7Z0UAQEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMAev//8/Pz8/Pz8/Pz8/Pz8/Pz+P+5AgIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQEL6vY9DxEPDw8PDw8PDw8PDxAQH9X/NAADAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAQ9fIGAAAAAAAAAAAAAAAAAAAAALf+QQEEAQAAAAAAAAAAAAAAAAAAAAAAAAAAAQAP8vMRAQIBAgUAAAAAAAAAAAAAALv/OgAAAAMBAAAAAAAAAAAAAAAAAAAAAAAAAQAP8/MPAAEAAAAJDw8PDw8PDw8RD7//Sg8SDgAAAAAAAAAAAAAAAAAAAAAAAAAAAQAP8/MPAAEBAnzj8fLz8/Pz8/Pz8/z/9vPy7Z0UAQEAAAAAAAAAAAAAAAAAAAAAAQAP8/MPAAUAev//8/Pz8/Pz8/Pz8/z/9vPy+P+5AgIAAAAAAAAAAAAAAAAAAAAAAQAP8/MPAAEL6vY9DxEPDw8PDw8RD7//Sg8SH9X/NAADAAAAAAAAAAAAAAAAAAAAAQAP8/MPAAAQ9fIGAAAAAAAAAAAAALr/OwABALb+QAADAAAAAAAAAAAAAAAAAAAAAQAP8/MPAAAP8vMRAQIBAQEBAQEDAbv/PwEGArz/PQADAAAAAAAAAAAAAAAAAAAAAQAP8/MPAAAP8/MPAAEAAAAAAAACALv/PgAFALv/PgADAAAAAAAAAAAAAAAAAAAAAQAP8/MPAAAP8/MPAAEAAAAAAAACALv/PgAFALv/PgADAAAAAAAAAAAAAAAAAAAAAQAP8/MPAAAP8/MPAAEAAAAAAAACALv/PgAFALv/PgADAAAAAAAAAAAAAAAAAAAAAQAP8/MPAAAP8/MPAAEAAAAAAAACALv/PgAFALv/PgADAAAAAAAAAAAAAAAAAAAAAQAP8/MPAAAP8/MPAAEAAAAAAAACALv/PgAFALv/PgADAAAAAAAAAAAAAAAAAAAAAQAP8/MPAAAP8/MPAAEAAAAAAAACALv/PgAFALv/PgADAAAAAAAAAAAAAAAAAAAAAQAP8/MPAAAP8/MPAAEAAAAAAAACALv/PgAFALv/PgADAAAAAAAAAAAAAAAAAAAAAQAP8/MPAAAP8/MPAAEAAAAAAAACALv/PgAFALv/PgADAAAAAAAAAAAAAAAAAAAAAQAP8/MPAAAP8/MPAAEAAAAAAAACALv/PgAFALv/PgADAAAAAAAAAAAAAAAAAAAAAQAP8/MPAAAP8/MPAAEAAAAAAAACALv/PgAFALv/PgADAAAAAAAAAAAAAAAAAAAAAQAP8/MQAAAP8/MPAAEAAAAAAAACALz/PgAFALv/PgADAAAAAAAAAAAAAAAAAAAAAQAP8/INAgIR8/MRAgMCAgICAgIFALj+PgAFALv/PgADAAAAAAAAAAAAAAAAAAAAAQAO8/MZAAAE8vIEAAAAAAAAAAAAAMf/PQAFALv/PgADAAAAAAAAAAAAAAAAAAAAAAMBoP/Yu7u//Py/u7u7u7u7u7y7yP/aCwIEALv/PgADAAAAAAAAAAAAAAAAAAAAAAEBFLb//////////////////////9Q1AAICALv/PgADAAAAAAAAAAAAAAAAAAAAAAAAAAAzPz5K9vZKPj8+Pj4+Pj4+PAUAAQACALv/PgADAAAAAAAAAAAAAAAAAAAAAAAAAQEAAAAC8vIDAAAAAAAAAAAAAAACAAACALz/PgADAAAAAAAAAAAAAAAAAAAAAAAAAAADBAMS8/IPBQYFBQUFBQUFBQMCAgIFALj+PgADAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAO8/MZAAAAAAAAAAAAAAAAAAAAAMf/PQADAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMBoP/Yu7y7u7u7u7u7u7u7u7y7yP/aCwEBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEBFLb//////////////////////9Q1AAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAzPj4+Pj4+Pj4+Pj4+Pj4+PAUAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQEAAAAAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAwMDAwMDAwMDAwMDAwMDAwEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    ["panels-top-left"] = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAQEBAQEBAQEBAQEBAQEBAQEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMAAAAAAAAAAAAAAAAAAAAAAAADAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJDw8PDw8PDw8PDw8PDw8PDw4AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAnzj8fLz8/Pz8/Pz8/Pz8/Pz8u2dFAEBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMAev//8/Pz8/Pz8/Pz8/Pz8/Pz8/j/uQICAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQEL6vY9DxEPDw8PDw8PDw8PDw8QEB/V/zQAAwAAAAAAAAAAAAAAAAAAAAAAAAAAAQAQ9fIGAAAAAAAAAAAAAAAAAAAAAAC2/kAAAwAAAAAAAAAAAAAAAAAAAAAAAAAAAQAP8vMRAQIBAQEBAQEBAQEBAQEBAwK8/z0AAwAAAAAAAAAAAAAAAAAAAAAAAAAAAQAP8/MPAAEAAAAAAAAAAAAAAAAAAgC7/z4AAwAAAAAAAAAAAAAAAAAAAAAAAAAAAQAP8/MPAAEAAAAAAAAAAAAAAAAAAgC7/z4AAwAAAAAAAAAAAAAAAAAAAAAAAAAAAQAP8/MPAAEAAAAAAAAAAAAAAAAAAgC7/z4AAwAAAAAAAAAAAAAAAAAAAAAAAAAAAQAP8/MPAAEAAAAAAAAAAAAAAAAAAgC7/z4AAwAAAAAAAAAAAAAAAAAAAAAAAAAAAQAP8/MPAAEAAAAAAAAAAAAAAAAAAgC7/z4AAwAAAAAAAAAAAAAAAAAAAAAAAAAAAQAP8/MPAAEAAAAAAAAAAAAAAAAAAgC7/z4AAwAAAAAAAAAAAAAAAAAAAAAAAAAAAQAP8/MPAAEAAAAAAAAAAAAAAAAAAgC7/z4AAwAAAAAAAAAAAAAAAAAAAAAAAAAAAQAP8/MPAAEAAAAAAAAAAAAAAAAAAgC7/z4AAwAAAAAAAAAAAAAAAAAAAAAAAAAAAQAP8/MPAAEAAAAAAAAAAAAAAAAAAgC7/z4ABAEBAQEBAQEBAQAAAAAAAAAAAAAAAQAP8/MPAAEAAAAAAAAAAAAAAAAAAgC7/z4DAAAAAAAAAAAAAAMBAAAAAAAAAAAAAQAP8/MPAAEAAAAAAAAAAAAAAAAAAgC7/z4ADA8PDw8PDw8PDgAAAAAAAAAAAAAAAQAP8/MPAAEAAAAAAAAAAAAAAAAAAgC7/zpz5PHy8/Pz8/Py7Z0UAQEAAAAAAAAAAQAP8/MQAAEAAAAAAAAAAAAAAAAAAgHA/7v///Pz8/Pz8/Pz+P+5AgIAAAAAAAAAAQAP8/INAgMCAgICAgICAgICAgICBQC7/v/0QA8RDw8PDxAQH9X/NAADAAAAAAAAAQAO8/MZAAAAAAAAAAAAAAAAAAAAAADJ///sCAAAAAAAAAAAALb+QAADAAAAAAAAAAMBoP/Yu7y7u7u7u7u7u7u7u7u8u8n/6fHyEwECAQEBAQEDArz/PQADAAAAAAAAAAEBFLb////////////////////////RQen1DwABAAAAAAACALv/PgADAAAAAAAAAAAAAAAzPj4+Pj4+Pj4+Pj4+Pj4+Pj0EBfXzDwABAAAAAAACALv/PgADAAAAAAAAAAAAAQEAAAAAAAAAAAAAAAAAAAAAAAAAEvPzDwABAAAAAAACALv/PgADAAAAAAAAAAAAAAADAwMDAwMDAwMDAwMDAwMDAwQBD/PzDwABAAAAAAACALv/PgADAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAD/PzDwABAAAAAAACALv/PgADAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAD/PzDwABAAAAAAACALv/PgADAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAD/PzEAABAAAAAAACALz/PgADAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAD/PyDQIDAgICAgIFALj+PgADAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEADvPzGQAAAAAAAAAAAMf/PQADAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAaD/2Lu8u7u7u7y7yP/aCwEBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABARS2/////////////9Q1AAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMz4+Pj4+Pj4+PAUAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEBAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAwMDAwMDAwMDAwEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    ["sparkles"] = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEPEQQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAA/d7jwAAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABDw/0EAAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABDr/kAAAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAQECARHs/0EBBAEBAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAzs/z0AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEPEBAREB/t/0wQExAQEAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABDc7Ovs7O3+//Hs7Ozq7DwAAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABL9/////////////////0UAAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQ8QEBBQEzx/3BAQkBAQBAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAPr/zYAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAwMEAxPs/0IDBgMDAwEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABDs/0AAAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABDq/T8AAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABH3/0MAAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQ8QRAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAwEAAAAAAAAAAAAAAQEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABDxEEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAP3e48AAMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAQ8P9BAAMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAQ6/5AAAMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQEBAgER7P9BAQQBAQEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAM7P89AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABDxAQERAf7f9MEBMQEBAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAQ3Ozr7Ozt/v/x7Ozs6uw8AAMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAS/f////////////////9FAAMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEPEBAQUBM8f9wQEJAQEAQAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD6/82AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAwMDBAMT7P9CAwYDAwMBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAQ7P9AAAMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAQ7P9AAAMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAQ6v0/AAMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAR9/9DAAMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEPEEQAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAwMBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    ["shapes"] = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEBAQEAAAAAAAAAAAAAAAAAAAABAQEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAgAAAAABBAEAAAAAAAAAAAAAAwMAAAACBAAAAAAAAAAAAAAAAAAAAAAAAAAAAQEAAA4PDw8AAAACAAAAAAAAAAADAAAJDw4AAAEBAAAAAAAAAAAAAAAAAAAAAAABAABguu7z8vLIfQ8AAgAAAAAAAAEAQ5vi8eytXAAAAQAAAAAAAAAAAAAAAAAAAAEBE7f///Xz9PP//9g2AAIAAAAAAgF/////8/v//6cTAQEAAAAAAAAAAAAAAAAAAAICuv/VXhQRERFCuP/oFwECAAADAH//+H8pEh1h4P+6AgIAAAAAAAAAAAAAAAAAAwBf/9YSAAAAAAAAAKf/nQADAAMAP/30PQAAAAAAGdX/dwADAAAAAAAAAAAAAAAAAgG//VkABwEBAQEFASP08hIAAQMAnv+BAAYCAQEGAEP/2wYBAAAAAAAAAAAAAAABAA7v9A0BAQAAAAAAAgC+/jsABAAL5vkhAgIAAAAAAgPV/jMAAwAAAAAAAAAAAAABAA/08xAAAQAAAAAAAgG6/z8ABAAQ9vEMAAEAAAAAAgG0/kEAAwAAAAAAAAAAAAABAA/y8xAAAQAAAAAAAgG8/z0ABAAO8PYXAQEAAAAAAgHI/zwAAwAAAAAAAAAAAAABABD08gsAAQAAAAAAAgC4/0AAAwIBsv5gAAYAAAAEACb56A8AAQAAAAAAAAAAAAAAAQTO+zwBBQAAAAADBBHn+BwAAgQAWf/hFgAAAgEAALX/mAADAAAAAAAAAAAAAAAABAB9/7wAAAMCAgMAAIH/vAICAAADBKv/1EcEAAAss//cFQIBAAAAAAAAAAAAAAAAAQIP3P+kKgAAAAAVgP38MgACAAABABG3///WvMn//9g0AAIAAAAAAAAAAAAAAAAAAAIANOX//b+8vLvr//xlAAIAAAAAAQAAe9X////kmBMAAgAAAAAAAAAAAAAAAAAAAAACABmb7v/////5tzcAAwAAAAAAAAEBAAIzPjsMAAACAAAAAAAAAAAAAAAAAAAAAAAAAgAAETs+Pj4cAAADAAAAAAAAAAAAAwAAAAAAAwEAAAAAAAAAAAAAAAAAAAAAAAAAAAEDAAAAAAAAAQIAAAAAAAAAAAAAAAEDAwMBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQMDAwMFBAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgB/nwsCAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAFX//5QABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAICFenx4P9CAAMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQApv9wNf/YDAIBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAwBS/8sGAJL/kAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAhXn+S8ABAzY/kEAAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAKb/fAAEAwBB/tgMAgEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMAUv/LBAMBAAQAkP+QAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgIV5/kvAAMAAAECDNj+QQADAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABACm/30ABQEBAQEEAEL/2QwCAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAFL/xgAAAAAAAAAAAACM/5EAAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEBHej2Pg8SDw8PDw8PEREb2v1AAAMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMAh//97/Pz8/Pz8/Pz8/Px+P/gCgEBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAGd/v8/Pz8/Pz8/Pz8/P07+7BCgEBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA8RDw8PDw8PDw8PDw8PEBEBAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEBAQEBAQEBAQEBAQEBAQEBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    ["badge-check"] = "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",
    ["volleyball"] = "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",
    ["x"] = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAICAAAAAAAAAAAAAAAAAAAAAAAAAgIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgAAAQEAAAAAAAAAAAAAAAAAAAACAAABAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAHCfAAIBAAAAAAAAAAAAAAAAAAQAcJ8AAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAICcf//mQADAQAAAAAAAAAAAAAABABl//+hCwIBAAAAAAAAAAAAAAAAAAAAAAAAAAIDoP/1/5oAAwEAAAAAAAAAAAAEAGX/+P/UEgEBAAAAAAAAAAAAAAAAAAAAAAAAAAECAJr/9v+aAAMBAAAAAAAAAAQAZf/4/8oPAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAABAgCa//b/mgADAQAAAAAABABl//j/yhEAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQMAmv/2/5oAAwEAAAAEAGX/+P/KEQACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEDAJr/9v+aAAMBAAUAZf/4/8oRAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAwCa//b/mgADBgBl//j/yhEAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQMAmv/2/5oAAGb/+P/KEQACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEDAJr/9v+PYP/4/8oRAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAwCa//v///z/yxEAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQMAjv37+/68EgACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAUAX/z6+f+ZAAQBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABQBm//v///r/mwADAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAGX/+P+/mf/3/5oAAwEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAZf/4/8oPAJv/9v+aAAMBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABl//j/yhEABQCa//b/mgADAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAGX/+P/KEQACAQMAmv/2/5oAAwEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAZf/4/8oRAAIAAAEDAJr/9v+aAAMBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABl//j/yhEAAgAAAAABAwCa//b/mgADAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAGX/+P/KEQACAAAAAAAAAQMAmv/2/5oAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAICcf/4/8oRAAIAAAAAAAAAAAEDAJr/9v+iCwIBAAAAAAAAAAAAAAAAAAAAAAAAAAIDoP//yhEAAgAAAAAAAAAAAAABAwCa///TEgEBAAAAAAAAAAAAAAAAAAAAAAAAAAECAKLSEAACAAAAAAAAAAAAAAAAAQMAo9IOAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAIMAAIAAAAAAAAAAAAAAAAAAAEBAgwAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEBAAAAAAAAAAAAAAAAAAAAAAAAAQEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    ["minus"] = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABD1BQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUERAAEAAAAAAAAAAAAAAAAAAAEAEfX///////////////////////////////////9DAAMAAAAAAAAAAAAAAAAAAAEAEv7///////////////////////////////////9FAAMAAAAAAAAAAAAAAAAAAAAACHd/f39/f39/f39/f39/f39/f39/f39/f39/fn8gAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    ["plus"] = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAQEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQREQgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAD3u7ncABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAEL//4EABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAEH+/n4ABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAEH//38ABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAEH//38ABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAEH//38ABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAEH//38ABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAEH//38ABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAEH//38ABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAEH//38ABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMDAwMDAwMDAwMGA0P//4EDBwMDAwMDAwMDAwMBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADf//3gAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABD1BQUFBQUFBQUFEQXL//6BBREFBQUFBQUFBQUERAAEAAAAAAAAAAAAAAAAAAAEAEfX///////////////////////////////////9DAAMAAAAAAAAAAAAAAAAAAAEAEv7///////////////////////////////////9FAAMAAAAAAAAAAAAAAAAAAAAACHd/f39/f39/f3+Bf6D//79/gX9/f39/f39/fn8gAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADP//3UAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQEBAQEBAQEBAQHBET//4EECAQEBAQEBAQEBAQBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAEH//38ABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAEH//38ABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAEH//38ABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAEH//38ABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAEH//38ABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAEH//38ABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAEH//38ABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAEH//38ABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAED9/X4ABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAET//4UABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABFBQSEAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEDAwIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    ["chevron-right"] = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAwIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAAADAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAZUAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgBF//NiAAMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAwBm+f//ZwADAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAO+3//5gAAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEADXa//+dDQADAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAwASyv//yhEAAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMAEan//84xAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAACa///tNgAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgMAcf//8WIAAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEDAGX6//9nAAMBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAA77P//mAAAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQANdr//50NAAMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADABLK///KEQACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAwARqf//zjEAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAAI/6/+kdAQEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAF/7/v8rAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgMAcf//8mAAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAACa///uNgACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMAEan//84xAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAwASyv//yhEAAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEADXa//+dDQADAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAO+z//5gAAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAwBl+v//ZwADAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIDAHH///FiAAMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgAAmv//7TYABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADABGp///OMQAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEsr//8oRAAMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgFD2P//nQ0AAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAwBo//+YAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAm3IAAwEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    ["chevron-down"] = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIDAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgMAAAAAAAAAAAAAAAAAAAAAAAAAAgAAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAAACAAAAAAAAAAAAAAAAAAAAAAACAD9mAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAQAQGYAAQAAAAAAAAAAAAAAAAAAAAIBQ+//ZAAEAAAAAAAAAAAAAAAAAAAAAAAABAA18P9wAgIAAAAAAAAAAAAAAAAAAAMAZv/5/2UABAAAAAAAAAAAAAAAAAAAAAAEADXu/f+gAwIAAAAAAAAAAAAAAAAAAAACAGT/+v9lAAQAAAAAAAAAAAAAAAAAAAQANe79/5oAAgEAAAAAAAAAAAAAAAAAAAAABABl//r/ZQAEAAAAAAAAAAAAAAAABAA17v3/mgACAQAAAAAAAAAAAAAAAAAAAAAAAAQAZf/6/2UABAAAAAAAAAAAAAAEADXu/f+aAAMBAAAAAAAAAAAAAAAAAAAAAAAAAAAEAGX/+v9lAAQAAAAAAAAAAAQANe79/5oAAwEAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABl//r/ZQAEAAAAAAAABAA17v3/mgADAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAZf/6/2UABAAAAAAEADXu/f+aAAMBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAGX/+v9lAAQAAAQANe79/5oAAwEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABl//r/ZQAEBAA17v3/mgADAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAZf/6/2UAADXu/f+aAAMBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAGX/+v9cLe/9/5oAAwEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABl//z88/7/mgADAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAZf////+aAAMBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAGX5/5kAAwEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgApMwABAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    ["check"] = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMAQGYAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgAW6v+UBAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACABHK//5zAgIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAICCsr//48AAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQIAoP//mgAEAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABBACa//+sAAMBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAFAID//8oRAgIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAZf3/yxEAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAIDAAAAAAAAAAAAAAAAAAAABQBg///tIQADAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgAAAgAAAAAAAAAAAAAAAAADADX0/u01AAMAAAAAAAAAAAAAAAAAAAAAAAAAAAACAD9mAAQAAAAAAAAAAAAAAAMANu3//TkAAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAIBQ+//ZAAEAAAAAAAAAAAAAgAV6f//ZQAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMAZv/5/2UABAAAAAAAAAACABHK//9lAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAGT/+v9lAAQAAAAAAAICCsr//48ABQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABl//r/ZQAEAAAAAQIAoP//mgAEAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAZf/6/2UABAABBACa//+sAAMBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAGX/+v9lAAUFAID//8oRAgIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABl//r/ZgAAZf3/yxEAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAZf/6/1lX///tIQADAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAGX//P34/u01AAMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABl//3//TgAAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAZfz6ZAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACACspAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgAAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAICAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
}

local ALIASES = {
    dashboard = "layout-dashboard",
    layout = "layout-dashboard",
    overview = "layout-dashboard",
    home = "house",
    config = "sliders-horizontal",
    tune = "sliders-horizontal",
    close = "x",
    remove = "minus",
    add = "plus",
    back = "chevron-right",
    next = "chevron-right",
    expand = "chevron-down",
    success = "check",
    warning = "shield-alert",
    user = "user-round",
    players = "users-round",
    copy = "copy",
    link = "external-link",
}

local function decodeAlpha(encoded)
    local out, accumulator, bits = {}, 0, 0
    for i = 1, #encoded do
        local c = encoded:sub(i, i)
        if c ~= "=" then
            local p = BASE64:find(c, 1, true)
            if p then
                accumulator = accumulator * 64 + (p - 1)
                bits = bits + 6
                while bits >= 8 do
                    bits = bits - 8
                    out[#out + 1] = string.char(math.floor(accumulator / (2 ^ bits)) % 256)
                end
                accumulator = accumulator % (2 ^ bits)
            end
        end
    end
    return table.concat(out)
end

local cachedEditable = {}

local function createEditableIcon(name)
    if not PACKED_ICONS[name] then name = "info" end
    if cachedEditable[name] then return cachedEditable[name] end
    if not buffer or not buffer.create then return nil end
    local alpha = decodeAlpha(PACKED_ICONS[name])
    if #alpha < 48 * 48 then return nil end

    local ok, editable = pcall(function()
        return AssetService:CreateEditableImage({ Size = Vector2.new(48, 48) })
    end)
    if not ok or not editable then return nil end

    local px = buffer.create(48 * 48 * 4)
    for index = 1, 48 * 48 do
        local off = (index - 1) * 4
        local a = string.byte(alpha, index) or 0
        buffer.writeu8(px, off, 255)
        buffer.writeu8(px, off + 1, 255)
        buffer.writeu8(px, off + 2, 255)
        buffer.writeu8(px, off + 3, a)
    end

    local okWrite = pcall(function()
        editable:WritePixelsBuffer(Vector2.zero, Vector2.new(48, 48), px)
    end)
    if not okWrite then return nil end

    cachedEditable[name] = editable
    return editable
end

local function resolveIcon(name)
    local key = string.lower(tostring(name or "info")):gsub("%s+", "-")
    return ALIASES[key] or key
end

local function icon(parent, name, pos, size, color, z)
    local resolved = resolveIcon(name)
    local img = make("ImageLabel", {
        Name = "Icon_" .. resolved,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = pos or UDim2.fromOffset(0, 0),
        Size = size or UDim2.fromOffset(20, 20),
        ImageColor3 = color or C.muted,
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = z or 20,
    }, parent)

    local editable = createEditableIcon(resolved)
    if editable then
        pcall(function()
            img.ImageContent = Content.fromObject(editable)
        end)
    else
        -- Compact fallback: one Unicode glyph, only used if EditableImage is unavailable.
        img.Visible = false
        local g = make("TextLabel", {
            Name = "IconFallback",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = pos or UDim2.fromOffset(0, 0),
            Size = size or UDim2.fromOffset(20, 20),
            Text = "•",
            TextColor3 = color or C.muted,
            TextSize = 18,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = z or 20,
        }, parent)
    end
    return img
end

local function setIconColor(img, color)
    if img and img:IsA("ImageLabel") then
        img.ImageColor3 = color
    end
end

-- ============================================================
-- Layout helpers
-- ============================================================

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local Section = {}
Section.__index = Section

local function newList(parent, gap)
    return make("UIListLayout", {
        Padding = UDim.new(0, gap or 8),
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, parent)
end

local function controlRow(section, name, height)
    local tab = section._tab
    local row = make("Frame", {
        Name = "Row_" .. tostring(name or "Control"),
        BackgroundColor3 = C.row,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, height or 40),
        LayoutOrder = tab:_nextOrder(),
        ClipsDescendants = false,
        ZIndex = 20,
    }, section._body)
    corner(row, 13)
    stroke(row, C.lineSoft, 0.35, 1)

    local hover = make("Frame", {
        Name = "Hover",
        BackgroundColor3 = C.whiteSoft,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 2,
        Active = false,
    }, row)
    corner(hover, 13)

    local function installHover(hit)
        hit.MouseEnter:Connect(function()
            tween(hover, Motion.hover, {BackgroundTransparency = 0.95})
        end)
        hit.MouseLeave:Connect(function()
            tween(hover, Motion.hover, {BackgroundTransparency = 1})
        end)
    end

    return row, hover, installHover
end

function Tab:_nextOrder()
    self._order = self._order + 1
    return self._order
end

function Section:_labelStart(hasIcon)
    return hasIcon and 42 or 14
end

local function sectionName(value)
    if type(value) == "table" then
        return tostring(value.Title or value.Name or "Section")
    end
    return tostring(value or "Section")
end

function Tab:_isSettings()
    return string.lower(tostring(self._name or "")) == "settings"
end

function Tab:_reflowSettings()
    local win = self._window
    if not self:_isSettings() then return end
    local isMobile = mobileNow()
    local left = self._leftColumn
    local right = self._rightColumn
    if not left or not right then return end

    right.Visible = not isMobile
    for i, section in ipairs(self._settingsSections) do
        local target
        if isMobile then
            target = left
        else
            target = section._side == "Right" and right or section._side == "Left" and left or ((i % 2 == 1) and left or right)
        end
        if section._frame.Parent ~= target then
            section._frame.Parent = target
        end
    end

    local function refresh()
        task.defer(function()
            local h1 = left.AbsoluteSize.Y
            local h2 = right.Visible and right.AbsoluteSize.Y or 0
            self._settingsHost.Size = UDim2.new(1, 0, 0, math.max(h1, h2, 1))
        end)
    end
    refresh()
end

function Window:_applyResponsive()
    local vp = viewportSize()
    local isMobile = mobileNow()
    local minW = isMobile and 330 or 520
    local minH = isMobile and 380 or 420
    local maxW = math.max(minW, vp.X - (isMobile and 12 or 26))
    local maxH = math.max(minH, vp.Y - (isMobile and 18 or 42))

    local targetW = math.clamp(self._userWidth or 760, minW, math.min(860, maxW))
    local targetH = math.clamp(self._userHeight or 540, minH, math.min(680, maxH))
    self._shell.Size = UDim2.fromOffset(targetW, targetH)

    local railW = isMobile and 62 or 196
    self._rail.Size = UDim2.new(0, railW, 1, 0)
    self._content.Position = UDim2.fromOffset(railW, self._topHeight)
    self._content.Size = UDim2.new(1, -railW, 1, -self._topHeight - self._bottomBarHeight)

    self._bottomBar.Position = UDim2.new(0, railW, 1, -self._bottomBarHeight)
    self._bottomBar.Size = UDim2.new(1, -railW, 0, self._bottomBarHeight)

    self._nav.Position = UDim2.fromOffset(isMobile and 6 or 14, isMobile and 70 or 86)
    self._nav.Size = UDim2.new(1, isMobile and -12 or -28, 1, isMobile and -90 or -120)

    self._brandTitle.Visible = not isMobile
    self._brandSub.Visible = not isMobile
    if self._brandMark then
        self._brandMark.Size = UDim2.fromOffset(isMobile and 32 or 34, isMobile and 32 or 34)
        self._brandMark.Position = UDim2.fromOffset(isMobile and 15 or 18, 18)
    end

    for _, tab in ipairs(self._tabs) do
        if tab._button then
            tab._button.Size = UDim2.new(1, 0, 0, 38)
            tab._label.Visible = not isMobile
            if tab._icon then
                tab._icon.Position = isMobile and UDim2.new(0.5, -10, 0.5, -10) or UDim2.fromOffset(10, 9)
            end
        end
        tab:_reflowSettings()
    end
end

function UI:SetTheme(name)
    applyTheme(name)
    for _, win in ipairs(self._windows) do
        win:ApplyTheme()
    end
end

function UI:GetTheme()
    return currentTheme
end

function UI:GetThemes()
    return {"Bento"}
end

function UI:DestroyAll()
    for _, win in ipairs(self._windows) do
        pcall(function() win:Destroy() end)
    end
    self._windows = {}
end

function UI:Notify(config)
    config = config or {}
    local parent = GuiParent
    if not self._notificationGui or not self._notificationGui.Parent then
        self._notificationGui = make("ScreenGui", {
            Name = "KhfreshNotifications",
            ResetOnSpawn = false,
            IgnoreGuiInset = true,
            DisplayOrder = 2147483640,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        }, parent)
    end
    local host = self._notificationGui:FindFirstChild("Host")
    if not host then
        host = make("Frame", {
            Name = "Host",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -14, 1, -14),
            Size = UDim2.fromOffset(330, 400),
        }, self._notificationGui)
        newList(host, 8)
        host.UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        host.UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    end

    local holder = make("CanvasGroup", {
        Name = "Notice",
        GroupTransparency = 1,
        BackgroundColor3 = C.header,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(320, 70),
        LayoutOrder = -math.floor(os.clock() * 1000),
    }, host)
    corner(holder, 16)
    stroke(holder, C.line, 0.25, 1)
    local mark = make("Frame", {
        BackgroundColor3 = C.raised,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(12, 13),
        Size = UDim2.fromOffset(44, 44),
        ZIndex = 10,
    }, holder)
    corner(mark, 12)
    icon(mark, config.Icon or "info", UDim2.fromOffset(10, 10), UDim2.fromOffset(24, 24), C.muted, 12)

    local t = label(holder, config.Title or "Khfresh", 13, C.text, true)
    t.Position = UDim2.fromOffset(68, 11); t.Size = UDim2.new(1, -82, 0, 20)
    local d = label(holder, config.Content or config.Message or "", 11, C.secondary, false)
    d.Position = UDim2.fromOffset(68, 33); d.Size = UDim2.new(1, -82, 0, 28)
    d.TextWrapped = true; d.TextYAlignment = Enum.TextYAlignment.Top

    tween(holder, Motion.pop, {GroupTransparency = 0})
    task.delay(tonumber(config.Duration) or 4, function()
        if holder.Parent then
            tween(holder, Motion.exit, {GroupTransparency = 1, Position = holder.Position + UDim2.fromOffset(16, 0)})
            task.delay(0.22, function()
                pcall(function() holder:Destroy() end)
            end)
        end
    end)
    return holder
end

function UI:CreateWindow(config)
    config = config or {}
    self:DestroyAll()
    applyTheme(config.Theme or "Bento")

    local vp = viewportSize()
    local mobile = mobileNow()
    local requested = config.Size or UDim2.fromOffset(760, 540)
    local initialW = requested.X.Offset
    local initialH = requested.Y.Offset
    if mobile then
        initialW = math.min(initialW, vp.X - 12)
        initialH = math.min(initialH, vp.Y - 18)
    end

    local sg = make("ScreenGui", {
        Name = "KhfreshPanel",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 2147483645,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, GuiParent)
    pcall(function()
        if syn and syn.protect_gui then syn.protect_gui(sg) end
    end)

    local viewport = make("Frame", {
        Name = "Viewport",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ClipsDescendants = false,
    }, sg)

    local shadow = make("Frame", {
        Name = "ContactDepth",
        BackgroundColor3 = Color3.new(0,0,0),
        BackgroundTransparency = 0.76,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5) + UDim2.fromOffset(0, 7),
        Size = UDim2.fromOffset(initialW + 10, initialH + 10),
        ZIndex = 1,
    }, viewport)
    corner(shadow, 20)

    local shell = make("CanvasGroup", {
        Name = "Panel",
        BackgroundColor3 = C.shell,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5) + UDim2.fromOffset(0, 12),
        Size = UDim2.fromOffset(initialW, initialH),
        ClipsDescendants = true,
        GroupTransparency = 1,
        ZIndex = 2,
    }, viewport)
    corner(shell, 18)
    stroke(shell, C.line, 0.22, 1)

    local bg
    if type(config.Background) == "string" and config.Background ~= "" then
        bg = make("ImageLabel", {
            Name = "Background",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1),
            Image = config.Background,
            ImageTransparency = tonumber(config.BackgroundImageTransparency) or 0.62,
            ScaleType = Enum.ScaleType.Crop,
            ZIndex = 3,
        }, shell)
    end

    local bgShade = make("Frame", {
        Name = "BackgroundShade",
        BackgroundColor3 = C.canvas,
        BackgroundTransparency = 0.90,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 4,
    }, shell)

    local topHeight = 70
    local bottomHeight = 22

    local rail = make("Frame", {
        Name = "Rail",
        BackgroundColor3 = C.rail,
        BorderSizePixel = 0,
        Size = UDim2.new(0, mobile and 62 or 196, 1, 0),
        ZIndex = 8,
        ClipsDescendants = true,
    }, shell)
    corner(rail, 18)

    local railFill = make("Frame", {
        Name = "RailFill",
        BackgroundColor3 = C.rail,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -18, 0, 0),
        Size = UDim2.new(0, 18, 1, 0),
        ZIndex = 8,
    }, rail)
    corner(railFill, 14)

    make("Frame", {
        BackgroundColor3 = C.lineSoft,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -1, 0, 0),
        Size = UDim2.new(0, 1, 1, 0),
        ZIndex = 9,
    }, rail)

    local brandMark = make("ImageLabel", {
        Name = "BrandMark",
        BackgroundColor3 = C.raised,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(mobile and 15 or 18, 18),
        Size = UDim2.fromOffset(mobile and 32 or 34, mobile and 32 or 34),
        Image = type(config.Logo) == "string" and config.Logo or "",
        ImageTransparency = type(config.Logo) == "string" and 0 or 1,
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = 10,
    }, rail)
    corner(brandMark, 10)
    stroke(brandMark, C.line, 0.22, 1)

    local brandTitle = label(rail, config.Title or "Khfresh Hub", 13, C.text, true)
    brandTitle.Position = UDim2.fromOffset(62, 14)
    brandTitle.Size = UDim2.new(1, -72, 0, 22)
    local brandSub = label(rail, config.Author or "Bento Grid", 9, C.muted, false)
    brandSub.Position = UDim2.fromOffset(62, 36)
    brandSub.Size = UDim2.new(1, -72, 0, 16)

    local nav = make("ScrollingFrame", {
        Name = "Navigation",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(mobile and 6 or 14, mobile and 70 or 86),
        Size = UDim2.new(1, mobile and -12 or -28, 1, mobile and -90 or -120),
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ScrollBarThickness = 2,
        ScrollBarImageTransparency = 1,
        ClipsDescendants = true,
        ZIndex = 10,
    }, rail)
    newList(nav, 5)
    padding(nav, 0, 0, 0, 8)

    local content = make("Frame", {
        Name = "ContentViewport",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(mobile and 62 or 196, topHeight),
        Size = UDim2.new(1, -(mobile and 62 or 196), 1, -(topHeight + bottomHeight)),
        ClipsDescendants = true,
        ZIndex = 6,
    }, shell)

    local top = make("Frame", {
        Name = "TopBar",
        BackgroundColor3 = C.header,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(mobile and 62 or 196, 0),
        Size = UDim2.new(1, -(mobile and 62 or 196), topHeight),
        ZIndex = 12,
    }, shell)
    corner(top, 18)
    make("Frame", {
        BackgroundColor3 = C.lineSoft,
        BackgroundTransparency = 0.30,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -1),
        Size = UDim2.new(1, 0, 0, 1),
        ZIndex = 13,
    }, top)

    local headerIcon = icon(top, config.Icon or "layout-dashboard", UDim2.fromOffset(18, 22), UDim2.fromOffset(22, 22), C.muted, 14)
    local pageTitle = label(top, config.Title or "Khfresh Hub", 18, C.text, true)
    pageTitle.Position = UDim2.fromOffset(50, 11)
    pageTitle.Size = UDim2.new(1, -150, 0, 28)
    local context = label(top, config.Author or "Khfresh Hub", 10, C.muted, false)
    context.Position = UDim2.fromOffset(50, 39)
    context.Size = UDim2.new(1, -150, 0, 18)

    local function topButton(name, x, glyph)
        local b = make("TextButton", {
            Name = name,
            BackgroundColor3 = C.raised,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(32, 32),
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, x, 0.5, 0),
            Text = "",
            AutoButtonColor = false,
            ZIndex = 20,
        }, top)
        corner(b, 10)
        stroke(b, C.lineSoft, 0.34, 1)
        icon(b, glyph, UDim2.fromOffset(7, 7), UDim2.fromOffset(18, 18), C.secondary, 22)
        return b
    end

    local minimizeButton = topButton("MinimizeButton", -48, "minus")
    local closeButton = topButton("CloseButton", -10, "x")

    local bottomBar = make("Frame", {
        Name = "BottomBar",
        BackgroundColor3 = C.rail,
        BorderSizePixel = 0,
        Position = UDim2.new(0, mobile and 62 or 196, 1, -bottomHeight),
        Size = UDim2.new(1, -(mobile and 62 or 196), 0, bottomHeight),
        ZIndex = 15,
    }, shell)
    corner(bottomBar, 16)

    local dragHit = make("TextButton", {
        Name = "DragHandle",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(110, 22),
        Text = "",
        AutoButtonColor = false,
        ZIndex = 30,
    }, bottomBar)
    make("Frame", {
        BackgroundColor3 = C.muted,
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(56, 3),
        ZIndex = 31,
    }, dragHit).Parent = dragHit

    local resize = make("TextButton", {
        Name = "ResizeHandle",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.fromScale(1, 1),
        Size = UDim2.fromOffset(30, 30),
        Text = "",
        AutoButtonColor = false,
        ZIndex = 50,
    }, shell)

    for i = 0, 2 do
        make("Frame", {
            BackgroundColor3 = C.muted,
            BackgroundTransparency = 0.15 + i * 0.1,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(11 + i * 4, 1),
            Position = UDim2.new(1, -13 - i * 4, 1, -7 - i * 4),
            Rotation = -45,
            ZIndex = 51,
        }, resize)
    end

    local overlay = make("Frame", {
        Name = "OverlayLayer",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        Active = false,
        ZIndex = 100,
    }, sg)

    local launcher = make("CanvasGroup", {
        Name = "KhfreshFloating",
        GroupTransparency = 1,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(54, 54),
        Position = UDim2.new(1, -18, 1, -18),
        AnchorPoint = Vector2.new(1, 1),
        Visible = false,
        ZIndex = 200,
    }, sg)
    local launcherButton = make("TextButton", {
        Name = "Button",
        BackgroundColor3 = C.raised,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        Text = "",
        AutoButtonColor = false,
        ZIndex = 201,
    }, launcher)
    corner(launcherButton, 16)
    stroke(launcherButton, C.line, 0.18, 1)
    icon(launcherButton, "volleyball", UDim2.fromOffset(13, 13), UDim2.fromOffset(28, 28), C.secondary, 203)

    local window = setmetatable({
        _gui = sg,
        _viewport = viewport,
        _shell = shell,
        _shadow = shadow,
        _panelScale = make("UIScale", {Scale = 1}, shell),
        _rail = rail,
        _nav = nav,
        _content = content,
        _top = top,
        _topHeight = topHeight,
        _bottomBar = bottomBar,
        _bottomBarHeight = bottomHeight,
        _pageTitle = pageTitle,
        _context = context,
        _headerIcon = headerIcon,
        _brandMark = brandMark,
        _brandTitle = brandTitle,
        _brandSub = brandSub,
        _background = bg,
        _backgroundShade = bgShade,
        _overlay = overlay,
        _launcher = launcher,
        _launcherButton = launcherButton,
        _tabs = {},
        _active = nil,
        _open = true,
        _floatingVisible = true,
        _connections = {},
        _pageTweens = {},
        _userWidth = initialW,
        _userHeight = initialH,
        _keybind = config.Keybind or Enum.KeyCode.RightAlt,
        _resizeBusy = false,
    }, Window)

    table.insert(self._windows, window)

    local dragging = false
    local dragStart
    local startPosition

    local function beginDrag(input)
        dragging = true
        dragStart = input.Position
        startPosition = shell.Position
    end

    local function updateDrag(input)
        if not dragging then return end
        local delta = input.Position - dragStart
        local vp2 = viewportSize()
        local halfW = shell.AbsoluteSize.X * 0.5
        local halfH = shell.AbsoluteSize.Y * 0.5
        local newX = startPosition.X.Offset + delta.X
        local newY = startPosition.Y.Offset + delta.Y
        newX = math.clamp(newX, -vp2.X * 0.5 + 20 - halfW, vp2.X * 0.5 - 20 + halfW)
        newY = math.clamp(newY, -vp2.Y * 0.5 + 20 - halfH, vp2.Y * 0.5 - 20 + halfH)
        shell.Position = UDim2.new(0.5, newX, 0.5, newY)
    end

    for _, handle in ipairs({top, dragHit}) do
        table.insert(window._connections, handle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                beginDrag(input)
            end
        end))
    end

    table.insert(window._connections, UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateDrag(input)
        end
    end))
    table.insert(window._connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))

    local resizing = false
    local resizeStart
    local startW, startH
    resize.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        resizing = true
        resizeStart = input.Position
        startW, startH = shell.AbsoluteSize.X, shell.AbsoluteSize.Y
    end)
    table.insert(window._connections, UserInputService.InputChanged:Connect(function(input)
        if not resizing then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local dx = input.Position.X - resizeStart.X
        local dy = input.Position.Y - resizeStart.Y
        local vp3 = viewportSize()
        local isMob = mobileNow()
        local minW = isMob and 330 or 520
        local minH = isMob and 380 or 420
        local maxW = vp3.X - (isMob and 12 or 26)
        local maxH = vp3.Y - (isMob and 18 or 42)
        window._userWidth = math.clamp(startW + dx, minW, math.min(860, maxW))
        window._userHeight = math.clamp(startH + dy, minH, math.min(680, maxH))
        window:_applyResponsive()
    end))
    table.insert(window._connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = false
        end
    end))

    table.insert(window._connections, workspace.CurrentCamera and workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        window:_applyResponsive()
    end) or Instance.new("BindableEvent").Event:Connect(function() end))

    bindActivated(closeButton, function() window:Destroy() end)
    bindActivated(minimizeButton, function() window:Minimize() end)
    bindActivated(launcherButton, function() window:Open() end)

    table.insert(window._connections, UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == window._keybind and not UserInputService:GetFocusedTextBox() then
            window:Toggle()
        end
    end))

    window:_applyResponsive()
    tween(shell, Motion.enter, {
        Position = UDim2.fromScale(0.5, 0.5),
        GroupTransparency = 0,
    })
    tween(shadow, Motion.enter, {
        BackgroundTransparency = 0.76,
        Position = UDim2.new(0.5, 0, 0.5, 7),
    })

    return window
end

function Window:CreateTab(nameOrConfig, iconName)
    local title, iconKey
    if type(nameOrConfig) == "table" then
        title = tostring(nameOrConfig.Title or nameOrConfig.Name or "Tab")
        iconKey = nameOrConfig.Icon or iconName
    else
        title = tostring(nameOrConfig or "Tab")
        iconKey = iconName
    end
    iconKey = iconKey or title

    local index = #self._tabs + 1
    local button = make("TextButton", {
        Name = "Tab_" .. title:gsub("[^%w_]+", "_"),
        BackgroundColor3 = C.raised,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 38),
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = index,
        ZIndex = 12,
    }, self._nav)
    corner(button, 15)

    local iconHolder = make("Frame", {
        Name = "IconHolder",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(10, 9),
        Size = UDim2.fromOffset(20, 20),
        ZIndex = 13,
    }, button)
    local iconImage = icon(iconHolder, iconKey, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), C.muted, 14)
    local tabLabel = label(button, title, 12, C.secondary, true)
    tabLabel.Position = UDim2.fromOffset(40, 0)
    tabLabel.Size = UDim2.new(1, -48, 1, 0)

    local page = make("CanvasGroup", {
        Name = "Page_" .. title:gsub("[^%w_]+", "_"),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.fromScale(1, 1),
        GroupTransparency = 1,
        Visible = false,
        ZIndex = 7,
    }, self._content)

    local scroll = make("ScrollingFrame", {
        Name = "Scroll",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, -16, 1, 0),
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = C.muted,
        ScrollBarImageTransparency = 0.25,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ElasticBehavior = Enum.ElasticBehavior.WhenScrollable,
        ClipsDescendants = true,
        ZIndex = 8,
    }, page)
    padding(scroll, 18, 8, 14, 18)

    local tab = setmetatable({
        _window = self,
        _name = title,
        _button = button,
        _icon = iconImage,
        _label = tabLabel,
        _page = page,
        _scroll = scroll,
        _order = 0,
        _settingsSections = {},
        _settingsMode = string.lower(title) == "settings",
    }, Tab)

    if tab:_isSettings() then
        local host = make("Frame", {
            Name = "SettingsHost",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 1),
            AutomaticSize = Enum.AutomaticSize.Y,
        }, scroll)
        local left = make("Frame", {
            Name = "LeftColumn",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(0.5, -5, 0, 1),
            AutomaticSize = Enum.AutomaticSize.Y,
        }, host)
        local right = make("Frame", {
            Name = "RightColumn",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(0.5, 5, 0, 0),
            Size = UDim2.new(0.5, -5, 0, 1),
            AutomaticSize = Enum.AutomaticSize.Y,
        }, host)
        local l = newList(left, 10)
        local r = newList(right, 10)
        tab._settingsHost = host
        tab._leftColumn = left
        tab._rightColumn = right
        tab._leftLayout = l
        tab._rightLayout = r
        local function refreshSettingsHost()
            task.defer(function()
                local a = left.AbsoluteSize.Y
                local b = right.Visible and right.AbsoluteSize.Y or 0
                host.Size = UDim2.new(1, 0, 0, math.max(a, b, 1))
            end)
        end
        l:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refreshSettingsHost)
        r:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refreshSettingsHost)
    else
        local listHost = make("Frame", {
            Name = "ListHost",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 1),
            AutomaticSize = Enum.AutomaticSize.Y,
        }, scroll)
        newList(listHost, 9)
        tab._listHost = listHost
    end

    table.insert(self._tabs, tab)

    bindActivated(button, function()
        self:_select(tab)
    end)
    button.MouseEnter:Connect(function()
        if self._active ~= tab then
            tween(button, Motion.hover, {BackgroundTransparency = 0.88})
        end
    end)
    button.MouseLeave:Connect(function()
        if self._active ~= tab then
            tween(button, Motion.hover, {BackgroundTransparency = 1})
        end
    end)

    if not self._active then
        self:_select(tab, true)
    end
    self:_applyResponsive()
    return tab
end

function Window:GetTab(title)
    local wanted = string.lower(tostring(title or ""))
    for _, tab in ipairs(self._tabs) do
        if string.lower(tab._name) == wanted then return tab end
    end
    return nil
end

function Window:_select(tab, instant)
    if not tab then return end
    self._active = tab
    self._pageTitle.Text = tab._name
    self._context.Text = string.upper(tab._name) .. "  /  KHFRESH"
    for _, other in ipairs(self._tabs) do
        local selected = other == tab
        other._page.Visible = selected
        if selected then
            other._page.Position = UDim2.fromOffset(0, 0)
            other._page.GroupTransparency = 0
        else
            other._page.Position = UDim2.fromOffset(12, 0)
            other._page.GroupTransparency = 1
        end
        tween(other._button, Motion.fast, {
            BackgroundColor3 = selected and C.accentSoft or C.raised,
            BackgroundTransparency = selected and 0 or 1,
        })
        setIconColor(other._icon, selected and C.accent or C.muted)
        other._label.TextColor3 = selected and C.text or C.secondary
    end
    if not instant then
        tab._page.GroupTransparency = 1
        tab._page.Position = UDim2.fromOffset(12, 0)
        tween(tab._page, Motion.enter, {GroupTransparency = 0, Position = UDim2.fromOffset(0, 0)})
    end
end

function Window:SelectTab(index)
    local idx = tonumber(index)
    if idx then
        self:_select(self._tabs[idx])
    else
        local tab = self:GetTab(index)
        if tab then self:_select(tab) end
    end
end

function Window:SetBackground(asset, transparency)
    if type(asset) ~= "string" or asset == "" then return end
    if self._background and self._background.Parent then
        self._background.Image = asset
        self._background.ImageTransparency = tonumber(transparency) or 0.62
        return
    end
    self._background = make("ImageLabel", {
        Name = "Background",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        Image = asset,
        ImageTransparency = tonumber(transparency) or 0.62,
        ScaleType = Enum.ScaleType.Crop,
        ZIndex = 3,
    }, self._shell)
end

function Window:SetLogo(asset)
    if not self._brandMark then return end
    if type(asset) == "string" and asset ~= "" then
        self._brandMark.Image = asset
        self._brandMark.ImageTransparency = 0
    end
end

function Window:SetFloatingVisible(value)
    self._floatingVisible = value == true
    if self._floatingVisible then
        if not self._open then
            self:_showLauncher()
        end
    else
        self:_hideLauncher()
    end
end

function Window:_showLauncher()
    if not self._floatingVisible or self._open then return end
    self._launcher.Visible = true
    self._launcher.GroupTransparency = 1
    local scale = self._launcher:FindFirstChildOfClass("UIScale") or make("UIScale", {Scale = 0.88}, self._launcher)
    scale.Scale = 0.88
    tween(self._launcher, Motion.pop, {GroupTransparency = 0})
    tween(scale, Motion.pop, {Scale = 1})
end

function Window:_hideLauncher()
    if not self._launcher then return end
    tween(self._launcher, Motion.exit, {GroupTransparency = 1})
    task.delay(0.21, function()
        if self._launcher and self._launcher.Parent and self._open then
            self._launcher.Visible = false
        end
    end)
end

function Window:Minimize()
    if not self._open then return end
    self._open = false
    tween(self._shell, Motion.exit, {
        Position = UDim2.fromScale(0.5, 0.5) + UDim2.fromOffset(0, 10),
        GroupTransparency = 1,
    })
    tween(self._panelScale, Motion.exit, {Scale = 0.975})
    tween(self._shadow, Motion.exit, {BackgroundTransparency = 1})
    task.delay(0.21, function()
        if not self._open and self._shell then
            self._shell.Visible = false
            self:_showLauncher()
        end
    end)
end

function Window:Open()
    if self._open then return end
    self._open = true
    self:_hideLauncher()
    self._shell.Visible = true
    self._shell.GroupTransparency = 1
    self._shell.Position = UDim2.fromScale(0.5, 0.5) + UDim2.fromOffset(0, 10)
    self._panelScale.Scale = 0.975
    self._shadow.BackgroundTransparency = 1
    tween(self._shell, Motion.enter, {Position = UDim2.fromScale(0.5, 0.5), GroupTransparency = 0})
    tween(self._panelScale, Motion.pop, {Scale = 1})
    tween(self._shadow, Motion.enter, {BackgroundTransparency = 0.76})
end

function Window:Toggle()
    if self._open then self:Minimize() else self:Open() end
end

function Window:Destroy()
    for _, c in ipairs(self._connections) do pcall(function() c:Disconnect() end) end
    if self._gui then pcall(function() self._gui:Destroy() end) end
    if self._launcher and self._launcher.Parent then pcall(function() self._launcher:Destroy() end) end
end

function Window:ToggleAcrylic() end

function Window:ApplyTheme()
    self._shell.BackgroundColor3 = C.shell
    self._rail.BackgroundColor3 = C.rail
    self._top.BackgroundColor3 = C.header
    if self._backgroundShade then self._backgroundShade.BackgroundColor3 = C.canvas end
    for _, tab in ipairs(self._tabs) do
        local selected = tab == self._active
        tab._button.BackgroundColor3 = selected and C.accentSoft or C.raised
        setIconColor(tab._icon, selected and C.accent or C.muted)
    end
end

-- ============================================================
-- TAB / SECTION
-- ============================================================

function Tab:CreateHeader(config)
    config = type(config) == "table" and config or {Title = tostring(config or "")}
    local parent = self._isSettings and self._leftColumn or self._listHost
    local frame = make("Frame", {
        Name = "Header_" .. tostring(config.Title or "Header"):gsub("[^%w_]+", "_"),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 62),
        LayoutOrder = self:_nextOrder(),
        ZIndex = 18,
    }, parent)
    local eyebrow = label(frame, "KHFRESH HUB", 9, C.muted, true)
    eyebrow.Position = UDim2.fromOffset(0, 0); eyebrow.Size = UDim2.new(1, 0, 0, 14)
    local title = label(frame, config.Title or "Overview", 21, C.text, true)
    title.Position = UDim2.fromOffset(0, 15); title.Size = UDim2.new(1, -30, 0, 28)
    local sub = label(frame, config.Subtitle or config.Desc or "", 11, C.secondary, false)
    sub.Position = UDim2.fromOffset(0, 44); sub.Size = UDim2.new(1, -20, 0, 17)
    return frame
end

function Tab:CreateSection(nameOrConfig, side)
    local name = sectionName(nameOrConfig)
    local cfg = type(nameOrConfig) == "table" and nameOrConfig or {}
    side = side or cfg.Side

    local isSettings = self:_isSettings()

    local frame = make("Frame", {
        Name = "Section_" .. name:gsub("[^%w_]+", "_"),
        BackgroundColor3 = isSettings and C.raised or Color3.new(0,0,0),
        BackgroundTransparency = isSettings and 0.08 or 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 1),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = self:_nextOrder(),
        ClipsDescendants = false,
        ZIndex = isSettings and 18 or 16,
    }, isSettings and self._leftColumn or self._listHost)

    if isSettings then
        corner(frame, 17)
        stroke(frame, C.line, 0.32, 1)
        padding(frame, 10, 10, 10, 10)
    end

    local header = make("Frame", {
        Name = "SectionHeader",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 27),
        ZIndex = 20,
    }, frame)
    icon(header, cfg.Icon or "layers", UDim2.fromOffset(2, 4), UDim2.fromOffset(18, 18), C.muted, 22)
    local headerText = label(header, name, 12, C.secondary, true)
    headerText.Position = UDim2.fromOffset(27, 0)
    headerText.Size = UDim2.new(1, -30, 1, 0)

    local body = make("Frame", {
        Name = "Body",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 31),
        Size = UDim2.new(1, 0, 0, 1),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 20,
    }, frame)
    newList(body, isSettings and 7 or 8)

    local section = setmetatable({
        _tab = self,
        _window = self._window,
        _name = name,
        _frame = frame,
        _body = body,
        _side = side,
    }, Section)

    if isSettings then
        table.insert(self._settingsSections, section)
        self:_reflowSettings()
    end
    return section
end

function Tab:_directSection()
    if not self._direct then
        self._direct = self:CreateSection("Controls", nil)
    end
    return self._direct
end

function Tab:CreateButton(config) return self:_directSection():CreateButton(config) end
function Tab:CreateToggle(config) return self:_directSection():CreateToggle(config) end
function Tab:CreateDropdown(config) return self:_directSection():CreateDropdown(config) end
function Tab:CreateMultiDropdown(config) return self:_directSection():CreateMultiDropdown(config) end
function Tab:CreateTextbox(config) return self:_directSection():CreateTextbox(config) end
function Tab:CreateSlider(config) return self:_directSection():CreateSlider(config) end
function Tab:CreateColorpicker(config) return self:_directSection():CreateColorpicker(config) end
function Tab:CreateLabel(value) return self:_directSection():CreateLabel(value) end

local function addLeadingIcon(row, config)
    if not config.Icon then return nil, 14 end
    local holder = make("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(12, 10),
        Size = UDim2.fromOffset(20, 20),
        ZIndex = 28,
    }, row)
    local img = icon(holder, config.Icon, UDim2.fromScale(0,0), UDim2.fromScale(1,1), C.muted, 30)
    return img, 42
end

function Section:CreateLabel(value)
    local row, hover = controlRow(self, "Label", 36)
    local t = label(row, tostring(value or ""), 11, C.secondary, false)
    t.Position = UDim2.fromOffset(14, 0); t.Size = UDim2.new(1, -28, 1, 0); t.ZIndex = 31
    return { _frame = row }
end

function Section:CreateButton(config)
    config = config or {}
    local row = controlRow(self, config.Name or "Button", 42)
    local img, start = addLeadingIcon(row, config)
    local title = label(row, config.Name or config.Title or "Action", 12, C.text, true)
    title.Position = UDim2.fromOffset(start, 0)
    title.Size = UDim2.new(1, -(start + 52), 1, 0)
    title.ZIndex = 31

    local chip = make("Frame", {
        BackgroundColor3 = C.accentSoft,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(26, 26),
        ZIndex = 32,
    }, row)
    corner(chip, 10)
    icon(chip, "chevron-right", UDim2.fromOffset(4, 4), UDim2.fromOffset(18, 18), C.secondary, 34)

    local hit = make("TextButton", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 60,
    }, row)
    hit.Activated:Connect(function()
        if config.Callback then task.spawn(config.Callback) end
    end)
    hit.MouseEnter:Connect(function() tween(chip, Motion.hover, {BackgroundColor3 = C.rowHover}) end)
    hit.MouseLeave:Connect(function() tween(chip, Motion.hover, {BackgroundColor3 = C.accentSoft}) end)
    return { _frame = row }
end

function Section:CreateToggle(config)
    config = config or {}
    local row = controlRow(self, config.Name or "Toggle", 42)
    local _, start = addLeadingIcon(row, config)
    local title = label(row, config.Name or config.Title or "Toggle", 12, C.text, true)
    title.Position = UDim2.fromOffset(start, 0)
    title.Size = UDim2.new(1, -start - 82, 1, 0)
    title.ZIndex = 31

    local state = config.Default == true or config.Value == true
    local track = make("Frame", {
        BackgroundColor3 = state and C.accentSoft or Color3.fromRGB(51, 56, 64),
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(44, 24),
        ZIndex = 32,
    }, row)
    corner(track, 12)
    local trStroke = stroke(track, C.line, 0.22, 1)
    local knob = make("Frame", {
        BackgroundColor3 = state and C.accent or Color3.fromRGB(190, 196, 204),
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = state and UDim2.new(1, -12, 0.5, 0) or UDim2.new(0, 12, 0.5, 0),
        Size = UDim2.fromOffset(state and 18 or 16, state and 18 or 16),
        ZIndex = 33,
    }, track)
    corner(knob, 10)

    local function set(value, emit)
        state = value == true
        tween(track, Motion.base, {BackgroundColor3 = state and C.accentSoft or Color3.fromRGB(51, 56, 64)})
        tween(knob, Motion.base, {
            Position = state and UDim2.new(1, -12, 0.5, 0) or UDim2.new(0, 12, 0.5, 0),
            Size = UDim2.fromOffset(state and 18 or 16, state and 18 or 16),
            BackgroundColor3 = state and C.accent or Color3.fromRGB(190,196,204),
        })
        if emit and config.Callback then task.spawn(config.Callback, state) end
    end

    local hit = make("TextButton", {
        Text = "",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        AutoButtonColor = false,
        ZIndex = 60,
    }, row)
    hit.Activated:Connect(function() set(not state, true) end)
    return {
        _frame = row,
        Set = function(_, value) set(value, true) end,
        SetValue = function(_, value) set(value, true) end,
        Get = function() return state end,
    }
end

local function makeDropdownOverlay(section, row, options, multi, config, selectedRef)
    local win = section._window
    local listFrame = make("Frame", {
        Name = "DropdownMenu",
        BackgroundColor3 = C.header,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 300,
    }, win._overlay)
    corner(listFrame, 14)
    stroke(listFrame, C.line, 0.16, 1)

    local scroll = make("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = C.muted,
        ZIndex = 301,
    }, listFrame)
    padding(scroll, 6, 6, 6, 6)
    newList(scroll, 4)

    local closed = false
    local function close()
        if closed then return end
        closed = true
        tween(listFrame, Motion.exit, {BackgroundTransparency = 0.15})
        task.delay(0.13, function()
            pcall(function() listFrame:Destroy() end)
        end)
    end

    for i, option in ipairs(options or {}) do
        local value = type(option) == "table" and (option.Title or option.Name or option.Value or option.Text or option[1]) or option
        value = tostring(value or "")
        local b = make("TextButton", {
            Name = "Option_" .. i,
            BackgroundColor3 = C.row,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 34),
            Text = "",
            AutoButtonColor = false,
            ZIndex = 305,
        }, scroll)
        corner(b, 9)
        local check = icon(b, multi and "check" or "chevron-right", UDim2.fromOffset(8, 8), UDim2.fromOffset(18, 18), C.muted, 306)
        local txt = label(b, value, 11, C.secondary, false)
        txt.Position = UDim2.fromOffset(34, 0); txt.Size = UDim2.new(1, -44, 1, 0); txt.ZIndex = 306
        b.MouseEnter:Connect(function() tween(b, Motion.hover, {BackgroundColor3 = C.rowHover}) end)
        b.MouseLeave:Connect(function() tween(b, Motion.hover, {BackgroundColor3 = C.row}) end)

        b.Activated:Connect(function()
            if multi then
                selectedRef[value] = not selectedRef[value]
                setIconColor(check, selectedRef[value] and C.accent or C.muted)
                if config.Callback then
                    local out = {}
                    for _, opt in ipairs(options) do
                        local s = type(opt) == "table" and (opt.Title or opt.Name or opt.Value or opt.Text or opt[1]) or opt
                        s = tostring(s or "")
                        if selectedRef[s] then out[#out+1] = s end
                    end
                    task.spawn(config.Callback, out)
                end
            else
                if config._setSelected then config._setSelected(value) end
                close()
            end
        end)
    end

    local rowPos = row.AbsolutePosition
    local rowSize = row.AbsoluteSize
    local vp = viewportSize()
    local width = math.clamp(rowSize.X, 220, math.min(360, vp.X - 16))
    local height = math.min(246, math.max(38, (#options * 38) + 12))
    local x = math.clamp(rowPos.X, 8, vp.X - width - 8)
    local yBelow = rowPos.Y + rowSize.Y + 4
    local y = yBelow
    if y + height > vp.Y - 8 then
        y = math.max(8, rowPos.Y - height - 4)
    end
    listFrame.Position = UDim2.fromOffset(x, y)
    listFrame.Size = UDim2.fromOffset(width, height)
    return close
end

function Section:CreateDropdown(config)
    config = config or {}
    local row = controlRow(self, config.Name or "Dropdown", 42)
    local _, start = addLeadingIcon(row, config)
    local title = label(row, config.Name or config.Title or "Select", 11, C.secondary, true)
    title.Position = UDim2.fromOffset(start, 0)
    title.Size = UDim2.new(0.50, -start, 1, 0)
    title.ZIndex = 31
    local options = config.Options or config.Values or {}
    local selected = config.Default or config.Value or options[1] or "Select"
    local value = label(row, tostring(selected), 11, C.text, false)
    value.Position = UDim2.new(0.50, 0, 0, 0)
    value.Size = UDim2.new(0.50, -42, 1, 0)
    value.TextXAlignment = Enum.TextXAlignment.Right
    value.ZIndex = 31
    icon(row, "chevron-down", UDim2.new(1, -30, 0.5, -9), UDim2.fromOffset(18, 18), C.muted, 34)

    local open = false
    local closeMenu
    local hit = make("TextButton", {
        Text = "",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        AutoButtonColor = false,
        ZIndex = 60,
    }, row)
    hit.Activated:Connect(function()
        if open and closeMenu then
            closeMenu(); closeMenu = nil; open = false
            return
        end
        open = true
        config._setSelected = function(v)
            selected = v
            value.Text = tostring(v)
            if config.Callback then task.spawn(config.Callback, v) end
        end
        closeMenu = makeDropdownOverlay(self, row, options, false, config, {})
        -- The overlay is self-closing after a selection. Reset the state after a brief defer.
        task.defer(function()
            if not row.Parent then open = false end
        end)
    end)
    return {
        _frame = row,
        Get = function() return selected end,
        Set = function(_, v) selected = v; value.Text = tostring(v) end,
        SetValue = function(_, v) selected = v; value.Text = tostring(v) end,
    }
end

function Section:CreateMultiDropdown(config)
    config = config or {}
    local row = controlRow(self, config.Name or "Multi-select", 42)
    local _, start = addLeadingIcon(row, config)
    local title = label(row, config.Name or config.Title or "Select", 11, C.secondary, true)
    title.Position = UDim2.fromOffset(start, 0)
    title.Size = UDim2.new(0.48, -start, 1, 0)
    title.ZIndex = 31

    local selected = {}
    for _, item in ipairs(config.Default or {}) do
        local v = type(item) == "table" and (item.Title or item.Name or item.Value or item.Text or item[1]) or item
        selected[tostring(v or "")] = true
    end

    local function displayValue()
        local out = {}
        for _, option in ipairs(config.Options or config.Values or {}) do
            local v = type(option) == "table" and (option.Title or option.Name or option.Value or option.Text or option[1]) or option
            v = tostring(v or "")
            if selected[v] then out[#out+1] = v end
        end
        return #out > 0 and table.concat(out, ", ") or "None"
    end

    local value = label(row, displayValue(), 11, C.text, false)
    value.Position = UDim2.new(0.48, 0, 0, 0)
    value.Size = UDim2.new(0.52, -42, 1, 0)
    value.TextXAlignment = Enum.TextXAlignment.Right
    value.ZIndex = 31
    icon(row, "chevron-down", UDim2.new(1, -30, 0.5, -9), UDim2.fromOffset(18,18), C.muted, 34)

    local hit = make("TextButton", {
        Text = "",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        AutoButtonColor = false,
        ZIndex = 60,
    }, row)
    local open, closeMenu = false, nil
    hit.Activated:Connect(function()
        if open and closeMenu then closeMenu(); closeMenu = nil; open = false; return end
        open = true
        local oldCb = config.Callback
        local wrapped = {}
        for k,v in pairs(config) do wrapped[k]=v end
        wrapped.Callback = function(out)
            for k in pairs(selected) do selected[k] = false end
            for _, v in ipairs(out or {}) do selected[tostring(v)] = true end
            value.Text = displayValue()
            if oldCb then task.spawn(oldCb, out) end
        end
        closeMenu = makeDropdownOverlay(self, row, config.Options or config.Values or {}, true, wrapped, selected)
    end)

    return {
        _frame = row,
        Get = function()
            local out = {}
            for _, option in ipairs(config.Options or config.Values or {}) do
                local v = type(option) == "table" and (option.Title or option.Name or option.Value or option.Text or option[1]) or option
                v = tostring(v or "")
                if selected[v] then out[#out+1] = v end
            end
            return out
        end,
        Set = function(_, vals)
            for k in pairs(selected) do selected[k] = false end
            for _, v in ipairs(vals or {}) do selected[tostring(v)] = true end
            value.Text = displayValue()
        end,
        SetValue = function(_, vals)
            for k in pairs(selected) do selected[k] = false end
            for _, v in ipairs(vals or {}) do selected[tostring(v)] = true end
            value.Text = displayValue()
        end,
    }
end

function Section:CreateTextbox(config)
    config = config or {}
    local row = controlRow(self, config.Name or "Input", 42)
    local _, start = addLeadingIcon(row, config)
    local title = label(row, config.Name or config.Title or "Input", 11, C.secondary, true)
    title.Position = UDim2.fromOffset(start, 0)
    title.Size = UDim2.new(1, -166, 1, 0)
    title.ZIndex = 31

    local box = make("TextBox", {
        BackgroundColor3 = C.raised,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        PlaceholderText = tostring(config.Placeholder or ""),
        Text = tostring(config.Default or config.Value or ""),
        TextColor3 = C.text,
        PlaceholderColor3 = C.muted,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(0, 146, 0, 30),
        Position = UDim2.new(1, -156, 0.5, -15),
        ZIndex = 40,
    }, row)
    corner(box, 10)
    stroke(box, C.lineSoft, 0.20, 1)
    box.FocusLost:Connect(function()
        if config.Callback then task.spawn(config.Callback, box.Text) end
    end)
    return {
        _frame = row,
        Set = function(_, v) box.Text = tostring(v or "") end,
        SetValue = function(_, v) box.Text = tostring(v or "") end,
        Get = function() return box.Text end,
    }
end

function Section:CreateSlider(config)
    config = config or {}
    local minV = tonumber(config.Min or config.MinValue) or 0
    local maxV = tonumber(config.Max or config.MaxValue) or 100
    if maxV <= minV then maxV = minV + 1 end
    local current = math.clamp(tonumber(config.Default or config.Value) or minV, minV, maxV)
    local row = controlRow(self, config.Name or "Slider", 58)
    local _, start = addLeadingIcon(row, config)
    local title = label(row, config.Name or config.Title or "Slider", 11, C.secondary, true)
    title.Position = UDim2.fromOffset(start, 2); title.Size = UDim2.new(1, -88, 0, 20)
    local value = label(row, tostring(current), 11, C.text, true)
    value.Position = UDim2.new(1, -62, 0, 2); value.Size = UDim2.fromOffset(50, 20); value.TextXAlignment = Enum.TextXAlignment.Right

    local track = make("Frame", {
        BackgroundColor3 = C.raised,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(start, 34),
        Size = UDim2.new(1, -start - 16, 0, 6),
        ZIndex = 32,
    }, row)
    corner(track, 4)
    local pct = (current - minV) / (maxV - minV)
    local fill = make("Frame", {
        BackgroundColor3 = C.accentSoft,
        BorderSizePixel = 0,
        Size = UDim2.new(pct, 0, 1, 0),
        ZIndex = 33,
    }, track)
    corner(fill, 4)
    local knob = make("Frame", {
        BackgroundColor3 = C.accent,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(pct, 0, 0.5, 0),
        Size = UDim2.fromOffset(10, 10),
        ZIndex = 34,
    }, track)
    corner(knob, 5)
    local hit = make("TextButton", {
        Text = "",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 28),
        Position = UDim2.fromOffset(0, -11),
        AutoButtonColor = false,
        ZIndex = 40,
    }, track)
    local draggingSlider = false
    local function setValue(v, emit)
        current = math.clamp(tonumber(v) or minV, minV, maxV)
        local p = (current - minV) / (maxV - minV)
        value.Text = tostring(math.floor(current + 0.5))
        fill.Size = UDim2.new(p, 0, 1, 0)
        knob.Position = UDim2.new(p, 0, 0.5, 0)
        if emit and config.Callback then task.spawn(config.Callback, current) end
    end
    hit.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingSlider = true
            setValue(minV + (input.Position.X - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X) * (maxV - minV), true)
        end
    end)
    self._window._connections[#self._window._connections+1] = UserInputService.InputChanged:Connect(function(input)
        if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            setValue(minV + (input.Position.X - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X) * (maxV - minV), true)
        end
    end)
    self._window._connections[#self._window._connections+1] = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingSlider = false
        end
    end)
    return {
        _frame = row,
        Set = function(_, v) setValue(v, true) end,
        SetValue = function(_, v) setValue(v, true) end,
        Get = function() return current end,
    }
end

function Section:CreateColorpicker(config)
    config = config or {}
    local row = controlRow(self, config.Name or "Color", 42)
    local _, start = addLeadingIcon(row, config)
    local title = label(row, config.Name or config.Title or "Color", 12, C.text, true)
    title.Position = UDim2.fromOffset(start,0); title.Size = UDim2.new(1, -72, 1, 0)
    local swatch = make("Frame", {
        BackgroundColor3 = typeof(config.Default) == "Color3" and config.Default or C.accentSoft,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1,0.5),
        Position = UDim2.new(1,-12,0.5,0),
        Size = UDim2.fromOffset(34,20),
        ZIndex = 34,
    }, row)
    corner(swatch, 7); stroke(swatch, C.line, 0.18, 1)
    local hit = make("TextButton", {
        Text = "",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1,1),
        AutoButtonColor = false,
        ZIndex = 60,
    }, row)
    hit.Activated:Connect(function()
        if config.Callback then task.spawn(config.Callback, swatch.BackgroundColor3) end
    end)
    return {
        _frame = row,
        Set = function(_, v) if typeof(v) == "Color3" then swatch.BackgroundColor3 = v end end,
        SetValue = function(_, v) if typeof(v) == "Color3" then swatch.BackgroundColor3 = v end end,
        Get = function() return swatch.BackgroundColor3 end,
    }
end

function Tab:CreateStatRow(items)
    local parent = self._isSettings and self._leftColumn or self._listHost
    local row = make("Frame", {
        Name = "StatRow",
        BackgroundColor3 = C.raised,
        BorderSizePixel = 0,
        Size = UDim2.new(1,0,0,46),
        LayoutOrder = self:_nextOrder(),
        ZIndex = 18,
    }, parent)
    corner(row, 14); stroke(row, C.lineSoft, 0.25, 1)
    local x = 12
    for _, item in ipairs(items or {}) do
        local t = label(row, tostring(item.Value or item[2] or "-"), 11, C.text, true)
        t.Position = UDim2.fromOffset(x,0); t.Size = UDim2.fromOffset(90,46)
        x = x + 94
    end
    return row
end

function Tab:CreateFeaturedCard(config)
    config = config or {}
    local parent = self._isSettings and self._leftColumn or self._listHost
    local row = make("Frame", {
        Name = "Featured",
        BackgroundColor3 = C.raised,
        BorderSizePixel = 0,
        Size = UDim2.new(1,0,0,74),
        LayoutOrder = self:_nextOrder(),
    }, parent)
    corner(row, 16); stroke(row, C.lineSoft, 0.25, 1)
    local t = label(row, config.Title or "Featured", 14, C.text, true)
    t.Position = UDim2.fromOffset(14,10); t.Size = UDim2.new(1,-28,0,24)
    local d = label(row, config.Subtitle or config.Desc or "", 11, C.muted, false)
    d.Position = UDim2.fromOffset(14,36); d.Size = UDim2.new(1,-28,0,22)
    if config.Callback then
        bindActivated(row, config.Callback)
    end
    return row
end

function Tab:CreateActionRow(config) return self:CreateFeaturedCard(config) end
function Tab:CreateCardGroup(config) return self:CreateFeaturedCard(config) end

return UI
