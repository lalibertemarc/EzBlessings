-- Options page: Esc > Options > AddOns > EzBlessings, or /ezb. Built at login, paladins only.
-- A canvas page with its own widgets: no Blizzard dropdown menus (they crash in combat on Forever)
-- and no search tags (they taint the options search).
local _, ns = ...

local ROW_HEIGHT, VISIBLE_ROWS = 22, 5
local LIST_WIDTH = 520

local ANNOUNCE_CHOICES = {
    { value = nil, label = "Off" },
    { value = "say", label = "Say (/s)" },
    { value = "whisper", label = "Whisper the target" },
}

function ns.BuildSettings()
    local panel = CreateFrame("Frame")
    local category = Settings.RegisterCanvasLayoutCategory(panel, "EzBlessings")
    Settings.RegisterAddOnCategory(category)
    ns.settingsCategory = category

    local refreshers = {} -- run on show, so changes made with slash commands are picked up

    local function Label(font, text, width)
        local fs = panel:CreateFontString(nil, "ARTWORK", font)
        fs:SetJustifyH("LEFT")
        if width then fs:SetWidth(width) end
        fs:SetText(text)
        return fs
    end

    local function Button(text, width, onClick, parent)
        local b = CreateFrame("Button", nil, parent or panel, "UIPanelButtonTemplate")
        b:SetSize(width, 22)
        b:SetText(text)
        b:SetScript("OnClick", onClick)
        return b
    end

    local function Check(text, tooltip, get, set)
        local check = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        check:SetSize(26, 26)
        check.Text:SetFontObject(GameFontHighlight)
        check.Text:SetText(text)
        check:SetScript("OnClick", function(self)
            set(self:GetChecked())
            ns.Update()
        end)
        if tooltip then
            check:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(text, 1, 1, 1)
                GameTooltip:AddLine(tooltip, nil, nil, nil, true)
                GameTooltip:Show()
            end)
            check:SetScript("OnLeave", function() GameTooltip:Hide() end)
        end
        refreshers[#refreshers + 1] = function() check:SetChecked(get() and true or false) end
        return check
    end

    -- Header -----------------------------------------------------------------
    local title = Label("GameFontNormalHuge", "EzBlessings")
    title:SetPoint("TOPLEFT", 16, -16)
    local subtitle = Label("GameFontHighlightSmall", "Shows which blessing your friendly target needs. None go unblessed.")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)

    -- Announce ---------------------------------------------------------------
    local announceHeader = Label("GameFontHighlightLarge", "Announce")
    announceHeader:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -20)
    local announceHelp = Label("GameFontHighlightSmall",
        "Say a line to your target when you bless them with the EzBlessings button or its key bindings. "
        .. "Each time, one line is picked at random from the built-in ones and yours.", LIST_WIDTH + 30)
    announceHelp:SetPoint("TOPLEFT", announceHeader, "BOTTOMLEFT", 0, -6)

    local radios = {}
    for i, choice in ipairs(ANNOUNCE_CHOICES) do
        local radio = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        radio:SetSize(26, 26)
        radio.Text:SetFontObject(GameFontHighlight)
        radio.Text:SetText(choice.label)
        if i == 1 then
            radio:SetPoint("TOPLEFT", announceHelp, "BOTTOMLEFT", -4, -8)
        else
            radio:SetPoint("LEFT", radios[i - 1].Text, "RIGHT", 24, 0)
        end
        radio:SetScript("OnClick", function()
            EzBlessingsDB.announce = choice.value
            for j, r in ipairs(radios) do r:SetChecked(ANNOUNCE_CHOICES[j].value == choice.value) end
            ns.Update()
        end)
        radios[i] = radio
    end
    refreshers[#refreshers + 1] = function()
        for j, r in ipairs(radios) do r:SetChecked(ANNOUNCE_CHOICES[j].value == EzBlessingsDB.announce) end
    end

    local onlyMine = Check("Use only my lines",
        "Leave out the built-in lines. While you have no lines of your own, the built-in ones are still used.",
        function() return EzBlessingsDB.onlyMine end,
        function(on) EzBlessingsDB.onlyMine = on or nil end)
    onlyMine:SetPoint("TOPLEFT", radios[1], "BOTTOMLEFT", 0, -2)

    -- Your lines -------------------------------------------------------------
    local linesLabel = Label("GameFontNormal", "Your lines")
    linesLabel:SetPoint("TOPLEFT", onlyMine, "BOTTOMLEFT", 4, -12)
    local tokens = Label("GameFontDisableSmall", "%t = your target's name, %b = the blessing you cast")
    tokens:SetPoint("LEFT", linesLabel, "RIGHT", 10, 0)

    local input = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    input:SetSize(LIST_WIDTH - 80, 22)
    input:SetPoint("TOPLEFT", linesLabel, "BOTTOMLEFT", 6, -6)
    input:SetAutoFocus(false)
    input:SetMaxLetters(255)
    local placeholder = input:CreateFontString(nil, "ARTWORK", "GameFontDisable")
    placeholder:SetPoint("LEFT", 2, 0)
    placeholder:SetText("e.g. %t, the Light is with you! I grant you %b.")
    -- Only toggles the hint, so it's fine that this also runs on the first show without typing.
    input:SetScript("OnTextChanged", function(self) placeholder:SetShown(self:GetText() == "") end)

    local RefreshList
    local function AddFromInput()
        if ns.AddLine(input:GetText()) then
            input:SetText("")
            input:ClearFocus()
            RefreshList()
        end
    end
    input:SetScript("OnEnterPressed", AddFromInput)
    input:SetScript("OnEscapePressed", input.ClearFocus)
    local add = Button("Add", 70, AddFromInput)
    add:SetPoint("LEFT", input, "RIGHT", 8, 0)

    local box = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    box:SetSize(LIST_WIDTH, ROW_HEIGHT * VISIBLE_ROWS + 10)
    box:SetPoint("TOPLEFT", input, "BOTTOMLEFT", -6, -8)
    box:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    box:SetBackdropColor(0, 0, 0, 0.5)
    box:SetBackdropBorderColor(0.6, 0.6, 0.6)

    local scroll = CreateFrame("ScrollFrame", nil, box, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 5, -5)
    scroll:SetPoint("BOTTOMRIGHT", -27, 5)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(LIST_WIDTH - 32, 1)
    scroll:SetScrollChild(content)

    local empty = box:CreateFontString(nil, "ARTWORK", "GameFontDisable")
    empty:SetPoint("CENTER")
    empty:SetText("No lines of your own yet. Type one above and click Add.")

    local rows = {}
    local function Row(i)
        if rows[i] then return rows[i] end
        local row = CreateFrame("Frame", nil, content)
        row:SetSize(LIST_WIDTH - 32, ROW_HEIGHT)
        row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)
        row:EnableMouse(true)
        row.text = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        row.text:SetPoint("LEFT", 4, 0)
        row.text:SetPoint("RIGHT", -72, 0)
        row.text:SetJustifyH("LEFT")
        row.text:SetWordWrap(false)
        row.remove = Button("Remove", 66, function()
            ns.RemoveLine(row.index)
            RefreshList()
        end, row)
        row.remove:SetHeight(20)
        row.remove:SetPoint("RIGHT", -2, 0)
        -- Long lines are cut off in the list: show them whole on hover.
        row:SetScript("OnEnter", function(self)
            if not self.text:IsTruncated() then return end
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(self.line, 1, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
        rows[i] = row
        return row
    end

    RefreshList = function()
        local mine = EzBlessingsDB.messages
        for i, line in ipairs(mine) do
            local row = Row(i)
            row.index, row.line = i, line
            row.text:SetText(i .. ". " .. line)
            row:Show()
        end
        for i = #mine + 1, #rows do rows[i]:Hide() end
        content:SetHeight(math.max(1, #mine * ROW_HEIGHT))
        empty:SetShown(#mine == 0)
    end
    refreshers[#refreshers + 1] = RefreshList

    local example = Label("GameFontHighlightSmall", "", LIST_WIDTH - 100)
    local try = Button("Try a line", 90, function() example:SetText(ns.Example()) end)
    try:SetPoint("TOPLEFT", box, "BOTTOMLEFT", 0, -8)
    example:SetPoint("LEFT", try, "RIGHT", 10, 0)
    refreshers[#refreshers + 1] = function() example:SetText("") end

    -- Button -----------------------------------------------------------------
    local buttonHeader = Label("GameFontHighlightLarge", "Button")
    buttonHeader:SetPoint("TOPLEFT", try, "BOTTOMLEFT", 0, -22)

    local lock = Check("Lock position", "Shift-drag still moves the button.",
        function() return EzBlessingsDB.locked end,
        function(on) EzBlessingsDB.locked = on end)
    lock:SetPoint("TOPLEFT", buttonHeader, "BOTTOMLEFT", -4, -6)

    local instances = Check("Hide in dungeons and raids",
        "The game hides buffs from addons there, so the button can't tell what's missing.",
        function() return EzBlessingsDB.hideInInstances end,
        function(on) EzBlessingsDB.hideInInstances = on end)
    instances:SetPoint("TOPLEFT", lock, "BOTTOMLEFT", 0, -2)

    local olympus = Check("Withhold blessings from the unworthy",
        "Players whose guild name contains \"Olympus\" get nothing. With OlympusMute installed, its lists are used.",
        function() return EzBlessingsDB.skipUnworthy end,
        function(on) EzBlessingsDB.skipUnworthy = on end)
    olympus:SetPoint("TOPLEFT", instances, "BOTTOMLEFT", 0, -2)

    local reset = Button("Reset position", 120, ns.ResetPosition)
    reset:SetPoint("TOPLEFT", olympus, "BOTTOMLEFT", 4, -10)
    -- A link instead of binding rows on this page: those taint the options search.
    local bindings = Button("Key Bindings", 120, function()
        Settings.OpenToCategory(Settings.KEYBINDINGS_CATEGORY_ID, "EzBlessings")
    end)
    bindings:SetPoint("LEFT", reset, "RIGHT", 8, 0)

    panel:SetScript("OnShow", function()
        for _, refresh in ipairs(refreshers) do refresh() end
    end)
end

function ns.OpenSettings()
    if not ns.settingsCategory then return end
    Settings.OpenToCategory(ns.settingsCategory:GetID())
end
