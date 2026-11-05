-- Options page: Esc > Options > AddOns > EzBlessings, or /ezb. Built at login, once the saved variables exist.
-- The main page is Blizzard's settings list, as in our other addons; your own lines get a subpage of their own
-- widgets (a list can't live in the settings list). No inline binding rows or search tags: they taint the options
-- search in Forever.
local _, ns = ...

local ROW_HEIGHT, VISIBLE_ROWS = 22, 8
local LIST_WIDTH = 560

-- EzBlessingsDB.announce: nil = off.
local ANNOUNCE_OFF = "off"

-- "Your lines" subpage: add box, the list with Remove buttons, and a sample line.
local function BuildLinesPage(parent)
    local panel = CreateFrame("Frame")
    local category = Settings.RegisterCanvasLayoutSubcategory(parent, panel, "Your lines")

    local function Label(font, text, width)
        local fs = panel:CreateFontString(nil, "ARTWORK", font)
        fs:SetJustifyH("LEFT")
        if width then fs:SetWidth(width) end
        fs:SetText(text)
        return fs
    end

    local function Button(text, width, onClick, owner)
        local b = CreateFrame("Button", nil, owner or panel, "UIPanelButtonTemplate")
        b:SetSize(width, 22)
        b:SetText(text)
        b:SetScript("OnClick", onClick)
        return b
    end

    local title = Label("GameFontNormalHuge", "Your lines")
    title:SetPoint("TOPLEFT", 16, -16)
    local help = Label("GameFontHighlightSmall",
        "Each announce picks one line at random from the built-in ones and yours (or yours alone, with "
        .. "\"Use only my lines\" on the main page). %t = your target's full name, %b = the blessing you cast. "
        .. "Your accent respells them as they go out.", LIST_WIDTH)
    help:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)

    local input = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    input:SetSize(LIST_WIDTH - 80, 22)
    input:SetPoint("TOPLEFT", help, "BOTTOMLEFT", 6, -14)
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

    local example = Label("GameFontHighlightSmall", "", LIST_WIDTH - 100)
    local try = Button("Try a line", 90, function() example:SetText(ns.Example()) end)
    try:SetPoint("TOPLEFT", box, "BOTTOMLEFT", 0, -8)
    example:SetPoint("LEFT", try, "RIGHT", 10, 0)

    -- Run on show, so lines added with /ezb message are picked up.
    panel:SetScript("OnShow", function()
        RefreshList()
        example:SetText("")
    end)
    return category
end

function ns.BuildSettings()
    local category, layout = Settings.RegisterVerticalLayoutCategory("EzBlessings")
    ns.settingsCategory = category

    local function Header(text)
        layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(text))
    end

    local function Button(name, text, onClick, tooltip)
        layout:AddInitializer(CreateSettingsButtonInitializer(name, text, onClick, tooltip, false))
    end

    local function Choices(list)
        return function()
            local container = Settings.CreateControlTextContainer()
            for _, o in ipairs(list) do container:Add(o.key, o.label, o.desc) end
            return container:GetData()
        end
    end

    -- A checkbox on a key of tbl; the button follows at once.
    local function Check(tbl, key, name, default, tooltip)
        local setting = Settings.RegisterAddOnSetting(category, "EZBLESSINGS_" .. key:upper(), key, tbl,
            Settings.VarType.Boolean, name, default)
        setting:SetValueChangedCallback(function() ns.Update() end)
        Settings.CreateCheckbox(category, setting, tooltip)
    end

    Header("Announce")
    -- nil means off in the saved variables, so this one goes through a proxy.
    local announce = Settings.RegisterProxySetting(category, "EZBLESSINGS_ANNOUNCE", Settings.VarType.String,
        "Announce", ANNOUNCE_OFF,
        function() return EzBlessingsDB.announce or ANNOUNCE_OFF end,
        function(value) EzBlessingsDB.announce = value ~= ANNOUNCE_OFF and value or nil end)
    Settings.CreateDropdown(category, announce, Choices({
        { key = ANNOUNCE_OFF, label = "Off", desc = "Blessings are cast in silence." },
        { key = "say", label = "/say", desc = "Everyone nearby hears you bless your target." },
        { key = "whisper", label = "Whisper", desc = "Only your target hears you." },
    }), "Say a line to your target when you bless them with the EzBlessings button or its keys. Shared by all your characters.")
    Check(EzBlessingsDB, "onlyMine", "Use only my lines", false,
        "Leave out the built-in lines. While you have no lines of your own, the built-in ones are still used.")
    local lines = BuildLinesPage(category)
    Button("Your lines", "Edit",
        function() Settings.OpenToCategory(lines:GetID()) end,
        "Add or remove lines of your own, mixed in with the built-in ones. Also under EzBlessings in the list on the left.")

    Header("Your character")
    -- Per character: each of your paladins can have a voice of their own.
    local accent = Settings.RegisterAddOnSetting(category, "EZBLESSINGS_ACCENT", "accent", EzBlessingsCharDB,
        Settings.VarType.String, "Accent", ns.DEFAULT_ACCENT)
    Settings.CreateDropdown(category, accent, Choices(ns.ACCENTS),
        "The accent this character's lines are said in, heard on the next one. Each character has their own.")
    local thick = Settings.RegisterAddOnSetting(category, "EZBLESSINGS_THICK", "thick", EzBlessingsCharDB,
        Settings.VarType.Boolean, "Thick accent", false)
    Settings.CreateCheckbox(category, thick, "A thicker accent. For the undead: no jaw at all.")
    Button("Sample lines", "Preview", function() ns.Preview() end,
        "Prints a few lines in this accent to your chat, to your target if you have one. Only you see them.")

    Header("Button")
    Check(EzBlessingsDB, "locked", "Lock position", true, "Shift-drag always moves the button.")
    -- Only Forever hides buffs in instances; Classic Era gets no checkbox.
    if not ns.ERA then
        Check(EzBlessingsDB, "hideInInstances", "Hide in dungeons and raids", true,
            "The game hides buffs from addons there, so the button can't tell what's missing.")
    end
    Check(EzBlessingsDB, "skipUnworthy", "Withhold blessings from the unworthy", false,
        "Players whose guild name contains \"Olympus\" get nothing. With OlympusMute installed, its lists are used.")
    Button("Position", "Reset", function() ns.ResetPosition() end, "Put the button back beside the target frame.")
    Button("Key bindings", "Key Bindings",
        function() Settings.OpenToCategory(Settings.KEYBINDINGS_CATEGORY_ID, "EzBlessings") end,
        "Bind the blessing keys in the EzBlessings section of the Key Bindings page.")

    Settings.RegisterAddOnCategory(category)
end

function ns.OpenSettings()
    if not ns.settingsCategory then return end
    Settings.OpenToCategory(ns.settingsCategory:GetID())
end
