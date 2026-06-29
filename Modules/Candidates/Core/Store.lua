--- Local candidate store.

local GB = GuildBeacon
GB.Modules.Candidates = GB.Modules.Candidates or {}
local Store = {}
GB.Modules.Candidates.Store = Store

local Widgets = GB.UI.Widgets
local messageSeq = 0

local function GetEnrichment()
    return GB.Modules.Candidates and GB.Modules.Candidates.Enrichment
end

local function GetStoreData()
    local profile = GB.API:GetProfile()
    if not profile.candidateStore then
        profile.candidateStore = { messages = {}, people = {} }
        local legacy = profile.candidates
        if type(legacy) == "table" then
            if legacy.messages then
                profile.candidateStore.messages = legacy.messages
                legacy.messages = nil
            end
            if legacy.people then
                profile.candidateStore.people = legacy.people
                legacy.people = nil
            end
        end
    end
    profile.candidateStore.messages = profile.candidateStore.messages or {}
    profile.candidateStore.people = profile.candidateStore.people or {}
    return profile.candidateStore
end

local function NextMessageId()
    messageSeq = messageSeq + 1
    return string.format("%d-%d", time(), messageSeq)
end

function Store:AddTimelineEvent(person, eventType, detail)
    if not person then
        return
    end
    person.timeline = person.timeline or {}
    table.insert(person.timeline, 1, {
        at = time(),
        type = eventType,
        detail = detail or "",
    })
    while #person.timeline > 25 do
        table.remove(person.timeline)
    end
end

function Store:AddMessage(entry)
    local data = GetStoreData()
    entry.id = entry.id or NextMessageId()
    entry.at = entry.at or time()
    entry.read = entry.read == true
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
    local data = GetStoreData()
    local people = data.people
    local person = people[fullName]
    local isNew = not person
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
            timeline = {},
        }
        people[fullName] = person
        self:AddTimelineEvent(person, "created", config.defaultStatus or "new")
    else
        person.lastSeen = entry and entry.at or time()
        person.messageCount = (person.messageCount or 0) + 1
    end
    if entry and entry.body and entry.body ~= "" then
        person.lastMessage = entry.body
        if not isNew then
            self:AddTimelineEvent(person, "message", Widgets and Widgets:Truncate(entry.body, 80) or entry.body)
        end
    end
    local config = GB.API:GetModuleConfig().candidates
    if config.autoEnrichOnMessage then
        local enrich = GetEnrichment()
        if enrich then
            enrich:EnrichPerson(person)
        end
    end
    GB.API:DispatchInternal("GUILDBEACON_CANDIDATE_UPDATED", fullName, person)
end

function Store:GetPeople()
    return GetStoreData().people
end

function Store:GetMessages()
    return GetStoreData().messages
end

function Store:GetPerson(key)
    return GetStoreData().people[key]
end

