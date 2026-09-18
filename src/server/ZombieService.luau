local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local ZombieService = {}
local folder
local isNight = false
local lastUpdate = 0

local function nearestCharacter(position)
	local bestCharacter, bestDistance
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if root and humanoid and humanoid.Health > 0 then
			local distance = (root.Position - position).Magnitude
			if not bestDistance or distance < bestDistance then
				bestCharacter, bestDistance = character, distance
			end
		end
	end
	return bestCharacter, bestDistance
end

local function bodyPart(model, name, size, position, color)
	local object = Instance.new("Part")
	object.Name = name
	object.Size = size
	object.Position = position
	object.Color = color
	object.Material = Enum.Material.SmoothPlastic
	object.CanCollide = name == "Torso"
	object.Parent = model
	return object
end

function ZombieService.Spawn()
	-- Spawn positions will come from a server-side director near active players.
	return
end

function ZombieService.SetNight(value)
	isNight = value
	if folder then
		for _, zombie in folder:GetChildren() do
			local humanoid = zombie:FindFirstChildOfClass("Humanoid")
			if humanoid then humanoid.WalkSpeed = value and Config.Zombie.NightSpeed or Config.Zombie.WalkSpeed end
		end
	end
end

function ZombieService.Start()
	folder = Instance.new("Folder")
	folder.Name = "Zombies"
	folder.Parent = workspace
	RunService.Heartbeat:Connect(function()
		if os.clock() - lastUpdate < 0.22 then return end
		lastUpdate = os.clock()
		for _, zombie in folder:GetChildren() do
			local root = zombie.PrimaryPart
			local humanoid = zombie:FindFirstChildOfClass("Humanoid")
			if root and humanoid and humanoid.Health > 0 then
				local character, distance = nearestCharacter(root.Position)
				local targetRoot = character and character:FindFirstChild("HumanoidRootPart")
				local targetHumanoid = character and character:FindFirstChildOfClass("Humanoid")
				if targetRoot then humanoid:MoveTo(targetRoot.Position) end
				if distance and distance <= Config.Zombie.AttackDistance and targetHumanoid then
					local lastAttack = zombie:GetAttribute("LastAttack") or 0
					if os.clock() - lastAttack >= Config.Zombie.AttackDelay then
						zombie:SetAttribute("LastAttack", os.clock())
						targetHumanoid:TakeDamage(Config.Zombie.Damage)
					end
				end
			end
		end
	end)
end

return ZombieService
