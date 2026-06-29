--- Candidates module lifecycle.

local GB = GuildBeacon
local M = GB.Modules.Candidates or {}
GB.Modules.Candidates = M

local Module = {}
M.Module = Module

function Module:OnInitialize()
    self.api = GB.API
end

function Module:OnEnable()
    local bus = GB.Internal.EventBus
    if not bus then
        return
    end
    bus:Subscribe(Module, "GUILDBEACON_INBOX_MESSAGE", function()
        if GB.UI.Dashboard and GB.UI.Dashboard.frame and GB.UI.Dashboard.frame:IsShown() then
            GB.UI.Dashboard:Refresh()
        end
    end)
    bus:Subscribe(Module, "GUILDBEACON_CANDIDATE_UPDATED", function()
        if GB.UI.Dashboard and GB.UI.Dashboard.frame and GB.UI.Dashboard.frame:IsShown() then
            GB.UI.Dashboard:Refresh()
        end
    end)
end

function Module:OnDisable()
    local bus = GB.Internal.EventBus
    if bus then
        bus:UnsubscribeAll(Module)
    end
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
