--- Local candidate store.

local GB = GuildBeacon
local Store = {}
GB.Modules.Candidates.Store = Store

local Enrichment = GB.Modules.Candidates.Enrichment
local Widgets = GB.UI.Widgets

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
    GB.API:DispatchInternal("GUILDBEACON_INBOX_MESSAGE", entry.from, entry.body)
end

function Store:TouchPerson(fullName, entry)
    if not fullName or fullName == "" then
        return
    end
    local name, realm = fullName, GetRealmName()
    if Widgets then
        name, realm = Widgets:ParseNameRealm(fullName)
    end
    local data = GetData()
    local people = data.people
    local person = people[fullName]
    if not person then
        local config = GB.API:GetModuleConfig().candidates
        person = {
            key = fullName,
            name = name,
            realm = realm,
            status = config.defaultStatus or "new",
            firstSeen = entry and entry.at or time(),
            lastSeen = entry and entry.at or time(),
            notes = "",
            messageCount = 0,
            rio = {},
        }
        people[fullName] = person
    else
        person.lastSeen = entry and entry.at or time()
        person.messageCount = (person.messageCount or 0) + 1
    end
    if entry and entry.body and entry.body ~= "" then
        person.lastMessage = entry.body
    end
    local config = GB.API:GetModuleConfig().candidates
    if config.autoEnrichOnMessage and Enrichment then
        Enrichment:EnrichPerson(person)
    end
    GB.API:DispatchInternal("GUILDBEACON_CANDIDATE_UPDATED", fullName, person)
end

function Store:GetPeople()
    return GetData().people
end

function Store:GetMessages()
    return GetData().messages
end

function Store:GetPerson(key)
    return GetData().people[key]
end

function Store:GetSortedPeople(filterStatus)
    local list = {}
    for key, person in pairs(self:GetPeople()) do
        if not filterStatus or filterStatus == "" or person.status == filterStatus then
            list[#list + 1] = person
        end
    end
    table.sort(list, function(a, b)
        return (a.lastSeen or 0) > (b.lastSeen or 0)
    end)
    return list
end

function Store:SetStatus(key, status)
    local person = GetData().people[key]
    if person then
        person.status = status
        GB.API:DispatchInternal("GUILDBEACON_CANDIDATE_UPDATED", key, person)
    end
end

function Store:SetNotes(key, notes)
    local person = GetData().people[key]
    if person then
        person.notes = notes or ""
        GB.API:DispatchInternal("GUILDBEACON_CANDIDATE_UPDATED", key, person)
    end
end

function Store:RemovePerson(key)
    GetData().people[key] = nil
    GB.API:DispatchInternal("GUILDBEACON_CANDIDATE_REMOVED", key)
end

function Store:Enrich(key)
    local person = GetData().people[key]
    if person and Enrichment then
        Enrichment:EnrichPerson(person)
        GB.API:DispatchInternal("GUILDBEACON_CANDIDATE_UPDATED", key, person)
    end
end

function Store:ExportJSON()
    local data = GetData()
    if C_EncodingUtil and C_EncodingUtil.SerializeJSON then
        return C_EncodingUtil.SerializeJSON(data)
    end
    return nil
end

function Store:GetStats()
    local people = self:GetPeople()
    local stats = { total = 0, new = 0, trial = 0, accepted = 0 }
    for _, person in pairs(people) do
        stats.total = stats.total + 1
        if person.status == "new" then
            stats.new = stats.new + 1
        elseif person.status == "trial" then
            stats.trial = stats.trial + 1
        elseif person.status == "accepted" then
            stats.accepted = stats.accepted + 1
        end
    end
    return stats
end
