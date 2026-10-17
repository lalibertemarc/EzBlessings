-- EzBlessings: recommends the Paladin blessing your friendly target needs.
local _, ns = ...

-- Key bindings (Bindings.xml) click the button, so they work with the UI hidden (e.g. EzCinematic).
BINDING_HEADER_EZBLESSINGS = "EzBlessings"
_G["BINDING_NAME_CLICK EzBlessingsButton:LeftButton"] = "Cast recommended blessing"
_G["BINDING_NAME_CLICK EzBlessingsButton:RightButton"] = "Cast recommended Greater blessing"

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

-- True while the spell (or the global cooldown) is cooling down; false when unknown.
local function OnCooldown(id)
    local start, duration
    if C_Spell and C_Spell.GetSpellCooldown then
        local cd = C_Spell.GetSpellCooldown(id)
        if cd then start, duration = cd.startTime, cd.duration end
    elseif GetSpellCooldown then
        start, duration = GetSpellCooldown(id)
    end
    if not (start and duration) or issecret(start) or issecret(duration) then return false end
    return start > 0 and duration > 0 and start + duration > GetTime()
end

-- False when the game says the spell can't be cast right now (e.g. out of mana); true when unknown.
local function Usable(id)
    local usable
    if C_Spell and C_Spell.IsSpellUsable then
        usable = C_Spell.IsSpellUsable(id)
    elseif IsUsableSpell then
        usable = IsUsableSpell(id)
    end
    if usable == nil or issecret(usable) then return true end
    return usable and true or false
end

-- chatType: "SAY", or "WHISPER" with target.
local function SendChat(msg, chatType, target)
    if C_ChatInfo and C_ChatInfo.SendChatMessage then
        C_ChatInfo.SendChatMessage(msg, chatType, nil, target)
    else
        SendChatMessage(msg, chatType, nil, target)
    end
end

-- Encounters and similar lock addon chat (C_ChatInfo.InChatMessagingLockdown); sending then is blocked.
local function ChatLocked()
    return C_ChatInfo and C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown()
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

-- "First Surname"; Forever's UnitName returns the surname where retail returns the realm.
-- Whispers need the full name.
local function FullName(unit)
    local name, surname = UnitName(unit)
    if not name or issecret(name) then return nil end
    if surname and not issecret(surname) and surname ~= "" then return name .. " " .. surname end
    return name
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
--           rec = entry to cast or nil, spell / greater = button cast strings for rec, refresh = bool,
--           casts = mouse button -> { id, name, key, refresh } of the spell it casts }
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
        -- What each mouse button casts, for /ezb announce.
        local key, renew = r.rec.key, r.rec.state == "expiring"
        local normal = { id = r.rec.spellId, name = blessing[key].name, key = key, refresh = renew }
        r.casts = {
            LeftButton = normal,
            RightButton = greaterId and { id = greaterId, name = SpellInfo(greaterId), key = key, refresh = renew } or normal,
        }
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
    self.moving = true
end)
-- Also fires after a drag that never started (locked): saving then would store the default anchor without TargetFrame.
btn:SetScript("OnDragStop", function(self)
    if not self.moving then return end
    self.moving = false
    self:StopMovingOrSizing()
    local point, _, relPoint, x, y = self:GetPoint()
    EzBlessingsDB.pos = { point, relPoint, x, y }
end)

---------------------------------------------------------------------------
-- Announce (/ezb announce, /ezb message)
---------------------------------------------------------------------------
local ANNOUNCE_TEXT = { say = "in /say", whisper = "by whisper" }

