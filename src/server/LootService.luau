local ModelService = require(script.Parent.ModelService)

local LootService = {}

local COLORS = {
	Ammo = Color3.fromRGB(255, 201, 87),
	Materials = Color3.fromRGB(171, 119, 70),
	Medkit = Color3.fromRGB(222, 65, 65),
	Cash = Color3.fromRGB(88, 178, 108),
	BackpackScout = Color3.fromRGB(59, 113, 78),
	RedDot = Color3.fromRGB(185, 50, 47),
	Flashlight = Color3.fromRGB(220, 195, 100),
}

local function createLoot(parent, position, lootType, amount, onLoot)
	local item = ModelService.CreateLoot(parent, position, lootType, amount, COLORS[lootType] or Color3.fromRGB(200, 200, 200))
	local prompt = item.PrimaryPart and item.PrimaryPart:FindFirstChild("LootPrompt")
	local taken = false
	if prompt and prompt:IsA("ProximityPrompt") then
		prompt.Triggered:Connect(function(player)
			if taken then return end
			taken = true
			if onLoot then onLoot(player, lootType, amount) end
			item:Destroy()
		end)
	end
end

function LootService.Start(map, onLoot)
	local old = map:FindFirstChild("Loot")
	if old then old:Destroy() end
	local folder = Instance.new("Folder")
	folder.Name = "Loot"
	folder.Parent = map
	local points = map:FindFirstChild("LootPoints")
	if points then
		for _, point in points:GetChildren() do
			local lootType = point:GetAttribute("LootType")
			local amount = point:GetAttribute("Amount")
			if type(lootType) == "string" and type(amount) == "number" then
				createLoot(folder, point.Position, lootType, amount, onLoot)
			end
		end
		return
	end
	for _, loot in {
		{ Vector3.new(-130, 2, -150), "Ammo", 10 },
		{ Vector3.new(-60, 2, -55), "Materials", 5 },
		{ Vector3.new(-210, 2, 80), "Medkit", 1 },
		{ Vector3.new(65, 2, -160), "Cash", 80 },
		{ Vector3.new(80, 2, 85), "BackpackScout", 1 },
		{ Vector3.new(-20, 2, 170), "RedDot", 1 },
		{ Vector3.new(132, 2, 20), "Flashlight", 1 },
	} do
		createLoot(folder, loot[1], loot[2], loot[3], onLoot)
	end
end

return LootService