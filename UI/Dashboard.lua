--- Officer dashboard — triage, pipeline, beacon, settings.

local GB = GuildBeacon
local Branding = GB.Internal.Branding

local function W()
    return GB.UI and GB.UI.Widgets
end
local Dashboard = {}
GB.UI.Dashboard = Dashboard

local LAYOUT = {
    MIN_W = 560,
    MIN_H = 440,
    MAX_W = 760,
    MAX_H = 620,
    DEFAULT_W = 720,
    DEFAULT_H = 560,
    HEADER_H = 44,
    STATUS_H = 24,
    TAB_H = 36,
    FOOTER_H = 26,
    PAD = 12,
    LIST_RATIO = 0.35,
    ROW_H = 38,
    ROW_POOL = 32,
    PIPE_TOOLBAR_H = 48,
    TRIAGE_BAR_H = 30,
}

local ROW_H = LAYOUT.ROW_H
local ROW_POOL = LAYOUT.ROW_POOL
local testLog = {}

local TAB_IDS = { "triage", "pipeline", "beacon", "settings" }

local VALID_TABS = {
    triage = true,
    pipeline = true,
    beacon = true,
    settings = true,
}

local LEGACY_TAB_MAP = {
    inbox = "triage",
    candidates = "pipeline",
    candidats = "pipeline",
    tests = "settings",
    test = "settings",
    config = "settings",
    dashboard = "triage",
    dash = "triage",
}

local function NormalizeTabId(tab)
    if tab == nil or tab == "" then
        return "triage"
    end
    tab = string.lower(tostring(tab))
    if VALID_TABS[tab] then
        return tab
    end
    return LEGACY_TAB_MAP[tab] or "triage"
end

local function AnchorTo(frame, ...)
    if not frame then
        return
    end
    if frame.ClearAllPoints then
        frame:ClearAllPoints()
    end
    frame:SetPoint(...)
end

local function AnchorFill(frame, parent, pad)
    if not frame or not parent then
        return
    end
    pad = pad or 0
    if frame.ClearAllPoints then
        frame:ClearAllPoints()
    end
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", pad, -pad)
    frame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -pad, pad)
end

local FRAME_DECORATION_KEYS = {
    "gbSolidBg",
    "gbHairline",
    "gbOutlineTop",
    "gbOutlineBottom",
    "gbOutlineLeft",
    "gbOutlineRight",
    "gbTopGlow",
    "gbTabRule",
    "gbStatusRule",
}

local function ClearFrameDecorations(frame)
    if not frame then
        return
    end
    for _, key in ipairs(FRAME_DECORATION_KEYS) do
        frame[key] = nil
    end
end

