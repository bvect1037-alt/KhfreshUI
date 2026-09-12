--[[
    KhfreshUI_NEW
    A self-contained, Japanese-inspired Bento Grid UI library for Khfresh Hub.
    The library intentionally uses only Roblox primitives and procedural shapes.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Theme = {
    Background = Color3.fromRGB(8, 12, 22),
    Surface = Color3.fromRGB(15, 21, 35),
    SurfaceRaised = Color3.fromRGB(21, 29, 47),
    SurfaceHover = Color3.fromRGB(29, 39, 63),
    Border = Color3.fromRGB(54, 70, 105),
    Accent = Color3.fromRGB(96, 116, 232),
    AccentBright = Color3.fromRGB(137, 153, 255),
    AccentMuted = Color3.fromRGB(59, 72, 145),
    Text = Color3.fromRGB(241, 244, 255),
    TextMuted = Color3.fromRGB(151, 163, 191),
    TextDim = Color3.fromRGB(100, 113, 143),
    Success = Color3.fromRGB(80, 205, 143),
    Warning = Color3.fromRGB(241, 184, 92),
    Danger = Color3.fromRGB(238, 102, 119),
    Shadow = Color3.fromRGB(1, 3, 9),
}

local UI = {}
local Windows = {}
local activeWindow
local notificationIndex = 0
local tweenInfo = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local fastTweenInfo = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function copyTable(source)
    local result = {}
    for key, value in pairs(source or {}) do
        result[key] = value
    end
    return result
end

local function mergeTheme(values)
    for key, value in pairs(values or {}) do
        if Theme[key] ~= nil then
            Theme[key] = value
        end
    end
end

local function tween(object, properties, info)
    if not object or not object.Parent then
        return
    end
    local animation = TweenService:Create(object, info or tweenInfo, properties)
    animation:Play()
    return animation
end

local function make(className, properties, parent)
    local object = Instance.new(className)
    for key, value in pairs(properties or {}) do
        pcall(function()
            object[key] = value
        end)
    end
    object.Parent = parent
    return object
end

local function corner(parent, radius)
    return make("UICorner", {CornerRadius = UDim.new(0, radius or 10)}, parent)
end

local function stroke(parent, color, transparency, thickness)
    return make("UIStroke", {
        Color = color or Theme.Border,
        Transparency = transparency or 0,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

local function padding(parent, left, top, right, bottom)
    return make("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingRight = UDim.new(0, right or left or 0),
        PaddingBottom = UDim.new(0, bottom or top or 0),
    }, parent)
end

local function label(parent, text, size, color, font)
    return make("TextLabel", {
        BackgroundTransparency = 1,
        Text = tostring(text or ""),
        TextColor3 = color or Theme.Text,
        TextSize = size or 14,
        Font = font or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Active = false,
        ZIndex = 5,
    }, parent)
end

local function button(parent, name, zIndex)
    return make("TextButton", {
        Name = name or "Hitbox",
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        Active = true,
        Selectable = true,
        ZIndex = zIndex or 12,
    }, parent)
end

local function shadow(parent, radius)
    local frame = make("Frame", {
        Name = "Shadow",
        BackgroundColor3 = Theme.Shadow,
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 6),
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = math.max(0, (parent.ZIndex or 1) - 1),
    }, parent)
    corner(frame, radius or 14)
    return frame
end

local function symbol(parent, kind, color)
    -- Small vector symbols assembled from Frames/Corners/rotated bars.
    local holder = make("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(22, 22),
    }, parent)
    local tint = color or Theme.TextMuted
    if kind == "plus" or kind == "minus" then
        make("Frame", {
            BackgroundColor3 = tint, BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(12, 2),
        }, holder)
        if kind == "plus" then
            make("Frame", {
                BackgroundColor3 = tint, BorderSizePixel = 0,
                AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(2, 12),
            }, holder)
        end
    elseif kind == "chevron" then
        for i = 1, 2 do
            make("Frame", {
                BackgroundColor3 = tint, BorderSizePixel = 0,
                AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(8 + i * 4, 8 + (i == 1 and -2 or 2)),
                Size = UDim2.fromOffset(8, 2), Rotation = i == 1 and 45 or -45,
            }, holder)
        end
    elseif kind == "dot" then
        local dot = make("Frame", {
            BackgroundColor3 = tint, BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(7, 7),
        }, holder)
        corner(dot, 7)
    elseif kind == "grid" then
        for y = 0, 1 do
            for x = 0, 1 do
                local dot = make("Frame", {
                    BackgroundColor3 = tint, BorderSizePixel = 0,
                    Position = UDim2.fromOffset(4 + x * 8, 4 + y * 8),
                    Size = UDim2.fromOffset(5, 5),
                }, holder)
                corner(dot, 3)
            end
        end
    elseif kind == "sliders" then
        for i, offset in ipairs({5, 11, 17}) do
            make("Frame", {
                BackgroundColor3 = tint, BorderSizePixel = 0,
                Position = UDim2.fromOffset(offset, 3), Size = UDim2.fromOffset(2, 16),
                Rotation = i == 2 and 180 or 0,
            }, holder)
            local knob = make("Frame", {
                BackgroundColor3 = tint, BorderSizePixel = 0,
                Position = UDim2.fromOffset(offset - 3, i == 2 and 6 or 11),
                Size = UDim2.fromOffset(8, 4),
            }, holder)
            corner(knob, 3)
        end
    elseif kind == "bell" then
        local bell = make("Frame", {
            BackgroundColor3 = tint, BorderSizePixel = 0,
            Position = UDim2.fromOffset(5, 4), Size = UDim2.fromOffset(12, 12),
        }, holder)
        corner(bell, 7)
        make("Frame", {
            BackgroundColor3 = tint, BorderSizePixel = 0,
            Position = UDim2.fromOffset(3, 15), Size = UDim2.fromOffset(16, 2),
        }, holder)
        local clapper = make("Frame", {
            BackgroundColor3 = tint, BorderSizePixel = 0,
            Position = UDim2.fromOffset(10, 18), Size = UDim2.fromOffset(3, 2),
        }, holder)
        corner(clapper, 2)
    elseif kind == "close" then
        for i, rotation in ipairs({45, -45}) do
            make("Frame", {
                BackgroundColor3 = tint, BorderSizePixel = 0,
                AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(15, 2), Rotation = rotation,
            }, holder)
        end
    elseif kind == "chevronUp" then
        for i, rotation in ipairs({45, -45}) do
            make("Frame", {
                BackgroundColor3 = tint, BorderSizePixel = 0,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromOffset(7 + i * 4, 12 - (i == 1 and 2 or -2)),
                Size = UDim2.fromOffset(8, 2), Rotation = rotation,
            }, holder)
        end
    else
        return symbol(parent, "dot", tint)
    end
    return holder
end

local function makeLogo(parent, compact)
    local logo = make("Frame", {
        Name = "KHFRESHLogo",
        BackgroundTransparency = 1,
        Size = compact and UDim2.fromOffset(36, 36) or UDim2.new(1, -28, 0, 62),
    }, parent)
    local mark = make("Frame", {
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Size = compact and UDim2.fromOffset(30, 30) or UDim2.fromOffset(38, 38),
        Position = compact and UDim2.fromOffset(3, 3) or UDim2.fromOffset(0, 9),
        ZIndex = 8,
    }, logo)
    corner(mark, 10)
    stroke(mark, Theme.AccentBright, 0.35, 1)
    for _, data in ipairs({
        {UDim2.fromOffset(8, 8), 0}, {UDim2.fromOffset(8, 17), 90},
        {UDim2.fromOffset(17, 8), 90}, {UDim2.fromOffset(17, 17), 0},
    }) do
        make("Frame", {
            BackgroundColor3 = Color3.fromRGB(226, 231, 255),
            BorderSizePixel = 0, Position = data[1], Size = UDim2.fromOffset(5, 5),
            Rotation = data[2], ZIndex = 9,
        }, mark)
    end
    if not compact then
        local name = label(logo, "KHFRESH", 18, Theme.Text, Enum.Font.GothamBold)
        name.Position = UDim2.fromOffset(50, 8)
        name.Size = UDim2.new(1, -50, 0, 24)
        local sub = label(logo, "NIGHT CONSOLE", 9, Theme.TextMuted, Enum.Font.GothamMedium)
        sub.Position = UDim2.fromOffset(51, 32)
        sub.Size = UDim2.new(1, -51, 0, 15)
    end
    return logo
end

local function getGuiParent()
    local parent
    pcall(function()
        parent = (gethui and gethui()) or (get_hidden_gui and get_hidden_gui())
    end)
    if not parent then
        parent = game:GetService("CoreGui")
    end
    return parent
end

local function setVisible(object, visible)
    if object then
        object.Visible = visible
    end
end

local function safeCallback(callback, ...)
    if type(callback) ~= "function" then
        return
    end
    task.spawn(function(...)
        pcall(callback, ...)
    end, ...)
end

local function normalizeConfig(config, fallbackTitle)
    if type(config) == "string" then
        return {Title = config}
    end
    config = config or {}
    local result = copyTable(config)
    result.Title = result.Title or result.Name or fallbackTitle or "Khfresh Hub"
    return result
end

local Window = {}
Window.__index = Window
local Tab = {}
Tab.__index = Tab
local Section = {}
Section.__index = Section

function UI:SetTheme(values)
    if type(values) == "string" then
        values = nil
    end
    mergeTheme(values)
    for _, window in ipairs(Windows) do
        if window and window._refreshTheme then
            window:_refreshTheme()
        end
    end
    return UI
end

function UI:Notify(config, duration)
    if type(config) == "string" then
        config = {Title = "Khfresh", Content = config}
    end
    config = config or {}
    local parent = getGuiParent()
    local gui = parent:FindFirstChild("KhfreshNotifications")
    if not gui then
        gui = make("ScreenGui", {
            Name = "KhfreshNotifications", ResetOnSpawn = false,
            IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Global,
            DisplayOrder = 2147483000,
        }, parent)
    end
    notificationIndex = notificationIndex + 1
    local card = make("Frame", {
        Name = "Notice" .. notificationIndex,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 28, 0, 24 + (#gui:GetChildren() - 1) * 76),
        Size = UDim2.fromOffset(294, 64),
        BackgroundColor3 = Theme.SurfaceRaised, BorderSizePixel = 0,
        ZIndex = 100,
    }, gui)
    corner(card, 12)
    stroke(card, Theme.Border, 0.2, 1)
    local accent = make("Frame", {
        BackgroundColor3 = config.Color or Theme.Accent, BorderSizePixel = 0,
        Size = UDim2.fromOffset(3, 40), Position = UDim2.fromOffset(12, 12), ZIndex = 101,
    }, card)
    corner(accent, 2)
    local title = label(card, config.Title or "Khfresh", 13, Theme.Text, Enum.Font.GothamBold)
    title.Position, title.Size = UDim2.fromOffset(26, 10), UDim2.new(1, -38, 0, 20)
    local content = label(card, config.Content or config.Message or config.Text or "", 11, Theme.TextMuted, Enum.Font.Gotham)
    content.Position, content.Size = UDim2.fromOffset(26, 32), UDim2.new(1, -38, 0, 20)
    tween(card, {Position = UDim2.new(1, -16, 0, 24 + (#gui:GetChildren() - 2) * 76)}, fastTweenInfo)
    task.delay(tonumber(duration or config.Duration) or 3.5, function()
        if card.Parent then
            tween(card, {Position = UDim2.new(1, 28, 0, card.Position.Y.Offset)}, fastTweenInfo)
            task.wait(0.18)
            card:Destroy()
        end
    end)
    return card
end

function UI:CreateWindow(config)
    return Window.new(normalizeConfig(config))
end

function Window.new(config)
    local self = setmetatable({}, Window)
    self.Config = config
    self.Tabs = {}
    self.TabOrder = {}
    self.SelectedTab = nil
    self.Minimized = false
    self.Destroyed = false
    self._connections = {}
    self._shownSize = config.Size or UDim2.fromOffset(900, 570)
    self._shownPosition = config.Position or UDim2.new(0.5, -450, 0.5, -285)
    self._size = self._shownSize

    local parent = getGuiParent()
    local old = parent:FindFirstChild(config.Identifier or "KhfreshUI")
    if old then
        pcall(function() old:Destroy() end)
    end
    self.Gui = make("ScreenGui", {
        Name = config.Identifier or "KhfreshUI",
        ResetOnSpawn = false, IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Global, DisplayOrder = config.DisplayOrder or 100,
    }, parent)
    pcall(function()
        if syn and syn.protect_gui then syn.protect_gui(self.Gui) end
    end)

    self.Root = make("Frame", {
        Name = "Window", AnchorPoint = Vector2.new(0.5, 0.5),
        Position = self._shownPosition, Size = self._shownSize,
        BackgroundColor3 = Theme.Background, BorderSizePixel = 0,
        Active = true, ZIndex = 2,
    }, self.Gui)
    corner(self.Root, 18)
    stroke(self.Root, Theme.Border, 0.12, 1)
    shadow(self.Root, 18)
    self._scale = make("UIScale", {Scale = 1}, self.Root)
    self:_build()
    table.insert(Windows, self)
    if config.AutoShow ~= false then
        self:Open()
    end
    return self
end

function Window:_build()
    local root = self.Root
    local header = make("Frame", {
        Name = "Header", BackgroundColor3 = Theme.Surface, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 74), Active = true, ZIndex = 4,
    }, root)
    corner(header, 18)
    self.Header = header
    local headerMask = make("Frame", {
        BackgroundColor3 = Theme.Surface, BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 18), Size = UDim2.new(1, 0, 1, -18), ZIndex = 4,
    }, header)
    self.HeaderMask = headerMask
    makeLogo(header, false)
    local title = label(header, self.Config.Title, 15, Theme.Text, Enum.Font.GothamBold)
    title.Position, title.Size = UDim2.new(0, 230, 0, 24), UDim2.fromOffset(230, 24)
    title.Position = UDim2.fromOffset(202, 16)
    local subtitle = label(header, self.Config.Subtitle or "静かな夜のコントロールパネル", 10, Theme.TextMuted, Enum.Font.Gotham)
    subtitle.Position, subtitle.Size = UDim2.fromOffset(202, 40), UDim2.fromOffset(260, 18)
    local closeButton = button(header, "Close", 15)
    closeButton.AnchorPoint, closeButton.Position, closeButton.Size = Vector2.new(1, 0), UDim2.new(1, -14, 0, 14), UDim2.fromOffset(36, 36)
    symbol(closeButton, "close", Theme.TextMuted)
    closeButton.MouseEnter:Connect(function() tween(closeButton, {BackgroundTransparency = 0.8}, fastTweenInfo) end)
    closeButton.MouseButton1Click:Connect(function() self:Destroy() end)
    local minButton = button(header, "Minimize", 15)
    minButton.AnchorPoint, minButton.Position, minButton.Size = Vector2.new(1, 0), UDim2.new(1, -54, 0, 14), UDim2.fromOffset(30, 36)
    symbol(minButton, "minus", Theme.TextMuted)
    minButton.MouseButton1Click:Connect(function() self:Minimize() end)
    self._dragTarget = header
    self:_makeDraggable(header)

    local sidebar = make("Frame", {
        Name = "Sidebar", BackgroundColor3 = Theme.Surface, BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 74), Size = UDim2.new(0, 184, 1, -74),
        Active = true, ZIndex = 3,
    }, root)
    self.Sidebar = sidebar
    local sideMask = make("Frame", {
        BackgroundColor3 = Theme.Surface, BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, -18), Size = UDim2.new(1, 0, 1, 18), ZIndex = 3,
    }, sidebar)
    self.SideMask = sideMask
    local nav = make("ScrollingFrame", {
        Name = "Navigation", BackgroundTransparency = 1, BorderSizePixel = 0,
        Position = UDim2.fromOffset(12, 86), Size = UDim2.new(1, -24, 1, -138),
        ScrollBarThickness = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Active = true, ZIndex = 6,
    }, sidebar)
    padding(nav, 0, 0, 0, 8)
    make("UIListLayout", {Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder}, nav)
    self.Navigation = nav
    local footer = label(sidebar, "KH / 01     ONLINE", 9, Theme.TextDim, Enum.Font.GothamMedium)
    footer.Position, footer.Size = UDim2.fromOffset(16, -34), UDim2.new(1, -28, 0, 18)
    footer.AnchorPoint = Vector2.new(0, 1)

    local content = make("Frame", {
        Name = "Content", BackgroundColor3 = Theme.Background, BorderSizePixel = 0,
        Position = UDim2.fromOffset(184, 74), Size = UDim2.new(1, -184, 1, -74),
        Active = true, ZIndex = 3,
    }, root)
    self.Content = content
    corner(content, 16)
    if type(self.Config.Background) == "string" and self.Config.Background ~= "" then
        self.BackgroundImage = make("ImageLabel", {
            Name = "BackgroundImage", BackgroundTransparency = 1, BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1), Image = self.Config.Background,
            ImageTransparency = tonumber(self.Config.BackgroundImageTransparency) or 0.72,
            ScaleType = Enum.ScaleType.Crop, ZIndex = 3,
        }, content)
        corner(self.BackgroundImage, 16)
        make("Frame", {
            Name = "BackgroundVeil", BackgroundColor3 = Theme.Background,
            BackgroundTransparency = 0.26, BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1), ZIndex = 4,
        }, content)
    end
    local contentMask = make("Frame", {
        BackgroundColor3 = Theme.Background, BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, -16), Size = UDim2.new(1, 0, 1, 16), ZIndex = 3,
    }, content)
    self.ContentMask = contentMask
    local pageHolder = make("Frame", {
        Name = "Pages", BackgroundTransparency = 1, BorderSizePixel = 0,
        Position = UDim2.fromOffset(22, 20), Size = UDim2.new(1, -44, 1, -42),
        ClipsDescendants = true, ZIndex = 5,
    }, content)
    self.Pages = pageHolder

    local bottom = make("Frame", {
        Name = "BottomHandle", BackgroundColor3 = Theme.SurfaceRaised, BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -8),
        Size = UDim2.fromOffset(64, 5), Active = true, ZIndex = 18,
    }, root)
    corner(bottom, 4)
    self.BottomHandle = bottom
    self:_makeDraggable(bottom, true)
    local resize = button(root, "ResizeHandle", 20)
    resize.AnchorPoint, resize.Position, resize.Size = Vector2.new(1, 1), UDim2.new(1, -5, 1, -5), UDim2.fromOffset(28, 28)
    symbol(resize, "grid", Theme.TextDim)
    self:_makeResize(resize)
