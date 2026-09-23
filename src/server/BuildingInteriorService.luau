local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local settings = Config.Buildings
local Service = {}

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

local LOCKED_BUILDINGS = {
	["tall apartments"] = true,
	["apartment building"] = true,
	["ramombuilding"] = true,
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

local function findBuilding(doorObject, world)
	local parent = doorObject.Parent
	local candidate
	while parent and parent ~= world do
		if parent:IsA("Model") and isBuildingName(parent.Name) and countBuildingParts(parent) >= 20 then
			candidate = parent
		end
		parent = parent.Parent
	end
	return candidate
end

local function createPart(parent, name, size, cframe, color, material, transparency)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Anchored = true
	part.CanCollide = true
	part.CanTouch = false
	part.CanQuery = true
	part.Color = color
	part.Material = material
	part.Transparency = transparency or 0
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function getDoorBounds(doorObject)
	if doorObject:IsA("Model") then
		return doorObject:GetBoundingBox()
	end
	return doorObject.CFrame, doorObject.Size
end

local function getRoomDirections(building, doorCFrame)
	local boundsCFrame = building:GetBoundingBox()
	local inward = Vector3.new(
		boundsCFrame.Position.X - doorCFrame.Position.X,
		0,
		boundsCFrame.Position.Z - doorCFrame.Position.Z
	)
	if inward.Magnitude < 1 then
		inward = Vector3.new(-doorCFrame.LookVector.X, 0, -doorCFrame.LookVector.Z)
	end
	if inward.Magnitude < 0.1 then inward = Vector3.new(0, 0, 1) end
	inward = inward.Unit
	return inward, -inward
end

local function hasInteriorFloorAtDoor(building, doorCFrame, doorSize)
	local boundsCFrame, boundsSize = building:GetBoundingBox()
	local inward = getRoomDirections(building, doorCFrame)
	local right = Vector3.new(doorCFrame.RightVector.X, 0, doorCFrame.RightVector.Z)
	if right.Magnitude < 0.1 then right = Vector3.new(1, 0, 0) end
	right = right.Unit

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { building }
	params.IgnoreWater = true

	local depth = math.max(4, math.min(boundsSize.X, boundsSize.Z) * 0.08)
	local halfWidth = math.clamp(math.max(doorSize.X, doorSize.Z) * 0.25, 1.2, 3.5)
	local floorY = doorCFrame.Position.Y - math.max(doorSize.Y, 4) * 0.5 + 0.5
	for _, offset in { -halfWidth, 0, halfWidth } do
		local start = doorCFrame.Position
			+ inward * depth
			+ right * offset
			+ Vector3.new(0, 9, 0)
		local hit = workspace:Raycast(start, Vector3.new(0, -18, 0), params)
		if hit
			and math.abs(hit.Normal.Y) >= 0.65
			and hit.Position.Y >= floorY - 2
			and hit.Position.Y <= floorY + 3 then
			return true
		end
	end
	return false
end

local function createDoorwayInterior(building, doorObject, folder)
	if doorObject:GetAttribute("ZurichFallbackInteriorCreated") then return false end

	local doorCFrame, doorSize = getDoorBounds(doorObject)
	local inward, outward = getRoomDirections(building, doorCFrame)
	local roomWidth = math.clamp(math.max(doorSize.X, doorSize.Z) * 2.4, 10, 18)
	local roomDepth = math.clamp(math.max(doorSize.Y * 1.8, 12), 12, 20)
	local roomHeight = 8
	local floorY = doorCFrame.Position.Y - math.max(doorSize.Y, 4) * 0.5 + 0.2
	local roomCenter = doorCFrame.Position + inward * (roomDepth * 0.5)
	roomCenter = Vector3.new(roomCenter.X, floorY + roomHeight * 0.5, roomCenter.Z)
	local roomFrame = CFrame.lookAt(roomCenter, roomCenter + outward, Vector3.new(0, 1, 0))

	local room = Instance.new("Model")
	room.Name = "InteriorDoorway_" .. building.Name .. "_" .. tostring(#folder:GetChildren() + 1)
	room:SetAttribute("ZurichGeneratedInterior", true)
	room:SetAttribute("ZurichFallbackFor", building.Name)
	room.Parent = folder

	local wallColor = Color3.fromRGB(88, 91, 96)
	local floorColor = Color3.fromRGB(132, 104, 78)
	createPart(room, "Floor", Vector3.new(roomWidth, 0.4, roomDepth),
		roomFrame * CFrame.new(0, -roomHeight * 0.5, 0), floorColor, Enum.Material.WoodPlanks)
	createPart(room, "Ceiling", Vector3.new(roomWidth, 0.35, roomDepth),
		roomFrame * CFrame.new(0, roomHeight * 0.5, 0), wallColor, Enum.Material.Concrete)
	createPart(room, "LeftWall", Vector3.new(0.35, roomHeight, roomDepth),
		roomFrame * CFrame.new(-roomWidth * 0.5, 0, 0), wallColor, Enum.Material.Concrete)
	createPart(room, "RightWall", Vector3.new(0.35, roomHeight, roomDepth),
		roomFrame * CFrame.new(roomWidth * 0.5, 0, 0), wallColor, Enum.Material.Concrete)
	createPart(room, "BackWall", Vector3.new(roomWidth, roomHeight, 0.35),
		roomFrame * CFrame.new(0, 0, -roomDepth * 0.5), wallColor, Enum.Material.Concrete)

	local exitPosition = roomCenter - outward * (roomDepth * 0.5 - 2)
	local exitCFrame = CFrame.lookAt(exitPosition, exitPosition + outward, Vector3.new(0, 1, 0))
	local outsidePosition = Vector3.new(
		doorCFrame.Position.X + outward.X * 3,
		floorY + 3,
		doorCFrame.Position.Z + outward.Z * 3
	)

	local exitPart = Instance.new("Part")
	exitPart.Name = "InteriorExit"
	exitPart.Size = Vector3.new(4, 5, 1)
	exitPart.CFrame = exitCFrame
	exitPart.Transparency = 1
	exitPart.Anchored = true
	exitPart.CanCollide = false
	exitPart.CanTouch = false
	exitPart.CanQuery = false
	exitPart.Parent = room

	local exitPrompt = Instance.new("ProximityPrompt")
	exitPrompt.Name = "ZurichInteriorExitPrompt"
	exitPrompt.ActionText = "Hinausgehen"
	exitPrompt.ObjectText = "Ausgang"
	exitPrompt.HoldDuration = 0.15
	exitPrompt.MaxActivationDistance = settings.InteractionDistance
	exitPrompt.RequiresLineOfSight = false
	exitPrompt.Parent = exitPart
	exitPrompt.Triggered:Connect(function(player)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root then
			root.CFrame = CFrame.lookAt(outsidePosition, outsidePosition + outward, Vector3.new(0, 1, 0))
		end
	end)

	local light = Instance.new("PointLight")
	light.Name = "InteriorLight"
	light.Brightness = 1.4
	light.Range = 16
	light.Color = Color3.fromRGB(255, 220, 170)
	light.Parent = exitPart

	doorObject:SetAttribute("ZurichFallbackInteriorCreated", true)
	return true
end

function Service.Prepare(world)
	if not world then return end
	local oldFolder = world:FindFirstChild("GeneratedBuildingInteriors")
	if oldFolder then oldFolder:Destroy() end

	local folder = Instance.new("Folder")
	folder.Name = "GeneratedBuildingInteriors"
	folder.Parent = world
	local generated = 0
	local seenDoors = {}

	for _, object in world:GetDescendants() do
		if object:GetAttribute("ZurichDoorConfigured") and not seenDoors[object] then
			seenDoors[object] = true
			local building = findBuilding(object, world)
			if building and not LOCKED_BUILDINGS[string.lower(building.Name)] then
				local doorCFrame, doorSize = getDoorBounds(object)
				if not hasInteriorFloorAtDoor(building, doorCFrame, doorSize)
					and createDoorwayInterior(building, object, folder) then
					generated += 1
				end
			end
		end
	end

	if generated > 0 then
		print("ZurichLastStand: generated " .. generated .. " accessible building shells with floors")
	end
end

return Service
