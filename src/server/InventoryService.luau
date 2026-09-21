local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local ModelService = require(script.Parent.ModelService)

local InventoryService = {}
local store
local dataStoreAttempted = false
local remotes
local map
local initialized = {}
local lastAction = {}
local shopAccess = {}
local activeTrades = {}
local tradeByPlayer = {}

local backpackOrder = { "Small", "Scout", "Tactical", "Heavy" }
local productRewards = {}

local function getWeaponConfig(player)
	local weaponName = player:GetAttribute("Weapon") or "Pistol"
	return Config.Weapon.Types[weaponName] or Config.Weapon.Types.Pistol
end

local function getWeaponMagazineSize(player)
	local size = getWeaponConfig(player).MagazineSize or Config.Weapon.MagazineSize
	if player:GetAttribute("ExtendedMagOwned") then size += Config.Inventory.Attachments.ExtendedMag.MagazineBonus end
	return size
end

local function getStore()
    if dataStoreAttempted then return store end
    dataStoreAttempted = true
    local success, result = pcall(function()
        return DataStoreService:GetDataStore("ZurichLastStandInventory_v1")
    end)
    if success then store = result end
    return store
end

local function notify(player, message, kind)
	if remotes and remotes.Notify then remotes.Notify:FireClient(player, message, kind or "Info") end
end

local function refresh(player)
	if remotes and remotes.InventoryState then remotes.InventoryState:FireClient(player, "Refresh") end
end

local function setDefaults(player)
	player:SetAttribute("Cash", Config.Player.StartingCash)
	player:SetAttribute("Ammo", Config.Player.StartingAmmo)
	player:SetAttribute("Weapon", "Pistol")
	player:SetAttribute("Magazine", Config.Weapon.Types.Pistol.MagazineSize)
	player:SetAttribute("Materials", Config.Player.StartingMaterials)
	player:SetAttribute("Medkits", Config.Player.StartingMedkits)
	player:SetAttribute("Kills", 0)
	player:SetAttribute("BackpackTier", Config.Player.StartingBackpack)
	player:SetAttribute("BackpackSlots", Config.Inventory.Backpacks[Config.Player.StartingBackpack].Slots)
	player:SetAttribute("FlashlightOwned", false)
	player:SetAttribute("FlashlightOn", false)
	player:SetAttribute("RedDotOwned", false)
	player:SetAttribute("ExtendedMagOwned", false)
end

local function applyData(player, data)
	setDefaults(player)
	if type(data) ~= "table" then return end
	if type(data.Weapon) == "string" and Config.Weapon.Types[data.Weapon] then
		player:SetAttribute("Weapon", data.Weapon)
	end
	for _, attribute in { "Cash", "Ammo", "Magazine", "Materials", "Medkits", "Kills" } do
		if type(data[attribute]) == "number" then player:SetAttribute(attribute, math.max(0, math.floor(data[attribute]))) end
	end
	if Config.Inventory.Backpacks[data.BackpackTier] then
		player:SetAttribute("BackpackTier", data.BackpackTier)
		player:SetAttribute("BackpackSlots", Config.Inventory.Backpacks[data.BackpackTier].Slots)
	end
	for _, attribute in { "FlashlightOwned", "FlashlightOn", "RedDotOwned", "ExtendedMagOwned" } do
		if type(data[attribute]) == "boolean" then player:SetAttribute(attribute, data[attribute]) end
	end
end

local function serialize(player)
	local data = {}
	for _, attribute in { "Weapon", "Cash", "Ammo", "Magazine", "Materials", "Medkits", "Kills", "BackpackTier", "FlashlightOwned", "RedDotOwned", "ExtendedMagOwned" } do
		data[attribute] = player:GetAttribute(attribute)
	end
	return data
end

local function savePlayer(player)
	if not initialized[player] then return end
	local dataStore = getStore()
	if not dataStore then return end
	local data = serialize(player)
	local success, errorMessage = pcall(function()
		dataStore:UpdateAsync(tostring(player.UserId), function() return data end)
	end)
	if not success then warn("ZurichLastStand save failed for " .. player.Name .. ": " .. tostring(errorMessage)) end
end

