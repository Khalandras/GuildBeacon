--- GB-WIDGETS-BUILD 20260629E
--- Nox design system for GuildBeacon (no BackdropTemplate).

local GB = GuildBeacon
local WHITE_TEX = "Interface\\Buttons\\WHITE8X8"

local Widgets = {}
GB.UI = GB.UI or {}
GB.UI.Widgets = Widgets
GB.WIDGETS_BUILD = "20260629E"

local function Hex(hex)
    hex = (hex or ""):gsub("#", "")
    if #hex < 6 then
        return 0, 0, 0
    end
    return tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255
end

local function ColorToken(hex, alpha)
    local r, g, b = Hex(hex)
    return { r, g, b, alpha or 1 }
end

local function Token(name)
    local t = Widgets.TOKENS[name] or Widgets.TOKENS.bgPrimary
    return t[1], t[2], t[3], t[4]
end

local function SetTexColor(tex, r, g, b, a)
    if not tex then
        return
    end
    a = a or 1
    if tex.SetTexture then
        tex:SetTexture(WHITE_TEX)
    end
    if tex.SetVertexColor then
        tex:SetVertexColor(r, g, b)
        if tex.SetAlpha then
            tex:SetAlpha(a)
        end
    elseif tex.SetColorTexture then
        tex:SetColorTexture(r, g, b, a)
    end
end

local function SetTextColor(fs, r, g, b, a)
    if not fs then
        return
    end
    if a and a < 1 then
        fs:SetTextColor(r, g, b, a)
    else
        fs:SetTextColor(r, g, b)
    end
end

local function StripBackdrop(frame)
    if not frame then
        return
    end
    if frame.SetBackdrop then
        pcall(frame.SetBackdrop, frame, nil)
    end
    if frame.NineSlice and frame.NineSlice.Hide then
        frame.NineSlice:Hide()
    end
end

local function StyleScrollBar(scroll)
    local bar = scroll and scroll.ScrollBar
    if not bar then
        return
    end
    StripBackdrop(bar)
    if bar.Background then
        bar.Background:Hide()
    end
    if bar.ScrollUpButton then
        bar.ScrollUpButton:Hide()
    end
    if bar.ScrollDownButton then
        bar.ScrollDownButton:Hide()
    end
    if bar.SetWidth then
        bar:SetWidth(8)
    end
    local track = bar.Track or bar.trackBG
    if track then
        track:SetTexture(WHITE_TEX)
        SetTexColor(track, Token("bgElevated"))
    end
    local thumb = bar.Thumb or (bar.GetThumbTexture and bar:GetThumbTexture())
    if thumb then
        thumb:SetTexture(WHITE_TEX)
        SetTexColor(thumb, Token("phosphor"))
        if thumb.SetAlpha then
            thumb:SetAlpha(0.75)
        end
    end
end

local function SolidBg(frame, r, g, b, a)
    if not frame then
        return
    end
    local tex = frame.gbSolidBg
    if tex and tex.GetParent and not tex:GetParent() then
        frame.gbSolidBg = nil
        tex = nil
    end
    if not tex then
        tex = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
        tex:SetAllPoints()
        frame.gbSolidBg = tex
    end
    SetTexColor(tex, r, g, b, a or 1)
end

local function OutlineEdge(frame, key, setup)
    local edge = frame[key]
    if edge and edge.GetParent and not edge:GetParent() then
        frame[key] = nil
        edge = nil
    end
    if not edge then
        edge = frame:CreateTexture(nil, "BORDER", nil, 2)
        frame[key] = edge
    end
    edge:SetTexture(WHITE_TEX)
    edge:ClearAllPoints()
    setup(edge)
    return edge
end

