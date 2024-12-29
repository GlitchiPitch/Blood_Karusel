local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UI = ReplicatedStorage.UI
local Components = UI.Components

export type RequiredInstances = {
    NotificationGui: ScreenGui,
}

local requiredInstances: RequiredInstances

local NotificationLabel = require(Components.NotificationLabel)

local function setup()
    local notificationGui = requiredInstances.NotificationGui
    local notificationLabel = NotificationLabel()
    notificationLabel.Parent = notificationGui
end

local function init(
    requiredInstances_: RequiredInstances
)
    warn(`[CLIENT] GUI INIT`)
    requiredInstances = requiredInstances_
    setup()
end

return init