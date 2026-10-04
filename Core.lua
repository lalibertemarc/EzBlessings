-- PallyBuff: recommends the Paladin blessing your friendly target needs.
local _, ns = ...

if select(2, UnitClass("player")) ~= "PALADIN" then return end

---------------------------------------------------------------------------
-- API compat (old classic globals vs. modern C_ namespaces)
---------------------------------------------------------------------------
local function SpellInfo(id)
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(id)
        if info then return info.name, info.iconID end
    elseif GetSpellInfo then
        local name, _, icon = GetSpellInfo(id)
        return name, icon
    end
end

local function SpellBookName(i)
    if C_SpellBook and C_SpellBook.GetSpellBookItemName then
        local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player or 0
        return (C_SpellBook.GetSpellBookItemName(i, bank))
    end
    return (GetSpellBookItemName(i, BOOKTYPE_SPELL or "spell"))
end

-- Returns name, sourceUnit, expirationTime of the i-th buff, or nil past the end.
local function BuffAt(unit, i)
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        local a = C_UnitAuras.GetAuraDataByIndex(unit, i, "HELPFUL")
        if a then return a.name, a.sourceUnit, a.expirationTime end
    else
        local name, _, _, _, _, expires, source = UnitBuff(unit, i)
        return name, source, expires
    end
end

---------------------------------------------------------------------------
-- Spell data
---------------------------------------------------------------------------
local blessing = {}   -- key -> { name, short, greater, icon }
local nameToKey = {}  -- localized buff name (normal or greater) -> key
local known = {}      -- localized spell name -> true

-- Whole words shared by every blessing name ("Blessing of ", "Bénédiction de ", ...).
local function SharedPrefix()
    local prefix
    for _, b in pairs(blessing) do
        if not prefix then
            prefix = b.name
        else
            local i = 1
            while i <= #prefix and prefix:byte(i) == b.name:byte(i) do i = i + 1 end
            prefix = prefix:sub(1, i - 1)
        end
    end
    return prefix and prefix:match("^(.* )") or ""
end

