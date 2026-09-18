local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")

local MovementController = {}

local player = Players.LocalPlayer
local config
local humanoid
local sprinting = false
local crouching = false

local function refreshMovement()
	if not humanoid then return end
	if crouching then
		humanoid.WalkSpeed = config.CrouchSpeed
		humanoid.CameraOffset = Vector3.new(0, -1.25, 0)
	elseif sprinting then
		humanoid.WalkSpeed = config.SprintSpeed
		humanoid.CameraOffset = Vector3.zero
	else
		humanoid.WalkSpeed = config.WalkSpeed
		humanoid.CameraOffset = Vector3.zero
	end
	player:SetAttribute("IsSprinting", sprinting and not crouching)
	player:SetAttribute("IsCrouching", crouching)
end

local function onSprint(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		sprinting = true
	elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
		sprinting = false
	end
	refreshMovement()
	return Enum.ContextActionResult.Pass
end

local function onCrouch(_, inputState)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	crouching = not crouching
	if crouching then sprinting = false end
	refreshMovement()
	return Enum.ContextActionResult.Sink
end

local function attachCharacter(character)
	humanoid = character:WaitForChild("Humanoid")
	humanoid.UseJumpPower = true
	humanoid.JumpPower = config.JumpPower
	sprinting = false
	crouching = false
	refreshMovement()
end

function MovementController.Start(playerConfig)
	config = playerConfig
	player.CameraMode = Enum.CameraMode.Classic
	player.CameraMinZoomDistance = config.CameraMinZoomDistance
	player.CameraMaxZoomDistance = config.CameraMaxZoomDistance

	ContextActionService:BindActionAtPriority(
		"Sprint",
		onSprint,
		false,
		Enum.ContextActionPriority.Medium.Value,
		Enum.KeyCode.LeftShift,
		Enum.KeyCode.RightShift,
		Enum.KeyCode.ButtonL3
	)
	ContextActionService:BindActionAtPriority(
		"Crouch",
		onCrouch,
		false,
		Enum.ContextActionPriority.Medium.Value,
		Enum.KeyCode.C,
		Enum.KeyCode.LeftControl,
		Enum.KeyCode.ButtonB
	)
	player.CharacterAdded:Connect(attachCharacter)
	if player.Character then attachCharacter(player.Character) end
end

return MovementController
