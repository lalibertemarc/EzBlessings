-- EzBlessings: recommends the Paladin blessing your friendly target needs.
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

local function SpellSubtext(id)
    if C_Spell and C_Spell.GetSpellSubtext then return C_Spell.GetSpellSubtext(id) end
    return GetSpellSubtext and GetSpellSubtext(id)
end

local function IsKnown(id)
    if C_SpellBook and C_SpellBook.IsSpellKnown then return C_SpellBook.IsSpellKnown(id) end
    return IsSpellKnown(id)
end

-- "Name(Rank N)" makes the secure button cast that exact rank instead of the highest one.
local function CastName(id)
    local name = SpellInfo(id)
    local rank = SpellSubtext(id)
    return (rank and rank ~= "") and format("%s(%s)", name, rank) or name
end

-- Forever's client hides aura data from addons in some situations (e.g. combat) as "secret" values.
local issecret = issecretvalue or function() return false end

-- true / false, or nil when range doesn't apply or can't be read.
local function InRange(id, unit)
    local r
    if C_Spell and C_Spell.IsSpellInRange then
        r = C_Spell.IsSpellInRange(id, unit)
    elseif IsSpellInRange then
        r = IsSpellInRange(SpellInfo(id), unit) -- 1, 0 or nil
    end
    if r == nil or issecret(r) then return nil end
    return r == true or r == 1
end

local function AurasHidden()
    return C_Secrets and C_Secrets.ShouldAurasBeSecret and C_Secrets.ShouldAurasBeSecret()
end

-- Returns name, sourceUnit, expirationTime of the i-th buff; nil past the end; false if auras are hidden.
local function BuffAt(unit, i)
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        -- Index access throws while auras are secret, so never call it bare.
        local ok, a = pcall(C_UnitAuras.GetAuraDataByIndex, unit, i, "HELPFUL")
        if not ok or issecret(a) then return false end
        if a then return a.name, a.sourceUnit, a.expirationTime end
    else
        local name, _, _, _, _, expires, source = UnitBuff(unit, i)
        return name, source, expires
    end
end

