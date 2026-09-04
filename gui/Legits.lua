--[[
    Legits
    A lightweight legitimate HUD library for Roblox.

    Modules:
        Clock
        Coords
        FPS
        Keystrokes

    Special:
        Legits.StartEditMode()
        Legits.StopEditMode()

    Usage:
        local Legits = loadstring(game:HttpGet("YOUR_RAW_GITHUB_URL"))()

        Legits.Clock.Show()
        Legits.FPS.Show()
        Legits.Coords.Show()

        Legits.Keystrokes.Show()
        Legits.Keystrokes.SetKeyStyle("Keyboard")
        Legits.Keystrokes.SetMouseStyle("Names")
        Legits.Keystrokes.ShowSpaceBar()

        Legits.StartEditMode()
]]

----------------------------------------------------------------
-- Services
----------------------------------------------------------------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

if not LocalPlayer then
    error("Legits must be executed from the client.")
end

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

----------------------------------------------------------------
-- Prevent duplicate Legits GUIs
----------------------------------------------------------------

local GUI_NAME = "LegitsHUD"

local ExistingGui = PlayerGui:FindFirstChild(GUI_NAME)

if ExistingGui then
    ExistingGui:Destroy()
end

----------------------------------------------------------------
-- Library
----------------------------------------------------------------

local Legits = {}

----------------------------------------------------------------
-- Constants
----------------------------------------------------------------

local FONT = Enum.Font.Code

local BACKGROUND_COLOR = Color3.fromRGB(35, 35, 35)
local BORDER_COLOR = Color3.fromRGB(15, 15, 15)
local TEXT_COLOR = Color3.fromRGB(235, 235, 235)

local ACTIVE_KEY_COLOR = Color3.fromRGB(75, 75, 75)
local INACTIVE_KEY_COLOR = Color3.fromRGB(42, 42, 42)

local HUD_HEIGHT = 22
local HUD_PADDING_X = 7
local HUD_PADDING_Y = 3

----------------------------------------------------------------
-- State
----------------------------------------------------------------

local EditMode = false
local EditConnections = {}

local DragState = {
    Object = nil,
    StartMouse = nil,
    StartPosition = nil,
}

----------------------------------------------------------------
-- Main GUI
----------------------------------------------------------------

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = GUI_NAME
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 10
ScreenGui.Parent = PlayerGui

----------------------------------------------------------------
-- Utility
----------------------------------------------------------------

local function Disconnect(connection)
    if connection then
        connection:Disconnect()
    end
end

local function DisconnectAll(list)
    for _, connection in ipairs(list) do
        Disconnect(connection)
    end

    table.clear(list)
end

local function SetTextStyle(textObject)
    textObject.Font = FONT
    textObject.TextColor3 = TEXT_COLOR
    textObject.TextSize = 14
    textObject.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    textObject.TextStrokeTransparency = 0.55
    textObject.BackgroundTransparency = 1
    textObject.BorderSizePixel = 0
end

local function AddPadding(frame)
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, HUD_PADDING_X)
    padding.PaddingRight = UDim.new(0, HUD_PADDING_X)
    padding.PaddingTop = UDim.new(0, HUD_PADDING_Y)
    padding.PaddingBottom = UDim.new(0, HUD_PADDING_Y)
    padding.Parent = frame

    return padding
end

local function CreateHUDFrame(name, position, size)
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.Position = position
    frame.Size = size or UDim2.new(0, 0, 0, HUD_HEIGHT)
    frame.BackgroundColor3 = BACKGROUND_COLOR
    frame.BackgroundTransparency = 0.23
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Active = true
    frame.ZIndex = 20
    frame.Parent = ScreenGui

    local stroke = Instance.new("UIStroke")
    stroke.Name = "Border"
    stroke.Color = BORDER_COLOR
    stroke.Thickness = 1
    stroke.Transparency = 0.15
    stroke.Parent = frame

    AddPadding(frame)

    return frame, stroke
end

local function CreateHUDText(frame)
    local label = Instance.new("TextLabel")
    label.Name = "Text"
    label.Size = UDim2.new(0, 0, 1, 0)
    label.AutomaticSize = Enum.AutomaticSize.X
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.ZIndex = frame.ZIndex + 1
    SetTextStyle(label)
    label.Parent = frame

    return label
end

local function SetModulePosition(frame, position)
    frame.Position = position
end

----------------------------------------------------------------
-- Clock
----------------------------------------------------------------

