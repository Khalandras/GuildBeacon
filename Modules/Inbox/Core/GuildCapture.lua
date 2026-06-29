--- Guild chat keyword capture.

local GB = GuildBeacon
local GuildCapture = {}
GB.Modules.Inbox.GuildCapture = GuildCapture

local api
local subscribed

local function MatchesKeywords(text, keywords)
    if not text or not keywords then
        return false
    end
    local lower = string.lower(text)
    for _, keyword in ipairs(keywords) do
        if keyword ~= "" and lower:find(string.lower(keyword), 1, true) then
            return true
        end
    end
    return false
end

function GuildCapture:Initialize(busApi)
    api = busApi
end

function GuildCapture:OnGuildMessage(event, text, sender, ...)
    if GB.IsSecret(sender) or GB.IsSecret(text) then
        return
    end
    local config = GB.API:GetModuleConfig().inbox
    if not config.enabled or not config.captureGuildChat then
        return
    end
    if sender == UnitName("player") then
        return
    end
    if not MatchesKeywords(text, config.guildKeywords) then
        return
    end
    local store = GB.Modules.Candidates.Store
    if store then
        store:AddMessage({
            channel = "guild",
            from = sender,
            body = text,
            at = time(),
        })
    end
end

function GuildCapture:Enable()
    if not api or subscribed then
        return
    end
    subscribed = true
    api:Subscribe("CHAT_MSG_GUILD", function(event, text, sender, ...)
        GuildCapture:OnGuildMessage(event, text, sender, ...)
    end)
end

function GuildCapture:Disable()
    if api and subscribed then
        api:UnsubscribeAll(GuildCapture)
        subscribed = nil
    end
end
