local ModelService = require(script.Parent.ModelService)

local MapService = {}

local function part(parent, name, size, position, color, material)
	local object = Instance.new("Part")
	object.Name = name
	object.Size = size
	object.Position = position
	object.Anchored = true
	object.Color = color
	object.Material = material or Enum.Material.Concrete
	object.TopSurface = Enum.SurfaceType.Smooth
	object.BottomSurface = Enum.SurfaceType.Smooth
	object.Parent = parent
	return object
end

local function label(parent, text, position)
	local anchor = part(parent, text, Vector3.new(22, 9, 1), position, Color3.fromRGB(35, 42, 39))
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.Parent = anchor
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.fromScale(1, 1)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = text
	textLabel.TextColor3 = Color3.fromRGB(235, 238, 226)
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.GothamBold
	textLabel.Parent = gui
end

function MapService.Create()
	local old = workspace:FindFirstChild("ZurichMap")
	if old then old:Destroy() end
	local map = Instance.new("Folder")
	map.Name = "ZurichMap"
	map.Parent = workspace

	part(map, "Ground", Vector3.new(700, 2, 700), Vector3.new(0, -1, 0), Color3.fromRGB(61, 72, 61), Enum.Material.Asphalt)
	part(map, "Zurichsee", Vector3.new(210, 1, 700), Vector3.new(245, 0.2, 0), Color3.fromRGB(30, 94, 132), Enum.Material.Water).CanCollide = false
	for x = -270, 150, 105 do
		part(map, "Road", Vector3.new(28, 0.4, 700), Vector3.new(x, 0.2, 0), Color3.fromRGB(57, 59, 60), Enum.Material.Asphalt)
	end
	for z = -280, 280, 95 do
		part(map, "Road", Vector3.new(530, 0.45, 25), Vector3.new(-35, 0.25, z), Color3.fromRGB(57, 59, 60), Enum.Material.Asphalt)
	end

	local locations = {
		{ "ZÜRICH HB", Vector3.new(-215, 16, -185), Color3.fromRGB(120, 126, 122) },
		{ "BAHNHOFSTRASSE", Vector3.new(-80, 16, -80), Color3.fromRGB(108, 105, 96) },
		{ "LANGSTRASSE", Vector3.new(-215, 16, 105), Color3.fromRGB(111, 91, 85) },
		{ "ETH", Vector3.new(70, 16, -205), Color3.fromRGB(119, 115, 102) },
		{ "BELLEVUE", Vector3.new(90, 16, 125), Color3.fromRGB(100, 109, 104) },
	}
	for _, location in locations do
		part(map, location[1] .. " Building", Vector3.new(65, 30, 55), location[2], location[3])
		label(map, location[1], location[2] + Vector3.new(0, 10, 28))
	end

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "HBSpawn"
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.Position = Vector3.new(-145, 1, -185)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Color = Color3.fromRGB(78, 163, 93)
	spawn.Parent = map

	local points = Instance.new("Folder")
	points.Name = "ZombieSpawns"
	points.Parent = map
	for index, position in {
		Vector3.new(-310, 2, -310), Vector3.new(160, 2, -300), Vector3.new(-300, 2, 300),
		Vector3.new(155, 2, 295), Vector3.new(-300, 2, 0), Vector3.new(155, 2, 0),
	} do
		local point = part(points, "Spawn" .. index, Vector3.one, position, Color3.new(1, 0, 0))
		point.Transparency = 1
		point.CanCollide = false
	end

	local traders = Instance.new("Folder")
	traders.Name = "Traders"
	traders.Parent = map
	ModelService.CreateTrader(traders, "Marta  ·  HB-Händlerin", Vector3.new(-145, 1, -225), Color3.fromRGB(137, 57, 49))
	ModelService.CreateTrader(traders, "Noah  ·  Bellevue-Händler", Vector3.new(92, 1, 160), Color3.fromRGB(48, 86, 103))
	return map
end

return MapService