end

function Window:_makeDraggable(handle, verticalOnly)
    local dragging, startInput, startPosition
    local function update(input)
        local delta = input.Position - startInput
        local x = startPosition.X.Offset + (verticalOnly and 0 or delta.X)
        local y = startPosition.Y.Offset + delta.Y
        if startPosition.X.Scale ~= 0 then
            x = startPosition.X.Offset + delta.X
        end
        self.Root.Position = UDim2.new(startPosition.X.Scale, x, startPosition.Y.Scale, y)
    end
    table.insert(self._connections, handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, startInput, startPosition = true, input, self.Root.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end))
    table.insert(self._connections, handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            startInput = input
        end
    end))
    table.insert(self._connections, UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end))
end

function Window:_makeResize(handle)
    local resizing, startInput, startSize
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing, startInput, startSize = true, input, self.Root.AbsoluteSize
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then resizing = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - startInput.Position
            local width = math.clamp(startSize.X + delta.X, 650, 1320)
            local height = math.clamp(startSize.Y + delta.Y, 420, 820)
            self._size = UDim2.fromOffset(width, height)
            self.Root.Size = self._size
        end
    end)
end

function Window:_refreshTheme()
    if self.Destroyed then return end
    self.Root.BackgroundColor3 = Theme.Background
    self.Header.BackgroundColor3 = Theme.Surface
    self.HeaderMask.BackgroundColor3 = Theme.Surface
    self.Sidebar.BackgroundColor3 = Theme.Surface
    self.SideMask.BackgroundColor3 = Theme.Surface
    self.Content.BackgroundColor3 = Theme.Background
    self.ContentMask.BackgroundColor3 = Theme.Background
    for _, object in ipairs(self.Root:GetDescendants()) do
        if object:IsA("UIStroke") and object.Parent ~= self.Root then
            object.Color = Theme.Border
        end
    end
