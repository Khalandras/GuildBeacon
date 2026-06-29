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
    local stats = GB.Modules.Candidates.Store and GB.Modules.Candidates.Store:GetStats()
    GB.API:Print(GB.L("STATUS_HEADER"),
        api:GetModuleState("Beacon") or "n/a",
        api:GetModuleState("Inbox") or "n/a",
        api:GetModuleState("Candidates") or "n/a")
    if stats then
        GB.API:Print(GB.L("CANDIDATES_STATS"), stats.total, stats.new, stats.trial)
    end
end

local function CmdBeacon(sub)
    sub = (sub or ""):lower()
    local config = GB.API:GetModuleConfig().beacon
    local scheduler = GB.Modules.Beacon.Scheduler
    if sub == "start" then
        config.enabled = true
        GB.API:EnableModule("Beacon")
        GB.API:Print(GB.L("BEACON_STARTED"))
    elseif sub == "stop" then
        config.enabled = false
        GB.API:DisableModule("Beacon")
        GB.API:Print(GB.L("BEACON_STOPPED"))
    elseif sub == "preview" then
        if scheduler then
            GB.API:Print(GB.L("BEACON_PREVIEW"), scheduler:Preview())
        end
    elseif sub == "now" then
        if scheduler then
            local dash = GB.UI.Dashboard
            if dash and not dash:CanPostLive() then
                GB.API:Print(GB.L("TEST_LIVE_BLOCKED"))
                return
            end
            scheduler:PostNow()
            GB.API:Print(config.dryRun and GB.L("TEST_DRY_TICK_DONE") or GB.L("BEACON_POSTED"))
        end
    else
        PrintHelp()
    end
end

local function CmdExport()
    local store = GB.Modules.Candidates.Store
    if not store then
        return
    end
    local json = store:ExportJSON()
    if json and C_ChatInfo and C_ChatInfo.CopyChatLine then
        C_ChatInfo.CopyChatLine(json)
        GB.API:Print(GB.L("EXPORT_DONE"))
    else
        GB.API:Print(GB.L("EXPORT_FAIL"))
    end
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
    elseif cmd == "dashboard" or cmd == "dash" then
        if GB.UI.Dashboard then
            GB.UI.Dashboard:Toggle()
        end
    elseif cmd == "status" then
        CmdStatus()
    elseif cmd == "beacon" then
        local sub = rest:match("^(%S*)")
        CmdBeacon(sub)
    elseif cmd == "inbox" then
        local store = GB.Modules.Candidates.Store
        if store then
            GB.API:Print("Inbox: %d messages", #store:GetMessages())
        end
        if GB.UI.Dashboard then
            GB.UI.Dashboard:Open()
            GB.UI.Dashboard:SelectTab("inbox")
        end
    elseif cmd == "candidates" or cmd == "candidats" then
        if GB.UI.Dashboard then
            GB.UI.Dashboard:Open()
            GB.UI.Dashboard:SelectTab("candidates")
        end
    elseif cmd == "tests" or cmd == "test" then
        if GB.UI.Dashboard then
            GB.UI.Dashboard:Open()
            GB.UI.Dashboard:SelectTab("tests")
        end
    elseif cmd == "export" then
        CmdExport()
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
