--- Anti-spam guards for beacon posts.

local GB = GuildBeacon
local AntiSpam = {}
GB.Modules.Beacon.AntiSpam = AntiSpam

function AntiSpam:CanPost(config, message)
    config.state = config.state or {}
    local now = time()
    local minGap = math.max(60, config.minSecondsBetweenPosts or 300)
    local lastAt = config.state.lastPostedAt or 0
    if now - lastAt < minGap then
        return false, "cooldown"
    end
    if config.state.lastPostedBody == message then
        return false, "duplicate"
    end
    return true
end

function AntiSpam:RecordPost(config, message)
    config.state = config.state or {}
    config.state.lastPostedAt = time()
    config.state.lastPostedBody = message
end

function AntiSpam:SecondsUntilNext(config)
    config.state = config.state or {}
    local minGap = math.max(60, config.minSecondsBetweenPosts or 300)
    local elapsed = time() - (config.state.lastPostedAt or 0)
    return math.max(0, minGap - elapsed)
end
