local Lighting = game:GetService("Lighting")

local MapService = {}

local COLORS = {
	Road = Color3.fromRGB(38, 43, 51),
	RoadEdge = Color3.fromRGB(91, 97, 105),
	Sidewalk = Color3.fromRGB(160, 164, 164),
	Concrete = Color3.fromRGB(117, 123, 128),
	Glass = Color3.fromRGB(117, 204, 225),
	GlassDark = Color3.fromRGB(43, 95, 122),
	Grass = Color3.fromRGB(67, 137, 82),
	Trim = Color3.fromRGB(30, 37, 48),
	Yellow = Color3.fromRGB(255, 202, 68),
	Emergency = Color3.fromRGB(210, 61, 53),
}

local function part(parent, name, size, position, color, material, shape)
	local object = Instance.new("Part")
	object.Name = name
	object.Size = size
	object.Position = position
	object.Anchored = true
	object.Color = color
	object.Material = material or Enum.Material.Concrete
	object.TopSurface = Enum.SurfaceType.Smooth
	object.BottomSurface = Enum.SurfaceType.Smooth
	if shape then object.Shape = shape end
	object.Parent = parent
	return object
end

local function rotate(object, rotation)
	object.CFrame = object.CFrame * rotation
	return object
end

local function label(parent, text, position, size, color, face)
	local anchor = part(parent, text .. " Sign", size or Vector3.new(30, 7, 0.5), position, color or COLORS.Trim, Enum.Material.Metal)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face or Enum.NormalId.Front
	gui.LightInfluence = 0
	gui.Parent = anchor
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.fromScale(1, 1)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = text
	textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.GothamBold
	textLabel.Parent = gui
	return anchor
end

local function window(parent, name, position, size, color)
	return part(parent, name, size, position, color or COLORS.Glass, Enum.Material.Glass)
end

local function createTower(parent, name, position, size, wallColor, glassColor, floors)
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent
	part(model, "Tower Core", size, position, wallColor, Enum.Material.Concrete)
	part(model, "Tower Roof", Vector3.new(size.X + 4, 2, size.Z + 4), position + Vector3.new(0, size.Y / 2 + 1, 0), COLORS.Trim, Enum.Material.Metal)
	part(model, "Tower Crown", Vector3.new(size.X * 0.35, 8, size.Z * 0.35), position + Vector3.new(0, size.Y / 2 + 6, 0), COLORS.Trim, Enum.Material.Metal)
	for floor = 1, floors do
		local y = position.Y - size.Y / 2 + floor * (size.Y / (floors + 1))
		for column = -1, 1 do
			local x = position.X + column * size.X * 0.27
			window(model, "Front Window", Vector3.new(x, y, position.Z - size.Z / 2 - 0.35), Vector3.new(size.X * 0.19, size.Y * 0.075, 0.5), glassColor)
			window(model, "Rear Window", Vector3.new(x, y, position.Z + size.Z / 2 + 0.35), Vector3.new(size.X * 0.19, size.Y * 0.075, 0.5), glassColor)
		end
		for row = -1, 1 do
			local z = position.Z + row * size.Z * 0.27
			window(model, "Side Window", Vector3.new(position.X - size.X / 2 - 0.35, y, z), Vector3.new(0.5, size.Y * 0.075, size.Z * 0.19), glassColor)
			window(model, "Side Window", Vector3.new(position.X + size.X / 2 + 0.35, y, z), Vector3.new(0.5, size.Y * 0.075, size.Z * 0.19), glassColor)
		end
	end
	local frontFace = position.Z < 0 and Enum.NormalId.Back or Enum.NormalId.Front
	label(parent, name, position + Vector3.new(0, size.Y / 2 + 13, position.Z < 0 and size.Z / 2 + 1 or -size.Z / 2 - 1), Vector3.new(42, 7, 0.5), COLORS.Trim, frontFace)
	return model
end

