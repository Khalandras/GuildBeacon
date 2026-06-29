--- Recruitment message scheduler.

local GB = GuildBeacon
local Internal = GB.Internal
local Scheduler = {}
GB.Modules.Beacon.Scheduler = Scheduler

local timerHandle
local Templates = GB.Modules.Beacon.Templates
local AntiSpam = GB.Modules.Beacon.AntiSpam

local CHANNEL_HANDLERS = {
    guild = function(msg) SendChatMessage(msg, "GUILD") end,
    say = function(msg) SendChatMessage(msg, "SAY") end,
    yell = function(msg) SendChatMessage(msg, "YELL") end,
}

local function IsOfficer(config)
    if not IsInGuild() then
        return false
    end
    local rankIndex = select(3, GetGuildInfo("player"))
    if rankIndex == nil then
        return false
    end
    local maxRank = config.minOfficerRank or 1
    return rankIndex <= maxRank
end

local function ShouldPause(config)
    if config.pauseInInstance and IsInInstance() then
        return true
    end
    if config.pauseInCombat and UnitAffectingCombat("player") then
        return true
    end
    return false
end

function Scheduler:Stop()
    if timerHandle then
        timerHandle:Cancel()
        timerHandle = nil
    end
end

function Scheduler:ScheduleNext()
    self:Stop()
    local config = GB.API:GetModuleConfig().beacon
    if not config.enabled then
        return
    end
    local base = math.max(1, (config.intervalMinutes or 15) * 60)
    local jitter = (config.jitterMinutes or 0) * 60
    local offset = 0
    if jitter > 0 then
        offset = math.random(-jitter, jitter)
    end
    local delay = math.max(30, base + offset)
    timerHandle = C_Timer.NewTimer(delay, function()
        Scheduler:Tick()
        Scheduler:ScheduleNext()
    end)
end

function Scheduler:Start()
    self:Stop()
    local config = GB.API:GetModuleConfig().beacon
    if not config.enabled then
        return
    end
    if config.onlyWhenOfficer and not IsOfficer(config) then
        GB.API:Print(GB.L("BEACON_NOT_OFFICER"))
        return
    end
    self:ScheduleNext()
end

function Scheduler:Tick()
    local config = GB.API:GetModuleConfig().beacon
    if not config.enabled then
        return
    end
    if ShouldPause(config) then
        return
    end
    if config.onlyWhenOfficer and not IsOfficer(config) then
        return
    end
    if InCombatLockdown() then
        return
    end
    local template = Templates:Pick(config)
    if not template or not template.body then
        return
    end
    local message = Templates:Render(template.body)
    local ok, reason = AntiSpam:CanPost(config, message)
    if not ok then
        return
    end
    if not config.dryRun and not config.livePostConfirmed then
        return
    end
    local channels = {}
    if config.rotateChannels then
        local ch = Templates:PickChannel(config)
        if ch then
            channels[#channels + 1] = ch
        end
    else
        channels = config.channels or {}
    end
    local posted = false
    for _, channel in ipairs(channels) do
        if config.dryRun then
            posted = true
            if Internal.TestHarness then
                Internal.TestHarness:LogBeaconDry(channel, message)
            else
                GB.API:Print(GB.L("TEST_DRY_POST"), channel, message)
            end
        else
            local handler = CHANNEL_HANDLERS[channel]
            if handler then
                local success = pcall(handler, message)
                posted = posted or success
            end
        end
    end
    if posted then
        AntiSpam:RecordPost(config, message)
        GB.API:DispatchInternal("GUILDBEACON_BEACON_POSTED", message)
    end
end

function Scheduler:Preview()
    local config = GB.API:GetModuleConfig().beacon
    local msg, channel = Templates:PreviewNext(config)
    if channel then
        return string.format("[%s] %s", channel, msg)
    end
    return msg
end

function Scheduler:GetCooldownSeconds()
    return AntiSpam:SecondsUntilNext(GB.API:GetModuleConfig().beacon)
end

function Scheduler:PostNow()
    self:Tick()
end
