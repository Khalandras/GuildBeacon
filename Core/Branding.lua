--- Guild chrome tokens (DA NØX / GuildHub companion).

local GB = GuildBeacon
local Branding = {}
GB.Internal.Branding = Branding

Branding.HEX = {
    gold = "d4af37",
    phosphor = "b794f6",
    nox = "2d1848",
    wine = "6b1d3a",
    textPrimary = "f2f0f5",
    textSecondary = "a89cb8",
    textMuted = "6b6178",
    success = "45c4b0",
    warning = "d4a84b",
    error = "c45c5c",
    info = "6b8cce",
}

Branding.COLORS = Branding.HEX

function Branding:Colorize(text, colorKey)
    local hex = self.HEX[colorKey] or self.HEX.gold
    return string.format("|cff%s%s|r", hex, text)
end

function Branding:Title()
    return self:Colorize("Guild", "gold") .. self:Colorize("Beacon", "phosphor")
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
