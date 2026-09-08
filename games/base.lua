local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character
local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
local HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")

local Workspace = game:GetService("Workspace")
local camera = Workspace.CurrentCamera or Workspace:FindFirstChildWhichIsA("Camera")
local Terrain = Workspace:FindFirstChildWhichIsA("Terrain")

-- functions
local run = function(func)
	local success, err = pcall(func)
	if not success then
		warn("Run error: " .. tostring(err))
	end
end

local function getCharacterData()
	if not Character then
		return nil
	end

	if Humanoid and Humanoid.Health > 0 and HumanoidRootPart then
		return Humanoid, HumanoidRootPart
	end
	return nil
end

local function serverHop()
	local servers = game:GetService("HttpService"):JSONDecode(
		game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
	)
	for _, server in ipairs(servers.data) do
		if server.playing < server.maxPlayers and server.id ~= game.JobId then
			TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
			break
		end
	end
end

-- loading libraries

local GUI = loadstring(
	game:HttpGet("https://raw.githubusercontent.com/itzBoolean/Fierce-Client/refs/heads/dev/gui/windui.lua")
)()

local LegitsLib = loadstring(
	game:HttpGet("https://raw.githubusercontent.com/itzBoolean/Fierce-Client/refs/heads/main/gui/Legits.lua")
)()

local BlurGUI = loadstring(
	game:HttpGet("https://raw.githubusercontent.com/itzBoolean/Fierce-Client/refs/heads/dev/gui/blurGUI.lua")
)()

-- module libraries
loadstring(game:HttpGet("https://raw.githubusercontent.com/itzBoolean/Fierce-Client/refs/heads/main/gui/aimbot.lua"))()

if LegitsLib == nil then
	warn("Failed to load Legits lib")
end

GUI:SetNotificationLower(true)

local Window = GUI:CreateWindow({
	Title = "Fierce Client",
	Icon = "",
	Author = "v1.0.0",
	Folder = "Fierce-Client",

	Size = UDim2.fromOffset(580, 460),
	MinSize = Vector2.new(560, 350),
	MaxSize = Vector2.new(850, 560),
	ToggleKey = Enum.KeyCode.RightShift,
	Transparent = true,
	Theme = "Dark",
	Resizable = true,
	SideBarWidth = 200,
	BackgroundImageTransparency = 0.42,
	HideSearchBar = false,
	ScrollBarEnabled = true,

	User = {
		Enabled = true,
		Anonymous = false,
	},
})

Window:Tag({
	Title = "Developer",
	Icon = "lucide:code-xml",
	Color = Color3.fromHex("#1f7e9b"),
	Border = true,
})

local function mtoggle(mname, state) --module notify
	GUI:Notify({
		Title = mname,
		Content = state and "Enabled" or "Disabled",
		Icon = state and "lucide:check" or "lucide:x",
		Duration = 1,
	})
end

-- Public UI references
local Controls = {
	Toggles = {},
	Buttons = {},
	Sliders = {},
	Dropdowns = {},
	ColorPickers = {},
	Keybinds = {},
}

-- Sections
local Modules = Window:Section({
	Title = "Modules",
	Icon = "lucide:package",
	IconThemed = true,
	Opened = true,
})

local Settings = Window:Section({
	Title = "Settings",
	Icon = "lucide:cog",
	IconThemed = true,
	Opened = false,
})

local Info = Window:Section({
	Title = "Info",
	Icon = "lucide:badge-info",
	IconThemed = true,
	Opened = false,
})

-- Tabs for Modules SECTION
local Player = Modules:Tab({
	Title = "Player",
	Desc = "All movement cheats",
	Icon = "solar:running-broken",
	IconThemed = true,
	Locked = false,
	ShowTabTitle = false,
	Border = true,
})

local Combat = Modules:Tab({
	Title = "Combat",
	Desc = "pvp like a pro",
	Icon = "lucide:swords",
	IconThemed = true,
	Locked = false,
	ShowTabTitle = false,
	Border = true,
})

local Visuals = Modules:Tab({
	Title = "Visuals",
	Desc = "Render, no detections!",
	Icon = "solar:paw-bold-duotone",
	IconThemed = true,
	Locked = false,
	ShowTabTitle = false,
	Border = true,
})

local Utility = Modules:Tab({
	Title = "Utiliy",
	Desc = "some miscellounous cheats",
	Icon = "lucide:wrench",
	IconThemed = true,
	Locked = false,
	ShowTabTitle = false,
	Border = true,
})

-- Tabs for Settings SECTION
local Legit = Settings:Tab({
	Title = "Legit",
	Desc = "all modules found in legit clients",
	Icon = "lucide:shapes", --lucide:layout-grid
	IconThemed = true,
	Locked = false,
	ShowTabTitle = false,
	Border = true,
})

-- Tabs for Info SECTION
local WhatsNew = Info:Tab({
	Title = "What's New?",
	Desc = "show all update logs",
	Icon = "lucide:circle-question-mark",
	IconThemed = true,
	Locked = false,
	ShowTabTitle = false,
	Border = true,
})

local AboutClient = Info:Tab({
	Title = "About",
	Icon = "lucide:info",
	IconThemed = true,
	Locked = false,
	ShowTabTitle = false,
	Border = true,
})
--[[
		Modules SECTION
]]

-- Modules for Player TAB
run(function()
	local HighJumpEnabled = false
	local ModeValue = "Velocity"
	local JumpHeightValue = 80
	local jumpConnection

	local function jump()
		local humanoid, root = getCharacterData()
		if not humanoid or not root then
			return
		end

		local state = humanoid:GetState()
		if state == Enum.HumanoidStateType.Running or state == Enum.HumanoidStateType.Landed then
			if ModeValue == "Velocity" then
				humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
				root.AssemblyLinearVelocity =
					Vector3.new(root.AssemblyLinearVelocity.X, JumpHeightValue, root.AssemblyLinearVelocity.Z)
			elseif ModeValue == "TP" then
				local yLevel = math.max(JumpHeightValue - humanoid.JumpHeight, 0)
				repeat
					root.CFrame = root.CFrame + Vector3.new(0, yLevel * 0.016, 0)
					yLevel = yLevel - (Workspace.Gravity * 0.016)
				until yLevel <= 0 or not getCharacterData()
			end
		end
	end

	local JumpPowerExploit = Player:Toggle({
		Title = "Jump Power",
		Callback = function(value)
			mtoggle("Jump Power", value)
			HighJumpEnabled = value

			if jumpConnection then
				jumpConnection:Disconnect()
				jumpConnection = nil
			end

			if HighJumpEnabled then
				jumpConnection = RunService.RenderStepped:Connect(function()
					if not UserInputService:GetFocusedTextBox() and UserInputService:IsKeyDown(Enum.KeyCode.Space) then
						jump()
					end
				end)
			end
		end,

		SubModule = {
			Elements = {
				{
					Type = "Slider",
					--[[
					--TODO: Jump Power:
					
					if speaker.Character:FindFirstChildOfClass('Humanoid').UseJumpPower
					then title = "Power" else title = "Height"
					Implement the logic in later versions of Fierce Client
					--]]
					Title = "Value",
					Min = 30,
					Max = 200,
					Default = 80,

					Callback = function(value)
						JumpHeightValue = value
					end,
				},
				{
					Type = "Dropdown",
					Title = "Type",
					Values = { "Velocity", "TP" },
					Default = "Velocity",

					Callback = function(value)
						if type(value) == "table" then
							ModeValue = value[1]
						else
							ModeValue = value
						end
					end,
				},
			},
		},
	})
	Controls.Toggles.JumpPower = JumpPowerExploit
end)