local function RefreshSpells()
    wipe(nameToKey)
    for key, ids in pairs(ns.BLESSINGS) do
        local name, icon = SpellInfo(ids[1])
        local greater = SpellInfo(ids[2])
        blessing[key] = { name = name or key, greater = greater, icon = icon or 134400 }
        if name then nameToKey[name] = key end
        if greater then nameToKey[greater] = key end
    end

    -- Button label shows only the part that differs ("Might", "Kings") in any client language.
    local prefix = SharedPrefix()
    for _, b in pairs(blessing) do
        b.short = b.name:sub(#prefix + 1)
    end

    wipe(known)
    for i = 1, 1000 do
        local name = SpellBookName(i)
        if not name then break end
        known[name] = true
    end
end

---------------------------------------------------------------------------
-- Evaluation
---------------------------------------------------------------------------
local function UnitKey(unit)
    local name = UnitName(unit)
    return name and name:lower()
end

local function ValidTarget(unit)
    return UnitExists(unit) and UnitIsPlayer(unit) and UnitIsFriend("player", unit)
        and not UnitIsDeadOrGhost(unit)
end

local function ScanBlessings(unit)
    local found, now = {}, GetTime()
    for i = 1, 40 do
        local name, source, expires = BuffAt(unit, i)
        if not name then break end
        local key = nameToKey[name]
        if key then
            found[key] = {
                mine = source ~= nil and UnitIsUnit(source, "player"),
                source = source and UnitName(source),
                remaining = (expires and expires > 0) and (expires - now) or nil,
            }
        end
    end
    return found
end

local function InGroup(unit)
    return UnitIsUnit(unit, "player") or UnitInParty(unit) or UnitInRaid(unit) ~= nil
end

-- Entry states: "missing", "expiring" (yours, about to drop), "mine", "other" (another paladin's),
-- "unknown" (not learned), "nogroup" (group-only blessing, target not in your group).
-- Result: { name, class, className, tank, grouped, list = {entries}, rec = entry to cast or nil, done = bool }
local function Evaluate(unit)
    local className, class = UnitClass(unit)
    local r = { name = UnitName(unit), class = class, className = className, list = {}, done = false }
    r.tank = PallyBuffDB.tanks[UnitKey(unit)] == true
    r.grouped = InGroup(unit)

    local prio = (r.tank and ns.TANK_PRIORITY[class]) or ns.PRIORITY[class] or ns.PRIORITY.WARRIOR
    local found = ScanBlessings(unit)

    for _, key in ipairs(prio) do
        local f = found[key]
        local state
        if f and f.mine then
            state = (f.remaining and f.remaining <= ns.REFRESH_THRESHOLD) and "expiring" or "mine"
        elseif f then
            state = "other"
        elseif not known[blessing[key].name] then
            state = "unknown"
        elseif ns.GROUP_ONLY[key] and not r.grouped then
            state = "nogroup"
        else
            state = "missing"
        end
        local e = { key = key, state = state, source = f and f.source, remaining = f and f.remaining }
        r.list[#r.list + 1] = e

        -- One blessing per paladin per target: the first slot not covered by someone else decides.
        if not r.rec and not r.done and (state == "missing" or state == "expiring" or state == "mine") then
            if state == "mine" then r.done = true else r.rec = e end
        end
    end
    return r
end

---------------------------------------------------------------------------
-- Button
---------------------------------------------------------------------------
local btn = CreateFrame("Button", "PallyBuffButton", UIParent, "SecureActionButtonTemplate")
btn:SetSize(40, 40)
btn:SetFrameStrata("MEDIUM")
btn:SetMovable(true)
btn:SetClampedToScreen(true)
btn:RegisterForDrag("LeftButton")
btn:RegisterForClicks(GetCVarBool("ActionButtonUseKeyDown") and "AnyDown" or "AnyUp")
for _, suffix in ipairs({ "", "2" }) do
    btn:SetAttribute("type" .. suffix, "spell")
    btn:SetAttribute("unit" .. suffix, "target")
end
btn:SetAlpha(0)
btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

btn.border = btn:CreateTexture(nil, "BACKGROUND")
btn.border:SetPoint("TOPLEFT", -2, 2)
btn.border:SetPoint("BOTTOMRIGHT", 2, -2)

btn.icon = btn:CreateTexture(nil, "ARTWORK")
btn.icon:SetAllPoints()
btn.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

btn.check = btn:CreateTexture(nil, "OVERLAY")
btn.check:SetSize(22, 22)
btn.check:SetPoint("BOTTOMRIGHT", 4, -4)
btn.check:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")

btn.label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
btn.label:SetPoint("TOP", btn, "BOTTOM", 0, -3)

local BORDER = {
    normal   = { 0, 0, 0 },
    expiring = { 1, 0.8, 0 },
    stale    = { 0.8, 0.1, 0.1 },
}

local function ApplyPosition()
    local p = PallyBuffDB.pos
    btn:ClearAllPoints()
    if p then
        btn:SetPoint(p[1], UIParent, p[2], p[3], p[4])
    else
        btn:SetPoint("LEFT", TargetFrame, "RIGHT", -10, 10)
    end
end

btn:SetScript("OnDragStart", function(self)
    if InCombatLockdown() or (PallyBuffDB.locked and not IsShiftKeyDown()) then return end
    self:StartMoving()
end)
btn:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relPoint, x, y = self:GetPoint()
    PallyBuffDB.pos = { point, relPoint, x, y }
end)

---------------------------------------------------------------------------
-- Tooltip
---------------------------------------------------------------------------
local STATE_TEXT = {
    missing  = "|cffff4040missing|r",
    expiring = "|cffffd000yours, expiring|r",
    mine     = "|cff40ff40yours|r",
    other    = "|cff40ff40from %s|r",
    unknown  = "|cff808080not learned|r",
    nogroup  = "|cff808080group only|r",
}

local function FormatTime(sec)
    if not sec then return "" end
    return sec >= 60 and format(" (%dm)", floor(sec / 60)) or format(" (%ds)", floor(sec))
end

local current -- last Evaluate() result for the target, nil when no valid target

local function ShowTooltip()
    if not current then return GameTooltip:Hide() end
    local c = RAID_CLASS_COLORS[current.class] or NORMAL_FONT_COLOR
    GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
    GameTooltip:AddLine(current.name, c.r, c.g, c.b)
    GameTooltip:AddLine(format("%s - %s", current.className or "?", current.tank and "Tank" or "DPS/Healer"), 0.8, 0.8, 0.8)
    GameTooltip:AddLine(" ")
    for i, e in ipairs(current.list) do
        local text = format(STATE_TEXT[e.state], e.source or "another paladin") .. FormatTime(e.remaining)
        GameTooltip:AddDoubleLine(format("%d. %s", i, blessing[e.key].name), text, 1, 1, 1)
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Left-click: cast blessing   Right-click: Greater", 0.6, 0.6, 0.6)
    GameTooltip:AddLine(PallyBuffDB.locked and "Shift-drag to move" or "Drag to move", 0.6, 0.6, 0.6)
    GameTooltip:Show()
end

btn:SetScript("OnEnter", function(self) self.hover = true; ShowTooltip() end)
btn:SetScript("OnLeave", function(self) self.hover = false; GameTooltip:Hide() end)

---------------------------------------------------------------------------
-- Update
---------------------------------------------------------------------------
local function Update()
    local inCombat = InCombatLockdown()
    current = ValidTarget("target") and Evaluate("target") or nil

    if not current then
        btn:SetAlpha(0)
        if not inCombat then btn:EnableMouse(false) end
    else
        local rec = current.rec
        local b = rec and blessing[rec.key]
        local spell = b and b.name
        -- Greater blessings only reach party/raid members.
        local greater = b and current.grouped and known[b.greater] and b.greater

        -- Secure attributes can't change in combat; the button keeps its old spell until combat ends.
        if not inCombat then
            btn:EnableMouse(true)
            btn:SetAttribute("spell", spell)
            btn:SetAttribute("spell2", greater or spell)
        end
        local stale = inCombat and btn:GetAttribute("spell") ~= spell

        btn:SetAlpha(1)
        btn.check:SetShown(current.done)
        btn.icon:SetTexture(b and b.icon or blessing.KINGS.icon)
        btn.icon:SetDesaturated(not b or stale)
        if b then
            btn.label:SetText(b.short)
        else
            btn.label:SetText(current.done and "|cff40ff40Done|r" or "|cff808080Nothing|r")
        end
        btn.border:SetColorTexture(unpack(BORDER[stale and "stale" or (rec and rec.state == "expiring") and "expiring" or "normal"]))
    end

    if btn.hover then ShowTooltip() end
end

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------
local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cfff58cbaPallyBuff|r: " .. msg)
end

local function SetTank(arg, value, verb)
    local name = (arg ~= "" and arg:lower()) or (UnitIsPlayer("target") and UnitKey("target"))
    if not name then return Print("give a name or target a player") end
    PallyBuffDB.tanks[name] = value
    Print(name .. " " .. verb)
end

local HELP = {
    "/pb tank [name] - mark player (or target) as tank",
    "/pb untank [name] - unmark tank",
    "/pb tanks - list tanks",
    "/pb lock | unlock - lock button position (shift-drag always moves)",
    "/pb reset - reset button position",
}

local COMMANDS = {
    tank   = function(arg) SetTank(arg, true, "marked as tank.") end,
    untank = function(arg) SetTank(arg, nil, "is no longer a tank.") end,
    tanks  = function()
        local names = {}
        for name in pairs(PallyBuffDB.tanks) do names[#names + 1] = name end
        table.sort(names)
        Print("Tanks: " .. (#names > 0 and table.concat(names, ", ") or "none"))
    end,
    lock   = function() PallyBuffDB.locked = true; Print("Locked.") end,
    unlock = function() PallyBuffDB.locked = false; Print("Unlocked.") end,
    reset  = function()
        if InCombatLockdown() then return Print("Can't move in combat.") end
        PallyBuffDB.pos = nil
        ApplyPosition()
        Print("Position reset.")
    end,
}

SLASH_PALLYBUFF1 = "/pb"
SLASH_PALLYBUFF2 = "/pallybuff"
SlashCmdList.PALLYBUFF = function(msg)
    local cmd, arg = msg:match("^(%S*)%s*(.-)%s*$")
    local fn = COMMANDS[cmd:lower()]
    if fn then
        fn(arg)
        Update()
    else
        for _, line in ipairs(HELP) do Print(line) end
    end
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function(self, event, unit)
    if event == "UNIT_AURA" and unit ~= "target" then return end
    if event == "PLAYER_LOGIN" then
        -- Saved variables are loaded by now; only start listening once they exist.
        PallyBuffDB = PallyBuffDB or {}
        PallyBuffDB.tanks = PallyBuffDB.tanks or {}
        if PallyBuffDB.locked == nil then PallyBuffDB.locked = true end
        ApplyPosition()
        for _, e in ipairs({ "PLAYER_TARGET_CHANGED", "UNIT_AURA", "SPELLS_CHANGED", "PLAYER_REGEN_ENABLED" }) do
            self:RegisterEvent(e)
        end
        C_Timer.NewTicker(1, Update)
    end
    if event == "PLAYER_LOGIN" or event == "SPELLS_CHANGED" then
        RefreshSpells()
    end
    Update()
end)
