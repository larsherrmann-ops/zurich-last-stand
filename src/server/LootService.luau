local ModelService = require(script.Parent.ModelService)

local LootService = {}

local function createLoot(parent, position, lootType, amount, color, onLoot)
	local item = ModelService.CreateLoot(parent, position, lootType, amount, color)
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
	local spots = {
		{ Vector3.new(-130, 2, -150), "Ammo", 10, Color3.fromRGB(255, 201, 87) },
		{ Vector3.new(-60, 2, -55), "Materials", 5, Color3.fromRGB(171, 119, 70) },
		{ Vector3.new(-210, 2, 80), "Medkit", 1, Color3.fromRGB(222, 65, 65) },
		{ Vector3.new(65, 2, -160), "Cash", 80, Color3.fromRGB(88, 178, 108) },
		{ Vector3.new(80, 2, 85), "BackpackScout", 1, Color3.fromRGB(59, 113, 78) },
		{ Vector3.new(-20, 2, 170), "RedDot", 1, Color3.fromRGB(185, 50, 47) },
		{ Vector3.new(132, 2, 20), "Flashlight", 1, Color3.fromRGB(220, 195, 100) },
	}
	for _, loot in spots do
		createLoot(folder, loot[1], loot[2], loot[3], loot[4], onLoot)
	end
end

return LootService
