local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local MapService = require(script.Parent.MapService)
local ZombieService = require(script.Parent.ZombieService)
local LootService = require(script.Parent.LootService)
local DayNightService = require(script.Parent.DayNightService)

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage
local shootEvent = Instance.new("RemoteEvent")
shootEvent.Name = "Shoot"
shootEvent.Parent = remotes
local buildEvent = Instance.new("RemoteEvent")
buildEvent.Name = "BuildBarricade"
buildEvent.Parent = remotes
local stateEvent = Instance.new("RemoteEvent")
stateEvent.Name = "State"
stateEvent.Parent = remotes

MapService.Create()
-- Zombies will be enabled by the dynamic spawn director in a later slice.
LootService.Start()
DayNightService.Start(stateEvent, ZombieService.SetNight)

Players.PlayerAdded:Connect(function(player)
	player:SetAttribute("Ammo", Config.Player.StartingAmmo)
	player:SetAttribute("Materials", Config.Player.StartingMaterials)
	player:SetAttribute("Kills", 0)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.MaxHealth = Config.Player.MaxHealth
		humanoid.Health = Config.Player.MaxHealth
		humanoid.UseJumpPower = true
		humanoid.JumpPower = Config.Player.JumpPower
		humanoid.WalkSpeed = Config.Player.WalkSpeed
	end)
end)

local lastShot = {}
shootEvent.OnServerEvent:Connect(function(player, origin, direction)
	if typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3" then return end
	if direction.Magnitude < 0.9 then return end
	local now = os.clock()
	if now - (lastShot[player] or 0) < Config.Weapon.FireDelay then return end
	local ammo = player:GetAttribute("Ammo") or 0
	if ammo <= 0 then return end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or (root.Position - origin).Magnitude > 10 then return end
	lastShot[player] = now
	player:SetAttribute("Ammo", ammo - 1)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	local result = workspace:Raycast(origin, direction.Unit * Config.Weapon.Range, params)
	if result then
		local model = result.Instance:FindFirstAncestorOfClass("Model")
		local humanoid = model and model:FindFirstChildOfClass("Humanoid")
		if humanoid and model.Name == "Zombie" and humanoid.Health > 0 then
			local wasAlive = humanoid.Health > 0
			humanoid:TakeDamage(Config.Weapon.Damage)
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
	barrier.Parent = workspace.SurvivalMap
end)

Players.PlayerRemoving:Connect(function(player) lastShot[player] = nil end)
