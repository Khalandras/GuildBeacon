--- Entry point.

local ADDON_NAME = (GuildBeacon and GuildBeacon.ADDON_NAME) or ...

local Bootstrap = GuildBeacon and GuildBeacon.Internal and GuildBeacon.Internal.Bootstrap
if Bootstrap and Bootstrap.Start then
    Bootstrap:Start(ADDON_NAME or "GuildBeacon")
end
