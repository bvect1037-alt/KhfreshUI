--[[
    Khfresh Hub - BentoGridStyle
    Purpose: dedicated UI library for Khfresh Hub.
    The previous library is used only as an API/layout reference.
    This file contains no feature logic from another hub and no branded asset.

    Icons: Footagesus/Icons Lucide pack, resolved by icon name at runtime.
    Main API is intentionally shaped around the Khfresh Hub source.
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local function getGuiParent()
    local ok, parent = pcall(function()
        if type(gethui) == "function" then
            local h = gethui()
            if h then return h end
        end
    end)
    if ok and parent then return parent end
    local ok2, core = pcall(function() return game:GetService("CoreGui") end)
    if ok2 and core then return core end
    return LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")
end

local GUI_PARENT = getGuiParent()

local Library = {
    _windows = {},
    _version = "3.0.0-khfresh-bento-lucide",
    _notificationGui = nil,
    _notificationHost = nil,
    _iconPack = nil,
}

-- ================================================================
-- THEME
-- ================================================================
local THEMES = {
    Bento = {
        Canvas = Color3.fromRGB(15, 17, 22),
        Shell = Color3.fromRGB(21, 24, 30),
        Rail = Color3.fromRGB(18, 20, 26),
        Card = Color3.fromRGB(27, 30, 38),
        Card2 = Color3.fromRGB(31, 34, 43),
        Raised = Color3.fromRGB(36, 40, 50),
        Hover = Color3.fromRGB(42, 47, 59),
        Pressed = Color3.fromRGB(49, 55, 68),
        Line = Color3.fromRGB(54, 60, 73),
        Accent = Color3.fromRGB(103, 193, 255),
        AccentSoft = Color3.fromRGB(38, 76, 106),
        Text = Color3.fromRGB(239, 242, 248),
        Secondary = Color3.fromRGB(177, 184, 200),
        Muted = Color3.fromRGB(116, 124, 142),
        Success = Color3.fromRGB(113, 218, 159),
        Danger = Color3.fromRGB(244, 106, 119),
    },
    Dark = {
        Canvas = Color3.fromRGB(11, 12, 16),
        Shell = Color3.fromRGB(17, 19, 24),
        Rail = Color3.fromRGB(14, 15, 20),
        Card = Color3.fromRGB(23, 26, 32),
        Card2 = Color3.fromRGB(27, 30, 37),
        Raised = Color3.fromRGB(32, 35, 43),
        Hover = Color3.fromRGB(39, 43, 52),
        Pressed = Color3.fromRGB(47, 52, 63),
        Line = Color3.fromRGB(47, 52, 62),
        Accent = Color3.fromRGB(96, 183, 255),
        AccentSoft = Color3.fromRGB(35, 69, 97),
        Text = Color3.fromRGB(236, 239, 246),
        Secondary = Color3.fromRGB(168, 175, 191),
        Muted = Color3.fromRGB(109, 117, 135),
        Success = Color3.fromRGB(104, 204, 149),
        Danger = Color3.fromRGB(238, 96, 110),
    },
}

local CurrentTheme = "Bento"
local C = {}
for k, v in pairs(THEMES.Bento) do C[k] = v end

function Library:SetTheme(name)
    name = tostring(name or "Bento")
    if not THEMES[name] then name = "Bento" end
    CurrentTheme = name
    for k, v in pairs(THEMES[name]) do C[k] = v end
    for _, window in ipairs(self._windows) do
        if window and window._alive then
            pcall(function() window:_refreshTheme() end)
        end
    end
end

function Library:GetTheme() return CurrentTheme end
function Library:GetThemes()
    local out = {}
    for name in pairs(THEMES) do out[#out+1] = name end
    table.sort(out)
    return out
end

-- ================================================================
-- HELPERS
-- ================================================================
local function make(className, props, parent)
    local obj = Instance.new(className)
    if props then
        for k, v in pairs(props) do
            local ok = pcall(function() obj[k] = v end)
            if not ok then
                -- Ignore optional properties that a specific Roblox build does not expose.
            end
        end
    end
    if parent then obj.Parent = parent end
    return obj
end

local function round(parent, radius)
    return make("UICorner", { CornerRadius = UDim.new(0, radius or 14) }, parent)
end

local function outline(parent, color, transparency, thickness)
    return make("UIStroke", {
        Color = color or C.Line,
        Transparency = transparency == nil and 0.55 or transparency,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

local function addPadding(parent, l, r, t, b)
    return make("UIPadding", {
        PaddingLeft = UDim.new(0, l or 0),
        PaddingRight = UDim.new(0, r or 0),
        PaddingTop = UDim.new(0, t or 0),
        PaddingBottom = UDim.new(0, b or 0),
    }, parent)
end

local function tween(obj, info, props)
    if not obj then return end
    local ok, tw = pcall(function()
        return TweenService:Create(obj, info or TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
    end)
    if ok and tw then tw:Play() return tw end
end

local function text(parent, value, size, color, bold)
    return make("TextLabel", {
        BackgroundTransparency = 1,
        Text = tostring(value or ""),
        TextColor3 = color or C.Text,
        TextSize = size or 13,
        Font = bold and Enum.Font.GothamMedium or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, parent)
end

local function button(parent, props)
    props = props or {}
    props.ClassName = nil
    props.Text = props.Text or ""
    props.AutoButtonColor = false
    return make("TextButton", props, parent)
end

local function bindActivate(gui, callback)
    if not gui or type(callback) ~= "function" then return end
    if gui.Activated then
        gui.Activated:Connect(function()
            task.spawn(function() pcall(callback) end)
        end)
    else
        gui.MouseButton1Click:Connect(function()
            task.spawn(function() pcall(callback) end)
        end)
    end
end

local function hoverButton(btn, normal, over)
    if not btn then return end
    normal = normal or btn.BackgroundColor3
    over = over or C.Hover
    btn.MouseEnter:Connect(function()
        tween(btn, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = over})
    end)
    btn.MouseLeave:Connect(function()
        tween(btn, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = normal})
    end)
end

local function normalizeArray(values)
    local out = {}
    if type(values) ~= "table" then return out end
    for _, value in ipairs(values) do
        if type(value) == "table" then
            value = value.Title or value.Name or value.Value or value.Text or value[1]
        end
        if value ~= nil then out[#out+1] = tostring(value) end
    end
    return out
end

local function viewport()
    local cam = workspace.CurrentCamera
    return cam and cam.ViewportSize or Vector2.new(1280, 720)
end

-- ================================================================
-- LUCIDE API
-- Uses the Footagesus icon runtime and the official Lucide pack.
-- ================================================================
local Lucide = {
    Loaded = false,
    Loading = false,
    Pack = nil,
    URL = "https://raw.githubusercontent.com/Footagesus/Icons/main/Main-v2.lua",
}

local function loadLucide()
    if Lucide.Loaded then return true end
    if Lucide.Loading then
        local deadline = os.clock() + 6
        while Lucide.Loading and os.clock() < deadline do task.wait() end
        return Lucide.Loaded
    end
    Lucide.Loading = true
    local ok, result = pcall(function()
        local source = game:HttpGet(Lucide.URL)
        local chunk = loadstring(source)
        if not chunk then error("Lucide loader did not compile") end
        local pack = chunk()
        if type(pack) ~= "table" then error("Lucide loader returned invalid pack") end
        pcall(function()
            if pack.SetIconsType then pack:SetIconsType("lucide") end
            if pack.SetIconsType then pack.SetIconsType("lucide") end
        end)
        Lucide.Pack = pack
        Lucide.Loaded = true
    end)
    Lucide.Loading = false
    if not ok then
        warn("[Khfresh] Lucide API load failed: " .. tostring(result))
    end
    return Lucide.Loaded
end

task.spawn(loadLucide)

function Library:GetIcon(iconName)
    if not loadLucide() then return nil end
    local pack = Lucide.Pack
    local name = tostring(iconName or "circle")
    local ok, result = pcall(function()
        if pack.GetIcon then return pack:GetIcon(name, "lucide") end
        if pack.Icon then return pack:Icon(name, "lucide", false) end
    end)
    if ok then return result end
    return nil
end

function Library:IconExists(iconName)
    return self:GetIcon(iconName) ~= nil
end

function Library:GetIconNames()
    if not loadLucide() then return {} end
    local pack = Lucide.Pack
    local out = {}
    local lucideSet = pack and pack.Icons and pack.Icons.lucide
    if lucideSet and lucideSet.Icons then
        for name in pairs(lucideSet.Icons) do out[#out+1] = name end
    elseif lucideSet then
        for name in pairs(lucideSet) do
            if type(name) == "string" then out[#out+1] = name end
        end
    end
    table.sort(out)
    return out
end

local function setImageFromIcon(img, iconName)
    if not img then return false end
    local result = Library:GetIcon(iconName)
    if type(result) == "string" then
        img.Image = result
        img.ImageRectSize = Vector2.new(0, 0)
        img.ImageRectOffset = Vector2.new(0, 0)
        return true
    end
    if type(result) == "table" then
        local image = result[1]
        local meta = result[2]
        if type(image) == "number" then image = "rbxassetid://" .. tostring(image) end
        if type(image) ~= "string" then return false end
        img.Image = image
        if type(meta) == "table" then
            pcall(function() img.ImageRectSize = meta.ImageRectSize or Vector2.new(0, 0) end)
            pcall(function() img.ImageRectOffset = meta.ImageRectPosition or Vector2.new(0, 0) end)
        end
        return true
    end
    return false
end

local function icon(parent, name, pos, size, color, z)
    local img = make("ImageLabel", {
        Name = "Lucide_" .. tostring(name or "circle"),
        BackgroundTransparency = 1,
        Size = size or UDim2.fromOffset(18, 18),
        Position = pos or UDim2.fromOffset(0, 0),
        ImageColor3 = color or C.Secondary,
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = z or 10,
    }, parent)
    if not setImageFromIcon(img, name) then
        task.spawn(function()
            if loadLucide() and img.Parent then
                setImageFromIcon(img, name)
            end
        end)
    end
    return img
end

-- ================================================================
-- WINDOW / TAB / SECTION
-- ================================================================
local Window = {}
Window.__index = Window
local Tab = {}
Tab.__index = Tab
local Section = {}
Section.__index = Section

local function setThemeRecursive(window)
    if not window or not window._alive then return end
    -- Keep theme updates explicit for primary surfaces. Individual controls are updated as they are created.
    pcall(function() window._shell.BackgroundColor3 = C.Canvas end)
    pcall(function() window._body.BackgroundColor3 = C.Canvas end)
    pcall(function() window._rail.BackgroundColor3 = C.Rail end)
    pcall(function() window._top.BackgroundColor3 = C.Shell end)
end

function Window:_refreshTheme()
    setThemeRecursive(self)
    for _, tab in ipairs(self._tabs) do
        for _, section in ipairs(tab._sections) do
            pcall(function() section:_refreshTheme() end)
        end
    end
end

function Section:_refreshTheme()
    if not self._alive then return end
    pcall(function() self._frame.BackgroundColor3 = C.Card end)
    pcall(function() self._title.TextColor3 = C.Text end)
end

local function createSectionCard(tab, cfg, side)
    local name = type(cfg) == "table" and (cfg.Title or cfg.Name) or tostring(cfg or "Section")
    local iconName = type(cfg) == "table" and cfg.Icon or "layers-3"
    name = tostring(name or "Section")

    local frame = make("Frame", {
        Name = "Section_" .. name,
        BackgroundColor3 = C.Card,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 60),
        AutomaticSize = Enum.AutomaticSize.Y,
        ClipsDescendants = false,
    })
    round(frame, 18)
    outline(frame, C.Line, 0.55, 1)

    local titleRow = make("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 46),
    }, frame)
    icon(titleRow, iconName, UDim2.fromOffset(14, 14), UDim2.fromOffset(18, 18), C.Accent, 3)
    local title = text(titleRow, name, 13, C.Text, true)
    title.Position = UDim2.fromOffset(42, 0)
    title.Size = UDim2.new(1, -54, 1, 0)

    local content = make("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(10, 46),
        Size = UDim2.new(1, -20, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
    }, frame)
    local layout = make("UIListLayout", {
        Padding = UDim.new(0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, content)
    addPadding(content, 0, 0, 0, 10)

    local obj = setmetatable({
        _tab = tab,
        _frame = frame,
        _title = title,
        _content = content,
        _layout = layout,
        _name = name,
        _side = tostring(side or "Auto"),
        _alive = true,
        _order = 0,
    }, Section)

    frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        if obj._alive then
            task.defer(function() tab:_reflow() end)
        end
    end)
    return obj
end

function Tab:_reflow()
    if not self._alive then return end
    local vp = viewport()
    local mobile = vp.X < 760 or vp.Y < 520
    self._mobile = mobile
    if self._topStack then
        self._topStack.Size = UDim2.new(1, 0, 0, self._topStack.UIListLayout.AbsoluteContentSize.Y)
    end
    local topH = self._topStack and self._topStack.AbsoluteSize.Y or 0
    local gap = 10
    local width = mobile and 1 or 0.5
    local columnW = mobile and 1 or 0.5
    local left = self._leftCol
    local right = self._rightCol
    left.Position = UDim2.new(0, 0, 0, topH + gap)
    left.Size = UDim2.new(columnW, mobile and 0 or -5, 0, left.UIListLayout.AbsoluteContentSize.Y)
    if mobile then
        right.Visible = false
        right.Size = UDim2.new(0, 0, 0, 0)
    else
        right.Visible = true
        right.Position = UDim2.new(0.5, 5, 0, topH + gap)
        right.Size = UDim2.new(0.5, -5, 0, right.UIListLayout.AbsoluteContentSize.Y)
    end
    local maxH = math.max(left.UIListLayout.AbsoluteContentSize.Y, right.Visible and right.UIListLayout.AbsoluteContentSize.Y or 0)
    local total = topH + gap + maxH + 18
    self._pageCanvas = total
    self._body.CanvasSize = UDim2.new(0, 0, 0, total)
end

function Tab:_attachSection(section)
    section._frame.LayoutOrder = #self._sections + 1
    local target
    if self._mobile then
        target = self._leftCol
    elseif section._side:lower() == "right" then
        target = self._rightCol
    elseif section._side:lower() == "left" then
        target = self._leftCol
    else
        local lh = self._leftCol.UIListLayout.AbsoluteContentSize.Y
        local rh = self._rightCol.UIListLayout.AbsoluteContentSize.Y
        target = lh <= rh and self._leftCol or self._rightCol
    end
    section._frame.Parent = target
    self._lastSection = section
    task.defer(function() self:_reflow() end)
end

function Tab:_implicitSection()
    if self._lastSection and self._lastSection._alive then return self._lastSection end
    local s = createSectionCard(self, {Title = "General", Icon = "sliders-horizontal"}, "Left")
    table.insert(self._sections, s)
    self:_attachSection(s)
    return s
end

function Tab:CreateSection(nameOrConfig, side)
    local cfg = nameOrConfig
    if type(cfg) ~= "table" then cfg = {Title = tostring(cfg or "Section"), Icon = "layers-3"} end
    local s = createSectionCard(self, cfg, side or cfg.Side or cfg.Position)
    table.insert(self._sections, s)
    self:_attachSection(s)
    return s
end

function Tab:CreateHeader(cfg)
    if type(cfg) ~= "table" then cfg = {Title = tostring(cfg or "")} end
    local wrap = make("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 52),
        AutomaticSize = Enum.AutomaticSize.Y,
    }, self._topStack)
    local title = text(wrap, cfg.Title or "", 18, C.Text, true)
    title.Size = UDim2.new(1, -34, 0, 27)
    title.Position = UDim2.fromOffset(2, 0)
    if cfg.Icon then icon(wrap, cfg.Icon, UDim2.new(1, -24, 0, 5), UDim2.fromOffset(18, 18), C.Accent, 3) end
    local subtitle = cfg.Subtitle or cfg.Desc or cfg.Description
    if subtitle and subtitle ~= "" then
        local sub = text(wrap, subtitle, 11, C.Muted, false)
        sub.Size = UDim2.new(1, -4, 0, 22)
        sub.Position = UDim2.fromOffset(2, 27)
    else
        wrap.Size = UDim2.new(1, 0, 0, 30)
    end
    task.defer(function() self:_reflow() end)
    return wrap
end

local function createControlRow(section, height)
    section._order = section._order + 1
    local row = make("Frame", {
        Name = "Control_" .. tostring(section._order),
        BackgroundColor3 = C.Card2,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, height or 46),
        LayoutOrder = section._order,
    }, section._content)
    round(row, 13)
    outline(row, C.Line, 0.70, 1)
    return row
end

local function controlLabel(row, name, iconName, compact)
    local left = iconName and 44 or 14
    if iconName then icon(row, iconName, UDim2.fromOffset(13, (compact and 12 or 14)), UDim2.fromOffset(17, 17), C.Muted, 3) end
    local lbl = text(row, name, compact and 11 or 12, C.Text, true)
    lbl.Position = UDim2.fromOffset(left, 0)
    lbl.Size = UDim2.new(1, -(left + 12), 1, 0)
    return lbl
end

function Section:CreateToggle(cfg)
    cfg = cfg or {}
    local state = cfg.Default == true or cfg.Value == true
    local row = createControlRow(self, 48)
    local lbl = controlLabel(row, cfg.Name or cfg.Title or "Toggle", cfg.Icon, false)
    lbl.Size = UDim2.new(1, -82, 1, 0)

    local track = make("Frame", {
        BackgroundColor3 = state and C.Accent or C.Raised,
        Position = UDim2.new(1, -58, 0.5, -13),
        Size = UDim2.fromOffset(44, 26),
        BorderSizePixel = 0,
    }, row)
    round(track, 13)
    local knob = make("Frame", {
        BackgroundColor3 = C.Text,
        Size = UDim2.fromOffset(20, 20),
        Position = state and UDim2.new(1, -23, 0.5, -10) or UDim2.fromOffset(3, 3),
        BorderSizePixel = 0,
    }, track)
    round(knob, 10)

    local hit = button(row, {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 20})
    local function set(value, emit)
        state = value == true
        tween(track, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = state and C.Accent or C.Raised})
        tween(knob, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = state and UDim2.new(1, -23, 0.5, -10) or UDim2.fromOffset(3, 3)
        })
        if emit and type(cfg.Callback) == "function" then task.spawn(function() pcall(cfg.Callback, state) end) end
    end
    bindActivate(hit, function() set(not state, true) end)
    return {
        Set = function(_, v) set(v, true) end,
        SetValue = function(_, v) set(v, true) end,
        Get = function() return state end,
        GetValue = function() return state end,
        _frame = row,
    }
end

function Section:CreateButton(cfg)
    cfg = cfg or {}
    local row = createControlRow(self, 46)
    local lbl = controlLabel(row, cfg.Name or cfg.Title or "Button", cfg.Icon, false)
    lbl.Size = UDim2.new(1, -54, 1, 0)
    local chev = icon(row, cfg.Icon or "chevron-right", UDim2.new(1, -31, 0.5, -9), UDim2.fromOffset(18, 18), C.Accent, 3)
    chev.Name = "ActionIcon"
    local hit = button(row, {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 20})
    hoverButton(hit, Color3.new(1,1,1), Color3.fromRGB(255,255,255))
    bindActivate(hit, function()
        if type(cfg.Callback) == "function" then cfg.Callback() end
    end)
    return {_frame = row}
end

function Section:CreateDropdown(cfg)
    cfg = cfg or {}
    local options = normalizeArray(cfg.Options or cfg.Values or {})
    local selected = cfg.Default or cfg.Value or options[1] or "Select"
    local row = createControlRow(self, 50)
    controlLabel(row, cfg.Name or cfg.Title or "Dropdown", cfg.Icon, true)
    local valueBtn = button(row, {
        Size = UDim2.new(0.56, -44, 1, -8),
        Position = UDim2.new(0.44, 0, 0, 4),
        BackgroundColor3 = C.Raised,
        ZIndex = 15,
    })
    round(valueBtn, 11)
    local valueText = text(valueBtn, tostring(selected), 11, C.Secondary, false)
    valueText.Position = UDim2.fromOffset(10, 0)
    valueText.Size = UDim2.new(1, -32, 1, 0)
    valueText.TextXAlignment = Enum.TextXAlignment.Right
    local chev = icon(valueBtn, "chevron-down", UDim2.new(1, -23, 0.5, -7), UDim2.fromOffset(14, 14), C.Muted, 16)

    local popup = make("Frame", {
        BackgroundColor3 = C.Raised,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -20, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Position = UDim2.new(0, 10, 0, 54),
        Visible = false,
        ZIndex = 40,
    }, row)
    round(popup, 12)
    outline(popup, C.Line, 0.4, 1)
    addPadding(popup, 6, 6, 6, 6)
    local lay = make("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, popup)
    local open = false
    local function rebuild()
        for _, child in ipairs(popup:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        for _, opt in ipairs(options) do
            local b = button(popup, {
                Size = UDim2.new(1, 0, 0, 32),
                BackgroundColor3 = C.Card,
                ZIndex = 41,
            })
            round(b, 9)
            local tx = text(b, opt, 10, C.Secondary, false)
            tx.Position = UDim2.fromOffset(10, 0)
            tx.Size = UDim2.new(1, -20, 1, 0)
            bindActivate(b, function()
                selected = opt
                valueText.Text = opt
                open = false
                popup.Visible = false
                if type(cfg.Callback) == "function" then task.spawn(function() pcall(cfg.Callback, opt) end) end
            end)
        end
    end
    rebuild()
    bindActivate(valueBtn, function()
        open = not open
        popup.Visible = open
        chev.ImageColor3 = open and C.Accent or C.Muted
    end)
    return {
        Set = function(_, value)
            value = tostring(value or "")
            for _, opt in ipairs(options) do if opt == value then selected = value break end end
            valueText.Text = tostring(selected)
        end,
        SetValue = function(_, value)
            value = tostring(value or "")
            for _, opt in ipairs(options) do
                if opt == value then selected = value; valueText.Text = value; break end
            end
        end,
        Get = function() return selected end,
        GetValue = function() return selected end,
        Refresh = function(_, newOptions)
            options = normalizeArray(newOptions or {})
            rebuild()
        end,
        _frame = row,
    }
end

function Section:CreateMultiDropdown(cfg)
    cfg = cfg or {}
    local options = normalizeArray(cfg.Options or cfg.Values or {})
    local chosen = {}
    if type(cfg.Default) == "table" then
        for _, value in ipairs(cfg.Default) do chosen[tostring(value)] = true end
    elseif cfg.Default ~= nil then
        chosen[tostring(cfg.Default)] = true
    end
    local row = createControlRow(self, 54)
    controlLabel(row, cfg.Name or cfg.Title or "Multi Select", cfg.Icon, true)
    local valueBtn = button(row, {
        Size = UDim2.new(0.56, -44, 1, -10),
        Position = UDim2.new(0.44, 0, 0, 5),
        BackgroundColor3 = C.Raised,
        ZIndex = 15,
    })
    round(valueBtn, 11)
    local valueText = text(valueBtn, "", 10, C.Secondary, false)
    valueText.Position = UDim2.fromOffset(10, 0)
    valueText.Size = UDim2.new(1, -32, 1, 0)
    valueText.TextXAlignment = Enum.TextXAlignment.Right
    icon(valueBtn, "chevrons-up-down", UDim2.new(1, -23, 0.5, -7), UDim2.fromOffset(14, 14), C.Muted, 16)

    local popup = make("Frame", {
        BackgroundColor3 = C.Raised, BorderSizePixel = 0,
        Size = UDim2.new(1, -20, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        Position = UDim2.new(0, 10, 0, 58), Visible = false, ZIndex = 40,
    }, row)
    round(popup, 12); outline(popup, C.Line, 0.4, 1); addPadding(popup, 6, 6, 6, 6)
    make("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, popup)
    local open = false
    local updateValue = function()
        local picked = {}
        for _, opt in ipairs(options) do if chosen[opt] then picked[#picked+1] = opt end end
        valueText.Text = #picked > 0 and table.concat(picked, ", ") or "None"
        return picked
    end
    local function rebuild()
        for _, child in ipairs(popup:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
        for _, opt in ipairs(options) do
            local b = button(popup, {Size = UDim2.new(1,0,0,32), BackgroundColor3 = chosen[opt] and C.AccentSoft or C.Card, ZIndex = 41})
            round(b, 9)
            local dot = make("Frame", {Size = UDim2.fromOffset(12,12), Position = UDim2.fromOffset(10,10), BackgroundColor3 = chosen[opt] and C.Accent or C.Muted, BorderSizePixel=0, ZIndex=42}, b)
            round(dot, 6)
            local tx = text(b, opt, 10, chosen[opt] and C.Text or C.Secondary, false)
            tx.Position = UDim2.fromOffset(30,0); tx.Size = UDim2.new(1,-40,1,0)
            bindActivate(b, function()
                chosen[opt] = not chosen[opt]
                rebuild(); updateValue()
                if type(cfg.Callback) == "function" then task.spawn(function() pcall(cfg.Callback, updateValue()) end) end
            end)
        end
        updateValue()
    end
    rebuild()
    bindActivate(valueBtn, function() open = not open; popup.Visible = open end)
    return {
        Set = function(_, values)
            table.clear(chosen)
            if type(values) == "table" then for _, value in ipairs(values) do chosen[tostring(value)] = true end end
            rebuild()
        end,
        SetValue = function(selfRef, values) selfRef:Set(values) end,
        Get = function()
            local out = {}; for _, opt in ipairs(options) do if chosen[opt] then out[#out+1]=opt end end; return out
        end,
        Refresh = function(_, values) options = normalizeArray(values or {}); rebuild() end,
        _frame = row,
    }
end

function Section:CreateTextbox(cfg)
    cfg = cfg or {}
    local current = tostring(cfg.Default or cfg.Value or "")
    local row = createControlRow(self, 50)
    controlLabel(row, cfg.Name or cfg.Title or "Input", cfg.Icon or "text-cursor-input", true)
    local box = make("TextBox", {
        Size = UDim2.new(0.56, -44, 1, -10), Position = UDim2.new(0.44, 0, 0, 5),
        BackgroundColor3 = C.Raised, BorderSizePixel = 0, ClearTextOnFocus = false,
        Text = current, PlaceholderText = tostring(cfg.Placeholder or ""),
        TextColor3 = C.Text, PlaceholderColor3 = C.Muted,
        TextSize = 11, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 15,
    }, row)
    round(box, 11)
    addPadding(box, 10, 10, 0, 0)
    box.FocusLost:Connect(function()
        current = box.Text
        if type(cfg.Callback) == "function" then task.spawn(function() pcall(cfg.Callback, current) end) end
    end)
    return {
        Set = function(_, value) current = tostring(value or ""); box.Text = current; if cfg.Callback then task.spawn(cfg.Callback, current) end end,
        SetValue = function(selfRef, value) selfRef:Set(value) end,
        Get = function() return current end,
        GetValue = function() return current end,
        _frame = row,
    }
end

function Section:CreateSlider(cfg)
    cfg = cfg or {}
    local min = tonumber(cfg.Min or cfg.Minimum) or 0
    local max = tonumber(cfg.Max or cfg.Maximum) or 100
    local value = math.clamp(tonumber(cfg.Default or cfg.Value) or min, min, max)
    local row = createControlRow(self, 62)
    local lbl = controlLabel(row, cfg.Name or cfg.Title or "Slider", cfg.Icon or "sliders-horizontal", true)
    lbl.Size = UDim2.new(0.55,0,0,22)
    local valueLbl = text(row, tostring(value), 10, C.Secondary, true)
    valueLbl.Position = UDim2.new(0.72,0,0,8); valueLbl.Size = UDim2.new(0.24,0,0,20); valueLbl.TextXAlignment = Enum.TextXAlignment.Right
    local track = make("Frame", {Position=UDim2.new(0,14,1,-24), Size=UDim2.new(1,-28,0,6), BackgroundColor3=C.Raised, BorderSizePixel=0}, row); round(track,3)
    local fill = make("Frame", {Size=UDim2.new((value-min)/math.max(0.0001,max-min),0,1,0), BackgroundColor3=C.Accent, BorderSizePixel=0}, track); round(fill,3)
    local drag = button(track, {Size=UDim2.fromScale(1,1), BackgroundTransparency=1, ZIndex=20})
    local function set(v, emit)
        value = math.clamp(tonumber(v) or min,min,max)
        local alpha=(value-min)/math.max(0.0001,max-min)
        fill.Size=UDim2.new(alpha,0,1,0); valueLbl.Text=tostring(math.floor(value*100+0.5)/100)
        if emit and type(cfg.Callback)=="function" then task.spawn(function() pcall(cfg.Callback,value) end) end
    end
    local dragging=false
    drag.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=true end
    end)
    drag.InputEnded:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType~=Enum.UserInputType.MouseMovement and input.UserInputType~=Enum.UserInputType.Touch then return end
        local x=math.clamp(input.Position.X,track.AbsolutePosition.X,track.AbsolutePosition.X+track.AbsoluteSize.X)
        local alpha=(x-track.AbsolutePosition.X)/math.max(1,track.AbsoluteSize.X)
        set(min+(max-min)*alpha,true)
    end)
    set(value,false)
    return {Set=function(_,v)set(v,true)end,SetValue=function(selfRef,v)selfRef:Set(v)end,Get=function()return value end,GetValue=function()return value end,_frame=row}
end

function Section:CreateColorpicker(cfg)
    cfg = cfg or {}
    local selected = cfg.Default or cfg.Value or C.Accent
    local row = createControlRow(self, 46)
    controlLabel(row, cfg.Name or cfg.Title or "Color", cfg.Icon or "palette", true)
    local swatch = make("Frame", {Size=UDim2.fromOffset(34,24), Position=UDim2.new(1,-48,0.5,-12), BackgroundColor3=selected, BorderSizePixel=0}, row); round(swatch,8)
    local hit=button(row,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ZIndex=20})
    bindActivate(hit,function() if type(cfg.Callback)=="function" then pcall(cfg.Callback,selected) end end)
    return {Set=function(_,v)if typeof(v)=="Color3"then selected=v;swatch.BackgroundColor3=v end end,Get=function()return selected end,_frame=row}
end

function Section:CreateLabel(value)
    local row = make("Frame", {BackgroundTransparency=1, Size=UDim2.new(1,0,0,30), LayoutOrder=self._order+1}, self._content)
    self._order=self._order+1
    local lbl=text(row,value,11,C.Muted,false); lbl.Size=UDim2.new(1,0,1,0)
    return row
end

-- Direct controls on tabs: always place them in the latest created section.
function Tab:CreateToggle(cfg) return self:_implicitSection():CreateToggle(cfg) end
function Tab:CreateButton(cfg) return self:_implicitSection():CreateButton(cfg) end
function Tab:CreateDropdown(cfg) return self:_implicitSection():CreateDropdown(cfg) end
function Tab:CreateMultiDropdown(cfg) return self:_implicitSection():CreateMultiDropdown(cfg) end
function Tab:CreateTextbox(cfg) return self:_implicitSection():CreateTextbox(cfg) end
function Tab:CreateSlider(cfg) return self:_implicitSection():CreateSlider(cfg) end
function Tab:CreateColorpicker(cfg) return self:_implicitSection():CreateColorpicker(cfg) end
function Tab:CreateLabel(value) return self:_implicitSection():CreateLabel(value) end

function Tab:CreateStatRow(items)
    local wrap = make("Frame", {BackgroundTransparency=1, Size=UDim2.new(1,0,0,58), LayoutOrder=1}, self._topStack)
    local count = #items
    for i,item in ipairs(items or {}) do
        local cell=make("Frame",{BackgroundColor3=C.Card,BorderSizePixel=0,Size=UDim2.new(1/count,-6,1,0),Position=UDim2.new((i-1)/count,((i-1)*3),0,0)},wrap)
        round(cell,14); outline(cell,C.Line,0.6,1)
        local t=text(cell,item.Title or item.Name or "",10,C.Muted,true); t.Position=UDim2.fromOffset(10,7);t.Size=UDim2.new(1,-20,0,18)
        local v=text(cell,tostring(item.Value or ""),15,C.Text,true);v.Position=UDim2.fromOffset(10,25);v.Size=UDim2.new(1,-20,0,22)
    end
    task.defer(function()self:_reflow()end)
    return wrap
end

function Tab:CreateFeaturedCard(cfg)
    cfg=cfg or {}
    local f=make("Frame",{BackgroundColor3=C.Card2,BorderSizePixel=0,Size=UDim2.new(1,0,0,86)},self._topStack)
    round(f,16); outline(f,C.Accent,0.65,1)
    if cfg.Icon then icon(f,cfg.Icon,UDim2.fromOffset(14,17),UDim2.fromOffset(24,24),C.Accent,4) end
    local t=text(f,cfg.Title or "",14,C.Text,true);t.Position=UDim2.fromOffset(cfg.Icon and 48 or 14,12);t.Size=UDim2.new(1,-64,0,24)
    local s=text(f,cfg.Description or cfg.Subtitle or "",11,C.Secondary,false);s.Position=UDim2.fromOffset(cfg.Icon and 48 or 14,38);s.Size=UDim2.new(1,-64,0,34);s.TextWrapped=true
    task.defer(function()self:_reflow()end)
    return f
end

-- ================================================================
-- WINDOW CONSTRUCTION
-- ================================================================
function Library:CreateWindow(config)
    config = config or {}
    self:SetTheme(config.Theme or "Bento")

    local vp=viewport()
    local small=vp.X<760 or vp.Y<520
    local desiredW=tonumber(config.Width) or ((config.Size and config.Size.X and config.Size.X.Offset) or 860)
    local desiredH=tonumber(config.Height) or ((config.Size and config.Size.Y and config.Size.Y.Offset) or 580)
    local shellW=small and math.max(300,math.min(vp.X-16,desiredW)) or math.max(620,math.min(vp.X-44,desiredW))
    local shellH=small and math.max(300,math.min(vp.Y-24,desiredH)) or math.max(420,math.min(vp.Y-44,desiredH))

    local gui=make("ScreenGui",{
        Name="KhfreshBentoUI",
        ResetOnSpawn=false,
        IgnoreGuiInset=true,
        DisplayOrder=2147483645,
        ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
        Enabled=true,
    },GUI_PARENT)
    pcall(function()if syn and syn.protect_gui then syn.protect_gui(gui) end end)

    local shell=make("Frame",{
        Name="Shell",
        BackgroundColor3=C.Canvas,
        BorderSizePixel=0,
        Size=UDim2.fromOffset(shellW,shellH),
        Position=UDim2.fromScale(0.5,0.5),
        AnchorPoint=Vector2.new(0.5,0.5),
        ClipsDescendants=true,
        Active=true,
        ZIndex=2,
    },gui)
    round(shell,22); outline(shell,C.Line,0.24,1)

    local bg=make("ImageLabel",{
        Name="Background",
        BackgroundTransparency=1,
        Size=UDim2.fromScale(1,1),
        Position=UDim2.fromScale(0,0),
        Image="",
        ImageTransparency=1,
        ScaleType=Enum.ScaleType.Crop,
        ZIndex=1,
    },shell)

    local scrim=make("Frame",{
        Name="BackgroundTint",
        BackgroundColor3=C.Canvas,
        BackgroundTransparency=0.36,
        Size=UDim2.fromScale(1,1),
        BorderSizePixel=0,
        ZIndex=1,
    },shell)

    local top=make("Frame",{
        Name="TopBar",
        BackgroundColor3=C.Shell,
        BackgroundTransparency=0.04,
        BorderSizePixel=0,
        Size=UDim2.new(1,-214,0,72),
        Position=UDim2.fromOffset(204,10),
        ZIndex=10,
    },shell)
    round(top,18); outline(top,C.Line,0.5,1)

    local topIcon=icon(top,config.Icon or "layout-dashboard",UDim2.fromOffset(18,22),UDim2.fromOffset(26,26),C.Accent,13)
    local title=text(top,config.Title or "Khfresh Hub",16,C.Text,true); title.Position=UDim2.fromOffset(58,12);title.Size=UDim2.new(1,-164,0,24);title.ZIndex=13
    local author=text(top,config.Author or "Khfresh",10,C.Muted,false);author.Position=UDim2.fromOffset(58,38);author.Size=UDim2.new(1,-164,0,18);author.ZIndex=13

    local closeBtn=button(top,{Size=UDim2.fromOffset(38,38),Position=UDim2.new(1,-48,0,17),BackgroundColor3=C.Raised,ZIndex=14});round(closeBtn,12);icon(closeBtn,"x",UDim2.fromOffset(10,10),UDim2.fromOffset(18,18),C.Secondary,15)
    local minBtn=button(top,{Size=UDim2.fromOffset(38,38),Position=UDim2.new(1,-92,0,17),BackgroundColor3=C.Raised,ZIndex=14});round(minBtn,12);icon(minBtn,"minus",UDim2.fromOffset(10,10),UDim2.fromOffset(18,18),C.Secondary,15)

    local rail=make("ScrollingFrame",{
        Name="Rail",BackgroundColor3=C.Rail,BackgroundTransparency=0.05,BorderSizePixel=0,
        Size=UDim2.fromOffset(194,shellH-20),Position=UDim2.fromOffset(10,10),
        CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,
        ScrollBarThickness=2,ScrollBarImageColor3=C.Muted,ZIndex=9,
    },shell)
    round(rail,18); outline(rail,C.Line,0.58,1)
    addPadding(rail,10,10,10,10)
    local railLayout=make("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},rail)

    local brand=make("Frame",{BackgroundColor3=C.Card2,BorderSizePixel=0,Size=UDim2.new(1,0,0,64),LayoutOrder=0,ZIndex=10},rail);round(brand,14)
    local brandIcon=icon(brand,config.Icon or "layout-dashboard",UDim2.fromOffset(12,12),UDim2.fromOffset(34,34),C.Accent,12);round(make("Frame",{},brand),0)
    -- The hub owns its logo asset; the library never invents one.
    local brandText=text(brand,config.Title or "Khfresh Hub",13,C.Text,true);brandText.Position=UDim2.fromOffset(54,8);brandText.Size=UDim2.new(1,-62,0,22);brandText.ZIndex=12
    local brandAuthor=text(brand,config.Author or "Khfresh",9,C.Muted,false);brandAuthor.Position=UDim2.fromOffset(54,31);brandAuthor.Size=UDim2.new(1,-62,0,18);brandAuthor.ZIndex=12

    local body=make("Frame",{
        Name="Body",BackgroundColor3=C.Canvas,BackgroundTransparency=0.10,BorderSizePixel=0,
        Size=UDim2.new(1,-214,1,-102),Position=UDim2.fromOffset(204,92),ClipsDescendants=true,ZIndex=5,
    },shell)

    local topBody=make("Frame",{Name="BodyTop",BackgroundTransparency=1,Size=UDim2.new(1,-8,0,0),Position=UDim2.fromOffset(4,4),AutomaticSize=Enum.AutomaticSize.Y,ZIndex=6},body)
    local topLayout=make("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},topBody)
    local leftCol=make("Frame",{Name="LeftColumn",BackgroundTransparency=1,Size=UDim2.new(0.5,-5,0,0),Position=UDim2.fromOffset(0,70),AutomaticSize=Enum.AutomaticSize.Y,ZIndex=6},body)
    local rightCol=make("Frame",{Name="RightColumn",BackgroundTransparency=1,Size=UDim2.new(0.5,-5,0,0),Position=UDim2.new(0.5,5,0,70),AutomaticSize=Enum.AutomaticSize.Y,ZIndex=6},body)
    local leftLayout=make("UIListLayout",{Padding=UDim.new(0,10),SortOrder=Enum.SortOrder.LayoutOrder},leftCol)
    local rightLayout=make("UIListLayout",{Padding=UDim.new(0,10),SortOrder=Enum.SortOrder.LayoutOrder},rightCol)

    local win=setmetatable({
        _gui=gui,_shell=shell,_body=body,_rail=rail,_top=top,
        _topStack=topBody,_tabs={},_active=nil,_selected=nil,
        _leftCol=leftCol,_rightCol=rightCol,
        _brand=brand,_brandText=brandText,_brandAuthor=brandAuthor,_brandIcon=brandIcon,_topIcon=topIcon,
        _background=bg,_backgroundTint=scrim,_open=true,_visible=true,_minimized=false,_alive=true,
        _connections={},_floating=nil,_mobile=small,
    },Window)

    -- Compatibility: Hub accesses Window._raw in a few boot/final checks.
    win._raw=win

    bindActivate(closeBtn,function() win:Destroy() end)
    bindActivate(minBtn,function() win:Minimize() end)

    -- Smooth drag, mouse + touch. Only the chrome area starts the drag.
    local dragging=false; local dragStart=nil; local startPos=nil
    top.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            dragging=true;dragStart=input.Position;startPos=shell.Position
        end
    end)
    table.insert(win._connections,UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType~=Enum.UserInputType.MouseMovement and input.UserInputType~=Enum.UserInputType.Touch then return end
        local delta=input.Position-dragStart
        shell.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
    end))
    table.insert(win._connections,UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=false end
    end))

    local lastViewport=nil
    local function responsive(force)
        if not win._alive then return end
        local v=viewport()
        if not force and lastViewport and lastViewport.X==v.X and lastViewport.Y==v.Y then return end
        lastViewport=v
        local m=v.X<760 or v.Y<520; win._mobile=m
        local w=m and math.max(300,math.min(v.X-16,desiredW)) or math.max(620,math.min(v.X-44,desiredW))
        local h=m and math.max(300,math.min(v.Y-24,desiredH)) or math.max(420,math.min(v.Y-44,desiredH))
        shell.Size=UDim2.fromOffset(w,h)
        if m then
            rail.Size=UDim2.fromOffset(64,h-20)
            top.Position=UDim2.fromOffset(76,10);top.Size=UDim2.new(1,-86,0,64)
            body.Position=UDim2.fromOffset(76,84);body.Size=UDim2.new(1,-86,1,-94)
            brand.Size=UDim2.new(1,0,0,54)
            brandText.Visible=false;brandAuthor.Visible=false
            brandIcon.Position=UDim2.fromOffset(15,10);brandIcon.Size=UDim2.fromOffset(30,30)
        else
            rail.Size=UDim2.fromOffset(194,h-20)
            top.Position=UDim2.fromOffset(204,10);top.Size=UDim2.new(1,-214,0,72)
            body.Position=UDim2.fromOffset(204,92);body.Size=UDim2.new(1,-214,1,-102)
            brand.Size=UDim2.new(1,0,0,64)
            brandText.Visible=true;brandAuthor.Visible=true
            brandIcon.Position=UDim2.fromOffset(12,12);brandIcon.Size=UDim2.fromOffset(34,34)
        end
        for _,t in ipairs(win._tabs) do
            local tabLabel=t._label
            local tabIcon=t._iconImg
            if tabLabel then tabLabel.Visible=not m end
            if tabIcon then
                tabIcon.Position=m and UDim2.new(0.5,-9,0.5,-9) or UDim2.fromOffset(13,12)
            end
            t:_reflow()
        end
        if win._floating and win._floating.Parent then
            local f=win._floating:FindFirstChild("FloatingButton")
            if f then
                f.Position=m and UDim2.new(1,-72,1,-72) or UDim2.new(0,16,0.5,-29)
            end
        end
    end
    table.insert(win._connections,workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        task.defer(function() if win._alive then responsive(true) end end)
    end))
    local cam=workspace.CurrentCamera
    if cam then table.insert(win._connections,cam:GetPropertyChangedSignal("ViewportSize"):Connect(function() responsive(true) end)) end

    table.insert(self._windows,win)
    responsive(true)
    return win
end

function Window:CreateTab(nameOrConfig, iconName)
    if not self._alive then return nil end
    local cfg=type(nameOrConfig)=="table" and nameOrConfig or {Title=tostring(nameOrConfig or "Tab"),Icon=iconName}
    local title=tostring(cfg.Title or cfg.Name or "Tab")
    local ico=cfg.Icon or iconName or "circle"

    local tabBtn=button(self._rail,{Name="Tab_"..title,BackgroundColor3=C.Card2,Size=UDim2.new(1,0,0,42),ZIndex=11,LayoutOrder=#self._tabs+1})
    round(tabBtn,13);outline(tabBtn,C.Line,0.78,1)
    local tabIcon=icon(tabBtn,ico,UDim2.fromOffset(13,12),UDim2.fromOffset(18,18),C.Muted,13)
    local lbl=text(tabBtn,title,11,C.Secondary,true);lbl.Position=UDim2.fromOffset(40,0);lbl.Size=UDim2.new(1,-48,1,0);lbl.ZIndex=13

    local page=make("ScrollingFrame",{
        Name="Page_"..title,BackgroundTransparency=1,Size=UDim2.fromScale(1,1),Position=UDim2.fromScale(0,0),
        CanvasSize=UDim2.new(0,0,0,0),ScrollBarThickness=3,ScrollBarImageColor3=C.Muted,
        BorderSizePixel=0,Visible=false,ZIndex=6,Active=true,
    },self._body)
    addPadding(page,2,4,4,10)

    local tab=setmetatable({
        _window=self,_button=tabBtn,_btn=tabBtn,_scroll=page,_body=page,
        _title=title,_name=title,_icon=ico,_iconImg=tabIcon,_label=lbl,_tabs={},
        _sections={},_lastSection=nil,_alive=true,_mobile=self._mobile,
        _topStack=nil,_leftCol=nil,_rightCol,_order=0,
    },Tab)
    -- tab-local stacks
    local topStack=make("Frame",{Name="TopStack",BackgroundTransparency=1,Size=UDim2.new(1,-4,0,0),Position=UDim2.fromOffset(0,0),AutomaticSize=Enum.AutomaticSize.Y,ZIndex=7},page)
    local topLayout=make("UIListLayout",{Name="UIListLayout",Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},topStack)
    local left=make("Frame",{Name="LeftColumn",BackgroundTransparency=1,Size=UDim2.new(0.5,-5,0,0),Position=UDim2.fromOffset(0,70),AutomaticSize=Enum.AutomaticSize.Y,ZIndex=7},page)
    local right=make("Frame",{Name="RightColumn",BackgroundTransparency=1,Size=UDim2.new(0.5,-5,0,0),Position=UDim2.new(0.5,5,0,70),AutomaticSize=Enum.AutomaticSize.Y,ZIndex=7},page)
    make("UIListLayout",{Name="UIListLayout",Padding=UDim.new(0,10),SortOrder=Enum.SortOrder.LayoutOrder},left)
    make("UIListLayout",{Name="UIListLayout",Padding=UDim.new(0,10),SortOrder=Enum.SortOrder.LayoutOrder},right)
    tab._topStack=topStack;tab._leftCol=left;tab._rightCol=right;tab._headerLayout=topLayout

    table.insert(self._tabs,tab)
    bindActivate(tabBtn,function() self:_select(tab) end)
    if #self._tabs==1 then self:_select(tab) end
    return tab
end

function Window:_select(tab)
    if not self._alive or not tab then return end
    self._active=tab
    self._selected=tab
    for _,t in ipairs(self._tabs) do
        local on=t==tab
        t._scroll.Visible=on
        t._btn.BackgroundColor3=on and C.AccentSoft or C.Card2
        t._label.TextColor3=on and C.Text or C.Secondary
        if t._iconImg then t._iconImg.ImageColor3=on and C.Accent or C.Muted end
    end
end

function Window:GetTab(name)
    name=tostring(name or "")
    for _,tab in ipairs(self._tabs) do
        if tab._title==name or tab._name==name then return tab end
    end
end

function Window:SelectTab(index)
    local tab
    if type(index)=="number" then tab=self._tabs[index]
    elseif type(index)=="string" then tab=self:GetTab(index) end
    if tab then self:_select(tab) return tab end
end

function Window:Toggle()
    if not self._alive then return false end
    self._open=not self._open
    self._visible=self._open
    self._gui.Enabled=self._open
    if self._open and not self._minimized then
        self:_applyResponsive()
    end
    return self._open
end

function Window:_applyResponsive()
    local v=viewport();local m=v.X<760 or v.Y<520
    self._mobile=m
    local w=m and math.max(300,math.min(v.X-16, self._shell.AbsoluteSize.X)) or math.max(620,math.min(v.X-44, self._shell.AbsoluteSize.X))
    local h=m and math.max(300,math.min(v.Y-24, self._shell.AbsoluteSize.Y)) or math.max(420,math.min(v.Y-44, self._shell.AbsoluteSize.Y))
    self._shell.Size=UDim2.fromOffset(w,h)
    for _,tab in ipairs(self._tabs) do tab:_reflow() end
end

function Window:Open()
    if not self._alive then return end
    self._open=true;self._visible=true;self._gui.Enabled=true
    if self._minimized then self:Minimize() end
    self:_applyResponsive()
end
function Window:Close()
    if not self._alive then return end
    self._open=false;self._visible=false;self._gui.Enabled=false
end
function Window:Minimize()
    if not self._alive then return end
    self._minimized=not self._minimized
    if self._minimized then
        self._body.Visible=false
        self._rail.Visible=false
        self._top.Size=UDim2.new(1,-20,0,64)
        self._top.Position=UDim2.fromOffset(10,10)
        self._shell.Size=UDim2.fromOffset(math.max(340,self._shell.AbsoluteSize.X),84)
    else
        self._body.Visible=true;self._rail.Visible=true
        self:_applyResponsive()
    end
end
function Window:ToggleAcrylic() end

function Window:SetLogo(asset)
    if type(asset)~="string" or asset=="" then return end
    if not self._logo then
        self._logo=make("ImageLabel",{
            Name="HubLogo",BackgroundTransparency=1,Size=UDim2.fromOffset(34,34),Position=UDim2.fromOffset(12,12),
            ScaleType=Enum.ScaleType.Fit,ZIndex=14,
        },self._brand)
        self._logoCorner=nil
        self._brandIcon.Visible=false
    end
    self._logo.Image=asset
    self._logo.ImageTransparency=0
end

function Window:SetBackground(asset, transparency, tintTransparency)
    if type(asset)~="string" or asset=="" then return end
    self._background.Image=asset
    self._background.ImageTransparency=tonumber(transparency) or 0.58
    self._background.Visible=true
    self._backgroundTint.BackgroundColor3=C.Canvas
    self._backgroundTint.BackgroundTransparency=tonumber(tintTransparency) or 0.38
end

function Window:CreateFloatingToggle(config)
    config=config or {}
    if self._floating and self._floating.Parent then self._floating:Destroy() end
    local sg=make("ScreenGui",{
        Name="KhfreshFloating",ResetOnSpawn=false,IgnoreGuiInset=true,
        DisplayOrder=2147483644,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,Enabled=true,
    },GUI_PARENT)
    pcall(function()if syn and syn.protect_gui then syn.protect_gui(sg) end end)
    local btn=button(sg,{
        Name="FloatingButton",Size=UDim2.fromOffset(58,58),Position=UDim2.new(1,-74,1,-74),
        BackgroundColor3=C.Shell,ZIndex=20,
    })
    round(btn,18);outline(btn,C.Line,0.3,1)
    local iconName=config.Icon or "volleyball"
    icon(btn,iconName,UDim2.fromOffset(15,15),UDim2.fromOffset(28,28),C.Accent,22)

    local scale=make("UIScale",{Scale=1},btn)
    btn.MouseEnter:Connect(function() tween(scale,TweenInfo.new(0.16,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Scale=1.06}) end)
    btn.MouseLeave:Connect(function() tween(scale,TweenInfo.new(0.16,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Scale=1.0}) end)

    local dragging=false;local moved=false;local dragStart=nil;local startPos=nil
    btn.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            dragging=true;moved=false;dragStart=input.Position;startPos=btn.Position
        end
    end)
    btn.InputEnded:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=false end
    end)
    local conn=UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType~=Enum.UserInputType.MouseMovement and input.UserInputType~=Enum.UserInputType.Touch then return end
        local delta=input.Position-dragStart
        if math.abs(delta.X)+math.abs(delta.Y)>6 then moved=true end
        btn.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
    end)
    sg.AncestryChanged:Connect(function(_,parent) if not parent then pcall(function()conn:Disconnect()end) end end)
    bindActivate(btn,function() if not moved then self:Toggle() end end)
    self._floating=sg
    return sg
end

function Window:Destroy()
    if not self._alive then return end
    self._alive=false
    for _,c in ipairs(self._connections) do pcall(function() c:Disconnect() end) end
    if self._floating then pcall(function() self._floating:Destroy() end) end
    if self._gui then pcall(function() self._gui:Destroy() end) end
    for i,v in ipairs(Library._windows) do if v==self then table.remove(Library._windows,i) break end end
end

-- ================================================================
-- NOTIFICATIONS
-- ================================================================
function Library:Notify(config)
    config=config or {}
    if not self._notificationGui or not self._notificationGui.Parent then
        self._notificationGui=make("ScreenGui",{
            Name="KhfreshNotifications",ResetOnSpawn=false,IgnoreGuiInset=true,
            DisplayOrder=2147483000,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
        },GUI_PARENT)
        self._notificationHost=make("Frame",{
            BackgroundTransparency=1,Size=UDim2.fromScale(1,1),
        },self._notificationGui)
        addPadding(self._notificationHost,0,16,0,16)
        local lay=make("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder,HorizontalAlignment=Enum.HorizontalAlignment.Right,VerticalAlignment=Enum.VerticalAlignment.Bottom},self._notificationHost)
    end
    local card=make("Frame",{
        BackgroundColor3=C.Shell,BorderSizePixel=0,Size=UDim2.fromOffset(320,72),LayoutOrder=-math.floor(os.clock()*1000),
    },self._notificationHost)
    round(card,15);outline(card,C.Accent,0.38,1)
    icon(card,config.Icon or "info",UDim2.fromOffset(14,22),UDim2.fromOffset(24,24),C.Accent,5)
    local title=text(card,config.Title or "Khfresh",12,C.Text,true);title.Position=UDim2.fromOffset(48,10);title.Size=UDim2.new(1,-60,0,20)
    local msg=text(card,config.Content or config.Message or "",10,C.Secondary,false);msg.Position=UDim2.fromOffset(48,31);msg.Size=UDim2.new(1,-60,0,30);msg.TextWrapped=true
    task.delay(tonumber(config.Duration) or 3,function()
        if card.Parent then
            tween(card,TweenInfo.new(0.18,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{BackgroundTransparency=1})
            task.wait(0.18);if card.Parent then card:Destroy() end
        end
    end)
end

Library.Lucide = Lucide
Library.Theme = THEMES

return Library
