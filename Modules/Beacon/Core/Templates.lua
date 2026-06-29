--- Template rendering and rotation.

local GB = GuildBeacon
local Templates = {}
GB.Modules.Beacon = GB.Modules.Beacon or {}
GB.Modules.Beacon.Templates = Templates

local PLACEHOLDERS = { "guild", "player", "realm", "class" }

function Templates:Render(body)
    if not body then
        return ""
    end
    local guild = GetGuildInfo("player") or ""
    local player = UnitName("player") or ""
    local realm = GetRealmName() or ""
    local _, classFile = UnitClass("player")
    local class = classFile or ""
    body = body:gsub("{guild}", guild)
    body = body:gsub("{player}", player)
    body = body:gsub("{realm}", realm)
    body = body:gsub("{class}", class)
    return body
end

function Templates:GetById(config, id)
    for _, template in ipairs(config.templates or {}) do
        if template.id == id then
            return template
        end
    end
end

function Templates:Pick(config)
    local list = config.templates or {}
    if #list == 0 then
        return nil
    end
    config.state = config.state or {}
    if config.rotateTemplates then
        local idx = config.state.templateIndex or 1
        if idx > #list then
            idx = 1
        end
        local template = list[idx]
        config.state.templateIndex = (idx % #list) + 1
        return template
    end
    return self:GetById(config, config.activeTemplateId) or list[1]
end

function Templates:PickChannel(config)
    local list = config.channels or {}
    if #list == 0 then
        return nil
    end
    config.state = config.state or {}
    if config.rotateChannels then
        local idx = config.state.channelIndex or 1
        if idx > #list then
            idx = 1
        end
        local channel = list[idx]
        config.state.channelIndex = (idx % #list) + 1
        return channel
    end
    return list[1]
end

function Templates:PreviewNext(config)
    local saved = {
        templateIndex = config.state and config.state.templateIndex,
        channelIndex = config.state and config.state.channelIndex,
    }
    local template = self:Pick(config)
    local channel = self:PickChannel(config)
    if config.state then
        config.state.templateIndex = saved.templateIndex
        config.state.channelIndex = saved.channelIndex
    end
    if not template then
        return "", channel
    end
    return self:Render(template.body), channel
end
