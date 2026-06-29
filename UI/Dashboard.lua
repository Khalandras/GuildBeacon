--- Officer dashboard (candidates, inbox, beacon).

local GB = GuildBeacon
local W = GB.UI.Widgets
local Dashboard = {}
GB.UI.Dashboard = Dashboard

local FRAME_W, FRAME_H = 720, 560
local activeTab = "candidates"
local statusFilter = ""
local testLog = {}

local function GetHarness()
    return GB.Internal and GB.Internal.TestHarness
end

local function GetStore()
    return GB.Modules.Candidates and GB.Modules.Candidates.Store
end

function Dashboard:IsShown()
    return self.frame and self.frame:IsShown()
end

function Dashboard:SelectTab(tab)
    activeTab = tab
    self:Refresh()
end

function Dashboard:BuildTabs(parent)
    local tabs = {
        { id = "candidates", label = GB.L("TAB_CANDIDATES") },
        { id = "inbox", label = GB.L("TAB_INBOX") },
        { id = "beacon", label = GB.L("TAB_BEACON") },
        { id = "tests", label = GB.L("TAB_TESTS") },
    }
    local x = 16
    self.tabButtons = {}
    for _, tab in ipairs(tabs) do
        local btn = W:CreateTabButton(parent, tab.label, function()
            Dashboard:SelectTab(tab.id)
        end)
        btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -36)
        btn:SetWidth(100)
        self.tabButtons[tab.id] = btn
        x = x + 104
    end
end