Widgets.TOKENS = {
    abyss = ColorToken("040408"),
    bgPrimary = ColorToken("08080e"),
    bgSecondary = ColorToken("0e0c14"),
    bgElevated = ColorToken("141018"),
    bgSurface = ColorToken("1a1522"),
    bgHover = ColorToken("221c2c", 0.85),
    gold = ColorToken("d4af37"),
    phosphor = ColorToken("b794f6"),
    nox = ColorToken("2d1848"),
    wine = ColorToken("6b1d3a"),
    wineHover = ColorToken("8b2550"),
    textPrimary = ColorToken("f2f0f5"),
    textSecondary = ColorToken("a89cb8"),
    textMuted = ColorToken("6b6178"),
    border = ColorToken("3a3248"),
    borderHair = ColorToken("d4af37", 0.18),
    success = ColorToken("45c4b0"),
    warning = ColorToken("d4a84b"),
    error = ColorToken("c45c5c"),
    info = ColorToken("6b8cce"),
}

Widgets.STATUS_COLORS = {
    new = ColorToken("d4af37"),
    contacted = ColorToken("6b8cce"),
    trial = ColorToken("b794f6"),
    accepted = ColorToken("45c4b0"),
    rejected = ColorToken("c45c5c"),
    archived = ColorToken("6b6178"),
}

function Widgets:RGB(name)
    return Token(name)
end

function Widgets:ApplyOpaqueBackground(frame, r, g, b, a)
    SolidBg(frame, r, g, b, a)
end

function Widgets:ApplyHairline(frame, alpha)
    if not frame or frame.gbHairline then
        return
    end
    local line = frame:CreateTexture(nil, "OVERLAY", nil, 7)
    line:SetPoint("TOPLEFT", 1, -1)
    line:SetPoint("TOPRIGHT", -1, -1)
    line:SetHeight(1)
    SetTexColor(line, Token("borderHair"))
    if line.SetAlpha then
        line:SetAlpha(alpha or 0.35)
    end
    frame.gbHairline = line
end

function Widgets:ApplyFrameOutline(frame, alpha)
    local a = alpha or 0.55
    local r, g, b = Token("border")
    local top = OutlineEdge(frame, "gbOutlineTop", function(edge)
        edge:SetHeight(1)
        edge:SetPoint("TOPLEFT", 0, 0)
        edge:SetPoint("TOPRIGHT", 0, 0)
    end)
    SetTexColor(top, r, g, b, a)
    local bottom = OutlineEdge(frame, "gbOutlineBottom", function(edge)
        edge:SetHeight(1)
        edge:SetPoint("BOTTOMLEFT", 0, 0)
        edge:SetPoint("BOTTOMRIGHT", 0, 0)
    end)
    SetTexColor(bottom, r, g, b, a)
    local left = OutlineEdge(frame, "gbOutlineLeft", function(edge)
        edge:SetWidth(1)
        edge:SetPoint("TOPLEFT", 0, 0)
        edge:SetPoint("BOTTOMLEFT", 0, 0)
    end)
    SetTexColor(left, r, g, b, a)
    local right = OutlineEdge(frame, "gbOutlineRight", function(edge)
        edge:SetWidth(1)
        edge:SetPoint("TOPRIGHT", 0, 0)
        edge:SetPoint("BOTTOMRIGHT", 0, 0)
    end)
    SetTexColor(right, r, g, b, a)
end

function Widgets:ApplyModernSurface(frame, tokenName, hairline)
    local r, g, b, a = Token(tokenName or "bgSecondary")
    SolidBg(frame, r, g, b, a)
    if hairline ~= false then
        self:ApplyHairline(frame, 0.22)
    end
end

function Widgets:ApplyPanelBackdrop(frame, tokenName)
    self:ApplyModernSurface(frame, tokenName or "bgSecondary", true)
    self:ApplyFrameOutline(frame, 0.35)
end

function Widgets:ApplyInsetBackdrop(frame)
    self:ApplyModernSurface(frame, "bgElevated", true)
end

