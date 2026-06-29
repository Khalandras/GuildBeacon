--- Central event bus.

local GB = GuildBeacon
local Internal = GB.Internal
local EventBus = {}
Internal.EventBus = EventBus

local eventFrame
local subscribers = {}
local registeredEvents = {}

local function GetList(event)
    if not subscribers[event] then
        subscribers[event] = {}
    end
    return subscribers[event]
end

function EventBus:Initialize()
    eventFrame = CreateFrame("Frame", "GuildBeaconEventFrame")
    eventFrame:SetScript("OnEvent", function(_, event, ...)
        EventBus:Dispatch(event, ...)
    end)
end

function EventBus:RegisterEvent(event)
    if registeredEvents[event] then
        return
    end
    if type(event) == "string" and event:match("^GUILDBEACON_") then
        registeredEvents[event] = true
        return
    end
    local ok = pcall(eventFrame.RegisterEvent, eventFrame, event)
    registeredEvents[event] = ok or true
end

function EventBus:UnregisterEventIfEmpty(event)
    local list = subscribers[event]
    if not list then
        return
    end
    for _ in pairs(list) do
        return
    end
    if registeredEvents[event] and type(event) == "string" and not event:match("^GUILDBEACON_") then
        pcall(eventFrame.UnregisterEvent, eventFrame, event)
    end
    registeredEvents[event] = nil
    subscribers[event] = nil
end

function EventBus:Dispatch(event, ...)
    local list = subscribers[event]
    if not list then
        return
    end
    for owner, callback in pairs(list) do
        if callback then
            local ok, err = pcall(callback, event, ...)
            if not ok and Internal.Logger then
                Internal.Logger:Log(Internal.Logger.LEVEL.ERROR, "EventBus",
                    "Callback error for %s on %s: %s", tostring(owner), event, GB.SafeToString(err))
            end
        end
    end
end

function EventBus:Subscribe(owner, event, callback)
    if not owner or not event or not callback then
        return
    end
    GetList(event)[owner] = callback
    self:RegisterEvent(event)
end

function EventBus:Unsubscribe(owner, event)
    local list = subscribers[event]
    if not list then
        return
    end
    list[owner] = nil
    self:UnregisterEventIfEmpty(event)
end

function EventBus:UnsubscribeAll(owner)
    for event, list in pairs(subscribers) do
        if list[owner] then
            list[owner] = nil
            self:UnregisterEventIfEmpty(event)
        end
    end
end

function GB.API:Subscribe(event, callback)
    EventBus:Subscribe(self, event, callback)
end

function GB.API:Unsubscribe(event)
    EventBus:Unsubscribe(self, event)
end

function GB.API:UnsubscribeAll(owner)
    EventBus:UnsubscribeAll(owner or self)
end

function GB.API:DispatchInternal(event, ...)
    EventBus:Dispatch(event, ...)
end
