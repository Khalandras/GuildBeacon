--- Recruitment message scheduler (stub).

local GB = GuildBeacon
local Scheduler = {}
GB.Modules.Beacon = GB.Modules.Beacon or {}
GB.Modules.Beacon.Scheduler = Scheduler

local ticker

local CHANNEL_HANDLERS = {
    guild = function(msg) SendChatMessage(msg, "GUILD") end,
    say = function(msg) SendChatMessage(msg, "SAY") end,
    yell = function(msg) SendChatMessage(msg, "YELL") end,
}

local function IsOfficer()
    local rank = select(2, GetGuildInfo("player"))
    return rank == 0 or rank == 1
end

local function InInstance()
    return IsInInstance()
end

local function RenderTemplate(body)
    local guild = GetGuildInfo("player") or ""
    body = body:gsub("{guild}", guild)
    body = body:gsub("{player}", UnitName("player") or "")
    return body
end

local function GetActiveTemplate(config)
    local id = config.activeTemplateId or "default"
    for _, template in ipairs(config.templates or {}) do
        if template.id == id then
            return template
        end
    end
    return config.templates and config.templates[1]
end

function Scheduler:Stop()
    if ticker then
        ticker:Cancel()
        ticker = nil
    end
end

function Scheduler:Start()
    self:Stop()
    local config = GB.API:GetModuleConfig().beacon
    if not config.enabled then
        return
    end
    if config.onlyWhenOfficer and not IsOfficer() then
        return
    end
    local interval = math.max(5, (config.intervalMinutes or 15) * 60)
    ticker = C_Timer.NewTicker(interval, function()
        self:Tick()
    end)
end

function Scheduler:Tick()
    local config = GB.API:GetModuleConfig().beacon
    if config.pauseInInstance and InInstance() then
        return
    end
    if config.onlyWhenOfficer and not IsOfficer() then
        return
    end
    local template = GetActiveTemplate(config)
    if not template or not template.body then
        return
    end
    local message = RenderTemplate(template.body)
    for _, channel in ipairs(config.channels or {}) do
        local handler = CHANNEL_HANDLERS[channel]
        if handler then
            pcall(handler, message)
        end
    end
end

function Scheduler:Preview()
    local config = GB.API:GetModuleConfig().beacon
    local template = GetActiveTemplate(config)
    if not template then
        return ""
    end
    return RenderTemplate(template.body)
end
