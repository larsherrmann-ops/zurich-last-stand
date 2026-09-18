local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local ZombieModels = require(script.Parent.ZombieModels)

local ZombieService = {}
local folder
local spawnFolder
local isNight = false
local lastUpdate = 0

-- model -> { walk = AnimationTrack?, attack = AnimationTrack?, death = string? }
local tracks = setmetatable({}, { __mode = "k" })

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

local function loadTrack(humanoid, animationId)
	if not animationId then return nil end
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then return nil end
	local animation = Instance.new("Animation")
	animation.AnimationId = animationId
	local ok, track = pcall(function() return animator:LoadAnimation(animation) end)
	animation:Destroy()
	if not ok then return nil end
	return track
end

local function variantSpeed(variant)
	if isNight then
		return variant.NightSpeed or Config.Zombie.NightSpeed
	end
	return variant.WalkSpeed or Config.Zombie.WalkSpeed
end

local function countVariant(name)
	local total = 0
	for _, zombie in folder:GetChildren() do
		if zombie:GetAttribute("Variant") == name then total += 1 end
	end
	return total
end

local function pickVariant()
	local variants = Config.Zombie.Variants
	if not variants or #variants == 0 then return nil end

	local pool, weightSum = {}, 0
	for _, variant in variants do
		if variant.NightOnly and not isNight then continue end
		if variant.MaxActive and countVariant(variant.Name) >= variant.MaxActive then continue end
		weightSum += variant.Weight
		table.insert(pool, variant)
	end
	if #pool == 0 then return variants[1] end

	local roll = math.random() * weightSum
	for _, variant in pool do
		roll -= variant.Weight
		if roll <= 0 then return variant end
	end
	return pool[#pool]
end

function ZombieService.Spawn()
	if not folder or #folder:GetChildren() >= Config.Zombie.MaxActive then return end
	local spawns = spawnFolder and spawnFolder:GetChildren() or {}
	if #spawns == 0 then return end

	local variant = pickVariant()
	if not variant then return end

	local model, animations = ZombieModels.Clone(variant)
	if not model then
		-- Asset nicht ladbar: Klotz-Zombie statt gar kein Gegner.
		model, animations = ZombieModels.CreateFallback()
	end

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model.PrimaryPart
	if not humanoid or not root then
		model:Destroy()
		return
	end

	-- main.server.luau erkennt Treffer über model.Name == "Zombie".
	model.Name = "Zombie"
	model:SetAttribute("Variant", variant.Name)
	model:SetAttribute("Damage", variant.Damage or Config.Zombie.Damage)
	model:SetAttribute("LastAttack", 0)

	local health = variant.Health or Config.Zombie.Health
	humanoid.MaxHealth = health
	humanoid.Health = health
	humanoid.WalkSpeed = variantSpeed(variant)

	local position = spawns[math.random(1, #spawns)].Position
	model.Parent = folder
	model:PivotTo(CFrame.new(position + Vector3.new(0, 3, 0)))
	pcall(function() root:SetNetworkOwner(nil) end)

	local entry = { death = animations and animations.Death }
	if animations then
		entry.walk = loadTrack(humanoid, animations.Walk or animations.Run)
		entry.attack = loadTrack(humanoid, animations.Attack)
	end
	if entry.walk then
		entry.walk.Looped = true
		entry.walk:Play(0.2)
	end
	tracks[model] = entry

	humanoid.Died:Connect(function()
		if entry.walk then entry.walk:Stop(0.2) end
		local deathTrack = loadTrack(humanoid, entry.death)
		if deathTrack then
			deathTrack.Looped = false
			deathTrack:Play(0.1)
		end
		for _, descendant in model:GetDescendants() do
			if descendant:IsA("BasePart") then descendant.CanCollide = false end
		end
		task.delay(3, function()
			tracks[model] = nil
			if model.Parent then model:Destroy() end
		end)
	end)
end

function ZombieService.SetNight(value)
	isNight = value
	if not folder then return end
	for _, zombie in folder:GetChildren() do
		local humanoid = zombie:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			local name = zombie:GetAttribute("Variant")
			local variant
			for _, candidate in Config.Zombie.Variants do
				if candidate.Name == name then
					variant = candidate
					break
				end
			end
			humanoid.WalkSpeed = variantSpeed(variant or Config.Zombie)
		end
	end
end

function ZombieService.Start(map)
	folder = Instance.new("Folder")
	folder.Name = "Zombies"
	folder.Parent = workspace

	spawnFolder = map and map:FindFirstChild("ZombieSpawns")
		or workspace:FindFirstChild("ZurichMap") and workspace.ZurichMap:FindFirstChild("ZombieSpawns")

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
						targetHumanoid:TakeDamage(zombie:GetAttribute("Damage") or Config.Zombie.Damage)
						local entry = tracks[zombie]
						if entry and entry.attack then entry.attack:Play(0.1) end
					end
				end
			end
		end
	end)

	-- Rigs im Hintergrund holen, damit der Serverstart nicht blockiert.
	task.spawn(function()
		ZombieModels.Preload(Config.Zombie.Variants)
		for _ = 1, 8 do ZombieService.Spawn() end
		while true do
			task.wait(Config.Zombie.SpawnDelay)
			ZombieService.Spawn()
			if isNight then ZombieService.Spawn() end
		end
	end)
end

return ZombieService
