-- KhfreshUI — dedicated Bento Grid UI for Khfresh Hub
-- The previous BentoGridStyle is used only as an API/layout reference.
-- This library contains no feature logic from another hub and no old hub assets.
-- Icons are resolved through a Lucide icon API at runtime.

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local KhfreshLib = {
    _windows = {},
    _themeName = "Bento",
    __KhfreshHubUIVersion = "3.0.0",
    LucideURL = "https://raw.githubusercontent.com/Footagesus/Icons/main/Main-v2.lua",
}

local Themes = {
    Bento = {
        Canvas = Color3.fromRGB(9, 11, 15),
        Shell = Color3.fromRGB(14, 17, 22),
        Rail = Color3.fromRGB(12, 15, 20),
        Topbar = Color3.fromRGB(18, 22, 28),
        Card = Color3.fromRGB(19, 23, 29),
        CardRaised = Color3.fromRGB(23, 28, 35),
        Input = Color3.fromRGB(26, 31, 39),
        Hover = Color3.fromRGB(30, 36, 44),
        Pressed = Color3.fromRGB(37, 45, 55),
        Border = Color3.fromRGB(42, 51, 63),
        BorderSoft = Color3.fromRGB(31, 38, 47),
        Text = Color3.fromRGB(239, 242, 246),
        Secondary = Color3.fromRGB(179, 187, 199),
        Muted = Color3.fromRGB(121, 132, 146),
        Accent = Color3.fromRGB(92, 184, 247),
        AccentSoft = Color3.fromRGB(34, 72, 101),
        Success = Color3.fromRGB(94, 213, 157),
        Danger = Color3.fromRGB(246, 105, 124),
        Warning = Color3.fromRGB(246, 190, 91),
    },
}

local THEME = Themes.Bento
local function T() return THEME end

local function getParent()
    local ok, result = pcall(function()
        if type(gethui) == "function" then
            return gethui()
        end
        return game:GetService("CoreGui")
    end)
    if ok and result then return result end
    return LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")
end

local function protectGui(gui)
    pcall(function()
        if syn and syn.protect_gui then syn.protect_gui(gui) end
    end)
end

local function create(className, props, parent)
    local obj = Instance.new(className)
    for k, v in pairs(props or {}) do
        pcall(function() obj[k] = v end)
    end
    if parent then obj.Parent = parent end
    return obj
end

local function addCorner(parent, radius)
    return create("UICorner", {CornerRadius = UDim.new(0, radius or 12)}, parent)
end

