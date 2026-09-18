local Players = game:GetService("Players")

local LootService = {}

local function createLoot(parent, position, lootType, amount, color)
	local item = Instance.new("Part")
	item.Name = lootType
	item.Size = Vector3.new(2.5, 1.5, 2.5)
	item.Position = position
	item.Anchored = true
	item.Color = color
	item.Material = Enum.Material.Neon
	item:SetAttribute("LootType", lootType)
	item:SetAttribute("Amount", amount)
	item.Parent = parent
	local taken = false
	item.Touched:Connect(function(hit)
		if taken then return end
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player then return end
		taken = true
		if lootType == "Health" then
			local humanoid = hit.Parent:FindFirstChildOfClass("Humanoid")
			if humanoid then humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + amount) end
		else
			player:SetAttribute(lootType, (player:GetAttribute(lootType) or 0) + amount)
		end
		item:Destroy()
	end)
end

function LootService.Start()
	local folder = Instance.new("Folder")
	folder.Name = "Loot"
	folder.Parent = workspace
	local spots = {
		Vector3.new(-130, 2, -150), Vector3.new(-60, 2, -55), Vector3.new(-210, 2, 80),
		Vector3.new(65, 2, -160), Vector3.new(80, 2, 85), Vector3.new(-20, 2, 170),
	}
	for index, position in spots do
		if index % 3 == 1 then
			createLoot(folder, position, "Ammo", 10, Color3.fromRGB(255, 201, 87))
		elseif index % 3 == 2 then
			createLoot(folder, position, "Materials", 2, Color3.fromRGB(171, 119, 70))
		else
			createLoot(folder, position, "Health", 25, Color3.fromRGB(222, 65, 65))
		end
	end
end

return LootService
