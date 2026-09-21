local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Config = require(ReplicatedStorage.Shared.Config)
local MovementController = require(script.Parent.MovementController)
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local shootEvent = remotes:WaitForChild("Shoot")
local buildEvent = remotes:WaitForChild("BuildBarricade")
local stateEvent = remotes:WaitForChild("State")
local inventoryAction = remotes:WaitForChild("InventoryAction")
local inventoryState = remotes:WaitForChild("InventoryState")
local notifyEvent = remotes:WaitForChild("Notify")
local openShopEvent = remotes:WaitForChild("OpenShop")
local tradeAction = remotes:WaitForChild("TradeAction")
local tradeState = remotes:WaitForChild("TradeState")
local tradePlayers = remotes:WaitForChild("TradePlayers")
local robuxAction = remotes:WaitForChild("RobuxAction")

local colors = {
	panel = Color3.fromRGB(13, 20, 23),
	panelLight = Color3.fromRGB(24, 34, 37),
	line = Color3.fromRGB(102, 112, 108),
	text = Color3.fromRGB(241, 232, 211),
	muted = Color3.fromRGB(174, 185, 167),
	red = Color3.fromRGB(182, 63, 62),
	green = Color3.fromRGB(78, 163, 93),
	gold = Color3.fromRGB(229, 184, 83),
	blue = Color3.fromRGB(41, 72, 98),
}

MovementController.Start(Config.Player)

local gui = Instance.new("ScreenGui")
gui.Name = "SurvivalHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local function stroke(object, color, thickness)
	local line = Instance.new("UIStroke")
	line.Color = color or colors.line
	line.Thickness = thickness or 1
	line.Transparency = 0.15
	line.Parent = object
	return line
end

local function panel(name, size, position, parent)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = size
	frame.Position = position
	frame.BackgroundColor3 = colors.panel
	frame.BackgroundTransparency = 0.06
	frame.BorderSizePixel = 0
	frame.Parent = parent or gui
	stroke(frame, colors.line, 1)
	return frame
end

local function label(name, text, size, position, parent, textSize, color)
	local object = Instance.new("TextLabel")
	object.Name = name
	object.Text = text
	object.Size = size
	object.Position = position
	object.BackgroundTransparency = 1
	object.TextColor3 = color or colors.text
	object.Font = Enum.Font.GothamBold
	object.TextSize = textSize or 14
	object.TextXAlignment = Enum.TextXAlignment.Left
	object.TextYAlignment = Enum.TextYAlignment.Center
	object.Parent = parent or gui
	return object
end

local function button(name, text, size, position, parent, callback, accent)
	local object = Instance.new("TextButton")
	object.Name = name
	object.Text = text
	object.Size = size
	object.Position = position
	object.BackgroundColor3 = accent or colors.panelLight
	object.BackgroundTransparency = 0.05
	object.BorderSizePixel = 0
	object.TextColor3 = colors.text
	object.Font = Enum.Font.GothamBold
	object.TextSize = 13
	object.AutoButtonColor = true
	object.Parent = parent
	stroke(object, colors.line, 1)
	object.Activated:Connect(callback)
	return object
end

local backpackFrame, tradeFrame