end

function Window:CreateTab(config)
    config = normalizeConfig(config, "Tab")
    local tab = setmetatable({
        Window = self, Config = config, Sections = {}, Controls = {},
        Name = config.Name or config.Title, Selected = false,
    }, Tab)
    self.Tabs[tab.Name] = tab
    table.insert(self.TabOrder, tab)
    tab:_build()
    if not self.SelectedTab then
        self:SelectTab(tab.Name)
    end
    return tab
end

function Window:GetTab(name)
    return self.Tabs[name]
end

function Window:SelectTab(name)
    local tab = type(name) == "table" and name or self.Tabs[name]
    if not tab then return self end
    for _, item in ipairs(self.TabOrder) do
        item:_setSelected(item == tab)
    end
    self.SelectedTab = tab
    return self
end

function Window:Open()
    self.Minimized = false
    self.Root.Visible = true
    tween(self.Root, {Size = self._size or self._shownSize}, tweenInfo)
    activeWindow = self
    return self
end

function Window:Minimize()
    self.Minimized = not self.Minimized
    if self.Minimized then
        tween(self.Root, {Size = UDim2.fromOffset(self.Root.AbsoluteSize.X, 74)}, tweenInfo)
    else
        tween(self.Root, {Size = self._size or self._shownSize}, tweenInfo)
    end
    return self