local Clock = {}

Clock.Type = 12

Clock.Frame, Clock.Stroke = CreateHUDFrame(
    "Clock",
    UDim2.new(1, -8, 0, 8),
    UDim2.new(0, 0, 0, HUD_HEIGHT)
)

Clock.Frame.AnchorPoint = Vector2.new(1, 0)

Clock.Text = CreateHUDText(Clock.Frame)

function Clock.Show()
    Clock.Frame.Visible = true
end

function Clock.Hide()
    Clock.Frame.Visible = false
end

function Clock.SetType(value)
    if value ~= 12 and value ~= 24 then
        return false
    end

    Clock.Type = value
    return true
end

function Clock.Update()
    if not Clock.Frame.Visible then
        return
    end

    local now = os.date("*t")

    if Clock.Type == 24 then
        Clock.Text.Text = string.format(
            "%02d:%02d:%02d",
            now.hour,
            now.min,
            now.sec
        )
    else
        local hour = now.hour
        local suffix = "AM"

        if hour >= 12 then
            suffix = "PM"
        end

        hour = hour % 12

        if hour == 0 then
            hour = 12
        end

        Clock.Text.Text = string.format(
            "%02d:%02d:%02d %s",
            hour,
            now.min,
            now.sec,
            suffix
        )
    end
end

Legits.Clock = Clock

----------------------------------------------------------------
-- Coords
----------------------------------------------------------------

local Coords = {}

Coords.Frame, Coords.Stroke = CreateHUDFrame(
    "Coords",
    UDim2.new(0, 8, 0, 8),
    UDim2.new(0, 0, 0, HUD_HEIGHT)
)

Coords.Text = CreateHUDText(Coords.Frame)

function Coords.Show()
    Coords.Frame.Visible = true
end

function Coords.Hide()
    Coords.Frame.Visible = false
end

function Coords.Update()
    if not Coords.Frame.Visible then
        return
    end

    local character = LocalPlayer.Character

    if not character then
        Coords.Text.Text = "XYZ: --, --, --"
        return
    end

    local root = character:FindFirstChild("HumanoidRootPart")

    if not root then
        Coords.Text.Text = "XYZ: --, --, --"
        return
    end

    local position = root.Position

    Coords.Text.Text = string.format(
        "XYZ: %.2f, %.2f, %.2f",
        position.X,
        position.Y,
        position.Z
    )
end

Legits.Coords = Coords

----------------------------------------------------------------
-- FPS
----------------------------------------------------------------

local FPS = {}

FPS.Frame, FPS.Stroke = CreateHUDFrame(
    "FPS",
    UDim2.new(1, -8, 0, 38),
    UDim2.new(0, 0, 0, HUD_HEIGHT)
)

FPS.Frame.AnchorPoint = Vector2.new(1, 0)

FPS.Text = CreateHUDText(FPS.Frame)

FPS.Samples = {}
FPS.SampleTime = 0.5
FPS.Value = 0

function FPS.Show()
    FPS.Frame.Visible = true
end

function FPS.Hide()
    FPS.Frame.Visible = false
end

function FPS.Update(deltaTime)
    if deltaTime <= 0 then
        return
    end

    local now = os.clock()

    FPS.Samples[#FPS.Samples + 1] = {
        Time = now,
        Delta = deltaTime,
    }

    local cutoff = now - FPS.SampleTime

    local removeCount = 0

    for index, sample in ipairs(FPS.Samples) do
        if sample.Time < cutoff then
            removeCount = index
        else
            break
        end
    end

    if removeCount > 0 then
        for index = 1, #FPS.Samples - removeCount do
            FPS.Samples[index] = FPS.Samples[index + removeCount]
        end

        for index = #FPS.Samples, #FPS.Samples - removeCount + 1, -1 do
            FPS.Samples[index] = nil
        end
    end

    local sampleCount = #FPS.Samples

    if sampleCount > 0 then
        local totalTime = 0

        for _, sample in ipairs(FPS.Samples) do
            totalTime += sample.Delta
        end

        if totalTime > 0 then
            FPS.Value = sampleCount / totalTime
        end
    end

    if FPS.Frame.Visible then
        FPS.Text.Text = string.format(
            "FPS: %.0f",
            FPS.Value
        )
    end
end

Legits.FPS = FPS

----------------------------------------------------------------
-- Keystrokes
----------------------------------------------------------------

