-- PallyBuff data: edit priorities here.
local _, ns = ...

-- key -> ranks of the normal and Greater blessing as { spellId, level learned }, lowest rank first.
ns.BLESSINGS = {
    MIGHT = {
        ranks   = { { 19740, 4 }, { 19834, 12 }, { 19835, 22 }, { 19836, 32 }, { 19837, 42 }, { 19838, 52 }, { 25291, 60 } },
        greater = { { 25782, 52 }, { 25916, 60 } },
    },
    WISDOM = {
        ranks   = { { 19742, 14 }, { 19850, 24 }, { 19852, 34 }, { 19853, 44 }, { 19854, 54 }, { 25290, 60 } },
        greater = { { 25894, 54 }, { 25918, 60 } },
    },
    KINGS = {
        ranks   = { { 20217, 20 } },
        greater = { { 25898, 60 } },
    },
    SALVATION = {
        ranks   = { { 1038, 26 } },
        greater = { { 25895, 60 } },
    },
    LIGHT = {
        ranks   = { { 19977, 40 }, { 19978, 50 }, { 19979, 60 } },
        greater = { { 25890, 60 } },
    },
}

-- A rank can't be cast on a target more than this many levels below the level it's learned at.
ns.RANK_LEVEL_GAP = 10

-- Blessings the game only lets you cast on yourself or party/raid members.
ns.GROUP_ONLY = {
    SALVATION = true,
}

-- Default (DPS / healer) priority by class. First entry = most wanted.
ns.PRIORITY = {
    WARRIOR = { "MIGHT", "KINGS", "SALVATION", "LIGHT" },
    ROGUE   = { "MIGHT", "KINGS", "SALVATION", "LIGHT" },
    HUNTER  = { "KINGS", "WISDOM", "SALVATION", "MIGHT" },
    MAGE    = { "WISDOM", "KINGS", "SALVATION", "LIGHT", "MIGHT" },
    WARLOCK = { "WISDOM", "KINGS", "SALVATION", "LIGHT", "MIGHT" },
    PRIEST  = { "WISDOM", "KINGS", "SALVATION", "LIGHT", "MIGHT" },
    DRUID   = { "WISDOM", "KINGS", "SALVATION", "LIGHT", "MIGHT" },
    PALADIN = { "WISDOM", "KINGS", "MIGHT", "LIGHT" },
    SHAMAN  = { "WISDOM", "KINGS", "MIGHT", "LIGHT" },
}

-- Classes that can heal; their default priority is labeled "DPS/Healer" instead of "DPS".
ns.HEALER_CLASSES = {
    PRIEST  = true,
    DRUID   = true,
    PALADIN = true,
    SHAMAN  = true,
}

-- Priority for players marked as tanks (/pb tank <name>). Never Salvation.
ns.TANK_PRIORITY = {
    WARRIOR = { "KINGS", "MIGHT", "LIGHT" },
    DRUID   = { "KINGS", "MIGHT", "LIGHT" },
    PALADIN = { "KINGS", "WISDOM", "LIGHT", "MIGHT" },
}

-- Seconds left on your own blessing before suggesting a refresh.
ns.REFRESH_THRESHOLD = 300
