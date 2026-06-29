--- Inbox module lifecycle.

local GB = GuildBeacon
local M = GB.Modules.Inbox or {}
GB.Modules.Inbox = M

local Module = {}
M.Module = Module

function Module:OnInitialize()
    if M.WhisperCapture then
        M.WhisperCapture:Initialize(GB.API)
    end
    if M.GuildCapture then
        M.GuildCapture:Initialize(GB.API)
    end
end

function Module:OnEnable()
    if M.WhisperCapture then
        M.WhisperCapture:Enable()
    end
    if M.GuildCapture then
        M.GuildCapture:Enable()
    end
end

function Module:OnDisable()
    if M.WhisperCapture then
        M.WhisperCapture:Disable()
    end
    if M.GuildCapture then
        M.GuildCapture:Disable()
    end
end

function Module:GetMeta()
    return {
        name = "Inbox",
        defaultEnabled = true,
        OnInitialize = function(meta) Module:OnInitialize(meta) end,
        OnEnable = function(meta) Module:OnEnable(meta) end,
        OnDisable = function(meta) Module:OnDisable(meta) end,
    }
end
