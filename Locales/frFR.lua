--- French strings.

local GB = GuildBeacon
GB.LocaleCatalogs = GB.LocaleCatalogs or { enUS = {}, frFR = {} }
local L = GB.LocaleCatalogs.frFR

L["ADDON_LOADED"] = "%s charge (v%s)."
L["TYPE_HELP"] = "Tape /gb ou /guildbeacon pour les commandes."
L["CMD_HELP"] = "Commandes : config, beacon start|stop|preview, inbox, candidates, status"
L["CMD_UNKNOWN"] = "Commande inconnue. %s"
L["BEACON_PREVIEW"] = "Apercu : %s"
L["BEACON_STARTED"] = "Balise de recrutement demarree."
L["BEACON_STOPPED"] = "Balise de recrutement arretee."
L["STATUS_HEADER"] = "Modules : Beacon=%s Inbox=%s Candidates=%s"
L["CONFIG_STUB"] = "Panneau de reglages bientot disponible. Utilise /gb status pour l'instant."

if GetLocale and GetLocale() == "frFR" then
    GB.ApplyLocale("frFR")
end
