-- EzBlessings data: edit priorities here.
local _, ns = ...

-- Classic Era (interface 11xxx) instead of Forever (16xxx): 5-minute blessings, Kings and Sanctuary are talents.
ns.ERA = select(4, GetBuildInfo()) < 16000

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
-- Classic Era only: Sanctuary is a Protection talent there; Forever has no Sanctuary at all.
if ns.ERA then
    ns.BLESSINGS.SANCTUARY = {
        ranks   = { { 20911, 30 }, { 20912, 40 }, { 20913, 50 }, { 20914, 60 } },
        greater = { { 25899, 60 } },
    }
end

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
    WARLOCK = { "KINGS", "WISDOM", "MIGHT", "SALVATION", "LIGHT" },
    PRIEST  = { "WISDOM", "KINGS", "SALVATION", "LIGHT", "MIGHT" },
    DRUID   = { "KINGS", "WISDOM", "SALVATION", "LIGHT", "MIGHT" },
    PALADIN = { "KINGS", "WISDOM", "MIGHT", "LIGHT" },
    SHAMAN  = { "KINGS", "WISDOM", "MIGHT", "LIGHT" },
}

-- Classes Might does nothing for: when it's all that's left for them, the announce admits it
-- (ns.MIGHT_ON_CASTER_LINES in Lines.lua).
ns.CASTER_CLASSES = {
    PRIEST  = true,
    MAGE    = true,
    WARLOCK = true,
}

-- Classes that can heal; their default priority is labeled "DPS/Healer" instead of "DPS".
ns.HEALER_CLASSES = {
    PRIEST  = true,
    DRUID   = true,
    PALADIN = true,
    SHAMAN  = true,
}

-- Priority for players marked as tanks (/ezb tank <name>). Never Salvation.
ns.TANK_PRIORITY = {
    WARRIOR = { "KINGS", "MIGHT", "LIGHT" },
    DRUID   = { "KINGS", "MIGHT", "LIGHT" },
    PALADIN = { "KINGS", "WISDOM", "LIGHT", "MIGHT" },
}
if ns.ERA then
    ns.TANK_PRIORITY = {
        WARRIOR = { "KINGS", "MIGHT", "SANCTUARY", "LIGHT" },
        DRUID   = { "KINGS", "MIGHT", "SANCTUARY", "LIGHT" },
        PALADIN = { "KINGS", "SANCTUARY", "WISDOM", "LIGHT", "MIGHT" },
    }
end

-- Case-insensitive parts of guild names whose members get no blessing while /ezb olympus is on.
-- Only used without OlympusMute; with it installed, its own lists are used instead.
ns.UNWORTHY_GUILDS = { "olympus" }

-- Seconds left on your own blessing before suggesting a refresh. Classic Era's blessings last
-- 5 minutes (Greater 15), so there it's only near the end.
ns.REFRESH_THRESHOLD = ns.ERA and 120 or 1200

-- Accents: Accent.lua (EzAccent's engine) respells every announce line live, in the accent of your race (dwarves;
-- orcs and trolls too, should they ever take up the Light; everyone else speaks plainly) unless the character
-- chose another (EzBlessingsCharDB.accent, a key below; /ezb accent or the options page), and .thick makes any of
-- them thicker (undead: no jaw at all). Undead is never picked by race, only chosen. %t, %b and %p are filled in
-- after, so names and the blessing are never respelled.
-- UnitRace's file name -> accent.
ns.RACE_ACCENT = { Orc = "orc", Troll = "troll", Dwarf = "dwarf" }
-- Accent choices, in menu order.
ns.ACCENTS = {
    { key = "race", label = "By race", desc = "Dwarves use their own accent, everyone else speaks plainly." },
    { key = "none", label = "None", desc = "Plain lines, whatever your race." },
    { key = "orc", label = "Orc", desc = "Lok'tar! Short, blunt, and proud of it." },
    { key = "troll", label = "Troll", desc = "Easy now, mon. Da Light be watchin'." },
    { key = "dwarf", label = "Dwarf", desc = "By me beard, lad! Your target is a lad or a lass." },
    { key = "undead", label = "Undead", desc = "A locked jaw squeezes every vowel; thick: no jaw at all." },
}
ns.ACCENT = {}
for _, a in ipairs(ns.ACCENTS) do ns.ACCENT[a.key] = a end
ns.DEFAULT_ACCENT = "race"
-- A woman hears the accent's own address words in her form (dwarf "lad" -> "lass", troll "bruddah" -> "sistah"),
-- unless the plain line already has one of the typed words (as EzAccent does).
ns.TO_HER = {
    { he = "lad", she = "lass", typed = { "lad" } },
    { he = "bruddah", she = "sistah", typed = { "brother", "bruddah" } },
}
ns.ACCENT_SAMPLE = "%t, may the Light guide you. I grant you %b, by the grace of the Light."