end

function Window:Toggle()
    if self.Root.Visible and not self.Minimized then
        self.Root.Visible = false
    else
        self:Open()
    end
    return self
end

function Window:CreateFloatingToggle(config)
    config = config or {}
    local parent = self.Gui
    local floating = make("TextButton", {
        Name = "FloatingToggle", Text = "", AutoButtonColor = false,
        AnchorPoint = Vector2.new(1, 1), Position = config.Position or UDim2.new(1, -24, 1, -24),
        Size = config.Size or UDim2.fromOffset(58, 58), BackgroundColor3 = Theme.SurfaceRaised,
        BorderSizePixel = 0, Active = true, ZIndex = 40,
    }, parent)
    corner(floating, 18)
    stroke(floating, Theme.Accent, 0.12, 1)
    makeLogo(floating, true)
    floating.MouseEnter:Connect(function()
        tween(floating, {BackgroundColor3 = Theme.SurfaceHover, Size = UDim2.fromOffset(62, 62)}, fastTweenInfo)
    end)
    floating.MouseLeave:Connect(function()
        tween(floating, {BackgroundColor3 = Theme.SurfaceRaised, Size = config.Size or UDim2.fromOffset(58, 58)}, fastTweenInfo)
    end)
    floating.MouseButton1Click:Connect(function() self:Toggle() end)
    self.FloatingToggle = floating
    return floating
end

function Window:SetBackground(color)
    if typeof(color) == "Color3" then
        self.Content.BackgroundColor3 = color
        self.ContentMask.BackgroundColor3 = color
    elseif type(color) == "string" then
        self.Config.Background = color
        if not self.BackgroundImage then
            self.BackgroundImage = make("ImageLabel", {
                Name = "BackgroundImage", BackgroundTransparency = 1, BorderSizePixel = 0,
                Size = UDim2.fromScale(1, 1), Image = color,
                ImageTransparency = 0.72, ScaleType = Enum.ScaleType.Crop, ZIndex = 3,
            }, self.Content)
            corner(self.BackgroundImage, 16)
        else
            self.BackgroundImage.Image = color
        end
    end
    return self
