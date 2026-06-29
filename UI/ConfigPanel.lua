--- Settings panel (redirects to dashboard settings tab).

local GB = GuildBeacon
local ConfigPanel = {}
GB.UI.ConfigPanel = ConfigPanel

function ConfigPanel:HasChannel(channel)
    if GB.UI.Dashboard then
        return GB.UI.Dashboard:HasChannel(channel)
    end
    return false
end

function ConfigPanel:SetChannel(channel, enabled)
    if GB.UI.Dashboard then
        GB.UI.Dashboard:SetChannel(channel, enabled)
    end
end

function ConfigPanel:Toggle()
    if GB.UI.Dashboard then
        GB.UI.Dashboard:Open("settings")
    end
end

function ConfigPanel:Open()
    if GB.UI.Dashboard then
        GB.UI.Dashboard:Open("settings")
    end
end
