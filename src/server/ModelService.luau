local ModelService = {}

local function part(parent, name, size, cframe, color, material, shape)
	local object = Instance.new("Part")
	object.Name = name
	object.Size = size
	object.CFrame = cframe
	object.Anchored = false
	object.CanCollide = false
	object.CanTouch = false
	object.CanQuery = false
	object.Massless = true
	object.Color = color
	object.Material = material or Enum.Material.SmoothPlastic
	if shape then object.Shape = shape end
	object.Parent = parent
	return object
end

local function weld(parent, base, child)
	local constraint = Instance.new("WeldConstraint")
	constraint.Part0 = base
	constraint.Part1 = child
	constraint.Parent = parent
	return constraint
end

local backpackSizes = {
	Small = Vector3.new(2.4, 2.8, 1.0),
	Scout = Vector3.new(2.8, 3.2, 1.1),
	Tactical = Vector3.new(3.2, 3.6, 1.25),
	Heavy = Vector3.new(3.6, 4.0, 1.45),
}

function ModelService.CreateBackpack(tier)
	local size = backpackSizes[tier] or backpackSizes.Small
	local model = Instance.new("Model")
	model.Name = "ZurichBackpack"
	model:SetAttribute("Tier", tier)
	local body = part(model, "BackpackBody", size, CFrame.new(), Color3.fromRGB(49, 74, 59), Enum.Material.Fabric)
	local flap = part(model, "Flap", Vector3.new(size.X * 0.84, size.Y * 0.22, size.Z + 0.08), CFrame.new(0, size.Y * 0.39, -0.03), Color3.fromRGB(70, 93, 68), Enum.Material.Fabric)
	local pocket = part(model, "FrontPocket", Vector3.new(size.X * 0.64, size.Y * 0.25, size.Z * 0.26), CFrame.new(0, -size.Y * 0.16, -size.Z * 0.58), Color3.fromRGB(38, 57, 46), Enum.Material.Fabric)
	local strap = part(model, "Strap", Vector3.new(size.X * 0.12, size.Y * 0.8, size.Z * 0.14), CFrame.new(-size.X * 0.35, 0, -size.Z * 0.53), Color3.fromRGB(22, 33, 28), Enum.Material.Fabric)
	local strap2 = part(model, "Strap2", Vector3.new(size.X * 0.12, size.Y * 0.8, size.Z * 0.14), CFrame.new(size.X * 0.35, 0, -size.Z * 0.53), Color3.fromRGB(22, 33, 28), Enum.Material.Fabric)
	for _, child in { flap, pocket, strap, strap2 } do weld(model, body, child) end
	model.PrimaryPart = body
	return model
end

function ModelService.AttachBackpack(character, tier)
	local old = character:FindFirstChild("ZurichBackpack")
	if old then old:Destroy() end
	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	if not torso or not torso:IsA("BasePart") then return end
	local backpack = ModelService.CreateBackpack(tier)
	backpack.Parent = character
	backpack:PivotTo(torso.CFrame * CFrame.new(0, 0.15, 0.65))
	weld(backpack, torso, backpack.PrimaryPart)
end