end

function Window:SetLogo(value)
    if typeof(value) == "Instance" and value:IsA("GuiObject") then
        local old = self.Header:FindFirstChild("KHFRESHLogo")
        if old then old:Destroy() end
        value.Name = "KHFRESHLogo"
        value.Parent = self.Header
    end
    return self
end

function Window:Destroy()
    if self.Destroyed then return end
    self.Destroyed = true
    for _, connection in ipairs(self._connections) do
        pcall(function() connection:Disconnect() end)
    end
    if self.Gui then self.Gui:Destroy() end
    for index, item in ipairs(Windows) do
        if item == self then table.remove(Windows, index) break end
    end
end

function Tab:_build()
    local window = self.Window
    local title = self.Config.Title or self.Name
    local navButton = make("TextButton", {
        Name = self.Name, Text = "", AutoButtonColor = false, Active = true,
        BackgroundColor3 = Theme.Surface, BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 38), BorderSizePixel = 0, LayoutOrder = #window.TabOrder,
        ZIndex = 8,
    }, window.Navigation)
    corner(navButton, 9)
    local icon = symbol(navButton, self.Config.Icon or "grid", Theme.TextMuted)
    icon.Position = UDim2.fromOffset(10, 8)
    local text = label(navButton, title, 12, Theme.TextMuted, Enum.Font.GothamMedium)
    text.Position, text.Size = UDim2.fromOffset(42, 0), UDim2.new(1, -50, 1, 0)
    local indicator = make("Frame", {
        BackgroundColor3 = Theme.AccentBright, BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 10), Size = UDim2.fromOffset(3, 18), Visible = false, ZIndex = 9,
    }, navButton)
    corner(indicator, 2)
    self.NavButton, self.NavText, self.NavIcon, self.Indicator = navButton, text, icon, indicator
    navButton.MouseEnter:Connect(function()
        if not self.Selected then tween(navButton, {BackgroundTransparency = 0.8}, fastTweenInfo) end
    end)
    navButton.MouseLeave:Connect(function()
        if not self.Selected then tween(navButton, {BackgroundTransparency = 1}, fastTweenInfo) end
    end)
    navButton.MouseButton1Click:Connect(function() window:SelectTab(self) end)
    self.Page = make("ScrollingFrame", {
        Name = self.Name .. "Page", BackgroundTransparency = 1, BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1), ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.AccentMuted,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false, Active = true, ZIndex = 6,
    }, window.Pages)
    padding(self.Page, 1, 2, 10, 10)
    self.Layout = make("UIListLayout", {Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder}, self.Page)
end

function Tab:_setSelected(selected)
    self.Selected = selected
    setVisible(self.Page, selected)
    setVisible(self.Indicator, selected)
    if selected then
        tween(self.NavButton, {BackgroundColor3 = Theme.AccentMuted, BackgroundTransparency = 0.65}, fastTweenInfo)
        self.NavText.TextColor3 = Theme.Text
        self.NavIcon:FindFirstChildWhichIsA("Frame").BackgroundColor3 = Theme.AccentBright
    else
        tween(self.NavButton, {BackgroundTransparency = 1}, fastTweenInfo)
        self.NavText.TextColor3 = Theme.TextMuted
    end
end

function Tab:CreateHeader(text, subtitle)
    if type(text) == "table" then
        subtitle = text.Subtitle or text.Desc or text.Description
        text = text.Title or text.Name or self.Config.Title or self.Name
    end
    local holder = make("Frame", {
        Name = "PageHeader", BackgroundTransparency = 1, Size = UDim2.new(1, -10, 0, 54),
        LayoutOrder = 1, ZIndex = 7,
    }, self.Page)
    local heading = label(holder, text or self.Config.Title or self.Name, 22, Theme.Text, Enum.Font.GothamBold)
    heading.Size = UDim2.new(1, 0, 0, 29)
    local sub = label(holder, subtitle or self.Config.Subtitle or "Select a module to begin.", 11, Theme.TextMuted, Enum.Font.Gotham)
    sub.Position, sub.Size = UDim2.fromOffset(0, 31), UDim2.new(1, 0, 0, 19)
    return holder
end

function Tab:CreateSection(config)
    config = normalizeConfig(config, "Section")
    return Section.new(self, config)
end

function Section.new(tab, config)
    local self = setmetatable({
        Tab = tab, Window = tab.Window, Config = config, Controls = {},
    }, Section)
    self:_build()
    table.insert(tab.Sections, self)
    return self
end

function Section:_build()
    local config = self.Config
    self.Card = make("Frame", {
        Name = config.Name or config.Title, BackgroundColor3 = Theme.Surface, BorderSizePixel = 0,
        Size = UDim2.new(1, -10, 0, config.Height or 86), AutomaticSize = config.Height and Enum.AutomaticSize.None or Enum.AutomaticSize.Y,
        LayoutOrder = #self.Tab.Sections + 2, ZIndex = 7,
    }, self.Tab.Page)
    corner(self.Card, 13)
    stroke(self.Card, Theme.Border, 0.35, 1)
    padding(self.Card, 15, 13, 15, 13)
    local heading = label(self.Card, config.Title or config.Name or "Section", 13, Theme.Text, Enum.Font.GothamBold)
    heading.Size = UDim2.new(1, 0, 0, 22)
    local desc = label(self.Card, config.Subtitle or config.Description or "", 10, Theme.TextMuted, Enum.Font.Gotham)
    desc.Position, desc.Size = UDim2.fromOffset(0, 24), UDim2.new(1, 0, 0, 17)
    if not (config.Subtitle or config.Description) then desc.Visible = false end
    self.Body = make("Frame", {
        Name = "Body", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 30),
        Size = UDim2.new(1, 0, 0, 36), AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 8,
    }, self.Card)
    self.Layout = make("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, self.Body)
end

local function resolveCallback(config)
    return config.Callback or config.Function or config.OnChanged or config.Changed
end

function Section:_row(config, height)
    local row = make("Frame", {
        Name = config.Name or config.Title or "Control", BackgroundColor3 = Theme.SurfaceRaised,
        BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, height or 42),
        LayoutOrder = #self.Controls + 1, ZIndex = 9,
    }, self.Body)
    corner(row, 9)
    stroke(row, Theme.Border, 0.55, 1)
    return row
