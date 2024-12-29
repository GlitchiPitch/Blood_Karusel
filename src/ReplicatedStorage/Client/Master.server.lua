local Players = game:GetService("Players")

local player = Players.LocalPlayer
local notificationGui = player.PlayerGui:WaitForChild("Notification") :: ScreenGui

local Client = script.Parent
local Modules = Client.Modules

local Notification = require(Modules.Notification)
local Gui = require(Modules.Gui)

local function init()
    warn(`[CLIENT] INIT`)
    Gui(
        {
            NotificationGui = notificationGui,
        } :: Gui.RequiredInstances
    )
    Notification(
        {
            NotificationGui = notificationGui,
        } :: Notification.RequiredInstances
    )
end

init()