--- Beacon module lifecycle.

local GB = GuildBeacon
local M = GB.Modules.Beacon or {}
GB.Modules.Beacon = M

local Module = {}
M.Module = Module

function Module:OnInitialize()
    self.api = GB.API
end

function Module:OnEnable()
    if M.Scheduler then
        M.Scheduler:Start()
    end
end

function Module:OnDisable()
    if M.Scheduler then
        M.Scheduler:Stop()
    end
end

function Module:OnProfileChanged()
    if M.Scheduler then
        M.Scheduler:Start()
    end
end

function Module:GetMeta()
    return {
        name = "Beacon",
        defaultEnabled = false,
        OnInitialize = function(meta) Module:OnInitialize(meta) end,
        OnEnable = function(meta) Module:OnEnable(meta) end,
        OnDisable = function(meta) Module:OnDisable(meta) end,
        OnProfileChanged = function(meta) Module:OnProfileChanged(meta) end,
    }
end
