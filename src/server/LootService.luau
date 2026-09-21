local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local ModelService = require(script.Parent.ModelService)

local LootService = {}

local COLORS = {
	Ammo = Color3.fromRGB(255, 201, 87),
	Materials = Color3.fromRGB(171, 119, 70),
	Medkit = Color3.fromRGB(222, 65, 65),
	Cash = Color3.fromRGB(88, 178, 108),
	BackpackScout = Color3.fromRGB(59, 113, 78),
	BackpackTactical = Color3.fromRGB(42, 82, 67),
	RedDot = Color3.fromRGB(185, 50, 47),
	ExtendedMag = Color3.fromRGB(88, 104, 121),
	Flashlight = Color3.fromRGB(220, 195, 100),
	Shotgun = Color3.fromRGB(134, 83, 47),
	Rifle = Color3.fromRGB(60, 69, 69),
}

local function createLoot(parent, position, lootType, amount, onLoot, tier)
	local item = ModelService.CreateLoot(parent, position, lootType, amount, COLORS[lootType] or Color3.fromRGB(200, 200, 200))
	item:SetAttribute("LootTier", tier or "Standard")
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

local function chooseHighRiskLoot()
	local entries = Config.Loot and Config.Loot.HighRisk
	if not entries or #entries == 0 then return "Ammo", 12 end
	local totalWeight = 0
	for _, entry in entries do totalWeight += entry.Weight or 0 end
	if totalWeight <= 0 then return "Ammo", 12 end
	local roll = math.random() * totalWeight
	for _, entry in entries do
		roll -= entry.Weight or 0
		if roll <= 0 then return entry.Name, entry.Amount or 1 end
	end
	local last = entries[#entries]
	return last.Name, last.Amount or 1
end

function LootService.Start(map, onLoot)
	local old = map:FindFirstChild("Loot")
	if old then old:Destroy() end
	local folder = Instance.new("Folder")
	folder.Name = "Loot"
	folder.Parent = map

	local standardCount = 0
	local points = map:FindFirstChild("LootPoints")
	if points then
		for _, point in points:GetChildren() do
			local lootType = point:GetAttribute("LootType")
			local amount = point:GetAttribute("Amount")
			if type(lootType) == "string" and type(amount) == "number" then
				createLoot(folder, point.Position, lootType, amount, onLoot, "Standard")
				standardCount += 1
			end
		end
	else
		for _, loot in {
			{ Vector3.new(-130, 2, -150), "Ammo", 10 },
			{ Vector3.new(-60, 2, -55), "Materials", 5 },
			{ Vector3.new(-210, 2, 80), "Medkit", 1 },
			{ Vector3.new(65, 2, -160), "Cash", 80 },
			{ Vector3.new(80, 2, 85), "BackpackScout", 1 },
			{ Vector3.new(-20, 2, 170), "RedDot", 1 },
			{ Vector3.new(132, 2, 20), "Flashlight", 1 },
		} do
			createLoot(folder, loot[1], loot[2], loot[3], onLoot, "Standard")
			standardCount += 1
		end
	end

	local premiumCount = 0
	local highRiskPoints = map:FindFirstChild("HighRiskLootPoints")
	if highRiskPoints then
		for _, point in highRiskPoints:GetChildren() do
			local lootType = point:GetAttribute("LootType")
			local amount = point:GetAttribute("Amount")
			if type(lootType) ~= "string" then lootType, amount = chooseHighRiskLoot() end
			if type(amount) ~= "number" then amount = 1 end
			createLoot(folder, point.Position, lootType, amount, onLoot, "High")
			premiumCount += 1
		end
	end

	print("ZurichLastStand: spawned " .. standardCount .. " standard loot and " .. premiumCount .. " high-risk loot")
end

return LootService
