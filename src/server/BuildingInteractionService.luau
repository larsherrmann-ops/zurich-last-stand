local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Config = require(ReplicatedStorage.Shared.Config)
local settings = Config.Buildings
local Service = {}
local brokenPanes = {}
local passageBusy = {}

local LOCKED_BUILDINGS = {
	["tall apartments"] = true,
	["apartment building"] = true,
	["ramombuilding"] = true,
}

local function notify(player, message, kind)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local event = remotes and remotes:FindFirstChild("Notify")
	if event then event:FireClient(player, message, kind or "Info") end
end

local function findLockedBuilding(instance)
	local parent = instance
	while parent do
		if parent:IsA("Model") and LOCKED_BUILDINGS[string.lower(parent.Name)] then
			return parent
		end
		parent = parent.Parent
	end
	return nil
end

local function canInteract(player, position, distance)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return root ~= nil and humanoid ~= nil and humanoid.Health > 0
		and (root.Position - position).Magnitude <= distance
end

local function isDoor(object)
	if object:GetAttribute("ZurichDoor") or object:GetAttribute("ZurichGarageDoor") then return true end
	local name = string.lower(object.Name)
	return string.find(name, "door", 1, true) ~= nil
		and not string.find(name, "frame", 1, true)
		and not string.find(name, "number", 1, true)
		and not string.find(name, "handle", 1, true)
		and not string.find(name, "hinge", 1, true)
end

local function isPane(object)
	if not object:IsA("BasePart") then return false end
	if object:GetAttribute("ZurichWindow") then return true end
	local name = string.lower(object.Name)
	if string.find(name, "frame", 1, true) or string.find(name, "sill", 1, true)
		or string.find(name, "trim", 1, true) then return false end
	return object.Material == Enum.Material.Glass or name == "glass" or name == "windowpane"
		or name == "glasswindow" or name == "window"
end

local function configureDoor(object)
	if object:GetAttribute("ZurichDoorConfigured") then return end
	local parts = {}
	if object:IsA("BasePart") then table.insert(parts, object) end
	for _, child in object:GetDescendants() do
		if child:IsA("BasePart") then
			local name = string.lower(child.Name)
			if not string.find(name, "frame", 1, true) and not string.find(name, "jamb", 1, true)
				and not string.find(name, "track", 1, true) then table.insert(parts, child) end
		end
	end
	if #parts == 0 then return end
	object:SetAttribute("ZurichDoorConfigured", true)
	local bounds, size
	if object:IsA("Model") then bounds, size = object:GetBoundingBox()
	else bounds, size = object.CFrame, object.Size end
	local lower = string.lower(object.Name)
	local locked = findLockedBuilding(object) ~= nil
	local garage = object:GetAttribute("ZurichGarageDoor") == true
		or string.find(lower, "garage", 1, true) ~= nil
		or string.find(lower, "rollup", 1, true) ~= nil
		or string.find(lower, "roller", 1, true) ~= nil
		or string.find(lower, "shutter", 1, true) ~= nil
		or string.find(lower, "overhead", 1, true) ~= nil
	local isWideGate = math.max(size.X, size.Z) >= 6.5
		and size.Y >= 5
		and math.min(size.X, size.Z) <= 2
	garage = garage or isWideGate
	local double = not garage and (string.find(lower, "double", 1, true)
		or string.find(lower, "groupdoor", 1, true) or lower == "storedoors")
	local widthAxis = size.X >= size.Z and bounds.RightVector or -bounds.LookVector
	local normal = size.X >= size.Z and bounds.LookVector or bounds.RightVector
	local width = math.max(size.X, size.Z)
	local closed = {}
	for _, part in parts do
		part.Anchored = true
		closed[part] = { Frame = part.CFrame, Collidable = true }
		part.CanCollide = true
	end
	-- A stationary control remains reachable from either side when the leaf opens.
	local anchor = Instance.new("Part")
	anchor.Name = "ZurichDoorControl"
	anchor.Size = Vector3.one
	anchor.CFrame = bounds
	anchor.Anchored = true
	anchor.Transparency = 1
	anchor.CanCollide = false
	anchor.CanTouch = false
	anchor.CanQuery = false
	anchor.Parent = object.Parent
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ZurichDoorPrompt"
	prompt.ActionText = locked and "Verschlossen" or "Öffnen"
	prompt.ObjectText = locked and "Wichtiger Eingang" or (garage and "Garagentor" or "Tür")
	prompt.KeyboardKeyCode = Enum.KeyCode.Q
	prompt.HoldDuration = 0.15
	prompt.MaxActivationDistance = settings.InteractionDistance
	prompt.RequiresLineOfSight = false
	prompt.Parent = anchor
	if locked then
		for _, part in parts do
			part.Anchored = true
			part.CanCollide = true
		end
		prompt.Triggered:Connect(function(player)
			if canInteract(player, bounds.Position, settings.InteractionDistance) then
				notify(player, "EINGANG VERRIEGELT  ·  FENSTER EINSCHLAGEN", "Info")
			end
		end)
		return
	end

	local open, busy = false, false
	local angle = math.pi / 2
	local driver = Instance.new("NumberValue")
	driver.Parent = anchor
	driver.Changed:Connect(function(value)
		for part, state in closed do
			if not part.Parent then continue end
			if garage then
				part.CFrame = CFrame.new(0, (size.Y + 0.5) * value, 0) * state.Frame
			else
				local side = double and ((state.Frame.Position - bounds.Position):Dot(widthAxis) > 0 and 1 or -1) or -1
				local hinge = bounds.Position + widthAxis * (width / 2 * side)
				local rotation = angle * value * -side
				part.CFrame = CFrame.new(hinge) * CFrame.Angles(0, rotation, 0)
					* CFrame.new(-hinge) * state.Frame
			end
		end
	end)
	prompt.Triggered:Connect(function(player)
		if busy or not object.Parent or not canInteract(player, bounds.Position, settings.InteractionDistance) then return end
		if open then
			for _, other in Players:GetPlayers() do
				local root = other.Character and other.Character:FindFirstChild("HumanoidRootPart")
				if root then
					local point = bounds:PointToObjectSpace(root.Position)
					if math.abs(point.X) < size.X / 2 + 1.5 and math.abs(point.Y) < size.Y / 2 + 2
						and math.abs(point.Z) < size.Z / 2 + 1.5 then return end
				end
			end
		else
			local root = player.Character.HumanoidRootPart
			local away = (root.Position - bounds.Position):Dot(normal) >= 0 and -normal or normal
			local swing = CFrame.Angles(0, math.pi / 2, 0):VectorToWorldSpace(widthAxis)
			angle = swing:Dot(away) >= 0 and math.pi / 2 or -math.pi / 2
		end
		busy = true
		open = not open
		object:SetAttribute("ZurichDoorOpen", open)
		prompt.ActionText = open and "Schließen" or "Öffnen"
		for part in closed do if part.Parent then part.CanCollide = false end end
		local tween = TweenService:Create(driver, TweenInfo.new(garage and 1.1 or 0.4), { Value = open and 1 or 0 })
		tween.Completed:Once(function()
			for part, state in closed do if part.Parent then part.CanCollide = state.Collidable end end
			busy = false
		end)
		tween:Play()
	end)
