--- Whisper capture for recruitment inbox.

local GB = GuildBeacon
GB.Modules.Inbox = GB.Modules.Inbox or {}
local WhisperCapture = {}
GB.Modules.Inbox.WhisperCapture = WhisperCapture

local api
local subscribed

function WhisperCapture:Initialize(busApi)
    api = busApi
end

function WhisperCapture:OnChatMessage(event, text, sender, ...)
    if GB.IsSecret(sender) or GB.IsSecret(text) then
        return
    end
    local config = GB.API:GetModuleConfig().inbox
    if not config.enabled or not config.captureWhispers then
        return
    end
    if event ~= "CHAT_MSG_WHISPER" and event ~= "CHAT_MSG_BN_WHISPER" then
        return
    end
    local store = GB.Modules.Candidates.Store
    if store then
        store:AddMessage({
            channel = event == "CHAT_MSG_BN_WHISPER" and "bnet" or "whisper",
            from = sender,
            body = text,
            at = time(),
        })
    end
end

function WhisperCapture:Enable()
    if not api or subscribed then
        return
    end
    subscribed = true
    api:Subscribe("CHAT_MSG_WHISPER", function(event, text, sender, ...)
        WhisperCapture:OnChatMessage(event, text, sender, ...)
    end)
    api:Subscribe("CHAT_MSG_BN_WHISPER", function(event, text, sender, ...)
        WhisperCapture:OnChatMessage(event, text, sender, ...)
    end)
end

function WhisperCapture:Disable()
    if api and subscribed then
        api:UnsubscribeAll(WhisperCapture)
        subscribed = nil
    end
end
