--- Defaults and migrations for GuildBeacon.

GuildBeacon = GuildBeacon or {}
local GB = GuildBeacon

GB.ADDON_NAME = "GuildBeacon"
GB.Version = "0.3.2"

GB.DEFAULTS = {
    beacon = {
        enabled = false,
        intervalMinutes = 15,
        jitterMinutes = 3,
        minSecondsBetweenPosts = 300,
        channels = { "guild" },
        templates = {
            {
                id = "default",
                label = "Recrutement",
                body = "[{guild}] Nous recrutons ! MP {player} ou repondez ici pour candidater.",
            },
            {
                id = "raid",
                label = "Raid",
                body = "[{guild}] Recrutement raid : MP pour infos, spec et dispo.",
            },
        },
        activeTemplateId = "default",
        rotateTemplates = true,
        rotateChannels = true,
        onlyWhenOfficer = true,
        minOfficerRank = 1,
        pauseInInstance = true,
        pauseInCombat = true,
        dryRun = true,
        livePostConfirmed = false,
        state = {
            templateIndex = 1,
            channelIndex = 1,
            lastPostedAt = 0,
            lastPostedBody = "",
        },
    },
    inbox = {
        enabled = true,
        captureWhispers = true,
        captureGuildChat = true,
        guildKeywords = { "recrute", "recruit", "candidature", "apply", "mp", "whisper" },
        maxEntries = 300,
    },
    candidates = {
        enabled = true,
        statuses = { "new", "contacted", "trial", "accepted", "rejected", "archived" },
        defaultStatus = "new",
        enrichRaiderIO = true,
        autoEnrichOnMessage = true,
    },
    ui = {
        dashboardScale = 1,
        frameWidth = 720,
        frameHeight = 560,
        layoutVersion = 11,
        lastTab = "triage",
        selectedKey = nil,
        statusFilter = "",
        searchQuery = "",
        diagnosticsOpen = false,
        framePoint = nil,
        sortBy = "recent",
    },
}

GB.DB_VERSION = 15

function GB.MigrateDB(db)
    if not db then
        return
    end
    db.version = db.version or 0
    if db.version < 1 then
        db.version = 1
    end
    if db.version < 2 then
        for _, profile in pairs(db.profiles or {}) do
            profile.beacon = profile.beacon or {}
            profile.beacon.state = profile.beacon.state or {}
            profile.inbox = profile.inbox or {}
            if profile.inbox.guildKeywords == nil then
                profile.inbox.guildKeywords = GB.DEFAULTS.inbox.guildKeywords
            end
            profile.candidates = profile.candidates or { messages = {}, people = {} }
        end
        db.version = 2
    end
    if db.version < 3 then
        for _, profile in pairs(db.profiles or {}) do
            profile.ui = profile.ui or {}
            local ui = profile.ui
            if ui.lastTab == nil then
                ui.lastTab = "triage"
            end
            if ui.lastTab == "candidates" or ui.lastTab == "inbox" then
                ui.lastTab = "triage"
            elseif ui.lastTab == "tests" then
                ui.lastTab = "settings"
                ui.diagnosticsOpen = true
            end
            if ui.sortBy == nil then
                ui.sortBy = "recent"
            end
            if ui.diagnosticsOpen == nil then
                ui.diagnosticsOpen = false
            end
        end
        db.version = 3
    end
    if db.version < 4 then
        for _, profile in pairs(db.profiles or {}) do
            profile.candidateStore = profile.candidateStore or { messages = {}, people = {} }
            local legacy = profile.candidates
            if type(legacy) == "table" then
                if legacy.messages and not profile.candidateStore.messages[1] then
                    profile.candidateStore.messages = legacy.messages
                    legacy.messages = nil
                end
                if legacy.people and not next(profile.candidateStore.people) then
                    profile.candidateStore.people = legacy.people
                    legacy.people = nil
                end
            end
            profile.candidateStore.messages = profile.candidateStore.messages or {}
            profile.candidateStore.people = profile.candidateStore.people or {}
        end
        db.version = 4
    end
    if db.version < 5 then
        for _, profile in pairs(db.profiles or {}) do
            profile.ui = profile.ui or {}
            local ui = profile.ui
            ui.frameWidth = ui.frameWidth or 680
            ui.frameHeight = ui.frameHeight or 520
            ui.layoutVersion = 2
        end
        db.version = 5
    end
    if db.version < 6 then
        local seq = 0
        for _, profile in pairs(db.profiles or {}) do
            local store = profile.candidateStore
            if store and type(store.messages) == "table" then
                for _, msg in ipairs(store.messages) do
                    if type(msg) == "table" then
                        if not msg.id or msg.id == "" then
                            seq = seq + 1
                            msg.id = string.format("migrated-%d-%d", time(), seq)
                        end
                        if msg.read == nil then
                            msg.read = false
                        end
                    end
                end
            end
        end
        db.version = 6
    end
    if db.version < 7 then
        for _, profile in pairs(db.profiles or {}) do
            profile.ui = profile.ui or {}
            profile.ui.layoutVersion = 3
        end
        db.version = 7
    end
    if db.version < 8 then
        for _, profile in pairs(db.profiles or {}) do
            profile.ui = profile.ui or {}
            profile.ui.layoutVersion = 4
        end
        db.version = 8
    end
    if db.version < 9 then
        for _, profile in pairs(db.profiles or {}) do
            profile.ui = profile.ui or {}
            profile.ui.layoutVersion = 5
        end
        db.version = 9
    end
    if db.version < 10 then
        for _, profile in pairs(db.profiles or {}) do
            profile.ui = profile.ui or {}
            profile.ui.layoutVersion = 6
        end
        db.version = 10
    end
    if db.version < 11 then
        for _, profile in pairs(db.profiles or {}) do
            profile.ui = profile.ui or {}
            profile.ui.layoutVersion = 7
        end
        db.version = 11
    end
    if db.version < 12 then
        for _, profile in pairs(db.profiles or {}) do
            profile.ui = profile.ui or {}
            profile.ui.layoutVersion = 8
        end
        db.version = 12
    end
    if db.version < 13 then
        for _, profile in pairs(db.profiles or {}) do
            profile.ui = profile.ui or {}
            profile.ui.layoutVersion = 9
        end
        db.version = 13
    end
    if db.version < 14 then
        local function knownTab(tab)
            tab = string.lower(tostring(tab or ""))
            return tab == "triage" or tab == "pipeline" or tab == "beacon" or tab == "settings"
        end
        for _, profile in pairs(db.profiles or {}) do
            profile.ui = profile.ui or {}
            profile.ui.layoutVersion = 10
            local tab = profile.ui.lastTab
            if tab == "inbox" then
                profile.ui.lastTab = "triage"
            elseif tab == "candidates" or tab == "candidats" then
                profile.ui.lastTab = "pipeline"
            elseif tab == "tests" or tab == "test" then
                profile.ui.lastTab = "settings"
                profile.ui.diagnosticsOpen = true
            elseif tab and tab ~= "" and not knownTab(tab) then
                profile.ui.lastTab = "triage"
            end
        end
        db.version = 14
    end
    if db.version < 15 then
        for _, profile in pairs(db.profiles or {}) do
            profile.ui = profile.ui or {}
            profile.ui.layoutVersion = 11
        end
        db.version = 15
    end
end