local function getRoot(player)
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function applyCharacter(player, character)
	local humanoid = character:WaitForChild("Humanoid", 8)
	if humanoid then
		humanoid.MaxHealth = Config.Player.MaxHealth
		humanoid.Health = math.min(humanoid.Health, Config.Player.MaxHealth)
		humanoid.WalkSpeed = Config.Player.WalkSpeed
	end
	ModelService.AttachBackpack(character, player:GetAttribute("BackpackTier") or "Small")
	ModelService.AttachWeapon(character, {
		WeaponName = player:GetAttribute("Weapon") or "Pistol",
		FlashlightOwned = player:GetAttribute("FlashlightOwned") == true,
		FlashlightOn = player:GetAttribute("FlashlightOn") == true,
		RedDotOwned = player:GetAttribute("RedDotOwned") == true,
		ExtendedMagOwned = player:GetAttribute("ExtendedMagOwned") == true,
	})
end

local function setupPlayer(player)
	if initialized[player] then return end
	local data
    local dataStore = getStore()
    if dataStore then
        local success, result = pcall(function() return dataStore:GetAsync(tostring(player.UserId)) end)
        if success then data = result end
    end
    applyData(player, data)
	initialized[player] = true
	player.CharacterAdded:Connect(function(character) applyCharacter(player, character) end)
	if player.Character then task.spawn(applyCharacter, player, player.Character) end
	refresh(player)
end

local function currentSlots(player)
	return player:GetAttribute("BackpackSlots") or Config.Inventory.Backpacks.Small.Slots
end

local function hasHigherBackpack(player, tier)
	local current = player:GetAttribute("BackpackTier") or "Small"
	local currentIndex, requestedIndex
	for index, name in backpackOrder do
		if name == current then currentIndex = index end
		if name == tier then requestedIndex = index end
	end
	return requestedIndex and currentIndex and requestedIndex > currentIndex
end

local function upgradeBackpack(player, tier, free)
	local config = Config.Inventory.Backpacks[tier]
	if not config or not hasHigherBackpack(player, tier) then
		notify(player, "Dieser Rucksack ist kein Upgrade.", "Error")
		return false
	end
	local price = free and 0 or config.Price
	local cash = player:GetAttribute("Cash") or 0
	if cash < price then
		notify(player, "Nicht genug Geld.", "Error")
		return false
	end
	player:SetAttribute("Cash", cash - price)
	player:SetAttribute("BackpackTier", tier)
	player:SetAttribute("BackpackSlots", config.Slots)
	if player.Character then ModelService.AttachBackpack(player.Character, tier) end
	notify(player, tier .. "-Rucksack ausgerüstet  ·  " .. config.Slots .. " Slots", "Success")
	refresh(player)
	return true
end

local function buyAttachment(player, attachmentName)
	local config = Config.Inventory.Attachments[attachmentName]
	if not config then return end
	local attribute = attachmentName .. "Owned"
	if player:GetAttribute(attribute) then
		notify(player, "Attachment bereits ausgerüstet.", "Info")
		return
	end
	local cash = player:GetAttribute("Cash") or 0
	if cash < config.Price then
		notify(player, "Nicht genug Geld.", "Error")
		return
	end
	player:SetAttribute("Cash", cash - config.Price)
	player:SetAttribute(attribute, true)
	if player.Character then
		ModelService.AttachWeapon(player.Character, {
			WeaponName = player:GetAttribute("Weapon") or "Pistol",
		FlashlightOwned = player:GetAttribute("FlashlightOwned") == true,
			FlashlightOn = player:GetAttribute("FlashlightOn") == true,
			RedDotOwned = player:GetAttribute("RedDotOwned") == true,
			ExtendedMagOwned = player:GetAttribute("ExtendedMagOwned") == true,
		})
	end
	notify(player, attachmentName .. " gekauft und ausgerüstet.", "Success")
	refresh(player)
end

local function changeItem(player, itemName, amount)
	local item = Config.Inventory.Items[itemName]
	if not item then return false end
	local attribute = item.Attribute
	local current = player:GetAttribute(attribute) or 0
	if current + amount < 0 then return false end
	player:SetAttribute(attribute, current + amount)
	return true
end

local function buyItem(player, itemName)
	local item = Config.Inventory.Items[itemName]
	if not item then return end
	local cash = player:GetAttribute("Cash") or 0
	if cash < item.Buy then notify(player, "Nicht genug Geld.", "Error"); return end
	player:SetAttribute("Cash", cash - item.Buy)
	changeItem(player, itemName, item.Amount)
	notify(player, itemName .. " gekauft.", "Success")
	refresh(player)
