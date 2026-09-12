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
        canvas = Color3.fromRGB(10, 12, 16),
        shell = Color3.fromRGB(18, 21, 27),
        rail = Color3.fromRGB(14, 17, 22),
        header = Color3.fromRGB(24, 28, 35),
        raised = Color3.fromRGB(34, 39, 48),
        row = Color3.fromRGB(27, 32, 40),
        rowHover = Color3.fromRGB(42, 49, 60),
        rowPressed = Color3.fromRGB(52, 61, 74),
        line = Color3.fromRGB(99, 111, 128),
        lineSoft = Color3.fromRGB(66, 76, 91),
        text = Color3.fromRGB(240, 242, 246),
        secondary = Color3.fromRGB(182, 188, 198),
        muted = Color3.fromRGB(125, 133, 145),
        accent = Color3.fromRGB(130, 194, 255),
        accentSoft = Color3.fromRGB(38, 86, 128),
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
    local holder = make("Frame", {Name="Icon_"..resolveIconName(name).."Fallback",BackgroundTransparency=1,BorderSizePixel=0,Position=pos,Size=size,ZIndex=z or 20}, parent)
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
    if not img then return end
    if img:IsA("ImageLabel") then
        img.ImageColor3=color
    else
        for _,child in ipairs(img:GetDescendants()) do
            if child:IsA("Frame") then
                child.BackgroundColor3=color
                local outline=child:FindFirstChildOfClass("UIStroke")
                if outline then outline.Color=color end
            end
        end
    end
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
        ZIndex=40,
    },self._body)
    corner(row,13)
    stroke(row,C.lineSoft,0.40,1)
    local hover=make("Frame",{BackgroundColor3=C.whiteSoft,BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromScale(1,1),ZIndex=41},row)
    corner(hover,13)
    local hit=make("TextButton",{Name="InputHitbox",Text="",BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromScale(1,1),AutoButtonColor=false,Active=true,ZIndex=100},row)
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
    local shadow=make("Frame",{Name="PanelShadow",BackgroundColor3=Color3.fromRGB(0,0,0),BackgroundTransparency=0.52,BorderSizePixel=0,AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5)+UDim2.fromOffset(0,8),Size=UDim2.fromOffset(initialW+12,initialH+12),ZIndex=9},sg)
    corner(shadow,24)
    local shell=make("CanvasGroup",{Name="Panel",BackgroundColor3=C.shell,BorderSizePixel=0,AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(initialW,initialH),GroupTransparency=1,ClipsDescendants=true,ZIndex=10},sg)
    corner(shell,20); stroke(shell,C.line,0.12,1.25)

    local bg
    if type(config.Background)=="string" and config.Background~="" then
        bg=make("ImageLabel",{Name="Background",BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromScale(1,1),Image=config.Background,ImageTransparency=tonumber(config.BackgroundImageTransparency) or 0.58,ScaleType=Enum.ScaleType.Crop,ZIndex=11},shell)
    end
    local shade=make("Frame",{Name="BackgroundShade",BackgroundColor3=C.canvas,BackgroundTransparency=0.68,BorderSizePixel=0,Size=UDim2.fromScale(1,1),ZIndex=12},shell)

    local topH=68
    local bottomH=22
    local railW=mobile and 68 or 190

    local rail=make("Frame",{Name="Rail",BackgroundColor3=C.rail,BorderSizePixel=0,Size=UDim2.new(0,railW,1,0),ZIndex=20,ClipsDescendants=true},shell)
    corner(rail,20)
    make("Frame",{BackgroundColor3=C.lineSoft,BackgroundTransparency=0.4,BorderSizePixel=0,Position=UDim2.new(1,-1,0,0),Size=UDim2.new(0,1,1,0),ZIndex=21},rail)

    local brand=make("ImageLabel",{Name="BrandMark",BackgroundColor3=C.raised,BorderSizePixel=0,Position=UDim2.fromOffset(mobile and 17 or 16,16),Size=UDim2.fromOffset(38,38),Image=type(config.Logo)=="string" and config.Logo or "",ImageTransparency=type(config.Logo)=="string" and 0 or 1,ScaleType=Enum.ScaleType.Fit,ZIndex=25},rail)
    corner(brand,12); stroke(brand,C.lineSoft,0.24,1)
    -- Always render a small vector K mark as a reliable fallback for blocked/slow assets.
    local mark=make("Frame",{Name="ProceduralLogo",BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(mobile and 17 or 16,16),Size=UDim2.fromOffset(38,38),ZIndex=26},rail)
    local stem=make("Frame",{BackgroundColor3=C.accent,BorderSizePixel=0,Position=UDim2.fromOffset(11,8),Size=UDim2.fromOffset(4,22),ZIndex=27},mark); corner(stem,2)
    local upper=make("Frame",{BackgroundColor3=C.accent,BorderSizePixel=0,AnchorPoint=Vector2.new(0,0.5),Position=UDim2.fromOffset(14,17),Size=UDim2.fromOffset(15,4),Rotation=-34,ZIndex=27},mark); corner(upper,2)
    local lower=make("Frame",{BackgroundColor3=C.accent,BorderSizePixel=0,AnchorPoint=Vector2.new(0,0.5),Position=UDim2.fromOffset(14,21),Size=UDim2.fromOffset(15,4),Rotation=34,ZIndex=27},mark); corner(lower,2)

    local brandTitle=label(rail,config.Title or "Khfresh Hub",13,C.text,true); brandTitle.Position=UDim2.fromOffset(62,10); brandTitle.Size=UDim2.new(1,-72,0,23); brandTitle.Visible=not mobile
    local brandSub=label(rail,config.Author or "Khfresh",9,C.muted,false); brandSub.Position=UDim2.fromOffset(62,34); brandSub.Size=UDim2.new(1,-72,0,18); brandSub.Visible=not mobile

    local nav=make("ScrollingFrame",{Name="Navigation",Active=true,BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(9,mobile and 76 or 74),Size=UDim2.new(1,-18,1,-88),CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=2,ScrollBarImageTransparency=1,ZIndex=25},rail)
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

    local content=make("Frame",{Name="ContentViewport",Active=true,BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(railW,topH),Size=UDim2.new(1,-railW,1,-(topH+bottomH)),ClipsDescendants=true,ZIndex=24},shell)
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
        _gui=sg,_shell=shell,_panel=shell,_shadow=shadow,_rail=rail,_nav=nav,_top=top,_content=content,_overlay=overlay,
        _bottomBar=bottom,_dragHandle=drag,_resizeHandle=resize,_floating=floating,_floatingButton=floatingBtn,
        _brandMark=brand,_proceduralLogo=mark,_brandTitle=brandTitle,_brandSub=brandSub,_background=bg,_backgroundShade=shade,
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
            shadow.Position=UDim2.new(0.5,nx,0.5,ny+8)
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
    if self._shadow then
        self._shadow.Size=UDim2.fromOffset(self._width+12,self._height+12)
        self._shadow.Position=UDim2.new(self._shell.Position.X.Scale,self._shell.Position.X.Offset,self._shell.Position.Y.Scale,self._shell.Position.Y.Offset+8)
    end
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
    local scroll=make("ScrollingFrame",{Name="Scroll",Active=true,BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(0,0),Size=UDim2.new(1,-4,1,0),CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.None,ScrollBarThickness=4,ScrollBarImageColor3=C.muted,ScrollBarImageTransparency=0.35,ScrollingDirection=Enum.ScrollingDirection.Y,ElasticBehavior=Enum.ElasticBehavior.Always,ZIndex=26},page)
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
    if self._brandMark and type(asset)=="string" and asset~="" then
        self._brandMark.Image=asset
        self._brandMark.ImageTransparency=0
        if self._proceduralLogo then self._proceduralLogo.Visible=false end
    end
