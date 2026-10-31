--[[
	Elite Client - TextGUI (ModuleList / ArrayList)

	API only: no UI is created here. Build the options with WindUI in your own
	script and call the API from their Callbacks.

		local TextGUI = loadstring(game:HttpGet("<url to this file>"))()
		TextGUI.addModule("fly")
		TextGUI.delModule("fly")
]]

--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")

--// Environment
local Env = (getgenv and getgenv()) or _G

if Env.EliteTextGUI and Env.EliteTextGUI.destroy then
	pcall(Env.EliteTextGUI.destroy)
end

--// Constants
local WATERMARK_TEXT = "Elite Client"

local TEXT_SIZE = 18
local CUSTOM_TEXT_SIZE = 25
local WATERMARK_SIZE = 24
local PADDING_X = 16
local PADDING_Y = 6
local TEXT_OFFSET_X = 6
local TEXT_OFFSET_Y = 2

local RGB_SPEED = 0.2
local RGB_GRADIENT_STEP = 0.03
local CUSTOM_GRADIENT_SHIFT = 0.075

local SCALE_MIN = 0.5
local SCALE_MAX = 2

local BACKGROUND_COLOR = Color3.fromRGB(20, 20, 20)
local TWEEN_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Exponential)

local SORT_MODES = { "Alphabetical", "Length" }
local COLOR_MODES = { "RGB", "Custom Color" }
local FONT_LIST = {
	"Arial", "ArialBold", "Gotham", "GothamMedium", "GothamBold", "GothamBlack",
	"SourceSans", "SourceSansSemibold", "SourceSansBold", "Code", "RobotoMono",
	"Roboto", "Ubuntu", "Nunito", "Montserrat", "Oswald", "Jura", "Highway",
	"SciFi", "Michroma", "Arimo", "FredokaOne", "Bangers", "TitilliumWeb",
	"Merriweather", "Cartoon", "Fantasy", "Antique",
}

--// State
local State = {
	Sort = "Alphabetical",
	FontName = "Arial",
	ColorMode = "RGB",
	Color = Color3.fromRGB(255, 70, 70),
	Scale = 1,
	Shadow = true,
	Gradient = false,
	Animations = true,
	Watermark = false,
	Background = false,
	Transparency = 0.5,
	Tint = false,
	CustomText = false,
	CustomTextValue = "",
	CustomTextFontName = "Arial",
	CustomTextColor = Color3.fromRGB(255, 255, 255),
}

local Entries = {} -- [name] = entry
local Ordered = {} -- entries sorted for display
local Destroyed = false
local HeartbeatConnection

--// Helpers
local function canonicalFont(name)
	if type(name) ~= "string" then
		return nil
	end

	for _, fontName in FONT_LIST do
		if fontName:lower() == name:lower() then
			return fontName
		end
	end

	local ok = pcall(function()
		return Enum.Font[name]
	end)
	return ok and name or nil
end

local function resolveFont(name)
	local ok, font = pcall(function()
		return Font.fromEnum(Enum.Font[name])
	end)
	return ok and font or Font.fromEnum(Enum.Font.Arial)
end

