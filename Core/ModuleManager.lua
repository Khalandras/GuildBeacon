--- Module lifecycle manager.

local GB = GuildBeacon
local Internal = GB.Internal
local L = GB.Locale
local ModuleManager = {}
Internal.ModuleManager = ModuleManager

ModuleManager.STATE = {
    REGISTERED = "REGISTERED",
    INITIALIZED = "INITIALIZED",
    ENABLED = "ENABLED",
    DISABLED = "DISABLED",
}

local modules = {}
local coreReady = false

local function SafeError(err)
    return GB.SafeToString(err)
end

function ModuleManager:Initialize()
    coreReady = true
    for _, entry in pairs(modules) do
        if entry.meta.defaultEnabled ~= false then
            self:EnableModule(entry.name)
        end
    end
end

function ModuleManager:Register(meta)
    if not meta or not meta.name then
        return false
    end
    if modules[meta.name] then
        return false
    end
    modules[meta.name] = {
        name = meta.name,
        meta = meta,
        state = ModuleManager.STATE.REGISTERED,
    }
    return true
end

function ModuleManager:GetModuleCount()
    local count = 0
    for _ in pairs(modules) do
        count = count + 1
    end
    return count
end

function ModuleManager:InitializeModule(name)
    local entry = modules[name]
    if not entry or entry.state ~= ModuleManager.STATE.REGISTERED then
        return
    end
    if entry.meta.OnInitialize then
        local ok, err = pcall(entry.meta.OnInitialize, entry.meta)
        if not ok and Internal.Logger then
            Internal.Logger:Log(Internal.Logger.LEVEL.ERROR, name, "OnInitialize failed: %s", SafeError(err))
            return
        end
    end
    entry.state = ModuleManager.STATE.INITIALIZED
end

function ModuleManager:EnableModule(name)
    local entry = modules[name]
    if not entry then
        return
    end
    if entry.state == ModuleManager.STATE.REGISTERED then
        self:InitializeModule(name)
    end
    if entry.state ~= ModuleManager.STATE.INITIALIZED and entry.state ~= ModuleManager.STATE.DISABLED then
        return
    end
    if entry.meta.OnEnable then
        local ok, err = pcall(entry.meta.OnEnable, entry.meta)
        if not ok and Internal.Logger then
            Internal.Logger:Log(Internal.Logger.LEVEL.ERROR, name, "OnEnable failed: %s", SafeError(err))
            return
        end
    end
    entry.state = ModuleManager.STATE.ENABLED
end

function ModuleManager:DisableModule(name)
    local entry = modules[name]
    if not entry or entry.state ~= ModuleManager.STATE.ENABLED then
        return
    end
    if entry.meta.OnDisable then
        local ok, err = pcall(entry.meta.OnDisable, entry.meta)
        if not ok and Internal.Logger then
            Internal.Logger:Log(Internal.Logger.LEVEL.ERROR, name, "OnDisable failed: %s", SafeError(err))
        end
    end
    entry.state = ModuleManager.STATE.DISABLED
end

function ModuleManager:OnProfileChanged()
    for _, entry in pairs(modules) do
        if entry.state == ModuleManager.STATE.ENABLED and entry.meta.OnProfileChanged then
            pcall(entry.meta.OnProfileChanged, entry.meta)
        end
    end
end

function GB.API:GetModuleState(name)
    local entry = modules[name]
    return entry and entry.state
end

function GB.API:EnableModule(name)
    ModuleManager:EnableModule(name)
end

function GB.API:DisableModule(name)
    ModuleManager:DisableModule(name)
end
