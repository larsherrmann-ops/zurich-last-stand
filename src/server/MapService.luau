local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ModelService = require(script.Parent.ModelService)

local MapService = {}

local FALLBACK_SPAWNS = {
	Vector3.new(0, 2, 0),
	Vector3.new(80, 2, 80),
	Vector3.new(-80, 2, 80),
	Vector3.new(80, 2, -80),
	Vector3.new(-80, 2, -80),
}

local function createPoint(parent, name, position)
	local point = Instance.new("Part")
	point.Name = name
	point.Size = Vector3.new(1, 1, 1)
	point.Position = position
	point.Anchored = true
	point.Transparency = 1
	point.CanCollide = false
	point.CanTouch = false
	point.CanQuery = false
	point.Parent = parent
	return point
end

local function createLighting()
	Lighting.ClockTime = 14
	Lighting.Brightness = 2.4
	Lighting.Ambient = Color3.fromRGB(145, 165, 181)
	Lighting.OutdoorAmbient = Color3.fromRGB(128, 153, 178)
	for _, child in Lighting:GetChildren() do
		if child.Name == "CityAtmosphere" or child.Name == "CityColor" then
			child:Destroy()
		end
	end
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "CityAtmosphere"
	atmosphere.Density = 0.22
	atmosphere.Offset = 0.25
	atmosphere.Color = Color3.fromRGB(189, 218, 236)
	atmosphere.Decay = Color3.fromRGB(103, 130, 158)
	atmosphere.Glare = 0.15
	atmosphere.Haze = 0.7
	atmosphere.Parent = Lighting
	local color = Instance.new("ColorCorrectionEffect")
	color.Name = "CityColor"
	color.Brightness = 0.03
	color.Contrast = 0.12
	color.Saturation = 0.18
	color.Parent = Lighting
end

local function collectSpawnPositions(world)
	local positions = {}
	if world then
		for _, object in world:GetDescendants() do
			if object:IsA("SpawnLocation") then
				table.insert(positions, object.Position + Vector3.new(0, 2, 0))
			end
		end
	end
	if #positions == 0 then
		for _, position in FALLBACK_SPAWNS do
			table.insert(positions, position)
		end
	end
	return positions
end

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

local function isDoorName(name)
	local lower = string.lower(name)
	local hasDoor = string.find(lower, "door", 1, true) ~= nil or string.find(lower, "screen", 1, true) ~= nil
	local isNumber = string.find(lower, "number", 1, true) ~= nil
	return hasDoor and not isNumber
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

function MapService.BreakWindow(target)
	local window = target
	while window and window ~= workspace do
		if window:GetAttribute("ZurichBreakableWindow") then break end
		window = window.Parent
	end
	if not window or not window:GetAttribute("ZurichBreakableWindow") then return false end
	if window:GetAttribute("ZurichBroken") then return true end
	window:SetAttribute("ZurichBroken", true)
	if window:IsA("BasePart") then
		window.CanCollide = false
		window.CanQuery = false
		window.Transparency = 1
	end
	for _, object in window:GetDescendants() do
		if object:IsA("BasePart") then
			object.CanCollide = false
			object.CanQuery = false
			object.Transparency = 1
		end
		if object:IsA("ProximityPrompt") and object.Name == "ZurichWindowPrompt" then
			object.Enabled = false
		end
	end
	return true
end

local function configureDoor(promptParent, parts, locked)
	if not promptParent or #parts == 0 or promptParent:FindFirstChild("ZurichDoorPrompt") then return false end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ZurichDoorPrompt"
	prompt.ActionText = locked and "Verschlossen" or "Öffnen"
	prompt.ObjectText = locked and "Wichtiger Eingang" or "Haus-/Ladentür"
	prompt.HoldDuration = 0.15
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = promptParent

	if locked then
		prompt.Triggered:Connect(function(player)
			notify(player, "EINGANG VERRIEGELT  ·  FENSTER EINSCHLAGEN", "Info")
		end)
		return true
	end

	local original = {}
	for _, part in parts do
		original[part] = {
			CanCollide = part.CanCollide,
			Transparency = part.Transparency,
		}
	end
	local open = false
	prompt.Triggered:Connect(function()
		open = not open
		for part, state in original do
			if part.Parent then
				part.CanCollide = open and false or state.CanCollide
				part.Transparency = open and math.max(state.Transparency, 0.35) or state.Transparency
			end
		end
		prompt.ActionText = open and "Schließen" or "Öffnen"
	end)
	return true
end

local function configureDoors(world)
	if not world then return end
	local configured = 0
	local configuredModels = {}
	for _, object in world:GetDescendants() do
		if object:IsA("Model") and isDoorName(object.Name) then
			local parent = object.Parent
			local nestedDoor = false
			while parent and parent ~= world do
				if parent:IsA("Model") and isDoorName(parent.Name) then
					nestedDoor = true
					break
				end
				parent = parent.Parent
			end
			if not nestedDoor then
				local root = object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart", true)
				local parts = {}
				for _, part in object:GetDescendants() do
					if part:IsA("BasePart") then table.insert(parts, part) end
				end
				local locked = findLockedBuilding(object) ~= nil
				if root and #parts > 0 and configureDoor(root, parts, locked) then
					configuredModels[object] = true
					configured += 1
				end
			end
		end
	end

	for _, object in world:GetDescendants() do
		if object:IsA("BasePart") and isDoorName(object.Name) then
			local parentModel = object:FindFirstAncestorOfClass("Model")
			if not parentModel or not configuredModels[parentModel] then
				if configureDoor(object, { object }, findLockedBuilding(object) ~= nil) then configured += 1 end
			end
		end
	end
	if configured > 0 then
		print("ZurichLastStand: configured " .. configured .. " interactive doors")
	end
