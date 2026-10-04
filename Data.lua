-- PallyBuff data: edit priorities here.
local _, ns = ...

-- key -> { normal blessing spellId, greater blessing spellId }
ns.BLESSINGS = {
    MIGHT     = { 19740, 25782 },
    WISDOM    = { 19742, 25894 },
    KINGS     = { 20217, 25898 },
    SALVATION = { 1038,  25895 },
    LIGHT     = { 19977, 25890 },
    SANCTUARY = { 20911, 25899 },
}

-- Blessings the game only lets you cast on yourself or party/raid members.
ns.GROUP_ONLY = {
    SALVATION = true,
}

-- Default (DPS / healer) priority by class. First entry = most wanted.
ns.PRIORITY = {
    WARRIOR = { "MIGHT", "KINGS", "SALVATION", "LIGHT" },
    ROGUE   = { "MIGHT", "KINGS", "SALVATION", "LIGHT" },
    HUNTER  = { "KINGS", "WISDOM", "SALVATION", "MIGHT" },
    MAGE    = { "WISDOM", "KINGS", "SALVATION", "LIGHT" },
    WARLOCK = { "WISDOM", "KINGS", "SALVATION", "LIGHT" },
    PRIEST  = { "WISDOM", "KINGS", "SALVATION", "LIGHT" },
    DRUID   = { "WISDOM", "KINGS", "SALVATION", "LIGHT" },
    PALADIN = { "WISDOM", "KINGS", "MIGHT", "LIGHT" },
    SHAMAN  = { "WISDOM", "KINGS", "MIGHT", "LIGHT" },
}

-- Priority for players marked as tanks (/pb tank <name>). Never Salvation.
ns.TANK_PRIORITY = {
    WARRIOR = { "KINGS", "MIGHT", "SANCTUARY", "LIGHT" },
    DRUID   = { "KINGS", "MIGHT", "SANCTUARY", "LIGHT" },
    PALADIN = { "KINGS", "SANCTUARY", "WISDOM", "LIGHT" },
}

-- Seconds left on your own blessing before suggesting a refresh.
ns.REFRESH_THRESHOLD = 60