local function addStroke(parent, color, transparency, thickness)
    return create("UIStroke", {
        Color = color or T().Border,
        Transparency = transparency or 0,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

local function addPadding(parent, left, right, top, bottom)
    return create("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
    }, parent)
end

local function tween(obj, duration, props, style, direction)
    if not obj or not obj.Parent then return end
    local ok, tw = pcall(function()
        return TweenService:Create(obj, TweenInfo.new(duration or 0.18, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out), props)
    end)
    if ok and tw then tw:Play() end
    return tw
end

local function pointerActivated(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

-- ============================================================
-- Lucide API
-- ============================================================
local Lucide = {
    Pack = nil,
    Ready = false,
    Loading = false,
}

local function cleanSource(body)
    if type(body) ~= "string" then return nil end
    body = body:gsub("^%s*```[%w_%-]*%s*\n", "")
    body = body:gsub("\n%s*```%s*$", "")
    return body
end

local function httpGet(url)
    local ok, body = pcall(function()
        if game.HttpGetAsync then return game:HttpGetAsync(url) end
        return game:HttpGet(url)
    end)
    if ok and type(body) == "string" and #body > 5000 then return body end
    local requestFn = (syn and syn.request) or http_request or request or (http and http.request)
    if type(requestFn) == "function" then
        local rok, response = pcall(requestFn, {Url = url, Method = "GET"})
        local rb = response and (response.Body or response.body)
        if rok and type(rb) == "string" and #rb > 5000 then return rb end
    end
    return nil
end

local function loadLucide()
    if Lucide.Loading or Lucide.Ready then return end
    Lucide.Loading = true
    task.spawn(function()
        local urls = {
            "https://raw.githubusercontent.com/Footagesus/Icons/main/Main-v2.lua",
            "https://raw.githubusercontent.com/Footagesus/Icons/main/Main.lua",
        }
        for _, url in ipairs(urls) do
            local body = httpGet(url)
            body = cleanSource(body)
            if body and type(loadstring) == "function" then
                local chunk, err = loadstring(body, "@KhfreshLucideAPI")
                if chunk then
                    local ok, pack = pcall(chunk)
                    if ok and type(pack) == "table" then
                        pcall(function()
                            if type(pack.SetIconsType) == "function" then
                                pack.SetIconsType("lucide")
                            end
                        end)
                        Lucide.Pack = pack
                        Lucide.Ready = true
                        Lucide.Loading = false
                        return
                    end
                end
            end
        end
        Lucide.Loading = false
    end)
end
loadLucide()

local function resolveLucide(iconName)
    iconName = tostring(iconName or "circle")
    iconName = iconName:gsub("^lucide%-", "")
    local pack = Lucide.Pack
    if not pack then return nil end

    local ok, result = pcall(function()
        if type(pack.GetIcon) == "function" then
            return pack.GetIcon(iconName, "lucide")
        end
        if type(pack.Icon2) == "function" then
            return pack.Icon2(iconName, "lucide", true)
        end
        if type(pack.Icon) == "function" then
            return pack.Icon(iconName, "lucide", true)
        end
        return nil
    end)
    if not ok or result == nil then return nil end

    if type(result) == "string" then
        return {
            Url = result,
            ImageRectOffset = Vector2.zero,
            ImageRectSize = Vector2.zero,
            IconName = iconName,
        }
    end

    if type(result) == "table" then
        local url = result.Url or result.Image or result[1]
        local meta = result
        if result[2] and type(result[2]) == "table" then meta = result[2] end
        if type(url) == "number" then url = "rbxassetid://" .. tostring(url) end
        if type(url) ~= "string" then return nil end
        return {
            Url = url,
            ImageRectOffset = meta.ImageRectPosition or meta.ImageRectOffset or Vector2.zero,
            ImageRectSize = meta.ImageRectSize or Vector2.zero,
            IconName = iconName,
        }
    end
    return nil
end

function KhfreshLib:GetIcon(iconName)
    local icon = resolveLucide(iconName)
    if icon then return icon end
    return nil
end

function KhfreshLib:IconExists(iconName)
    return self:GetIcon(iconName) ~= nil
end

function KhfreshLib:GetIconNames()
    local pack = Lucide.Pack
    if not pack then return {} end
    local result = {}
    local seen = {}
    local function collect(tbl)
        if type(tbl) ~= "table" then return end
        for key, value in pairs(tbl) do
            if type(key) == "string" and type(value) ~= "function" and not seen[key] then
                seen[key] = true
                result[#result + 1] = key
            end
        end
    end
    pcall(function()
        if pack.Icons and pack.Icons.lucide then
            local set = pack.Icons.lucide
            collect(set.Icons)
            collect(set)
        end
    end)
    table.sort(result)
    return result
end

local function iconObject(parent, iconName, size, color, z)
    local requested = tostring(iconName or "circle"):gsub("^lucide%-", "")
    local img = create("ImageLabel", {
        Name = "LucideIcon",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(size or 18, size or 18),
        Image = "",
        ImageColor3 = color or T().Secondary,
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = z or 20,
        Active = false,
    }, parent)

    local applied = false
    local function apply()
        local info = resolveLucide(requested)
        if not info then
            local fallback = resolveLucide("circle")
            info = fallback
        end
        if not info then return false end
        img.Image = info.Url
        img.ImageRectOffset = info.ImageRectOffset or Vector2.zero
        img.ImageRectSize = info.ImageRectSize or Vector2.zero
        applied = true
        return true
    end
    if not apply() then
        task.spawn(function()
            for _ = 1, 50 do
                task.wait(0.1)
                if img.Parent and apply() then break end
            end
        end)
    end
    return img
end

function KhfreshLib:CreateIcon(parent, iconName, size, color, z)
    return iconObject(parent, iconName, size, color, z)
end

-- ============================================================
-- Notifications
-- ============================================================
local NotificationGui
local NotificationStack

local function getNotificationStack()
    if NotificationStack and NotificationStack.Parent then return NotificationStack end
    NotificationGui = create("ScreenGui", {
        Name = "KhfreshNotifications",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 2147483646,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, getParent())
    protectGui(NotificationGui)
    NotificationStack = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -18, 0, 18),
        AnchorPoint = Vector2.new(1, 0),
        Size = UDim2.fromOffset(330, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 900,
    }, NotificationGui)
    addPadding(NotificationStack, 0, 0, 0, 0)
    local list = create("UIListLayout", {
        Padding = UDim.new(0, 8),
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, NotificationStack)
    return NotificationStack
end

function KhfreshLib:Notify(cfg)
    cfg = cfg or {}
    local stack = getNotificationStack()
    local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(900, 700)
    local noteWidth = math.max(240, math.min(318, viewport.X - 28))
    local card = create("Frame", {
        BackgroundColor3 = T().CardRaised,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(noteWidth, 68),
        LayoutOrder = os.clock() * 1000,
        ZIndex = 901,
    }, stack)
    addCorner(card, 14)
    addStroke(card, T().Border, 0.1, 1)

    local iconBox = create("Frame", {
        BackgroundColor3 = T().AccentSoft,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(10, 12),
        Size = UDim2.fromOffset(42, 42),
        ZIndex = 902,
    }, card)
    addCorner(iconBox, 12)
    iconObject(iconBox, cfg.Icon or "bell", 19, T().Accent, 903).Position = UDim2.fromOffset(11, 11)

    local title = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(62, 10),
        Size = UDim2.new(1, -72, 0, 22),
        Text = tostring(cfg.Title or "Khfresh Hub"),
        TextColor3 = T().Text,
        TextSize = 13,
        Font = Enum.Font.GothamSemibold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 903,
    }, card)
    local content = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(62, 30),
        Size = UDim2.new(1, -72, 0, 27),
        Text = tostring(cfg.Message or cfg.Content or ""),
        TextColor3 = T().Secondary,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = 903,
    }, card)

    card.Position = UDim2.new(1, 24, 0, 0)
    tween(card, 0.25, {Position = UDim2.new(1, 0, 0, 0)})
    local duration = math.max(tonumber(cfg.Duration) or 3, 0.5)
    task.delay(duration, function()
        if card.Parent then
            tween(card, 0.18, {Position = UDim2.new(1, 24, 0, 0)})
            task.wait(0.2)
            if card.Parent then card:Destroy() end
        end
    end)
    return card
end

-- ============================================================
-- Window / Tab / Section / Controls
-- ============================================================
local Window = {}
Window.__index = Window
local Tab = {}
Tab.__index = Tab
local Section = {}
Section.__index = Section
local Control = {}
Control.__index = Control

local function setControlValue(control, value, fire)
    if control._destroyed then return end
    control._value = value
    if control._setVisual then pcall(control._setVisual, value) end
    if fire and type(control._callback) == "function" then
        task.spawn(function()
            local ok, err = pcall(control._callback, value)
            if not ok then warn("[KhfreshUI] Callback error: " .. tostring(err)) end
        end)
    end
end

function Control:GetValue()
    return self._value
end

function Control:SetValue(value, fireCallback)
    setControlValue(self, value, fireCallback == true)
end

function Control:Set(value)
    self:SetValue(value, true)
end

function Control:OnChanged(fn)
    self._callback = fn
    return self