local Keystrokes = {}

Keystrokes.KeyStyle = "Keyboard"
Keystrokes.MouseStyle = "Names"
Keystrokes.SpaceBar = false

Keystrokes.Clicks = {}

Keystrokes.Frame, Keystrokes.Stroke = CreateHUDFrame(
    "Keystrokes",
    UDim2.new(0, 8, 1, -8),
    UDim2.new(0, 150, 0, 190)
)

Keystrokes.Frame.AnchorPoint = Vector2.new(0, 1)

-- Remove the normal HUD padding because this module has its own layout.
for _, child in ipairs(Keystrokes.Frame:GetChildren()) do
    if child:IsA("UIPadding") then
        child:Destroy()
    end
end

----------------------------------------------------------------
-- Keystrokes layout helpers
----------------------------------------------------------------

local function CreateKey(parent, name, x, y, width, height)
    local key = Instance.new("TextLabel")
    key.Name = name
    key.Position = UDim2.new(0, x, 0, y)
    key.Size = UDim2.new(0, width, 0, height)
    key.BackgroundColor3 = INACTIVE_KEY_COLOR
    key.BackgroundTransparency = 0.05
    key.BorderSizePixel = 0
    key.Text = ""
    key.TextColor3 = TEXT_COLOR
    key.TextSize = 15
    key.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    key.TextStrokeTransparency = 0.55
    key.Font = FONT
    key.ZIndex = 21
    key.Parent = parent

    local stroke = Instance.new("UIStroke")
    stroke.Name = "Border"
    stroke.Color = BORDER_COLOR
    stroke.Thickness = 1
    stroke.Transparency = 0.2
    stroke.Parent = key

    return key
end

local KEY_WIDTH = 40
local KEY_HEIGHT = 40
local GAP = 3

local CENTER_X = 55
local LEFT_X = CENTER_X - KEY_WIDTH - GAP
local RIGHT_X = CENTER_X + KEY_WIDTH + GAP

Keystrokes.Keys = {
    W = CreateKey(
        Keystrokes.Frame,
        "W",
        CENTER_X,
        8,
        KEY_WIDTH,
        KEY_HEIGHT
    ),

    A = CreateKey(
        Keystrokes.Frame,
        "A",
        LEFT_X,
        8 + KEY_HEIGHT + GAP,
        KEY_WIDTH,
        KEY_HEIGHT
    ),

    S = CreateKey(
        Keystrokes.Frame,
        "S",
        CENTER_X,
        8 + KEY_HEIGHT + GAP,
        KEY_WIDTH,
        KEY_HEIGHT
    ),

    D = CreateKey(
        Keystrokes.Frame,
        "D",
        RIGHT_X,
        8 + KEY_HEIGHT + GAP,
        KEY_WIDTH,
        KEY_HEIGHT
    ),

    LMB = CreateKey(
        Keystrokes.Frame,
        "LMB",
        LEFT_X,
        8 + (KEY_HEIGHT + GAP) * 2,
        KEY_WIDTH,
        30
    ),

    RMB = CreateKey(
        Keystrokes.Frame,
        "RMB",
        CENTER_X,
        8 + (KEY_HEIGHT + GAP) * 2,
        KEY_WIDTH,
        30
    ),

    CPS = CreateKey(
        Keystrokes.Frame,
        "CPS",
        RIGHT_X,
        8 + (KEY_HEIGHT + GAP) * 2,
        KEY_WIDTH,
        30
    ),
}

Keystrokes.Space = CreateKey(
    Keystrokes.Frame,
    "Space",
    LEFT_X,
    8 + (KEY_HEIGHT + GAP) * 2 + 30 + GAP,
    KEY_WIDTH * 3 + GAP * 2,
    30
)

Keystrokes.CPS.Text = "0"

Keystrokes.CPS.MouseButton = "CPS"

----------------------------------------------------------------
-- Keystrokes configuration
----------------------------------------------------------------

function Keystrokes.Show()
    Keystrokes.Frame.Visible = true
end

function Keystrokes.Hide()
    Keystrokes.Frame.Visible = false
end

function Keystrokes.SetKeyStyle(value)
    if value ~= "Keyboard" and value ~= "Arrows" then
        return false
    end

    Keystrokes.KeyStyle = value
    return true
end

function Keystrokes.SetMouseStyle(value)
    if value ~= "Names" and value ~= "None" then
        return false
    end

    Keystrokes.MouseStyle = value
    return true