run(function()
	local flying = false
	local speed = 50
	local verticalSpeed = 50
	local flyConnection = nil

	local FlightExploit = Player:Toggle({
		Title = "Flight",
		Callback = function(value)
			mtoggle("Flight", value)
			flying = value

			if flying then
				if Humanoid then
					Humanoid.PlatformStand = false
				end

				flyConnection = RunService.PreSimulation:Connect(function(dt)
					if not flying or not LocalPlayer.Character then
						return
					end
					local currentCharacter = LocalPlayer.Character
					local currentRoot = currentCharacter:FindFirstChild("HumanoidRootPart")
					local currentHumanoid = currentCharacter:FindFirstChildOfClass("Humanoid")

					if not currentRoot or not currentHumanoid then
						return
					end

					local moveDir = Vector3.zero
					if UserInputService:IsKeyDown(Enum.KeyCode.W) then
						moveDir += camera.CFrame.LookVector
					end
					if UserInputService:IsKeyDown(Enum.KeyCode.S) then
						moveDir -= camera.CFrame.LookVector
					end
					if UserInputService:IsKeyDown(Enum.KeyCode.A) then
						moveDir -= camera.CFrame.RightVector
					end
					if UserInputService:IsKeyDown(Enum.KeyCode.D) then
						moveDir += camera.CFrame.RightVector
					end

					moveDir = Vector3.new(moveDir.X, 0, moveDir.Z)
					if moveDir.Magnitude > 0 then
						moveDir = moveDir.Unit * speed
					end

					local vertVel = 0
					if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
						vertVel = verticalSpeed
					elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
						vertVel = -verticalSpeed
					end

					currentRoot.AssemblyLinearVelocity = Vector3.new(moveDir.X, vertVel, moveDir.Z)
				end)
			else
				if flyConnection then
					flyConnection:Disconnect()
					flyConnection = nil
				end
				if Humanoid then
					Humanoid.PlatformStand = false
				end
				if HumanoidRootPart then
					HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(
						HumanoidRootPart.AssemblyLinearVelocity.X,
						0,
						HumanoidRootPart.AssemblyLinearVelocity.Z
					)
				end
			end
		end,

		SubModule = {
			Elements = {
				{
					Type = "Slider",
					Title = "Horizontal Speed",
					Min = 10,
					Max = 200,
					Default = 50,
					Callback = function(value)
						speed = value
					end,
				},
				{
					Type = "Slider",
					Title = "Vertical Speed",
					Min = 10,
					Max = 200,
					Default = 50,
					Callback = function(value)
						verticalSpeed = value
					end,
				},
			},
		},
	})
	Controls.Toggles.Flight = FlightExploit
end)

run(function()
	local airJump
	local airJumpDebounce = false

	local AirJumpExploit = Player:Toggle({
		Title = "Air Jump",
		Callback = function(value)
			mtoggle("Air Jump", value)
			if value then
				if airJump then
					airJump:Disconnect()
				end
				airJumpDebounce = false
				airJump = UserInputService.JumpRequest:Connect(function()
					if not airJumpDebounce then
						airJumpDebounce = true
						LocalPlayer.Character
							:FindFirstChildWhichIsA("Humanoid")
							:ChangeState(Enum.HumanoidStateType.Jumping)
						airJumpDebounce = false
					end
				end)
			else
				if airJump then
					airJump:Disconnect()
				end
				airJumpDebounce = false
			end
		end,
	})
	Controls.Toggles.AirJump = AirJumpExploit
end)

run(function()
	local speedEnabled = false
	local speedValue = 50

	RunService.PreSimulation:Connect(function(dt)
		if not speedEnabled then
			return
		end

		if not Character then
			return
		end

		if Humanoid and HumanoidRootPart then
			local moveDir = Humanoid.MoveDirection
			if moveDir.Magnitude > 0 then
				local currentVel = HumanoidRootPart.Velocity
				local newVelocity = moveDir * speedValue
				HumanoidRootPart.Velocity = Vector3.new(newVelocity.X, currentVel.Y, newVelocity.Z)
			end
		end
	end)

	local WalkSpeedExploit = Player:Toggle({
		Title = "Walk Speed",
		Callback = function(value)
			mtoggle("Walk Speed", value)
			speedEnabled = value
		end,

		SubModule = {
			Elements = {
				{
					Type = "Slider",
					Title = "Value",
					Min = 10,
					Max = 100,
					Default = 50,

					Callback = function(value)
						speedValue = value
					end,
				},
			},
		},
	})
	Controls.Toggles.WalkSpeed = WalkSpeedExploit
end)

run(function()
	local gravityEnabled = false
	local mode = "Velocity"
	local gravityValue = 60
	local oldGravity = nil
	local gravityConnection = nil
	local propConnection = nil
	local changed = false

	local function updateGravityState()
		if gravityEnabled then
			if propConnection then
				propConnection:Disconnect()
				propConnection = nil
			end
			if gravityConnection then
				gravityConnection:Disconnect()
				gravityConnection = nil
			end

			if mode == "Workspace" then
				oldGravity = Workspace.Gravity
				Workspace.Gravity = gravityValue

				propConnection = Workspace:GetPropertyChangedSignal("Gravity"):Connect(function()
					if changed then
						return
					end
					changed = true
					oldGravity = Workspace.Gravity
					Workspace.Gravity = gravityValue
					changed = false
				end)
			else
				gravityConnection = RunService.PreSimulation:Connect(function(dt)
					if Character and Humanoid and HumanoidRootPart and Humanoid.FloorMaterial == Enum.Material.Air then
						HumanoidRootPart.AssemblyLinearVelocity += Vector3.new(
							0,
							dt * (Workspace.Gravity - gravityValue),
							0
						)
					end
				end)
			end
		else
			if propConnection then
				propConnection:Disconnect()
				propConnection = nil
			end
			if gravityConnection then
				gravityConnection:Disconnect()
				gravityConnection = nil
			end
			if oldGravity then
				Workspace.Gravity = oldGravity
				oldGravity = nil
			end
		end
	end

	local GravityExploit = Player:Toggle({
		Title = "Gravity",
		Callback = function(value)
			mtoggle("Gravity", value)
			gravityEnabled = value
			updateGravityState()
		end,

		SubModule = {
			Elements = {
				{
					Type = "Slider",
					Title = "Value",
					Min = 0,
					Max = 192,
					Default = 60,

					Callback = function(value)
						gravityValue = value
						if gravityEnabled and mode == "Workspace" then
							changed = true
							Workspace.Gravity = value
							changed = false
						end
					end,
				},
				{
					Type = "Dropdown",
					Title = "Type",
					Values = { "Velocity", "Workspace" },
					Default = "Velocity",

					Callback = function(value)
						mode = value
						if gravityEnabled then
							updateGravityState()
						end
					end,
				},
			},
		},
	})
	Controls.Toggles.Gravity = GravityExploit
end)

