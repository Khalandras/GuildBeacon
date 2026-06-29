--- Profiles and per-character settings.

local GB = GuildBeacon
local Internal = GB.Internal
local ProfileManager = {}
Internal.ProfileManager = ProfileManager

local db

local function DeepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local copy = {}
    for k, v in pairs(value) do
        copy[k] = DeepCopy(v)
    end
    return copy
end

local function MergeDefaults(target, defaults)
    for key, value in pairs(defaults) do
        if target[key] == nil then
            target[key] = DeepCopy(value)
        elseif type(value) == "table" and type(target[key]) == "table" then
            MergeDefaults(target[key], value)
        end
    end
end

function ProfileManager:Initialize()
    _G.GuildBeaconDB = _G.GuildBeaconDB or {}
    db = _G.GuildBeaconDB
    GB.MigrateDB(db)
    db.global = db.global or {}
    db.profiles = db.profiles or {}
    db.profileKeys = db.profileKeys or {}
    if not db.global.debugLevel then
        db.global.debugLevel = Internal.Logger and Internal.Logger.LEVEL.WARN or 2
    end
end

function ProfileManager:GetGlobal()
    return db and db.global
end

function ProfileManager:GetPlayerKey()
    local name = UnitName("player")
    local realm = GetRealmName()
    if GB.IsSecret(name) or GB.IsSecret(realm) then
        return "Default"
    end
    return string.format("%s - %s", name, realm)
end

function ProfileManager:GetActiveProfileName()
    local key = self:GetPlayerKey()
    return db.profileKeys[key] or "Default"
end

function ProfileManager:GetProfile(name)
    name = name or self:GetActiveProfileName()
    if not db.profiles[name] then
        db.profiles[name] = DeepCopy(GB.DEFAULTS)
    end
    MergeDefaults(db.profiles[name], GB.DEFAULTS)
    return db.profiles[name]
end

function ProfileManager:GetModuleConfig()
    return self:GetProfile()
end

function ProfileManager:EnsureProfileForPlayer()
    local key = self:GetPlayerKey()
    if not db.profileKeys[key] then
        db.profileKeys[key] = "Default"
    end
    self:GetProfile(db.profileKeys[key])
end

function GB.API:GetProfile()
    return ProfileManager:GetProfile()
end

function GB.API:GetActiveProfileName()
    return ProfileManager:GetActiveProfileName()
end

function GB.API:GetModuleConfig()
    return ProfileManager:GetModuleConfig()
end
