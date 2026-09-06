-- Services
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

-- Configuration
local BLUR_SIZE = 24
local TWEEN_TIME = 0.5
local tweenInfo = TweenInfo.new(TWEEN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Create or find the BlurEffect instance in Lighting
local blurEffect = Lighting:FindFirstChild("ScreenBlur")
if not blurEffect then
	blurEffect = Instance.new("BlurEffect")
	blurEffect.Name = "ScreenBlur"
	blurEffect.Size = 0
	blurEffect.Enabled = true
	blurEffect.Parent = Lighting
end

-- Variables to track active animations
local activeTween = nil

--[[
	Blurs the screen smoothly using TweenService.
--]]
local function blur()
	if activeTween then
		activeTween:Cancel()
	end
	
	activeTween = TweenService:Create(blurEffect, tweenInfo, {Size = BLUR_SIZE})
	activeTween:Play()
end

--[[
	Unblurs the screen smoothly using TweenService.
--]]
local function unblur()
	if activeTween then
		activeTween:Cancel()
	end
	
	activeTween = TweenService:Create(blurEffect, tweenInfo, {Size = 0})
	activeTween:Play()
end

-- Return the functions for use in other scripts
return {
	blur = blur,
	unblur = unblur
}