local function ReleaseDashboardFrame(frame)
    if not frame then
        return
    end
    frame:Hide()
    frame:StopMovingOrSizing()
    frame:UnregisterAllEvents()
    frame:SetScript("OnUpdate", nil)
    frame:SetScript("OnSizeChanged", nil)
    frame:SetScript("OnDragStart", nil)
    frame:SetScript("OnDragStop", nil)
    frame:SetScript("OnHide", nil)

    for _, child in ipairs({ frame:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end

    for _, region in ipairs({ frame:GetRegions() }) do
        if region.Hide then
            region:Hide()
        end
        if region.SetParent then
            region:SetParent(nil)
        end
    end

    ClearFrameDecorations(frame)
    frame:ClearAllPoints()
    frame:SetParent(nil)
end

local function ClearDashboardRefs(self)
    self.frame = nil
    self.headerBand = nil
    self.sigil = nil
    self.titleBtn = nil
    self.close = nil
    self.statusStrip = nil
    self.tabBar = nil
    self.tabButtons = nil
    self.body = nil
    self.splitView = nil
    self.fullView = nil
    self.listScroll = nil
    self.listContent = nil
    self.listDivider = nil
    self.detailPanel = nil
    self.triageBar = nil
    self.footer = nil
    self.footerSigil = nil
    self.pipelineToolbar = nil
    self.searchBox = nil
    self.listRows = nil
    self.layout = nil
end

local function GetStore()
    return GB.Modules.Candidates and GB.Modules.Candidates.Store
end

local function GetHarness()
    return GB.Internal and GB.Internal.TestHarness
end

local function GetUI()
    return GB.API:GetModuleConfig().ui
end

local function GetScheduler()
    return GB.Modules.Beacon and GB.Modules.Beacon.Scheduler
end

-- ---------------------------------------------------------------------------
-- State
-- ---------------------------------------------------------------------------

function Dashboard:GetActiveTab()
    local ui = GetUI()
    local tab = NormalizeTabId(ui.lastTab)
    if ui.lastTab ~= tab then
        ui.lastTab = tab
    end
    return tab
end

function Dashboard:SetActiveTab(tab)
    GetUI().lastTab = NormalizeTabId(tab)
end

function Dashboard:GetSelectedKey()
    return GetUI().selectedKey
end

function Dashboard:SelectKey(key)
    GetUI().selectedKey = key
end

function Dashboard:AppendLog(line)
    testLog[#testLog + 1] = string.format("[%s] %s", date("%H:%M:%S"), line)
    while #testLog > 50 do
        table.remove(testLog, 1)
    end
    if self.diagLogContent then
        self:UpdateDiagnosticsLog()
    end
end

function Dashboard:CanPostLive()
    local config = GB.API:GetModuleConfig().beacon
    if config.dryRun then
        return true
    end
    return config.livePostConfirmed == true
end

-- ---------------------------------------------------------------------------
-- Frame bootstrap
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- Layout (DA: header 40, tabs 32, footer 28, master-detail responsive)
-- ---------------------------------------------------------------------------

function Dashboard:IsFrameReady()
    if not self.frame or not self.headerBand or not self.body then
        return false
    end
    if self.headerBand:GetParent() ~= self.frame or self.body:GetParent() ~= self.frame then
        return false
    end
    if self.headerBand.GetNumPoints and self.headerBand:GetNumPoints() < 1 then
        return false
    end
    return self.splitView
        and self.fullView
        and self.listScroll
        and self.listContent
        and self.tabButtons
end

function Dashboard:DestroyFrame()
    local frame = self.frame or _G.GuildBeaconDashboard
    if frame then
        ReleaseDashboardFrame(frame)
    end
    ClearDashboardRefs(self)
end

function Dashboard:InvalidateFrameIfStale()
    if not self.frame then
        return
    end
    if self:IsFrameReady() and (GetUI().layoutVersion or 0) >= 11 then
        return
    end
    self:DestroyFrame()
end

function Dashboard:ComputeLayout()
    local ui = GetUI()
    local fw, fh
    if self.frame then
        fw = self.frame:GetWidth()
        fh = self.frame:GetHeight()
    else
        fw = ui.frameWidth or 680
        fh = ui.frameHeight or 520
    end
    fw = math.max(LAYOUT.MIN_W, math.min(LAYOUT.MAX_W, fw))
    fh = math.max(LAYOUT.MIN_H, math.min(LAYOUT.MAX_H, fh))
    local pad = LAYOUT.PAD
    local innerW = fw - pad * 2
    local top = LAYOUT.HEADER_H + LAYOUT.STATUS_H + LAYOUT.TAB_H + pad
    local bodyH = math.max(1, fh - top - LAYOUT.FOOTER_H - pad)
    local listW = math.floor(innerW * LAYOUT.LIST_RATIO)
    local detailW = innerW - listW - 9
    local tab = self:GetActiveTab()
    local toolbarH = (tab == "pipeline") and LAYOUT.PIPE_TOOLBAR_H or 0
    local triageH = (tab == "triage") and LAYOUT.TRIAGE_BAR_H or 0
    local paneH = bodyH - toolbarH
    local listPaneH = paneH - triageH
    return {
        fw = fw,
        fh = fh,
        pad = pad,
        innerW = innerW,
        bodyTop = -top,
        bodyH = bodyH,
        listW = listW,
        detailW = detailW,
        paneH = paneH,
        listPaneH = listPaneH,
        toolbarH = toolbarH,
        triageH = triageH,
    }
end

function Dashboard:ApplyDetailLayout()
    if not self.detailPanel or not self.layout then
        return
    end
    local L = self.layout
    local dw = L.detailW - 12
    local dh = L.paneH - 12
    local actionsH = 32
    local headerH = 36
    local gap = 8
    local blocksH = dh - headerH - actionsH - gap * 2
    local msgH = math.max(72, math.floor(blocksH * 0.44))
    local notesH = math.max(56, math.floor(blocksH * 0.30))
    local timelineH = math.max(48, blocksH - msgH - notesH - gap * 2)

    self.detailEmpty:SetWidth(dw - 24)
    AnchorTo(self.detailName, "TOPLEFT", self.detailPanel, "TOPLEFT", 10, -8)
    AnchorTo(self.detailMeta, "TOPLEFT", self.detailPanel, "TOPLEFT", 10, -26)

    local y = headerH
    self.detailMsgSection:SetSize(dw, msgH)
    AnchorTo(self.detailMsgSection, "TOPLEFT", self.detailPanel, "TOPLEFT", 6, -y)
    AnchorFill(self.detailMsgScroll, self.detailMsgSection.inner, 0)
    local msgInnerW = self.detailMsgSection.inner:GetWidth()
    local msgInnerH = self.detailMsgSection.inner:GetHeight()
    if msgInnerW and msgInnerW > 0 and msgInnerH and msgInnerH > 0 then
        self.detailMsgScroll:SetSize(msgInnerW, msgInnerH)
    end

    y = y + msgH + gap
    self.detailNotesSection:SetSize(dw, notesH)
    AnchorTo(self.detailNotesSection, "TOPLEFT", self.detailPanel, "TOPLEFT", 6, -y)
    AnchorFill(self.detailNotesBox, self.detailNotesSection.inner, 2)

    y = y + notesH + gap
    self.detailTimelineSection:SetSize(dw, timelineH)
    AnchorTo(self.detailTimelineSection, "TOPLEFT", self.detailPanel, "TOPLEFT", 6, -y)
    AnchorFill(self.detailTimelineScroll, self.detailTimelineSection.inner, 0)
    local tlInnerW = self.detailTimelineSection.inner:GetWidth()
    local tlInnerH = self.detailTimelineSection.inner:GetHeight()
    if tlInnerW and tlInnerW > 0 and tlInnerH and tlInnerH > 0 then
        self.detailTimelineScroll:SetSize(tlInnerW, tlInnerH)
    end

    self.detailActions:SetSize(dw - 4, actionsH)
    AnchorTo(self.detailActions, "BOTTOMLEFT", self.detailPanel, "BOTTOMLEFT", 6, 6)
end

function Dashboard:ApplyLayout(skipFrameResize)
    if not self.frame or not self.headerBand then
        return
    end
    local L = self:ComputeLayout()
    self.layout = L
    local ui = GetUI()
    ui.frameWidth = L.fw
    ui.frameHeight = L.fh

    if not skipFrameResize then
        self.frame:SetSize(L.fw, L.fh)
    end
    if self.frame.SetResizeBounds then
        self.frame:SetResizeBounds(LAYOUT.MIN_W, LAYOUT.MIN_H, LAYOUT.MAX_W, LAYOUT.MAX_H)
    end

    local pad = L.pad
    self.headerBand:SetSize(L.fw, LAYOUT.HEADER_H)
    AnchorTo(self.headerBand, "TOPLEFT", self.frame, "TOPLEFT", 0, 0)
    if self.sigil then
        AnchorTo(self.sigil, "TOPLEFT", self.headerBand, "TOPLEFT", 8, -11)
    end
    if self.titleBtn then
        self.titleBtn:SetSize(L.fw - 52, LAYOUT.HEADER_H)
        AnchorTo(self.titleBtn, "TOPLEFT", self.headerBand, "TOPLEFT", 30, 0)
    end
    if self.close then
        AnchorTo(self.close, "TOPRIGHT", self.headerBand, "TOPRIGHT", -6, -6)
    end

    self.statusStrip:SetSize(L.innerW, LAYOUT.STATUS_H)
    AnchorTo(self.statusStrip, "TOPLEFT", self.headerBand, "BOTTOMLEFT", pad, 0)

    self.tabBar:SetSize(L.innerW, LAYOUT.TAB_H)
    AnchorTo(self.tabBar, "TOPLEFT", self.statusStrip, "BOTTOMLEFT", 0, 0)

    self.footer:SetSize(L.innerW, LAYOUT.FOOTER_H)
    AnchorTo(self.footer, "BOTTOMLEFT", self.frame, "BOTTOMLEFT", pad, pad)

    self.body:SetWidth(L.innerW)
    if self.body.ClearAllPoints then
        self.body:ClearAllPoints()
    end
    self.body:SetPoint("TOPLEFT", self.tabBar, "BOTTOMLEFT", 0, -pad)
    self.body:SetPoint("BOTTOMRIGHT", self.footer, "TOPRIGHT", -pad, 0)

    AnchorFill(self.splitView, self.body, 0)
    AnchorFill(self.fullView, self.body, 0)

    local baseLevel = self.frame:GetFrameLevel()
    self.headerBand:SetFrameLevel(baseLevel + 30)
    self.statusStrip:SetFrameLevel(baseLevel + 25)
    self.tabBar:SetFrameLevel(baseLevel + 25)
    self.footer:SetFrameLevel(baseLevel + 25)
    self.body:SetFrameLevel(baseLevel + 15)

    local tabW = math.floor((L.innerW - 6) / 4)
    local tx = 2
    for _, id in ipairs(TAB_IDS) do
        local btn = self.tabButtons and self.tabButtons[id]
        if btn then
            btn:SetWidth(tabW)
            AnchorTo(btn, "TOPLEFT", self.tabBar, "TOPLEFT", tx, -2)
            tx = tx + tabW
        end
    end

    local contentY = -L.toolbarH
    if self.pipelineToolbar then
        self.pipelineToolbar:SetSize(L.innerW, L.toolbarH)
        AnchorTo(self.pipelineToolbar, "TOPLEFT", self.splitView, "TOPLEFT", 0, 0)
        self.pipelineToolbar:SetShown(L.toolbarH > 0)
    end

    self.triageBar:SetSize(L.listW, L.triageH)
    AnchorTo(self.triageBar, "TOPLEFT", self.splitView, "TOPLEFT", 0, contentY)
    self.triageBar:SetShown(L.triageH > 0)

    local listY = contentY - L.triageH
    self.listScroll:SetSize(L.listW, L.listPaneH)
    AnchorTo(self.listScroll, "TOPLEFT", self.splitView, "TOPLEFT", 0, listY)

    self.listDivider:SetSize(1, L.paneH)
    AnchorTo(self.listDivider, "TOPLEFT", self.splitView, "TOPLEFT", L.listW + 4, contentY)

    self.detailPanel:SetSize(L.detailW, L.paneH)
    AnchorTo(self.detailPanel, "TOPLEFT", self.splitView, "TOPLEFT", L.listW + 9, contentY)

    local listRowW = L.listW - 38
    for i = 1, ROW_POOL do
        if self.listRows[i] then
            self.listRows[i]:SetWidth(listRowW)
            self.listRows[i].subtitle:SetWidth(listRowW - 14)
        end
    end
    self.listEmpty:SetWidth(listRowW)

    self:ApplyDetailLayout()
end

function Dashboard:SaveFrameGeometry()
    if not self.frame then
        return
    end
    self.frame:StopMovingOrSizing()
    local ui = GetUI()
    local point, _, relativePoint, x, y = self.frame:GetPoint(1)
    ui.framePoint = { point, relativePoint, x, y }
    ui.frameWidth = self.frame:GetWidth()
    ui.frameHeight = self.frame:GetHeight()
    ui.frameWidth = math.max(LAYOUT.MIN_W, math.min(LAYOUT.MAX_W, ui.frameWidth))
    ui.frameHeight = math.max(LAYOUT.MIN_H, math.min(LAYOUT.MAX_H, ui.frameHeight))
end

function Dashboard:SaveFramePoint()
    self:SaveFrameGeometry()
end

function Dashboard:EnsureFrame()
    self:InvalidateFrameIfStale()
    if self:IsFrameReady() then
        return true
    end

    local existing = self.frame or _G.GuildBeaconDashboard
    if existing then
        ReleaseDashboardFrame(existing)
    end
    ClearDashboardRefs(self)

    local widgets = W()
    if not widgets then
        return false, "Widgets not loaded"
    end

    local ui = GetUI()
    local fw = math.max(LAYOUT.MIN_W, math.min(LAYOUT.MAX_W, ui.frameWidth or LAYOUT.DEFAULT_W))
    local fh = math.max(LAYOUT.MIN_H, math.min(LAYOUT.MAX_H, ui.frameHeight or LAYOUT.DEFAULT_H))
    ui.frameWidth = fw
    ui.frameHeight = fh

    local f = CreateFrame("Frame", "GuildBeaconDashboard", UIParent)
    f:SetSize(fw, fh)
    f:SetClipsChildren(true)
    ClearFrameDecorations(f)
    if ui.framePoint then
        local p = ui.framePoint
        f:SetPoint(p[1], UIParent, p[2], p[3], p[4])
    else
        f:SetPoint("CENTER")
    end
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(100)
    f:EnableMouse(true)
    f:SetMovable(true)
    if f.SetResizable then
        f:SetResizable(true)
    end
    if f.SetResizeBounds then
        f:SetResizeBounds(LAYOUT.MIN_W, LAYOUT.MIN_H, LAYOUT.MAX_W, LAYOUT.MAX_H)
    end

    local function OnGeometryChange()
        Dashboard:ApplyLayout()
        Dashboard:SaveFrameGeometry()
        if Dashboard.frame and Dashboard.frame:IsShown() then
            Dashboard:RefreshViews()
        end
    end

    self.frame = f
    widgets:ApplyWindowChrome(f)

    self.headerBand = widgets:CreateTitleBand(f, fw, LAYOUT.HEADER_H)
    W():EnableDrag(self.headerBand, f, OnGeometryChange)

    self.sigil = widgets:CreateSigil(self.headerBand, 22)

    self.titleBtn = CreateFrame("Button", nil, self.headerBand)
    self.titleBtn:EnableMouse(true)
    W():EnableDrag(self.titleBtn, f, OnGeometryChange)
    local title = W():CreateGoldFontString(self.titleBtn, 15)
    title:SetPoint("LEFT", 8, 0)
    title:SetText(Branding:Title() .. " · " .. GB.L("DASHBOARD_TITLE"))
    self.titleBtn:SetScript("OnClick", function()
        if IsShiftKeyDown() then
            ui.diagnosticsOpen = not ui.diagnosticsOpen
            if Dashboard:GetActiveTab() ~= "settings" then
                Dashboard:SelectTab("settings")
            else
                Dashboard:Refresh()
            end
        end
    end)
    W():SetTooltip(self.titleBtn, GB.L("DASHBOARD_TITLE"), GB.L("TIP_TITLE_BAR"))

    self.close = W():CreateCloseButton(self.headerBand, function()
        f:StopMovingOrSizing()
        f:Hide()
    end)

    f:SetScript("OnHide", function()
        f:StopMovingOrSizing()
    end)

    self.statusStrip = CreateFrame("Frame", nil, f)
    W():ApplyStatusStrip(self.statusStrip)

    self.statusBeacon = W():CreateMutedFontString(self.statusStrip)
    self.statusBeacon:SetPoint("LEFT", 8, 0)
    self.statusCountdown = W():CreateMutedFontString(self.statusStrip)
    self.statusCountdown:SetPoint("LEFT", 150, 0)
    self.statusStats = W():CreateMutedFontString(self.statusStrip)
    self.statusStats:SetPoint("RIGHT", -8, 0)
    self.statusAlert = W():CreateMutedFontString(self.statusStrip)
    self.statusAlert:SetPoint("CENTER", 0, 0)
    local er, eg, eb = W():RGB("error")
    self.statusAlert:SetTextColor(er, eg, eb)

    self.tabBar = CreateFrame("Frame", nil, f)
    W():DecorateTabBar(self.tabBar)
    self:BuildTabs(self.tabBar, f)

    self.body = CreateFrame("Frame", nil, f)
    self.body:SetClipsChildren(true)
    self.splitView = CreateFrame("Frame", nil, self.body)
    self.fullView = CreateFrame("Frame", nil, self.body)
    W():ApplyModernSurface(self.splitView, "bgPrimary", false)
    W():ApplyModernSurface(self.fullView, "bgPrimary", false)
    self.splitView:Hide()
    self.fullView:Hide()

    self.listScroll = W():CreateScrollArea(self.splitView, 200, 200)
    self.listContent = self.listScroll.content

    self.listDivider = W():CreateDivider(self.splitView, 200, true)

    self.detailPanel = CreateFrame("Frame", nil, self.splitView)
    W():ApplyModernSurface(self.detailPanel, "bgElevated", true)

    self.listRows = {}
    for i = 1, ROW_POOL do
        self.listRows[i] = W():CreateListRow(self.listContent, 180, ROW_H)
        self.listRows[i]:Hide()
    end

    self.listEmpty = W():CreateBodyFontString(self.listContent)
    self.listEmpty:SetPoint("TOP", 0, -36)
    self.listEmpty:SetJustifyH("CENTER")
    self.listEmpty:Hide()

    self.triageBar = CreateFrame("Frame", nil, self.splitView)
    self.markAllBtn = W():CreateButton(self.triageBar, 108, 26, GB.L("BTN_MARK_ALL_READ"), function()
        local store = GetStore()
        if store then
            store:MarkAllRead()
            Dashboard:RefreshList()
            Dashboard:UpdateTabs()
        end
    end, "ghost")
    self.markAllBtn:SetPoint("RIGHT", -4, 0)
    W():SetTooltip(self.markAllBtn, GB.L("BTN_MARK_ALL_READ"), GB.L("TIP_MARK_ALL"))

    self.footer = CreateFrame("Frame", nil, f)
    W():ApplyModernSurface(self.footer, "bgSecondary", false)
    self.footerSigil = widgets:CreateDiamondMark(self.footer, 10, "phosphor")
    self.footerSigil:SetPoint("LEFT", 10, 0)
    local footerLeft = W():CreateMutedFontString(self.footer)
    footerLeft:SetPoint("LEFT", self.footerSigil, "RIGHT", 6, 0)
    footerLeft:SetText(GB.L("FOOTER_PORTAL"))
    local footerVer = W():CreateMutedFontString(self.footer)
    footerVer:SetPoint("RIGHT", -8, 0)
    footerVer:SetText(string.format("v%s", GB.Version or "?"))

    self:BuildDetailWidgets()
    self:SubscribeEvents()
    self:SetActiveTab(self:GetActiveTab())
    self:ApplyLayout()
    self:RefreshViews()

    f:SetScript("OnSizeChanged", function()
        if not Dashboard.headerBand then
            return
        end
        Dashboard:ApplyLayout(true)
        if Dashboard.frame and Dashboard.frame:IsShown() then
            Dashboard:RefreshViews()
        end
    end)

    f:SetScript("OnUpdate", function(_, elapsed)
        Dashboard.tick = (Dashboard.tick or 0) + elapsed
        if Dashboard.tick >= 1 and f:IsShown() then
            Dashboard.tick = 0
            Dashboard:UpdateStatusBar()
        end
    end)

    ui.layoutVersion = 11

    if not Dashboard._escapeRegistered then
        UISpecialFrames = UISpecialFrames or {}
        tinsert(UISpecialFrames, "GuildBeaconDashboard")
        Dashboard._escapeRegistered = true
    end

    return true
end

function Dashboard:BuildTabs(parent, mover)
    local tabs = {
        { id = "triage", label = GB.L("TAB_TRIAGE") },
        { id = "pipeline", label = GB.L("TAB_PIPELINE") },
        { id = "beacon", label = GB.L("TAB_BEACON") },
        { id = "settings", label = GB.L("TAB_SETTINGS") },
    }
    self.tabButtons = {}
    for _, tab in ipairs(tabs) do
        local btn = W():CreateTabButton(parent, tab.label, function()
            Dashboard:SelectTab(tab.id)
        end)
        btn.tabId = tab.id
        self.tabButtons[tab.id] = btn
    end
end

function Dashboard:BuildDetailWidgets()
    local p = self.detailPanel
    self.detailEmpty = W():CreateBodyFontString(p)
    self.detailEmpty:SetPoint("CENTER")
    self.detailEmpty:SetWidth(280)
    self.detailEmpty:SetJustifyH("CENTER")
    self.detailEmpty:SetText(GB.L("DETAIL_EMPTY"))

    self.detailName = W():CreateGoldFontString(p, 14)
    self.detailName:SetPoint("TOPLEFT", 12, -10)
    self.detailStatus = W():CreateMutedFontString(p)
    self.detailStatus:SetPoint("LEFT", self.detailName, "RIGHT", 8, 0)
    self.detailMeta = W():CreateMutedFontString(p)
    self.detailMeta:SetPoint("TOPLEFT", 12, -30)

    self.detailTestBadge = W():CreateMutedFontString(p)
    self.detailTestBadge:SetPoint("TOPRIGHT", -12, -10)
    self.detailTestBadge:SetTextColor(0.9, 0.6, 0.2)

    self.detailMsgSection = W():CreateInsetSection(p, GB.L("DETAIL_MESSAGES"))
    self.detailMsgScroll = W():CreateScrollArea(self.detailMsgSection.inner, 260, 80)
    self.detailMsgContent = self.detailMsgScroll.content

    self.detailNotesSection = W():CreateInsetSection(p, GB.L("DETAIL_NOTES"))
    self.detailNotesBox = CreateFrame("EditBox", nil, self.detailNotesSection.inner)
    W():StyleEditBox(self.detailNotesBox)
    self.detailNotesBox:SetAutoFocus(false)
    if self.detailNotesBox.SetMultiLine then
        self.detailNotesBox:SetMultiLine(true)
    end
    self.detailNotesBox:SetScript("OnEditFocusLost", function(box)
        local key = Dashboard:GetSelectedKey()
        local store = GetStore()
        if key and store then
            store:SetNotes(key, box:GetText())
        end
    end)

    self.detailTimelineSection = W():CreateInsetSection(p, GB.L("DETAIL_TIMELINE"))
    self.detailTimelineScroll = W():CreateScrollArea(self.detailTimelineSection.inner, 260, 48)

    self.detailActions = CreateFrame("Frame", nil, p)
    self.detailActions:SetPoint("BOTTOMLEFT", 8, 8)
    self.detailActions:SetSize(260, 28)

    self.detailWidgets = {
        self.detailName, self.detailStatus, self.detailMeta, self.detailTestBadge,
        self.detailMsgSection, self.detailNotesSection, self.detailTimelineSection,
        self.detailActions,
    }
    self:HideDetail()
end

function Dashboard:HideDetail()
    self.detailEmpty:Show()
    for _, w in ipairs(self.detailWidgets) do
        if w ~= self.detailEmpty then
            w:Hide()
        end
    end
    if self.detailActionButtons then
        for _, btn in ipairs(self.detailActionButtons) do
            btn:Hide()
        end
    end
end

function Dashboard:ShowDetail()
    self.detailEmpty:Hide()
    for _, w in ipairs(self.detailWidgets) do
        w:Show()
    end
end

function Dashboard:SubscribeEvents()
    local bus = GB.Internal.EventBus
    if not bus then
        return
    end
    local function refresh()
        if Dashboard.frame and Dashboard.frame:IsShown() then
            Dashboard:Refresh()
        end
    end
    bus:Subscribe(Dashboard, "GUILDBEACON_INBOX_MESSAGE", refresh)
    bus:Subscribe(Dashboard, "GUILDBEACON_CANDIDATE_UPDATED", refresh)
    bus:Subscribe(Dashboard, "GUILDBEACON_BEACON_POSTED", refresh)
end

-- ---------------------------------------------------------------------------
-- Navigation
-- ---------------------------------------------------------------------------

function Dashboard:SelectTab(tab)
    self:SetActiveTab(tab)
    self:Refresh()
end

function Dashboard:SelectItem(key, msgId)
    self:SelectKey(key)
    local store = GetStore()
    if store and msgId then
        store:MarkMessageRead(msgId)
    end
    self:RefreshList()
    self:UpdateDetail()
    self:UpdateTabs()
end

-- ---------------------------------------------------------------------------
-- Status bar
-- ---------------------------------------------------------------------------

function Dashboard:UpdateStatusBar()
    if not self.statusBeacon then
        return
    end
    local config = GB.API:GetModuleConfig().beacon
    local scheduler = GetScheduler()
    local store = GetStore()
    local stats = store and store:GetStats() or { new = 0, trial = 0 }

    local beaconColor = config.enabled and "|cff45c4b0" or "|cff6b6178"
    local modeColor = config.dryRun and "|cffd4af37" or "|cffc45c5c"
    local mode = config.dryRun and GB.L("BEACON_DRY_ON") or GB.L("BEACON_DRY_OFF")
    self.statusBeacon:SetText(string.format("%s%s|r · %s%s|r",
        beaconColor, config.enabled and GB.L("BEACON_ON_SHORT") or GB.L("BEACON_OFF_SHORT"),
        modeColor, mode))

    local cdSec = scheduler and scheduler:GetSecondsUntilNextPost() or 0
    local antiSec = scheduler and scheduler:GetCooldownSeconds() or 0
    if config.enabled and cdSec > 0 then
        self.statusCountdown:SetText(string.format(GB.L("STATUS_NEXT_POST"), math.ceil(cdSec / 60), math.ceil(antiSec / 60)))
    else
        self.statusCountdown:SetText(string.format(GB.L("STATUS_COOLDOWN"), math.ceil(antiSec / 60)))
    end

    self.statusStats:SetText(string.format(GB.L("STATUS_COUNTERS"),
        stats.new or 0, stats.trial or 0, store and store:GetUnreadCount() or 0))

    if not config.dryRun and not config.livePostConfirmed then
        self.statusAlert:SetText(GB.L("STATUS_LIVE_ALERT"))
    else
        self.statusAlert:SetText("")
    end
end

function Dashboard:UpdateTabs()
    local widgets = W()
    if not widgets or not self.tabButtons then
        return
    end
    local store = GetStore()
    local unread = store and store:GetUnreadCount() or 0
    local stats = store and store:GetStats() or { new = 0 }
    local active = self:GetActiveTab()
    for id, btn in pairs(self.tabButtons or {}) do
        widgets:SetTabSelected(btn, id == active)
        if id == "triage" then
            widgets:SetTabBadge(btn, unread + (stats.new or 0))
        elseif id == "pipeline" then
            widgets:SetTabBadge(btn, stats.trial or 0)
        else
            widgets:SetTabBadge(btn, nil)
        end
    end
end

-- ---------------------------------------------------------------------------
-- List (pooled rows)
-- ---------------------------------------------------------------------------

function Dashboard:GetListItems()
    local store = GetStore()
    if not store then
        return {}
    end
    local tab = self:GetActiveTab()
    if tab == "triage" then
        return store:GetTriageItems()
    end
    local ui = GetUI()
    local people = store:GetSortedPeople(ui.statusFilter, ui.searchQuery, ui.sortBy)
    local items = {}
    for _, person in ipairs(people) do
        items[#items + 1] = { type = "candidate", key = person.key, person = person, at = person.lastSeen, unread = person.status == "new" }
    end
    return items
end

function Dashboard:RefreshList()
    local items = self:GetListItems()
    local selected = self:GetSelectedKey()
    local listH = (self.layout and self.layout.listPaneH) or 200
    local contentH = math.max(listH, #items * (ROW_H + 2) + 4)
    self.listContent:SetHeight(contentH)

    if #items == 0 then
        self.listEmpty:SetText(self:GetActiveTab() == "triage" and GB.L("INBOX_EMPTY") or GB.L("CANDIDATES_EMPTY"))
        self.listEmpty:Show()
    else
        self.listEmpty:Hide()
    end

    for i = 1, ROW_POOL do
        local row = self.listRows[i]
        local item = items[i]
        if item then
            row:Show()
            AnchorTo(row, "TOPLEFT", self.listContent, "TOPLEFT", 0, -((i - 1) * (ROW_H + 2)))
            local key = item.key
            local title, subtitle, badge
            if item.type == "message" and item.msg then
                local msg = item.msg
                title = string.format("%s %s", W():ChannelIcon(msg.channel), msg.from or "?")
                subtitle = W():Truncate(msg.body or "", 52)
                badge = W():FormatRelativeTime(msg.at)
                row.unreadMark:SetShown(not msg.read)
            else
                local person = item.person or GetStore():GetPerson(key)
                title = person and person.key or key
                subtitle = W():Truncate(person and person.lastMessage or "", 52)
                badge = W():StatusBadgeText(person and person.status or "new")
                row.unreadMark:SetShown(item.unread)
                if person and person.test then
                    title = title .. " " .. GB.L("BADGE_TEST")
                end
            end
            row.title:SetText(title)
            row.subtitle:SetText(subtitle)
            row.badge:SetText(badge or "")
            W():SetListRowSelected(row, key == selected)
            row:SetScript("OnClick", function()
                Dashboard:SelectItem(key, item.msg and item.msg.id)
            end)
            row:SetScript("OnMouseUp", function(_, button)
                if button == "RightButton" and key then
                    Dashboard:SelectItem(key, item.msg and item.msg.id)
                    Dashboard:ShowStatusMenu(key)
                elseif button == "LeftButton" and IsShiftKeyDown() and key then
                    if W():CopyToClipboard(key) then
                        GB.API:Print(GB.L("COPIED_NAME"), key)
                    end
                end
            end)
        else
            row:Hide()
        end
    end
end

-- ---------------------------------------------------------------------------
-- Detail panel
-- ---------------------------------------------------------------------------

function Dashboard:UpdateDetail()
    local key = self:GetSelectedKey()
    local store = GetStore()
    if not key or not store then
        self:HideDetail()
        return
    end
    local person = store:GetPerson(key)
    if not person then
        self:HideDetail()
        return
    end
    self:ShowDetail()

    self.detailName:SetText(person.key)
    self.detailStatus:SetText(W():StatusBadgeText(person.status))
    local rioScore = person.rio and person.rio.score or 0
    local raid = person.rio and person.rio.raid or ""
    self.detailMeta:SetText(string.format("%s · " .. GB.L("MSG_COUNT") .. " · M+ %d · %s",
        W():FormatRelativeTime(person.lastSeen),
        person.messageCount or 0,
        rioScore,
        raid ~= "" and raid or GB.L("NO_RAID_DATA")))
    if person.test then
        self.detailTestBadge:SetText(GB.L("BADGE_TEST"))
        self.detailTestBadge:Show()
    else
        self.detailTestBadge:Hide()
    end

    self:UpdateDetailMessages(key)
    if not self.detailNotesBox:HasFocus() then
        self.detailNotesBox:SetText(person.notes or "")
    end
    self:UpdateDetailTimeline(person)
    self:UpdateDetailActions(key, person)
end

function Dashboard:UpdateDetailMessages(key)
    local store = GetStore()
    local messages = store and store:GetMessagesForPerson(key) or {}
    local child = self.detailMsgContent
    local children = { child:GetChildren() }
    for _, c in ipairs(children) do
        c:Hide()
        c:SetParent(nil)
    end
    local y = 0
    for i = 1, math.min(8, #messages) do
        local msg = messages[i]
        local fs = W():CreateMutedFontString(child)
        fs:SetWidth((self.layout and self.layout.detailW - 40) or 260)
        fs:SetJustifyH("LEFT")
        fs:SetPoint("TOPLEFT", 0, -y)
        fs:SetText(string.format("%s |cff9a8b7f%s|r\n%s",
            W():ChannelIcon(msg.channel), W():FormatRelativeTime(msg.at), msg.body or ""))
        y = y + 36
    end
    child:SetHeight(math.max(80, y + 8))
end

function Dashboard:UpdateDetailTimeline(person)
    local child = self.detailTimelineScroll.content
    local children = { child:GetChildren() }
    for _, c in ipairs(children) do
        c:Hide()
        c:SetParent(nil)
    end
    local timeline = person.timeline or {}
    local y = 0
    for i = 1, math.min(6, #timeline) do
        local ev = timeline[i]
        local fs = W():CreateMutedFontString(child)
        fs:SetWidth((self.layout and self.layout.detailW - 40) or 260)
        fs:SetJustifyH("LEFT")
        fs:SetPoint("TOPLEFT", 0, -y)
        local label = GB.L("TIMELINE_" .. string.upper(ev.type or "")) or ev.type
        fs:SetText(string.format("|cff9a8b7f%s|r %s — %s", W():FormatRelativeTime(ev.at), label, ev.detail or ""))
        y = y + 14
    end
    child:SetHeight(math.max(60, y + 8))
end

function Dashboard:UpdateDetailActions(key, person)
    if self.detailActionButtons then
        for _, btn in ipairs(self.detailActionButtons) do
            btn:Hide()
            btn:SetParent(nil)
        end
    end
    self.detailActionButtons = {}
    local parent = self.detailActions
    local x = 0

    local function addBtn(w, label, tip, fn, variant)
        local btn = W():CreateButton(parent, w, 24, label, fn, variant or "secondary")
        btn:SetPoint("LEFT", x, 0)
        W():SetTooltip(btn, label, tip)
        self.detailActionButtons[#self.detailActionButtons + 1] = btn
        x = x + w + 4
    end

    addBtn(64, GB.L("BTN_WHISPER"), GB.L("TIP_WHISPER"), function()
        W():OpenWhisper(key)
    end, "ghost")
    addBtn(40, "RIO", GB.L("TIP_RIO"), function()
        local store = GetStore()
        if store then
            store:Enrich(key)
            Dashboard:UpdateDetail()
        end
    end)

    local statuses = GB.API:GetModuleConfig().candidates.statuses or {}
    for _, status in ipairs(statuses) do
        if status ~= person.status then
            local label = W():StatusLabel(status):sub(1, 4)
            addBtn(52, label, W():StatusLabel(status), function()
                local store = GetStore()
                if store then
                    store:SetStatus(key, status)
                    Dashboard:UpdateDetail()
                    Dashboard:RefreshList()
                    Dashboard:UpdateTabs()
                end
            end)
        end
    end
end

function Dashboard:ShowStatusMenu(key)
    -- Right-click already cycles via detail; optional future menu
end

-- ---------------------------------------------------------------------------
-- Full views: beacon & settings
-- ---------------------------------------------------------------------------

function Dashboard:ClearFullView()
    local children = { self.fullView:GetChildren() }
    for _, child in ipairs(children) do
        child:Hide()
        child:SetParent(nil)
    end
end

function Dashboard:RenderBeacon()
    self:ClearFullView()
    local parent = self.fullView
    local config = GB.API:GetModuleConfig().beacon
    local scheduler = GetScheduler()
    local y = -4

    local statusFs = W():CreateGoldFontString(parent)
    statusFs:SetPoint("TOPLEFT", 8, y)
    local dryLabel = config.dryRun and GB.L("BEACON_DRY_ON") or GB.L("BEACON_DRY_OFF")
    statusFs:SetText(string.format(GB.L("BEACON_STATUS"), config.enabled and GB.L("ON") or GB.L("OFF")) .. " · " .. dryLabel)
    y = y - 22

    if not config.dryRun and not config.livePostConfirmed then
        local blocked = W():CreateMutedFontString(parent)
        blocked:SetPoint("TOPLEFT", 8, y)
        blocked:SetWidth(760)
        blocked:SetTextColor(0.9, 0.35, 0.35)
        blocked:SetText(GB.L("BEACON_LIVE_BLOCKED"))
        y = y - 20
    end

    local cdSec = scheduler and scheduler:GetSecondsUntilNextPost() or 0
    local cdFs = W():CreateMutedFontString(parent)
    cdFs:SetPoint("TOPLEFT", 8, y)
    if config.enabled and cdSec > 0 then
        cdFs:SetText(string.format(GB.L("BEACON_NEXT_IN"), math.ceil(cdSec / 60), math.ceil((scheduler:GetCooldownSeconds() or 0) / 60)))
    else
        cdFs:SetText(string.format(GB.L("BEACON_COOLDOWN"), math.ceil((scheduler:GetCooldownSeconds() or 0) / 60)))
    end
    y = y - 22

    local previewBox = CreateFrame("Frame", nil, parent)
    previewBox:SetSize(760, 56)
    previewBox:SetPoint("TOPLEFT", 8, y - 56)
    W():ApplyInsetBackdrop(previewBox)
    local previewFs = W():CreateMutedFontString(previewBox)
    previewFs:SetPoint("TOPLEFT", 12, -10)
    previewFs:SetWidth(730)
    previewFs:SetJustifyH("LEFT")
    local preview = scheduler and scheduler:Preview() or ""
    previewFs:SetText(string.format("|cffd4af37%s|r", GB.L("BEACON_PREVIEW_LABEL")) .. "\n" .. preview)
    y = y - 68

    local dryCb = W():CreateCheckbox(parent, GB.L("CFG_DRY_RUN"), config.dryRun, function(checked)
        config.dryRun = checked
        if checked then
            config.livePostConfirmed = false
        end
        Dashboard:Refresh()
    end)
    dryCb:SetPoint("TOPLEFT", 8, y)
    y = y - 28

    if not config.dryRun then
        local liveCb = W():CreateCheckbox(parent, GB.L("TEST_LIVE_CONFIRM"), config.livePostConfirmed, function(checked)
            config.livePostConfirmed = checked
        end)
        liveCb:SetPoint("TOPLEFT", 8, y)
        y = y - 26
    end

    local toggleBtn
    if config.enabled then
        toggleBtn = W():CreateButton(parent, 120, 24, GB.L("BEACON_STOP"), function()
            config.enabled = false
            GB.API:DisableModule("Beacon")
            Dashboard:Refresh()
        end)
    else
        toggleBtn = W():CreateButton(parent, 120, 24, GB.L("BEACON_START"), function()
            config.enabled = true
            GB.API:EnableModule("Beacon")
            Dashboard:Refresh()
        end)
    end
    toggleBtn:SetPoint("TOPLEFT", 8, y)

    local postBtn = W():CreateButton(parent, 100, 28, GB.L("BEACON_POST_NOW"), function()
        if not Dashboard:CanPostLive() then
            GB.API:Print(GB.L("TEST_LIVE_BLOCKED"))
            Dashboard:SelectTab("settings")
            GetUI().diagnosticsOpen = true
            return
        end
        if not config.dryRun then
            StaticPopup_Show("GUILDBEACON_CONFIRM_LIVE")
            return
        end
        if scheduler then
            scheduler:PostNow()
            Dashboard:Refresh()
        end
    end, "primary")
    postBtn:SetPoint("LEFT", toggleBtn, "RIGHT", 8, 0)
    W():SetTooltip(postBtn, GB.L("BEACON_POST_NOW"), GB.L("TIP_POST_NOW"))
    y = y - 34

    local histHeader = W():CreateGoldFontString(parent)
    histHeader:SetPoint("TOPLEFT", 8, y)
    histHeader:SetText(GB.L("BEACON_HISTORY"))
    y = y - 18

    local history = scheduler and scheduler:GetPostHistory() or {}
    for i = 1, math.min(5, #history) do
        local entry = history[i]
        local line = W():CreateMutedFontString(parent)
        line:SetPoint("TOPLEFT", 12, y)
        line:SetWidth(740)
        line:SetJustifyH("LEFT")
        local tag = entry.dryRun and GB.L("HISTORY_DRY") or GB.L("HISTORY_LIVE")
        line:SetText(string.format("%s [%s] %s — %s", W():FormatRelativeTime(entry.at), tag, entry.channel or "?", W():Truncate(entry.body, 70)))
        y = y - 14
    end
    if #history == 0 then
        local empty = W():CreateMutedFontString(parent)
        empty:SetPoint("TOPLEFT", 12, y)
        empty:SetText(GB.L("BEACON_HISTORY_EMPTY"))
    end
end

function Dashboard:RenderSettings()
    self:ClearFullView()
    local parent = self.fullView
    local config = GB.API:GetModuleConfig()
    local y = -4

    local innerW = (self.layout and self.layout.innerW) or 660
    local bodyH = (self.layout and self.layout.bodyH) or 360
    local scroll = W():CreateScrollArea(parent, innerW - 16, bodyH - 12)
    scroll:SetPoint("TOPLEFT", 8, -8)
    local content = scroll.content
    content:SetWidth(innerW - 44)
    local cy = 0

    local function addY(h)
        cy = cy - h
        return cy
    end

    local function place(widget, offsetY)
        widget:SetPoint("TOPLEFT", 8, offsetY)
    end

    local intervalLabel = W():CreateMutedFontString(content)
    place(intervalLabel, addY(0) - 16)
    intervalLabel:SetText(GB.L("CFG_INTERVAL"))
    addY(20)

    local intervalBox = CreateFrame("EditBox", nil, content, "InputBoxTemplate")
    intervalBox:SetSize(60, 20)
    place(intervalBox, cy)
    intervalBox:SetAutoFocus(false)
    intervalBox:SetNumeric(true)
    intervalBox:SetText(tostring(config.beacon.intervalMinutes or 15))
    intervalBox:SetScript("OnEnterPressed", function(self)
        config.beacon.intervalMinutes = math.max(1, tonumber(self:GetText()) or 15)
        if GetScheduler() and config.beacon.enabled then
            GetScheduler():Start()
        end
        self:ClearFocus()
    end)
    addY(32)

    local function addCheckbox(label, checked, onToggle)
        local cb = W():CreateCheckbox(content, label, checked, onToggle)
        place(cb, cy)
        addY(28)
        return cb
    end

    addCheckbox(GB.L("CFG_CHANNEL_GUILD"), Dashboard:HasChannel("guild"), function(c)
        Dashboard:SetChannel("guild", c)
    end)
    addCheckbox(GB.L("CFG_CHANNEL_SAY"), Dashboard:HasChannel("say"), function(c)
        Dashboard:SetChannel("say", c)
    end)
    addCheckbox(GB.L("CFG_OFFICER_ONLY"), config.beacon.onlyWhenOfficer, function(c)
        config.beacon.onlyWhenOfficer = c
    end)
    addCheckbox(GB.L("CFG_PAUSE_INSTANCE"), config.beacon.pauseInInstance, function(c)
        config.beacon.pauseInInstance = c
    end)
    addCheckbox(GB.L("CFG_ROTATE_TEMPLATES"), config.beacon.rotateTemplates, function(c)
        config.beacon.rotateTemplates = c
    end)
    addCheckbox(GB.L("CFG_CAPTURE_WHISPERS"), config.inbox.captureWhispers, function(c)
        config.inbox.captureWhispers = c
    end)
    addCheckbox(GB.L("CFG_CAPTURE_GUILD"), config.inbox.captureGuildChat, function(c)
        config.inbox.captureGuildChat = c
    end)
    addCheckbox(GB.L("CFG_RIO_ENRICH"), config.candidates.enrichRaiderIO, function(c)
        config.candidates.enrichRaiderIO = c
    end)

    local diagToggle = W():CreateButton(content, 200, 24, GetUI().diagnosticsOpen and GB.L("DIAG_COLLAPSE") or GB.L("DIAG_EXPAND"), function()
        GetUI().diagnosticsOpen = not GetUI().diagnosticsOpen
        Dashboard:Refresh()
    end)
    place(diagToggle, cy)
    addY(32)

    if GetUI().diagnosticsOpen then
        self:RenderDiagnostics(content, cy)
        cy = self.diagEndY or cy
    end

    content:SetHeight(math.abs(cy) + 40)
end

function Dashboard:RenderDiagnostics(parent, startY)
    local harness = GetHarness()
    local y = startY

    local intro = W():CreateMutedFontString(parent)
    intro:SetPoint("TOPLEFT", 8, y)
    intro:SetWidth(700)
    intro:SetJustifyH("LEFT")
    intro:SetText(GB.L("TEST_TAB_INTRO"))
    y = y - 28

    local debugOn = harness and harness:IsDebugEnabled()
    local debugCb = W():CreateCheckbox(parent, GB.L("TEST_DEBUG_LABEL"), debugOn, function(checked)
        if harness then harness:SetDebug(checked) end
    end)
    debugCb:SetPoint("TOPLEFT", 8, y)
    y = y - 30

    local btnSelf = W():CreateButton(parent, 88, 22, GB.L("TEST_BTN_SELF"), function()
        if harness then harness:RunSelf() end
    end)
    btnSelf:SetPoint("TOPLEFT", 8, y)

    local btnSeed2 = W():CreateButton(parent, 88, 22, GB.L("TEST_BTN_SEED"), function()
        if harness then harness:Seed() end
    end)
    btnSeed2:SetPoint("LEFT", btnSelf, "RIGHT", 6, 0)

    local btnClear = W():CreateButton(parent, 88, 22, GB.L("TEST_BTN_CLEAR"), function()
        if harness then harness:ClearTestData() end
    end)
    btnClear:SetPoint("LEFT", btnSeed2, "RIGHT", 6, 0)

    local btnDry = W():CreateButton(parent, 88, 22, GB.L("TEST_BTN_DRY_TICK"), function()
        if harness then harness:DryTickBeacon() end
    end)
    btnDry:SetPoint("LEFT", btnClear, "RIGHT", 6, 0)

    local btnTeardown = W():CreateButton(parent, 88, 22, GB.L("TEST_BTN_TEARDOWN"), function()
        if harness then harness:Teardown() end
    end)
    btnTeardown:SetPoint("LEFT", btnDry, "RIGHT", 6, 0)
    y = y - 28

    local nameBox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    nameBox:SetSize(150, 20)
    nameBox:SetPoint("TOPLEFT", 8, y)
    nameBox:SetAutoFocus(false)
    nameBox:SetText("TestRecruit-" .. (GetRealmName() or "Realm"))
    Dashboard.diagNameBox = nameBox

    local bodyBox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    bodyBox:SetSize(280, 20)
    bodyBox:SetPoint("LEFT", nameBox, "RIGHT", 8, 0)
    bodyBox:SetAutoFocus(false)
    bodyBox:SetText(GB.L("TEST_SIM_DEFAULT_BODY"))

    local simBtn = W():CreateButton(parent, 80, 22, GB.L("TEST_BTN_SIM"), function()
        if harness then harness:SimulateWhisper(nameBox:GetText(), bodyBox:GetText()) end
    end)
    simBtn:SetPoint("LEFT", bodyBox, "RIGHT", 8, 0)
    y = y - 28

    local logHeader = W():CreateGoldFontString(parent)
    logHeader:SetPoint("TOPLEFT", 8, y)
    logHeader:SetText(GB.L("TEST_LOG_HEADER"))
    y = y - 16

    local logScroll = W():CreateScrollArea(parent, 700, 100)
    logScroll:SetPoint("TOPLEFT", 4, y - 100)
    self.diagLogContent = logScroll.content
    self.diagLogScroll = logScroll
    self:UpdateDiagnosticsLog()

    self.diagEndY = y - 110
end

function Dashboard:UpdateDiagnosticsLog()
    if not self.diagLogContent then
        return
    end
    local child = self.diagLogContent
    local children = { child:GetChildren() }
    for _, c in ipairs(children) do
        c:Hide()
        c:SetParent(nil)
    end
    local y = 0
    if #testLog == 0 then
        local empty = W():CreateMutedFontString(child)
        empty:SetPoint("TOPLEFT", 4, 0)
        empty:SetText(GB.L("TEST_LOG_EMPTY"))
        child:SetHeight(20)
        return
    end
    for i = 1, #testLog do
        local fs = W():CreateMutedFontString(child)
        fs:SetWidth(680)
        fs:SetJustifyH("LEFT")
        fs:SetPoint("TOPLEFT", 4, -y)
        fs:SetText(testLog[i])
        y = y + 14
    end
    child:SetHeight(y + 8)
end

function Dashboard:HasChannel(channel)
    local channels = GB.API:GetModuleConfig().beacon.channels or {}
    for _, ch in ipairs(channels) do
        if ch == channel then
            return true
        end
    end
    return false
end

function Dashboard:SetChannel(channel, enabled)
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

-- ---------------------------------------------------------------------------
-- Pipeline toolbar
-- ---------------------------------------------------------------------------

function Dashboard:EnsurePipelineToolbar()
    if self.pipelineToolbar then
        return
    end
    local innerW = (self.layout and self.layout.innerW) or 660
    local bar = CreateFrame("Frame", nil, self.splitView)
    bar:SetSize(innerW, LAYOUT.PIPE_TOOLBAR_H)
    bar:SetPoint("TOPLEFT", 0, 0)
    W():ApplyInsetBackdrop(bar)
    self.pipelineToolbar = bar

    self.searchBox = W():CreateSearchBox(bar, math.min(180, innerW * 0.28), GB.L("SEARCH_PLACEHOLDER"), function(text)
        GetUI().searchQuery = text
        Dashboard:RefreshList()
    end)
    self.searchBox:SetPoint("TOPLEFT", 8, -6)

    local sorts = { "recent", "rio", "status" }
    local sx = 0
    for _, sortId in ipairs(sorts) do
        local btn = W():CreateButton(bar, 64, 24, GB.L("SORT_" .. string.upper(sortId)), function()
            GetUI().sortBy = sortId
            Dashboard:RefreshList()
        end)
        btn:SetPoint("LEFT", self.searchBox, "RIGHT", 8 + sx, 0)
        sx = sx + 76
    end

    local filterRow = CreateFrame("Frame", nil, bar)
    filterRow:SetPoint("TOPLEFT", 8, -30)
    filterRow:SetSize(innerW - 16, 22)
    local filterLabel = W():CreateMutedFontString(filterRow)
    filterLabel:SetPoint("LEFT", 0, 0)
    filterLabel:SetText(GB.L("FILTER_STATUS"))

    local statuses = GB.API:GetModuleConfig().candidates.statuses or {}
    local fx = 90
    for _, status in ipairs(statuses) do
        local btn = W():CreateButton(filterRow, 64, 20, W():StatusLabel(status):sub(1, 5), function()
            local ui = GetUI()
            ui.statusFilter = (ui.statusFilter == status) and "" or status
            Dashboard:RefreshList()
        end)
        btn:SetPoint("LEFT", fx, 0)
        if GetUI().statusFilter == status then
            btn:SetAlpha(1)
        else
            btn:SetAlpha(0.7)
        end
        fx = fx + 68
    end
end

-- ---------------------------------------------------------------------------
-- Refresh orchestration
-- ---------------------------------------------------------------------------

function Dashboard:RefreshViews()
    if not self.frame or not W() or not self.splitView or not self.fullView then
        return
    end

    local tab = self:GetActiveTab()
    local isSplit = tab == "triage" or tab == "pipeline"

    self:UpdateStatusBar()
    self:UpdateTabs()

    self.splitView:SetShown(isSplit)
    self.fullView:SetShown(not isSplit)

    if self.triageBar then
        self.triageBar:SetShown(tab == "triage")
    end

    if isSplit then
        if tab == "pipeline" then
            self:EnsurePipelineToolbar()
        end
        if not self:GetSelectedKey() then
            local items = self:GetListItems()
            if items[1] then
                local first = items[1]
                self:SelectItem(first.key, first.msg and first.msg.id)
            end
        end
        self:RefreshList()
        self:UpdateDetail()
    elseif tab == "beacon" then
        self:RenderBeacon()
    elseif tab == "settings" then
        self:RenderSettings()
    else
        self:SetActiveTab("triage")
        self.splitView:Show()
        self.fullView:Hide()
        self:RefreshList()
        self:UpdateDetail()
    end
end

function Dashboard:Refresh()
    if not self.frame or not W() then
        return
    end
    self:ApplyLayout()
    self:RefreshViews()
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

function Dashboard:ResetUI()
    self:DestroyFrame()
    local ui = GetUI()
    ui.framePoint = nil
    ui.frameWidth = 720
    ui.frameHeight = 560
    ui.layoutVersion = 11
    ui.dashboardScale = 1
end

function Dashboard:EnsureVisible()
    if not self.frame then
        return
    end
    self.frame:ClearAllPoints()
    self.frame:SetPoint("CENTER")
    local ui = GetUI()
    if ui then
        ui.framePoint = nil
    end
end

local function BringFrameToFront(frame)
    if not frame then
        return
    end
    frame:SetFrameStrata("DIALOG")
    if frame.Raise then
        frame:Raise()
    elseif frame.SetFrameLevel then
        frame:SetFrameLevel((frame:GetFrameLevel() or 0) + 10)
    end
end

local function IsFrameOnScreen(frame)
    if not frame then
        return false
    end
    local left, bottom, right, top = frame:GetLeft(), frame:GetBottom(), frame:GetRight(), frame:GetTop()
    if not left or not bottom or not right or not top then
        return false
    end
    local sw, sh = UIParent:GetSize()
    if not sw or sw <= 0 or not sh or sh <= 0 then
        return true
    end
    return right > 0 and left < sw and top > 0 and bottom < sh
end

function Dashboard:TryOpen(tab)
    local ok, err = pcall(function()
        if not self:EnsureFrame() then
            error("UI widgets unavailable")
        end
        if not self:IsFrameReady() then
            error("dashboard frame incomplete")
        end
        if tab then
            self:SetActiveTab(tab)
        end
        local ui = GetUI()
        local scale = tonumber(ui and ui.dashboardScale) or 1
        if scale <= 0 or scale > 2 then
            scale = 1
            if ui then
                ui.dashboardScale = 1
            end
        end
        self.frame:SetScale(scale)
        if ui and ui.framePoint then
            local _, _, _, x, y = self.frame:GetPoint(1)
            if x and (math.abs(x) > 2000 or math.abs(y or 0) > 2000) then
                self:EnsureVisible()
            end
        end
        self.frame:Show()
        BringFrameToFront(self.frame)
        if not self.frame:IsShown() or not IsFrameOnScreen(self.frame) then
            self:EnsureVisible()
            self.frame:Show()
            BringFrameToFront(self.frame)
        end
        self:Refresh()
    end)
    if not ok then
        if GB.API and GB.API.Print then
            GB.API:Print("|cffff4444Dashboard error:|r %s — try /reload", tostring(err))
        elseif DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff4444GuildBeacon:|r " .. tostring(err) .. " — try /reload")
        end
        return false
    end
    return true
end

function Dashboard:IsShown()
    return self.frame and self.frame:IsShown()
end

function Dashboard:Toggle()
    if self:IsShown() then
        self.frame:Hide()
        return
    end
    self:TryOpen()
end

function Dashboard:Open(tab)
    self:TryOpen(tab)
end

function Dashboard:Initialize()
    StaticPopupDialogs.GUILDBEACON_CONFIRM_LIVE = {
        text = GB.L("POPUP_LIVE_TEXT"),
        button1 = GB.L("POPUP_CONFIRM"),
        button2 = GB.L("POPUP_CANCEL"),
        OnAccept = function()
            local scheduler = GetScheduler()
            if scheduler then
                scheduler:PostNow()
            end
            if Dashboard.frame and Dashboard.frame:IsShown() then
                Dashboard:Refresh()
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
end