run(function()
	local NoclipConnection = nil
	local NoclipEnabled = false

	LocalPlayer.CharacterAdded:Connect(function(character)
		if NoclipEnabled then
			character:WaitForChild("HumanoidRootPart")

			for _, part in ipairs(character:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = false
				end
			end
		end
	end)

	local function ToggleNoclip(state)
		NoclipEnabled = state

		if NoclipEnabled then
			NoclipConnection = RunService.Stepped:Connect(function()
				local character = LocalPlayer.Character
				if character then
					for _, part in ipairs(character:GetDescendants()) do
						if part:IsA("BasePart") and part.CanCollide then
							part.CanCollide = false
						end
					end
				end
			end)
		else
			if NoclipConnection then
				NoclipConnection:Disconnect()
				NoclipConnection = nil
			end

			local character = LocalPlayer.Character
			if character then
				for _, part in ipairs(character:GetDescendants()) do
					if part:IsA("BasePart") then
						part.CanCollide = true
					end
				end
			end
		end
	end

	local NoClipExploit = Player:Toggle({
		Title = "Phase",
		Callback = function(value)
			mtoggle("Phase", value)
			ToggleNoclip(value)
		end,
	})
	Controls.Toggles.Phase = NoClipExploit
end)

run(function()
	local spiderEnabled = false
	local spiderMode = "Regular"
	local spiderSpeed = 30
	local truss = nil
	local active = false

	local rayCheck = RaycastParams.new()
	rayCheck.RespectCanCollide = true

	RunService.PreSimulation:Connect(function(dt)
		if not spiderEnabled then
			return
		end

		local chars = { camera, Character, truss }
		for _, player in ipairs(game.Players:GetPlayers()) do
			if player ~= LocalPlayer and player.Character then
				table.insert(chars, player.Character)
			end
		end

		rayCheck.FilterDescendantsInstances = chars
		rayCheck.CollisionGroup = HumanoidRootPart.CollisionGroup

		if spiderMode == "Regular" then
			local vec = Humanoid.MoveDirection * 2.5
			local hipHeight = Humanoid.HipHeight > 0 and Humanoid.HipHeight or 2
			local ray = Workspace:Raycast(HumanoidRootPart.Position - Vector3.new(0, hipHeight - 0.5, 0), vec, rayCheck)

			if active and not ray then
				HumanoidRootPart.AssemblyLinearVelocity =
					Vector3.new(HumanoidRootPart.AssemblyLinearVelocity.X, 0, HumanoidRootPart.AssemblyLinearVelocity.Z)
			end

			active = ray
			if active and ray.Normal.Y == 0 then
				HumanoidRootPart.AssemblyLinearVelocity =
					Vector3.new(HumanoidRootPart.AssemblyLinearVelocity.X, 0, HumanoidRootPart.AssemblyLinearVelocity.Z)
				HumanoidRootPart.AssemblyLinearVelocity += Vector3.new(0, spiderSpeed, 0)
			end
		elseif spiderMode == "Climb" and truss then
			local hipHeight = Humanoid.HipHeight > 0 and Humanoid.HipHeight or 2
			local ray = Workspace:Raycast(
				HumanoidRootPart.Position - Vector3.new(0, hipHeight - 0.5, 0),
				HumanoidRootPart.CFrame.LookVector * 2,
				rayCheck
			)
			if ray then
				truss.Position = ray.Position - ray.Normal * 0.9
			else
				truss.Position = Vector3.zero
			end
		end
	end)

	local SpiderExploit = Player:Toggle({
		Title = "Spider",
		Callback = function(value)
			mtoggle("Spider", value)
			spiderEnabled = value
			if not spiderEnabled then
				if truss then
					truss.Parent = nil
				end
			else
				if truss and spiderMode == "Climb" then
					truss.Parent = camera
				end
			end
		end,

		SubModule = {
			Elements = {
				{
					Type = "Slider",
					Title = "Climb Speed",
					Min = 0,
					Max = 100,
					Default = 30,

					Callback = function(value)
						spiderSpeed = value
					end,
				},
				{
					Type = "Dropdown",
					Title = "Type",
					Values = { "Regular", "Climb" },
					Value = "Regular",

					Callback = function(value)
						spiderMode = value
						if truss then
							truss:Destroy()
							truss = nil
						end
						if spiderMode == "Climb" then
							truss = Instance.new("TrussPart")
							truss.Size = Vector3.new(2, 2, 2)
							truss.Transparency = 1
							truss.Anchored = true
							truss.Parent = spiderEnabled and camera or nil
						end
					end,
				},
			},
		},
	})
	Controls.Toggles.Spider = SpiderExploit
end)

run(function()
	local jesusConnection = nil
	local platform = nil
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include

	local JesusExploit = Player:Toggle({
		Title = "Water Walk",
		Callback = function(value)
			mtoggle("Water Walk", value)
			if value then
				local terrain = Workspace:FindFirstChildWhichIsA("Terrain")
				if not terrain then
					return
				end
				params.FilterDescendantsInstances = { terrain }

				platform = Instance.new("Part")
				platform.CanQuery = false
				platform.Anchored = true
				platform.Size = Vector3.one
				platform.Transparency = 1
				platform.Parent = camera

				jesusConnection = RunService.PreSimulation:Connect(function()
					local character = LocalPlayer.Character
					if character and character:FindFirstChild("HumanoidRootPart") then
						local root = character.HumanoidRootPart
						local humanoid = character:FindFirstChildOfClass("Humanoid")
						local hipHeight = humanoid and humanoid.HipHeight or 2

						local ray = Workspace:Raycast(
							root.Position,
							Vector3.new(
								0,
								-((root.Size.Y / 2) + hipHeight + math.abs(root.AssemblyLinearVelocity.Y * 0.032)),
								0
							),
							params
						)

						if ray and ray.Material == Enum.Material.Water then
							platform.CFrame = CFrame.new(ray.Position)
						else
							platform.CFrame = CFrame.new(10000, 10000, 10000)
						end
					end
				end)
			else
				if jesusConnection then
					jesusConnection:Disconnect()
					jesusConnection = nil
				end
				if platform then
					platform:Destroy()
					platform = nil
				end
			end
		end,
	})
	Controls.Toggles.WaterWalk = JesusExploit
end)

run(function()
	local AntiFallConfig = {
		Enabled = false,
		BounceVelocity = 100,
		VoidColor = Color3.fromRGB(214, 243, 176),
	}

	local part = nil
	local touchConnection = nil

	local function cleanupPart()
		if part then
			part:Destroy()
			part = nil
		end
		if touchConnection then
			touchConnection:Disconnect()
			touchConnection = nil
		end
	end

	local AntiVoidExploit = Player:Toggle({
		Title = "Anti Void",
		Callback = function(value)
			AntiFallConfig.Enabled = value

			if value then
				local debounce = 0
				part = Instance.new("Part")
				part.Anchored = true
				part.Color = AntiFallConfig.VoidColor
				part.CanCollide = false
				part.CanQuery = false
				part.Material = Enum.Material.ForceField
				part.Size = Vector3.new(10000, 1, 10000)
				part.Transparency = 0.5
				part.Parent = Workspace

				touchConnection = part.Touched:Connect(function(touched)
					local lplr = game:GetService("Players").LocalPlayer
					if lplr.Character and touched:IsDescendantOf(lplr.Character) and debounce < os.clock() then
						local root = lplr.Character:FindFirstChild("HumanoidRootPart")
						if root then
							debounce = os.clock() + 0.1
							root.AssemblyLinearVelocity = Vector3.new(
								root.AssemblyLinearVelocity.X,
								AntiFallConfig.BounceVelocity,
								root.AssemblyLinearVelocity.Z
							)
						end
					end
				end)

				task.spawn(function()
					local rayCheck = RaycastParams.new()
					rayCheck.RespectCanCollide = true
					while AntiFallConfig.Enabled do
						local lplr = game:GetService("Players").LocalPlayer
						local character = lplr.Character
						if character and character:FindFirstChild("HumanoidRootPart") then
							local root = character.HumanoidRootPart
							rayCheck.FilterDescendantsInstances = { Workspace.CurrentCamera, character, part }
							rayCheck.CollisionGroup = root.CollisionGroup

							local ray = Workspace:Raycast(root.Position, Vector3.new(0, -1000, 0), rayCheck)
							if ray then
								part.Position = ray.Position - Vector3.new(0, 15, 0)
							end
						end
						task.wait(0.1)
					end
				end)
			else
				cleanupPart()
			end
		end,

		SubModule = {
			Elements = {
				{
					Type = "ColorPicker",
					Title = "Void Color",
					Default = Color3.fromRGB(214, 243, 176),

					Callback = function(color)
						AntiFallConfig.VoidColor = color
						if part then
							part.Color = color
						end
					end,
				},
				{
					Type = "Slider",
					Title = "Bounce Length",
					Min = 0,
					Max = 200,
					Default = 100,
					Callback = function(value)
						AntiFallConfig.BounceVelocity = value
					end,
				},
			},
		},
	})
	Controls.Toggles.AntiVoid = AntiVoidExploit
end)

run(function()
	local ajLoop = nil
	local ajCA = nil

	local AutoJumpExploit = Player:Toggle({
		Title = "Auto Jump",
		Callback = function(value)
			if value then
				local Char = LocalPlayer.Character
				local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")

				local function autoJump()
					if Char and Human then
						local rootPart = Char:FindFirstChild("HumanoidRootPart") or Human.RootPart
						if rootPart then
							local check1 = Workspace:FindPartOnRay(
								Ray.new(rootPart.Position - Vector3.new(0, 1.5, 0), rootPart.CFrame.LookVector * 3),
								Char
							)
							local check2 = Workspace:FindPartOnRay(
								Ray.new(rootPart.Position + Vector3.new(0, 1.5, 0), rootPart.CFrame.LookVector * 3),
								Char
							)

							if check1 or check2 then
								Human.Jump = true
							end
						end
					end
				end

				autoJump()
				ajLoop = RunService.RenderStepped:Connect(autoJump)

				ajCA = LocalPlayer.CharacterAdded:Connect(function(nChar)
					Char = nChar
					Human = nChar:WaitForChild("Humanoid")
					autoJump()
					if ajLoop then
						ajLoop:Disconnect()
					end
					ajLoop = RunService.RenderStepped:Connect(autoJump)
				end)
			else
				if ajLoop then
					ajLoop:Disconnect()
					ajLoop = nil
				end
				if ajCA then
					ajCA:Disconnect()
					ajCA = nil
				end
			end
		end,
	})
	Controls.Toggles.AutoJump = AutoJumpExploit
end)

run(function()
	local ejLoop = nil
	local ejCA = nil

	local ParkourExploit = Player:Toggle({
		Title = "Parkour",
		Callback = function(value)
			if value then
				local Char = LocalPlayer.Character
				local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")

				local state
				local laststate
				local lastcf

				local function edgejump()
					if Char and Human and Char:FindFirstChild("HumanoidRootPart") then
						laststate = state
						state = Human:GetState()
						local rootPart = Char.HumanoidRootPart

						if
							laststate ~= state
							and state == Enum.HumanoidStateType.Freefall
							and laststate ~= Enum.HumanoidStateType.Jumping
						then
							rootPart.CFrame = lastcf
							rootPart.AssemblyLinearVelocity = Vector3.new(
								rootPart.AssemblyLinearVelocity.X,
								Human.JumpPower or Human.JumpHeight,
								rootPart.AssemblyLinearVelocity.Z
							)
						end
						lastcf = rootPart.CFrame
					end
				end

				ejLoop = RunService.RenderStepped:Connect(edgejump)
				ejCA = LocalPlayer.CharacterAdded:Connect(function(nChar)
					Char = nChar
					Human = nChar:WaitForChild("Humanoid")
					edgejump()
					if ejLoop then
						ejLoop:Disconnect()
					end
					ejLoop = RunService.RenderStepped:Connect(edgejump)
				end)
			else
				if ejLoop then
					ejLoop:Disconnect()
					ejLoop = nil
				end
				if ejCA then
					ejCA:Disconnect()
					ejCA = nil
				end
			end
		end,
	})
	Controls.Toggles.Parkour = ParkourExploit
end)

-- Modules for Combat TAB

run(function()
	ExunysDeveloperAimbot.Load()

	local Aimbot = getgenv().ExunysDeveloperAimbot
	Aimbot.Settings.Enabled = false
	Aimbot.Settings.Toggle = true
	Aimbot.Settings.Sensitivity = 0.10
	Aimbot.FOVSettings.Radius = 90

	local AimAssistExploit = Combat:Toggle({
		Title = "Aim Assist",
		Value = Aimbot.Settings.Enabled,
		Callback = function(value)
			Aimbot.Settings.Enabled = value
		end,

		SubModule = {
			Elements = {
				{
					Type = "Dropdown",
					Title = "Mode",
					Values = { "Limitless", "Blatant", "Smooth", "Legit" },
					Value = "Smooth",

					Callback = function(value)
						if value == "Limitless" then
							Aimbot.Settings.Sensitivity = 0.0
						elseif value == "Blatant" then
							Aimbot.Settings.Sensitivity = 0.05
						elseif value == "Smooth" then
							Aimbot.Settings.Sensitivity = 0.10
						elseif value == "Legit" then
							Aimbot.Settings.Sensitivity = 0.15
						end
					end,
				},
				{
					Type = "Dropdown",
					Title = "Target Part",
					Values = { "Head", "HumanoidRootPart" },
					Value = Aimbot.Settings.LockPart or "Head",

					Callback = function(value)
						Aimbot.Settings.LockPart = value
					end,
				},
				{
					Type = "Toggle",
					Title = "Team check",
					Value = Aimbot.Settings.TeamCheck,

					Callback = function(value)
						print(value)
						Aimbot.Settings.TeamCheck = value
					end,
				},
				{
					Type = "Toggle",
					Title = "Wall check",
					Value = Aimbot.Settings.WallCheck,

					Callback = function(value)
						Aimbot.Settings.WallCheck = value
					end,
				},
				--TODO: OffsetToMoveDirection (boolean), OffsetIncreament (number)
				{
					Type = "Toggle",
					Title = "Require right click",
					Value = Aimbot.Settings.RequireRightClick,

					Callback = function(value)
						Aimbot.Settings.RequireRightClick = value
					end,
				},
				--
				{
					Type = "Toggle",
					Title = "Show FOV",
					Value = true,

					Callback = function(value)
						Aimbot.FOVSettings.Enabled = value
						Aimbot.FOVSettings.Visible = value
					end,
				},
				{
					Type = "Slider",
					Title = "FOV radius",
					Min = 10,
					Max = 500,
					Value = Aimbot.FOVSettings.Radius,
					Callback = function(value)
						Aimbot.FOVSettings.Radius = value
					end,
				},
				{
					Type = "ColorPicker",
					Title = "FOV colour",
					Value = Aimbot.FOVSettings.Color,

					Callback = function(color)
						Aimbot.FOVSettings.Color = color
					end,
				},
				--TODO: closest player tracer
			},
		},
	})

	local TriggerbotExploit = Combat:Toggle({
		Title = "Triggerbot",
		Value = Aimbot.Triggerbot.Enabled,
		Callback = function(value)
			Aimbot.Triggerbot.Enabled = value
		end,

		SubModule = {
			Elements = {
				{
					Type = "Slider",
					Title = "Click Delay ",
					Min = 0,
					Max = 1,
					Step = 0.01,
					Value = Aimbot.Triggerbot.Delay,
					Callback = function(Value)
						Aimbot.Triggerbot.Delay = Value
					end,
				},
				{
					Type = "Toggle",
					Title = "Team check",
					Value = Aimbot.Triggerbot.TeamCheck,

					Callback = function(value)
						Aimbot.Triggerbot.TeamCheck = value
					end,
				},
				{
					Type = "Toggle",
					Title = "Alive check",
					Value = Aimbot.Triggerbot.AliveCheck,

					Callback = function(value)
						Aimbot.Triggerbot.AliveCheck = value
					end,
				},
				{
					Type = "Toggle",
					Title = "Wall check",
					Value = Aimbot.Settings.WallCheck,

					Callback = function(value)
						Aimbot.Settings.WallCheck = value
					end,
				},
			},
		},
	})
	Controls.Toggles.AimAssist = AimAssistExploit
	Controls.Toggles.Triggerbot = TriggerbotExploit
end)

--TODO: Velocity
--TODO: Rotations

-- Modules for Visuals TAB

run(function()
	local ESP = { Enabled = false }
	local Color = { Hue = 0, Sat = 1, Value = 1 }
	local Distance = { Enabled = true }
	local DistanceLimit = { ValueMin = 0, ValueMax = 64 }

	local Reference = {}
	local RenderConnection
	local PlayerAddedConnection
	local PlayerRemovingConnection

	Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		camera = Workspace.CurrentCamera or Workspace.ActiveCamera
	end)

	local function CreateESP(plr)
		if plr == LocalPlayer or Reference[plr] then
			return
		end

		local EntityESP = {}

		EntityESP.Main = Drawing.new("Square")
		EntityESP.Main.Transparency = 1
		EntityESP.Main.ZIndex = 2
		EntityESP.Main.Filled = false
		EntityESP.Main.Thickness = 1
		EntityESP.Main.Color = Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)

		EntityESP.Border = Drawing.new("Square")
		EntityESP.Border.Transparency = 0.35
		EntityESP.Border.ZIndex = 1
		EntityESP.Border.Thickness = 1
		EntityESP.Border.Filled = false
		EntityESP.Border.Color = Color3.new(0, 0, 0)

		EntityESP.Border2 = Drawing.new("Square")
		EntityESP.Border2.Transparency = 0.35
		EntityESP.Border2.ZIndex = 1
		EntityESP.Border2.Thickness = 1
		EntityESP.Border2.Filled = false
		EntityESP.Border2.Color = Color3.new(0, 0, 0)

		Reference[plr] = EntityESP
	end

	local function RemoveESP(plr)
		local EntityESP = Reference[plr]
		if EntityESP then
			Reference[plr] = nil
			for _, obj in pairs(EntityESP) do
				pcall(function()
					obj.Visible = false
					obj:Remove()
				end)
			end
		end
	end

	local function UpdateESP()
		if not camera then
			return
		end
		local localChar = LocalPlayer.Character
		local localRoot = localChar and (localChar:FindFirstChild("HumanoidRootPart") or localChar.PrimaryPart)

		for plr, EntityESP in pairs(Reference) do
			local char = plr.Character
			local root = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
			local hum = char and char:FindFirstChildOfClass("Humanoid")

			if not char or not root or not hum or hum.Health <= 0 then
				for _, obj in pairs(EntityESP) do
					obj.Visible = false
				end
				continue
			end

			if Distance.Enabled and localRoot then
				local dist = (localRoot.Position - root.Position).Magnitude
				if dist < DistanceLimit.ValueMin or dist > DistanceLimit.ValueMax then
					for _, obj in pairs(EntityESP) do
						obj.Visible = false
					end
					continue
				end
			end

			local rootPos, rootVis = camera:WorldToViewportPoint(root.Position)
			for _, obj in pairs(EntityESP) do
				obj.Visible = rootVis
			end

			if not rootVis then
				continue
			end

			local hipHeight = (hum.HipHeight > 0 and hum.HipHeight) or 2
			local topPos = camera:WorldToViewportPoint(
				(CFrame.lookAlong(root.Position, camera.CFrame.LookVector) * CFrame.new(2, hipHeight, 0)).Position
			)
			local bottomPos = camera:WorldToViewportPoint(
				(CFrame.lookAlong(root.Position, camera.CFrame.LookVector) * CFrame.new(-2, -hipHeight - 1, 0)).Position
			)

			local sizex = topPos.X - bottomPos.X
			local sizey = topPos.Y - bottomPos.Y
			local posx = rootPos.X - (sizex / 2)
			local posy = rootPos.Y - (sizey / 2)

			EntityESP.Main.Position = Vector2.new(posx, posy)
			EntityESP.Main.Size = Vector2.new(sizex, sizey)

			EntityESP.Border.Position = Vector2.new(posx - 1, posy + 1)
			EntityESP.Border.Size = Vector2.new(sizex + 2, sizey - 2)

			EntityESP.Border2.Position = Vector2.new(posx + 1, posy - 1)
			EntityESP.Border2.Size = Vector2.new(sizex - 2, sizey + 2)
		end
	end

	local function ToggleESP(state)
		ESP.Enabled = state

		if state then
			for _, plr in pairs(Players:GetPlayers()) do
				CreateESP(plr)
			end

			PlayerAddedConnection = Players.PlayerAdded:Connect(CreateESP)
			PlayerRemovingConnection = Players.PlayerRemoving:Connect(RemoveESP)
			RenderConnection = RunService.RenderStepped:Connect(UpdateESP)
		else
			if PlayerAddedConnection then
				PlayerAddedConnection:Disconnect()
			end
			if PlayerRemovingConnection then
				PlayerRemovingConnection:Disconnect()
			end
			if RenderConnection then
				RenderConnection:Disconnect()
			end

			for plr in pairs(Reference) do
				RemoveESP(plr)
			end
		end
	end

	local ESPExploit = Visuals:Toggle({
		Title = "ESP",
		Callback = function(value)
			ToggleESP(value)
		end,

		SubModule = {
			Elements = {
				{
					Type = "ColorPicker",
					Title = "Box Color",
					Default = Color3.fromHSV(Color.Hue, Color.Sat, Color.Value),

					Callback = function(color)
						local h, s, v = color:ToHSV()
						Color.Hue, Color.Sat, Color.Value = h, s, v
						for _, EntityESP in pairs(Reference) do
							EntityESP.Main.Color = color
						end
					end,
				},
				{
					Type = "Slider",
					Title = "Render Distance",
					Min = 0,
					Max = 256,
					Default = 64,
					Callback = function(value)
						DistanceLimit.ValueMax = value
					end,
				},
			},
		},
	})
	Controls.Toggles.ESP = ESPExploit