function Widgets:ApplyWindowChrome(frame)
    SolidBg(frame, Token("abyss"))
    self:ApplyFrameOutline(frame, 0.55)
    if frame.gbTopGlow then
        return
    end
    local glow = frame:CreateTexture(nil, "ARTWORK", nil, 7)
    glow:SetPoint("TOPLEFT", 1, -1)
    glow:SetPoint("TOPRIGHT", -1, -1)
    glow:SetHeight(1)
    SetTexColor(glow, Token("phosphor"))
    if glow.SetAlpha then
        glow:SetAlpha(0.45)
    end
    frame.gbTopGlow = glow
end

function Widgets:ApplyStatusStrip(frame)
    self:ApplyModernSurface(frame, "bgSecondary", false)
    if frame.gbStatusRule then
        return
    end
    local rule = frame:CreateTexture(nil, "OVERLAY")
    rule:SetPoint("BOTTOMLEFT", 8, 0)
    rule:SetPoint("BOTTOMRIGHT", -8, 0)
    rule:SetHeight(1)
    SetTexColor(rule, Token("border"))
    if rule.SetAlpha then
        rule:SetAlpha(0.4)
    end
    frame.gbStatusRule = rule
end

function Widgets:DecorateTabBar(frame)
    if frame.gbTabRule then
        return
    end
    local rule = frame:CreateTexture(nil, "ARTWORK")
    rule:SetPoint("BOTTOMLEFT", 0, 0)
    rule:SetPoint("BOTTOMRIGHT", 0, 0)
    rule:SetHeight(1)
    SetTexColor(rule, Token("border"))
    if rule.SetAlpha then
        rule:SetAlpha(0.5)
    end
    frame.gbTabRule = rule
end

function Widgets:CreateTitleBand(parent, width, height)
    local band = CreateFrame("Frame", nil, parent)
    height = height or 44
    band:SetSize(width, height)
    local signal = band:CreateTexture(nil, "ARTWORK", nil, 7)
    signal:SetPoint("TOPLEFT", 0, 0)
    signal:SetPoint("TOPRIGHT", 0, 0)
    signal:SetHeight(3)
    SetTexColor(signal, Token("wine"))
    local base = band:CreateTexture(nil, "BACKGROUND")
    base:SetAllPoints()
    SetTexColor(base, Token("abyss"))
    local wash = band:CreateTexture(nil, "BACKGROUND", nil, 1)
    wash:SetPoint("TOPLEFT", 0, 0)
    wash:SetPoint("TOPRIGHT", 0, 0)
    wash:SetHeight(math.min(height, math.floor(height * 0.55)))
    local nr, ng, nb, na = Token("nox")
    SetTexColor(wash, nr, ng, nb, 0.22)
    local accent = band:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("TOPLEFT", 12, -1)
    accent:SetPoint("TOPRIGHT", -12, -1)
    accent:SetHeight(1)
    SetTexColor(accent, Token("phosphor"))
    if accent.SetAlpha then
        accent:SetAlpha(0.5)
    end
    local line = band:CreateTexture(nil, "OVERLAY")
    line:SetPoint("BOTTOMLEFT", 12, 0)
    line:SetPoint("BOTTOMRIGHT", -12, 0)
    line:SetHeight(1)
    SetTexColor(line, Token("gold"))
    if line.SetAlpha then
        line:SetAlpha(0.55)
    end
    return band
end

function Widgets:ApplyDiamondTexture(tex, size, tokenName, alpha)
    if not tex then
        return
    end
    size = size or 8
    tex:SetTexture(WHITE_TEX)
    tex:SetSize(size, size)
    if tex.SetRotation then
        tex:SetRotation(math.rad(45))
    end
    SetTexColor(tex, Token(tokenName or "gold"))
    if alpha and tex.SetAlpha then
        tex:SetAlpha(alpha)
    end
end

function Widgets:CreateDiamondMark(parent, size, tokenName)
    size = size or 10
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(size, size)
    frame.mark = frame:CreateTexture(nil, "ARTWORK")
    frame.mark:SetPoint("CENTER")
    self:ApplyDiamondTexture(frame.mark, math.floor(size * 0.65), tokenName)
    return frame
