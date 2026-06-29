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
    local prefix = string.format("|cff%sGuild|r|cff%sBeacon|r", "d4af37", "8c2a3a")
    local text = string.format(message, ...)
    DEFAULT_CHAT_FRAME:AddMessage(string.format("%s [%s] %s", prefix, tag, text))
end

function GB.API:Print(message, ...)
    Logger:Log(Logger.LEVEL.INFO, "Core", message, ...)
end

function GB.API:Log(level, tag, message, ...)
    Logger:Log(level, tag, message, ...)
end