end

function Control:Destroy()
    self._destroyed = true
    if self._row then self._row:Destroy() end
end

local function controlRow(section, height)
    local row = create("Frame", {
        BackgroundColor3 = T().CardRaised,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, height or 44),
        ZIndex = 30,
    }, section._controls)
    addCorner(row, 12)
    addStroke(row, T().BorderSoft, 0.1, 1)
    return row
end

local function controlIcon(row, iconName)
    local box = create("Frame", {
        BackgroundColor3 = T().Input,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(8, 8),
        Size = UDim2.fromOffset(28, 28),
        ZIndex = 31,
    }, row)
    addCorner(box, 9)
    local icon = iconObject(box, iconName or "circle", 15, T().Secondary, 32)
    icon.Position = UDim2.fromOffset(7, 7)
end

local function controlTitle(row, cfg, widthOffset)
    local label = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(45, 0),
        Size = UDim2.new(1, -(widthOffset or 62), 1, 0),
        Text = tostring(cfg.Name or cfg.Title or "Control"),
        TextColor3 = T().Text,
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 32,
    }, row)
    return label
end

local function addRowHover(target, base, hover)
    if not target or not target:IsA("GuiButton") then return end
    target.AutoButtonColor = false
    target.MouseEnter:Connect(function() tween(target, 0.12, {BackgroundColor3 = hover or T().Hover}) end)
    target.MouseLeave:Connect(function() tween(target, 0.14, {BackgroundColor3 = base or T().CardRaised}) end)
end

function Section:CreateToggle(cfg)
    cfg = cfg or {}
    local row = controlRow(self, 44)
    controlIcon(row, cfg.Icon or "circle-check")
    controlTitle(row, cfg, 74)

    local switch = create("TextButton", {
        BackgroundColor3 = T().Border,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Position = UDim2.new(1, -54, 0.5, -12),
        Size = UDim2.fromOffset(44, 24),
        ZIndex = 36,
        Active = true,
    }, row)
    addCorner(switch, 12)
    local knob = create("Frame", {
        BackgroundColor3 = Color3.fromRGB(199, 206, 217),
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(3, 3),
        Size = UDim2.fromOffset(18, 18),
        ZIndex = 37,
    }, switch)
    addCorner(knob, 9)

    local c = setmetatable({
        _row = row,
        _switch = switch,
        _knob = knob,
        _value = cfg.Default == true,
        _callback = cfg.Callback,
        _window = self._tab._window,
    }, Control)

    c._setVisual = function(value)
        local on = value == true
        tween(switch, 0.16, {BackgroundColor3 = on and T().Accent or T().Border})
        tween(knob, 0.16, {Position = on and UDim2.new(1, -21, 0, 3) or UDim2.fromOffset(3, 3)})
        knob.BackgroundColor3 = on and Color3.fromRGB(250, 252, 255) or Color3.fromRGB(199, 206, 217)
    end
    c._setVisual(c._value)

    switch.Activated:Connect(function()
        c:SetValue(not c._value, true)
    end)
    row.InputBegan:Connect(function(input)
        if pointerActivated(input) and input.UserInputType == Enum.UserInputType.Touch then
            c:SetValue(not c._value, true)
        end
    end)
    return c
end

function Section:CreateButton(cfg)
    cfg = cfg or {}
    local row = create("TextButton", {
        BackgroundColor3 = T().CardRaised,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Size = UDim2.new(1, 0, 0, 44),
        ZIndex = 30,
        Active = true,
    }, self._controls)
    addCorner(row, 12)
    addStroke(row, T().BorderSoft, 0.1, 1)
    controlIcon(row, cfg.Icon or "play")
    controlTitle(row, cfg, 72)
    iconObject(row, cfg.IconRight or "arrow-up-right", 14, T().Muted, 34).Position = UDim2.new(1, -28, 0.5, -7)
    addRowHover(row)
    row.Activated:Connect(function()
        if cfg.Disabled then return end
        tween(row, 0.08, {BackgroundColor3 = T().Pressed})
        task.delay(0.09, function() if row.Parent then tween(row, 0.13, {BackgroundColor3 = T().CardRaised}) end end)
        if type(cfg.Callback) == "function" then
            task.spawn(function()
                local ok, err = pcall(cfg.Callback)
                if not ok then warn("[KhfreshUI] Callback error: " .. tostring(err)) end
            end)
        end
    end)
    return setmetatable({_row = row, _value = false, _callback = cfg.Callback, _window = self._tab._window}, Control)
end

