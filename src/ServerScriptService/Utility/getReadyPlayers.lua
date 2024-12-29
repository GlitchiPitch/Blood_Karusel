local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Constants = require(ReplicatedStorage.Constants)

local function getReadyPlayers()
	local readyPlayers = {}
	for _, player: Player in Players:GetPlayers() do
		if player.Character then
			table.insert(readyPlayers, player)
		end
	end

	if #readyPlayers > Constants.MIN_PLAYERS then		
		return readyPlayers
	else
		return {}
	end
end

return getReadyPlayers