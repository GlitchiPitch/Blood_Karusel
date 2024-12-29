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
			Body: Model & { Part },
			Hinge: HingeConstraint,
		}
	},
	Floor: Part,
	Billboard: Part & {
		SurfaceGui: SurfaceGui & {
			Info: Frame & {
				Timer: Frame & {
					Label: TextLabel,
				},
				GroupSize: Frame & {
					Amount: TextLabel,
				}
			},
		},
	}
} = workspace.Karusel

local readyPlayers: { Player } = {}
local openedDoors: { Model } = {}
local doorsTouchedConnect: { [Model]: RBXScriptConnection } = {}
local playersInRooms: { [Model]: { Player } } = {}
local playersDiedConnect: { [Player]: RBXScriptConnection } = {}
local livePlayerGroupSize = 0
local roomsCount = 0

local function setFloor(gameStatus: boolean)
	warn(`setFloor // gameStatus = {gameStatus}`)
	if gameStatus then
		lobby.Floor.Transparency = 1
		lobby.Floor.CanCollide = false
		task.wait(1)
		lobby.Floor.CanCollide = true
	else
		lobby.Floor.Transparency = 0
		lobby.Floor.CanCollide = true
	end
end

local function spinKarusel()
	warn(` ___ spinKarusel ___ `)
	local killFloorConnect: RBXScriptConnection
	karusel.Hinge.Enabled = true
	warn(`=== turn on Hinge ===`)
	karusel.Floor.BrickColor = BrickColor.new("Really red")
	killFloorConnect = karusel.Floor.Touched:Connect(function(hit: BasePart)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if player then
			player.Character.Humanoid.Health = 0
		end
	end)
	task.wait(Constants.SPIN_KARUSEL_TIMER)
	warn(`=== turn off Hinge ===`)
	killFloorConnect:Disconnect()
	karusel.Floor.BrickColor = BrickColor.new("Medium green")
	karusel.Hinge.Enabled = false
end

local function calculatePlayerGroups()
	warn(` === calculatePlayerGroups === `)
	local players = #readyPlayers
	warn(`players amount {players}`)
	local killedPlayersCount = math.floor(players * Constants.KILLED_PERCENTAGE)
	warn(`killedPlayersCount = {killedPlayersCount}`)
	local livePlayers = players - killedPlayersCount
	warn(`livePlayers = {livePlayers}`)
	local livePlayersDivivder = 2
	-- [TESTING]
	if livePlayersDivivder > livePlayers then
		livePlayersDivivder = 1
	else
		while livePlayers % livePlayersDivivder ~= 0 do
			livePlayersDivivder += 1
		end
	end

	livePlayerGroupSize = livePlayers // livePlayersDivivder
	roomsCount = livePlayersDivivder

	warn(`livePlayerGroupSize = {livePlayerGroupSize}`)
	warn(`roomsCount = {roomsCount}`)
end

