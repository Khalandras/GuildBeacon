--- Settings panel placeholder.

local GB = GuildBeacon
GB.UI = GB.UI or {}

local ConfigPanel = {}
GB.UI.ConfigPanel = ConfigPanel

function ConfigPanel:Toggle()
    GB.API:Print(GB.L("CONFIG_STUB"))
end

function ConfigPanel:Open()
    self:Toggle()
end
