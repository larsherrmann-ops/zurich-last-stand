--[[
	ZombieModels
	Lädt die Zombie-Rigs aus dem Creator Store, entschärft sie und hält
	sanitisierte Vorlagen im Speicher.

	Sicherheit: Free Models sind der klassische Backdoor-Vektor. Wir übernehmen
	deshalb ausschliesslich Rig, Meshes und Animations-IDs. Jedes mitgelieferte
	Script wird vor der ersten Verwendung gelöscht - die KI läuft komplett über
	den ZombieService.
]]

local InsertService = game:GetService("InsertService")
local PhysicsService = game:GetService("PhysicsService")

local ZombieModels = {}

local COLLISION_GROUP = "Zombies"

-- assetId -> { rig = Model, animations = { [key] = animationId } } oder false bei Ladefehler
local templates = {}
local collisionReady = false

local ANIMATION_RULES = {
	{ pattern = "death", key = "Death" },
	{ pattern = "died", key = "Death" },
	{ pattern = "attack", key = "Attack" },
	{ pattern = "punch", key = "Attack" },
	{ pattern = "swipe", key = "Attack" },
	{ pattern = "bite", key = "Attack" },
	{ pattern = "run", key = "Run" },
	{ pattern = "walk", key = "Walk" },
	{ pattern = "idle", key = "Idle" },
}

local function ensureCollisionGroup()
	if collisionReady then return end
	collisionReady = true
	pcall(function() PhysicsService:RegisterCollisionGroup(COLLISION_GROUP) end)
	pcall(function() PhysicsService:CollisionGroupSetCollidable(COLLISION_GROUP, COLLISION_GROUP, false) end)
end

-- Animations-IDs einsammeln, BEVOR die Animate-Scripts entfernt werden.
local function harvestAnimations(container)
	local found = {}
	for _, descendant in container:GetDescendants() do
		if descendant:IsA("Animation") and descendant.AnimationId ~= "" then
			local parentName = descendant.Parent and descendant.Parent.Name or ""
			local label = string.lower(descendant.Name .. " " .. parentName)
			for _, rule in ANIMATION_RULES do
				if string.find(label, rule.pattern, 1, true) then
					if not found[rule.key] then found[rule.key] = descendant.AnimationId end
					break
				end
			end
		end
	end
	return found
end

local function sanitize(container)
	local removedScripts = 0
	for _, descendant in container:GetDescendants() do
		if descendant:IsA("LuaSourceContainer") then
			descendant:Destroy()
			removedScripts += 1
		elseif descendant:IsA("ProximityPrompt") or descendant:IsA("ClickDetector") or descendant:IsA("RemoteEvent") or descendant:IsA("RemoteFunction") then
			descendant:Destroy()
		elseif descendant:IsA("Sound") then
			descendant.Playing = false
			descendant.Looped = false
		end
	end
	return removedScripts
end

local function findRig(container)
	if container:IsA("Model") and container:FindFirstChildOfClass("Humanoid") then return container end
	for _, descendant in container:GetDescendants() do
		if descendant:IsA("Model") and descendant:FindFirstChildOfClass("Humanoid") then return descendant end
	end
	return nil
end

-- Verschachtelte Models auflösen. Sonst liefert FindFirstAncestorOfClass("Model")
-- beim Raycast in main.server.luau das Sub-Model statt des Zombies - und der
-- Treffer würde verpuffen.
local function flatten(rig)
	for _, descendant in rig:GetDescendants() do
		if descendant:IsA("Model") and descendant ~= rig and descendant.Parent then
			for _, child in descendant:GetChildren() do
				child.Parent = rig
			end
			descendant:Destroy()
		end
	end
end