end

local function sellItem(player, itemName)
	local item = Config.Inventory.Items[itemName]
	if not item then return end
	if not changeItem(player, itemName, -item.Amount) then
		notify(player, "Du hast davon nicht genug.", "Error")
		return
	end
	player:SetAttribute("Cash", (player:GetAttribute("Cash") or 0) + item.Sell)
	notify(player, itemName .. " verkauft  ·  +$" .. item.Sell, "Success")
	refresh(player)
end

local function getMagazineSize(player)
	return getWeaponMagazineSize(player)
end

local function reload(player)
	local reserve = player:GetAttribute("Ammo") or 0
	local magazine = player:GetAttribute("Magazine") or 0
	local capacity = getMagazineSize(player)
	if reserve <= 0 or magazine >= capacity then return end
	local loaded = math.min(capacity - magazine, reserve)
	player:SetAttribute("Magazine", magazine + loaded)
	player:SetAttribute("Ammo", reserve - loaded)
	notify(player, "NACHLADEN  ·  " .. (magazine + loaded) .. "/" .. capacity, "Info")
	refresh(player)
end

local function useMedkit(player)
	local count = player:GetAttribute("Medkits") or 0
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if count <= 0 or not humanoid or humanoid.Health >= humanoid.MaxHealth then
		notify(player, "Medkit kann gerade nicht benutzt werden.", "Error")
		return
	end
	player:SetAttribute("Medkits", count - 1)
	humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + 35)
	notify(player, "MEDKIT BENUTZT  ·  +35 LEBEN", "Success")
	refresh(player)
end

local function toggleFlashlight(player)
	if not player:GetAttribute("FlashlightOwned") then
		notify(player, "Finde oder kaufe zuerst eine Taschenlampe.", "Error")
		return
	end
	local enabled = not player:GetAttribute("FlashlightOn")
	player:SetAttribute("FlashlightOn", enabled)
	ModelService.SetFlashlight(player.Character, enabled)
	refresh(player)
end

function InventoryService.CollectLoot(player, lootType, amount)
	if not player or not player:IsDescendantOf(Players) then return end
	amount = math.max(1, math.floor(tonumber(amount) or 1))
	if lootType == "BackpackScout" then
		upgradeBackpack(player, "Scout", true)
	elseif lootType == "BackpackTactical" then
		upgradeBackpack(player, "Tactical", true)
	elseif lootType == "Shotgun" or lootType == "Rifle" then
		if Config.Weapon.Types[lootType] then
			player:SetAttribute("Weapon", lootType)
			player:SetAttribute("Magazine", getWeaponMagazineSize(player))
			if player.Character then
				ModelService.AttachWeapon(player.Character, {
					WeaponName = lootType,
					FlashlightOwned = player:GetAttribute("FlashlightOwned") == true,
					FlashlightOn = player:GetAttribute("FlashlightOn") == true,
					RedDotOwned = player:GetAttribute("RedDotOwned") == true,
					ExtendedMagOwned = player:GetAttribute("ExtendedMagOwned") == true,
				})
			end
			notify(player, Config.Weapon.Types[lootType].DisplayName .. " gefunden und ausgerüstet.", "Success")
			refresh(player)
		end
	elseif lootType == "ExtendedMag" then
		player:SetAttribute("ExtendedMagOwned", true)
		notify(player, "Erweitertes Magazin gefunden.", "Success")
		refresh(player)
	elseif lootType == "RedDot" then
		player:SetAttribute("RedDotOwned", true)
		notify(player, "Rotpunktvisier gefunden.", "Success")
		refresh(player)
	elseif lootType == "Flashlight" then
		player:SetAttribute("FlashlightOwned", true)
		notify(player, "Taschenlampe gefunden. Mit F einschalten.", "Success")
		if player.Character then ModelService.AttachWeapon(player.Character, {
			WeaponName = player:GetAttribute("Weapon") or "Pistol",
			FlashlightOwned = true,
			FlashlightOn = player:GetAttribute("FlashlightOn") == true,
			RedDotOwned = player:GetAttribute("RedDotOwned") == true,
			ExtendedMagOwned = player:GetAttribute("ExtendedMagOwned") == true,
		}) end
		refresh(player)
	elseif lootType == "Cash" then
		player:SetAttribute("Cash", (player:GetAttribute("Cash") or 0) + amount)
		notify(player, "$" .. amount .. " gefunden.", "Success")
		refresh(player)
	elseif Config.Inventory.Items[lootType] then
		changeItem(player, lootType, amount)
		notify(player, lootType .. " gefunden.", "Success")
		refresh(player)
	end