end

function Window:CreateFloatingToggle(config)
    config=config or {}
    local wanted=resolveIconName(config.Icon or "volleyball")
    if self._floatingButton then
        for _,child in ipairs(self._floatingButton:GetChildren()) do
            if child.Name:sub(1,5)=="Icon_" or child.Name:find("Fallback",1,true) then pcall(function() child:Destroy() end) end
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
    tween(self._shadow,Motion.exit,{BackgroundTransparency=1,Position=UDim2.fromScale(0.5,0.5)+UDim2.fromOffset(0,16)})
    task.delay(0.19,function()
        if not self._open and self._shell then
            self._shell.Visible=false
            if self._shadow then self._shadow.Visible=false end
            self:_showFloating()
        end
    end)
end

function Window:Open()
    if self._open then return end
    self._open=true
    self._minimized=false
    self:_hideFloating()
    self._shell.Visible=true
    if self._shadow then
        self._shadow.Visible=true
        self._shadow.BackgroundTransparency=0.52
    end
    self._shell.GroupTransparency=1
    self._shell.Position=UDim2.fromScale(0.5,0.5)+UDim2.fromOffset(0,8)
    if self._shadow then self._shadow.Position=UDim2.fromScale(0.5,0.5)+UDim2.fromOffset(0,16) end
    tween(self._shell,Motion.enter,{GroupTransparency=0,Position=UDim2.fromScale(0.5,0.5)})
    tween(self._shadow,Motion.enter,{BackgroundTransparency=0.52,Position=UDim2.fromScale(0.5,0.5)+UDim2.fromOffset(0,8)})
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