local hud = panel("HUD", UDim2.fromOffset(430, 172), UDim2.fromOffset(18, 18))
label("Title", "ZÜRICH: LAST STAND", UDim2.fromOffset(250, 26), UDim2.fromOffset(16, 10), hud, 20)
label("Phase", "TAG 1", UDim2.fromOffset(130, 26), UDim2.fromOffset(280, 10), hud, 16, colors.gold)
local health = label("Health", "LEBEN 0 / 100", UDim2.fromOffset(190, 28), UDim2.fromOffset(16, 44), hud, 15)
local healthBack = Instance.new("Frame")
healthBack.Size = UDim2.fromOffset(190, 10)
healthBack.Position = UDim2.fromOffset(16, 73)
healthBack.BackgroundColor3 = Color3.fromRGB(33, 43, 43)
healthBack.BorderSizePixel = 0
healthBack.Parent = hud
local healthFill = Instance.new("Frame")
healthFill.Size = UDim2.fromScale(1, 1)
healthFill.BackgroundColor3 = colors.red
healthFill.BorderSizePixel = 0
healthFill.Parent = healthBack
label("Stats", "MUNITION 0   ·   MATERIAL 0   ·   $0", UDim2.fromOffset(390, 26), UDim2.fromOffset(16, 92), hud, 13, colors.muted)
local loadout = label("Loadout", "RUCKSACK SMALL  ·  0/6 SLOTS", UDim2.fromOffset(390, 22), UDim2.fromOffset(16, 116), hud, 12, colors.muted)
button("BackpackButton", "B  RUCKSACK", UDim2.fromOffset(112, 27), UDim2.fromOffset(16, 140), hud, function() backpackFrame.Visible = not backpackFrame.Visible end, colors.blue)
button("TradeButton", "T  SPIELERHANDEL", UDim2.fromOffset(140, 27), UDim2.fromOffset(138, 140), hud, function() tradeFrame.Visible = not tradeFrame.Visible; tradeAction:FireServer("ListPlayers") end, colors.blue)
button("FlashlightButton", "F  TASCHENLAMPE", UDim2.fromOffset(132, 27), UDim2.fromOffset(288, 140), hud, function() inventoryAction:FireServer("ToggleFlashlight") end, colors.panelLight)

local banner = panel("Banner", UDim2.fromOffset(460, 62), UDim2.new(0.5, -230, 0, 18))
banner.Visible = false
local bannerText = label("Text", "", UDim2.fromScale(1, 1), UDim2.fromOffset(0, 0), banner, 23, colors.gold)
bannerText.TextXAlignment = Enum.TextXAlignment.Center

local hint = panel("Hint", UDim2.fromOffset(310, 48), UDim2.new(0.5, -155, 1, -70))
local hintText = label("HintText", "KLICK  SCHIESSEN   ·   R  NACHLADEN   ·   E  BAUEN", UDim2.fromScale(1, 1), UDim2.fromOffset(0, 0), hint, 12, colors.text)
hintText.TextXAlignment = Enum.TextXAlignment.Center

backpackFrame = panel("Backpack", UDim2.fromOffset(560, 470), UDim2.new(0.5, -280, 0.5, -235))
backpackFrame.Visible = false
label("Header", "RUCKSACK  //  AUSRÜSTUNG", UDim2.fromOffset(520, 34), UDim2.fromOffset(22, 16), backpackFrame, 23)
local backpackInfo = label("Info", "", UDim2.fromOffset(520, 24), UDim2.fromOffset(22, 52), backpackFrame, 13, colors.muted)
label("SlotsHeader", "GEGENSTÄNDE", UDim2.fromOffset(250, 24), UDim2.fromOffset(22, 92), backpackFrame, 12, colors.gold)
local itemList = label("Items", "MEDKIT\nMUNITION\nMATERIAL", UDim2.fromOffset(230, 90), UDim2.fromOffset(22, 120), backpackFrame, 15, colors.text)
label("AttachmentHeader", "WAFFEN-ATTACHMENTS", UDim2.fromOffset(260, 24), UDim2.fromOffset(284, 92), backpackFrame, 12, colors.gold)
local attachmentList = label("Attachments", "", UDim2.fromOffset(250, 96), UDim2.fromOffset(284, 120), backpackFrame, 14, colors.muted)
button("UseMedkit", "Q  MEDKIT BENUTZEN", UDim2.fromOffset(180, 34), UDim2.fromOffset(22, 372), backpackFrame, function() inventoryAction:FireServer("UseMedkit") end, colors.red)
button("CloseBackpack", "SCHLIESSEN  [B]", UDim2.fromOffset(180, 34), UDim2.fromOffset(22, 414), backpackFrame, function() backpackFrame.Visible = false end)

