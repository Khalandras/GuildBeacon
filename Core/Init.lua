--- Namespace and shared helpers.

local ADDON_NAME = ...

GuildBeacon = GuildBeacon or {}
local GB = GuildBeacon

GB.ADDON_NAME = ADDON_NAME
GB.Internal = GB.Internal or {}
GB.API = GB.API or {}
GB.Modules = GB.Modules or {}

local function IsSecret(value)
    return issecretvalue and value ~= nil and issecretvalue(value)
end

function GB.IsSecret(value)
    return IsSecret(value)
end

function GB.SafeToString(value)
    if IsSecret(value) then
        return "<restricted>"
    end
    return tostring(value)
end
