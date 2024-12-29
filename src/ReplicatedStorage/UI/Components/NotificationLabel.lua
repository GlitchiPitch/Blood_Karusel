local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UI = ReplicatedStorage.UI
local Objects = UI.Objects

local notificationLabelTemplate = Objects.Notification.NotificationLabel

local function create() : typeof(notificationLabelTemplate)
    local notificationLabel = notificationLabelTemplate:Clone()
    return notificationLabel
end

return create