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
shootEvent.OnServerEvent:Connect(function(player, origin, direction)
	if typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3" then return end
	if direction.Magnitude < 0.9 or direction.Magnitude > 2000 then return end
	local now = os.clock()
	if now - (lastShot[player] or 0) < Config.Weapon.FireDelay then return end
	local magazine = player:GetAttribute("Magazine") or 0
	if magazine <= 0 then remotes.Notify:FireClient(player, "MAGAZIN LEER  ·  R DRÜCKEN", "Info"); return end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or (root.Position - origin).Magnitude > 10 then return end
	lastShot[player] = now
	player:SetAttribute("Magazine", magazine - 1)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	local range = Config.Weapon.Range
	if player:GetAttribute("RedDotOwned") then range += 45 end
	local result = workspace:Raycast(origin, direction.Unit * range, params)
	if result then
		local windowBroken, windowRemaining = MapService.DamageWindow(result.Instance, 1)
		if windowRemaining ~= nil then
			if windowBroken then
				remotes.Notify:FireClient(player, "FENSTER ZERBROCHEN  ·  ZUGANG OFFEN", "Success")
			else
				remotes.Notify:FireClient(player, "GLAS BESCHÄDIGT  ·  NOCH " .. windowRemaining .. " TREFFER", "Info")
			end
			return
		end
		local model = result.Instance:FindFirstAncestorOfClass("Model")
		local humanoid = model and model:FindFirstChildOfClass("Humanoid")
		if humanoid and model.Name == "Zombie" and humanoid.Health > 0 then
			local wasAlive = humanoid.Health > 0
			local damage = Config.Weapon.Damage + (player:GetAttribute("RedDotOwned") and 6 or 0)
			humanoid:TakeDamage(damage)
			if wasAlive and humanoid.Health <= 0 then
				player:SetAttribute("Kills", (player:GetAttribute("Kills") or 0) + 1)
			end
		end
	end
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