local function measureText(text, font, textSize)
	local params = Instance.new("GetTextBoundsParams")
	params.Text = text
	params.Font = font
	params.Size = textSize
	params.Width = 10000

	local ok, bounds = pcall(TextService.GetTextBoundsAsync, TextService, params)
	if ok then
		return bounds
	end
	return Vector2.new(#text * textSize * 0.55, textSize)
end

--// GUI objects
local function getGuiParent()
	local ok, result = pcall(function()
		return (gethui and gethui()) or game:GetService("CoreGui")
	end)
	if ok and result then
		return result
	end
	return Players.LocalPlayer:WaitForChild("PlayerGui")
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "EliteTextGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 100
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = getGuiParent()

local Root = Instance.new("Frame")
Root.Name = "Root"
Root.BackgroundTransparency = 1
Root.AnchorPoint = Vector2.new(1, 0)
Root.Position = UDim2.new(1, -12, 0, 14)
Root.Size = UDim2.fromOffset(600, 0)
Root.AutomaticSize = Enum.AutomaticSize.Y
Root.Parent = ScreenGui

local RootScale = Instance.new("UIScale")
RootScale.Parent = Root

local RootLayout = Instance.new("UIListLayout")
RootLayout.SortOrder = Enum.SortOrder.LayoutOrder
RootLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
RootLayout.Padding = UDim.new(0, 2)
RootLayout.Parent = Root

local function createTextPair(parent)
	local shadow = Instance.new("TextLabel")
	shadow.Name = "Shadow"
	shadow.BackgroundTransparency = 1
	shadow.BorderSizePixel = 0
	shadow.TextColor3 = Color3.new()
	shadow.TextTransparency = 0.65
	shadow.TextXAlignment = Enum.TextXAlignment.Left
	shadow.ZIndex = 2
	shadow.Parent = parent

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 3
	label.Parent = parent

	return { Label = label, Shadow = shadow }
end

local function styleTextPair(pair, text, font, textSize, shadowEnabled)
	local bounds = measureText(text, font, textSize)
	local size = UDim2.fromOffset(bounds.X, bounds.Y)

	for _, textLabel in { pair.Label, pair.Shadow } do
		textLabel.FontFace = font
		textLabel.Text = text
		textLabel.TextSize = textSize
		textLabel.Size = size
	end

	pair.Label.Position = UDim2.fromOffset(TEXT_OFFSET_X, TEXT_OFFSET_Y)
	pair.Shadow.Position = UDim2.fromOffset(TEXT_OFFSET_X + 1, TEXT_OFFSET_Y + 1)
	pair.Shadow.Visible = shadowEnabled

	return bounds
end

local function createHeaderBlock(name, layoutOrder)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.BackgroundTransparency = 1
	frame.LayoutOrder = layoutOrder
	frame.Visible = false
	frame.Parent = Root

	return frame, createTextPair(frame)
end

local WatermarkFrame, WatermarkPair = createHeaderBlock("Watermark", 1)
local CustomTextFrame, CustomTextPair = createHeaderBlock("CustomText", 2)

local ListHolder = Instance.new("Frame")
ListHolder.Name = "Modules"
ListHolder.BackgroundTransparency = 1
ListHolder.LayoutOrder = 3
ListHolder.Size = UDim2.new(1, 0, 0, 0)
ListHolder.AutomaticSize = Enum.AutomaticSize.Y
ListHolder.Parent = Root

local ListLayout = Instance.new("UIListLayout")
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
ListLayout.Parent = ListHolder

--// Module entries
local function createEntry(name)
	local holder = Instance.new("Frame")
	holder.Name = name
	holder.BackgroundTransparency = 1
	holder.ClipsDescendants = true
	holder.Size = UDim2.fromOffset(0, 0)
	holder.Parent = ListHolder

	local background = Instance.new("Frame")
	background.Name = "Background"
	background.BackgroundColor3 = BACKGROUND_COLOR
	background.BorderSizePixel = 0
	background.Size = UDim2.fromScale(1, 1)
	background.ZIndex = 1
	background.Visible = false
	background.Parent = holder

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 3)
	corner.Parent = background

	local accent = Instance.new("Frame")
	accent.Name = "Accent"
	accent.BorderSizePixel = 0
	accent.Position = UDim2.new(1, -3, 0, 0)
	accent.Size = UDim2.new(0, 3, 1, 0)
	accent.Parent = background

	return {
		Name = name,
		Holder = holder,
		Background = background,
		Accent = accent,
		Text = createTextPair(holder),
		Width = 0,
		Height = 0,
		Removing = false,
		Tween = nil,
	}
end

local function rebuildOrder()
	table.clear(Ordered)
	for _, entry in Entries do
		table.insert(Ordered, entry)
	end

	if State.Sort == "Length" then
		table.sort(Ordered, function(a, b)
			if a.Width ~= b.Width then
				return a.Width > b.Width
			end
			return a.Name:lower() < b.Name:lower()
		end)
	else
		table.sort(Ordered, function(a, b)
			return a.Name:lower() < b.Name:lower()
		end)
	end

	for index, entry in Ordered do
		entry.Holder.LayoutOrder = index
	end
end