end

function Section:CreateButton(config, maybeCallback)
    if type(config) == "string" then config = {Title = config, Callback = maybeCallback} end
    config = config or {}
    local row = self:_row(config, 42)
    local title = label(row, config.Title or config.Name or "Button", 12, Theme.Text, Enum.Font.GothamMedium)
    title.Position, title.Size = UDim2.fromOffset(13, 0), UDim2.new(1, -50, 1, 0)
    local arrow = symbol(row, "chevron", Theme.TextDim)
    arrow.AnchorPoint, arrow.Position = Vector2.new(1, 0.5), UDim2.new(1, -12, 0.5, -11)
    local hit = button(row, "ButtonHitbox", 12)
    hit.Size = UDim2.fromScale(1, 1)
    hit.MouseEnter:Connect(function() tween(row, {BackgroundColor3 = Theme.SurfaceHover}, fastTweenInfo) end)
    hit.MouseLeave:Connect(function() tween(row, {BackgroundColor3 = Theme.SurfaceRaised}, fastTweenInfo) end)
    hit.MouseButton1Click:Connect(function() safeCallback(resolveCallback(config)) end)
    table.insert(self.Controls, row)
    return row
end

function Section:CreateToggle(config, maybeCallback)
    if type(config) == "string" then config = {Title = config, Callback = maybeCallback} end
    config = config or {}
    local value = config.Default
    if value == nil then value = config.Value end
    value = value == true
    local row = self:_row(config, 42)
    local title = label(row, config.Title or config.Name or "Toggle", 12, Theme.Text, Enum.Font.GothamMedium)
    title.Position, title.Size = UDim2.fromOffset(13, 0), UDim2.new(1, -80, 1, 0)
    local switch = make("Frame", {
        BackgroundColor3 = value and Theme.AccentMuted or Theme.Background,
        BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -13, 0.5, 0), Size = UDim2.fromOffset(38, 20), ZIndex = 11,
    }, row)
    corner(switch, 10)
    stroke(switch, Theme.Border, 0.3, 1)
    local knob = make("Frame", {
        BackgroundColor3 = value and Theme.AccentBright or Theme.TextDim,
        BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 0.5),
        Position = value and UDim2.new(1, -18, 0.5, 0) or UDim2.fromOffset(3, 10),
        Size = UDim2.fromOffset(14, 14), ZIndex = 12,
    }, switch)
    corner(knob, 7)
    local hit = button(row, "ToggleHitbox", 13)
    hit.Size = UDim2.fromScale(1, 1)
    local function update(fire)
        switch.BackgroundColor3 = value and Theme.AccentMuted or Theme.Background
        tween(knob, {Position = value and UDim2.new(1, -18, 0.5, 0) or UDim2.fromOffset(3, 10), BackgroundColor3 = value and Theme.AccentBright or Theme.TextDim}, fastTweenInfo)
        if fire then safeCallback(resolveCallback(config), value) end
    end
    hit.MouseButton1Click:Connect(function() value = not value; update(true) end)
    local control = {Set = function(_, newValue, fire) value = newValue == true; update(fire ~= false) end, Get = function() return value end, Row = row}
    table.insert(self.Controls, control)
    return control
end