-- Lines that fit this cast, from Lines.lua: the renewal ones for your own fading blessing, else the
-- general ones plus the blessing's and the target class's own. Your lines (/ezb message add) are mixed
-- in, or used alone with /ezb message mine.
local function Lines(cast, class)
    local mine = EzBlessingsDB.messages
    if EzBlessingsDB.onlyMine and #mine > 0 then return mine end
    local lines = {}
    local function Add(t)
        for _, line in ipairs(t or {}) do lines[#lines + 1] = line end
    end
    if cast.refresh then
        Add(ns.REFRESH_LINES)
    else
        Add(ns.LINES)
        Add(ns.BLESSING_LINES[cast.key])
        Add(ns.CLASS_LINES[class])
    end
    Add(mine)
    return lines
end

local lastLine -- said last time, so the same line never comes twice in a row

local function PickLine(lines)
    local i = math.random(#lines)
    if #lines > 1 and lines[i] == lastLine then i = i % #lines + 1 end
    lastLine = lines[i]
    return lines[i]
end

-- The line with %t (target) and %b (blessing) filled in, cut to chat's 255-byte limit.
local function FormatMessage(line, name, spellName)
    local msg = line
        :gsub("%%t", function() return name end)
        :gsub("%%b", function() return spellName end)
    if #msg > 255 then
        msg = msg:sub(1, 255):gsub("[\192-\255][\128-\191]*$", "") -- don't leave half a UTF-8 character
    end
    return msg
end

-- The server won't take player links in sent chat, so the target's name goes out as plain text and
-- is turned into a link when your own line comes back. Only you see the link; clicking it works like
-- any player link (whisper, EzMark's Alt+click...).
local said = {} -- your last few lines, newest last: { msg, name, class }

local function Remember(msg, name, class)
    said[#said + 1] = { msg = msg, name = name, class = class }
    if #said > 5 then table.remove(said, 1) end
end

-- Class-colored link on the full name, "First Surname" like Blizzard's own chat links: whispers
-- need the surname.
local function NameLink(name, class)
    local c = RAID_CLASS_COLORS[class]
    local link = format("|Hplayer:%s|h%s|h", name, name)
    return c and c.colorStr and format("|c%s%s|r", c.colorStr, link) or link
end

-- CHAT_MSG_SAY / CHAT_MSG_WHISPER_INFORM filter: returning false keeps the line; the message, if any,
-- replaces it.
local function LinkTarget(_, _, msg, ...)
    if issecret(msg) then return false end
    for _, entry in ipairs(said) do
        if entry.msg == msg then
            local link = NameLink(entry.name, entry.class)
            local pattern = entry.name:gsub("%p", "%%%0")
            return false, (msg:gsub(pattern, function() return link end)), ...
        end
    end
    return false
end

-- Runs inside the click or key press, before the secure cast: addons can only send chat then.
-- Skipped when the cast would fail anyway (range, mounted, cooldown, mana), so a spammed press says it once.
btn:SetScript("PreClick", function(self, button)
    local channel = EzBlessingsDB.announce
    local cast = self.casts and self.casts[button]
    if not (channel == "say" or channel == "whisper") or not cast or ChatLocked() then return end
    if not ValidTarget("target") or UnitIsUnit("target", "player") then return end
    if IsMounted() or InRange(cast.id, "target") == false or OnCooldown(cast.id) or not Usable(cast.id) then return end
    local name = FullName("target")
    if not name then return end
    local _, class = UnitClass("target")
    local msg = FormatMessage(PickLine(Lines(cast, class)), name, cast.name)
    Remember(msg, name, class)
    if channel == "whisper" then
        SendChat(msg, "WHISPER", name)
    else
        SendChat(msg, "SAY")
    end
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
        if EzBlessingsDB.announce then
            GameTooltip:AddLine("and announces it " .. ANNOUNCE_TEXT[EzBlessingsDB.announce], 0.6, 0.6, 0.6)
        end
    end
    if current.refresh then
        GameTooltip:AddLine(format("All covered: refreshes %s's blessing.", current.rec.source or "another paladin"), 0.6, 0.6, 0.6)
    end
    GameTooltip:AddLine("Left-click: cast blessing   Right-click: Greater", 0.6, 0.6, 0.6)
    GameTooltip:AddLine("Options and announce lines: /ezb", 0.6, 0.6, 0.6)
    GameTooltip:AddLine("Key bindings: Options > Keybindings > EzBlessings", 0.6, 0.6, 0.6)
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
        -- Clear the spell too, so the key binding can't cast on nothing.
        if not inCombat then
            btn:EnableMouse(false)
            btn:SetAttribute("spell", nil)
            btn:SetAttribute("spell2", nil)
            btn.casts = nil
        end
    else
        local rec = current.rec
        local b = rec and blessing[rec.key]
        local spell = current.spell

        -- Secure attributes can't change in combat; the button keeps its old spell until combat ends.
        if not inCombat then
            btn:EnableMouse(true)
            btn:SetAttribute("spell", spell)
            btn:SetAttribute("spell2", current.greater or spell)
            btn.casts = current.casts -- kept in step with the attributes, so announces name what's really cast
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
ns.Update = Update

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

function ns.ResetPosition()
    if InCombatLockdown() then return Print("Can't move in combat.") end
    EzBlessingsDB.pos = nil
    ApplyPosition()
    Print("Position reset.")
end

local HELP = {
    "/ezb - open the options",
    "/ezb tank [name] - mark player (or target) as tank",
    "/ezb untank [name] - unmark tank",
    "/ezb tanks - list tanks",
    "/ezb lock | unlock - lock button position (shift-drag always moves)",
    "/ezb reset - reset button position",
    "/ezb instances - toggle hiding the button in dungeons and raids",
    "/ezb olympus - toggle skipping Olympus guilds (and your OlympusMute list)",
    "/ezb announce off | say | whisper - say or whisper a line to the target when you bless them",
    "/ezb message - list your own lines (mixed in with the built-in ones)",
    "/ezb message add <text> | remove <n> | clear - edit them; %t = target, %b = blessing",
    "/ezb message mine - toggle using only your lines",
    "/ezb message test - show a line as it could go out now",
}

-- A line as it could go out on your target (or a stand-in) now. Doesn't count as said.
local function Example()
    local valid = ValidTarget("target")
    local name = valid and FullName("target") or "Anduin Lothar"
    local class = valid and select(2, UnitClass("target"))
    local cast = current and current.casts and current.casts.LeftButton or { name = blessing.KINGS.name, key = "KINGS" }
    local lines = Lines(cast, class)
    return FormatMessage(lines[math.random(#lines)], name, cast.name)
end

-- Adds one of your own lines; returns its number, or nil when there's nothing to add.
function ns.AddLine(text)
    text = strtrim((text:gsub("|", ""))) -- "|" starts chat escape codes, which the server rejects
    if text == "" then return nil end
    local mine = EzBlessingsDB.messages
    mine[#mine + 1] = text
    return #mine, text
end

-- Removes your line number i; returns its text, or nil when there's no such line.
function ns.RemoveLine(i)
    local mine = EzBlessingsDB.messages
    if not (i and mine[i]) then return nil end
    return table.remove(mine, i)
end

ns.Example = Example

local function AnnounceHint()
    if not EzBlessingsDB.announce then Print("Lines go out once you turn on /ezb announce say | whisper") end
end

-- /ezb message subcommands.
local MESSAGE = {
    list = function()
        local mine = EzBlessingsDB.messages
        Print(format("Your lines (%d), %s:", #mine,
            EzBlessingsDB.onlyMine and "used alone" or "mixed in with the built-in ones"))
        for i, line in ipairs(mine) do Print(format("%d. %s", i, line)) end
        if #mine == 0 then Print("None yet. /ezb message add <text>; %t = target, %b = blessing") end
        AnnounceHint()
    end,
    add = function(text)
        local i, line = ns.AddLine(text)
        if not i then return Print("/ezb message add <text>; %t = target, %b = blessing") end
        Print(format("Line %d added: %s", i, line))
        AnnounceHint()
    end,
    remove = function(arg)
        local line = ns.RemoveLine(tonumber(arg))
        if not line then return Print("/ezb message remove <number>, from /ezb message") end
        Print("Removed: " .. line)
    end,
    clear = function()
        wipe(EzBlessingsDB.messages)
        Print("Your lines are cleared. The built-in ones remain.")
    end,
    mine = function()
        EzBlessingsDB.onlyMine = not EzBlessingsDB.onlyMine
        Print(EzBlessingsDB.onlyMine and "Only your lines are used (the built-in ones while you have none)."
            or "Your lines are mixed in with the built-in ones.")
    end,
    test = function() Print("Example: " .. Example()) end,
}
MESSAGE.del, MESSAGE.reset = MESSAGE.remove, MESSAGE.clear

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
    reset  = function() ns.ResetPosition() end,
    instances = function()
        EzBlessingsDB.hideInInstances = not EzBlessingsDB.hideInInstances
        Print(EzBlessingsDB.hideInInstances and "Hidden in dungeons and raids." or "Shown in dungeons and raids.")
    end,
    olympus = function()
        EzBlessingsDB.skipUnworthy = not EzBlessingsDB.skipUnworthy
        Print(EzBlessingsDB.skipUnworthy and "The unworthy get no blessing." or "The unworthy are blessed again.")
    end,
    announce = function(arg)
        arg = arg:lower()
        if arg == "off" then
            EzBlessingsDB.announce = nil
        elseif ANNOUNCE_TEXT[arg] then
            EzBlessingsDB.announce = arg
        elseif arg ~= "" then
            return Print("/ezb announce off | say | whisper")
        end
        local a = EzBlessingsDB.announce
        Print(a and format("Blessings announced %s, e.g.: %s", ANNOUNCE_TEXT[a], Example()) or "Blessings are cast in silence.")
    end,
    message = function(arg)
        local sub, rest = arg:match("^(%S*)%s*(.-)$")
        local fn = MESSAGE[sub:lower()] or (sub == "" and MESSAGE.list)
        if fn then return fn(rest) end
        Print("/ezb message [add <text> | remove <n> | clear | mine | test]")
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
    elseif cmd == "" then
        ns.OpenSettings()
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
        EzBlessingsDB.messages = EzBlessingsDB.messages or {}
        -- Before random lines, /ezb message kept a single line here.
        if type(EzBlessingsDB.message) == "string" then
            table.insert(EzBlessingsDB.messages, EzBlessingsDB.message)
            EzBlessingsDB.message = nil
        end
        if EzBlessingsDB.locked == nil then EzBlessingsDB.locked = true end
        if EzBlessingsDB.hideInInstances == nil then EzBlessingsDB.hideInInstances = true end
        -- Older versions could save the default anchor without TargetFrame, putting the button off-screen.
        local p = EzBlessingsDB.pos
        if p and p[1] == "LEFT" and p[2] == "RIGHT" and p[3] == -10 and p[4] == 10 then EzBlessingsDB.pos = nil end
        ApplyPosition()
        ns.BuildSettings()
        local AddFilter = (ChatFrameUtil and ChatFrameUtil.AddMessageEventFilter) or ChatFrame_AddMessageEventFilter
        if AddFilter then
            AddFilter("CHAT_MSG_SAY", LinkTarget)
            AddFilter("CHAT_MSG_WHISPER_INFORM", LinkTarget)
        end
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
