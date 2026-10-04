std = "lua51"
max_line_length = false
self = false

globals = {
    "PallyBuffDB",
    "SLASH_PALLYBUFF1",
    "SLASH_PALLYBUFF2",
    "SlashCmdList",
}

read_globals = {
    -- Lua / WoW utility
    "format", "floor", "strtrim", "wipe", "unpack",
    -- Frames & UI
    "CreateFrame", "UIParent", "TargetFrame", "GameTooltip", "DEFAULT_CHAT_FRAME",
    "RAID_CLASS_COLORS", "NORMAL_FONT_COLOR", "BOOKTYPE_SPELL", "Enum",
    -- Namespaced APIs
    "C_Spell", "C_SpellBook", "C_UnitAuras", "C_Timer",
    -- Global APIs
    "GetSpellInfo", "GetSpellBookItemName", "UnitBuff", "UnitClass", "UnitName",
    "UnitIsUnit", "UnitExists", "UnitIsPlayer", "UnitIsFriend", "UnitIsDeadOrGhost",
    "GetTime", "GetCVarBool", "InCombatLockdown", "IsShiftKeyDown",
}