function Section:CreateDropdown(config)
    config = config or {}
    local values = config.Options or config.Values or {}
    local selected = config.Default
    if selected == nil and #values > 0 then selected = values[1] end
    local row = self:_row(config, 46)
    local title = label(row, config.Title or config.Name or "Dropdown", 11, Theme.TextMuted, Enum.Font.GothamMedium)
    title.Position, title.Size = UDim2.fromOffset(13, 3), UDim2.new(0.42, 0, 0, 18)
    local current = label(row, selected == nil and "Select..." or tostring(selected), 12, Theme.Text, Enum.Font.GothamMedium)
    current.AnchorPoint, current.Position, current.Size = Vector2.new(1, 0), UDim2.new(1, -38, 0, 20), UDim2.new(0.53, 0, 0, 20)
    current.TextXAlignment = Enum.TextXAlignment.Right
    local chevron = symbol(row, "chevron", Theme.TextMuted)
    chevron.AnchorPoint, chevron.Position = Vector2.new(1, 0.5), UDim2.new(1, -10, 0.5, -11)
    local list = make("Frame", {
        Name = "Options", BackgroundColor3 = Theme.SurfaceRaised, BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, 5), Size = UDim2.new(1, 0, 0, 0),
        ClipsDescendants = true, Visible = false, ZIndex = 30,
    }, row)
    corner(list, 9); stroke(list, Theme.Border, 0.1, 1)
    local layout = make("UIListLayout", {Padding = UDim.new(0, 2)}, list)
    local hit = button(row, "DropdownHitbox", 14); hit.Size = UDim2.fromScale(1, 1)
    local open = false
    local function setValue(newValue, fire)
        selected = newValue; current.Text = tostring(newValue or "Select...")
        if fire then safeCallback(resolveCallback(config), newValue) end
    end
    for _, option in ipairs(values) do
        local optionButton = make("TextButton", {
            BackgroundTransparency = 1, Text = tostring(option), TextColor3 = Theme.Text,
            TextSize = 11, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, -12, 0, 28), Position = UDim2.fromOffset(6, 0),
            AutoButtonColor = false, Active = true, ZIndex = 32,
        }, list)
        optionButton.MouseButton1Click:Connect(function()
            setValue(option, true); open = false; list.Visible = false; hit.ZIndex = 14
        end)
    end
    local function toggleList()
        open = not open; list.Visible = open; hit.ZIndex = open and 12 or 14
        list.Size = UDim2.new(1, 0, 0, open and math.min(150, #values * 30 + 8) or 0)
    end
    hit.MouseButton1Click:Connect(toggleList)
    table.insert(self.Controls, row)
    return {Set = function(_, v, fire) setValue(v, fire ~= false) end, Get = function() return selected end, Row = row}
end

function Section:CreateMultiDropdown(config)
    config = config or {}
    local values = config.Options or config.Values or {}
    local selected = {}
    for _, value in ipairs(config.Default or config.ValuesSelected or {}) do selected[value] = true end
    local row = self:_row(config, 46)
    local title = label(row, config.Title or config.Name or "Multi select", 11, Theme.TextMuted, Enum.Font.GothamMedium)
    title.Position, title.Size = UDim2.fromOffset(13, 3), UDim2.new(0.42, 0, 0, 18)
    local summary = label(row, "None selected", 11, Theme.Text, Enum.Font.GothamMedium)
    summary.AnchorPoint, summary.Position, summary.Size = Vector2.new(1, 0), UDim2.new(1, -36, 0, 20), UDim2.new(0.54, 0, 0, 20)
    summary.TextXAlignment = Enum.TextXAlignment.Right
    local function refresh()
        local names = {}
        for _, option in ipairs(values) do if selected[option] then table.insert(names, tostring(option)) end end
        summary.Text = #names == 0 and "None selected" or table.concat(names, ", ")
    end
    refresh()
    local list = make("Frame", {
        BackgroundColor3 = Theme.SurfaceRaised, BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, 5),
        Size = UDim2.new(1, 0, 0, 0), ClipsDescendants = true, Visible = false, ZIndex = 30,
    }, row)
    corner(list, 9); stroke(list, Theme.Border, 0.1, 1)
    local hit = button(row, "MultiDropdownHitbox", 14); hit.Size = UDim2.fromScale(1, 1)
    local open = false
    for _, option in ipairs(values) do
        local optionButton = make("TextButton", {
            BackgroundTransparency = 1, Text = "  " .. tostring(option), TextColor3 = Theme.Text,
            TextSize = 11, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, -12, 0, 28), AutoButtonColor = false, Active = true, ZIndex = 32,
        }, list)
        optionButton.MouseButton1Click:Connect(function()
            selected[option] = not selected[option]; refresh()
            local output = {}; for _, item in ipairs(values) do if selected[item] then table.insert(output, item) end end
            safeCallback(resolveCallback(config), output)
        end)
    end
    hit.MouseButton1Click:Connect(function()
        open = not open; list.Visible = open; hit.ZIndex = open and 12 or 14
        list.Size = UDim2.new(1, 0, 0, open and math.min(150, #values * 30 + 8) or 0)
    end)
    table.insert(self.Controls, row)
    return {Get = function() local output = {}; for _, item in ipairs(values) do if selected[item] then table.insert(output, item) end end; return output end, Row = row}
end

function Section:CreateTextbox(config)
    config = config or {}
    local row = self:_row(config, 52)
    local title = label(row, config.Title or config.Name or "Textbox", 11, Theme.TextMuted, Enum.Font.GothamMedium)
    title.Position, title.Size = UDim2.fromOffset(13, 4), UDim2.new(0.36, 0, 0, 18)
    local input = make("TextBox", {
        BackgroundColor3 = Theme.Background, BorderSizePixel = 0, ClearTextOnFocus = false,
        PlaceholderText = config.Placeholder or "Type here...", PlaceholderColor3 = Theme.TextDim,
        Text = tostring(config.Default or config.Value or ""), TextColor3 = Theme.Text, TextSize = 11,
        Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0.36, 0, 0, 9), Size = UDim2.new(0.62, -4, 0, 32),
        Active = true, ZIndex = 15,
    }, row)
    corner(input, 8); padding(input, 10, 0, 10, 0)
    stroke(input, Theme.Border, 0.4, 1)
    input.FocusLost:Connect(function(enterPressed)
        safeCallback(resolveCallback(config), input.Text, enterPressed)
    end)
    table.insert(self.Controls, input)
    return {Set = function(_, value) input.Text = tostring(value or "") end, Get = function() return input.Text end, Row = row}
end

function Section:CreateSlider(config)
    config = config or {}
    local minimum, maximum = tonumber(config.Min or config.Minimum) or 0, tonumber(config.Max or config.Maximum) or 100
    local value = math.clamp(tonumber(config.Default or config.Value) or minimum, minimum, maximum)
    local row = self:_row(config, 57)
    local title = label(row, config.Title or config.Name or "Slider", 11, Theme.TextMuted, Enum.Font.GothamMedium)
    title.Position, title.Size = UDim2.fromOffset(13, 4), UDim2.new(0.65, 0, 0, 18)
    local valueText = label(row, tostring(value), 11, Theme.Text, Enum.Font.GothamBold)
    valueText.AnchorPoint, valueText.Position, valueText.Size = Vector2.new(1, 0), UDim2.new(1, -13, 0, 18), UDim2.fromOffset(60, 18)
    valueText.TextXAlignment = Enum.TextXAlignment.Right
    local track = make("Frame", {
        BackgroundColor3 = Theme.Background, BorderSizePixel = 0, Position = UDim2.fromOffset(13, 32),
        Size = UDim2.new(1, -26, 0, 6), ZIndex = 11,
    }, row)
    corner(track, 3)
    local fill = make("Frame", {
        BackgroundColor3 = Theme.Accent, BorderSizePixel = 0,
        Size = UDim2.fromScale((value - minimum) / math.max(1, maximum - minimum), 1), ZIndex = 12,
    }, track)
    corner(fill, 3)
    local knob = make("Frame", {
        BackgroundColor3 = Theme.AccentBright, BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new((value - minimum) / math.max(1, maximum - minimum), 0, 0.5, 0),
        Size = UDim2.fromOffset(13, 13), ZIndex = 13,
    }, track)
    corner(knob, 7)
    local hit = button(track, "SliderHitbox", 14); hit.Size = UDim2.fromScale(1, 3); hit.Position = UDim2.fromScale(0, -1)
    local dragging = false
    local function update(input, fire)
        local percent = math.clamp((input.Position.X - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)
        value = minimum + (maximum - minimum) * percent
        if config.Rounding or config.Decimals then
            local places = tonumber(config.Rounding or config.Decimals) or 0
            local factor = 10 ^ places; value = math.floor(value * factor + 0.5) / factor
        else value = math.floor(value + 0.5) end
        local ratio = (value - minimum) / math.max(1, maximum - minimum)
        fill.Size, knob.Position, valueText.Text = UDim2.fromScale(ratio, 1), UDim2.new(ratio, 0, 0.5, 0), tostring(value)
        if fire then safeCallback(resolveCallback(config), value) end
    end
    hit.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; update(input, true) end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then update(input, true) end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
    table.insert(self.Controls, row)
    return {Set = function(_, v, fire) value = math.clamp(tonumber(v) or minimum, minimum, maximum); local ratio = (value - minimum) / math.max(1, maximum - minimum); fill.Size = UDim2.fromScale(ratio, 1); knob.Position = UDim2.new(ratio, 0, 0.5, 0); valueText.Text = tostring(value); if fire ~= false then safeCallback(resolveCallback(config), value) end end, Get = function() return value end, Row = row}
end

function Section:CreateColorpicker(config)
    config = config or {}
    local value = config.Default or config.Color or Color3.fromRGB(100, 120, 230)
    local row = self:_row(config, 42)
    local title = label(row, config.Title or config.Name or "Color", 12, Theme.Text, Enum.Font.GothamMedium)
    title.Position, title.Size = UDim2.fromOffset(13, 0), UDim2.new(1, -80, 1, 0)
    local swatch = make("Frame", {BackgroundColor3 = value, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -13, 0.5, 0), Size = UDim2.fromOffset(42, 22), ZIndex = 11}, row)
    corner(swatch, 7); stroke(swatch, Theme.Text, 0.55, 1)
    local hit = button(row, "ColorHitbox", 14); hit.Size = UDim2.fromScale(1, 1)
    local palette = make("Frame", {BackgroundColor3 = Theme.SurfaceRaised, BorderSizePixel = 0, Position = UDim2.new(1, -178, 1, 5), Size = UDim2.fromOffset(165, 0), ClipsDescendants = true, Visible = false, ZIndex = 30}, row)
    corner(palette, 9); stroke(palette, Theme.Border, 0.1, 1); padding(palette, 8, 8, 8, 8)
    local colors = {Color3.fromRGB(240, 95, 111), Color3.fromRGB(241, 184, 92), Color3.fromRGB(80, 205, 143), Color3.fromRGB(89, 164, 255), Color3.fromRGB(137, 113, 255), Color3.fromRGB(230, 236, 255)}
    local grid = make("UIGridLayout", {CellSize = UDim2.fromOffset(22, 22), CellPadding = UDim2.fromOffset(9, 7)}, palette)
    for _, color in ipairs(colors) do
        local colorButton = make("TextButton", {Text = "", AutoButtonColor = false, BackgroundColor3 = color, BorderSizePixel = 0, Active = true, ZIndex = 32}, palette)
        corner(colorButton, 7)
        colorButton.MouseButton1Click:Connect(function() value = color; swatch.BackgroundColor3 = value; palette.Visible = false; palette.Size = UDim2.fromOffset(165, 0); safeCallback(resolveCallback(config), value) end)
    end
    local open = false
    hit.MouseButton1Click:Connect(function() open = not open; palette.Visible = open; palette.Size = UDim2.fromOffset(165, open and 100 or 0) end)
    table.insert(self.Controls, row)
    return {Set = function(_, color, fire) if typeof(color) == "Color3" then value = color; swatch.BackgroundColor3 = color; if fire ~= false then safeCallback(resolveCallback(config), color) end end end, Get = function() return value end, Row = row}
end

function Section:CreateLabel(config)
    if type(config) == "string" then config = {Text = config} end
    config = config or {}
    local row = self:_row(config, config.Height or 30)
    row.BackgroundTransparency = 1
    local text = label(row, config.Text or config.Title or "", config.TextSize or 11, config.Color or Theme.TextMuted, config.Font or Enum.Font.Gotham)
    text.Size = UDim2.fromScale(1, 1)
    table.insert(self.Controls, text)
    return text
end

function Section:CreateStatRow(config)
    config = config or {}
    local row = self:_row(config, 48)
    local title = label(row, config.Title or config.Name or "Status", 11, Theme.TextMuted, Enum.Font.GothamMedium)
    title.Position, title.Size = UDim2.fromOffset(13, 0), UDim2.new(0.6, 0, 1, 0)
    local value = label(row, tostring(config.Value or config.Text or "—"), 14, config.Color or Theme.AccentBright, Enum.Font.GothamBold)
    value.AnchorPoint, value.Position, value.Size = Vector2.new(1, 0), UDim2.new(1, -13, 0, 0), UDim2.new(0.38, 0, 1, 0)
    value.TextXAlignment = Enum.TextXAlignment.Right
    table.insert(self.Controls, row)
    return {Set = function(_, newValue) value.Text = tostring(newValue) end, Row = row}
end

-- Tab-level convenience methods preserve the traditional Khfresh Hub API.
for _, method in ipairs({"CreateButton", "CreateToggle", "CreateDropdown", "CreateMultiDropdown", "CreateTextbox", "CreateSlider", "CreateColorpicker", "CreateLabel", "CreateStatRow"}) do
    Tab[method] = function(self, config, ...)
        local section = self._directSection
        if not section then
            section = Section.new(self, {Title = "Controls", Name = "Controls", Subtitle = ""})
            self._directSection = section
        end
        return section[method](section, config, ...)
    end
end

-- Section aliases are useful to scripts that use mixed casing.
Section.CreateColorPicker = Section.CreateColorpicker

return UI