end)

run(function()
	local Tracers = { Enabled = false }
	local Color = { Hue = 0, Sat = 1, Value = 1 }
	local Distance = { Enabled = true }
	local DistanceLimit = { ValueMin = 0, ValueMax = 64 }

	local Reference = {}
	local RenderConnection
	local PlayerAddedConnection
	local PlayerRemovingConnection

	Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		camera = Workspace.CurrentCamera or Workspace.ActiveCamera
	end)

	local function CreateTracer(plr)
		if plr == LocalPlayer or Reference[plr] then
			return
		end

		local EntityTracer = Drawing.new("Line")
		EntityTracer.Thickness = 1
		EntityTracer.Transparency = 1
		EntityTracer.Color = Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)

		Reference[plr] = EntityTracer
	end

	local function RemoveTracer(plr)
		local EntityTracer = Reference[plr]
		if EntityTracer then
			Reference[plr] = nil
			pcall(function()
				EntityTracer.Visible = false
				EntityTracer:Remove()
			end)
		end
	end

	local function UpdateTracers()
		if not camera then
			return
		end

		local screenSize = camera.ViewportSize
		local startVector = Vector2.new(screenSize.X / 2, screenSize.Y)

		local localChar = LocalPlayer.Character
		local localRoot = localChar and (localChar:FindFirstChild("HumanoidRootPart") or localChar.PrimaryPart)

		for plr, EntityTracer in pairs(Reference) do
			local char = plr.Character
			local root = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
			local hum = char and char:FindFirstChildOfClass("Humanoid")

			if not char or not root or not hum or hum.Health <= 0 then
				EntityTracer.Visible = false
				continue
			end

			if Distance.Enabled and localRoot then
				local dist = (localRoot.Position - root.Position).Magnitude
				if dist < DistanceLimit.ValueMin or dist > DistanceLimit.ValueMax then
					EntityTracer.Visible = false
					continue
				end
			end

			local rootPos, rootVis = camera:WorldToViewportPoint(root.Position)
			if not rootVis then
				EntityTracer.Visible = false
				continue
			end

			EntityTracer.Visible = true
			EntityTracer.From = startVector
			EntityTracer.To = Vector2.new(rootPos.X, rootPos.Y)
		end
	end

	local function ToggleTracers(state)
		Tracers.Enabled = state

		if state then
			for _, plr in pairs(Players:GetPlayers()) do
				CreateTracer(plr)
			end

			PlayerAddedConnection = Players.PlayerAdded:Connect(CreateTracer)
			PlayerRemovingConnection = Players.PlayerRemoving:Connect(RemoveTracer)
			RenderConnection = RunService.RenderStepped:Connect(UpdateTracers)
		else
			if PlayerAddedConnection then
				PlayerAddedConnection:Disconnect()
			end
			if PlayerRemovingConnection then
				PlayerRemovingConnection:Disconnect()
			end
			if RenderConnection then
				RenderConnection:Disconnect()
			end

			for plr in pairs(Reference) do
				RemoveTracer(plr)
			end
		end
	end

	local TracersExploit = Visuals:Toggle({
		Title = "Tracers",
		Callback = function(value)
			ToggleTracers(value)
		end,

		SubModule = {
			Elements = {
				{
					Type = "ColorPicker",
					Title = "Box Colour",
					Default = Color3.fromHSV(Color.Hue, Color.Sat, Color.Value),

					Callback = function(color)
						local h, s, v = color:ToHSV()
						Color.Hue, Color.Sat, Color.Value = h, s, v
						for _, EntityTracer in pairs(Reference) do
							EntityTracer.Color = color
						end
					end,
				},
				{
					Type = "Slider",
					Title = "Render Distance",
					Min = 0,
					Max = 256,
					Default = 64,
					Callback = function(value)
						DistanceLimit.ValueMax = value
					end,
				},
			},
		},
	})
	Controls.Toggles.Tracers = TracersExploit