local function openSpecificDoors()
	warn(` === openSpecificDoors === `)

	if #readyPlayers <= Constants.MIN_PLAYERS then
		return
	end

	local function open(isFirstOpen: boolean)
		warn(`open isFirstOpen = {isFirstOpen}`)
		print("openedDoors", openedDoors)
		for _, door in openedDoors do

			for _, item in door.Body:GetChildren() do
				item.Transparency = 1
			end
			
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
				print("playersInRooms", playersInRooms)
				print("doorsTouchedConnect", doorsTouchedConnect)
				doorsTouchedConnect[door]:Disconnect()
				doorsTouchedConnect[door] = nil
				print("playersInRooms", playersInRooms)
				print("doorsTouchedConnect", doorsTouchedConnect)
				doorsTouchedConnect[door] = door.PrimaryPart.Touched:Connect(function(hit: BasePart)
					local player = Players:GetPlayerFromCharacter(hit.Parent)
					if player and player.Character then
						local playerIndex = table.find(playersInRooms[door], player)
						if playerIndex then
							table.remove(playersInRooms[door], playerIndex)
						end
					end
				end)
			end
		end
	end

	if #openedDoors > 0 then
		open(false)
		print("playersInRooms", playersInRooms)
		print("doorsTouchedConnect", doorsTouchedConnect)
		return
	end

	local doorIndexies = {}
	for i = 1, #karusel.Doors:GetChildren() do
		table.insert(doorIndexies, i)
	end

	print("doorIndexies", doorIndexies)

	-- get random indexies
	for _ = 1, roomsCount do
		local randomDoorIndex = math.random(#doorIndexies)
		local randomDoor = karusel.Doors:FindFirstChild(doorIndexies[randomDoorIndex])
		table.remove(doorIndexies, randomDoorIndex)
		table.insert(openedDoors, randomDoor)
	end
	print("openedDoors", openedDoors)
	open(true)
	print("playersInRooms", playersInRooms)
	print("doorsTouchedConnect", doorsTouchedConnect)
end

local function closeDoors()
	warn(` ___ closeDoors ___ `)
	print("openedDoors", openedDoors)
	for _, door in openedDoors do
		for _, item in door.Body:GetChildren() do
			item.Transparency = item.Name == "Glass" and .8 or 0
		end
		door.PrimaryPart.CanCollide = true
	end
end

local function clearRooms()
	warn(` ___ clearRooms ___ `)
	print("playersInRooms", playersInRooms)

	if #readyPlayers > Constants.MIN_PLAYERS then
		for _, playersInRoom in playersInRooms do
			if #playersInRoom > 0 then
				for _, player in playersInRoom do
					if player and player.Character then
						player.Character.Humanoid.Health = 0
					end
				end
			end
		end

		for i = 1, #doorsTouchedConnect do
			doorsTouchedConnect[i]:Disconnect()
			doorsTouchedConnect[i] = nil
		end
	end

	openedDoors = {}
	playersInRooms = {}
end

local function safeTimer()
	warn(` ___ safeTimer ___ `)

	karusel.Billboard.SurfaceGui.Info.GroupSize.Amount.Text = livePlayerGroupSize

	for i = Constants.SAFE_TIMER, 0, -1 do
		if #readyPlayers <= Constants.MIN_PLAYERS then
			break
		end
		task.wait(1)
		karusel.Billboard.SurfaceGui.Info.Timer.Label.Text = i
		-- print(i)
	end
	
	karusel.Billboard.SurfaceGui.Info.GroupSize.Amount.Text = 0
	karusel.Billboard.SurfaceGui.Info.Timer.Label.Text = 0
end

local function returnToKaruselTimer()
	warn(` ___ returnToKaruselTimer ___ `)
	if #readyPlayers <= Constants.MIN_PLAYERS then
		return
	end
	notificationRemote:FireAllClients(notificationRemoteActions.returnToKarusel)
	for i = Constants.RETURN_TO_KARUSEL_TIMER, 0, -1 do
		if #readyPlayers <= Constants.MIN_PLAYERS then
			break
		end
		task.wait(1)
	end
end

local function killLosers()
	warn(` ___ killLosers ___ `)
	local playersForKill = table.clone(readyPlayers)
	print("playersForKill", playersForKill)
	local safedPlayers = {}
	for _, playersInRoom in playersInRooms do
		for _, player in playersInRoom do
			table.insert(safedPlayers, player)
		end
	end

	print("safedPlayers", safedPlayers)

	for i = 1, #playersForKill do
		if table.find(safedPlayers, playersForKill[i]) then
			table.remove(playersForKill, i)
		end
	end

	print("playersForKill", playersForKill)

	-- в будущем добавить смешную надпись
	for _, player in playersForKill do
		if player and player.Character then
			player.Character.Humanoid.Health = 0
		end
	end

	-- [TESTING]
	task.wait(5)
end

local function checkRoommates()
	warn(`checkRoommates()`)
	print("playersInRooms", playersInRooms)
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
	warn(`winner(winnerPlayer: Player)`)
	task.wait(2)
	winnerPlayer:LoadCharacter()
    notificationRemote:FireClient(winnerPlayer, notificationRemoteActions.win)
	readyPlayers = {}
end

local function preparePlayers()

	warn(` === [SERVER] PREPARE PLAYERS FOR GAME === `)

	for i = 1, #readyPlayers do
		local player = readyPlayers[i]
		player.Character.Humanoid.Died:Once(function()
			notificationRemote:FireClient(player, notificationRemoteActions.died)
			if table.find(readyPlayers, player) then
				table.remove(readyPlayers, i)
			end
			task.wait(2)
			player:LoadCharacter()
		end)
	end
end

local function startKarusel()
	warn(` === [SERVER] START KARUSEL === `)

	preparePlayers()

	local function checkLivePlayers()
		warn(` ___ checkLivePlayers ___ `)
		for i = 1, #readyPlayers do
			local player = readyPlayers[i]

			if not player or not player.Character then -- or player.Character.Humanoid.Health <= 0 
                -- notificationRemote:FireClient(player, notificationRemoteActions.died)
				if table.find(readyPlayers, player) then
					table.remove(readyPlayers, i)
					
				end
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
	warn(` ___ checkStartGame ___`)
    readyPlayers = getReadyPlayers()
	print("readyPlayers", #readyPlayers)
	return #readyPlayers > Constants.MIN_PLAYERS
end

local function lobbyTimer()
	warn(`=== [SERVER] START LOBBY TIMER === `)
	for i = Constants.LOBBY_TIMER, 0, -1 do
		task.wait(1)
		notificationRemote:FireAllClients(notificationRemoteActions.timer, i)
	end
end

local function startGame()
	-- warn(`startGame()`)
	setFloor(true)
    startKarusel()
    setFloor(false)
end

local function gameLoop()
	while task.wait(1) do
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
	warn(`[SERVER] KARUSEL INIT`)
	setup()
	gameLoop()
end

init()