function ModelService.AttachWeapon(character, attributes)
	attributes = attributes or {}
	for _, name in { "ZurichWeapon", "ZurichPistol" } do
		local old = character:FindFirstChild(name)
		if old then old:Destroy() end
	end
	local hand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	if not hand or not hand:IsA("BasePart") then return end

	local weaponName = attributes.WeaponName or "Pistol"
	local model = Instance.new("Model")
	model.Name = "ZurichWeapon"
	model:SetAttribute("WeaponName", weaponName)
	local handle = part(model, "Handle", Vector3.new(0.35, 0.8, 0.3), CFrame.new(), Color3.fromRGB(31, 35, 35), Enum.Material.Metal)

	if weaponName == "Shotgun" then
		local receiver = part(model, "Receiver", Vector3.new(0.5, 0.48, 0.78), CFrame.new(0, 0.12, 0.05), Color3.fromRGB(42, 45, 42), Enum.Material.Metal)
		local barrel = part(model, "Barrel", Vector3.new(0.25, 0.25, 2.6), CFrame.new(0, 0.24, -1.25), Color3.fromRGB(111, 116, 108), Enum.Material.Metal)
		local stock = part(model, "Stock", Vector3.new(0.44, 0.5, 1.0), CFrame.new(0, 0.08, 0.82), Color3.fromRGB(101, 62, 38), Enum.Material.Wood)
		local pump = part(model, "Pump", Vector3.new(0.38, 0.3, 0.52), CFrame.new(0, -0.02, -0.7), Color3.fromRGB(111, 67, 39), Enum.Material.Wood)
		local grip = part(model, "Grip", Vector3.new(0.38, 0.78, 0.34), CFrame.new(0, -0.45, 0.05) * CFrame.Angles(math.rad(-12), 0, 0), Color3.fromRGB(44, 54, 52), Enum.Material.Plastic)
		for _, child in { receiver, barrel, stock, pump, grip } do weld(model, handle, child) end
	elseif weaponName == "Rifle" then
		local receiver = part(model, "Receiver", Vector3.new(0.52, 0.5, 1.08), CFrame.new(0, 0.12, 0.02), Color3.fromRGB(45, 49, 47), Enum.Material.Metal)
		local barrel = part(model, "Barrel", Vector3.new(0.22, 0.22, 2.7), CFrame.new(0, 0.24, -1.7), Color3.fromRGB(112, 119, 113), Enum.Material.Metal)
		local stock = part(model, "Stock", Vector3.new(0.44, 0.46, 1.2), CFrame.new(0, 0.08, 1.05), Color3.fromRGB(37, 47, 44), Enum.Material.Plastic)
		local magazine = part(model, "Magazine", Vector3.new(0.38, 0.72, 0.38), CFrame.new(0, -0.42, -0.2) * CFrame.Angles(math.rad(-10), 0, 0), Color3.fromRGB(31, 35, 34), Enum.Material.Metal)
		local grip = part(model, "Grip", Vector3.new(0.36, 0.76, 0.32), CFrame.new(0, -0.45, 0.34) * CFrame.Angles(math.rad(-10), 0, 0), Color3.fromRGB(33, 42, 39), Enum.Material.Plastic)
		for _, child in { receiver, barrel, stock, magazine, grip } do weld(model, handle, child) end
	else
		local barrel = part(model, "Barrel", Vector3.new(0.28, 0.28, 1.35), CFrame.new(0, 0.26, -0.7), Color3.fromRGB(130, 135, 129), Enum.Material.Metal)
		local grip = part(model, "Grip", Vector3.new(0.38, 0.78, 0.34), CFrame.new(0, -0.45, 0.05) * CFrame.Angles(math.rad(-12), 0, 0), Color3.fromRGB(44, 54, 52), Enum.Material.Plastic)
		weld(model, handle, barrel)
		weld(model, handle, grip)
	end

	local sightZ = weaponName == "Pistol" and -0.18 or -0.2
	if attributes.RedDotOwned then
		local sight = part(model, "RedDot", Vector3.new(0.16, 0.16, 0.32), CFrame.new(0, 0.45, sightZ), Color3.fromRGB(174, 47, 42), Enum.Material.Neon)
		weld(model, handle, sight)
	end
	if attributes.FlashlightOwned then
		local mountZ = weaponName == "Pistol" and -0.58 or -1.05
		local lightMount = part(model, "FlashlightMount", Vector3.new(0.36, 0.18, 0.36), CFrame.new(0, -0.02, mountZ), Color3.fromRGB(23, 25, 24), Enum.Material.Metal)
		local beam = Instance.new("SpotLight")
		beam.Name = "FlashlightBeam"
		beam.Angle = 54
		beam.Brightness = 2.4
		beam.Range = 34
		beam.Color = Color3.fromRGB(255, 235, 184)
		beam.Enabled = attributes.FlashlightOn == true
		beam.Face = Enum.NormalId.Front
		beam.Parent = lightMount
		weld(model, handle, lightMount)
	end

	model.PrimaryPart = handle
	model.Parent = character
	model:PivotTo(hand.CFrame * CFrame.new(0, -0.08, -0.72) * CFrame.Angles(math.rad(-90), 0, 0))
	weld(model, hand, handle)
end
function ModelService.SetFlashlight(character, enabled)
	local weapon = character and (character:FindFirstChild("ZurichWeapon") or character:FindFirstChild("ZurichPistol"))
	local mount = weapon and weapon:FindFirstChild("FlashlightMount")
	local beam = mount and mount:FindFirstChild("FlashlightBeam")
	if beam and beam:IsA("SpotLight") then beam.Enabled = enabled end
end

function ModelService.CreateTrader(parent, name, position, color)
	local model = Instance.new("Model")
	model.Name = name
	local root = part(model, "Root", Vector3.new(3, 4, 2), CFrame.new(position + Vector3.new(0, 2, 0)), color, Enum.Material.SmoothPlastic)
	local head = part(model, "Head", Vector3.new(2.2, 2.2, 2.2), CFrame.new(position + Vector3.new(0, 5.2, 0)), Color3.fromRGB(202, 146, 111), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	local sign = part(model, "Sign", Vector3.new(4.5, 1.2, 0.25), CFrame.new(position + Vector3.new(0, 7.2, 0)), Color3.fromRGB(22, 38, 45), Enum.Material.Wood)
	for _, child in { head, sign } do weld(model, root, child) end
	model.PrimaryPart = root
	model.Parent = parent
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then descendant.Anchored = true end
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "TradePrompt"
	prompt.ActionText = "Handeln"
	prompt.ObjectText = name
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = root
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "TraderLabel"
	billboard.Size = UDim2.fromOffset(180, 34)
	billboard.StudsOffset = Vector3.new(0, 2.2, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = sign
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Text = name .. "  ·  HANDEL"
	text.TextColor3 = Color3.fromRGB(242, 232, 207)
	text.TextStrokeTransparency = 0.35
	text.Font = Enum.Font.GothamBold
	text.TextScaled = true
	text.Parent = billboard
	return model
end

function ModelService.CreateLoot(parent, position, lootType, amount, color)
	local model = Instance.new("Model")
	model.Name = lootType
	model:SetAttribute("LootType", lootType)
	model:SetAttribute("Amount", amount)
	local root = part(model, "Root", Vector3.new(2.8, 1.5, 2.8), CFrame.new(position), color, Enum.Material.WoodPlanks)
	local accent = part(model, "Accent", Vector3.new(1.9, 0.25, 0.35), CFrame.new(position + Vector3.new(0, 0.8, -0.6)), Color3.fromRGB(236, 206, 132), Enum.Material.Neon)
	weld(model, root, accent)
	model.PrimaryPart = root
	model.Parent = parent
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then descendant.Anchored = true end
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "LootPrompt"
	prompt.ActionText = "Aufnehmen"
	prompt.ObjectText = lootType
	prompt.HoldDuration = 0.15
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = root
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 7
	light.Brightness = 0.45
	light.Parent = root
	return model
end

return ModelService