end

function Service.DamageWindow(target, amount)
	if not target:IsA("BasePart") or not target:GetAttribute("ZurichBreakableWindow") then return nil end
	if target:GetAttribute("ZurichBroken") then return true, 0 end
	local health = math.max(0, (target:GetAttribute("ZurichWindowHealth") or settings.WindowHealth) - math.max(1, amount or 1))
	target:SetAttribute("ZurichWindowHealth", health)
	local prompt = target:FindFirstChild("ZurichWindowPrompt")
	if prompt then prompt.ActionText = "Einschlagen (" .. health .. ")" end
	if health == 0 then
		target:SetAttribute("ZurichBroken", true)
		brokenPanes[target] = true
		target.Transparency = 1
		target.CanCollide = false
		target.CanQuery = false
		target.CanTouch = false
		if prompt then prompt.Enabled = false end
		for _, child in target:GetChildren() do
			if child:IsA("Decal") or child:IsA("Texture") then child.Transparency = 1 end
		end
	else
		target.Color = Color3.fromRGB(180, 206, 214)
		target.Transparency = settings.WindowTransparency + (1 - health / settings.WindowHealth) * 0.15
	end
	return health == 0, health
end

local function playWindowPassage(character, root, humanoid, throughDirection, distance)
	if passageBusy[character] then return end
	passageBusy[character] = true

	local startCFrame = root.CFrame
	local startPosition = startCFrame.Position
	local targetPosition = startPosition + throughDirection * distance
	local middlePosition = startPosition
		+ throughDirection * (distance * 0.45)
		+ Vector3.new(0, 1.6, 0)
	local rotation = startCFrame.Rotation
	local wasAnchored = root.Anchored
	local oldWalkSpeed = humanoid.WalkSpeed
	local oldAutoRotate = humanoid.AutoRotate

	root.Anchored = true
	humanoid.WalkSpeed = 0
	humanoid.AutoRotate = false
	character:SetAttribute("WindowVaulting", true)

	local driver = Instance.new("CFrameValue")
	driver.Value = startCFrame
	driver.Changed:Connect(function(value)
		if root.Parent then root.CFrame = value end
	end)

	local first = TweenService:Create(driver, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Value = CFrame.new(middlePosition) * rotation,
	})
	local second = TweenService:Create(driver, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Value = CFrame.new(targetPosition) * rotation,
	})

	first.Completed:Connect(function(state)
		if state == Enum.PlaybackState.Completed and root.Parent then second:Play() end
	end)
	second.Completed:Connect(function()
		if root.Parent then
			root.Anchored = wasAnchored
			humanoid.WalkSpeed = oldWalkSpeed
			humanoid.AutoRotate = oldAutoRotate
			character:SetAttribute("WindowVaulting", false)
		end
		driver:Destroy()
		passageBusy[character] = nil
	end)
	first:Play()