---------------------------------------------------------------------------
-- Spell data
---------------------------------------------------------------------------
local blessing = ns.BLESSINGS -- key -> { ranks, greater } from Data.lua, plus name, short, icon added below
local nameToKey = {}          -- localized buff name (normal or greater) -> key

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
    for key, b in pairs(blessing) do
        local name, icon = SpellInfo(b.ranks[1][1])
        local greaterName = SpellInfo(b.greater[1][1])
        b.name, b.icon = name or key, icon or 134400
        if name then nameToKey[name] = key end
        if greaterName then nameToKey[greaterName] = key end
    end

    -- Button label shows only the part that differs ("Might", "Kings") in any client language.
    local prefix = SharedPrefix()
    for _, b in pairs(blessing) do
        b.short = b.name:sub(#prefix + 1)
    end
end

-- Highest known rank castable on a target of this level (nil if none); second value: any rank known at all.
local function BestRank(ranks, level)
    local best, anyKnown = nil, false
    for _, r in ipairs(ranks) do
        if IsKnown(r[1]) then
            anyKnown = true
            if r[2] - ns.RANK_LEVEL_GAP <= level then best = r[1] end
        end
    end
    return best, anyKnown
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

-- Returns key -> { mine, source, remaining } for blessings on the unit, or nil if auras are hidden.
local function ScanBlessings(unit)
    if AurasHidden() then return nil end
    local found, now = {}, GetTime()
    for i = 1, 40 do
        local name, source, expires = BuffAt(unit, i)
        if name == false then return nil end
        if not name then break end
        local key = not (issecret(name) or issecret(source) or issecret(expires)) and nameToKey[name]
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

-- OlympusMute's saved lists, when that addon is loaded, so both addons agree on who's unworthy.
local function MuteLists()
    local om = OlympusMuteDB
    if type(om) ~= "table" then return nil end
    for _, k in ipairs({ "keywords", "guildAllow", "names", "manual", "allow", "guids", "nameWords" }) do
        if type(om[k]) ~= "table" then return nil end
    end
    return om
end

-- Same key OlympusMute uses: "name-realm", lowercase, realm without spaces or hyphens.
local function MuteKey(unit, om)
    local guid = UnitGUID(unit)
    local key = guid and not issecret(guid) and om.guids[guid]
    if type(key) == "string" then return key end
    local full = GetUnitName(unit, true)
    if issecret(full) or type(full) ~= "string" or full == "" then return nil end
    local name, realm = full:match("^([^%-]+)%-(.+)$")
    if not name then
        name, realm = full, (GetNormalizedRealmName and GetNormalizedRealmName()) or GetRealmName() or ""
    end
    return (name .. "-" .. realm:gsub("[%s%-]", "")):lower()
end

-- True if lowercase text contains any of the words (and isn't on the exact-name whitelist).
local function ContainsAny(text, words, whitelist)
    if whitelist and whitelist[text] then return false end
    for _, w in ipairs(words) do
        if type(w) == "string" and w ~= "" and text:find(w, 1, true) then return true end
    end
    return false
end

-- Why the unit gets no blessing ("<Guild>" or "On your OlympusMute list"), or nil.
-- With OlympusMute: its guild names and guild whitelist, players it learned or you added,
-- its never-mute list and character-name keywords. Without it: ns.UNWORTHY_GUILDS.
local function Unworthy(unit)
    if not EzBlessingsDB.skipUnworthy or UnitIsUnit(unit, "player") then return nil end
    local guild = GetGuildInfo(unit)
    if issecret(guild) or type(guild) ~= "string" or guild == "" then guild = nil end
    local om = MuteLists()
    local key = om and MuteKey(unit, om)
    if key and om.allow[key] then return nil end
    -- Guild info can take a moment to load after targeting: fall back to the guild OlympusMute saw.
    if not guild and key and not om.manual[key] and type(om.names[key]) == "string" then guild = om.names[key] end
    if guild and ContainsAny(guild:lower(), om and om.keywords or ns.UNWORTHY_GUILDS, om and om.guildAllow) then
        return "<" .. guild .. ">"
    end
    if key and (om.manual[key] or ContainsAny(key:match("^[^%-]+"), om.nameWords)) then
        return "On your OlympusMute list"
    end
end

local function InGroup(unit)
    return UnitIsUnit(unit, "player") or UnitInParty(unit) or UnitInRaid(unit) ~= nil
end

-- Entry states: "missing", "expiring" (yours, about to drop), "mine", "other" (another paladin's),
-- "unknown" (not learned), "lowlevel" (no rank you know fits the target's level),
-- "nogroup" (group-only blessing, target not in your group).
-- Entry: { key, state, spellId (rank to cast), source, remaining }
-- Result: { name, class, className, tank, grouped, hidden, unworthy, list = {entries}, done = bool,
--           rec = entry to cast or nil, spell / greater = button cast strings for rec, refresh = bool }
-- hidden = auras couldn't be read, so the result is class priority only.
-- unworthy = why the target gets no blessing (see Unworthy); nothing is recommended.
-- refresh = every slot is covered by other paladins, so rec recasts the most wanted of theirs.
local function Evaluate(unit)
    local className, class = UnitClass(unit)
    local r = { name = UnitName(unit), class = class, className = className, list = {}, done = false }
    r.tank = EzBlessingsDB.tanks[UnitKey(unit)] == true
    r.grouped = InGroup(unit)
    r.unworthy = Unworthy(unit)
    local level = UnitLevel(unit)
    level = (level and level > 0) and level or math.huge -- -1 means far above you

    local prio = (r.tank and ns.TANK_PRIORITY[class]) or ns.PRIORITY[class] or ns.PRIORITY.WARRIOR
    local found = ScanBlessings(unit)
    r.hidden = found == nil
    found = found or {}

    for _, key in ipairs(prio) do
        local f = found[key]
        local spellId, anyKnown = BestRank(blessing[key].ranks, level)
        local state
        if f and f.mine then
            state = (spellId and f.remaining and f.remaining <= ns.REFRESH_THRESHOLD) and "expiring" or "mine"
        elseif f then
            state = "other"
        elseif not anyKnown then
            state = "unknown"
        elseif not spellId then
            state = "lowlevel"
        elseif ns.GROUP_ONLY[key] and not r.grouped then
            state = "nogroup"
        else
            state = "missing"
        end
        local e = { key = key, state = state, spellId = spellId, source = f and f.source, remaining = f and f.remaining }
        r.list[#r.list + 1] = e

        -- One blessing per paladin per target: the first slot not covered by someone else decides.
        if not (r.rec or r.done or r.unworthy) then
            if state == "mine" then
                r.done = true
            elseif state == "missing" or state == "expiring" then
                r.rec = e
            end
        end
    end

    -- Everything is covered by other paladins: refresh the most wanted one you can cast rather than give nothing.
    if not (r.rec or r.done or r.unworthy) then
        for _, e in ipairs(r.list) do
            if e.state == "other" and e.spellId and not (ns.GROUP_ONLY[e.key] and not r.grouped) then
                r.rec, r.refresh = e, true
                break
            end
        end
    end

    if r.rec then
        r.spell = CastName(r.rec.spellId)
        -- Greater blessings only reach party/raid members.
        local greaterId = r.grouped and BestRank(blessing[r.rec.key].greater, level)
        r.greater = greaterId and CastName(greaterId)
    end
    return r
end

---------------------------------------------------------------------------
-- Button
---------------------------------------------------------------------------
local btn = CreateFrame("Button", "EzBlessingsButton", UIParent, "SecureActionButtonTemplate")
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
btn.label:SetPoint("LEFT", btn, "RIGHT", 6, 0)

local BORDER = {
    normal   = { 0, 0, 0 },
    expiring = { 1, 0.8, 0 },
    stale    = { 0.8, 0.1, 0.1 },
}

local function ApplyPosition()
    local p = EzBlessingsDB.pos
    btn:ClearAllPoints()
    if p then
        btn:SetPoint(p[1], UIParent, p[2], p[3], p[4])
    else
        btn:SetPoint("LEFT", TargetFrame, "RIGHT", -10, 10)
    end
end

btn:SetScript("OnDragStart", function(self)
    if InCombatLockdown() or (EzBlessingsDB.locked and not IsShiftKeyDown()) then return end
    self:StartMoving()
end)
btn:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relPoint, x, y = self:GetPoint()
    EzBlessingsDB.pos = { point, relPoint, x, y }
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
    lowlevel = "|cff808080target too low|r",
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
    local role = current.tank and "Tank" or ns.HEALER_CLASSES[current.class] and "DPS/Healer" or "DPS"
    GameTooltip:AddLine(format("%s - %s", current.className or "?", role), 0.8, 0.8, 0.8)
    if not current.tank and ns.TANK_PRIORITY[current.class] then
        GameTooltip:AddLine("Tanking? /ezb tank", 0.6, 0.6, 0.6)
    end
    if current.unworthy then
        GameTooltip:AddLine(current.unworthy .. ": unworthy of the Light.", 1, 0.25, 0.25)
        GameTooltip:AddLine("Toggle with /ezb olympus", 0.6, 0.6, 0.6)
    end
    if current.hidden then
        GameTooltip:AddLine("Buffs hidden by the game right now.", 1, 0.5, 0.1)
        GameTooltip:AddLine(current.stale and "Showing what was read before." or "Showing class priority only.", 1, 0.5, 0.1)
    end
    GameTooltip:AddLine(" ")
    for i, e in ipairs(current.list) do
        local text = format(STATE_TEXT[e.state], e.source or "another paladin") .. FormatTime(e.remaining)
        GameTooltip:AddDoubleLine(format("%d. %s", i, blessing[e.key].name), text, 1, 1, 1)
    end
    GameTooltip:AddLine(" ")
    if current.spell then
        GameTooltip:AddLine("Casts " .. current.spell, 1, 0.82, 0)
    end
    if current.refresh then
        GameTooltip:AddLine(format("All covered: refreshes %s's blessing.", current.rec.source or "another paladin"), 0.6, 0.6, 0.6)
    end
    GameTooltip:AddLine("Left-click: cast blessing   Right-click: Greater", 0.6, 0.6, 0.6)
    GameTooltip:AddLine(EzBlessingsDB.locked and "Shift-drag to move" or "Drag to move", 0.6, 0.6, 0.6)
    GameTooltip:Show()
end

btn:SetScript("OnEnter", function(self) self.hover = true; ShowTooltip() end)
btn:SetScript("OnLeave", function(self) self.hover = false; GameTooltip:Hide() end)

---------------------------------------------------------------------------
-- Update
---------------------------------------------------------------------------
-- Forever hides buffs for the whole of a dungeon or raid, so the button can't tell anything useful there.
local function InHiddenInstance()
    if not EzBlessingsDB.hideInInstances then return false end
    local _, kind = IsInInstance()
    return kind == "party" or kind == "raid"
end

-- Red icon, like action bars, while the recommended blessing can't be cast: target out of range or you're mounted.
local function UpdateRange()
    local rec = current and current.rec
    if rec and (IsMounted() or InRange(rec.spellId, "target") == false) then
        btn.icon:SetVertexColor(1, 0.25, 0.25)
    else
        btn.icon:SetVertexColor(1, 1, 1)
    end
end

local function Update()
    local inCombat = InCombatLockdown()
    local r = not InHiddenInstance() and ValidTarget("target") and Evaluate("target") or nil
    local hasRealResult = current and (current.stale or not current.hidden)
    if r and r.hidden and hasRealResult then
        -- Can't read buffs now: keep the last real result for this target (cleared on target change).
        current.hidden, current.stale = true, true
    else
        current = r
    end

    if not current then
        btn:SetAlpha(0)
        if not inCombat then btn:EnableMouse(false) end
    else
        local rec = current.rec
        local b = rec and blessing[rec.key]
        local spell = current.spell

        -- Secure attributes can't change in combat; the button keeps its old spell until combat ends.
        if not inCombat then
            btn:EnableMouse(true)
            btn:SetAttribute("spell", spell)
            btn:SetAttribute("spell2", current.greater or spell)
        end
        local stale = inCombat and btn:GetAttribute("spell") ~= spell

        btn:SetAlpha(1)
        btn.check:SetShown(current.done)
        btn.icon:SetTexture(b and b.icon or blessing.KINGS.icon)
        btn.icon:SetDesaturated(not b or stale)
        if b then
            btn.label:SetText(current.refresh and b.short .. " |cff808080(refresh)|r" or b.short)
        else
            btn.label:SetText((current.unworthy and "|cffff4040Unworthy|r")
                or (current.done and "|cff40ff40Done|r") or "|cff808080Nothing|r")
        end
        local border = (stale and "stale") or (rec and rec.state == "expiring" and "expiring") or "normal"
        btn.border:SetColorTexture(unpack(BORDER[border]))
        UpdateRange()
    end

    if btn.hover then ShowTooltip() end
end

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------
local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cfff58cbaEzBlessings|r: " .. msg)
end

local function SetTank(arg, value, verb)
    local name = (arg ~= "" and arg:lower()) or (UnitIsPlayer("target") and UnitKey("target"))
    if not name then return Print("give a name or target a player") end
    EzBlessingsDB.tanks[name] = value
    Print(name .. " " .. verb)
end

local HELP = {
    "/ezb tank [name] - mark player (or target) as tank",
    "/ezb untank [name] - unmark tank",
    "/ezb tanks - list tanks",
    "/ezb lock | unlock - lock button position (shift-drag always moves)",
    "/ezb reset - reset button position",
    "/ezb instances - toggle hiding the button in dungeons and raids",
    "/ezb olympus - toggle skipping Olympus guilds (and your OlympusMute list)",
}

local COMMANDS = {
    tank   = function(arg) SetTank(arg, true, "marked as tank.") end,
    untank = function(arg) SetTank(arg, nil, "is no longer a tank.") end,
    tanks  = function()
        local names = {}
        for name in pairs(EzBlessingsDB.tanks) do names[#names + 1] = name end
        table.sort(names)
        Print("Tanks: " .. (#names > 0 and table.concat(names, ", ") or "none"))
    end,
    lock   = function() EzBlessingsDB.locked = true; Print("Locked.") end,
    unlock = function() EzBlessingsDB.locked = false; Print("Unlocked.") end,
    reset  = function()
        if InCombatLockdown() then return Print("Can't move in combat.") end
        EzBlessingsDB.pos = nil
        ApplyPosition()
        Print("Position reset.")
    end,
    instances = function()
        EzBlessingsDB.hideInInstances = not EzBlessingsDB.hideInInstances
        Print(EzBlessingsDB.hideInInstances and "Hidden in dungeons and raids." or "Shown in dungeons and raids.")
    end,
    olympus = function()
        EzBlessingsDB.skipUnworthy = not EzBlessingsDB.skipUnworthy
        Print(EzBlessingsDB.skipUnworthy and "The unworthy get no blessing." or "The unworthy are blessed again.")
    end,
}

SLASH_EZBLESSINGS1 = "/ezb"
SLASH_EZBLESSINGS2 = "/ezblessings"
SlashCmdList.EZBLESSINGS = function(msg)
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
    if event == "PLAYER_TARGET_CHANGED" then current = nil end
    if event == "PLAYER_LOGIN" then
        -- Saved variables are loaded by now; only start listening once they exist.
        EzBlessingsDB = EzBlessingsDB or {}
        EzBlessingsDB.tanks = EzBlessingsDB.tanks or {}
        if EzBlessingsDB.locked == nil then EzBlessingsDB.locked = true end
        if EzBlessingsDB.hideInInstances == nil then EzBlessingsDB.hideInInstances = true end
        ApplyPosition()
        for _, e in ipairs({ "PLAYER_TARGET_CHANGED", "UNIT_AURA", "SPELLS_CHANGED", "PLAYER_REGEN_ENABLED", "PLAYER_ENTERING_WORLD" }) do
            self:RegisterEvent(e)
        end
        C_Timer.NewTicker(1, Update)
        -- Range has no event, so poll it faster than the full update.
        C_Timer.NewTicker(0.2, UpdateRange)
    end
    if event == "PLAYER_LOGIN" or event == "SPELLS_CHANGED" then
        RefreshSpells()
    end
    Update()
end)