local function buildDropdownPopup(control, multiple)
    if control._popup and control._popup.Parent then
        control._popup:Destroy()
        control._popup = nil
        return
    end
    local window = control._window
    if not window or not window._shell then return end

    local popup = create("Frame", {
        BackgroundColor3 = T().Shell,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(math.max(220, math.min(330, control._row.AbsoluteSize.X)), math.min(250, 44 + (#control._options * 32))),
        ZIndex = 500,
        Active = true,
    }, window._gui)
    addCorner(popup, 14)
    addStroke(popup, T().Border, 0.02, 1)

    local rowPos = control._row.AbsolutePosition
    local shellPos = window._shell.AbsolutePosition
    local viewport = window._shell.AbsoluteSize
    local x = rowPos.X - shellPos.X
    local y = rowPos.Y - shellPos.Y + control._row.AbsoluteSize.Y + 6
    local width = popup.AbsoluteSize.X
    if x + width > viewport.X - 8 then x = math.max(8, viewport.X - width - 8) end
    popup.Position = UDim2.fromOffset(x, y)

    local scroll = create("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(6, 6),
        Size = UDim2.new(1, -12, 1, -12),
        ScrollBarThickness = 3,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ZIndex = 501,
    }, popup)
    addCorner(scroll, 9)
    local list = create("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, scroll)

    for index, option in ipairs(control._options) do
        local selected = multiple and control._selected[option] or control._value == option
        local choice = create("TextButton", {
            BackgroundColor3 = selected and T().AccentSoft or T().Card,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = "",
            Size = UDim2.new(1, -4, 0, 32),
            LayoutOrder = index,
            ZIndex = 502,
            Active = true,
        }, scroll)
        addCorner(choice, 9)
        local txt = create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(10, 0),
            Size = UDim2.new(1, -42, 1, 0),
            Text = tostring(option),
            TextColor3 = selected and T().Accent or T().Text,
            TextSize = 11,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 503,
        }, choice)
        if multiple then
            iconObject(choice, selected and "check" or "circle", 13, selected and T().Accent or T().Muted, 503).Position = UDim2.new(1, -24, 0.5, -6.5)
        end
        choice.MouseEnter:Connect(function() tween(choice, 0.1, {BackgroundColor3 = T().Hover}) end)
        choice.MouseLeave:Connect(function() tween(choice, 0.1, {BackgroundColor3 = selected and T().AccentSoft or T().Card}) end)
        choice.Activated:Connect(function()
            if multiple then
                control._selected[option] = not control._selected[option]
                local values = {}
                for _, v in ipairs(control._options) do
                    if control._selected[v] then values[#values + 1] = v end
                end
                control:SetValue(values, true)
                if control._valueLabel then
                    control._valueLabel.Text = #values > 0 and table.concat(values, ", ") or (control._placeholder or "Select options")
                end
                buildDropdownPopup(control, multiple)
            else
                control:SetValue(option, true)
                if control._valueLabel then control._valueLabel.Text = tostring(option) end
                popup:Destroy()
                control._popup = nil
            end
        end)
    end
    control._popup = popup
end

function Section:_createDropdown(cfg, multiple)
    cfg = cfg or {}
    local row = controlRow(self, multiple and 54 or 54)
    controlIcon(row, cfg.Icon or (multiple and "list-checks" or "chevron-down"))
    controlTitle(row, cfg, 52)

    local valueBack = create("TextButton", {
        BackgroundColor3 = T().Input,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Position = UDim2.fromOffset(145, 9),
        Size = UDim2.new(1, -154, 0, 36),
        ZIndex = 34,
        Active = true,
    }, row)
    addCorner(valueBack, 10)
    local valueLabel = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(10, 0),
        Size = UDim2.new(1, -38, 1, 0),
        Text = "",
        TextColor3 = T().Secondary,
        TextSize = 10,
        Font = Enum.Font.Gotham,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 35,
    }, valueBack)
    iconObject(valueBack, "chevron-down", 14, T().Secondary, 35).Position = UDim2.new(1, -24, 0.5, -7)

    local options = cfg.Options or {}
    local selected = {}
    if multiple and type(cfg.Default) == "table" then
        for _, v in ipairs(cfg.Default) do selected[v] = true end
    end

    local c = setmetatable({
        _row = row,
        _window = self._tab._window,
        _options = options,
        _callback = cfg.Callback,
        _selected = selected,
        _value = multiple and (type(cfg.Default) == "table" and cfg.Default or {}) or cfg.Default,
        _valueLabel = valueLabel,
        _placeholder = cfg.Placeholder or (multiple and "Select options" or "Select an option"),
    }, Control)

    if multiple then
        local vals = {}
        for _, v in ipairs(options) do if selected[v] then vals[#vals + 1] = tostring(v) end end
        valueLabel.Text = #vals > 0 and table.concat(vals, ", ") or c._placeholder
    else
        valueLabel.Text = cfg.Default ~= nil and tostring(cfg.Default) or c._placeholder
    end

    valueBack.MouseEnter:Connect(function() tween(valueBack, 0.1, {BackgroundColor3 = T().Hover}) end)
    valueBack.MouseLeave:Connect(function() tween(valueBack, 0.1, {BackgroundColor3 = T().Input}) end)
    valueBack.Activated:Connect(function()
        if cfg.Disabled then return end
        buildDropdownPopup(c, multiple)
    end)
    return c
end

function Section:CreateDropdown(cfg) return self:_createDropdown(cfg, false) end
function Section:CreateMultiDropdown(cfg) return self:_createDropdown(cfg, true) end

function Section:CreateTextbox(cfg)
    cfg = cfg or {}
    local row = controlRow(self, 52)
    controlIcon(row, cfg.Icon or "text-cursor-input")
    local title = controlTitle(row, cfg, 155)
    title.Size = UDim2.new(0, 94, 1, 0)

    local box = create("TextBox", {
        BackgroundColor3 = T().Input,
        BorderSizePixel = 0,
        TextColor3 = T().Text,
        PlaceholderColor3 = T().Muted,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Text = cfg.Default ~= nil and tostring(cfg.Default) or "",
        PlaceholderText = cfg.Placeholder or "Enter value...",
        Position = UDim2.new(0, 143, 0.5, -16),
        Size = UDim2.new(1, -152, 0, 32),
        ZIndex = 35,
        Active = true,
    }, row)
    addCorner(box, 10)
    addPadding(box, 9, 8, 0, 0)

    local c = setmetatable({
        _row = row,
        _box = box,
        _value = box.Text,
        _callback = cfg.Callback,
        _window = self._tab._window,
    }, Control)

    box.FocusLost:Connect(function()
        c._value = box.Text
        if type(c._callback) == "function" then
            task.spawn(function()
                local ok, err = pcall(c._callback, box.Text)
                if not ok then warn("[KhfreshUI] Callback error: " .. tostring(err)) end
            end)
        end
    end)
    c._setVisual = function(value)
        box.Text = tostring(value or "")
        c._value = box.Text
    end
    return c
end

function Section:CreateLabel(cfg)
    cfg = type(cfg) == "table" and cfg or {Text = tostring(cfg or "")}
    local row = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, cfg.Height or 30),
        ZIndex = 30,
    }, self._controls)
    local txt = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(5, 0),
        Size = UDim2.new(1, -10, 1, 0),
        Text = tostring(cfg.Text or cfg.Name or ""),
        TextColor3 = cfg.TextColor or T().Secondary,
        TextSize = cfg.TextSize or 11,
        Font = Enum.Font.Gotham,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 31,
    }, row)
    return {Instance = row, Label = txt}
