--- Shared UI helpers (no external libs).

local GB = GuildBeacon
local Branding = GB.Internal.Branding
local Widgets = {}
GB.UI = GB.UI or {}
GB.UI.Widgets = Widgets

local BACKDROP = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
}

function Widgets:ApplyDialogBackdrop(frame)
    if frame.SetBackdrop then
        frame:SetBackdrop(BACKDROP)
    elseif frame.SetBackdropColor then
        frame:SetBackdropColor(0.05, 0.05, 0.07, 0.95)
    end
end

function Widgets:CreateGoldFontString(parent, size)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetTextColor(0.83, 0.69, 0.22)
    if size then
        fs:SetFont(fs:GetFont(), size)
    end
    return fs
end

function Widgets:CreateMutedFontString(parent)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetTextColor(0.6, 0.55, 0.5)
    return fs
end

function Widgets:CreateButton(parent, width, height, label, onClick)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(width or 100, height or 22)
    btn:SetText(label or "")
    if onClick then
        btn:SetScript("OnClick", onClick)
    end
    return btn
end

function Widgets:CreateCheckbox(parent, label, checked, onToggle)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    local text = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    text:SetText(label or "")
    cb.label = text
    cb:SetChecked(checked and true or false)
    cb:SetScript("OnClick", function(self)
        if onToggle then
            onToggle(self:GetChecked())
        end
    end)
    return cb
end

function Widgets:CreateTabButton(parent, label, onClick)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetHeight(24)
    local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    fs:SetPoint("CENTER")
    fs:SetText(label)
    btn.text = fs
    btn:SetScript("OnClick", onClick)
    btn:SetNormalFontObject("GameFontNormal")
    btn:SetHighlightFontObject("GameFontHighlight")
    return btn
end

function Widgets:CreateScrollList(parent, width, height)
    local scroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scroll:SetSize(width, height)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(width - 24, height)
    scroll:SetScrollChild(child)
    scroll.content = child
    return scroll
end

function Widgets:FormatRelativeTime(ts)
    if not ts or ts == 0 then
        return "-"
    end
    local diff = time() - ts
    if diff < 60 then
        return GB.L("TIME_JUST_NOW")
    elseif diff < 3600 then
        return string.format(GB.L("TIME_MINUTES"), math.floor(diff / 60))
    elseif diff < 86400 then
        return string.format(GB.L("TIME_HOURS"), math.floor(diff / 3600))
    end
    return string.format(GB.L("TIME_DAYS"), math.floor(diff / 86400))
end

function Widgets:StatusLabel(status)
    local key = "STATUS_" .. string.upper(status or "NEW")
    return GB.L(key) or status
end

function Widgets:ParseNameRealm(fullName)
    if GB.IsSecret(fullName) then
        return fullName, nil
    end
    local name, realm = fullName:match("^([^%-]+)%-(.+)$")
    if name then
        return name, realm
    end
    return fullName, GetRealmName()
end
