--- Slash commands.

local GB = GuildBeacon
GB.UI = GB.UI or {}

local SlashCommands = {}
GB.UI.SlashCommands = SlashCommands

local function PrintHelp()
    GB.API:Print(GB.L("CMD_HELP"))
end

local function CmdStatus()
    local api = GB.API
    GB.API:Print(GB.L("STATUS_HEADER"),
        api:GetModuleState("Beacon") or "n/a",
        api:GetModuleState("Inbox") or "n/a",
        api:GetModuleState("Candidates") or "n/a")
end

local function CmdBeacon(sub, arg)
    if sub == "start" then
        local config = GB.API:GetModuleConfig().beacon
        config.enabled = true
        GB.API:EnableModule("Beacon")
        GB.API:Print(GB.L("BEACON_STARTED"))
    elseif sub == "stop" then
        local config = GB.API:GetModuleConfig().beacon
        config.enabled = false
        GB.API:DisableModule("Beacon")
        GB.API:Print(GB.L("BEACON_STOPPED"))
    elseif sub == "preview" then
        local preview = GB.Modules.Beacon.Scheduler:Preview()
        GB.API:Print(GB.L("BEACON_PREVIEW"), preview)
    else
        PrintHelp()
    end
end

local function CmdCandidates()
    local store = GB.Modules.Candidates.Store
    if not store then
        return
    end
    local count = 0
    for _ in pairs(store:GetPeople()) do
        count = count + 1
    end
    GB.API:Print("Candidates tracked: %d", count)
end

function SlashCommands:Handle(input)
    local cmd, rest = input:match("^(%S*)%s*(.*)$")
    cmd = (cmd or ""):lower()
    rest = rest or ""

    if cmd == "" or cmd == "help" then
        PrintHelp()
    elseif cmd == "config" then
        if GB.UI.ConfigPanel then
            GB.UI.ConfigPanel:Toggle()
        end
    elseif cmd == "status" then
        CmdStatus()
    elseif cmd == "beacon" then
        local sub, arg = rest:match("^(%S*)%s*(.*)$")
        CmdBeacon((sub or ""):lower(), arg)
    elseif cmd == "inbox" then
        local store = GB.Modules.Inbox and GB.Modules.Candidates and GB.Modules.Candidates.Store
        if store then
            GB.API:Print("Inbox messages: %d", #store:GetMessages())
        end
    elseif cmd == "candidates" then
        CmdCandidates()
    else
        GB.API:Print(GB.L("CMD_UNKNOWN"), GB.L("CMD_HELP"))
    end
end

function SlashCommands:Initialize()
    SLASH_GUILDBEACON1 = "/guildbeacon"
    SLASH_GUILDBEACON2 = "/gb"
    SlashCmdList.GUILDBEACON = function(msg)
        SlashCommands:Handle(strtrim(msg or ""))
    end
end
