--- Settings panel.

local GB = GuildBeacon
local W = GB.UI.Widgets
local ConfigPanel = {}
GB.UI.ConfigPanel = ConfigPanel

local FRAME_W, FRAME_H = 480, 420

function ConfigPanel:EnsureFrame()
    if self.frame then
        return
    end
    local f = CreateFrame("Frame", "GuildBeaconConfig", UIParent, "BackdropTemplate")
    f:SetSize(FRAME_W, FRAME_H)
    f:SetPoint("CENTER", 40, 0)
    f:SetFrameStrata("DIALOG")
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    W:ApplyDialogBackdrop(f)

    local title = W:CreateGoldFontString(f, 14)
    title:SetPoint("TOP", 0, -14)
    title:SetText(GB.L("CONFIG_TITLE"))

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)

    self.rows = {}
    self.frame = f
    self:BuildControls()
end

function ConfigPanel:BuildControls()
    local config = GB.API:GetModuleConfig()
    local y = -48

    local intervalLabel = W:CreateMutedFontString(self.frame)
    intervalLabel:SetPoint("TOPLEFT", 20, y)
    intervalLabel:SetText(GB.L("CFG_INTERVAL"))
    y = y - 22

    local intervalBox = CreateFrame("EditBox", nil, self.frame, "InputBoxTemplate")
    intervalBox:SetSize(60, 20)
    intervalBox:SetPoint("TOPLEFT", 20, y)
    intervalBox:SetAutoFocus(false)
    intervalBox:SetNumeric(true)
    intervalBox:SetText(tostring(config.beacon.intervalMinutes or 15))
    intervalBox:SetScript("OnEnterPressed", function(self)
        local v = tonumber(self:GetText()) or 15
        config.beacon.intervalMinutes = math.max(1, v)
        if GB.Modules.Beacon.Scheduler and config.beacon.enabled then
            GB.Modules.Beacon.Scheduler:Start()
        end
    end)
    self.rows.interval = intervalBox
    y = y - 36

    local cbGuild = W:CreateCheckbox(self.frame, GB.L("CFG_CHANNEL_GUILD"), self:HasChannel("guild"), function(checked)
        ConfigPanel:SetChannel("guild", checked)
    end)
    cbGuild:SetPoint("TOPLEFT", 20, y)
    y = y - 28

    local cbSay = W:CreateCheckbox(self.frame, GB.L("CFG_CHANNEL_SAY"), self:HasChannel("say"), function(checked)
        ConfigPanel:SetChannel("say", checked)
    end)
    cbSay:SetPoint("TOPLEFT", 20, y)
    y = y - 28

    local cbOfficer = W:CreateCheckbox(self.frame, GB.L("CFG_OFFICER_ONLY"), config.beacon.onlyWhenOfficer, function(checked)
        config.beacon.onlyWhenOfficer = checked
    end)
    cbOfficer:SetPoint("TOPLEFT", 20, y)
    y = y - 28

    local cbInstance = W:CreateCheckbox(self.frame, GB.L("CFG_PAUSE_INSTANCE"), config.beacon.pauseInInstance, function(checked)
        config.beacon.pauseInInstance = checked
    end)
    cbInstance:SetPoint("TOPLEFT", 20, y)
    y = y - 28

    local cbRotate = W:CreateCheckbox(self.frame, GB.L("CFG_ROTATE_TEMPLATES"), config.beacon.rotateTemplates, function(checked)
        config.beacon.rotateTemplates = checked
    end)
    cbRotate:SetPoint("TOPLEFT", 20, y)
    y = y - 28

    local cbWhisper = W:CreateCheckbox(self.frame, GB.L("CFG_CAPTURE_WHISPERS"), config.inbox.captureWhispers, function(checked)
        config.inbox.captureWhispers = checked
    end)
    cbWhisper:SetPoint("TOPLEFT", 20, y)
    y = y - 28

    local cbGuildChat = W:CreateCheckbox(self.frame, GB.L("CFG_CAPTURE_GUILD"), config.inbox.captureGuildChat, function(checked)
        config.inbox.captureGuildChat = checked
    end)
    cbGuildChat:SetPoint("TOPLEFT", 20, y)
    y = y - 28

    local cbRio = W:CreateCheckbox(self.frame, GB.L("CFG_RIO_ENRICH"), config.candidates.enrichRaiderIO, function(checked)
        config.candidates.enrichRaiderIO = checked
    end)
    cbRio:SetPoint("TOPLEFT", 20, y)
    y = y - 36

    local dashBtn = W:CreateButton(self.frame, 140, 22, GB.L("BTN_OPEN_DASHBOARD"), function()
        if GB.UI.Dashboard then
            GB.UI.Dashboard:Open()
        end
    end)
    dashBtn:SetPoint("TOPLEFT", 20, y)
end

function ConfigPanel:HasChannel(channel)
    local channels = GB.API:GetModuleConfig().beacon.channels or {}
    for _, ch in ipairs(channels) do
        if ch == channel then
            return true
        end
    end
    return false
end

function ConfigPanel:SetChannel(channel, enabled)
    local config = GB.API:GetModuleConfig().beacon
    local channels = config.channels or {}
    local found, idx
    for i, ch in ipairs(channels) do
        if ch == channel then
            found, idx = true, i
            break
        end
    end
    if enabled and not found then
        channels[#channels + 1] = channel
    elseif not enabled and found then
        table.remove(channels, idx)
    end
    config.channels = channels
end

function ConfigPanel:Toggle()
    self:EnsureFrame()
    if self.frame:IsShown() then
        self.frame:Hide()
    else
        self.frame:Show()
    end
end

function ConfigPanel:Open()
    self:EnsureFrame()
    self.frame:Show()
end