end

function Keystrokes.ShowSpaceBar()
    Keystrokes.SpaceBar = true
    return true
end

-- Optional convenience function.
function Keystrokes.HideSpaceBar()
    Keystrokes.SpaceBar = false
    return true
end

local function GetKeyboardKeyCodes()
    if Keystrokes.KeyStyle == "Arrows" then
        return {
            W = Enum.KeyCode.Up,
            A = Enum.KeyCode.Left,
            S = Enum.KeyCode.Down,
            D = Enum.KeyCode.Right,
        }
    end

    return {
        W = Enum.KeyCode.W,
        A = Enum.KeyCode.A,
        S = Enum.KeyCode.S,
        D = Enum.KeyCode.D,
    }
end

local function UpdateKeystrokeLabels()
    if Keystrokes.KeyStyle == "Arrows" then
        Keystrokes.Keys.W.Text = "↑"
        Keystrokes.Keys.A.Text = "←"
        Keystrokes.Keys.S.Text = "↓"
        Keystrokes.Keys.D.Text = "→"
    else
        Keystrokes.Keys.W.Text = "W"
        Keystrokes.Keys.A.Text = "A"
        Keystrokes.Keys.S.Text = "S"
        Keystrokes.Keys.D.Text = "D"
    end

    if Keystrokes.MouseStyle == "Names" then
        Keystrokes.Keys.LMB.Text = "LMB"
        Keystrokes.Keys.RMB.Text = "RMB"
    else
        Keystrokes.Keys.LMB.Text = ""
        Keystrokes.Keys.RMB.Text = ""
    end

    Keystrokes.Space.Visible = Keystrokes.SpaceBar
end

local function SetKeyActive(key, active)
    key.BackgroundColor3 = active
        and ACTIVE_KEY_COLOR
        or INACTIVE_KEY_COLOR
end

