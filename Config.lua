--- Defaults and migrations for GuildBeacon.

GuildBeacon = GuildBeacon or {}
local GB = GuildBeacon

GB.ADDON_NAME = "GuildBeacon"
GB.Version = "0.2.0"

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
    },
}

GB.DB_VERSION = 2

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
end