end

local function normalizeSectionInput(input)
    if type(input) == "table" then return input end
    return {Title = tostring(input or "Section")}
end

function Tab:_reflow()
    if not self._scroll or not self._left or not self._right then return end
    local camera = workspace.CurrentCamera
    local width = camera and camera.ViewportSize.X or 900
    local small = width < 720
    self._small = small

    for _, section in ipairs(self._sections) do
        if section._frame then section._frame.Parent = self._left end
    end
    if not small then
        for i, section in ipairs(self._sections) do
            section._frame.Parent = (i % 2 == 1) and self._left or self._right
        end
        self._left.Size = UDim2.new(0.5, -5, 0, 0)
        self._right.Size = UDim2.new(0.5, -5, 0, 0)
    else
        self._left.Size = UDim2.new(1, 0, 0, 0)
        self._right.Size = UDim2.fromOffset(0, 0)
    end
    self._right.Visible = not small
    self._small = small
end

function Tab:_resizeColumns()
    if not self._left or not self._right then return end
    -- Both columns use AutomaticSize.Y; the ScrollingFrame uses AutomaticCanvasSize.Y.
end

function Tab:CreateHeader(cfg)
    cfg = type(cfg) == "table" and cfg or {Title = tostring(cfg or "Header")}
    local card = create("Frame", {
        BackgroundColor3 = T().Topbar,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 72),
        ZIndex = 40,
    }, self._headerHolder)
    addCorner(card, 15)
    addStroke(card, T().Border, 0.08, 1)
    if cfg.Icon then iconObject(card, cfg.Icon, 22, T().Accent, 41).Position = UDim2.fromOffset(16, 25) end
    local x = cfg.Icon and 52 or 16
    create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(x, 13),
        Size = UDim2.new(1, -x - 14, 0, 24),
        Text = tostring(cfg.Title or "Header"),
        TextColor3 = T().Text,
        TextSize = 16,
        Font = Enum.Font.GothamSemibold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 41,
    }, card)
    create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(x, 37),
        Size = UDim2.new(1, -x - 14, 0, 22),
        Text = tostring(cfg.Subtitle or ""),
        TextColor3 = T().Muted,
        TextSize = 10,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 41,
    }, card)
    if self._syncHeaderLayout then task.defer(self._syncHeaderLayout) end
    return card
end

function Tab:_default()
    if self._lastSection then return self._lastSection end
    return self:CreateSection("General")
end