end

function Widgets:CreateSigil(parent, size)
    size = size or 22
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(size, size)
    frame:EnableMouse(false)
    local glow = frame:CreateTexture(nil, "BACKGROUND")
    glow:SetSize(size, size)
    glow:SetPoint("CENTER")
    SetTexColor(glow, Token("phosphor"))
    if glow.SetAlpha then
        glow:SetAlpha(0.12)
    end
    frame.mark = frame:CreateTexture(nil, "ARTWORK")
    frame.mark:SetPoint("CENTER")
    self:ApplyDiamondTexture(frame.mark, math.max(8, math.floor(size * 0.42)), "gold")
    return frame
end

function Widgets:CreateCloseButton(parent, onClick)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(22, 22)
    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetAllPoints()
    SetTexColor(btn.bg, 0, 0, 0, 0)
    btn.border = btn:CreateTexture(nil, "BORDER")
    btn.border:SetPoint("TOPLEFT", -1, 1)
    btn.border:SetPoint("BOTTOMRIGHT", 1, -1)
    SetTexColor(btn.border, Token("border"))
    if btn.border.SetAlpha then
        btn.border:SetAlpha(0.45)
    end
    btn.lineA = btn:CreateTexture(nil, "ARTWORK")
    btn.lineA:SetSize(10, 1)
    btn.lineA:SetPoint("CENTER")
    if btn.lineA.SetRotation then
        btn.lineA:SetRotation(math.rad(45))
    end
    btn.lineB = btn:CreateTexture(nil, "ARTWORK")
    btn.lineB:SetSize(10, 1)
    btn.lineB:SetPoint("CENTER")
    if btn.lineB.SetRotation then
        btn.lineB:SetRotation(math.rad(-45))
    end
    local mr, mg, mb = Token("textSecondary")
    SetTexColor(btn.lineA, mr, mg, mb, 0.9)
    SetTexColor(btn.lineB, mr, mg, mb, 0.9)
    btn:SetScript("OnClick", onClick)
    self:SetTooltip(btn, GB.L("BTN_CLOSE") or "Close", GB.L("TIP_CLOSE_ESC") or "Escape")
    return btn
end

function Widgets:CreateGoldFontString(parent, size)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetTextColor(fs, Token("gold"))
    if size then
        fs:SetFont(fs:GetFont(), size)
    end
    return fs
end

function Widgets:CreateSectionFontString(parent)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    SetTextColor(fs, Token("textPrimary"))
    return fs
end

function Widgets:CreateMutedFontString(parent)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    SetTextColor(fs, Token("textSecondary"))
    return fs
end

function Widgets:CreateBodyFontString(parent)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    SetTextColor(fs, Token("textPrimary"))
    return fs
end

function Widgets:CreateInsetSection(parent, title)
    local section = CreateFrame("Frame", nil, parent)
    section:SetClipsChildren(true)
    self:ApplyPanelBackdrop(section)
    section.title = self:CreateGoldFontString(section, 11)
    section.title:SetPoint("TOPLEFT", 10, -7)
    section.title:SetText(title or "")
    section.inner = CreateFrame("Frame", nil, section)
    section.inner:SetPoint("TOPLEFT", 8, -24)
    section.inner:SetPoint("BOTTOMRIGHT", -8, 8)
    return section
end

function Widgets:StyleEditBox(box)
    if not box then
        return
    end
    StripBackdrop(box)
    if box.Left then
        box.Left:Hide()
    end
    if box.Right then
        box.Right:Hide()
    end
    if box.Middle then
        SetTexColor(box.Middle, Token("bgPrimary"))
    else
        SolidBg(box, Token("bgPrimary"))
    end
    SetTextColor(box, Token("textPrimary"))
    if box.SetTextInsets then
        box:SetTextInsets(6, 6, 4, 4)
    end
    if box.SetFont then
        local font, fontSize = GameFontHighlightSmall:GetFont()
        if font then
            box:SetFont(font, fontSize or 12)
        end
    end
