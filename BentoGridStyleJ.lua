-- BentoGridStyleJ executor example
-- Copy BentoLucide.lua to BentoGridStyleJ.lua on GitHub first.

local URL =
    "https://raw.githubusercontent.com/bvect1037-alt/KhfreshUI/main/BentoGridStyleJ.lua?t="
    .. tostring(os.time())

local Source = game:HttpGet(URL)
local Compile = loadstring or load
assert(type(Compile) == "function", "Executor does not support loadstring")

local Chunk, CompileError = Compile(Source)
assert(Chunk, "BentoGridStyleJ compile failed: " .. tostring(CompileError))

local Library = Chunk()
assert(type(Library) == "table", "Library did not return a table")
assert(type(Library.new) == "function", "Library.new is missing")

local UI = Library.new({
    Name = "KasumiBento",
    Title = "KASUMI",
    Subtitle = "Japanese Bento Grid",
    Width = 760,
    Height = 560,
    IconPack = "lucide",
    PerformanceProfile = "PC",
})

local Main = UI:AddTab({
    Name = "Main",
    Icon = "lucide:layout-dashboard",
})

Main:AddSection({
    Name = "Overview",
    Title = "Overview",
    Icon = "lucide:sparkles",
}):AddParagraph({
    Text = "Sidebar tabs, fixed cards and popup dropdown controls.",
    Muted = true,
})

Main:AddToggle({
    Name = "AutoFarm",
    Title = "Auto Farm",
    Icon = "lucide:zap",
    Description = "This toggle only changes color and knob state.",
    Default = false,
    Callback = function(enabled)
        print("Auto Farm:", enabled)
    end,
})

Main:AddSlider({
    Name = "WalkSpeed",
    Title = "Walk Speed",
    Icon = "lucide:gauge",
    Min = 16,
    Max = 150,
    Step = 1,
    Default = 16,
    Callback = function(value)
        local player = game:GetService("Players").LocalPlayer
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = value
        end
    end,
})

Main:AddDropdown({
    Name = "WorkspaceMode",
    Title = "Workspace Mode",
    Icon = "lucide:layers",
    Options = {"Focus", "Explore", "Quiet"},
    Placeholder = "Click To Select",
    Default = "Focus",
    Callback = function(value)
        print("Workspace mode:", value)
    end,
})

Main:AddMultiDropdown({
    Name = "VisiblePanels",
    Title = "Visible Panels",
    Icon = "lucide:list",
    Options = {"Overview", "Statistics", "Activity", "Logs"},
    Placeholder = "Click To Select",
    Default = {"Overview", "Statistics"},
    Callback = function(values)
        print("Visible panels:", table.concat(values, ", "))
    end,
})

Main:AddButton({
    Name = "TestNotification",
    Title = "Test Notification",
    Icon = "lucide:bell",
    Description = "Show a notification without changing panel geometry.",
    Callback = function()
        UI:Notify({
            Title = "KASUMI",
            Description = "Notification is working.",
            Type = "Success",
            Duration = 3,
        })
    end,
})

local Settings = UI:AddTab({
    Name = "Settings",
    Icon = "lucide:settings-2",
})

Settings:AddTextbox({
    Name = "PlayerName",
    Title = "Player Name",
    Icon = "lucide:user",
    Placeholder = "Enter a name",
    Default = "Kasumi",
    Callback = function(value)
        print("Player name:", value)
    end,
})

Settings:AddColorPicker({
    Name = "AccentColor",
    Title = "Accent Color",
    Icon = "lucide:palette",
    Default = Color3.fromRGB(205, 219, 255),
    Callback = function(color)
        UI:SetTheme({
            Accent = color,
        })
    end,
})

Settings:AddDropdown({
    Name = "DeviceProfile",
    Title = "Performance Profile",
    Icon = "lucide:monitor-smartphone",
    Options = {"PC", "Mobile"},
    Placeholder = "Click To Select",
    Default = "PC",
    Callback = function(profile)
        UI:SetPerformanceProfile(profile)
    end,
})

Settings:AddKeybind({
    Name = "ToggleInterface",
    Title = "Toggle Interface",
    Icon = "lucide:keyboard",
    Default = Enum.KeyCode.RightShift,
    Callback = function(_, activated)
        if activated then
            UI:SetVisible(not UI._visible)
        end
    end,
})

UI:RegisterThemePreset("Ocean", {
    Background = Color3.fromRGB(9, 18, 28),
    Surface = Color3.fromRGB(14, 29, 43),
    Surface2 = Color3.fromRGB(22, 42, 59),
    Accent = Color3.fromRGB(129, 220, 238),
    AccentDark = Color3.fromRGB(34, 103, 128),
})

-- Uncomment this line if you want to use the custom theme:
-- UI:ApplyThemePreset("Ocean")

UI:SetWindowPadding(16)
UI:SetWindowDraggable(true)
UI:SetNotificationLimit(4)
UI:WatchViewport()

UI:Notify({
    Title = "KASUMI loaded",
    Description = "Use the left sidebar. Dropdown opens as a popup.",
    Type = "Success",
    Duration = 4,
})

getgenv().KasumiBentoUI = UI