function Dashboard:AppendLog(line)
    testLog[#testLog + 1] = string.format("[%s] %s", date("%H:%M:%S"), line)
    while #testLog > 40 do
        table.remove(testLog, 1)
    end
    if activeTab == "tests" and self.content then
        self:Refresh()
    end
end

function Dashboard:CanPostLive()
    local config = GB.API:GetModuleConfig().beacon
    if config.dryRun then
        return true
    end
    return config.livePostConfirmed == true
end

function Dashboard:RenderTests()
    local harness = GetHarness()
    local config = GB.API:GetModuleConfig().beacon
    local y = -8

    local intro = W:CreateMutedFontString(self.content)
    intro:SetPoint("TOPLEFT", 8, y)
    intro:SetWidth(660)
    intro:SetJustifyH("LEFT")
    intro:SetText(GB.L("TEST_TAB_INTRO"))
    y = y - 32

    local dryCb = W:CreateCheckbox(self.content, GB.L("CFG_DRY_RUN"), config.dryRun, function(checked)
        config.dryRun = checked
        if checked then
            config.livePostConfirmed = false
        end
        Dashboard:AppendLog(checked and GB.L("TEST_DRY_ON") or GB.L("TEST_DRY_OFF"))
        Dashboard:Refresh()
    end)
    dryCb:SetPoint("TOPLEFT", 8, y)

    local debugOn = harness and harness:IsDebugEnabled()
    local debugCb = W:CreateCheckbox(self.content, GB.L("TEST_DEBUG_LABEL"), debugOn, function(checked)
        if harness then
            harness:SetDebug(checked)
        end
    end)
    debugCb:SetPoint("LEFT", dryCb, "RIGHT", 160, 0)
    y = y - 30

    if not config.dryRun then
        local liveCb = W:CreateCheckbox(self.content, GB.L("TEST_LIVE_CONFIRM"), config.livePostConfirmed, function(checked)
            config.livePostConfirmed = checked
            Dashboard:AppendLog(checked and GB.L("TEST_LIVE_ARMED") or GB.L("TEST_LIVE_DISARMED"))
        end)
        liveCb:SetPoint("TOPLEFT", 8, y)
        y = y - 28

        local warn = W:CreateMutedFontString(self.content)
        warn:SetPoint("TOPLEFT", 8, y)
        warn:SetTextColor(0.9, 0.35, 0.35)
        warn:SetText(GB.L("TEST_LIVE_WARNING"))
        y = y - 22
    end

    local btnSelf = W:CreateButton(self.content, 88, 22, GB.L("TEST_BTN_SELF"), function()
        if harness then harness:RunSelf() end
    end)
    btnSelf:SetPoint("TOPLEFT", 8, y)

    local btnSeed = W:CreateButton(self.content, 88, 22, GB.L("TEST_BTN_SEED"), function()
        if harness then harness:Seed() end
    end)
    btnSeed:SetPoint("LEFT", btnSelf, "RIGHT", 6, 0)

    local btnClear = W:CreateButton(self.content, 88, 22, GB.L("TEST_BTN_CLEAR"), function()
        if harness then harness:ClearTestData() end
    end)
    btnClear:SetPoint("LEFT", btnSeed, "RIGHT", 6, 0)

    local btnDry = W:CreateButton(self.content, 88, 22, GB.L("TEST_BTN_DRY_TICK"), function()
        if harness then harness:DryTickBeacon() end
    end)
    btnDry:SetPoint("LEFT", btnClear, "RIGHT", 6, 0)

    local btnTeardown = W:CreateButton(self.content, 88, 22, GB.L("TEST_BTN_TEARDOWN"), function()
        if harness then harness:Teardown() end
    end)
    btnTeardown:SetPoint("LEFT", btnDry, "RIGHT", 6, 0)
    y = y - 30

    local simLabel = W:CreateMutedFontString(self.content)
    simLabel:SetPoint("TOPLEFT", 8, y)
    simLabel:SetText(GB.L("TEST_SIM_LABEL"))
    y = y - 20

    local nameBox = CreateFrame("EditBox", nil, self.content, "InputBoxTemplate")
    nameBox:SetSize(160, 20)
    nameBox:SetPoint("TOPLEFT", 8, y)
    nameBox:SetAutoFocus(false)
    nameBox:SetText("TestRecruit-" .. (GetRealmName() or "Realm"))

    local bodyBox = CreateFrame("EditBox", nil, self.content, "InputBoxTemplate")
    bodyBox:SetSize(320, 20)
    bodyBox:SetPoint("LEFT", nameBox, "RIGHT", 8, 0)
    bodyBox:SetAutoFocus(false)
    bodyBox:SetText(GB.L("TEST_SIM_DEFAULT_BODY"))

    local simBtn = W:CreateButton(self.content, 80, 22, GB.L("TEST_BTN_SIM"), function()
        if harness then
            harness:SimulateWhisper(nameBox:GetText(), bodyBox:GetText())
        end
    end)
    simBtn:SetPoint("LEFT", bodyBox, "RIGHT", 8, 0)
    y = y - 28

    local rioBtn = W:CreateButton(self.content, 120, 22, GB.L("TEST_BTN_RIO"), function()
        if harness then
            local n, r = W:ParseNameRealm(nameBox:GetText())
            harness:TestRaiderIO(n, r)
        end
    end)
    rioBtn:SetPoint("TOPLEFT", 8, y)

    local logClearBtn = W:CreateButton(self.content, 100, 22, GB.L("TEST_BTN_LOG_CLEAR"), function()
        wipe(testLog)
        Dashboard:Refresh()
    end)
    logClearBtn:SetPoint("LEFT", rioBtn, "RIGHT", 8, 0)
    y = y - 28

    local logHeader = W:CreateGoldFontString(self.content)
    logHeader:SetPoint("TOPLEFT", 8, y)
    logHeader:SetText(GB.L("TEST_LOG_HEADER"))
    y = y - 18

    for i = #testLog, math.max(1, #testLog - 11), -1 do
        local lineFs = W:CreateMutedFontString(self.content)
        lineFs:SetPoint("TOPLEFT", 12, y)
        lineFs:SetWidth(660)
        lineFs:SetJustifyH("LEFT")
        lineFs:SetText(testLog[i])
        y = y - 14
    end
    if #testLog == 0 then
        local empty = W:CreateMutedFontString(self.content)
        empty:SetPoint("TOPLEFT", 12, y)
        empty:SetText(GB.L("TEST_LOG_EMPTY"))
    end
end

function Dashboard:ClearContent()
    if not self.content then
        return
    end
    local children = { self.content:GetChildren() }
    for _, child in ipairs(children) do
        child:Hide()
        child:SetParent(nil)
    end
end

function Dashboard:RenderCandidates()
    local store = GetStore()
    if not store then
        return
    end
    local y = -8
    local stats = store:GetStats()
    local header = W:CreateMutedFontString(self.content)
    header:SetPoint("TOPLEFT", 8, y)
    header:SetText(string.format(GB.L("CANDIDATES_STATS"), stats.total, stats.new, stats.trial))
    y = y - 24

    local filterLabel = W:CreateMutedFontString(self.content)
    filterLabel:SetPoint("TOPLEFT", 8, y)
    filterLabel:SetText(GB.L("FILTER_STATUS"))
    y = y - 22

    local statuses = GB.API:GetModuleConfig().candidates.statuses or {}
    local fx = 8
    for _, status in ipairs(statuses) do
        local btn = W:CreateButton(self.content, 72, 20, W:StatusLabel(status), function()
            statusFilter = (statusFilter == status) and "" or status
            Dashboard:Refresh()
        end)
        btn:SetPoint("TOPLEFT", fx, y)
        if statusFilter == status then
            btn:SetAlpha(1)
        else
            btn:SetAlpha(0.75)
        end
        fx = fx + 76
    end
    y = y - 28

    local people = store:GetSortedPeople(statusFilter)
    for i = 1, math.min(12, #people) do
        local person = people[i]
        local key = person.key or person.name
        local row = CreateFrame("Frame", nil, self.content)
        row:SetSize(640, 52)
        row:SetPoint("TOPLEFT", 4, y)

        local nameFs = W:CreateGoldFontString(row)
        nameFs:SetPoint("TOPLEFT", 4, -4)
        local rioScore = person.rio and person.rio.score or 0
        local rioText = rioScore > 0 and string.format(" M+ %d", rioScore) or ""
        nameFs:SetText(string.format("%s |cff9a8b7f%s|r%s", key, W:StatusLabel(person.status), rioText))

        local metaFs = W:CreateMutedFontString(row)
        metaFs:SetPoint("TOPLEFT", 4, -20)
        local raid = person.rio and person.rio.raid or ""
        metaFs:SetText(string.format("%s · %s", W:FormatRelativeTime(person.lastSeen), raid ~= "" and raid or GB.L("NO_RAID_DATA")))

        local msgFs = W:CreateMutedFontString(row)
        msgFs:SetPoint("TOPLEFT", 4, -34)
        msgFs:SetWidth(400)
        msgFs:SetJustifyH("LEFT")
        msgFs:SetText(person.lastMessage or "")

        local contactBtn = W:CreateButton(row, 70, 20, GB.L("BTN_CONTACTED"), function()
            store:SetStatus(key, "contacted")
            Dashboard:Refresh()
        end)
        contactBtn:SetPoint("TOPRIGHT", -4, -4)

        local trialBtn = W:CreateButton(row, 50, 20, GB.L("BTN_TRIAL"), function()
            store:SetStatus(key, "trial")
            Dashboard:Refresh()
        end)
        trialBtn:SetPoint("RIGHT", contactBtn, "LEFT", -4, 0)

        local rioBtn = W:CreateButton(row, 40, 20, "RIO", function()
            store:Enrich(key)
            Dashboard:Refresh()
        end)
        rioBtn:SetPoint("RIGHT", trialBtn, "LEFT", -4, 0)

        y = y - 56
    end

    if #people == 0 then
        local empty = W:CreateMutedFontString(self.content)
        empty:SetPoint("TOPLEFT", 8, y)
        empty:SetText(GB.L("CANDIDATES_EMPTY"))
    end
end

function Dashboard:RenderInbox()
    local store = GetStore()
    if not store then
        return
    end
    local y = -8
    local messages = store:GetMessages()
    for i = 1, math.min(20, #messages) do
        local msg = messages[i]
        local row = W:CreateMutedFontString(self.content)
        row:SetPoint("TOPLEFT", 8, y)
        row:SetWidth(640)
        row:SetJustifyH("LEFT")
        row:SetText(string.format("|cffd4af37%s|r [%s] %s", msg.from or "?", msg.channel or "?", msg.body or ""))
        y = y - 18
    end
    if #messages == 0 then
        local empty = W:CreateMutedFontString(self.content)
        empty:SetPoint("TOPLEFT", 8, y)
        empty:SetText(GB.L("INBOX_EMPTY"))
    end
end

function Dashboard:RenderBeacon()
    local config = GB.API:GetModuleConfig().beacon
    local scheduler = GB.Modules.Beacon.Scheduler
    local y = -8

    local statusFs = W:CreateGoldFontString(self.content)
    statusFs:SetPoint("TOPLEFT", 8, y)
    local dryLabel = config.dryRun and GB.L("BEACON_DRY_ON") or GB.L("BEACON_DRY_OFF")
    statusFs:SetText(string.format(GB.L("BEACON_STATUS"), config.enabled and GB.L("ON") or GB.L("OFF")) .. " · " .. dryLabel)
    y = y - 24

    if not config.dryRun and not config.livePostConfirmed then
        local blocked = W:CreateMutedFontString(self.content)
        blocked:SetPoint("TOPLEFT", 8, y)
        blocked:SetWidth(640)
        blocked:SetJustifyH("LEFT")
        blocked:SetTextColor(0.9, 0.35, 0.35)
        blocked:SetText(GB.L("BEACON_LIVE_BLOCKED"))
        y = y - 22
    end

    local cd = scheduler and scheduler:GetCooldownSeconds() or 0
    local cdFs = W:CreateMutedFontString(self.content)
    cdFs:SetPoint("TOPLEFT", 8, y)
    cdFs:SetText(string.format(GB.L("BEACON_COOLDOWN"), math.ceil(cd / 60)))
    y = y - 28

    local previewFs = W:CreateMutedFontString(self.content)
    previewFs:SetPoint("TOPLEFT", 8, y)
    previewFs:SetWidth(640)
    previewFs:SetJustifyH("LEFT")
    previewFs:SetText(scheduler and scheduler:Preview() or "")
    y = y - 40

    local startBtn = W:CreateButton(self.content, 100, 22, GB.L("BEACON_START"), function()
        config.enabled = true
        GB.API:EnableModule("Beacon")
        GB.API:Print(GB.L("BEACON_STARTED"))
        Dashboard:Refresh()
    end)
    startBtn:SetPoint("TOPLEFT", 8, y)

    local stopBtn = W:CreateButton(self.content, 100, 22, GB.L("BEACON_STOP"), function()
        config.enabled = false
        GB.API:DisableModule("Beacon")
        GB.API:Print(GB.L("BEACON_STOPPED"))
        Dashboard:Refresh()
    end)
    stopBtn:SetPoint("LEFT", startBtn, "RIGHT", 8, 0)

    local postBtn = W:CreateButton(self.content, 100, 22, GB.L("BEACON_POST_NOW"), function()
        if not Dashboard:CanPostLive() then
            GB.API:Print(GB.L("TEST_LIVE_BLOCKED"))
            Dashboard:SelectTab("tests")
            return
        end
        if scheduler then
            scheduler:PostNow()
            GB.API:Print(config.dryRun and GB.L("TEST_DRY_TICK_DONE") or GB.L("BEACON_POSTED"))
            Dashboard:Refresh()
        end
    end)
    postBtn:SetPoint("LEFT", stopBtn, "RIGHT", 8, 0)

    local configBtn = W:CreateButton(self.content, 100, 22, GB.L("BTN_SETTINGS"), function()
        if GB.UI.ConfigPanel then
            GB.UI.ConfigPanel:Open()
        end
    end)
    configBtn:SetPoint("LEFT", postBtn, "RIGHT", 8, 0)

    local testsBtn = W:CreateButton(self.content, 120, 22, GB.L("TAB_TESTS"), function()
        Dashboard:SelectTab("tests")
    end)
    testsBtn:SetPoint("TOPLEFT", 8, y - 30)
end

function Dashboard:Refresh()
    if not self.frame or not self.content then
        return
    end
    for id, btn in pairs(self.tabButtons or {}) do
        if id == activeTab then
            btn.text:SetTextColor(0.83, 0.69, 0.22)
        else
            btn.text:SetTextColor(1, 1, 1)
        end
    end
    self:ClearContent()
    if activeTab == "candidates" then
        self:RenderCandidates()
    elseif activeTab == "inbox" then
        self:RenderInbox()
    elseif activeTab == "beacon" then
        self:RenderBeacon()
    elseif activeTab == "tests" then
        self:RenderTests()
    end
end

function Dashboard:EnsureFrame()
    if self.frame then
        return
    end
    local f = CreateFrame("Frame", "GuildBeaconDashboard", UIParent, "BackdropTemplate")
    f:SetSize(FRAME_W, FRAME_H)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    W:ApplyDialogBackdrop(f)

    local title = W:CreateGoldFontString(f, 16)
    title:SetPoint("TOP", 0, -14)
    title:SetText(GB.Internal.Branding:Title() .. " · " .. GB.L("DASHBOARD_TITLE"))

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)

    self:BuildTabs(f)

    local content = CreateFrame("Frame", nil, f)
    content:SetPoint("TOPLEFT", 12, -68)
    content:SetPoint("BOTTOMRIGHT", -12, 12)
    self.content = content
    self.frame = f
end

function Dashboard:Toggle()
    self:EnsureFrame()
    if self.frame:IsShown() then
        self.frame:Hide()
    else
        self.frame:Show()
        self:Refresh()
    end
end

function Dashboard:Open()
    self:EnsureFrame()
    self.frame:Show()
    self:Refresh()
end

function Dashboard:Initialize()
    self:EnsureFrame()
    self.frame:Hide()
end