local function prepare(rig)
	local humanoid = rig:FindFirstChildOfClass("Humanoid")
	if not humanoid then return nil end

	local root = rig:FindFirstChild("HumanoidRootPart") or rig:FindFirstChild("Torso") or rig:FindFirstChild("UpperTorso")
	if not root or not root:IsA("BasePart") then return nil end

	flatten(rig)
	rig.PrimaryPart = root

	if not humanoid:FindFirstChildOfClass("Animator") then
		local animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.BreakJointsOnDeath = false
	humanoid.RequiresNeck = false

	for _, descendant in rig:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CollisionGroup = COLLISION_GROUP
		end
	end
	-- Nur der echte HumanoidRootPart darf durchlässig sein. Fiel die Suche auf
	-- den Torso zurück, würde der Zombie sonst durch den Boden sacken.
	if root.Name == "HumanoidRootPart" then
		root.CanCollide = false
	end

	return rig
end

local function animationSummary(animations)
	local keys = {}
	for key in animations do
		table.insert(keys, key)
	end
	if #keys == 0 then return "keine" end
	table.sort(keys)
	return table.concat(keys, ", ")
end

--[[ Lädt eine Variante und legt die sanitisierte Vorlage ab.
     Rückgabe: template-Tabelle oder false, wenn das Asset nicht ladbar ist. ]]
function ZombieModels.Load(variant)
	local cached = templates[variant.AssetId]
	if cached ~= nil then return cached end

	ensureCollisionGroup()

	local ok, container = pcall(function()
		return InsertService:LoadAsset(variant.AssetId)
	end)
	if not ok or typeof(container) ~= "Instance" then
		warn(string.format("[Zombies] %s (%d) nicht ladbar: %s", variant.Name, variant.AssetId, tostring(container)))
		templates[variant.AssetId] = false
		return false
	end

	local animations = harvestAnimations(container)
	local removedScripts = sanitize(container)

	local rig = findRig(container)
	if rig then rig = prepare(rig) end
	if not rig then
		warn(string.format("[Zombies] %s (%d) enthält kein brauchbares Rig", variant.Name, variant.AssetId))
		container:Destroy()
		templates[variant.AssetId] = false
		return false
	end

	rig.Parent = nil
	container:Destroy()

	print(string.format(
		"[Zombies] %s geladen (%d Scripts entfernt, Animationen: %s)",
		variant.Name,
		removedScripts,
		animationSummary(animations)
	))

	local template = { rig = rig, animations = animations }
	templates[variant.AssetId] = template
	return template
end

function ZombieModels.Preload(variants)
	for _, variant in variants do
		ZombieModels.Load(variant)
	end
end

-- Frische Instanz einer Variante, oder nil wenn das Asset nicht verfügbar ist.
function ZombieModels.Clone(variant)
	local template = ZombieModels.Load(variant)
	if not template then return nil, nil end
	return template.rig:Clone(), template.animations
end

-- Notnagel im alten Klotz-Look, falls InsertService blockiert ist.
function ZombieModels.CreateFallback()
	ensureCollisionGroup()

	local function bodyPart(model, name, size, offset, color, collide)
		local object = Instance.new("Part")
		object.Name = name
		object.Size = size
		object.CFrame = CFrame.new(offset)
		object.Color = color
		object.Material = Enum.Material.SmoothPlastic
		object.CanCollide = collide
		object.CollisionGroup = COLLISION_GROUP
		object.Parent = model
		return object
	end

	local model = Instance.new("Model")
	local root = bodyPart(model, "HumanoidRootPart", Vector3.new(2, 2, 1), Vector3.zero, Color3.fromRGB(70, 90, 58), false)
	root.Transparency = 1
	local torso = bodyPart(model, "Torso", Vector3.new(2.5, 3, 1.4), Vector3.zero, Color3.fromRGB(82, 107, 70), true)
	local head = bodyPart(model, "Head", Vector3.new(2, 2, 2), Vector3.new(0, 2.4, 0), Color3.fromRGB(119, 143, 91), false)
	for _, object in { torso, head } do
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = object
		weld.Parent = root
	end

	local humanoid = Instance.new("Humanoid")
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.BreakJointsOnDeath = false
	humanoid.RequiresNeck = false
	humanoid.Parent = model

	model.PrimaryPart = root
	return model, {}
end

return ZombieModels