local function createShop(parent, name, position, size, wallColor, signColor)
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent
	part(model, "Shop", size, position, wallColor, Enum.Material.Concrete)
	part(model, "Shop Roof", Vector3.new(size.X + 2, 1.5, size.Z + 2), position + Vector3.new(0, size.Y / 2 + 0.75, 0), COLORS.Trim, Enum.Material.Metal)
	window(model, "Shopfront Left", position + Vector3.new(-size.X * 0.27, 0, size.Z / 2 + 0.3), Vector3.new(size.X * 0.22, size.Y * 0.45, 0.5), COLORS.Glass)
	window(model, "Shopfront Right", position + Vector3.new(size.X * 0.27, 0, size.Z / 2 + 0.3), Vector3.new(size.X * 0.22, size.Y * 0.45, 0.5), COLORS.Glass)
	part(model, "Door", Vector3.new(size.X * 0.18, size.Y * 0.58, 0.6), position + Vector3.new(0, -1, size.Z / 2 + 0.5), COLORS.GlassDark, Enum.Material.Glass)
	part(model, "Awning", Vector3.new(size.X * 0.92, 1.4, 4), position + Vector3.new(0, size.Y * 0.15, size.Z / 2 + 2), signColor, Enum.Material.Neon)
	label(model, name, position + Vector3.new(0, size.Y * 0.28, size.Z / 2 + 2.5), Vector3.new(size.X * 0.78, 4, 0.4), signColor, Enum.NormalId.Back)
	return model
end

local function createStreetLamp(parent, position)
	part(parent, "Lamp Pole", Vector3.new(0.8, 13, 0.8), position + Vector3.new(0, 6.5, 0), COLORS.Trim, Enum.Material.Metal)
	part(parent, "Lamp Arm", Vector3.new(6, 0.5, 0.5), position + Vector3.new(2.5, 12.5, 0), COLORS.Trim, Enum.Material.Metal)
	local lamp = part(parent, "Lamp Glow", Vector3.new(2, 0.5, 2), position + Vector3.new(5, 12.1, 0), Color3.fromRGB(255, 236, 160), Enum.Material.Neon)
	local light = Instance.new("PointLight")
	light.Brightness = 0.9
	light.Range = 24
	light.Color = Color3.fromRGB(255, 218, 154)
	light.Parent = lamp
end

local function createTrafficLight(parent, position, rotation)
	local pole = part(parent, "Traffic Pole", Vector3.new(0.7, 12, 0.7), position + Vector3.new(0, 6, 0), COLORS.Trim, Enum.Material.Metal)
	rotate(pole, rotation or CFrame.Angles(0, 0, 0))
	part(parent, "Traffic Arm", Vector3.new(5, 0.6, 0.6), position + Vector3.new(2, 11, 0), COLORS.Trim, Enum.Material.Metal)
	local box = part(parent, "Traffic Signal", Vector3.new(1.8, 4.8, 1.4), position + Vector3.new(4.4, 8.8, 0), COLORS.Trim, Enum.Material.Metal)
	for index, color in ipairs({ Color3.fromRGB(226, 53, 52), COLORS.Yellow, Color3.fromRGB(47, 226, 101) }) do
		local light = part(box, "Signal", Vector3.new(0.85, 0.85, 0.18), box.Position + Vector3.new(0, 1.55 - (index - 1) * 1.55, -0.78), color, Enum.Material.Neon, Enum.PartType.Ball)
		light.CanCollide = false
	end
end

local function createCrosswalk(parent, center, horizontal)
	for index = -4, 4 do
		local size = horizontal and Vector3.new(4, 0.08, 22) or Vector3.new(22, 0.08, 4)
		local offset = horizontal and Vector3.new(index * 5, 0, 0) or Vector3.new(0, 0, index * 5)
		part(parent, "Crosswalk Stripe", size, center + offset + Vector3.new(0, 0.5, 0), Color3.fromRGB(239, 239, 230), Enum.Material.Concrete)
	end
end

local function createRoad(parent, name, center, length, horizontal)
	local roadSize = horizontal and Vector3.new(length, 0.35, 42) or Vector3.new(42, 0.35, length)
	part(parent, name, roadSize, center + Vector3.new(0, 0.15, 0), COLORS.Road, Enum.Material.Asphalt)
	local sidewalkSize = horizontal and Vector3.new(length, 0.5, 12) or Vector3.new(12, 0.5, length)
	local sideOffset = horizontal and Vector3.new(0, 0.35, 27) or Vector3.new(27, 0.35, 0)
	part(parent, "Sidewalk", sidewalkSize, center + sideOffset, COLORS.Sidewalk, Enum.Material.Concrete)
	part(parent, "Sidewalk", sidewalkSize, center - sideOffset, COLORS.Sidewalk, Enum.Material.Concrete)
	for offset = -length / 2 + 18, length / 2 - 18, 38 do
		local markSize = horizontal and Vector3.new(18, 0.08, 0.55) or Vector3.new(0.55, 0.08, 18)
		local markPosition = horizontal and center + Vector3.new(offset, 0.4, 0) or center + Vector3.new(0, 0.4, offset)
		part(parent, "Lane Marking", markSize, markPosition, Color3.fromRGB(245, 245, 238), Enum.Material.Neon)
	end
