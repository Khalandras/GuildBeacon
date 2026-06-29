--- Khalandras palette and optional core detection.

local GB = GuildBeacon
local Branding = {}
GB.Internal.Branding = Branding

Branding.COLORS = {
    gold = "d4af37",
    bordeaux = "8c2a3a",
    muted = "9a8b7f",
}

function Branding:Colorize(text, colorKey)
    local hex = self.COLORS[colorKey] or self.COLORS.gold
    return string.format("|cff%s%s|r", hex, text)
end

function Branding:Title()
    return self:Colorize("Guild", "gold") .. self:Colorize("Beacon", "bordeaux")
end

function Branding:HasKhalandrasCore()
    return KhalandrasUICore ~= nil and KhalandrasUICore.API ~= nil
end

function Branding:GetAccentTexture()
    if self:HasKhalandrasCore() and KhalandrasUICore.Internal and KhalandrasUICore.Internal.Branding then
        return KhalandrasUICore.Internal.Branding.GetAccentTexture and KhalandrasUICore.Internal.Branding:GetAccentTexture()
    end
    return nil
end
