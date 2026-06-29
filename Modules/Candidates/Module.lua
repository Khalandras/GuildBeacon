--- Candidates module lifecycle.

local GB = GuildBeacon
local M = GB.Modules.Candidates or {}
GB.Modules.Candidates = M

local Module = {}
M.Module = Module

function Module:OnInitialize()
end

function Module:OnEnable()
end

function Module:OnDisable()
end

function Module:GetMeta()
    return {
        name = "Candidates",
        defaultEnabled = true,
        OnInitialize = function(meta) Module:OnInitialize(meta) end,
        OnEnable = function(meta) Module:OnEnable(meta) end,
        OnDisable = function(meta) Module:OnDisable(meta) end,
    }
end