function Tab:CreateSection(input)
    local cfg = normalizeSectionInput(input)
    local frame = create("Frame", {
        BackgroundColor3 = T().Card,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 86),
        ZIndex = 30,
    }, self._left)
    addCorner(frame, 18)
    addStroke(frame, T().Border, 0.06, 1)

    local head = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 48),
        ZIndex = 31,
    }, frame)
    if cfg.Icon then iconObject(head, cfg.Icon, 18, T().Accent, 33).Position = UDim2.fromOffset(16, 15) end
    local hx = cfg.Icon and 44 or 16
    create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(hx, 0),
        Size = UDim2.new(1, -hx - 16, 1, 0),
        Text = tostring(cfg.Title or "Section"),
        TextColor3 = T().Text,
        TextSize = 13,
        Font = Enum.Font.GothamSemibold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 33,
    }, head)

    local controls = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 46),
        Size = UDim2.new(1, -24, 30, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 32,
    }, frame)
    local layout = create("UIListLayout", {
        Padding = UDim.new(0, 8),
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, controls)

    local section = setmetatable({
        _tab = self,
        _frame = frame,
        _controls = controls,
        _layout = layout,
        _baseHeight = 54,
        _name = tostring(cfg.Title or "Section"),
    }, Section)
    self._sections[#self._sections + 1] = section
    self._lastSection = section

    local function resize()
        task.defer(function()
            if not frame.Parent then return end
            local h = math.max(80, 52 + controls.AbsoluteSize.Y)
            frame.Size = UDim2.new(1, 0, 0, h)
        end)
    end
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resize)
    resize()
    self:_reflow()
    return section
end

function Tab:CreateButton(cfg) return self:_default():CreateButton(cfg) end
function Tab:CreateToggle(cfg) return self:_default():CreateToggle(cfg) end
function Tab:CreateDropdown(cfg) return self:_default():CreateDropdown(cfg) end
function Tab:CreateMultiDropdown(cfg) return self:_default():CreateMultiDropdown(cfg) end
function Tab:CreateTextbox(cfg) return self:_default():CreateTextbox(cfg) end
function Tab:CreateLabel(cfg) return self:_default():CreateLabel(cfg) end

function Window:CreateTab(input)
    local cfg = type(input) == "table" and input or {Title = tostring(input or "Tab")}
    local title = tostring(cfg.Title or cfg.Name or "Tab")
    local icon = tostring(cfg.Icon or "circle")

    local pageButton = create("TextButton", {
        BackgroundColor3 = T().Rail,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Size = UDim2.new(1, -14, 0, 44),
        LayoutOrder = #self._tabs + 1,
        ZIndex = 33,
        Active = true,
    }, self._navScroll)
    addCorner(pageButton, 12)
    local iconFrame = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(9, 9),
        Size = UDim2.fromOffset(26, 26),
        ZIndex = 34,
    }, pageButton)
    local img = iconObject(iconFrame, icon, 17, T().Secondary, 35)
    img.Position = UDim2.fromOffset(4, 4)
    local label = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(43, 0),
        Size = UDim2.new(1, -51, 1, 0),
        Text = title,
        TextColor3 = T().Secondary,
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 35,
    }, pageButton)

    local page = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Visible = false,
        ZIndex = 25,
    }, self._pageHost)

    local headerHolder = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 40,
    }, page)
    local headerList = create("UIListLayout", {
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, headerHolder)
    local scroll = create("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = T().Border,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ZIndex = 26,
        Active = true,
    }, page)
    addPadding(scroll, 2, 10, 2, 12)

    -- Header is a separate overlay band so tabs never sit underneath it.
    headerHolder.Position = UDim2.fromOffset(2, 2)
    headerHolder.Size = UDim2.new(1, -14, 0, 0)
    headerHolder.ZIndex = 45
    local columns = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 27,
    }, scroll)
    local left = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0.5, -5, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 28,
    }, columns)
    local right = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 5, 0, 0),
        Size = UDim2.new(0.5, -5, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 28,
    }, columns)
    local leftList = create("UIListLayout", {Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder}, left)
    local rightList = create("UIListLayout", {Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder}, right)

    local tab = setmetatable({
        _window = self,
        _name = title,
        _icon = icon,
        _button = pageButton,
        _page = page,
        _headerHolder = headerHolder,
        _scroll = scroll,
        _columns = columns,
        _left = left,
        _right = right,
        _leftList = leftList,
        _rightList = rightList,
        _sections = {},
        _lastSection = nil,
    }, Tab)

    local function syncHeaderLayout()
        local h = headerHolder.AbsoluteSize.Y
        scroll.Position = UDim2.fromOffset(0, h > 0 and (h + 10) or 0)
        scroll.Size = UDim2.new(1, 0, 1, -(h > 0 and (h + 10) or 0))
    end
    tab._syncHeaderLayout = syncHeaderLayout
    headerList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(syncHeaderLayout)
    syncHeaderLayout()

    pageButton.Activated:Connect(function()
        self:SelectTab(title)
    end)
    pageButton.MouseEnter:Connect(function()
        if self._active ~= tab then tween(pageButton, 0.1, {BackgroundColor3 = T().Hover}) end
    end)
    pageButton.MouseLeave:Connect(function()
        tween(pageButton, 0.1, {BackgroundColor3 = self._active == tab and T().Pressed or T().Rail})
    end)

    self._tabs[#self._tabs + 1] = tab
    self:_applyResponsive()
    if #self._tabs == 1 then self:SelectTab(1) end
    return tab
end

function Window:GetTab(name)
    for _, tab in ipairs(self._tabs) do
        if string.lower(tostring(tab._name)) == string.lower(tostring(name)) then return tab end
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
    if not target then return nil end

    for _, tab in ipairs(self._tabs) do
        local active = tab == target
        tab._page.Visible = active
        tab._button.BackgroundColor3 = active and T().Pressed or T().Rail
        local icon = tab._button:FindFirstChild("LucideIcon", true)
        if icon and icon:IsA("ImageLabel") then icon.ImageColor3 = active and T().Accent or T().Secondary end
        local label = tab._button:FindFirstChildWhichIsA("TextLabel", true)
        if label then label.TextColor3 = active and T().Text or T().Secondary end
    end
    self._active = target
    self._pageTitle.Text = target._name
    self._pageSubtitle.Text = "Khfresh Hub"
    if target._scroll then target._scroll.CanvasPosition = Vector2.zero end
    return target
end

function Window:_applyResponsive()
    local cam = workspace.CurrentCamera
    local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
    local small = vp.X < 720
    self._small = small
    if small then
        self._rail.Size = UDim2.fromOffset(72, 0)
        self._brandText.Visible = false
        self._brandAuthor.Visible = false
        for _, tab in ipairs(self._tabs) do
            local label = tab._button:FindFirstChildWhichIsA("TextLabel", true)
            if label then label.Visible = false end
            tab:_reflow()
        end
        self._content.Position = UDim2.fromOffset(82, 8)
        self._content.Size = UDim2.new(1, -90, 1, -16)
    else
        self._rail.Size = UDim2.fromOffset(214, 0)
        self._brandText.Visible = true
        self._brandAuthor.Visible = true
        for _, tab in ipairs(self._tabs) do
            local label = tab._button:FindFirstChildWhichIsA("TextLabel", true)
            if label then label.Visible = true end
            tab:_reflow()
        end
        self._content.Position = UDim2.fromOffset(224, 10)
        self._content.Size = UDim2.new(1, -234, 1, -20)
    end

    local minW = small and 300 or 540
    local minH = small and 300 or 340
    local maxW = math.max(minW, math.min(vp.X - (small and 12 or 32), 1040))
    local maxH = math.max(minH, math.min(vp.Y - (small and 14 or 32), 700))
    self._shell.Size = UDim2.fromOffset(maxW, maxH)
    self._floating.Position = self._floating.Position
end

function Window:Toggle()
    self._visible = not self._visible
    self._gui.Enabled = self._visible
    if self._visible then
        self:_applyResponsive()
    end
    return self._visible
end

function Window:Open()
    self._visible = true
    self._gui.Enabled = true
    self:_applyResponsive()
end

function Window:Close()
    self._visible = false
    self._gui.Enabled = false
end

function Window:Minimize()
    self._minimized = not self._minimized
    if self._minimized then
        self._body.Visible = false
        self._shell.Size = UDim2.fromOffset(math.max(360, self._shell.AbsoluteSize.X), 82)
        self._minButtonText.ImageColor3 = T().Accent
    else
        self._body.Visible = true
        self:_applyResponsive()
    end
end

function Window:SetLogo(asset)
    local hasLogo = asset ~= nil and tostring(asset) ~= ""
    self._logo.Image = hasLogo and tostring(asset) or ""
    self._logo.ImageRectOffset = Vector2.zero
    self._logo.ImageRectSize = Vector2.zero
    self._logo.Visible = hasLogo
    local x = hasLogo and 64 or 16
    self._pageTitle.Position = UDim2.fromOffset(x, 9)
    self._pageTitle.Size = UDim2.new(1, -x - 122, 0, 29)
    self._pageSubtitle.Position = UDim2.fromOffset(x, 36)
    self._pageSubtitle.Size = UDim2.new(1, -x - 122, 0, 22)
    return self
end

function Window:SetBackground(asset, imageTransparency, shadeTransparency)
    if asset == nil or tostring(asset) == "" then
        self._background.Visible = false
        self._backgroundShade.Visible = false
        return self
    end
    self._background.Image = tostring(asset)
    self._background.ImageRectOffset = Vector2.zero
    self._background.ImageRectSize = Vector2.zero
    self._background.ImageTransparency = math.clamp(tonumber(imageTransparency) or 0.55, 0, 1)
    self._backgroundShade.BackgroundTransparency = math.clamp(tonumber(shadeTransparency) or 0.55, 0, 1)
    self._background.Visible = true
    self._backgroundShade.Visible = true
    return self
end

function Window:SetFloatingEnabled(enabled)
    self._floating.Enabled = enabled == true
    return self
end

function Window:CreateFloatingToggle(cfg)
    cfg = cfg or {}
    local iconName = cfg.Icon or "volleyball"
    local parent = self._floating
    local button = self._floatingButton
    if not button then return self._floating end
    button:ClearAllChildren()
    local inner = create("Frame", {
        BackgroundColor3 = T().CardRaised,
        BackgroundTransparency = 0.02,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 2,
    }, button)
    addCorner(inner, 18)
    addStroke(inner, T().Border, 0.02, 1)
    local img = iconObject(inner, iconName, 23, T().Accent, 4)
    img.Position = UDim2.new(0.5, -11.5, 0.5, -11.5)

    local scale = create("UIScale", {Scale = 1}, button)
    local dragging = false
    local dragStart
    local startPos
    local moved = false

    button.InputBegan:Connect(function(input)
        if pointerActivated(input) then
            dragging = true
            moved = false
            dragStart = input.Position
            startPos = button.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    button.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            if math.abs(delta.X) + math.abs(delta.Y) > 6 then moved = true end
            button.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    button.MouseEnter:Connect(function() tween(scale, 0.13, {Scale = 1.07}) end)
    button.MouseLeave:Connect(function() tween(scale, 0.13, {Scale = 1}) end)
    button.Activated:Connect(function()
        if not moved then self:Toggle() end
    end)
    self._floatingButton = button
    return self._floating
end

function Window:Destroy()
    if self._gui then self._gui:Destroy(); self._gui = nil end
    self._floating = nil
end

function KhfreshLib:SetTheme(name)
    THEME = Themes[tostring(name)] or Themes.Bento
    self._themeName = tostring(name)
    for _, win in ipairs(self._windows) do
        pcall(function() win:_refreshColors() end)
    end
    return self
end

function Window:_refreshColors()
    if not self._shell then return end
    -- Current controls use colors during construction. Rebuilding colors is intentionally
    -- conservative so runtime theme switches do not break Roblox UI instances.
    self._shell.BackgroundColor3 = T().Shell
    self._rail.BackgroundColor3 = T().Rail
    self._topbar.BackgroundColor3 = T().Topbar
end

function KhfreshLib:CreateWindow(config)
    config = config or {}
    self:DestroyAll()

    local parent = getParent()
    local gui = create("ScreenGui", {
        Name = "KhfreshPanel",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 2147483645,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Enabled = true,
    }, parent)
    protectGui(gui)

    local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
    local small = viewport.X < 720
    local shellW = math.max(small and 300 or 540, math.min(viewport.X - (small and 12 or 32), 1040))
    local shellH = math.max(small and 300 or 340, math.min(viewport.Y - (small and 14 or 32), 700))

    local shell = create("Frame", {
        Name = "Shell",
        BackgroundColor3 = T().Shell,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(shellW, shellH),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ClipsDescendants = true,
        ZIndex = 10,
    }, gui)
    addCorner(shell, 22)
    addStroke(shell, T().Border, 0.04, 1.2)

    local background = create("ImageLabel", {
        Name = "Background",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.fromScale(1, 1),
        Image = "",
        ImageTransparency = 0.58,
        ScaleType = Enum.ScaleType.Crop,
        Visible = false,
        ZIndex = 11,
    }, shell)
    addCorner(background, 22)
    local shade = create("Frame", {
        Name = "BackgroundShade",
        BackgroundColor3 = Color3.fromRGB(5, 8, 11),
        BackgroundTransparency = 0.58,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        Visible = false,
        ZIndex = 12,
    }, shell)
    addCorner(shade, 22)

    local rail = create("Frame", {
        Name = "Rail",
        BackgroundColor3 = T().Rail,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.fromOffset(small and 72 or 214, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 20,
    }, shell)
    addCorner(rail, 22)

    local brand = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 12),
        Size = UDim2.new(1, -24, 0, 62),
        ZIndex = 30,
    }, rail)
    local brandIcon = create("Frame", {
        BackgroundColor3 = T().AccentSoft,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(2, 4),
        Size = UDim2.fromOffset(48, 48),
        ZIndex = 31,
    }, brand)
    addCorner(brandIcon, 14)
    iconObject(brandIcon, config.Icon or "layout-dashboard", 22, T().Accent, 32).Position = UDim2.fromOffset(13, 13)
    local brandText = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(62, 2),
        Size = UDim2.new(1, -62, 0, 26),
        Text = tostring(config.Title or "Khfresh Hub"),
        TextColor3 = T().Text,
        TextSize = 15,
        Font = Enum.Font.GothamSemibold,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 32,
    }, brand)
    local brandAuthor = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(62, 29),
        Size = UDim2.new(1, -62, 0, 20),
        Text = tostring(config.Author or "Khfresh"),
        TextColor3 = T().Muted,
        TextSize = 9,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 32,
    }, brand)

    local navScroll = create("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(8, 84),
        Size = UDim2.new(1, -16, 1, -102),
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 0,
        ZIndex = 30,
        Active = true,
    }, rail)
    local navList = create("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, navScroll)

    local content = create("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(small and 82 or 224, small and 8 or 10),
        Size = UDim2.new(1, -(small and 90 or 234), 1, -(small and 16 or 20)),
        ZIndex = 20,
    }, shell)

    local topbar = create("Frame", {
        Name = "Topbar",
        BackgroundColor3 = T().Topbar,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 74),
        ZIndex = 25,
    }, content)
    addCorner(topbar, 18)
    addStroke(topbar, T().BorderSoft, 0.08, 1)

    local logo = create("ImageLabel", {
        Name = "Logo",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(16, 18),
        Size = UDim2.fromOffset(38, 38),
        Image = "",
        Visible = false,
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = 27,
    }, topbar)
    addCorner(logo, 10)

    local pageTitle = create("TextLabel", {
        Name = "PageTitle",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(16, 9),
        Size = UDim2.new(1, -122, 0, 29),
        Text = "Khfresh Hub",
        TextColor3 = T().Text,
        TextSize = 16,
        Font = Enum.Font.GothamSemibold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 27,
    }, topbar)
    local pageSubtitle = create("TextLabel", {
        Name = "PageSubtitle",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(16, 36),
        Size = UDim2.new(1, -122, 0, 22),
        Text = "Khfresh Hub",
        TextColor3 = T().Muted,
        TextSize = 10,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 27,
    }, topbar)

    local minButton = create("TextButton", {
        BackgroundColor3 = T().Card,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Position = UDim2.new(1, -98, 0.5, -23),
        Size = UDim2.fromOffset(46, 46),
        ZIndex = 28,
        Active = true,
    }, topbar)
    addCorner(minButton, 14)
    local minIcon = iconObject(minButton, "minus", 18, T().Secondary, 29)
    minIcon.Position = UDim2.fromOffset(14, 14)
    local closeButton = create("TextButton", {
        BackgroundColor3 = T().Card,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Position = UDim2.new(1, -48, 0.5, -23),
        Size = UDim2.fromOffset(46, 46),
        ZIndex = 28,
        Active = true,
    }, topbar)
    addCorner(closeButton, 14)
    local closeIcon = iconObject(closeButton, "x", 18, T().Secondary, 29)
    closeIcon.Position = UDim2.fromOffset(14, 14)

    local body = create("Frame", {
        Name = "Body",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 84),
        Size = UDim2.new(1, 0, 1, -84),
        ZIndex = 24,
    }, content)
    local pageHost = create("Frame", {
        Name = "PageHost",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 24,
    }, body)

    local floating = create("ScreenGui", {
        Name = "KhfreshFloating",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 2147483647,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Enabled = true,
    }, parent)
    protectGui(floating)
    local floatingButton = create("TextButton", {
        Name = "Toggle",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Size = UDim2.fromOffset(58, 58),
        Position = UDim2.new(1, -70, 1, -70),
        ZIndex = 1,
        Active = true,
    }, floating)

    local selfWindow = setmetatable({
        _gui = gui,
        _shell = shell,
        _rail = rail,
        _topbar = topbar,
        _top = topbar,
        _content = content,
        _body = body,
        _pageHost = pageHost,
        _navScroll = navScroll,
        _brandText = brandText,
        _brandAuthor = brandAuthor,
        _logo = logo,
        _background = background,
        _backgroundShade = shade,
        _pageTitle = pageTitle,
        _pageSubtitle = pageSubtitle,
        _tabs = {},
        _active = nil,
        _visible = true,
        _minimized = false,
        _floating = floating,
        _floatingButton = floatingButton,
        _minButtonText = minIcon,
        _raw = nil,
    }, Window)
    selfWindow._raw = selfWindow

    -- Fix closure created before selfWindow existed.
    minButton.Activated:Connect(function() selfWindow:Minimize() end)
    closeButton.Activated:Connect(function() selfWindow:Close() end)
    minButton.MouseEnter:Connect(function() tween(minButton, 0.1, {BackgroundColor3 = T().Hover}) end)
    minButton.MouseLeave:Connect(function() tween(minButton, 0.1, {BackgroundColor3 = T().Card}) end)
    closeButton.MouseEnter:Connect(function() tween(closeButton, 0.1, {BackgroundColor3 = T().Hover}) end)
    closeButton.MouseLeave:Connect(function() tween(closeButton, 0.1, {BackgroundColor3 = T().Card}) end)

    -- Window drag: title bar + logo/title area, desktop and touch.
    do
        local dragging = false
        local dragStart
        local startPos
        topbar.InputBegan:Connect(function(input)
            if pointerActivated(input) then
                dragging = true
                dragStart = input.Position
                startPos = shell.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
            end
        end)
        topbar.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local d = input.Position - dragStart
                shell.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end)
    end

    -- Remove accidental full-screen black layers: GUI itself stays transparent.
    gui.DisplayOrder = 2147483645

    table.insert(self._windows, selfWindow)
    if config.Logo then selfWindow:SetLogo(config.Logo) end
    if config.Background then selfWindow:SetBackground(config.Background, config.BackgroundImageTransparency, config.BackgroundShadeTransparency) end
    if config.Theme then selfWindow._themeName = tostring(config.Theme) end
    selfWindow:_applyResponsive()
    selfWindow:CreateFloatingToggle({Icon = "volleyball"})
    return selfWindow
end

-- Correct forward declaration used by Minimize button setup above.

function KhfreshLib:DestroyAll()
    for _, win in ipairs(self._windows) do pcall(function() win:Destroy() end) end
    table.clear(self._windows)
end

return KhfreshLib
