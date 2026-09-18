return {
	Player = {
		MaxHealth = 100,
		WalkSpeed = 18,
        SprintSpeed = 26,
        CrouchSpeed = 8,
        JumpPower = 50,
        CameraMinZoomDistance = 0.5,
        CameraMaxZoomDistance = 20,
		StartingAmmo = 30,
		StartingMaterials = 3,
		StartingMedkits = 1,
		StartingCash = 120,
		StartingBackpack = "Small",
	},
	Weapon = {
		Damage = 34,
		Range = 350,
		FireDelay = 0.18,
		MagazineSize = 9,
	},
	Zombie = {
		MaxActive = 40,
		-- Fallback-Werte, falls eine Variante keine eigenen mitbringt.
		Health = 100,
		WalkSpeed = 9,
		NightSpeed = 14,
		Damage = 10,
		AttackDistance = 5,
		AttackDelay = 0.8,
		SpawnDelay = 2.7,
		--[[ Rigs aus dem Creator Store. Alle gratis und im Inventar des
		     Place-Owners, damit InsertService:LoadAsset auch im veröffentlichten
		     Spiel funktioniert. Scripts werden beim Laden entfernt
		     (siehe ZombieModels.luau). ]]
		Variants = {
			{
				Name = "Walker",
				AssetId = 187789986, -- Drooling Zombie (@Roblox)
				Weight = 50,
				Health = 100,
				WalkSpeed = 9,
				NightSpeed = 14,
				Damage = 10,
			},
			{
				Name = "Runner",
				AssetId = 3924238625, -- Drooling Zombie Rthro (@Roblox)
				Weight = 26,
				Health = 85,
				WalkSpeed = 13,
				NightSpeed = 19,
				Damage = 8,
			},
			{
				Name = "Brute",
				AssetId = 5038317529, -- Tank Zombie (@trevle0ck)
				Weight = 13,
				Health = 260,
				WalkSpeed = 7,
				NightSpeed = 9,
				Damage = 22,
			},
			{
				Name = "Crawler",
				AssetId = 2791914892, -- A Zombie. [Enemy] (@Burger_MeaI)
				Weight = 9,
				Health = 70,
				WalkSpeed = 11,
				NightSpeed = 16,
				Damage = 7,
			},
			{
				Name = "FrostBoss",
				AssetId = 12128443490, -- Frost Boss Zombie (@safulla202020)
				Weight = 2,
				Health = 900,
				WalkSpeed = 8,
				NightSpeed = 11,
				Damage = 34,
				MaxActive = 1,
				NightOnly = true,
			},
		},
	},
	Cycle = {
		DaySeconds = 70,
		NightSeconds = 55,
	},
	Barricade = {
		Cost = 2,
		MaxDistance = 14,
	},
	Inventory = {
		Backpacks = {
			Small = { Slots = 6, Price = 0 },
			Scout = { Slots = 10, Price = 250 },
			Tactical = { Slots = 16, Price = 650 },
			Heavy = { Slots = 22, Price = 1200 },
		},
		Attachments = {
			RedDot = { Price = 180, DamageBonus = 6 },
			ExtendedMag = { Price = 300, MagazineBonus = 6 },
			Flashlight = { Price = 100 },
		},
		Items = {
			Ammo = { Buy = 30, Sell = 8, Attribute = "Ammo", Amount = 10 },
			Medkit = { Buy = 70, Sell = 35, Attribute = "Medkits", Amount = 1 },
			Materials = { Buy = 45, Sell = 12, Attribute = "Materials", Amount = 5 },
		},
	},
	Trading = {
		MaxDistance = 40,
		Cooldown = 0.35,
		Items = { "Cash", "Ammo", "Materials", "Medkits" },
	},
	Monetization = {
		-- Im Creator Dashboard nach dem Anlegen der Developer Products ersetzen.
		ScoutBackpackProductId = 0,
		TacticalBackpackProductId = 0,
		FlashlightProductId = 0,
	},
}
