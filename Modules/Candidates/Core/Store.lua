--- Local candidate store (sync-ready).

local GB = GuildBeacon
local Store = {}
GB.Modules.Candidates = GB.Modules.Candidates or {}
GB.Modules.Candidates.Store = Store

local function GetData()
    local profile = GB.API:GetProfile()
    profile.candidates = profile.candidates or { messages = {}, people = {} }
    return profile.candidates
end

function Store:AddMessage(entry)
    local data = GetData()
    table.insert(data.messages, 1, entry)
    local maxEntries = GB.API:GetModuleConfig().inbox.maxEntries or 200
    while #data.messages > maxEntries do
        table.remove(data.messages)
    end
    self:TouchPerson(entry.from, entry)
end

function Store:TouchPerson(name, entry)
    if not name or name == "" then
        return
    end
    local data = GetData()
    local people = data.people
    local person = people[name]
    if not person then
        local config = GB.API:GetModuleConfig().candidates
        person = {
            name = name,
            status = config.defaultStatus or "new",
            firstSeen = entry and entry.at or time(),
            lastSeen = entry and entry.at or time(),
            notes = "",
        }
        people[name] = person
    else
        person.lastSeen = entry and entry.at or time()
    end
    GB.API:DispatchInternal("GUILDBEACON_CANDIDATE_UPDATED", name, person)
end

function Store:GetPeople()
    return GetData().people
end

function Store:GetMessages()
    return GetData().messages
end

function Store:SetStatus(name, status)
    local data = GetData()
    local person = data.people[name]
    if person then
        person.status = status
        GB.API:DispatchInternal("GUILDBEACON_CANDIDATE_UPDATED", name, person)
    end
end

function Store:ExportJSON()
    local data = GetData()
    if C_EncodingUtil and C_EncodingUtil.SerializeJSON then
        return C_EncodingUtil.SerializeJSON(data)
    end
    return nil
end
