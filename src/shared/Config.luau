return {
	Player = {
		MaxHealth = 100,
		WalkSpeed = 18,
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
		Health = 100,
		WalkSpeed = 9,
		NightSpeed = 14,
		Damage = 10,
		AttackDistance = 5,
		AttackDelay = 0.8,
		SpawnDelay = 2.7,
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
