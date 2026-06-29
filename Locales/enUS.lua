--- English strings.

local GB = GuildBeacon
GB.LocaleCatalogs = GB.LocaleCatalogs or { enUS = {}, frFR = {} }
local L = GB.LocaleCatalogs.enUS
GB.Locale = L

L["ADDON_LOADED"] = "%s loaded (v%s)."
L["TYPE_HELP"] = "Type /gb or /guildbeacon for commands."
L["CMD_HELP"] = "Commands: config, beacon start|stop|preview, inbox, candidates, status"
L["CMD_UNKNOWN"] = "Unknown command. %s"
L["BEACON_PREVIEW"] = "Preview: %s"
L["BEACON_STARTED"] = "Recruitment beacon started."
L["BEACON_STOPPED"] = "Recruitment beacon stopped."
L["STATUS_HEADER"] = "Modules: Beacon=%s Inbox=%s Candidates=%s"
L["CONFIG_STUB"] = "Settings panel coming soon. Use /gb status for now."

function GB.ApplyLocale(locale)
    GB.Locale = GB.LocaleCatalogs[locale] or GB.LocaleCatalogs.enUS
end

function GB.L(key)
    return (GB.Locale or GB.LocaleCatalogs.enUS)[key] or key
end

GB.L = GB.L