local shopFrame = panel("Shop", UDim2.fromOffset(390, 700), UDim2.new(1, -410, 0.5, -350))
shopFrame.Visible = false
local shopTitle = label("Header", "HÄNDLER", UDim2.fromOffset(350, 34), UDim2.fromOffset(18, 16), shopFrame, 23)
label("Sub", "KAUFEN · VERKAUFEN · UPGRADEN", UDim2.fromOffset(350, 22), UDim2.fromOffset(18, 48), shopFrame, 11, colors.muted)
local shopY = 82
local function shopButton(text, action, value, accent)
	local created = button("ShopAction", text, UDim2.fromOffset(350, 36), UDim2.fromOffset(18, shopY), shopFrame, function() inventoryAction:FireServer(action, value) end, accent)
	shopY += 43
	return created
end
shopButton("🎒  Scout-Rucksack     $250", "BuyBackpack", "Scout", colors.green)
shopButton("🎒  Tactical-Rucksack  $650", "BuyBackpack", "Tactical", colors.green)
shopButton("🎒  Heavy-Rucksack      $1200", "BuyBackpack", "Heavy", colors.green)
shopButton("◉  Rotpunktvisier      $180", "BuyAttachment", "RedDot", colors.blue)
shopButton("▣  Erweitertes Magazin  $300", "BuyAttachment", "ExtendedMag", colors.blue)
shopButton("🔦 Taschenlampe       $100", "BuyAttachment", "Flashlight", colors.blue)
shopButton("+10 Munition          $30", "BuyItem", "Ammo", colors.panelLight)
shopButton("+1 Medkit             $70", "BuyItem", "Medkit", colors.panelLight)
shopButton("+5 Material           $45", "BuyItem", "Materials", colors.panelLight)
shopButton("10 Munition verkaufen  +$8", "SellItem", "Ammo", colors.panelLight)
shopButton("1 Medkit verkaufen     +$35", "SellItem", "Medkit", colors.panelLight)
shopButton("5 Material verkaufen   +$12", "SellItem", "Materials", colors.panelLight)
local robuxButton = button("Robux", "ROBux: Scout-Rucksack", UDim2.fromOffset(350, 36), UDim2.fromOffset(18, shopY), shopFrame, function() robuxAction:FireServer("ScoutBackpack") end, colors.red)
shopY += 43
button("CloseShop", "SCHLIESSEN", UDim2.fromOffset(150, 34), UDim2.fromOffset(18, 658), shopFrame, function() shopFrame.Visible = false end)

tradeFrame = panel("Trade", UDim2.fromOffset(420, 510), UDim2.new(0, 18, 1, -528))
tradeFrame.Visible = false
local tradeTitle = label("Header", "SPIELERHANDEL", UDim2.fromOffset(380, 32), UDim2.fromOffset(18, 14), tradeFrame, 22)
local tradeStatus = label("Status", "T drücken: Spieler suchen", UDim2.fromOffset(380, 26), UDim2.fromOffset(18, 46), tradeFrame, 12, colors.muted)
local playerList = Instance.new("ScrollingFrame")
playerList.Name = "PlayerList"
playerList.Size = UDim2.fromOffset(382, 170)
playerList.Position = UDim2.fromOffset(18, 80)
playerList.BackgroundColor3 = colors.panelLight
playerList.BackgroundTransparency = 0.35
playerList.BorderSizePixel = 0
playerList.CanvasSize = UDim2.new()
playerList.AutomaticCanvasSize = Enum.AutomaticSize.Y
playerList.ScrollBarThickness = 5
playerList.Parent = tradeFrame
stroke(playerList, colors.line, 1)
local playerLayout = Instance.new("UIListLayout")
playerLayout.Padding = UDim.new(0, 6)
playerLayout.Parent = playerList
local offerText = label("Offer", "DEIN ANGEBOT: —\nPARTNER: —", UDim2.fromOffset(380, 55), UDim2.fromOffset(18, 264), tradeFrame, 13, colors.text)
button("AmmoOffer", "+10 MUNITION", UDim2.fromOffset(116, 34), UDim2.fromOffset(18, 330), tradeFrame, function() tradeAction:FireServer("SetOffer", "Ammo", 10) end, colors.blue)
button("MaterialOffer", "+2 MATERIAL", UDim2.fromOffset(116, 34), UDim2.fromOffset(142, 330), tradeFrame, function() tradeAction:FireServer("SetOffer", "Materials", 2) end, colors.blue)
button("MedkitOffer", "+1 MEDKIT", UDim2.fromOffset(116, 34), UDim2.fromOffset(266, 330), tradeFrame, function() tradeAction:FireServer("SetOffer", "Medkits", 1) end, colors.blue)
button("CashOffer", "+$50", UDim2.fromOffset(116, 34), UDim2.fromOffset(18, 372), tradeFrame, function() tradeAction:FireServer("SetOffer", "Cash", 50) end, colors.blue)
button("AcceptTrade", "ANGEBOT ANNEHMEN", UDim2.fromOffset(185, 38), UDim2.fromOffset(142, 372), tradeFrame, function() tradeAction:FireServer("Accept") end, colors.green)
button("CancelTrade", "ABBRECHEN", UDim2.fromOffset(150, 34), UDim2.fromOffset(18, 424), tradeFrame, function() tradeAction:FireServer("Cancel"); tradeFrame.Visible = false end, colors.red)