end)

--TODO: spectate

--TODO: waypoint

run(function()
	local modifiedParts = {}
	local ignoredParts = {}
	local xrayConnection

	local XrayExploit = Visuals:Toggle({
		Title = "Xray",
		Callback = function(value)
			mtoggle("Xray", value)
			if value then
				local function modifyPart(part)
					if part:IsA("BasePart") and not table.find(ignoredParts, part.Name) then
						modifiedParts[part] = true
						part.LocalTransparencyModifier = 0.5
					end
				end

				xrayConnection = Workspace.DescendantAdded:Connect(modifyPart)

				for _, part in ipairs(Workspace:GetDescendants()) do
					modifyPart(part)
				end
			else
				if xrayConnection then
					xrayConnection:Disconnect()
					xrayConnection = nil
				end

				for part, _ in pairs(modifiedParts) do
					if part and part.Parent then
						part.LocalTransparencyModifier = 0
					end
				end

				table.clear(modifiedParts)
			end
		end,
	})
	Controls.Toggles.Xray = XrayExploit
end)

run(function()
	local originalLighting = {
		Brightness = Lighting.Brightness,
		ClockTime = Lighting.ClockTime,
		FogEnd = Lighting.FogEnd,
		GlobalShadows = Lighting.GlobalShadows,
		OutdoorAmbient = Lighting.OutdoorAmbient,
	}

	local FullbrightExploit = Visuals:Toggle({
		Title = "Fullbright",
		Callback = function(value)
			mtoggle("Fullbright", value)
			if value then
				Lighting.Brightness = 2
				Lighting.ClockTime = 14
				Lighting.FogEnd = 100000
				Lighting.GlobalShadows = false
				Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
			else
				Lighting.Brightness = originalLighting.Brightness
				Lighting.ClockTime = originalLighting.ClockTime
				Lighting.FogEnd = originalLighting.FogEnd
				Lighting.GlobalShadows = originalLighting.GlobalShadows
				Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
			end
		end,
	})
	Controls.Toggles.Fullbright = FullbrightExploit
end)