function Store:GetMessagesForPerson(key)
    local list = {}
    for _, msg in ipairs(self:GetMessages()) do
        if msg.from == key then
            list[#list + 1] = msg
        end
    end
    return list
end

function Store:GetUnreadCount()
    local count = 0
    for _, msg in ipairs(self:GetMessages()) do
        if not msg.read then
            count = count + 1
        end
    end
    return count
end

function Store:MarkMessageRead(msgId)
    for _, msg in ipairs(self:GetMessages()) do
        if msg.id == msgId then
            msg.read = true
            GB.API:DispatchInternal("GUILDBEACON_INBOX_READ", msgId)
            return true
        end
    end
    return false
end

function Store:MarkAllRead()
    for _, msg in ipairs(self:GetMessages()) do
        msg.read = true
    end
    GB.API:DispatchInternal("GUILDBEACON_INBOX_READ_ALL")
end

function Store:ArchiveMessage(msgId)
    local data = GetStoreData()
    for i, msg in ipairs(data.messages) do
        if msg.id == msgId then
            msg.archived = true
            msg.read = true
            table.remove(data.messages, i)
            table.insert(data.messages, msg)
            GB.API:DispatchInternal("GUILDBEACON_INBOX_ARCHIVED", msgId)
            return true
        end
    end
    return false
end

function Store:GetTriageItems()
    local items = {}
    local seen = {}
    for _, msg in ipairs(self:GetMessages()) do
        if not msg.archived then
            items[#items + 1] = {
                type = "message",
                key = msg.from,
                msg = msg,
                at = msg.at or 0,
                unread = not msg.read,
            }
            seen[msg.from] = true
        end
    end
    for key, person in pairs(self:GetPeople()) do
        if person.status == "new" and not seen[key] then
            items[#items + 1] = {
                type = "candidate",
                key = key,
                person = person,
                at = person.lastSeen or 0,
                unread = true,
            }
        end
    end
    table.sort(items, function(a, b)
        if a.unread ~= b.unread then
            return a.unread
        end
        return a.at > b.at
    end)
    return items
end

function Store:GetSortedPeople(filterStatus, searchQuery, sortBy)
    local query = strlower(strtrim(searchQuery or ""))
    local list = {}
    for key, person in pairs(self:GetPeople()) do
        if not filterStatus or filterStatus == "" or person.status == filterStatus then
            local match = query == ""
            if not match then
                local hay = strlower(string.format("%s %s %s", key, person.name or "", person.lastMessage or ""))
                match = hay:find(query, 1, true) ~= nil
            end
            if match then
                list[#list + 1] = person
            end
        end
    end
    sortBy = sortBy or "recent"
    table.sort(list, function(a, b)
        if sortBy == "rio" then
            local as = a.rio and a.rio.score or 0
            local bs = b.rio and b.rio.score or 0
            if as ~= bs then
                return as > bs
            end
        elseif sortBy == "status" then
            local order = { new = 1, contacted = 2, trial = 3, accepted = 4, rejected = 5, archived = 6 }
            local ao = order[a.status] or 9
            local bo = order[b.status] or 9
            if ao ~= bo then
                return ao < bo
            end
        end
        return (a.lastSeen or 0) > (b.lastSeen or 0)
    end)
    return list
end

function Store:SetStatus(key, status)
    local person = GetStoreData().people[key]
    if person and person.status ~= status then
        local old = person.status
        person.status = status
        self:AddTimelineEvent(person, "status", string.format("%s -> %s", old, status))
        GB.API:DispatchInternal("GUILDBEACON_CANDIDATE_UPDATED", key, person)
    end
end

function Store:SetNotes(key, notes)
    local person = GetStoreData().people[key]
    if person then
        notes = notes or ""
        if (person.notes or "") ~= notes then
            person.notes = notes
            self:AddTimelineEvent(person, "note", GB.L("TIMELINE_NOTE"))
            GB.API:DispatchInternal("GUILDBEACON_CANDIDATE_UPDATED", key, person)
        end
    end
end

function Store:RemovePerson(key)
    GetStoreData().people[key] = nil
    GB.API:DispatchInternal("GUILDBEACON_CANDIDATE_REMOVED", key)
end

function Store:Enrich(key)
    local person = GetStoreData().people[key]
    if person then
        local enrich = GetEnrichment()
        if enrich then
            enrich:EnrichPerson(person)
            self:AddTimelineEvent(person, "rio", GB.L("TIMELINE_RIO"))
            GB.API:DispatchInternal("GUILDBEACON_CANDIDATE_UPDATED", key, person)
        end
    end
end

function Store:ExportJSON()
    local data = GetStoreData()
    if C_EncodingUtil and C_EncodingUtil.SerializeJSON then
        return C_EncodingUtil.SerializeJSON(data)
    end
    return nil
end

function Store:GetStats()
    local people = self:GetPeople()
    local stats = { total = 0, new = 0, contacted = 0, trial = 0, accepted = 0, rejected = 0 }
    for _, person in pairs(people) do
        stats.total = stats.total + 1
        if person.status == "new" then
            stats.new = stats.new + 1
        elseif person.status == "contacted" then
            stats.contacted = stats.contacted + 1
        elseif person.status == "trial" then
            stats.trial = stats.trial + 1
        elseif person.status == "accepted" then
            stats.accepted = stats.accepted + 1
        elseif person.status == "rejected" then
            stats.rejected = stats.rejected + 1
        end
    end
    return stats
end
