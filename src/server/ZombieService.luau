local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local ZombieService = {}
local folder
local spawnFolder
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
	if not folder or #folder:GetChildren() >= Config.Zombie.MaxActive then return end
	local spawns = spawnFolder and spawnFolder:GetChildren() or {}
	if #spawns == 0 then return end
	local position = spawns[math.random(1, #spawns)].Position
	local model = Instance.new("Model")
	model.Name = "Zombie"
	model:SetAttribute("LastAttack", 0)
	local root = bodyPart(model, "HumanoidRootPart", Vector3.new(2, 2, 1), position + Vector3.new(0, 3, 0), Color3.fromRGB(70, 90, 58))
	root.Transparency = 1
	root.CanCollide = false
	local torso = bodyPart(model, "Torso", Vector3.new(2.5, 3, 1.4), root.Position, Color3.fromRGB(82, 107, 70))
	local head = bodyPart(model, "Head", Vector3.new(2, 2, 2), root.Position + Vector3.new(0, 2.4, 0), Color3.fromRGB(119, 143, 91))
	for _, object in { torso, head } do
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = object
		weld.Parent = root
	end
	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = Config.Zombie.Health
	humanoid.Health = Config.Zombie.Health
	humanoid.WalkSpeed = isNight and Config.Zombie.NightSpeed or Config.Zombie.WalkSpeed
	humanoid.Parent = model
	model.PrimaryPart = root
	model.Parent = folder
	model:PivotTo(CFrame.new(position + Vector3.new(0, 3, 0)))
	humanoid.Died:Connect(function()
		task.delay(1.5, function() if model.Parent then model:Destroy() end end)
	end)
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

function ZombieService.Start(map)
	folder = Instance.new("Folder")
	folder.Name = "Zombies"
	folder.Parent = workspace
	spawnFolder = map and map:FindFirstChild("ZombieSpawns") or workspace:FindFirstChild("ZurichMap") and workspace.ZurichMap:FindFirstChild("ZombieSpawns")
	for _ = 1, 8 do ZombieService.Spawn() end
	task.spawn(function()
		while true do
			task.wait(Config.Zombie.SpawnDelay)
			ZombieService.Spawn()
			if isNight then ZombieService.Spawn() end
		end
	end)
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