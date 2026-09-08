--[[
    Sense ESP - Multi-Color Rewrite

    Preserves the original ESP structure while adding:
      * Per-player color overrides.
      * Independent box / box-fill / box-outline colors.
      * Independent chams / chams-outline colors.
      * Independent nametag / nametag-outline colors.
      * A universal per-player color that can drive box, chams and nametag together.
      * Clear/set APIs intended for a second script loaded with loadstring().

    Public color API examples:

        ESP:SetPlayerColor(player, Color3.fromRGB(255, 0, 0))
        ESP:SetPlayerColor(otherPlayer, Color3.fromRGB(0, 170, 255))
        ESP:SetPlayerFeatureColor(player, "box", Color3.fromRGB(255, 255, 0))
        ESP:SetPlayerFeatureColor(player, "chams", Color3.fromRGB(255, 105, 180))
        ESP:SetPlayerFeatureColor(player, "name", Color3.fromRGB(255, 255, 255))
        ESP:ClearPlayerColor(player)
        ESP:ClearPlayerFeatureColor(player, "box")
]]

-- services
local runService = game:GetService("RunService")
local players = game:GetService("Players")
local workspace = game:GetService("Workspace")
local coreGui = game:GetService("CoreGui")

-- variables
local localPlayer = players.LocalPlayer
local camera = workspace.CurrentCamera
local viewportSize = camera and camera.ViewportSize or Vector2.new(0, 0)

local function getContainerParent()
    if type(gethui) == "function" then
        local hui = gethui()
        if hui then
            return hui
        end
    end

    return coreGui
end

local container = Instance.new("Folder")
container.Name = "SenseESP"
container.Parent = getContainerParent()

-- locals
local floor = math.floor
local round = math.round
local sin = math.sin
local cos = math.cos
local clear = table.clear
local unpack = table.unpack
local find = table.find
local create = table.create
local fromMatrix = CFrame.fromMatrix
local min2 = Vector2.zero.Min
local max2 = Vector2.zero.Max
local lerp2 = Vector2.zero.Lerp
local min3 = Vector3.zero.Min
local max3 = Vector3.zero.Max
local lerpColor = Color3.new().Lerp
local findFirstChild = workspace.FindFirstChild
local findFirstChildOfClass = workspace.FindFirstChildOfClass
local getChildren = workspace.GetChildren
local getPivot = workspace.GetPivot

-- constants
local HEALTH_BAR_OFFSET = Vector2.new(5, 0)
local HEALTH_TEXT_OFFSET = Vector2.new(3, 0)
local HEALTH_BAR_OUTLINE_OFFSET = Vector2.new(0, 1)
local NAME_OFFSET = Vector2.new(0, 2)
local DISTANCE_OFFSET = Vector2.new(0, 2)
local ZERO_VECTOR_2 = Vector2.zero
local ONE_VECTOR_2 = Vector2.one
local DEFAULT_COLOR = Color3.new(1, 1, 1)
local BLACK_COLOR = Color3.new(0, 0, 0)
local FEATURE_ALIASES = {
    box = "box",
    boxfill = "boxFill",
    boxoutline = "boxOutline",
    box3d = "box3d",
    chams = "chams",
    chamsfill = "chams",
    chamsoutline = "chamsOutline",
    name = "name",
    nametag = "name",
    nameoutline = "nameOutline",
    nametagoutline = "nameOutline",
    healthtext = "healthText",
    healthtextoutline = "healthTextOutline",
    healthbaroutline = "healthBarOutline",
    tracer = "tracer",
    traceroutline = "tracerOutline",
    offscreenarrow = "offScreenArrow",
    offscreenarrowoutline = "offScreenArrowOutline",
    distance = "distance",
    distanceoutline = "distanceOutline",
    weapon = "weapon",
    weaponoutline = "weaponOutline"
}

local VERTICES = {
    Vector3.new(-1, -1, -1),
    Vector3.new(-1, 1, -1),
    Vector3.new(-1, 1, 1),
    Vector3.new(-1, -1, 1),
    Vector3.new(1, -1, -1),
    Vector3.new(1, 1, -1),
    Vector3.new(1, 1, 1),
    Vector3.new(1, -1, 1)
}

-- forward declarations
local EspInterface

-- helpers
local function refreshCamera()
    local currentCamera = workspace.CurrentCamera
    if currentCamera and currentCamera ~= camera then
        camera = currentCamera
    end

    if camera then
        viewportSize = camera.ViewportSize
    else
        viewportSize = ZERO_VECTOR_2
    end
end

local function isBodyPart(name)
    return name == "Head"
        or string.find(name, "Torso") ~= nil
        or string.find(name, "Leg") ~= nil
        or string.find(name, "Arm") ~= nil
end