local phase, day = "Tag", 1
local function attr(name, fallback)
	local value = player:GetAttribute(name)
	if value == nil then return fallback end
	return value
end

local function updateHud()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local currentHealth = humanoid and math.floor(humanoid.Health) or 0
	local maxHealth = humanoid and math.floor(humanoid.MaxHealth) or 100
	health.Text = string.format("LEBEN  %d / %d", currentHealth, maxHealth)
	healthFill.Size = UDim2.fromScale(math.clamp(currentHealth / math.max(maxHealth, 1), 0, 1), 1)
	healthFill.BackgroundColor3 = currentHealth > 35 and colors.red or Color3.fromRGB(225, 126, 71)

	local weaponName = attr("Weapon", "Pistol")
	local weapon = Config.Weapon.Types[weaponName] or Config.Weapon.Types.Pistol
	local magazineSize = (weapon.MagazineSize or Config.Weapon.MagazineSize)
		+ (attr("ExtendedMagOwned", false) and Config.Inventory.Attachments.ExtendedMag.MagazineBonus or 0)
	local stats = hud:FindFirstChild("Stats")
	if stats then
		stats.Text = string.format(
			"%s  ·  MAG %d/%d   ·   RESERVE %d   ·   MATERIAL %d   ·   $%d   ·   KILLS %d",
			string.upper(weapon.DisplayName or weaponName),
			attr("Magazine", 0),
			magazineSize,
			attr("Ammo", 0),
			attr("Materials", 0),
			attr("Cash", 0),
			attr("Kills", 0)
		)
	end
	loadout.Text = string.format(
		"RUCKSACK %s  ·  %d SLOTS  ·  MEDKIT %d",
		string.upper(tostring(attr("BackpackTier", "Small"))),
		attr("BackpackSlots", 6),
		attr("Medkits", 0)
	)
	itemList.Text = string.format(
		"WAFFE      %s\nMEDKIT     x%d\nMUNITION   x%d\nMATERIAL   x%d",
		weapon.DisplayName or weaponName,
		attr("Medkits", 0),
		attr("Ammo", 0),
		attr("Materials", 0)
	)
	local attachments = {
		"Rotpunktvisier   " .. (attr("RedDotOwned", false) and "✓" or "—"),
		"Erweitertes Mag. " .. (attr("ExtendedMagOwned", false) and "✓" or "—"),
		"Taschenlampe     " .. (attr("FlashlightOwned", false) and (attr("FlashlightOn", false) and "AN" or "AUS") or "—"),
	}
	attachmentList.Text = table.concat(attachments, "\n")
	backpackInfo.Text = string.format(
		"%s-Rucksack  ·  %d Inventarplätze  ·  B zum Schliessen",
		tostring(attr("BackpackTier", "Small")),
		attr("BackpackSlots", 6)
	)
end
local function showBanner(text, color)
	bannerText.Text = text
	bannerText.TextColor3 = color or colors.gold
	banner.Visible = true
	banner.BackgroundTransparency = 0.04
	TweenService:Create(banner, TweenInfo.new(0.25), { BackgroundTransparency = 0.04 }):Play()
	task.delay(2.5, function() if bannerText.Text == text then banner.Visible = false end end)