run(function()
	local orgTime = Lighting.TimeOfDay
	local val = 12
	local isTimeChanger = false

	local TimeChangerExploit = Legit:Toggle({
		Title = "Time Changer",
		Callback = function(value)
			isTimeChanger = value
			if value then
				Lighting.TimeOfDay = val
			else
				Lighting.TimeOfDay = orgTime
			end
		end,

		SubModule = {
			Elements = {
				{
					Type = "Slider",
					Title = "Time",
					Min = 0,
					Max = 24,
					Default = val,

					Callback = function(value)
						val = value
						if isTimeChanger then
							Lighting.TimeOfDay = val
						end
					end,
				},
			},
		},
	})
	Controls.Toggles.TimeChanger = TimeChangerExploit
end)

run(function()
	local orgFogEnd = Lighting.FogEnd

	local NoFogExploit = Legit:Toggle({
		Title = "No Fog",
		Callback = function(value)
			if value then
				Lighting.FogEnd = 100000
				for i, v in pairs(Lighting:GetDescendants()) do
					if v:IsA("Atmosphere") then
						v:Destroy()
					end
				end
			else
				Lighting.FogEnd = orgFogEnd
				for i, v in pairs(Lighting:GetDescendants()) do
					if v:IsA("Atmosphere") then
						v:Destroy()
					end
				end
			end
		end,
	})
	Controls.Toggles.NoFog = NoFogExploit
end)