end

local function createPalm(parent, position)
	local trunk = part(parent, "Palm Trunk", Vector3.new(2.2, 15, 2.2), position + Vector3.new(0, 7.5, 0), Color3.fromRGB(126, 91, 57), Enum.Material.Wood, Enum.PartType.Cylinder)
	rotate(trunk, CFrame.Angles(0, 0, math.rad(-5)))
	for index = 0, 5 do
		local angle = math.rad(index * 60)
		local leaf = part(parent, "Palm Leaf", Vector3.new(1.4, 0.4, 8), position + Vector3.new(math.cos(angle) * 3.2, 15, math.sin(angle) * 3.2), Color3.fromRGB(52, 161, 83), Enum.Material.Grass)
		rotate(leaf, CFrame.Angles(0, -angle, math.rad(18)))
	end
end

local function createCar(parent, name, position, color, rotation)
	local car = Instance.new("Model")
	car.Name = name
	car.Parent = parent
	local body = part(car, "Body", Vector3.new(12, 2.4, 5.5), position + Vector3.new(0, 2, 0), color, Enum.Material.Metal)
	local cabin = part(car, "Cabin", Vector3.new(6.5, 2.2, 4.7), position + Vector3.new(0, 4, 0), color, Enum.Material.Metal)
	window(car, "Windshield", position + Vector3.new(0, 4.15, -2.42), Vector3.new(5.2, 1.5, 0.25), COLORS.GlassDark)
	window(car, "Rear Window", position + Vector3.new(0, 4.15, 2.42), Vector3.new(5.2, 1.5, 0.25), COLORS.GlassDark)
	for _, x in { -4.2, 4.2 } do
		for _, z in { -2.6, 2.6 } do
			local wheel = part(car, "Wheel", Vector3.new(1.5, 1.5, 1.1), position + Vector3.new(x, 1.25, z), Color3.fromRGB(18, 20, 22), Enum.Material.Rubber, Enum.PartType.Cylinder)
			rotate(wheel, CFrame.Angles(math.rad(90), 0, 0))
		end
	end
	if rotation then car:PivotTo(CFrame.new(position) * rotation) end
	return car
end

local function createPark(parent)
	local park = Instance.new("Model")
	park.Name = "CivicPark"
	park.Parent = parent
	part(park, "Park Lawn", Vector3.new(240, 0.6, 150), Vector3.new(290, 0.25, 315), COLORS.Grass, Enum.Material.Grass)
	part(park, "Sports Court", Vector3.new(130, 0.8, 78), Vector3.new(290, 0.8, 315), Color3.fromRGB(38, 112, 171), Enum.Material.SmoothPlastic)
	part(park, "Court Line", Vector3.new(4, 0.1, 78), Vector3.new(290, 1.25, 315), Color3.fromRGB(245, 245, 235), Enum.Material.Neon)
	part(park, "Court Line", Vector3.new(130, 0.1, 4), Vector3.new(290, 1.25, 315), Color3.fromRGB(245, 245, 235), Enum.Material.Neon)
	for _, x in { 225, 355 } do
		part(park, "Court Fence", Vector3.new(1, 10, 82), Vector3.new(x, 5, 315), COLORS.Trim, Enum.Material.Metal)
	end
	for _, z in { 274, 356 } do
		part(park, "Court Fence", Vector3.new(132, 10, 1), Vector3.new(290, 5, z), COLORS.Trim, Enum.Material.Metal)
	end
	part(park, "Bleachers", Vector3.new(38, 8, 10), Vector3.new(390, 4, 315), COLORS.Trim, Enum.Material.Metal)
	label(park, "CIVIC PARK", Vector3.new(290, 12, 240), Vector3.new(45, 8, 0.5), Color3.fromRGB(36, 102, 57))
	for _, position in { Vector3.new(190, 0, 250), Vector3.new(400, 0, 250), Vector3.new(190, 0, 380), Vector3.new(400, 0, 380) } do
		createPalm(park, position)
	end
