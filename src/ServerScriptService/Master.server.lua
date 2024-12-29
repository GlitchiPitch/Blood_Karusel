local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Events = ReplicatedStorage.Events
local Utility = ServerScriptService.Utility
local Constants = require(ReplicatedStorage.Constants)

local notificationRemote = Events.NotificationRemote
local notificationRemoteActions = require(notificationRemote.Actions)

local getReadyPlayers = require(Utility.getReadyPlayers)

local lobby: Folder & {
	Floor: Part,
	Body: Model,
} = workspace.Lobby

local karusel: Folder & {
    Body: Model,
	Hinge: HingeConstraint,
	Doors: Folder & {
		Model & {
			Hinge: HingeConstraint,
		}
	},
} = workspace.Karusel

local readyPlayers: { Player } = {}
local openedDoors: { Model } = {}
local doorsTouchedConnect: { [Model]: RBXScriptConnection } = {}
local playersInRooms: { [Model]: { Player } } = {}
local livePlayerGroupSize = 0
local roomsCount = 0

local function setFloor(gameStatus: boolean)
	if gameStatus then
		lobby.Floor.Transparency = 1
		lobby.Floor.CanCollide = false
		task.wait(1)
		lobby.CanCollide = true
	else
		lobby.Floor.Transparency = 0
		lobby.CanCollide = true
	end
end

local function spinKarusel()
	karusel.Hinge.Enabled = true
	task.wait(Constants.SPIN_KARUSEL_TIMER)
	karusel.Hinge.Enabled = false
end

local function calculatePlayerGroups()
	local players = #readyPlayers
	local killedPlayersCount = math.floor(players * Constants.KILLED_PERCENTAGE)
	local livePlayers = players - killedPlayersCount
	local livePlayersDivivder = 2
	while livePlayers % livePlayersDivivder ~= 0 do
		livePlayersDivivder += 1
	end
	livePlayerGroupSize = livePlayers // livePlayersDivivder
	roomsCount = livePlayersDivivder
end

local function openSpecificDoors()
	local function open(isFirstOpen: boolean)
		for _, door in openedDoors do
			door.PrimaryPart.Transparency = 0.5
			door.PrimaryPart.CanCollide = false

			if isFirstOpen then
				playersInRooms[door] = {}
				doorsTouchedConnect[door] = door.PrimaryPart.Touched:Connect(function(hit: BasePart)
					local player = Players:GetPlayerFromCharacter(hit.Parent)
					if player then
						if not table.find(playersInRooms[door], player) then
							table.insert(playersInRooms[door], player)
						end
					end
				end)
			else
				doorsTouchedConnect[door]:Disconnect()
				doorsTouchedConnect[door] = door.PrimaryPart.Touched:Connect(function(hit: BasePart)
					local player = Players:GetPlayerFromCharacter(hit.Parent)
					if player then
						if table.find(playersInRooms[door], player) then
							table.remove(playersInRooms[door], player)
						end
					end
				end)
			end
		end
	end

	if #openedDoors > 0 then
		open(false)
		return
	end

	local doorIndexies = {}
	for i = 1, #karusel.Doors:GetChildren() do
		table.insert(doorIndexies, i)
	end
	-- get random indexies
	for _ = 1, roomsCount do
		local randomDoorIndex = math.random(#doorIndexies)
		local randomDoor = karusel.Doors:FindFirstChild(doorIndexies[randomDoorIndex])
		table.remove(doorIndexies, randomDoorIndex)
		table.insert(openedDoors, randomDoor)
	end

	open(true)
end

local function closeDoors()
	for _, door in openedDoors do
		door.PrimaryPart.Transparency = 0.5
		door.PrimaryPart.CanCollide = true
	end
end

local function clearRooms()
	for _, playersInRoom in playersInRooms do
		if #playersInRoom > 0 then
			for _, player in playersInRoom do
				if player and player.Character then
					player.Character.Humanoid.Health = 0
				end
			end
		end
	end

	playersInRooms = {}
end

local function safeTimer()
	task.wait(Constants.SAFE_TIMER)
end

local function returnToKaruselTimer()
	task.wait(Constants.RETURN_TO_KARUSEL_TIMER)
end

local function killLosers()
	local playersForKill = table.clone(readyPlayers)
	local safedPlayers = {}
	for _, playersInRoom in playersInRooms do
		for _, player in playersInRoom do
			table.insert(safedPlayers, player)
		end
	end

	for i = 1, #playersForKill do
		if table.find(safedPlayers, playersForKill[i]) then
			table.remove(playersForKill, i)
		end
	end

	for _, player in playersForKill do
		if player and player.Character then
			player.Character.Humanoid.Health = 0
		end
	end
end

local function checkRoommates()
    for _, playersInRoom in playersInRooms do
        if #playersInRoom ~= livePlayerGroupSize then
            for _, player in playersInRoom do
                if player and player.Character then
                    player.Character.Humanoid.Health = 0
                end
            end
        end
    end
end

local function winner(winnerPlayer: Player)
	winnerPlayer:LoadCharacter()
    notificationRemote:FireClient(winnerPlayer, notificationRemoteActions.win)
end

local function startKarusel()
	local function checkLivePlayers()
		for i = 1, #readyPlayers do
			local player = readyPlayers[i]
			if not player or not player.Character or player.Character.Humanoid.Health <= 0 then
                notificationRemote:FireClient(player, notificationRemoteActions.died)
				table.remove(readyPlayers, i)
			end
		end
		return #readyPlayers > 0
	end

	while task.wait(1) do
		if not checkLivePlayers() then
			break
		end
		spinKarusel()
		calculatePlayerGroups()
		openSpecificDoors()
		safeTimer()
		closeDoors()
		killLosers()
        checkRoommates()
		openSpecificDoors()
		returnToKaruselTimer()
		closeDoors()
		clearRooms()
	end

	local winnerPlayer = readyPlayers[1]
	if winnerPlayer then
		winner(winnerPlayer)
	end
end

local function onPlayerAdded(player: Player)
	if not lobby.Floor.CanCollide then
		repeat
			task.wait(1)
		until lobby.Floor.CanCollide
	end
	player:LoadCharacter()
end

local function checkStartGame(): boolean
    readyPlayers = getReadyPlayers()
	return #readyPlayers > 1
end

local function lobbyTimer()
	for i = Constants.LOBBY_TIMER, 0, -1 do
		task.wait(1)
		notificationRemote:FireAllClients(notificationRemoteActions.timer, i)
	end
end

local function startGame()
	setFloor(true)
    startKarusel()
    setFloor(false)
end

local function gameLoop()
	while task.wait() do
        lobbyTimer()
		if checkStartGame() then
            startGame()
        end
	end
end

local function setup()
	Players.CharacterAutoLoads = false
	Players.PlayerAdded:Connect(onPlayerAdded)
end

local function init()
	setup()
	gameLoop()
end

init()