end

local function findPlayer(userId)
	if type(userId) ~= "number" then return nil end
	return Players:GetPlayerByUserId(math.floor(userId))
end

local function validTradeItem(itemName)
	for _, allowed in Config.Trading.Items do
		if allowed == itemName then return true end
	end
	return false
end

local function sendTradeState(session)
	if not session then return end
	local aOffer = session.offers[session.a]
	local bOffer = session.offers[session.b]
	remotes.TradeState:FireClient(session.a, "Open", session.b.UserId, session.b.DisplayName, aOffer, bOffer, session.accepted[session.a] == true, session.accepted[session.b] == true)
	remotes.TradeState:FireClient(session.b, "Open", session.a.UserId, session.a.DisplayName, bOffer, aOffer, session.accepted[session.b] == true, session.accepted[session.a] == true)
end

local function closeTrade(session, message)
	if not session then return end
	tradeByPlayer[session.a] = nil
	tradeByPlayer[session.b] = nil
	activeTrades[session] = nil
	remotes.TradeState:FireClient(session.a, "Closed")
	remotes.TradeState:FireClient(session.b, "Closed")
	if message then notify(session.a, message, "Info"); notify(session.b, message, "Info") end
end

local function setTradeValue(player, itemName, amount)
	if not validTradeItem(itemName) then return false end
	amount = math.floor(tonumber(amount) or 0)
	return amount > 0 and amount <= (player:GetAttribute(itemName) or 0)
end

local function addTradeValue(player, itemName, amount)
	player:SetAttribute(itemName, (player:GetAttribute(itemName) or 0) + amount)
end

local function completeTrade(session)
	local aOffer = session.offers[session.a]
	local bOffer = session.offers[session.b]
	if not aOffer or not bOffer or not setTradeValue(session.a, aOffer.item, aOffer.amount) or not setTradeValue(session.b, bOffer.item, bOffer.amount) then
		closeTrade(session, "Handel abgebrochen: Angebot nicht mehr verfügbar.")
		return
	end
	addTradeValue(session.a, aOffer.item, -aOffer.amount)
	addTradeValue(session.b, aOffer.item, aOffer.amount)
	addTradeValue(session.b, bOffer.item, -bOffer.amount)
	addTradeValue(session.a, bOffer.item, bOffer.amount)
	closeTrade(session, "Handel abgeschlossen.")
	refresh(session.a)
	refresh(session.b)
end

local function canUseShop(player)
	local trader = shopAccess[player]
	local root = getRoot(player)
	local traderRoot = trader and trader.PrimaryPart
	return trader and root and traderRoot and (root.Position - traderRoot.Position).Magnitude <= 18
end

local function connectTraderPrompts()
	local traders = map and map:FindFirstChild("Traders")
	if not traders then return end
	for _, trader in traders:GetChildren() do
		local prompt = trader:FindFirstChild("TradePrompt", true)
		if prompt and prompt:IsA("ProximityPrompt") then
			prompt.Triggered:Connect(function(player)
				shopAccess[player] = trader
				remotes.OpenShop:FireClient(player, trader.Name)
			end)
		end
	end
end

local function allowed(player)
	local now = os.clock()
	if now - (lastAction[player] or 0) < Config.Trading.Cooldown then return false end
	lastAction[player] = now
	return true
end

local function promptProduct(player, productName)
	local productId = Config.Monetization[productName .. "ProductId"]
	if not productId or productId <= 0 then
		notify(player, "Dieses Robux-Produkt ist noch nicht im Creator Dashboard konfiguriert.", "Info")
		return
	end
	MarketplaceService:PromptProductPurchase(player, productId)
end

if Config.Monetization.ScoutBackpackProductId > 0 then productRewards[Config.Monetization.ScoutBackpackProductId] = "ScoutBackpack" end
if Config.Monetization.TacticalBackpackProductId > 0 then productRewards[Config.Monetization.TacticalBackpackProductId] = "TacticalBackpack" end
if Config.Monetization.FlashlightProductId > 0 then productRewards[Config.Monetization.FlashlightProductId] = "Flashlight" end

