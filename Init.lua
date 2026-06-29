--- Entry point.

local ADDON_NAME = ...

local Bootstrap = GuildBeacon and GuildBeacon.Internal and GuildBeacon.Internal.Bootstrap
if Bootstrap and Bootstrap.Start then
    Bootstrap:Start(ADDON_NAME)
end
