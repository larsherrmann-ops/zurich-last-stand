local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local MapService = require(script.Parent.MapService)
local ZombieService = require(script.Parent.ZombieService)
local LootService = require(script.Parent.LootService)
local DayNightService = require(script.Parent.DayNightService)
local InventoryService = require(script.Parent.InventoryService)

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage
end

local function remote(name)
	local event = remotes:FindFirstChild(name)
	if not event then
		event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = remotes
	end
	return event
end

local shootEvent = remote("Shoot")
local buildEvent = remote("BuildBarricade")
local stateEvent = remote("State")
remote("InventoryAction")
remote("InventoryState")
remote("Notify")
remote("OpenShop")
remote("TradeAction")
remote("TradeState")
remote("TradePlayers")
remote("RobuxAction")

local map = MapService.Create()
InventoryService.Start(remotes, map)
ZombieService.Start(map)
LootService.Start(map, InventoryService.CollectLoot)
DayNightService.Start(stateEvent, ZombieService.SetNight)

local lastShot = {}

local function getWeaponConfig(player)
	local weaponName = player:GetAttribute("Weapon") or "Pistol"
	return Config.Weapon.Types[weaponName] or Config.Weapon.Types.Pistol
end

shootEvent.OnServerEvent:Connect(function(player, origin, direction)
	if typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3" then return end
	if direction.Magnitude < 0.9 or direction.Magnitude > 2000 then return end
	local weapon = getWeaponConfig(player)
	local now = os.clock()
	if now - (lastShot[player] or 0) < (weapon.FireDelay or Config.Weapon.FireDelay) then return end
	local magazine = player:GetAttribute("Magazine") or 0
	if magazine <= 0 then
		remotes.Notify:FireClient(player, "MAGAZIN LEER  ·  R DRÜCKEN", "Info")
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or (root.Position - origin).Magnitude > 10 then return end

	lastShot[player] = now
	player:SetAttribute("Magazine", magazine - 1)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	local range = (weapon.Range or Config.Weapon.Range) + (player:GetAttribute("RedDotOwned") and 45 or 0)
	local baseDirection = direction.Unit
	local pellets = math.max(1, math.floor(weapon.Pellets or 1))
	local spread = weapon.Spread or 0
	local windowMessage
	for _ = 1, pellets do
		local shotDirection = baseDirection
		if spread > 0 then
			local reference = math.abs(baseDirection.Y) > 0.95 and Vector3.new(0, 0, 1) or Vector3.new(0, 1, 0)
			local right = baseDirection:Cross(reference).Unit
			local up = right:Cross(baseDirection).Unit
			shotDirection = (baseDirection
				+ right * ((math.random() - 0.5) * spread)
				+ up * ((math.random() - 0.5) * spread)).Unit
		end

		local result = workspace:Raycast(origin, shotDirection * range, params)
		if not result then continue end
		local windowBroken, windowRemaining = MapService.DamageWindow(result.Instance, 1)
		if windowRemaining ~= nil then
			if not windowMessage then
				if windowBroken then
					windowMessage = { Text = "FENSTER ZERBROCHEN  ·  ZUGANG OFFEN", Kind = "Success" }
				else
					windowMessage = { Text = "GLAS BESCHÄDIGT  ·  NOCH " .. windowRemaining .. " TREFFER", Kind = "Info" }
				end
			end
			continue
		end

		local model = result.Instance:FindFirstAncestorOfClass("Model")
		local humanoid = model and model:FindFirstChildOfClass("Humanoid")
		if humanoid and model.Name == "Zombie" and humanoid.Health > 0 then
			local wasAlive = humanoid.Health > 0
			local redDotBonus = player:GetAttribute("RedDotOwned")
				and Config.Inventory.Attachments.RedDot.DamageBonus
				or 0
			humanoid:TakeDamage((weapon.Damage or Config.Weapon.Damage) + redDotBonus)
			if wasAlive and humanoid.Health <= 0 then
				player:SetAttribute("Kills", (player:GetAttribute("Kills") or 0) + 1)
			end
		end
	end
	if windowMessage then remotes.Notify:FireClient(player, windowMessage.Text, windowMessage.Kind) end
end)
buildEvent.OnServerEvent:Connect(function(player, targetPosition)
	if typeof(targetPosition) ~= "Vector3" then return end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local materials = player:GetAttribute("Materials") or 0
	if not root or materials < Config.Barricade.Cost then return end
	if (root.Position - targetPosition).Magnitude > Config.Barricade.MaxDistance then return end
	player:SetAttribute("Materials", materials - Config.Barricade.Cost)
	local barrier = Instance.new("Part")
	barrier.Name = "Barricade"
	barrier.Size = Vector3.new(10, 5, 1)
	barrier.CFrame = CFrame.lookAt(targetPosition + Vector3.new(0, 2.5, 0), root.Position)
	barrier.Anchored = true
	barrier.Material = Enum.Material.WoodPlanks
	barrier.Color = Color3.fromRGB(118, 78, 48)
	barrier:SetAttribute("Durability", 100)
	barrier.Parent = workspace.ZurichMap
end)

Players.PlayerRemoving:Connect(function(player) lastShot[player] = nil end)
