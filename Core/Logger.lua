--- Lightweight logger.

local GB = GuildBeacon
local Internal = GB.Internal
local Logger = {}
Internal.Logger = Logger

Logger.LEVEL = {
    ERROR = 1,
    WARN = 2,
    INFO = 3,
    DEBUG = 4,
}

local debugLevel = Logger.LEVEL.WARN

function Logger:Initialize()
    local db = Internal.ProfileManager and Internal.ProfileManager:GetGlobal()
    if db and db.debugLevel then
        debugLevel = db.debugLevel
    end
end

function Logger:SetLevel(level)
    debugLevel = level or Logger.LEVEL.WARN
end

function Logger:Log(level, tag, message, ...)
    if level > debugLevel then
        return
    end
    Logger:WriteChat(tag, message, ...)
end

function Logger:WriteChat(tag, message, ...)
    local prefix = string.format("|cff%sGuild|r|cff%sBeacon|r", "d4af37", "8c2a3a")
    local text = message or ""
    if select("#", ...) > 0 then
        local ok, formatted = pcall(string.format, message, ...)
        if ok then
            text = formatted
        end
    end
    if tag and tag ~= "" then
        DEFAULT_CHAT_FRAME:AddMessage(string.format("%s [%s] %s", prefix, tag, text))
    else
        DEFAULT_CHAT_FRAME:AddMessage(string.format("%s %s", prefix, text))
    end
end

function GB.API:Print(message, ...)
    Logger:WriteChat(nil, message, ...)
end

function GB.API:Log(level, tag, message, ...)
    Logger:Log(level, tag, message, ...)
end
