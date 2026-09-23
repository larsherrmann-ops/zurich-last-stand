local Lighting = game:GetService("Lighting")
local ModelService = require(script.Parent.ModelService)
local BuildingInteriorService = require(script.Parent.BuildingInteriorService)
local BuildingInteractionService = require(script.Parent.BuildingInteractionService)

local MapService = {}
MapService.DamageWindow = BuildingInteractionService.DamageWindow

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


local BUILDING_NAME_HINTS = {
	"house",
	"building",
	"apartment",
	"store",
	"shop",
	"streetstores",
	"wingstop",
	"corner store",
	"ramom",
	"random building",
}

local function isBuildingName(name)
	local lower = string.lower(name)
	if string.find(lower, "rack", 1, true)
		or string.find(lower, "cover", 1, true)
		or string.find(lower, "door", 1, true)
		or string.find(lower, "window", 1, true) then
		return false
	end
	for _, hint in BUILDING_NAME_HINTS do
		if string.find(lower, hint, 1, true) then return true end
	end
	return false
end

local function countBuildingParts(building)
	local count = 0
	for _, object in building:GetDescendants() do
		if object:IsA("BasePart") then count += 1 end
	end
	return count
end

local function configureHighRiskBuildings(map, world)
	if not map or not world then return end
	local lootFolder = Instance.new("Folder")
	lootFolder.Name = "HighRiskLootPoints"
	lootFolder.Parent = map
	local zombieFolder = Instance.new("Folder")
	zombieFolder.Name = "HighRiskZombieSpawns"
	zombieFolder.Parent = map

	local configured = 0
	local buildings = {}
	for _, object in world:GetDescendants() do
		if object:IsA("Model") and isBuildingName(object.Name) and countBuildingParts(object) >= 20 then
			local nestedBuilding = false
			local parent = object.Parent
			while parent and parent ~= world do
				if parent:IsA("Model") and isBuildingName(parent.Name) then
					nestedBuilding = true
					break
				end
				parent = parent.Parent
			end
			if not nestedBuilding then table.insert(buildings, object) end
		end
	end

	for _, building in buildings do
		local partCount = countBuildingParts(building)
		local lower = string.lower(building.Name)
		local namedLarge = string.find(lower, "apartment", 1, true)
			or string.find(lower, "streetstores", 1, true)
			or string.find(lower, "ramom", 1, true)
			or string.find(lower, "wingstop", 1, true)
			or string.find(lower, "building", 1, true)
		if partCount >= 90 or namedLarge then
			local boundsCFrame, boundsSize = building:GetBoundingBox()
			local floorY = math.max(-1, boundsCFrame.Position.Y - boundsSize.Y * 0.5 + 2.8)
			local xStep = math.max(2, math.min(boundsSize.X * 0.22, 18))
			local zStep = math.max(2, math.min(boundsSize.Z * 0.22, 18))
			building:SetAttribute("ZurichHighRisk", true)
			building:SetAttribute("ZurichLootTier", "High")
			building:SetAttribute("ZurichZombieDensity", 2)

			local lootCount = math.clamp(math.floor(partCount / 80), 3, 8)
			for index = 1, lootCount do
				local column = (index - 1) % 3 - 1
				local row = math.floor((index - 1) / 3) % 3 - 1
				local localPosition = Vector3.new(column * xStep, floorY - boundsCFrame.Position.Y, row * zStep)
				local point = createPoint(lootFolder, "HighLoot_" .. configured .. "_" .. index, boundsCFrame:PointToWorldSpace(localPosition))
				point:SetAttribute("HighRisk", true)
				point:SetAttribute("LootTier", "High")
				point:SetAttribute("BuildingName", building.Name)
			end

			local zombieCount = math.clamp(math.floor(partCount / 55), 5, 12)
			for index = 1, zombieCount do
				local column = (index - 1) % 4 - 1.5
				local row = math.floor((index - 1) / 4) % 3 - 1
				local localPosition = Vector3.new(column * xStep, floorY - boundsCFrame.Position.Y, row * zStep)
				local point = createPoint(zombieFolder, "HighZombie_" .. configured .. "_" .. index, boundsCFrame:PointToWorldSpace(localPosition))
				point:SetAttribute("HighRisk", true)
				point:SetAttribute("BuildingName", building.Name)
			end
			configured += 1
		end
	end

	if configured > 0 then
		print("ZurichLastStand: marked " .. configured .. " high-risk buildings with premium loot and dense zombie spawns")
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
	BuildingInteractionService.Configure(world)
	BuildingInteriorService.Prepare(world)
	configureHighRiskBuildings(map, world)
end

local function createCityGround(map)
	local ground = Instance.new("Part")
	ground.Name = "CityGround"
	ground.Size = Vector3.new(2400, 1, 2400)
	ground.Position = Vector3.new(0, -0.55, 0)
	ground.Anchored = true
	ground.Material = Enum.Material.Concrete
	ground.Color = Color3.fromRGB(76, 81, 86)
	ground.TopSurface = Enum.SurfaceType.Smooth
	ground.BottomSurface = Enum.SurfaceType.Smooth
	ground.Parent = map
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
	else
		createCityGround(map)
	end
	createRuntimeObjects(map, world, positions)
	return map
end

return MapService
