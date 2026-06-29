--- Whisper capture for recruitment inbox.

local GB = GuildBeacon
local WhisperCapture = {}
GB.Modules.Inbox = GB.Modules.Inbox or {}
GB.Modules.Inbox.WhisperCapture = WhisperCapture

local api

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
    local store = GB.Modules.Candidates and GB.Modules.Candidates.Store
    if store then
        store:AddMessage({
            channel = "whisper",
            from = sender,
            body = text,
            at = time(),
        })
    end
    GB.API:DispatchInternal("GUILDBEACON_INBOX_MESSAGE", sender, text)
end

function WhisperCapture:Enable()
    if not api then
        return
    end
    api:Subscribe("CHAT_MSG_WHISPER", function(event, ...) WhisperCapture:OnChatMessage(event, ...) end)
    api:Subscribe("CHAT_MSG_BN_WHISPER", function(event, ...) WhisperCapture:OnChatMessage(event, ...) end)
end

function WhisperCapture:Disable()
    if api then
        api:UnsubscribeAll(WhisperCapture)
    end
end
