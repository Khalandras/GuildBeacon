--- In-game diagnostics (driven from dashboard Tests tab).

local GB = GuildBeacon
local Internal = GB.Internal
local TestHarness = {}
Internal.TestHarness = TestHarness

local TEST_PREFIX = "[GB_TEST]"

local function Log(line)
    if GB.UI.Dashboard and GB.UI.Dashboard.AppendLog then
        GB.UI.Dashboard:AppendLog(line)
    end
    if Internal.Logger then
        Internal.Logger:Log(Internal.Logger.LEVEL.DEBUG, "Test", "%s", line)
    end
end

function TestHarness:LogBeaconDry(channel, message)
    Log(string.format(GB.L("TEST_DRY_POST"), channel or "?", message or ""))
end

local function GetStore()
    return GB.Modules.Candidates and GB.Modules.Candidates.Store
end

function TestHarness:RunSelf()
    local lines = {}
    local function add(fmt, ...)
        lines[#lines + 1] = string.format(fmt, ...)
    end

    add("GuildBeacon v%s", GB.Version or "?")
    add("Profile: %s", GB.API:GetActiveProfileName())

    local mm = Internal.ModuleManager
    if mm then
        for _, name in ipairs({ "Beacon", "Inbox", "Candidates" }) do
            add("Module %s: %s", name, GB.API:GetModuleState(name) or "missing")
        end
    else
        add("ModuleManager: missing")
    end

    local store = GetStore()
    if store then
        local stats = store:GetStats()
        add("Store: %d candidates, %d inbox", stats.total, #store:GetMessages())
    else
        add("Store: missing")
    end

    local enrich = GB.Modules.Candidates and GB.Modules.Candidates.Enrichment
    add("Raider.IO: %s", enrich and enrich:IsAvailable() and "yes" or "no")

    local config = GB.API:GetModuleConfig().beacon
    add("Beacon dry-run: %s", config.dryRun and "ON" or "OFF")
    add("In guild: %s", IsInGuild() and "yes" or "no")

    if IsInGuild() then
        local _, rankName, rankIndex = GetGuildInfo("player")
        add("Guild rank: %s (%s)", rankName or "?", tostring(rankIndex))
    end

    for _, line in ipairs(lines) do
        Log(line)
    end
    return lines
end

function TestHarness:Seed()
    local store = GetStore()
    if not store then
        Log(GB.L("TEST_FAIL_STORE"))
        return
    end
    local samples = {
        { from = "TestRecruit-Hyjal", body = "Salut, je cherche une guilde pour raid." },
        { from = "TrialDK-Test", body = "DK blood 700, dispo soirs." },
        { from = "ApplyBot-Test", body = "Apply: heal main, offspec dps." },
    }
    for _, sample in ipairs(samples) do
        store:AddMessage({
            channel = "test",
            from = sample.from,
            body = TEST_PREFIX .. " " .. sample.body,
            at = time(),
            test = true,
        })
        local person = store:GetPerson(sample.from)
        if person then
            person.test = true
        end
    end
    Log(GB.L("TEST_SEED_DONE"))
    if GB.UI.Dashboard then
        GB.UI.Dashboard:Refresh()
    end
end

function TestHarness:ClearTestData()
    local profile = GB.API:GetProfile()
    local data = profile.candidateStore
    if not data then
        return
    end
    local removedPeople, removedMsgs = 0, 0
    for key, person in pairs(data.people or {}) do
        if person.test or (key and key:find("Test", 1, true)) then
            data.people[key] = nil
            removedPeople = removedPeople + 1
        end
    end
    local kept = {}
    for _, msg in ipairs(data.messages or {}) do
        if msg.test or (msg.body and msg.body:find(TEST_PREFIX, 1, true)) then
            removedMsgs = removedMsgs + 1
        else
            kept[#kept + 1] = msg
        end
    end
    data.messages = kept
    Log(string.format(GB.L("TEST_CLEAR_DONE"), removedPeople, removedMsgs))
    if GB.UI.Dashboard then
        GB.UI.Dashboard:Refresh()
    end
end

function TestHarness:SimulateWhisper(name, body)
    name = strtrim(name or "")
    body = strtrim(body or "")
    if name == "" or body == "" then
        Log(GB.L("TEST_SIM_WHISPER_USAGE"))
        return
    end
    local store = GetStore()
    if not store then
        return
    end
    store:AddMessage({
        channel = "test-whisper",
        from = name,
        body = TEST_PREFIX .. " " .. body,
        at = time(),
        test = true,
    })
    local person = store:GetPerson(name)
    if person then
        person.test = true
    end
    Log(string.format(GB.L("TEST_SIM_WHISPER_OK"), name))
    if GB.UI.Dashboard then
        GB.UI.Dashboard:Refresh()
    end
end

function TestHarness:TestRaiderIO(name, realm)
    local enrich = GB.Modules.Candidates and GB.Modules.Candidates.Enrichment
    if not enrich or not enrich:IsAvailable() then
        Log(GB.L("TEST_RIO_MISSING"))
        return
    end
    if not name or name == "" then
        if UnitExists("target") and UnitIsPlayer("target") then
            name = UnitName("target")
            realm = GetRealmName()
        else
            name, realm = UnitName("player"), GetRealmName()
        end
    end
    local data = enrich:Fetch(name, realm)
    if not data then
        Log(string.format(GB.L("TEST_RIO_NONE"), name, realm or ""))
        return
    end
    Log(string.format(GB.L("TEST_RIO_OK"), name, data.score or 0, data.raid or GB.L("NO_RAID_DATA")))
end

function TestHarness:DryTickBeacon()
    local config = GB.API:GetModuleConfig().beacon
    local wasDry = config.dryRun
    local wasEnabled = config.enabled
    config.dryRun = true
    config.enabled = true
    local scheduler = GB.Modules.Beacon and GB.Modules.Beacon.Scheduler
    if scheduler then
        scheduler:Tick()
    end
    config.dryRun = wasDry
    config.enabled = wasEnabled
    Log(GB.L("TEST_DRY_TICK_DONE"))
end

function TestHarness:Teardown()
    local mm = Internal.ModuleManager
    if not mm then
        return
    end
    for _, name in ipairs({ "Beacon", "Inbox", "Candidates" }) do
        mm:DisableModule(name)
        mm:EnableModule(name)
    end
    Log(GB.L("TEST_TEARDOWN_DONE"))
end

function TestHarness:SetDebug(enabled)
    local global = Internal.ProfileManager:GetGlobal()
    if not global then
        return
    end
    global.debugLevel = enabled and Internal.Logger.LEVEL.DEBUG or Internal.Logger.LEVEL.WARN
    Internal.Logger:SetLevel(global.debugLevel)
    Log(enabled and GB.L("TEST_DEBUG_ON") or GB.L("TEST_DEBUG_OFF"))
end

function TestHarness:IsDebugEnabled()
    local global = Internal.ProfileManager and Internal.ProfileManager:GetGlobal()
    return global and global.debugLevel == Internal.Logger.LEVEL.DEBUG
end