end

function Widgets:StyleButton(btn, variant)
    variant = variant or "secondary"
    if variant == "primary" then
        SetTexColor(btn.bg, Token("wine"))
        btn.border:Hide()
        btn.text:SetTextColor(1, 0.98, 0.96)
    elseif variant == "danger" then
        local r, g, b = Token("error")
        SetTexColor(btn.bg, r * 0.65, g * 0.65, b * 0.65, 1)
        btn.border:Hide()
        btn.text:SetTextColor(1, 0.95, 0.95)
    elseif variant == "ghost" then
        SetTexColor(btn.bg, 0, 0, 0, 0)
        btn.border:Hide()
        SetTextColor(btn.text, Token("textSecondary"))
    else
        SetTexColor(btn.bg, 0, 0, 0, 0)
        btn.border:Show()
        SetTexColor(btn.border, Token("border"))
        if btn.border.SetAlpha then
            btn.border:SetAlpha(0.65)
        end
        SetTextColor(btn.text, Token("textPrimary"))
    end
    btn.variant = variant
end

function Widgets:CreateButton(parent, width, height, label, onClick, variant)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(width or 96, height or 28)
    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetAllPoints()
    btn.border = btn:CreateTexture(nil, "BORDER")
    btn.border:SetPoint("TOPLEFT", -1, 1)
    btn.border:SetPoint("BOTTOMRIGHT", 1, -1)
    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    btn.text:SetPoint("CENTER")
    btn.text:SetText(label or "")
    self:StyleButton(btn, variant)
    if onClick then
        btn:SetScript("OnClick", onClick)
    end
    return btn
end

function Widgets:SetTooltip(widget, title, body)
    if not widget then
        return
    end
    widget:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if body then
            GameTooltip:SetText(title or "", 0.95, 0.93, 0.98)
            GameTooltip:AddLine(body, 0.66, 0.61, 0.72, true)
        else
            GameTooltip:SetText(title or "", 0.94, 0.93, 0.95, true)
        end
        GameTooltip:Show()
    end)
    widget:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

function Widgets:EnableDrag(handle, mover, onStop)
    if not handle then
        return
    end
    mover = mover or handle
    mover:SetMovable(true)
    handle:EnableMouse(true)
    handle:RegisterForDrag("LeftButton")
    handle:SetScript("OnDragStart", function()
        mover:StartMoving()
    end)
    handle:SetScript("OnDragStop", function()
        mover:StopMovingOrSizing()
        if onStop then
            onStop(mover)
        end
    end)
end

function Widgets:CreateCheckbox(parent, label, checked, onToggle)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    local text = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("LEFT", cb, "RIGHT", 2, 0)
    text:SetText(label or "")
    SetTextColor(text, Token("textPrimary"))
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
    btn:SetHeight(36)
    btn:SetWidth(80)
    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetPoint("TOPLEFT", 6, -6)
    btn.bg:SetPoint("BOTTOMRIGHT", -6, 6)
    SetTexColor(btn.bg, 0, 0, 0, 0)
    btn.underline = btn:CreateTexture(nil, "ARTWORK")
    btn.underline:SetHeight(2)
    btn.underline:SetPoint("BOTTOMLEFT", 8, 2)
    btn.underline:SetPoint("BOTTOMRIGHT", -8, 2)
    SetTexColor(btn.underline, Token("phosphor"))
    if btn.underline.SetAlpha then
        btn.underline:SetAlpha(0)
    end
    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    btn.text:SetPoint("CENTER", 0, 2)
    btn.text:SetText(label)
    SetTextColor(btn.text, Token("textMuted"))
    btn.badge = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    btn.badge:SetPoint("LEFT", btn.text, "RIGHT", 4, 1)
    SetTextColor(btn.badge, Token("gold"))
    btn.badge:Hide()
    btn:SetScript("OnClick", onClick)
    return btn
end