end

function Service.StartWindowPassage()
	if Service._windowPassageConnection then return end
	Service._windowPassageConnection = RunService.Heartbeat:Connect(function()
		for pane in brokenPanes do
			if not pane.Parent then
				brokenPanes[pane] = nil
				continue
			end

			local boxCFrame = pane.CFrame
			local boxSize = pane.Size
			local thinOnX = boxSize.X <= boxSize.Z
			local normal = thinOnX and boxCFrame.RightVector or boxCFrame.LookVector
			normal = Vector3.new(normal.X, 0, normal.Z)
			if normal.Magnitude < 0.1 then continue end
			normal = normal.Unit

			local halfWidth = math.max(boxSize.X, boxSize.Z) / 2 + 1.5
			local halfHeight = boxSize.Y / 2 + 2.5
			local halfThickness = math.min(boxSize.X, boxSize.Z) / 2 + 2.5
			for _, player in Players:GetPlayers() do
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				if root and humanoid and humanoid.Health > 0 and not passageBusy[character] then
					local localPosition = boxCFrame:PointToObjectSpace(root.Position)
					local lateral = math.abs(thinOnX and localPosition.Z or localPosition.X)
					local sideDistance = (root.Position - boxCFrame.Position):Dot(normal)
					local movement = humanoid.MoveDirection
					if lateral <= halfWidth
						and math.abs(localPosition.Y) <= halfHeight
						and math.abs(sideDistance) <= halfThickness
						and movement.Magnitude > 0.1 then
						local throughDirection = sideDistance >= 0 and -normal or normal
						if movement.Unit:Dot(throughDirection) > 0.2 then
							local distance = math.abs(sideDistance) + math.min(boxSize.X, boxSize.Z) + 3
							playWindowPassage(character, root, humanoid, throughDirection, distance)
							break
						end
					end
				end
			end
		end
	end)
end

local function configureWindow(pane)
	if pane:GetAttribute("ZurichBreakableWindow") then return end
	pane:SetAttribute("ZurichBreakableWindow", true)
	pane:SetAttribute("ZurichWindowMaxHealth", settings.WindowHealth)
	pane:SetAttribute("ZurichWindowHealth", settings.WindowHealth)
	pane.Material = Enum.Material.Glass
	pane.Transparency = settings.WindowTransparency
	pane.Reflectance = 0.03
	pane.CanQuery = true
	pane.CanCollide = true
	for _, child in pane:GetChildren() do
		if child:IsA("Decal") or child:IsA("Texture") then child.Transparency = 1 end
		if child:IsA("Light") then child.Enabled = false end
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ZurichWindowPrompt"
	prompt.ActionText = "Einschlagen (" .. settings.WindowHealth .. ")"
	prompt.ObjectText = "Fenster"
	prompt.KeyboardKeyCode = Enum.KeyCode.Q
	prompt.HoldDuration = settings.WindowHitCooldown
	prompt.MaxActivationDistance = settings.WindowInteractionDistance
	prompt.RequiresLineOfSight = true
	prompt.Parent = pane
	local lastHit = 0
	prompt.Triggered:Connect(function(player)
		if not pane.Parent or not canInteract(player, pane.Position, settings.WindowInteractionDistance) then return end
		local now = os.clock()
		if now - lastHit < settings.WindowHitCooldown then return end
		lastHit = now
		Service.DamageWindow(pane, 1)
	end)
end

function Service.Configure(world)
	if not world then return end
	local descendants = world:GetDescendants()
	for _, object in descendants do
		if (object:IsA("Model") or object:IsA("BasePart")) and isDoor(object) then
			local parent, nested = object.Parent, false
			while parent and parent ~= world do
				if (parent:IsA("Model") or parent:IsA("BasePart")) and isDoor(parent) then nested = true; break end
				parent = parent.Parent
			end
			if not nested then configureDoor(object) end
		end
		if isPane(object) then configureWindow(object) end
	end
	Service.StartWindowPassage()
end

return Service
