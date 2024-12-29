local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Constants)

local notificationRemote = ReplicatedStorage.Events.NotificationRemote
local notificationRemoteActions = require(notificationRemote.Actions)

export type RequiredInstances = {
    NotificationGui: ScreenGui,
}

local requiredInstances: RequiredInstances

local function showNotification(isVisible: boolean, text: string)
    local notificationGui = requiredInstances.NotificationGui
    local notification = notificationGui:FindFirstChild("NotificationLabel") :: Frame
    notification.Visible = isVisible
    notification.Label.Text = text
    
end

local function timer(leftTime: number)
    showNotification(leftTime > 0, tostring(leftTime))
end

local function died()
    showNotification(true, "YOU DIED")
    task.wait(Constants.SHOW_NOTIFICATION_TIME)
    showNotification(false, "")
end

local function win()
    showNotification(true, "YOU WIN")
    task.wait(Constants.SHOW_NOTIFICATION_TIME)
    showNotification(false, "")
end

local function returnToKarusel()
    showNotification(true, "REUTRN TO KARUSEL")
    task.wait(Constants.SHOW_NOTIFICATION_TIME)
    showNotification(false, "")
end

local function notificationRemoteConnect(action: string, ...: any)
    local actions = {
        [notificationRemoteActions.timer] = timer,
        [notificationRemoteActions.died] = died,
        [notificationRemoteActions.win] = win,
        [notificationRemoteActions.returnToKarusel] = returnToKarusel,
    }

    if actions[action] then
        actions[action](...)
    end
end

local function setup()
    notificationRemote.OnClientEvent:Connect(notificationRemoteConnect)
end

local function init(
    requiredInstances_: RequiredInstances
)
    warn(`[CLIENT] NOTIFICATION INIT`)
    requiredInstances = requiredInstances_
    setup()
end

return init