local function getListColor(index, total)
	if State.ColorMode == "RGB" then
		local offset = State.Gradient and (index - 1) * RGB_GRADIENT_STEP or 0
		return Color3.fromHSV((os.clock() * RGB_SPEED - offset) % 1, 0.8, 1)
	end

	local hue, sat, val = State.Color:ToHSV()
	if State.Gradient and total > 1 then
		hue = (hue - CUSTOM_GRADIENT_SHIFT * (index - 1) / (total - 1)) % 1
	end
	return Color3.fromHSV(hue, sat, val)
end

local function applyColors()
	local total = #Ordered

	for index, entry in Ordered do
		local color = getListColor(index, total)
		entry.Text.Label.TextColor3 = color
		entry.Accent.BackgroundColor3 = color
		entry.Background.BackgroundColor3 = State.Tint and color:Lerp(Color3.new(), 0.75) or BACKGROUND_COLOR
	end

	WatermarkPair.Label.TextColor3 = getListColor(1, math.max(total, 1))
	CustomTextPair.Label.TextColor3 = State.CustomTextColor
end

local function styleEntry(entry)
	local bounds = styleTextPair(entry.Text, entry.Name, resolveFont(State.FontName), TEXT_SIZE, State.Shadow)

	entry.Width = bounds.X + PADDING_X
	entry.Height = bounds.Y + PADDING_Y
	entry.Background.Visible = State.Background
	entry.Background.BackgroundTransparency = State.Transparency
	entry.Accent.Visible = State.Background
end

local function destroyEntry(entry)
	entry.Holder:Destroy()
	if Entries[entry.Name] == entry then
		Entries[entry.Name] = nil
	end

	rebuildOrder()
	applyColors()
end

local function applyEntrySize(entry, animate)
	if entry.Tween then
		entry.Tween:Cancel()
		entry.Tween = nil
	end

	local target = entry.Removing and UDim2.fromOffset(0, 0) or UDim2.fromOffset(entry.Width, entry.Height)

	if animate and State.Animations then
		local tween = TweenService:Create(entry.Holder, TWEEN_INFO, { Size = target })
		entry.Tween = tween

		tween.Completed:Connect(function(playbackState)
			if playbackState == Enum.PlaybackState.Completed and entry.Removing then
				destroyEntry(entry)
			end
		end)
		tween:Play()
	else
		entry.Holder.Size = target
		if entry.Removing then
			destroyEntry(entry)
		end
	end
end

--// Header (watermark + custom text)
local function updateHeader()
	local mainFont = resolveFont(State.FontName)

	WatermarkFrame.Visible = State.Watermark
	if State.Watermark then
		local bounds = styleTextPair(WatermarkPair, WATERMARK_TEXT, mainFont, WATERMARK_SIZE, State.Shadow)
		WatermarkFrame.Size = UDim2.fromOffset(bounds.X + PADDING_X, bounds.Y + 2)
	end

	local showCustom = State.CustomText and State.CustomTextValue ~= ""
	CustomTextFrame.Visible = showCustom
	if showCustom then
		local bounds = styleTextPair(
			CustomTextPair,
			State.CustomTextValue,
			resolveFont(State.CustomTextFontName),
			CUSTOM_TEXT_SIZE,
			State.Shadow
		)
		CustomTextFrame.Size = UDim2.fromOffset(bounds.X + PADDING_X, bounds.Y + 2)
	end
end

--// Full refresh (called whenever a setting changes)
local function refresh()
	if Destroyed then
		return
	end

	RootScale.Scale = State.Scale
	updateHeader()

	for _, entry in Entries do
		styleEntry(entry)
		applyEntrySize(entry, false)
	end

	rebuildOrder()
	applyColors()
end

HeartbeatConnection = RunService.Heartbeat:Connect(function()
	if State.ColorMode == "RGB" then
		applyColors()
	end
end)

--// Module list control
local function addModule(name)
	if Destroyed or type(name) ~= "string" or name == "" then
		return
	end

	local entry = Entries[name]
	if entry then
		if entry.Removing then
			entry.Removing = false
			applyEntrySize(entry, true)
		end
		return
	end

	entry = createEntry(name)
	Entries[name] = entry
	styleEntry(entry)
	rebuildOrder()
	applyColors()
	applyEntrySize(entry, true)