local function grantProduct(player, reward)
	if reward == "ScoutBackpack" then upgradeBackpack(player, "Scout", true)
	elseif reward == "TacticalBackpack" then upgradeBackpack(player, "Tactical", true)
	elseif reward == "Flashlight" then InventoryService.CollectLoot(player, "Flashlight", 1) end
end

function InventoryService.Start(remoteFolder, createdMap)
	remotes = remoteFolder
	map = createdMap
	for _, player in Players:GetPlayers() do setupPlayer(player) end
	Players.PlayerAdded:Connect(setupPlayer)
	Players.PlayerRemoving:Connect(function(player)
		savePlayer(player)
		initialized[player] = nil
		lastAction[player] = nil
		shopAccess[player] = nil
		local session = tradeByPlayer[player]
		if session then closeTrade(session, "Handel beendet.") end
	end)
	connectTraderPrompts()

	remotes.InventoryAction.OnServerEvent:Connect(function(player, action, value)
		if type(action) ~= "string" or not allowed(player) then return end
		if action == "ToggleFlashlight" then toggleFlashlight(player)
		elseif action == "Reload" then reload(player)
		elseif action == "UseMedkit" then useMedkit(player)
		elseif action == "BuyBackpack" and type(value) == "string" and canUseShop(player) then upgradeBackpack(player, value, false)
		elseif action == "BuyAttachment" and type(value) == "string" and canUseShop(player) then buyAttachment(player, value)
		elseif action == "BuyItem" and type(value) == "string" and canUseShop(player) then buyItem(player, value)
		elseif action == "SellItem" and type(value) == "string" and canUseShop(player) then sellItem(player, value)
		end
	end)

	remotes.RobuxAction.OnServerEvent:Connect(function(player, productName)
		if type(productName) == "string" and allowed(player) then promptProduct(player, productName) end
	end)

	remotes.TradeAction.OnServerEvent:Connect(function(player, action, value, amount)
		if type(action) ~= "string" or not allowed(player) then return end
		if action == "ListPlayers" then
			local list = {}
			for _, other in Players:GetPlayers() do
				if other ~= player then table.insert(list, { UserId = other.UserId, Name = other.DisplayName }) end
			end
			remotes.TradePlayers:FireClient(player, list)
		elseif action == "Request" then
			local target = findPlayer(value)
			local root = getRoot(player)
			local targetRoot = target and getRoot(target)
			if not target or target == player or tradeByPlayer[player] or tradeByPlayer[target] or not root or not targetRoot or (root.Position - targetRoot.Position).Magnitude > Config.Trading.MaxDistance then
				notify(player, "Spieler ist zu weit entfernt oder bereits im Handel.", "Error")
				return
			end
			local session = { a = player, b = target, offers = {}, accepted = {} }
			activeTrades[session] = true
			tradeByPlayer[player] = session
			tradeByPlayer[target] = session
			notify(target, player.DisplayName .. " möchte handeln.", "Info")
			sendTradeState(session)
		elseif action == "SetOffer" then
			local session = tradeByPlayer[player]
			local numericAmount = math.floor(tonumber(amount) or 0)
			if session and setTradeValue(player, value, numericAmount) then
				session.offers[player] = { item = value, amount = numericAmount }
				session.accepted[player] = nil
				session.accepted[session.a == player and session.b or session.a] = nil
				sendTradeState(session)
			end
		elseif action == "Accept" then
			local session = tradeByPlayer[player]
			if session then
				session.accepted[player] = true
				if session.accepted[session.a] and session.accepted[session.b] then completeTrade(session) else sendTradeState(session) end
			end
		elseif action == "Cancel" then
			closeTrade(tradeByPlayer[player], "Handel abgebrochen.")
		end
	end)

	MarketplaceService.ProcessReceipt = function(receiptInfo)
		local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
		local reward = productRewards[receiptInfo.ProductId]
		if not player or not reward then return Enum.ProductPurchaseDecision.NotProcessedYet end
		grantProduct(player, reward)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	game:BindToClose(function()
		for _, player in Players:GetPlayers() do savePlayer(player) end
	end)
end

return InventoryService