function Widgets:SetTabSelected(btn, selected)
    btn.selected = selected
    if selected then
        SetTextColor(btn.text, Token("textPrimary"))
        SetTexColor(btn.underline, Token("gold"))
        if btn.underline.SetAlpha then
            btn.underline:SetAlpha(0.95)
        end
        SetTexColor(btn.bg, Token("bgSurface"))
    else
        SetTextColor(btn.text, Token("textMuted"))
        SetTexColor(btn.underline, Token("phosphor"))
        if btn.underline.SetAlpha then
            btn.underline:SetAlpha(0)
        end
        SetTexColor(btn.bg, 0, 0, 0, 0)
    end
end

function Widgets:SetTabBadge(btn, count)
    if count and count > 0 then
        btn.badge:SetText(tostring(count))
        btn.badge:Show()
    else
        btn.badge:Hide()
    end
end

function Widgets:CreateScrollArea(parent, width, height)
    local shell = CreateFrame("Frame", nil, parent)
    shell:SetSize(width, height)
    self:ApplyModernSurface(shell, "bgSecondary", false)
    local scroll = CreateFrame("ScrollFrame", nil, shell, "UIPanelScrollFrameTemplate")
    StripBackdrop(scroll)
    StyleScrollBar(scroll)
    scroll:SetPoint("TOPLEFT", 6, -6)
    scroll:SetPoint("BOTTOMRIGHT", -10, 6)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(math.max(40, width - 34), math.max(40, height - 12))
    scroll:SetScrollChild(child)
    scroll.content = child
    scroll.shell = shell
    scroll.ClearAllPoints = function()
        shell:ClearAllPoints()
    end
    scroll.SetPoint = function(_, ...)
        return shell:SetPoint(...)
    end
    scroll.SetSize = function(_, w, h)
        shell:SetSize(w, h)
        child:SetWidth(math.max(40, (w or width) - 34))
        if h then
            child:SetHeight(math.max(40, h - 8))
        end
    end
    scroll.SetHeight = function(_, h)
        shell:SetHeight(h)
        child:SetHeight(math.max(40, h - 8))
    end
    scroll.SetWidth = function(_, w)
        shell:SetWidth(w)
        child:SetWidth(math.max(40, w - 34))
    end
    scroll.GetHeight = function()
        return shell:GetHeight()
    end
    scroll.GetWidth = function()
        return shell:GetWidth()
    end
    return scroll
end

function Widgets:CreateScrollList(parent, width, height)
    return self:CreateScrollArea(parent, width, height)
end

function Widgets:CreateDivider(parent, length, vertical)
    local line = parent:CreateTexture(nil, "ARTWORK")
    SetTexColor(line, Token("border"))
    if line.SetAlpha then
        line:SetAlpha(0.35)
    end
    if vertical then
        line:SetSize(1, length or 200)
    else
        line:SetSize(length or 200, 1)
    end
    return line
end

function Widgets:CreateSearchBox(parent, width, placeholder, onChange)
    local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    box:SetSize(width or 160, 22)
    box:SetAutoFocus(false)
    SetTextColor(box, Token("textPrimary"))
    box:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    box:SetScript("OnTextChanged", function(self)
        if onChange then
            onChange(self:GetText() or "")
        end
    end)
    if placeholder then
        box.placeholder = self:CreateMutedFontString(parent)
        box.placeholder:SetPoint("LEFT", box, "LEFT", 6, 0)
        box.placeholder:SetText(placeholder)
        box:SetScript("OnEditFocusGained", function()
            box.placeholder:Hide()
        end)
        box:SetScript("OnEditFocusLost", function(self)
            if self:GetText() == "" then
                box.placeholder:Show()
            end
        end)
    end
    return box
end

