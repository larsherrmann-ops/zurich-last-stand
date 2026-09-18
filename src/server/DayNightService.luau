local Lighting = game:GetService("Lighting")
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local DayNightService = {}

function DayNightService.Start(stateEvent, onNightChanged)
	task.spawn(function()
		local day = 1
		while true do
			Lighting.ClockTime = 10
			Lighting.Brightness = 2
			onNightChanged(false)
			stateEvent:FireAllClients("Day", day)
			task.wait(Config.Cycle.DaySeconds)
			Lighting.ClockTime = 0
			Lighting.Brightness = 0.7
			onNightChanged(true)
			stateEvent:FireAllClients("Night", day)
			task.wait(Config.Cycle.NightSeconds)
			day += 1
		end
	end)
end

return DayNightService