end

local function createSubway(parent)
	local subway = Instance.new("Model")
	subway.Name = "SubwayStation"
	subway.Parent = parent
	local stationX = 0
	part(subway, "Platform", Vector3.new(120, 2, 230), Vector3.new(stationX, -18, 80), Color3.fromRGB(55, 61, 68), Enum.Material.Concrete)
	part(subway, "North Wall", Vector3.new(120, 25, 3), Vector3.new(stationX, -6, -35), COLORS.Trim, Enum.Material.Concrete)
	part(subway, "South Wall", Vector3.new(120, 25, 3), Vector3.new(stationX, -6, 195), COLORS.Trim, Enum.Material.Concrete)
	part(subway, "West Wall", Vector3.new(3, 25, 230), Vector3.new(-60, -6, 80), COLORS.Trim, Enum.Material.Concrete)
	part(subway, "East Wall", Vector3.new(3, 25, 230), Vector3.new(60, -6, 80), COLORS.Trim, Enum.Material.Concrete)
	part(subway, "Track A", Vector3.new(8, 1, 220), Vector3.new(-26, -16.5, 80), Color3.fromRGB(18, 21, 24), Enum.Material.Metal)
	part(subway, "Track B", Vector3.new(8, 1, 220), Vector3.new(26, -16.5, 80), Color3.fromRGB(18, 21, 24), Enum.Material.Metal)
	label(subway, "CENTRAL LINE 01", Vector3.new(0, -3, -33), Vector3.new(58, 8, 0.5), Color3.fromRGB(28, 113, 153))
	for step = 0, 9 do
		part(subway, "Station Stair", Vector3.new(32, 2, 8), Vector3.new(0, -step * 2, 204 - step * 6), Color3.fromRGB(133, 136, 133), Enum.Material.Concrete)
	end
	local entrance = part(subway, "Station Entrance", Vector3.new(52, 1, 45), Vector3.new(0, 0.5, 230), Color3.fromRGB(54, 69, 77), Enum.Material.Glass)
	entrance.Transparency = 0.35
	entrance.CanCollide = false
	label(parent, "METRO 01", Vector3.new(0, 10, 227), Vector3.new(48, 9, 0.5), Color3.fromRGB(27, 113, 166))
	for _, position in { Vector3.new(-45, -10, 25), Vector3.new(45, -10, 85), Vector3.new(-45, -10, 145) } do
		part(subway, "Platform Pillar", Vector3.new(4, 20, 4), position, Color3.fromRGB(77, 83, 91), Enum.Material.Concrete)
		local lamp = part(subway, "Station Light", Vector3.new(2, 0.4, 2), position + Vector3.new(0, 10, 0), Color3.fromRGB(159, 229, 255), Enum.Material.Neon)
		local pointLight = Instance.new("PointLight")
		pointLight.Brightness = 1.1
		pointLight.Range = 16
		pointLight.Color = Color3.fromRGB(141, 218, 255)
		pointLight.Parent = lamp
	end
end

local function createLighting()
	Lighting.ClockTime = 14
	Lighting.Brightness = 2.4
	Lighting.Ambient = Color3.fromRGB(145, 165, 181)
	Lighting.OutdoorAmbient = Color3.fromRGB(128, 153, 178)
	Lighting.Technology = Enum.Technology.Future
	for _, child in Lighting:GetChildren() do
		if child.Name == "CityAtmosphere" or child.Name == "CityColor" then child:Destroy() end
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