end

local function configureBreakableWindows(world)
	if not world then return end
	local configured = 0
	for _, object in world:GetDescendants() do
		if object:IsA("Model") and string.lower(object.Name) == "window" and findLockedBuilding(object) then
			local root = object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart", true)
			if root and not root:FindFirstChild("ZurichWindowPrompt") then
				object:SetAttribute("ZurichBreakableWindow", true)
				local parts = {}
				for _, part in object:GetDescendants() do
					if part:IsA("BasePart") then
						part:SetAttribute("ZurichBreakableWindow", true)
						table.insert(parts, part)
					end
				end
				local prompt = Instance.new("ProximityPrompt")
				prompt.Name = "ZurichWindowPrompt"
				prompt.ActionText = "Einschlagen"
				prompt.ObjectText = "Verriegeltes Fenster"
				prompt.HoldDuration = 0.35
				prompt.MaxActivationDistance = 8
				prompt.RequiresLineOfSight = false
				prompt.Parent = root
				prompt.Triggered:Connect(function(player)
					if MapService.BreakWindow(object) then
						notify(player, "FENSTER ZERBROCHEN  ·  ZUGANG OFFEN", "Success")
					end
				end)
				configured += 1
			end
		end
	end
	if configured > 0 then
		print("ZurichLastStand: configured " .. configured .. " breakable windows")
	end
end
local function createRuntimeObjects(map, world, positions)
	map:SetAttribute("MapSource", "FREE Bronx River City Roblox Realistic Roleplay Map")
	map:SetAttribute("MapEditable", true)

	local zombieSpawns = Instance.new("Folder")
	zombieSpawns.Name = "ZombieSpawns"
	zombieSpawns.Parent = map
	local spawnOffsets = {
		Vector3.new(52, 0, 0),
		Vector3.new(-52, 0, 0),
		Vector3.new(0, 0, 52),
		Vector3.new(0, 0, -52),
		Vector3.new(38, 0, 38),
	}
	for index, position in positions do
		local offset = spawnOffsets[((index - 1) % #spawnOffsets) + 1]
		createPoint(zombieSpawns, "Spawn" .. index, position + offset)
	end

	local lootPoints = Instance.new("Folder")
	lootPoints.Name = "LootPoints"
	lootPoints.Parent = map
	local lootDefinitions = {
		{ "Ammo", 12 },
		{ "Materials", 5 },
		{ "Medkit", 1 },
		{ "Cash", 80 },
		{ "BackpackScout", 1 },
		{ "RedDot", 1 },
		{ "Flashlight", 1 },
	}
	for index, loot in lootDefinitions do
		local position = positions[((index - 1) % #positions) + 1]
		local offset = Vector3.new((index % 3) * 8 - 8, 0, math.floor(index / 3) * 8)
		local point = createPoint(lootPoints, "LootPoint" .. index, position + offset)
		point:SetAttribute("LootType", loot[1])
		point:SetAttribute("Amount", loot[2])
	end

	local traders = Instance.new("Folder")
	traders.Name = "Traders"
	traders.Parent = map
	local traderPositions = {
		positions[1] + Vector3.new(12, 0, 0),
		positions[math.min(2, #positions)] + Vector3.new(-12, 0, 0),
	}
	ModelService.CreateTrader(traders, "Marta  ·  Bronx-Händlerin", traderPositions[1], Color3.fromRGB(137, 57, 49))
	ModelService.CreateTrader(traders, "Noah  ·  River-Händler", traderPositions[2], Color3.fromRGB(48, 86, 103))

	local safehouse = createPoint(map, "SafehouseSpawn", positions[1])
	safehouse:SetAttribute("Description", "Startpunkt in der Bronx River City")
	configureDoors(world)
	configureBreakableWindows(world)
end

local function createFallbackWorld(map)
	local ground = Instance.new("Part")
	ground.Name = "FallbackGround"
	ground.Size = Vector3.new(600, 2, 600)
	ground.Position = Vector3.new(0, -1, 0)
	ground.Anchored = true
	ground.Material = Enum.Material.Asphalt
	ground.Color = Color3.fromRGB(55, 62, 68)
	ground.Parent = map
end

function MapService.Create()
	createLighting()
	local old = workspace:FindFirstChild("ZurichMap")
	if old then old:Destroy() end

	local world = workspace:FindFirstChild("World")
	local map = Instance.new("Folder")
	map.Name = "ZurichMap"
	map.Parent = workspace
	local positions = collectSpawnPositions(world)
	if not world then
		warn("ZurichLastStand: Bronx River City base place is not open; using fallback ground")
		createFallbackWorld(map)
	end
	createRuntimeObjects(map, world, positions)
	return map
end

return MapService