local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local shootEvent = remotes:WaitForChild("Shoot")
local buildEvent = remotes:WaitForChild("BuildBarricade")
local stateEvent = remotes:WaitForChild("State")

local gui = Instance.new("ScreenGui")
gui.Name = "SurvivalHUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")
local hud = Instance.new("TextLabel")
hud.Size = UDim2.fromOffset(560, 86)
hud.Position = UDim2.fromOffset(18, 18)
hud.BackgroundColor3 = Color3.fromRGB(15, 21, 16)
hud.BackgroundTransparency = 0.15
hud.TextColor3 = Color3.new(1, 1, 1)
hud.Font = Enum.Font.GothamBold
hud.TextSize = 18
hud.TextXAlignment = Enum.TextXAlignment.Left
hud.TextYAlignment = Enum.TextYAlignment.Top
hud.Parent = gui
local banner = Instance.new("TextLabel")
banner.Size = UDim2.fromOffset(480, 65)
banner.Position = UDim2.new(0.5, -240, 0, 22)
banner.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
banner.BackgroundTransparency = 0.2
banner.TextColor3 = Color3.fromRGB(255, 209, 102)
banner.Font = Enum.Font.GothamBlack
banner.TextSize = 26
banner.Visible = false
banner.Parent = gui

local phase, day = "Tag", 1
local function updateHud()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local health = humanoid and math.floor(humanoid.Health) or 0
	hud.Text = string.format("  ZÜRICH: LAST STAND  |  %s %d\n  Leben %d   Munition %d   Material %d   Kills %d\n  Klick: Schiessen   E: Barrikade bauen", phase, day, health, player:GetAttribute("Ammo") or 0, player:GetAttribute("Materials") or 0, player:GetAttribute("Kills") or 0)
end

for _, attribute in { "Ammo", "Materials", "Kills" } do
	player:GetAttributeChangedSignal(attribute):Connect(updateHud)
end
player.CharacterAdded:Connect(function(character)
	character:WaitForChild("Humanoid").HealthChanged:Connect(updateHud)
	updateHud()
end)

stateEvent.OnClientEvent:Connect(function(newPhase, newDay)
	phase, day = newPhase == "Night" and "Nacht" or "Tag", newDay
	banner.Text = string.format("%s %d", string.upper(phase), day)
	banner.Visible = true
	task.delay(2.5, function() banner.Visible = false end)
	updateHud()
end)

mouse.Button1Down:Connect(function()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root then shootEvent:FireServer(root.Position + Vector3.new(0, 1.5, 0), mouse.Hit.Position - root.Position) end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or input.KeyCode ~= Enum.KeyCode.E then return end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root then buildEvent:FireServer(root.Position + root.CFrame.LookVector * 8) end
end)

task.spawn(function()
	while true do updateHud(); task.wait(0.25) end
end)