run(function()
	local wwSize = Terrain.WaterWaveSize
	local wwSpeed = Terrain.WaterWaveSpeed
	local wReflect = Terrain.WaterReflectance
	local wTrans = Terrain.WaterTransparency
	local gs = Lighting.GlobalShadows
	local fs = Lighting.FogStart
	local fe = Lighting.FogEnd

	local FPSBoostExploit = Legit:Toggle({
		Title = "FPS Boost",
		Callback = function(value)
			if value then
				Terrain.WaterWaveSize = 0
				Terrain.WaterWaveSpeed = 0
				Terrain.WaterReflectance = 0
				Terrain.WaterTransparency = 1
				Lighting.GlobalShadows = false
				Lighting.FogEnd = 9e9
				Lighting.FogStart = 9e9
				settings().Rendering.QualityLevel = 1
				for _, v in pairs(game:GetDescendants()) do
					if v:IsA("BasePart") then
						v.CastShadow = false
						v.Material = "Plastic"
						v.Reflectance = 0
						v.BackSurface = "SmoothNoOutlines"
						v.BottomSurface = "SmoothNoOutlines"
						v.FrontSurface = "SmoothNoOutlines"
						v.LeftSurface = "SmoothNoOutlines"
						v.RightSurface = "SmoothNoOutlines"
						v.TopSurface = "SmoothNoOutlines"
					elseif v:IsA("Decal") then
						v.Transparency = 1
						v.Texture = ""
					elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
						v.Lifetime = NumberRange.new(0)
					end
				end
				for _, v in pairs(Lighting:GetDescendants()) do
					if v:IsA("PostEffect") then
						v.Enabled = false
					end
				end
				Workspace.DescendantAdded:Connect(function(child)
					task.spawn(function()
						if
							child:IsA("ForceField")
							or child:IsA("Sparkles")
							or child:IsA("Smoke")
							or child:IsA("Fire")
							or child:IsA("Beam")
						then
							RunService.Heartbeat:Wait()
							child:Destroy()
						elseif child:IsA("BasePart") then
							child.CastShadow = false
						end
					end)
				end)
			else
				Terrain.WaterWaveSize = wwSize
				Terrain.WaterWaveSpeed = wwSpeed
				Terrain.WaterReflectance = wReflect
				Terrain.WaterTransparency = wTrans
				Lighting.GlobalShadows = gs
				Lighting.FogEnd = fe
				Lighting.FogStart = fs
			end
		end,
	})
	Controls.Toggles.FPSBoost = FPSBoostExploit
end)

-- Modules for Networks TAB

--TODO: Blink
--TODO: No Position Update
--TODO: fake lag
--TODO: backtrack

-- Modules for Utilities TAB
--[[
run(function()
	Utility:Button({
		Title = "Anti Kick",
		Desc = "Does not work on modern anticheat systems. May work on older games which has kick algorithm stored in LocalScripts.",
		Callback = function()
			local oldNamecall
			oldNamecall = hookmetamethod(
				game,
				"__namecall",
				newcclosure(function(...)
					local method = getnamecallmethod and getnamecallmethod() or ""
					if select(1, ...) == LocalPlayer and method == "Kick" or method == "kick" then
						return nil
					end
					return oldNamecall(...)
				end)
			)
			hookfunction(
				LocalPlayer.Kick,
				newcclosure(function(self, _)
					if self ~= LocalPlayer then
						error("Expected ':' not '.' calling member function Kick", 2)
					end
					return nil
				end)
			)
		end,
	})
	Controls.Toggles.FPSBoost = FPSBoostExploit
end)

run(function()
	Utility:Button({
		Title = "Anti Teleport",
		Desc = "Does not work on modern anticheat systems. May work on older games which has tp algorithm stored in LocalScripts.",
		Callback = function()
			local oldTp
			oldTp = hookfunction(
				TeleportService.Teleport,
				newcclosure(function(self, placeId, player, _teleportData, customLoadingScreen)
					if checkcaller() or (allow_rj and placeId == game.PlaceId) then
						return oldTp(self, placeId, player, _teleportData, customLoadingScreen)
					end
					if self ~= TeleportService then
						error("Expected ':' not '.' calling member function Teleport", 2)
					end
					if placeId == nil then
						error("Argument 1 missing or nil", 2)
					end
					if typeof(placeId) ~= "number" and placeId ~= true then
						error(`Unable to cast {typeof(placeId)} to int64`, 2)
					elseif placeId == true then
						-- somehow raise raiseTeleportInitFailedEvent
						return
					end
					if typeof(customLoadingScreen) ~= "Instance" and customLoadingScreen ~= nil then
						error("Unable to cast value to Object", 2)
					end
					return nil
				end)
			)
			hookfunction(
				TeleportService.TeleportAsync,
				newcclosure(function(self, placeId, players, teleportOptions)
					if self ~= TeleportService then
						error("Expected ':' not '.' calling member function TeleportAsync", 2)
					end
					if players == nil then
						error("Argument 2 missing or nil", 2)
					end
					if typeof(players) ~= "table" then
						error("Unable to cast value to Objects", 2)
					end
					error("TeleportUnknown must be called from a Server", 2)
				end)
			)
			local oldNamecall
			oldNamecall = hookmetamethod(
				game,
				"__namecall",
				newcclosure(function(...)
					local nmc = getnamecallmethod()
					if
						select(1, ...) == TeleportService and nmc == "teleport"
						or nmc == "Teleport"
						or nmc == "TeleportToPlaceInstance"
						or nmc == "TeleportAsync"
					then
						if checkcaller() or (allow_rj and select(2, ...) == game.PlaceId) then
							return oldNamecall(...)
						end
						return
					end
					return oldNamecall(...)
				end)
			)
		end,
	})
end)

run(function()
	Utility:Button({
		Title = "Serverhop",
		Callback = function()
			serverHop()
		end,
	})
end)

run(function()
	Utility:Button({
		Title = "Rejoin",
		Callback = function()
			TeleportService:Teleport(game.PlaceId)
		end,
	})
end)
]]
--