function Keystrokes.Update()
    UpdateKeystrokeLabels()

    if not Keystrokes.Frame.Visible then
        return
    end

    local keyCodes = GetKeyboardKeyCodes()

    SetKeyActive(
        Keystrokes.Keys.W,
        UserInputService:IsKeyDown(keyCodes.W)
    )

    SetKeyActive(
        Keystrokes.Keys.A,
        UserInputService:IsKeyDown(keyCodes.A)
    )

    SetKeyActive(
        Keystrokes.Keys.S,
        UserInputService:IsKeyDown(keyCodes.S)
    )

    SetKeyActive(
        Keystrokes.Keys.D,
        UserInputService:IsKeyDown(keyCodes.D)
    )

    SetKeyActive(
        Keystrokes.Keys.LMB,
        UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
    )

    SetKeyActive(
        Keystrokes.Keys.RMB,
        UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    )

    SetKeyActive(
        Keystrokes.Space,
        UserInputService:IsKeyDown(Enum.KeyCode.Space)
    )

    Keystrokes.CPS.Text = tostring(#Keystrokes.Clicks)
end

Legits.Keystrokes = Keystrokes

----------------------------------------------------------------
-- Mouse click tracking for CPS
----------------------------------------------------------------

local ClickConnection = UserInputService.InputBegan:Connect(function(input, processed)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.MouseButton2 then
        return
    end

    if processed then
        return
    end

    Keystrokes.Clicks[#Keystrokes.Clicks + 1] = os.clock()
end)

----------------------------------------------------------------
-- Edit mode
----------------------------------------------------------------

local EditInstruction = nil

local function CreateEditInstruction()
    if EditInstruction then
        EditInstruction:Destroy()
    end

    local label = Instance.new("TextLabel")
    label.Name = "EditInstruction"
    label.AnchorPoint = Vector2.new(0.5, 1)
    label.Position = UDim2.new(0.5, 0, 1, -10)
    label.Size = UDim2.new(0, 320, 0, 26)
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.Text = "Press Esc to exit edit mode"
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 16
    label.Font = FONT
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.TextStrokeTransparency = 0
    label.ZIndex = 100
    label.Parent = ScreenGui

    EditInstruction = label
end

local function RemoveEditInstruction()
    if EditInstruction then
        EditInstruction:Destroy()
        EditInstruction = nil
    end
end

local function GetVisibleModules()
    return {
        Clock,
        Coords,
        FPS,
        Keystrokes,
    }
end

local function CreateDragOverlay(module)
    local frame = module.Frame

    local overlay = Instance.new("Frame")
    overlay.Name = "EditOverlay"
    overlay.BackgroundTransparency = 1
    overlay.BorderSizePixel = 0
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.Position = UDim2.new(0, 0, 0, 0)
    overlay.Active = true
    overlay.Selectable = true
    overlay.ZIndex = 90
    overlay.Parent = frame

    return overlay
end

function Legits.StartEditMode()
    if EditMode then
        return
    end

    EditMode = true

    CreateEditInstruction()

    for _, module in ipairs(GetVisibleModules()) do
        local frame = module.Frame

        if frame.Visible then
            module._editOverlay = CreateDragOverlay(module)

            if module.Stroke then
                module.Stroke.Transparency = 0
                module.Stroke.Color = Color3.fromRGB(180, 180, 180)
            end

            table.insert(EditConnections, module._editOverlay.InputBegan:Connect(function(input)
                if not EditMode then
                    return
                end

                if input.UserInputType ~= Enum.UserInputType.MouseButton1
                    and input.UserInputType ~= Enum.UserInputType.Touch then
                    return
                end

                DragState.Object = frame
                DragState.StartMouse = input.Position
                DragState.StartPosition = frame.AbsolutePosition

                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        if DragState.Object == frame then
                            DragState.Object = nil
                            DragState.StartMouse = nil
                            DragState.StartPosition = nil
                        end
                    end
                end)
            end))
        end
    end

    table.insert(EditConnections, UserInputService.InputChanged:Connect(function(input)
        if not EditMode then
            return
        end

        local frame = DragState.Object

        if not frame then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        if not DragState.StartMouse or not DragState.StartPosition then
            return
        end

        local delta = input.Position - DragState.StartMouse

        local parentSize = ScreenGui.AbsoluteSize
        local frameSize = frame.AbsoluteSize

        local x = DragState.StartPosition.X + delta.X
        local y = DragState.StartPosition.Y + delta.Y

        local parentAbsolutePosition = ScreenGui.AbsolutePosition

        x -= parentAbsolutePosition.X
        y -= parentAbsolutePosition.Y

        local maxX = math.max(0, parentSize.X - frameSize.X)
        local maxY = math.max(0, parentSize.Y - frameSize.Y)

        x = math.clamp(x, 0, maxX)
        y = math.clamp(y, 0, maxY)

        frame.Position = UDim2.fromOffset(
            math.floor(x + 0.5),
            math.floor(y + 0.5)
        )
    end))

    table.insert(EditConnections, UserInputService.InputBegan:Connect(function(input)
        if not EditMode then
            return
        end

        if input.KeyCode == Enum.KeyCode.Escape then
            Legits.StopEditMode()
        end
    end))
end

function Legits.StopEditMode()
    if not EditMode then
        return
    end

    EditMode = false

    DragState.Object = nil
    DragState.StartMouse = nil
    DragState.StartPosition = nil

    for _, module in ipairs(GetVisibleModules()) do
        if module._editOverlay then
            module._editOverlay:Destroy()
            module._editOverlay = nil
        end

        if module.Stroke then
            module.Stroke.Transparency = 0.15
            module.Stroke.Color = BORDER_COLOR
        end
    end

    DisconnectAll(EditConnections)
    RemoveEditInstruction()
end

Legits.IsEditMode = function()
    return EditMode
end

----------------------------------------------------------------
-- Main update loop
----------------------------------------------------------------

local RenderConnection = RunService.RenderStepped:Connect(function(deltaTime)
    Clock.Update()
    Coords.Update()
    FPS.Update(deltaTime)
    Keystrokes.Update()

    local now = os.clock()
    local cutoff = now - 1

    local clicks = Keystrokes.Clicks

    while #clicks > 0 and clicks[1] < cutoff do
        table.remove(clicks, 1)
    end
end)

----------------------------------------------------------------
-- Cleanup
----------------------------------------------------------------

function Legits.Destroy()
    Legits.StopEditMode()

    Disconnect(ClickConnection)
    Disconnect(RenderConnection)

    if ScreenGui then
        ScreenGui:Destroy()
    end
end

----------------------------------------------------------------
-- Defaults
----------------------------------------------------------------

Clock.SetType(12)
Keystrokes.SetKeyStyle("Keyboard")
Keystrokes.SetMouseStyle("Names")

----------------------------------------------------------------
-- Return library
----------------------------------------------------------------

return Legits
