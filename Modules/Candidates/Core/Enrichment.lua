--- RaiderIO profile enrichment (optional).

local GB = GuildBeacon
GB.Modules.Candidates = GB.Modules.Candidates or {}
local Enrichment = {}
GB.Modules.Candidates.Enrichment = Enrichment

local CACHE_TTL = 3600

function Enrichment:IsAvailable()
    return RaiderIO ~= nil and type(RaiderIO.GetProfile) == "function"
end

function Enrichment:ExtractScore(profile)
    if not profile then
        return 0
    end
    local mk = profile.mythicKeystoneProfile
    if mk then
        return mk.currentScore or mk.score or 0
    end
    return 0
end

function Enrichment:ExtractRaidSummary(profile)
    if not profile or not profile.raidProfile then
        return ""
    end
    local raid = profile.raidProfile
    local parts = {}
    local progress = raid.mainProgress or raid.progress
    if type(progress) == "table" then
        for i = 1, math.min(3, #progress) do
            local p = progress[i]
            if p and p.shortName and p.progress then
                parts[#parts + 1] = string.format("%s %d/%d", p.shortName, p.progress.killCount or 0, p.progress.numBosses or 0)
            end
        end
    end
    return table.concat(parts, ", ")
end

function Enrichment:Fetch(name, realm)
    if not self:IsAvailable() then
        return nil
    end
    local ok, profile = pcall(RaiderIO.GetProfile, name, realm)
    if not ok or not profile then
        return nil
    end
    return {
        score = self:ExtractScore(profile),
        raid = self:ExtractRaidSummary(profile),
        fetchedAt = time(),
    }
end

function Enrichment:EnrichPerson(person)
    if not person or not GB.API:GetModuleConfig().candidates.enrichRaiderIO then
        return person
    end
    person.rio = person.rio or {}
    local fetchedAt = person.rio.fetchedAt or 0
    if time() - fetchedAt < CACHE_TTL and person.rio.score then
        return person
    end
    local name, realm = person.name, person.realm
    if not realm then
        local W = GB.UI.Widgets
        if W then
            name, realm = W:ParseNameRealm(person.name)
        end
    end
    local data = self:Fetch(name, realm)
    if data then
        person.rio = data
    end
    return person
end