run(function()
	local antiflingConnection

	local AntiFlingExploit = Utility:Toggle({
		Title = "Anti Fling",
		Callback = function(value)
			if value then
				antiflingConnection = RunService.Stepped:Connect(function()
					for _, player in ipairs(Players:GetPlayers()) do
						if player ~= LocalPlayer and player.Character then
							for _, v in ipairs(player.Character:GetDescendants()) do
								if v:IsA("BasePart") then
									v.CanCollide = false
								end
							end
						end
					end
				end)
			else
				if antiflingConnection then
					antiflingConnection:Disconnect()
					antiflingConnection = nil
				end
			end
		end,
	})
	Controls.Toggles.AntiFling = AntiFlingExploit
end)

--TODO: AntiRagdoll
--TODO: AntiAFK

run(function()
	local KeepAnimationExploit = Utility:Toggle({
		Title = "Keep Animation",
		Callback = function(value)
			LocalPlayer.Character.Animate.Disabled = value
		end,
	})
	Controls.Toggles.KeepAnimation = KeepAnimationExploit
end)

run(function()
	local animSpeedEnabled = false

	local function fetchDefaultSpeed()
		local char = LocalPlayer.Character
		if char then
			local hum = char:FindFirstChildOfClass("Humanoid") or char:FindFirstChildOfClass("AnimationController")
			if hum then
				for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
					if track and track.Speed then
						return track.Speed
					end
				end
			end
		end
		return 1
	end

	local animSpeedValue = fetchDefaultSpeed()

	RunService.Heartbeat:Connect(function()
		if not animSpeedEnabled then
			return
		end

		local char = LocalPlayer.Character
		if not char then
			return
		end

		local hum = char:FindFirstChildOfClass("Humanoid") or char:FindFirstChildOfClass("AnimationController")
		if hum then
			for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
				track:AdjustSpeed(animSpeedValue)
			end
		end
	end)

	local AnimationSpeedExploit = Utility:Toggle({
		Title = "Animation Speed",
		Callback = function(value)
			animSpeedEnabled = value
		end,

		SubModule = {
			Elements = {
				{
					Type = "Slider",
					Title = "Speed",
					Min = 1,
					Max = fetchDefaultSpeed(),
					Step = 3,
					Default = fetchDefaultSpeed(),

					Callback = function(value)
						animSpeedValue = value
					end,
				},
			},
		},
	})
	Controls.Toggles.AnimationSpeed = AnimationSpeedExploit
end)

-- TODO: staff detector

--[[
			Settings SECTION
]]
--

-- Modules for Legit TAB

run(function()
	local EditModeLegits = Legit:Toggle({
		Title = "Edit Mode",
		Callback = function(value)
			if value then
				LegitsLib.StartEditMode()
			else
				LegitsLib.StopEditMode()
			end
		end,
	})
	Controls.Toggles.EditMode = EditModeLegits
end)

run(function()
	local ClockLegits = Legit:Toggle({
		Title = "Clock",
		Callback = function(value)
			if value then
				LegitsLib.Clock.Show()
			else
				LegitsLib.Clock.Hide()
			end
		end,

		SubModule = {
			Elements = {
				{
					Type = "Dropdown",
					Title = "Format",
					Values = { "12 hour", "24 hour" },
					Default = "12 hour",

					Callback = function(value)
						if value == "12 hour" then
							LegitsLib.Clock.SetType(12)
						else
							LegitsLib.Clock.SetType(24)
						end
					end,
				},
			},
		},
	})
	Controls.Toggles.Clock = ClockLegits
end)

run(function()
	local FPSLegits = Legit:Toggle({
		Title = "FPS",
		Callback = function(value)
			if value then
				LegitsLib.FPS.Show()
			else
				LegitsLib.FPS.Hide()
			end
		end,
	})
	Controls.Toggles.FPS = FPSLegits
end)

run(function()
	local CoordsLegits = Legit:Toggle({
		Title = "Coords",
		Callback = function(value)
			if value then
				LegitsLib.Coords.Show()
			else
				LegitsLib.Coords.Hide()
			end
		end,
	})
	Controls.Toggles.Coords = CoordsLegits
end)

run(function()
	LegitsLib.Keystrokes.SetKeyStyle("Keyboard")
	LegitsLib.Keystrokes.SetMouseStyle("Names")
	LegitsLib.Keystrokes.ShowSpaceBar = true

	local KeystrokesLegits = Legit:Toggle({
		Title = "Keystrokes",
		Callback = function(value)
			if value then
				LegitsLib.Keystrokes.Show()
			else
				LegitsLib.Keystrokes.Hide()
			end
		end,

		SubModule = {
			Elements = {
				{
					Type = "Dropdown",
					Title = "Key Style",
					Values = { "WASD", "Arrows" },
					Default = "WASD",

					Callback = function(value)
						if value == "WASD" then
							LegitsLib.Keystrokes.SetKeyStyle("Keyboard")
						else
							LegitsLib.Keystrokes.SetKeyStyle("Arrows")
						end
					end,
				},
				{
					Type = "Dropdown",
					Title = "Mouse Style",
					Values = { "Names", "None" },
					Default = "Names",

					Callback = function(value)
						LegitsLib.Keystrokes.SetMouseStyle(value)
					end,
				},
				{
					Type = "Toggle",
					Title = "Show Spacebar",
					Default = true,
					Callback = function(value)
						LegitsLib.Keystrokes.ShowSpaceBar = value
					end,
				},
			},
		},
	})
	Controls.Toggles.Keystrokes = KeystrokesLegits
end)

Window:Close()

Window:OnOpen(function()
	print("Window Opened")
	BlurGUI.blur()
end)

Window:OnClose(function()
	print("Window Closed")
	BlurGUI.unblur()
end)

-- return values
return {
	FierceGUI = GUI,
	FierceWindow = Window,

	FierceSections = {
		Modules = Modules,
		Settings = Settings,
		Info = Info,
	},

	FierceTabs = {
		Player = Player,
		Combat = Combat,
		Visuals = Visuals,
		Utility = Utility,
		Legit = Legit,
		WhatsNew = WhatsNew,
		AboutClient = AboutClient,
	},

	Controls = Controls,

	Libraries = {
		Legits = LegitsLib,
		Blur = BlurGUI,
	},
}