function MapService.Create()
	local old = workspace:FindFirstChild("SurvivalMap")
	if old then old:Destroy() end
	local map = Instance.new("Folder")
	map.Name = "SurvivalMap"
	map.Parent = workspace
	createLighting()

	local ground = Color3.fromRGB(83, 104, 91)
	part(map, "Ground North", Vector3.new(1000, 2, 500), Vector3.new(0, -1, -150), ground, Enum.Material.Grass)
	part(map, "Ground South", Vector3.new(1000, 2, 240), Vector3.new(0, -1, 380), ground, Enum.Material.Grass)
	part(map, "Ground West", Vector3.new(430, 2, 160), Vector3.new(-285, -1, 180), ground, Enum.Material.Grass)
	part(map, "Ground East", Vector3.new(430, 2, 160), Vector3.new(285, -1, 180), ground, Enum.Material.Grass)

	createRoad(map, "Main Boulevard", Vector3.new(0, 0, 0), 1000, true)
	createRoad(map, "Central Avenue", Vector3.new(0, 0, 0), 1000, false)
	createRoad(map, "North Boulevard", Vector3.new(0, 0, -280), 1000, true)
	createRoad(map, "South Boulevard", Vector3.new(0, 0, 420), 1000, true)
	createRoad(map, "West Avenue", Vector3.new(-360, 0, 130), 520, false)
	createRoad(map, "East Avenue", Vector3.new(360, 0, 130), 520, false)
	createCrosswalk(map, Vector3.new(0, 0, -27), true)
	createCrosswalk(map, Vector3.new(-27, 0, 0), false)
	for _, position in { Vector3.new(-34, 0, -34), Vector3.new(34, 0, -34), Vector3.new(-34, 0, 34), Vector3.new(34, 0, 34) } do
		createTrafficLight(map, position)
	end

	createTower(map, "NOVA TOWER", Vector3.new(-300, 42, -345), Vector3.new(100, 84, 86), Color3.fromRGB(77, 91, 110), COLORS.Glass, 8)
	createTower(map, "SKYLINE ONE", Vector3.new(285, 50, -345), Vector3.new(118, 100, 92), Color3.fromRGB(96, 102, 113), COLORS.GlassDark, 9)
	createTower(map, "RIVERGLASS", Vector3.new(390, 35, 40), Vector3.new(100, 70, 76), Color3.fromRGB(73, 105, 114), COLORS.Glass, 7)
	createShop(map, "GROCERY", Vector3.new(-250, 12, -85), Vector3.new(100, 24, 54), Color3.fromRGB(217, 216, 199), Color3.fromRGB(31, 170, 191))
	createShop(map, "CAFE", Vector3.new(-100, 10, -85), Vector3.new(82, 20, 54), Color3.fromRGB(226, 188, 145), Color3.fromRGB(235, 116, 61))
	createShop(map, "ARCADE", Vector3.new(105, 11, -85), Vector3.new(98, 22, 54), Color3.fromRGB(108, 77, 138), Color3.fromRGB(228, 68, 207))
	createShop(map, "PHARMACY", Vector3.new(245, 11, -85), Vector3.new(100, 22, 54), Color3.fromRGB(224, 232, 222), Color3.fromRGB(40, 185, 109))
	createShop(map, "FIRE RESCUE", Vector3.new(-450, 12, 220), Vector3.new(90, 24, 70), Color3.fromRGB(181, 71, 63), COLORS.Emergency)
	createShop(map, "MOTEL", Vector3.new(450, 13, 235), Vector3.new(90, 26, 72), Color3.fromRGB(152, 107, 96), Color3.fromRGB(246, 178, 64))
	createPark(map)
	createSubway(map)

	for _, position in {
		Vector3.new(-430, 0, -35), Vector3.new(-330, 0, -35), Vector3.new(-230, 0, -35), Vector3.new(230, 0, -35), Vector3.new(330, 0, -35), Vector3.new(430, 0, -35),
		Vector3.new(-430, 0, 35), Vector3.new(-330, 0, 35), Vector3.new(230, 0, 35), Vector3.new(330, 0, 35), Vector3.new(430, 0, 35),
	} do
		createPalm(map, position)
		createStreetLamp(map, position + Vector3.new(0, 0, position.Z > 0 and 13 or -13))
	end

	createCar(map, "Abandoned Sedan", Vector3.new(-170, 0, 42), Color3.fromRGB(184, 52, 48), CFrame.Angles(0, math.rad(90), 0))
	createCar(map, "Abandoned Taxi", Vector3.new(160, 0, -42), COLORS.Yellow, CFrame.Angles(0, math.rad(-90), 0))
	createCar(map, "Police Cruiser", Vector3.new(375, 0, 170), Color3.fromRGB(39, 56, 87), CFrame.Angles(0, math.rad(180), 0))

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SafehouseSpawn"
	spawn.Size = Vector3.new(14, 1, 14)
	spawn.Position = Vector3.new(-420, 1, -340)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Color = Color3.fromRGB(54, 203, 111)
	spawn.Material = Enum.Material.Neon
	spawn.Parent = map
	label(map, "SAFEHOUSE", Vector3.new(-420, 9, -350), Vector3.new(42, 8, 0.5), Color3.fromRGB(37, 127, 70))
	return map
end

return MapService
