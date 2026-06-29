--- Defaults and migrations for GuildBeacon.

GuildBeacon = GuildBeacon or {}
local GB = GuildBeacon

GB.ADDON_NAME = "GuildBeacon"
GB.Version = "0.1.0"

GB.DEFAULTS = {
    beacon = {
        enabled = false,
        intervalMinutes = 15,
        jitterMinutes = 3,
        channels = { "guild", "say" },
        templates = {
            {
                id = "default",
                label = "Recrutement",
                body = "Guilde {guild} recrute ! MP pour infos.",
            },
        },
        activeTemplateId = "default",
        onlyWhenOfficer = true,
        pauseInInstance = true,
    },
    inbox = {
        enabled = true,
        captureWhispers = true,
        captureGuildChat = false,
        maxEntries = 200,
    },
    candidates = {
        enabled = true,
        statuses = { "new", "contacted", "trial", "accepted", "rejected", "archived" },
        defaultStatus = "new",
    },
    ui = {
        dashboardKeybind = nil,
    },
}

GB.DB_VERSION = 1

function GB.MigrateDB(db)
    if not db then
        return
    end
    db.version = db.version or 0
    if db.version < 1 then
        db.version = 1
    end
end