local function getBoundingBox(parts)
    if #parts == 0 then
        return nil, nil
    end

    local minimum
    local maximum

    for i = 1, #parts do
        local part = parts[i]
        if part and part.Parent then
            local cframe = part.CFrame
            local size = part.Size

            minimum = min3(minimum or cframe.Position, (cframe - size * 0.5).Position)
            maximum = max3(maximum or cframe.Position, (cframe + size * 0.5).Position)
        end
    end

    if not minimum or not maximum then
        return nil, nil
    end

    local center = (minimum + maximum) * 0.5
    local front = Vector3.new(center.X, center.Y, maximum.Z)

    return CFrame.new(center, front), maximum - minimum
end

local function worldToScreen(world)
    if not camera then
        return ZERO_VECTOR_2, false, math.huge
    end

    local screen, inBounds = camera:WorldToViewportPoint(world)
    return Vector2.new(screen.X, screen.Y), inBounds, screen.Z
end

local function calculateCorners(cframe, size)
    local corners = create(#VERTICES)

    for i = 1, #VERTICES do
        corners[i] = worldToScreen((cframe + size * 0.5 * VERTICES[i]).Position)
    end

    local minimum = min2(viewportSize, unpack(corners))
    local maximum = max2(ZERO_VECTOR_2, unpack(corners))

    return {
        corners = corners,
        topLeft = Vector2.new(floor(minimum.X), floor(minimum.Y)),
        topRight = Vector2.new(floor(maximum.X), floor(minimum.Y)),
        bottomLeft = Vector2.new(floor(minimum.X), floor(maximum.Y)),
        bottomRight = Vector2.new(floor(maximum.X), floor(maximum.Y))
    }
end

local function rotateVector(vector, radians)
    local x, y = vector.X, vector.Y
    local c, s = cos(radians), sin(radians)
    return Vector2.new(x * c - y * s, x * s + y * c)
end

local function normalizePlayerId(playerOrUserId)
    if typeof(playerOrUserId) == "Instance" and playerOrUserId:IsA("Player") then
        return playerOrUserId.UserId
    end

    if type(playerOrUserId) == "number" then
        return playerOrUserId
    end

    return nil
end

local function resolvePlayer(playerOrUserId)
    if typeof(playerOrUserId) == "Instance" and playerOrUserId:IsA("Player") then
        return playerOrUserId
    end

    if type(playerOrUserId) == "number" then
        return players:GetPlayerByUserId(playerOrUserId)
    end

    return nil
end

local function sanitizeColor(color)
    return typeof(color) == "Color3" and color or nil
end

local function normalizeFeature(feature)
    if type(feature) ~= "string" then
        return nil
    end

    return FEATURE_ALIASES[string.lower(feature)]
end

local function getOverrideColor(player, feature)
    local interface = EspInterface
    if not interface then
        return nil
    end

    local userId = normalizePlayerId(player)
    if not userId then
        return nil
    end

    local override = interface.playerColors[userId]
    if not override then
        return nil
    end

    if feature and override[feature] ~= nil then
        return override[feature]
    end

    return override.color
end

local function parseColor(self, feature, color, isOutline)
    local overrideColor = getOverrideColor(self.player, feature)
    if overrideColor then
        return overrideColor
    end

    if color == "Team Color" or (self.interface.sharedSettings.useTeamColor and not isOutline) then
        return self.interface.getTeamColor(self.player) or DEFAULT_COLOR
    end

    return color
end

local function getHealthFraction(health, maxHealth)
    local numericHealth = tonumber(health) or 0
    local numericMaxHealth = tonumber(maxHealth) or 0

    if numericMaxHealth <= 0 then
        return 0
    end

    return math.clamp(numericHealth / numericMaxHealth, 0, 1)
end

-- esp object
local EspObject = {}
EspObject.__index = EspObject

function EspObject.new(player, interface)
    local self = setmetatable({}, EspObject)
    self.player = assert(player, "Missing argument #1 (Player expected)")
    self.interface = assert(interface, "Missing argument #2 (table expected)")
    self:Construct()
    return self
end

function EspObject:_create(class, properties)
    local drawing = Drawing.new(class)

    for property, value in next, properties do
        pcall(function()
            drawing[property] = value
        end)
    end

    self.bin[#self.bin + 1] = drawing
    return drawing
end

function EspObject:Construct()
    self.charCache = {}
    self.childCount = 0
    self.bin = {}
    self.options = self.interface.teamSettings.enemy
    self.health = 100
    self.maxHealth = 100
    self.weapon = "Unknown"
    self.enabled = false
    self.onScreen = false
    self.distance = 0
    self.direction = nil
    self.corners = nil

    self.drawings = {
        box3d = {
            {
                self:_create("Line", { Thickness = 1, Visible = false }),
                self:_create("Line", { Thickness = 1, Visible = false }),
                self:_create("Line", { Thickness = 1, Visible = false })
            },
            {
                self:_create("Line", { Thickness = 1, Visible = false }),
                self:_create("Line", { Thickness = 1, Visible = false }),
                self:_create("Line", { Thickness = 1, Visible = false })
            },
            {
                self:_create("Line", { Thickness = 1, Visible = false }),
                self:_create("Line", { Thickness = 1, Visible = false }),
                self:_create("Line", { Thickness = 1, Visible = false })
            },
            {
                self:_create("Line", { Thickness = 1, Visible = false }),
                self:_create("Line", { Thickness = 1, Visible = false }),
                self:_create("Line", { Thickness = 1, Visible = false })
            }
        },
        visible = {
            tracerOutline = self:_create("Line", { Thickness = 3, Visible = false }),
            tracer = self:_create("Line", { Thickness = 1, Visible = false }),
            boxFill = self:_create("Square", { Filled = true, Visible = false }),
            boxOutline = self:_create("Square", { Thickness = 3, Visible = false }),
            box = self:_create("Square", { Thickness = 1, Visible = false }),
            healthBarOutline = self:_create("Line", { Thickness = 3, Visible = false }),
            healthBar = self:_create("Line", { Thickness = 1, Visible = false }),
            healthText = self:_create("Text", { Center = true, Visible = false }),
            name = self:_create("Text", { Text = self.player.DisplayName, Center = true, Visible = false }),
            distance = self:_create("Text", { Center = true, Visible = false }),
            weapon = self:_create("Text", { Center = true, Visible = false })
        },
        hidden = {
            arrowOutline = self:_create("Triangle", { Thickness = 3, Visible = false }),
            arrow = self:_create("Triangle", { Filled = true, Visible = false })
        }
    }

    self.renderConnection = runService.Heartbeat:Connect(function(deltaTime)
        self:Update(deltaTime)
        self:Render(deltaTime)
    end)
end

function EspObject:HideAll()
    for _, drawing in next, self.bin do
        pcall(function()
            drawing.Visible = false
        end)
    end
end

function EspObject:Destruct()
    if self.renderConnection then
        self.renderConnection:Disconnect()
        self.renderConnection = nil
    end

    for i = 1, #self.bin do
        local drawing = self.bin[i]
        if drawing then
            pcall(function()
                drawing:Remove()
            end)
        end
    end

    self.bin = {}
    self.drawings = nil
    self.charCache = {}
end

function EspObject:Update()
    refreshCamera()

    local interface = self.interface
    local isFriendly = interface.isFriendly(self.player)
    self.options = interface.teamSettings[isFriendly and "friendly" or "enemy"]
    self.character = interface.getCharacter(self.player)
    self.health, self.maxHealth = interface.getHealth(self.player)
    self.weapon = interface.getWeapon(self.player)

    local whitelisted = #interface.whitelist > 0 and find(interface.whitelist, self.player.UserId) ~= nil
    self.enabled = self.options.enabled == true and self.character ~= nil and not whitelisted
    self.onScreen = false
    self.corners = nil

    local head = self.enabled and findFirstChild(self.character, "Head")
    if not head then
        self.charCache = {}
        self.childCount = 0
        self.direction = nil
        return
    end

    local _, onScreen, depth = worldToScreen(head.Position)
    self.onScreen = onScreen and depth > 0
    self.distance = depth

    if interface.sharedSettings.limitDistance and depth > interface.sharedSettings.maxDistance then
        self.onScreen = false
    end

    if self.onScreen then
        local cache = self.charCache
        local children = getChildren(self.character)

        if not cache[1] or self.childCount ~= #children then
            clear(cache)

            for i = 1, #children do
                local part = children[i]
                if part:IsA("BasePart") and isBodyPart(part.Name) then
                    cache[#cache + 1] = part
                end
            end

            self.childCount = #children
        end

        local boundingCFrame, boundingSize = getBoundingBox(cache)
        if boundingCFrame and boundingSize then
            self.corners = calculateCorners(boundingCFrame, boundingSize)
        else
            self.onScreen = false
        end
    elseif self.options.offScreenArrow then
        if camera then
            local cframe = camera.CFrame
            local flat = fromMatrix(cframe.Position, cframe.RightVector, Vector3.yAxis)
            local objectSpace = flat:PointToObjectSpace(head.Position)
            local direction = Vector2.new(objectSpace.X, objectSpace.Z)

            if direction.Magnitude > 0 then
                self.direction = direction.Unit
            else
                self.direction = nil
            end
        end
    else
        self.direction = nil
    end
end

function EspObject:Render()
    local interface = self.interface
    local options = self.options or interface.teamSettings.enemy
    local onScreen = self.onScreen == true
    local enabled = self.enabled == true
    local visible = self.drawings.visible
    local hidden = self.drawings.hidden
    local box3d = self.drawings.box3d
    local corners = self.corners

    if not enabled then
        self:HideAll()
        return
    end

    -- Clear every drawable that depends on the 2D projection first.
    -- This also prevents stale geometry while a player moves off-screen.
    visible.box.Visible = false
    visible.boxOutline.Visible = false
    visible.boxFill.Visible = false
    visible.healthBar.Visible = false
    visible.healthBarOutline.Visible = false
    visible.healthText.Visible = false
    visible.name.Visible = false
    visible.distance.Visible = false
    visible.weapon.Visible = false
    visible.tracer.Visible = false
    visible.tracerOutline.Visible = false

    -- standard 2D box
        if onScreen and corners then
            visible.box.Visible = options.box == true
        visible.boxOutline.Visible = visible.box.Visible and options.boxOutline == true

        if visible.box.Visible then
            local box = visible.box
            box.Position = corners.topLeft
            box.Size = corners.bottomRight - corners.topLeft
            box.Color = parseColor(self, "box", options.boxColor[1])
            box.Transparency = options.boxColor[2]

            local boxOutline = visible.boxOutline
            boxOutline.Position = box.Position
            boxOutline.Size = box.Size
            boxOutline.Color = parseColor(self, "boxOutline", options.boxOutlineColor[1], true)
            boxOutline.Transparency = options.boxOutlineColor[2]
        end

        -- box fill
        visible.boxFill.Visible = onScreen and options.boxFill == true
        if visible.boxFill.Visible then
            local boxFill = visible.boxFill
            boxFill.Position = corners.topLeft
            boxFill.Size = corners.bottomRight - corners.topLeft
            boxFill.Color = parseColor(self, "boxFill", options.boxFillColor[1])
            boxFill.Transparency = options.boxFillColor[2]
        end

        -- health bar
        visible.healthBar.Visible = onScreen and options.healthBar == true
        visible.healthBarOutline.Visible = visible.healthBar.Visible and options.healthBarOutline == true

        if visible.healthBar.Visible then
            local barFrom = corners.topLeft - HEALTH_BAR_OFFSET
            local barTo = corners.bottomLeft - HEALTH_BAR_OFFSET
            local healthFraction = getHealthFraction(self.health, self.maxHealth)

            local healthBar = visible.healthBar
            healthBar.To = barTo
            healthBar.From = lerp2(barTo, barFrom, healthFraction)
            healthBar.Color = lerpColor(options.dyingColor, options.healthyColor, healthFraction)

            local healthBarOutline = visible.healthBarOutline
            healthBarOutline.To = barTo + HEALTH_BAR_OUTLINE_OFFSET
            healthBarOutline.From = barFrom - HEALTH_BAR_OUTLINE_OFFSET
            healthBarOutline.Color = parseColor(self, "healthBarOutline", options.healthBarOutlineColor[1], true)
            healthBarOutline.Transparency = options.healthBarOutlineColor[2]
        end

        -- health text
        visible.healthText.Visible = onScreen and options.healthText == true
        if visible.healthText.Visible then
            local barFrom = corners.topLeft - HEALTH_BAR_OFFSET
            local barTo = corners.bottomLeft - HEALTH_BAR_OFFSET
            local healthFraction = getHealthFraction(self.health, self.maxHealth)

            local healthText = visible.healthText
            healthText.Text = round(self.health) .. "hp"
            healthText.Size = interface.sharedSettings.textSize
            healthText.Font = interface.sharedSettings.textFont
            healthText.Color = parseColor(self, "healthText", options.healthTextColor[1])
            healthText.Transparency = options.healthTextColor[2]
            healthText.Outline = options.healthTextOutline
            healthText.OutlineColor = parseColor(self, "healthTextOutline", options.healthTextOutlineColor, true)
            healthText.Position = lerp2(barTo, barFrom, healthFraction) - healthText.TextBounds * 0.5 - HEALTH_TEXT_OFFSET
        end

        -- nametag
        visible.name.Visible = onScreen and options.name == true
        if visible.name.Visible then
            local name = visible.name
            name.Text = self.player.DisplayName
            name.Size = interface.sharedSettings.textSize
            name.Font = interface.sharedSettings.textFont
            name.Color = parseColor(self, "name", options.nameColor[1])
            name.Transparency = options.nameColor[2]
            name.Outline = options.nameOutline
            name.OutlineColor = parseColor(self, "nameOutline", options.nameOutlineColor, true)
            name.Position = (corners.topLeft + corners.topRight) * 0.5 - Vector2.yAxis * name.TextBounds.Y - NAME_OFFSET
        end

        -- distance
        visible.distance.Visible = onScreen and self.distance > 0 and options.distance == true
        if visible.distance.Visible then
            local distance = visible.distance
            distance.Text = round(self.distance) .. " studs"
            distance.Size = interface.sharedSettings.textSize
            distance.Font = interface.sharedSettings.textFont
            distance.Color = parseColor(self, "distance", options.distanceColor[1])
            distance.Transparency = options.distanceColor[2]
            distance.Outline = options.distanceOutline
            distance.OutlineColor = parseColor(self, "distanceOutline", options.distanceOutlineColor, true)
            distance.Position = (corners.bottomLeft + corners.bottomRight) * 0.5 + DISTANCE_OFFSET
        end

        -- weapon
        visible.weapon.Visible = onScreen and options.weapon == true
        if visible.weapon.Visible then
            local weapon = visible.weapon
            weapon.Text = tostring(self.weapon or "Unknown")
            weapon.Size = interface.sharedSettings.textSize
            weapon.Font = interface.sharedSettings.textFont
            weapon.Color = parseColor(self, "weapon", options.weaponColor[1])
            weapon.Transparency = options.weaponColor[2]
            weapon.Outline = options.weaponOutline
            weapon.OutlineColor = parseColor(self, "weaponOutline", options.weaponOutlineColor, true)
            weapon.Position =
                (corners.bottomLeft + corners.bottomRight) * 0.5 +
                (visible.distance.Visible and DISTANCE_OFFSET + Vector2.yAxis * visible.distance.TextBounds.Y or ZERO_VECTOR_2)
        end

        -- tracer
        visible.tracer.Visible = onScreen and options.tracer == true
        visible.tracerOutline.Visible = visible.tracer.Visible and options.tracerOutline == true

        if visible.tracer.Visible then
            local tracer = visible.tracer
            tracer.Color = parseColor(self, "tracer", options.tracerColor[1])
            tracer.Transparency = options.tracerColor[2]
            tracer.To = (corners.bottomLeft + corners.bottomRight) * 0.5
            tracer.From =
                options.tracerOrigin == "Middle" and viewportSize * 0.5 or
                options.tracerOrigin == "Top" and viewportSize * Vector2.new(0.5, 0) or
                options.tracerOrigin == "Bottom" and viewportSize * Vector2.new(0.5, 1) or
                viewportSize * 0.5

            local tracerOutline = visible.tracerOutline
            tracerOutline.Color = parseColor(self, "tracerOutline", options.tracerOutlineColor[1], true)
            tracerOutline.Transparency = options.tracerOutlineColor[2]
            tracerOutline.To = tracer.To
            tracerOutline.From = tracer.From
        end

    end

    -- off-screen arrow
    hidden.arrow.Visible = enabled and (not onScreen) and options.offScreenArrow == true and self.direction ~= nil
    hidden.arrowOutline.Visible = hidden.arrow.Visible and options.offScreenArrowOutline == true

    if hidden.arrow.Visible then
        local arrow = hidden.arrow
        arrow.PointA = min2(max2(viewportSize * 0.5 + self.direction * options.offScreenArrowRadius, ONE_VECTOR_2 * 25), viewportSize - ONE_VECTOR_2 * 25)
        arrow.PointB = arrow.PointA - rotateVector(self.direction, 0.45) * options.offScreenArrowSize
        arrow.PointC = arrow.PointA - rotateVector(self.direction, -0.45) * options.offScreenArrowSize
        arrow.Color = parseColor(self, "offScreenArrow", options.offScreenArrowColor[1])
        arrow.Transparency = options.offScreenArrowColor[2]

        local arrowOutline = hidden.arrowOutline
        arrowOutline.PointA = arrow.PointA
        arrowOutline.PointB = arrow.PointB
        arrowOutline.PointC = arrow.PointC
        arrowOutline.Color = parseColor(self, "offScreenArrowOutline", options.offScreenArrowOutlineColor[1], true)
        arrowOutline.Transparency = options.offScreenArrowOutlineColor[2]
    end

    -- 3D box
    local box3dEnabled = enabled and onScreen and options.box3d == true
    for i = 1, #box3d do
        local face = box3d[i]
        for i2 = 1, #face do
            local line = face[i2]
            line.Visible = box3dEnabled
            line.Color = parseColor(self, "box3d", options.box3dColor[1])
            line.Transparency = options.box3dColor[2]
        end

        if box3dEnabled then
            local line1 = face[1]
            line1.From = corners.corners[i]
            line1.To = corners.corners[i == 4 and 1 or i + 1]

            local line2 = face[2]
            line2.From = corners.corners[i == 4 and 1 or i + 1]
            line2.To = corners.corners[i == 4 and 5 or i + 5]

            local line3 = face[3]
            line3.From = corners.corners[i == 4 and 5 or i + 5]
            line3.To = corners.corners[i == 4 and 8 or i + 4]
        end
    end
end

-- cham object
local ChamObject = {}
ChamObject.__index = ChamObject

function ChamObject.new(player, interface)
    local self = setmetatable({}, ChamObject)
    self.player = assert(player, "Missing argument #1 (Player expected)")
    self.interface = assert(interface, "Missing argument #2 (table expected)")
    self:Construct()
    return self
end

function ChamObject:Construct()
    self.highlight = Instance.new("Highlight")
    self.highlight.Name = "SenseCham_" .. tostring(self.player.UserId)
    self.highlight.Enabled = false
    self.highlight.Parent = container

    self.updateConnection = runService.Heartbeat:Connect(function()
        self:Update()
    end)
end

function ChamObject:Destruct()
    if self.updateConnection then
        self.updateConnection:Disconnect()
        self.updateConnection = nil
    end

    if self.highlight then
        self.highlight:Destroy()
        self.highlight = nil
    end
end

function ChamObject:Update()
    local highlight = self.highlight
    if not highlight then
        return
    end

    local interface = self.interface
    local isFriendly = interface.isFriendly(self.player)
    local options = interface.teamSettings[isFriendly and "friendly" or "enemy"]
    local character = interface.getCharacter(self.player)
    local whitelisted = #interface.whitelist > 0 and find(interface.whitelist, self.player.UserId) ~= nil
    local enabled = options.enabled == true and character ~= nil and not whitelisted

    highlight.Enabled = enabled and options.chams == true
    if not highlight.Enabled then
        highlight.Adornee = nil
        return
    end

    highlight.Adornee = character
    highlight.FillColor = parseColor(self, "chams", options.chamsFillColor[1])
    highlight.FillTransparency = options.chamsFillColor[2]
    highlight.OutlineColor = parseColor(self, "chamsOutline", options.chamsOutlineColor[1], true)
    highlight.OutlineTransparency = options.chamsOutlineColor[2]
    highlight.DepthMode = options.chamsVisibleOnly and Enum.HighlightDepthMode.Occluded or Enum.HighlightDepthMode.AlwaysOnTop
end

-- instance class
local InstanceObject = {}
InstanceObject.__index = InstanceObject

function InstanceObject.new(instance, options)
    local self = setmetatable({}, InstanceObject)
    self.instance = assert(instance, "Missing argument #1 (Instance expected)")
    self.options = assert(options, "Missing argument #2 (table expected)")
    self:Construct()
    return self
end

function InstanceObject:Construct()
    local options = self.options

    options.enabled = options.enabled == nil and true or options.enabled
    options.text = options.text or "{name}"
    options.textColor = options.textColor or { DEFAULT_COLOR, 1 }
    options.textOutline = options.textOutline == nil and true or options.textOutline
    options.textOutlineColor = options.textOutlineColor or BLACK_COLOR
    options.textSize = options.textSize or 13
    options.textFont = options.textFont or 2
    options.limitDistance = options.limitDistance == nil and false or options.limitDistance
    options.maxDistance = options.maxDistance or 150

    self.text = Drawing.new("Text")
    self.text.Center = true
    self.text.Visible = false

    self.renderConnection = runService.Heartbeat:Connect(function(deltaTime)
        self:Render(deltaTime)
    end)
end

function InstanceObject:Destruct()
    if self.renderConnection then
        self.renderConnection:Disconnect()
        self.renderConnection = nil
    end

    if self.text then
        pcall(function()
            self.text:Remove()
        end)
        self.text = nil
    end
end

function InstanceObject:Render()
    local instance = self.instance
    if not instance or not instance.Parent then
        self:Destruct()
        return
    end

    local text = self.text
    local options = self.options
    if not text then
        return
    end

    if not options.enabled then
        text.Visible = false
        return
    end

    refreshCamera()

    local pivot = getPivot(instance)
    local world = pivot.Position
    local position, visible, depth = worldToScreen(world)

    if options.limitDistance and depth > options.maxDistance then
        visible = false
    end

    text.Visible = visible and depth > 0
    if text.Visible then
        text.Position = position
        text.Color = options.textColor[1]
        text.Transparency = options.textColor[2]
        text.Outline = options.textOutline
        text.OutlineColor = options.textOutlineColor
        text.Size = options.textSize
        text.Font = options.textFont
        text.Text = options.text
            :gsub("{name}", instance.Name)
            :gsub("{distance}", tostring(round(depth)))
            :gsub("{position}", tostring(world))
    end
end

-- interface
EspInterface = {
    _hasLoaded = false,
    _objectCache = {},
    _instanceCache = {},
    playerColors = {},
    whitelist = {},

    sharedSettings = {
        textSize = 13,
        textFont = 2,
        limitDistance = false,
        maxDistance = 150,
        useTeamColor = false
    },

    teamSettings = {
        enemy = {
            enabled = false,
            box = false,
            boxColor = { Color3.new(1, 0, 0), 1 },
            boxOutline = true,
            boxOutlineColor = { BLACK_COLOR, 1 },
            boxFill = false,
            boxFillColor = { Color3.new(1, 0, 0), 0.5 },
            healthBar = false,
            healthyColor = Color3.new(0, 1, 0),
            dyingColor = Color3.new(1, 0, 0),
            healthBarOutline = true,
            healthBarOutlineColor = { BLACK_COLOR, 0.5 },
            healthText = false,
            healthTextColor = { DEFAULT_COLOR, 1 },
            healthTextOutline = true,
            healthTextOutlineColor = BLACK_COLOR,
            box3d = false,
            box3dColor = { Color3.new(1, 0, 0), 1 },
            name = false,
            nameColor = { DEFAULT_COLOR, 1 },
            nameOutline = true,
            nameOutlineColor = BLACK_COLOR,
            weapon = false,
            weaponColor = { DEFAULT_COLOR, 1 },
            weaponOutline = true,
            weaponOutlineColor = BLACK_COLOR,
            distance = false,
            distanceColor = { DEFAULT_COLOR, 1 },
            distanceOutline = true,
            distanceOutlineColor = BLACK_COLOR,
            tracer = false,
            tracerOrigin = "Bottom",
            tracerColor = { Color3.new(1, 0, 0), 1 },
            tracerOutline = true,
            tracerOutlineColor = { BLACK_COLOR, 1 },
            offScreenArrow = false,
            offScreenArrowColor = { DEFAULT_COLOR, 1 },
            offScreenArrowSize = 15,
            offScreenArrowRadius = 150,
            offScreenArrowOutline = true,
            offScreenArrowOutlineColor = { BLACK_COLOR, 1 },
            chams = false,
            chamsVisibleOnly = false,
            chamsFillColor = { Color3.new(0.2, 0.2, 0.2), 0.5 },
            chamsOutlineColor = { Color3.new(1, 0, 0), 0 }
        },

        friendly = {
            enabled = false,
            box = false,
            boxColor = { Color3.new(0, 1, 0), 1 },
            boxOutline = true,
            boxOutlineColor = { BLACK_COLOR, 1 },
            boxFill = false,
            boxFillColor = { Color3.new(0, 1, 0), 0.5 },
            healthBar = false,
            healthyColor = Color3.new(0, 1, 0),
            dyingColor = Color3.new(1, 0, 0),
            healthBarOutline = true,
            healthBarOutlineColor = { BLACK_COLOR, 0.5 },
            healthText = false,
            healthTextColor = { DEFAULT_COLOR, 1 },
            healthTextOutline = true,
            healthTextOutlineColor = BLACK_COLOR,
            box3d = false,
            box3dColor = { Color3.new(0, 1, 0), 1 },
            name = false,
            nameColor = { DEFAULT_COLOR, 1 },
            nameOutline = true,
            nameOutlineColor = BLACK_COLOR,
            weapon = false,
            weaponColor = { DEFAULT_COLOR, 1 },
            weaponOutline = true,
            weaponOutlineColor = BLACK_COLOR,
            distance = false,
            distanceColor = { DEFAULT_COLOR, 1 },
            distanceOutline = true,
            distanceOutlineColor = BLACK_COLOR,
            tracer = false,
            tracerOrigin = "Bottom",
            tracerColor = { Color3.new(0, 1, 0), 1 },
            tracerOutline = true,
            tracerOutlineColor = { BLACK_COLOR, 1 },
            offScreenArrow = false,
            offScreenArrowColor = { DEFAULT_COLOR, 1 },
            offScreenArrowSize = 15,
            offScreenArrowRadius = 150,
            offScreenArrowOutline = true,
            offScreenArrowOutlineColor = { BLACK_COLOR, 1 },
            chams = false,
            chamsVisibleOnly = false,
            chamsFillColor = { Color3.new(0.2, 0.2, 0.2), 0.5 },
            chamsOutlineColor = { Color3.new(0, 1, 0), 0 }
        }
    }
}

--
-- Multi-color API
--

function EspInterface:_getColorEntry(playerOrUserId, createEntry)
    local userId = normalizePlayerId(playerOrUserId)
    if not userId then
        return nil, nil
    end

    local entry = self.playerColors[userId]
    if not entry and createEntry then
        entry = {}
        self.playerColors[userId] = entry
    end

    return entry, userId
end

function EspInterface:SetPlayerColor(playerOrUserId, color)
    color = sanitizeColor(color)
    assert(color, "SetPlayerColor: color must be a Color3")

    local entry = self:_getColorEntry(playerOrUserId, true)
    assert(entry, "SetPlayerColor: player must be a Player or UserId")

    entry.color = color
    return color
end

function EspInterface:SetPlayerColors(playerColors)
    assert(type(playerColors) == "table", "SetPlayerColors: playerColors must be a table")

    for playerOrUserId, color in next, playerColors do
        self:SetPlayerColor(playerOrUserId, color)
    end
end

function EspInterface:SetPlayerFeatureColor(playerOrUserId, feature, color)
    color = sanitizeColor(color)
    assert(color, "SetPlayerFeatureColor: color must be a Color3")
    assert(type(feature) == "string", "SetPlayerFeatureColor: feature must be a string")

    local key = normalizeFeature(feature)
    assert(key, "SetPlayerFeatureColor: unsupported feature '" .. feature .. "'")

    local entry = self:_getColorEntry(playerOrUserId, true)
    assert(entry, "SetPlayerFeatureColor: player must be a Player or UserId")

    entry[key] = color
    return color
end

function EspInterface:SetPlayerBoxColor(playerOrUserId, color)
    return self:SetPlayerFeatureColor(playerOrUserId, "box", color)
end

function EspInterface:SetPlayerChamsColor(playerOrUserId, color)
    return self:SetPlayerFeatureColor(playerOrUserId, "chams", color)
end

function EspInterface:SetPlayerNameColor(playerOrUserId, color)
    return self:SetPlayerFeatureColor(playerOrUserId, "name", color)
end

function EspInterface:GetPlayerColor(playerOrUserId, feature)
    local entry = self:_getColorEntry(playerOrUserId, false)
    if not entry then
        return nil
    end

    local key = feature and normalizeFeature(feature) or nil
    if key and entry[key] ~= nil then
        return entry[key]
    end

    if not feature or not key then
        return entry.color
    end

    return nil
end

function EspInterface:ClearPlayerColor(playerOrUserId)
    local _, userId = self:_getColorEntry(playerOrUserId, false)
    if userId then
        self.playerColors[userId] = nil
    end
end

function EspInterface:ClearPlayerFeatureColor(playerOrUserId, feature)
    local entry, userId = self:_getColorEntry(playerOrUserId, false)
    if not entry then
        return
    end

    assert(type(feature) == "string", "ClearPlayerFeatureColor: feature must be a string")

    local key = normalizeFeature(feature)
    assert(key, "ClearPlayerFeatureColor: unsupported feature '" .. feature .. "'")

    entry[key] = nil

    if not entry.color and next(entry) == nil then
        self.playerColors[userId] = nil
    end
end

-- object helpers
function EspInterface:GetPlayerObject(playerOrUserId)
    local player = resolvePlayer(playerOrUserId)
    if not player then
        return nil
    end

    local object = self._objectCache[player]
    return object and object[1] or nil
end

function EspInterface:GetPlayerChamObject(playerOrUserId)
    local player = resolvePlayer(playerOrUserId)
    if not player then
        return nil
    end

    local object = self._objectCache[player]
    return object and object[2] or nil
end

function EspInterface.AddInstance(instance, options)
    assert(instance, "AddInstance: missing instance")
    assert(options, "AddInstance: missing options")

    local cache = EspInterface._instanceCache
    if cache[instance] then
        warn("Instance handler already exists.")
        return cache[instance][1]
    end

    cache[instance] = { InstanceObject.new(instance, options) }
    return cache[instance][1]
end

function EspInterface.RemoveInstance(instance)
    local object = EspInterface._instanceCache[instance]
    if not object then
        return false
    end

    for i = 1, #object do
        object[i]:Destruct()
    end

    EspInterface._instanceCache[instance] = nil
    return true
end

function EspInterface.Load()
    assert(not EspInterface._hasLoaded, "Esp has already been loaded.")

    local interface = EspInterface
    refreshCamera()

    local function createObject(player)
        if player == localPlayer or interface._objectCache[player] then
            return
        end

        interface._objectCache[player] = {
            EspObject.new(player, interface),
            ChamObject.new(player, interface)
        }
    end

    local function removeObject(player)
        local object = interface._objectCache[player]
        if not object then
            return
        end

        for i = 1, #object do
            if object[i] then
                object[i]:Destruct()
            end
        end

        interface._objectCache[player] = nil
    end

    local playerList = players:GetPlayers()
    for i = 1, #playerList do
        createObject(playerList[i])
    end

    interface.playerAdded = players.PlayerAdded:Connect(createObject)
    interface.playerRemoving = players.PlayerRemoving:Connect(function(player)
        removeObject(player)
        interface.playerColors[player.UserId] = nil
    end)

    interface._hasLoaded = true
    return interface
end

function EspInterface.Unload()
    assert(EspInterface._hasLoaded, "Esp has not been loaded yet.")

    local interface = EspInterface

    for player, object in next, interface._objectCache do
        for i = 1, #object do
            if object[i] then
                object[i]:Destruct()
            end
        end

        interface._objectCache[player] = nil
    end

    for instance, object in next, interface._instanceCache do
        for i = 1, #object do
            if object[i] then
                object[i]:Destruct()
            end
        end

        interface._instanceCache[instance] = nil
    end

    if interface.playerAdded then
        interface.playerAdded:Disconnect()
        interface.playerAdded = nil
    end

    if interface.playerRemoving then
        interface.playerRemoving:Disconnect()
        interface.playerRemoving = nil
    end

    clear(interface.playerColors)
    interface._hasLoaded = false
end

-- game-specific functions
function EspInterface.getWeapon(player)
    return "Unknown"
end

function EspInterface.isFriendly(player)
    return player.Team ~= nil and player.Team == localPlayer.Team
end

function EspInterface.getTeamColor(player)
    return player.Team and player.Team.TeamColor and player.Team.TeamColor.Color
end

function EspInterface.getCharacter(player)
    return player.Character
end

function EspInterface.getHealth(player)
    local character = player and EspInterface.getCharacter(player)
    local humanoid = character and findFirstChildOfClass(character, "Humanoid")

    if humanoid then
        return humanoid.Health, humanoid.MaxHealth
    end

    return 100, 100
end

return EspInterface