end

local function delModule(name)
	local entry = Entries[name]
	if Destroyed or not entry or entry.Removing then
		return
	end

	entry.Removing = true
	applyEntrySize(entry, true)
end

--// Setting handlers (used by the public API)
local function setSort(value)
	if type(value) ~= "string" then
		return
	end
	State.Sort = value:lower() == "length" and "Length" or "Alphabetical"
	refresh()
end

local function setFont(value)
	local fontName = canonicalFont(value)
	if not fontName then
		warn("[TextGUI] Unknown font: " .. tostring(value))
		return
	end
	State.FontName = fontName
	refresh()
end

local function setColorMode(value)
	if type(value) ~= "string" then
		return
	end
	State.ColorMode = value:lower():find("custom") and "Custom Color" or "RGB"
	refresh()
end

local function setColor(value)
	if typeof(value) ~= "Color3" then
		return
	end
	State.Color = value
	refresh()
end

local function setScale(value)
	value = tonumber(value)
	if not value then
		return
	end
	State.Scale = math.clamp(value, SCALE_MIN, SCALE_MAX)
	refresh()
end

local function setShadow(value)
	State.Shadow = not not value
	refresh()
end

local function setGradient(value)
	State.Gradient = not not value
	refresh()
end

local function setAnimations(value)
	State.Animations = not not value
end

local function setWatermark(value)
	State.Watermark = not not value
	refresh()
end

local function setBackground(value)
	State.Background = not not value
	refresh()
end

local function setTransparency(value)
	value = tonumber(value)
	if not value then
		return
	end
	State.Transparency = math.clamp(value, 0, 1)
	refresh()
end

local function setTint(value)
	State.Tint = not not value
	refresh()
end

local function setCustomText(value)
	State.CustomText = not not value
	refresh()
end

local function setCustomTextValue(value)
	State.CustomTextValue = tostring(value or "")
	refresh()
end

local function setCustomTextFont(value)
	local fontName = canonicalFont(value)
	if not fontName then
		warn("[TextGUI] Unknown font: " .. tostring(value))
		return
	end
	State.CustomTextFontName = fontName
	refresh()
end

local function setCustomTextColor(value)
	if typeof(value) ~= "Color3" then
		return
	end
	State.CustomTextColor = value
	refresh()
end

refresh()

--// Public API
local TextGUI = {}

-- Values for your own WindUI dropdowns
TextGUI.Fonts = FONT_LIST
TextGUI.SortModes = SORT_MODES
TextGUI.ColorModes = COLOR_MODES

function TextGUI.addModule(name)
	addModule(name)
end

function TextGUI.delModule(name)
	delModule(name)
end

function TextGUI.setSort(str)
	setSort(str)
end

function TextGUI.setFont(name)
	setFont(name)
end

function TextGUI.setColorModeType(type)
	setColorMode(type)
end

function TextGUI.setColor(color)
	setColor(color)
end

function TextGUI.setScale(num)
	setScale(num)
end

function TextGUI.setShadow(val)
	setShadow(val)
end

function TextGUI.setGradient(val)
	setGradient(val)
end

function TextGUI.useAnimations(val)
	setAnimations(val)
end

function TextGUI.useWatermark(val)
	setWatermark(val)
end

function TextGUI.renderBackground(val)
	setBackground(val)
end

function TextGUI.setTransparency(val)
	setTransparency(val)
end

function TextGUI.setTint(val)
	setTint(val)
end

function TextGUI.addCustomText(val)
	setCustomText(val)
end

function TextGUI.setCustomText(str)
	setCustomTextValue(str)
end

function TextGUI.setCustomTextFont(name)
	setCustomTextFont(name)
end

function TextGUI.setCustomTextColor(color)
	setCustomTextColor(color)
end

function TextGUI.destroy()
	Destroyed = true

	if HeartbeatConnection then
		HeartbeatConnection:Disconnect()
	end
	ScreenGui:Destroy()
	table.clear(Entries)
	table.clear(Ordered)

	if Env.EliteTextGUI == TextGUI then
		Env.EliteTextGUI = nil
	end
end

Env.EliteTextGUI = TextGUI

return TextGUI