function Widgets:CreateListRow(parent, width, height)
    local row = CreateFrame("Button", nil, parent)
    row:SetSize(width, height or 38)
    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetPoint("TOPLEFT", 6, -1)
    row.bg:SetPoint("BOTTOMRIGHT", -2, 1)
    SetTexColor(row.bg, 0, 0, 0, 0)
    row.selBar = row:CreateTexture(nil, "ARTWORK", nil, 1)
    row.selBar:SetWidth(2)
    row.selBar:SetPoint("TOPLEFT", 4, -2)
    row.selBar:SetPoint("BOTTOMLEFT", 4, 2)
    SetTexColor(row.selBar, Token("phosphor"))
    if row.selBar.SetAlpha then
        row.selBar:SetAlpha(0)
    end
    row.title = self:CreateSectionFontString(row)
    row.title:SetFont(row.title:GetFont(), 12)
    row.title:SetPoint("TOPLEFT", 14, -6)
    row.subtitle = self:CreateMutedFontString(row)
    row.subtitle:SetPoint("TOPLEFT", 14, -22)
    row.subtitle:SetWidth(width - 28)
    row.subtitle:SetJustifyH("LEFT")
    row.badge = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.badge:SetPoint("TOPRIGHT", -8, -6)
    SetTextColor(row.badge, Token("textMuted"))
    row.unreadMark = row:CreateTexture(nil, "OVERLAY")
    row.unreadMark:SetPoint("LEFT", 4, 0)
    self:ApplyDiamondTexture(row.unreadMark, 5, "gold")
    row.unreadMark:Hide()
    return row
end

function Widgets:SetListRowSelected(row, selected)
    row.selected = selected
    if selected then
        SetTexColor(row.bg, Token("bgSurface"))
        SetTexColor(row.selBar, Token("phosphor"))
        if row.selBar.SetAlpha then
            row.selBar:SetAlpha(0.9)
        end
        SetTextColor(row.title, Token("gold"))
    else
        SetTexColor(row.bg, 0, 0, 0, 0)
        SetTexColor(row.selBar, Token("phosphor"))
        if row.selBar.SetAlpha then
            row.selBar:SetAlpha(0)
        end
        SetTextColor(row.title, Token("textPrimary"))
    end
end

function Widgets:StatusColor(status)
    return self.STATUS_COLORS[status] or self.STATUS_COLORS.new
end

function Widgets:StatusBadgeText(status)
    local label = self:StatusLabel(status)
    local c = self:StatusColor(status)
    return string.format("|cff%02x%02x%02x%s|r", math.floor(c[1] * 255), math.floor(c[2] * 255), math.floor(c[3] * 255), label)
end

function Widgets:ChannelIcon(channel)
    if channel == "WHISPER" or channel == "whisper" or channel == "test-whisper" then
        return "|TInterface\\ChatFrame\\UI-ChatIcon-Whisper:14:14|t"
    elseif channel == "guild" or channel == "GUILD" then
        return "|TInterface\\ChatFrame\\UI-ChatIcon-Guild:14:14|t"
    elseif channel == "test" then
        return "|TInterface\\Buttons\\UI-GuildButton-PublicNote-Up:14:14|t"
    end
    return "|TInterface\\ChatFrame\\UI-ChatIcon-Chat:14:14|t"
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

function Widgets:OpenWhisper(fullName)
    if not fullName or fullName == "" then
        return
    end
    local editBox = ChatEdit_ChooseBoxForSend and ChatEdit_ChooseBoxForSend()
    if editBox then
        ChatEdit_ActivateChat(editBox)
        editBox:SetText("/w " .. fullName .. " ")
    end
end

function Widgets:CopyToClipboard(text)
    if not text or text == "" then
        return false
    end
    if C_ChatInfo and C_ChatInfo.CopyChatLine then
        C_ChatInfo.CopyChatLine(text)
        return true
    end
    return false
end

function Widgets:Truncate(text, maxLen)
    if not text then
        return ""
    end
    if #text <= maxLen then
        return text
    end
    return text:sub(1, maxLen - 3) .. "..."
end

Widgets.ApplyDialogBackdrop = Widgets.ApplyWindowChrome
