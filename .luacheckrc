std = "lua51"
max_line_length = false
self = false

globals = {
    "EzBlessingsDB",
    "SLASH_EZBLESSINGS1",
    "SLASH_EZBLESSINGS2",
    "SlashCmdList",
    "BINDING_HEADER_EZBLESSINGS",
    "_G",
}

read_globals = {
    -- Lua / WoW utility
    "format", "floor", "strtrim", "wipe", "unpack",
    -- Frames & UI
    "CreateFrame", "UIParent", "TargetFrame", "GameTooltip", "DEFAULT_CHAT_FRAME",
    "RAID_CLASS_COLORS", "NORMAL_FONT_COLOR",
    -- Namespaced APIs
    "C_Spell", "C_SpellBook", "C_UnitAuras", "C_Timer", "C_Secrets", "issecretvalue",
    -- Global APIs
    "GetSpellInfo", "GetSpellSubtext", "IsSpellKnown", "IsSpellInRange", "UnitBuff", "UnitClass", "UnitName", "UnitLevel",
    "UnitIsUnit", "UnitInParty", "UnitInRaid", "UnitExists", "UnitIsPlayer", "UnitIsFriend", "UnitIsDeadOrGhost", "GetGuildInfo",
    "UnitGUID", "GetUnitName", "GetNormalizedRealmName", "GetRealmName",
    "GetTime", "GetCVarBool", "InCombatLockdown", "IsShiftKeyDown", "IsMounted", "IsInInstance",
    -- Other addons (optional)
    "OlympusMuteDB",
}