end

local function clearPlayerList()
	for _, child in playerList:GetChildren() do
		if child:IsA("TextButton") then child:Destroy() end
	end
end

tradePlayers.OnClientEvent:Connect(function(list)
	clearPlayerList()
	if #list == 0 then
		local empty = label("Empty", "Keine anderen Spieler online.", UDim2.fromOffset(350, 34), UDim2.fromOffset(12, 8), playerList, 13, colors.muted)
		return
	end
	for _, info in list do
		button("Player", "HANDELN  ·  " .. info.Name, UDim2.new(1, -12, 0, 34), UDim2.fromOffset(6, 0), playerList, function()
			tradeAction:FireServer("Request", info.UserId)
		end, colors.panel)
	end
end)

tradeState.OnClientEvent:Connect(function(action, partnerId, partnerName, ownOffer, partnerOffer, ownAccepted, partnerAccepted)
	if action == "Closed" then
		tradeStatus.Text = "Handel geschlossen"
		offerText.Text = "DEIN ANGEBOT: —\nPARTNER: —"
		return
	end
	tradeFrame.Visible = true
	tradeTitle.Text = "HANDEL  ·  " .. tostring(partnerName)
	tradeStatus.Text = string.format("%s  %s", ownAccepted and "✓ DU BIST BEREIT" or "○ DU", partnerAccepted and "✓ PARTNER BEREIT" or "○ PARTNER")
	local own = ownOffer and (ownOffer.item .. " x" .. ownOffer.amount) or "—"
	local other = partnerOffer and (partnerOffer.item .. " x" .. partnerOffer.amount) or "—"
	offerText.Text = "DEIN ANGEBOT: " .. own .. "\nPARTNER: " .. other
end)

openShopEvent.OnClientEvent:Connect(function(traderName)
	shopTitle.Text = "HÄNDLER  ·  " .. traderName
	shopFrame.Visible = true
end)

notifyEvent.OnClientEvent:Connect(function(message, kind)
	local color = kind == "Error" and colors.red or (kind == "Success" and colors.green or colors.gold)
	showBanner(message, color)
	updateHud()
end)

stateEvent.OnClientEvent:Connect(function(newPhase, newDay)
	phase, day = newPhase == "Night" and "Nacht" or "Tag", newDay
	showBanner(string.upper(phase) .. " " .. day, colors.gold)
	local phaseLabel = hud:FindFirstChild("Phase")
	if phaseLabel then phaseLabel.Text = string.upper(phase) .. " " .. day end
end)

inventoryState.OnClientEvent:Connect(updateHud)

for _, attribute in { "Weapon", "Ammo", "Materials", "Medkits", "Cash", "Kills", "BackpackTier", "BackpackSlots", "FlashlightOwned", "FlashlightOn", "RedDotOwned", "ExtendedMagOwned" } do
	player:GetAttributeChangedSignal(attribute):Connect(updateHud)
end

player.CharacterAdded:Connect(function(character)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.HealthChanged:Connect(updateHud)
	updateHud()
end)

mouse.Button1Down:Connect(function()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root then shootEvent:FireServer(root.Position + Vector3.new(0, 1.5, 0), mouse.Hit.Position - root.Position) end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.B then
		backpackFrame.Visible = not backpackFrame.Visible
	elseif input.KeyCode == Enum.KeyCode.T then
		tradeFrame.Visible = not tradeFrame.Visible
		if tradeFrame.Visible then tradeAction:FireServer("ListPlayers") end
	elseif input.KeyCode == Enum.KeyCode.F then
		inventoryAction:FireServer("ToggleFlashlight")
	elseif input.KeyCode == Enum.KeyCode.R then
		inventoryAction:FireServer("Reload")
	elseif input.KeyCode == Enum.KeyCode.E then
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root then buildEvent:FireServer(root.Position + root.CFrame.LookVector * 8) end
	end
end)

updateHud()
task.spawn(function()
	while true do
		updateHud()
		task.wait(0.25)
	end
end)
