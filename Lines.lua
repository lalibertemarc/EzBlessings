-- EzBlessings lines: what you say or whisper on cast while /ezb announce is on. Edit them here.
-- One is picked at random (never the same twice in a row). %t = target's full name (linked in your chat), %b = blessing cast.
-- Your own lines (/ezb message add) are mixed in; /ezb message mine uses only yours.
local _, ns = ...

ns.LINES = {
    "%t, may the Light guide you. I grant you %b.",
    "The Light provides, %t. Receive %b.",
    "%t, by the grace of the Light, I bless you with %b.",
    "Stand tall, %t. %b is upon you.",
    "In Uther's name, %t, I grant you %b.",
    "%t, the Silver Hand looks after its own. Take %b.",
    "Respect, Tenacity, Compassion. %t, receive %b.",
    "%t, walk in the Light. %b goes with you.",
    "None go unblessed, %t. Not even you. %b.",
    "%t, the Light sees you. Here is %b.",
    "Go forth, %t, with %b and a clear conscience.",
    "%t, %b is yours. Try not to waste it.",
    "May %b shield you where my hammer cannot, %t.",
    "%t, I prayed for you. The Light answered: %b.",
    "%t, you look like you could use %b. The Light agrees.",
    "Kneel, %t. Actually, don't. %b works standing up.",
    "By the Light of Lordaeron, %t, I grant you %b.",
    "%t, the Light shines brightest on those who fight for others. Take %b.",
    "Fear not, %t. %b is with you now.",
    "%t, a blessing freely given: %b. Pass the kindness on.",
    "%t, the Light has many gifts. Today it chose %b.",
    "Hold fast, %t. %b will see you through.",
    "%t, I bless you with %b. Uther would have done the same.",
    "Light be with you, %t. And %b, for good measure.",
    "%t, consider yourself blessed. With %b, specifically.",
    "%t, the Light needs no thanks. %b is yours.",
    "%t, I swore an oath to protect the innocent. You'll do. %b.",
    "A paladin's duty, %t: %b for you, and the Light for all.",
    "%t, the Light flows through me to you. Feel %b.",
    "Be strong, %t. Be kind. Be blessed with %b.",
    "%t, the Light keeps no ledger. %b is yours, free.",
    "Here, %t. %b, straight from the Light. No charge.",
    "%t, let %b remind you that you are never alone.",
    "With the Light's blessing, %t: %b. Now go do some good.",
    "%t, by the oath of the Silver Hand, I grant you %b.",
    "%t, Tirion Fordring would want you blessed. %b.",
    "The Light is generous today, %t. Take %b.",
    "%t, may %b serve you better than the last hearthstone.",
    "%t, the Light chose you. I just pointed. %b.",
    "Take %b, %t, and let your enemies wonder why you're glowing.",
}

-- Extra lines for one blessing, mixed in with the lines above.
ns.BLESSING_LINES = {
    MIGHT = {
        "%t, may %b put strength in your arm and steel in your strikes.",
        "Hit harder, %t. %b insists.",
        "%t, the Light grants you %b. Your enemies will feel it.",
        "Strike true, %t. %b is behind every blow.",
        "%t, take %b. A strong arm defends the weak.",
    },
    WISDOM = {
        "%t, may %b keep your mind clear and your mana full.",
        "Drink less, cast more, %t. %b is yours.",
        "%t, wisdom is a gift. %b, to be exact.",
        "%t, may %b fill the well you draw from.",
        "Fewer breaks, %t. %b will see to it.",
    },
    KINGS = {
        "%t, %b, as Lordaeron's kings once received it.",
        "Every hero deserves a crown, %t. %b is yours.",
        "%t, may %b make you stronger in every way.",
        "Rise, %t, and receive %b. Kings would envy you.",
        "%t, %b. Fit for a king, given to you.",
    },
    SALVATION = {
        "%t, %b. Let the beasts look elsewhere.",
        "Quiet now, %t. %b will keep their eyes off you.",
        "%t, may %b hide you from the wrath of your foes.",
        "%t, take %b and let the tank do their job.",
        "%t, %b is yours. The monsters will forget you were here.",
    },
    LIGHT = {
        "%t, may %b make every heal shine brighter.",
        "%t, %b. Let the Light mend you faster.",
        "The Light heals, %t, and %b helps it along.",
        "%t, take %b. Your healers will thank me.",
        "%t, may %b carry each heal a little further.",
    },
}

-- Extra lines for the target's class, mixed in with the lines above.
ns.CLASS_LINES = {
    WARRIOR = {
        "%t, Lothar fought for Lordaeron with a blade like yours. Take %b.",
        "Into the fray, %t. %b goes with you.",
        "%t, may %b keep you standing when the shield breaks.",
    },
    ROGUE = {
        "%t, even the shadows deserve the Light. Take %b.",
        "%t, I won't ask where you've been. %b, no questions.",
        "Quick and quiet, %t. %b won't slow you down.",
    },
    HUNTER = {
        "%t, %b for you. Your pet will have to wait its turn.",
        "%t, may %b keep your aim true.",
        "Good hunting, %t. %b goes with you and your companion.",
    },
    MAGE = {
        "%t, the Light and the arcane can get along. Take %b.",
        "%t, %b. Dalaran's books don't cover this one.",
        "%t, may %b keep you from sheeping the wrong target.",
    },
    WARLOCK = {
        "%t, I don't approve of your demons. The Light blesses you anyway: %b.",
        "%t, %b. Keep your imp away from my libram.",
        "Even you, %t. Especially you. %b, and think about your choices.",
    },
    PRIEST = {
        "%t, from one servant of the Light to another: %b.",
        "%t, you heal them, I bless you. %b.",
        "%t, the Light calls us both. Take %b.",
    },
    DRUID = {
        "%t, the Light and Elune would get along. Take %b.",
        "%t, %b, whatever form you're in today.",
        "%t, may %b serve you in bark, claw or fur.",
    },
    PALADIN = {
        "%t, Silver Hand to Silver Hand: %b.",
        "%t, a paladin blessing a paladin. Uther would smile. %b.",
        "%t, I'll trust you to return the favor. %b.",
    },
    SHAMAN = {
        "%t, the elements and the Light walk together today. Take %b.",
        "%t, %b. Your totems can rest a moment.",
        "%t, may %b stand with your ancestors beside you.",
    },
}

-- Said instead of a blessing when you click an unworthy target (/ezb olympus). Firm, never cruel:
-- a paladin keeps a vow, not a grudge, and always leaves the way back open. %t only (nothing is
-- cast, so no %b).
ns.UNWORTHY_LINES = {
    "%t, the Light forgives all who repent. Turn from Olympus, and my blessing is yours.",
    "Repent, %t. The Light has not closed its door to you, and neither have I.",
    "%t, I will pray for your repentance. Until then, no blessing from me.",
    "Forgive me, %t. My oath keeps my hands still for those who stand with Olympus. Repent, and they are yours.",
    "%t, Uther taught that no soul is beyond redemption. Not even yours. Repent, and come back to me.",
    "Peace be with you, %t. Leave Olympus behind, and the Light will bless you through my hands.",
    "%t, the Light shines on all, but it asks one thing of you first: repentance.",
    "Your banner flies for Olympus, %t. Lay it down, repent, and walk with the Light.",
    "%t, the Silver Hand keeps its vows. Make yours to the Light, repent, and I will bless you gladly.",
    "%t, repentance is a road, not a wall. Take the first step and I will meet you there.",
    "I bear you no ill will, %t. Repent, and my blessing will be the first you receive.",
    "%t, the doors of Northshire Abbey are open to all who repent. Seek the Light there.",
    "The Light remembers every deed, %t, and forgives every one that is repented.",
    "%t, I will not raise my hand against you, nor in blessing. Repent, and go in peace.",
    "%t, false gods offer you nothing. The Light offers forgiveness. Repent.",
    "Walk safely, %t. Should you ever repent and leave Olympus behind, my blessings will be waiting.",
    "%t, the Cathedral of Light hears every confession. Repent there, and return to me.",
    "%t, it is never too late to repent. The Light is patient. So am I.",
    "Light keep you, %t, and guide you to repentance.",
    "%t, forgive a paladin's vows. Repent, and they will bless you instead of passing you by.",
}

-- Seconds between two refusals, so clicking an unworthy target again and again says it once.
ns.REFUSAL_COOLDOWN = 10

-- Said instead of the lines above when Might goes to a caster (ns.CASTER_CLASSES): every other
-- blessing was taken, and you both know it does nothing for them.
ns.MIGHT_ON_CASTER_LINES = {
    "%t, %b. Yes, I know. You'll never swing that staff hard enough to notice.",
    "%t, the Light ran out of better ideas. Enjoy %b, I suppose.",
    "%t, %b for you. Utterly useless, but none go unblessed.",
    "%t, I'm told %b does nothing for spellcasters. The Light insists anyway.",
    "Here's %b, %t. Please don't try to melee anything because of it.",
    "%t, %b. It won't help your spells, but it looks nice on you.",
    "%t, every other blessing is taken. You get %b. We both know it's pointless.",
    "%t, %b: for when you finally run out of mana and start hitting things with your staff.",
    "%t, %b. Uther would call it a gesture. I call it the only one left.",
    "Behold, %t: %b! About as useful as boots on a murloc.",
    "%t, %b won't make your spells hit any harder. Sorry.",
    "%t, take %b. Purely ceremonial.",
    "%t, consider %b a souvenir. It does nothing else.",
    "%t, %b. Better than nothing, but only just.",
    "%t, %b. Don't tell the warriors I wasted it on you.",
}

-- Said instead when other paladins already cover everything the target wants and you renew one of
-- theirs (the button's "(refresh)"). %p = that paladin's name, or "another paladin" when unknown, so
-- don't start a line with it.
ns.RENEW_OTHER_LINES = {
    "%t, %p already gave you %b. Let me renew it, the Light won't mind.",
    "%t, %b from %p is still on you. A fresh one never hurts.",
    "%t, every blessing you need is already yours, thanks to %p. I'll renew %b anyway.",
    "%t, you're well blessed already. Here's a fresh %b, with %p's compliments and mine.",
    "%t, I'll top up the %b that %p gave you. The Light is never idle.",
    "%t, nothing's missing, so I'm renewing %b. I'm sure %p won't mind sharing.",
    "%t, %p beat me to it. Here's %b again, freshly blessed.",
    "%t, another hour of %b. %p started it, I'm finishing it.",
    "%t, the Light has already been generous with you. %b, renewed all the same.",
    "%t, %p and I both think you deserve %b. Here it is again.",
}

-- Said instead when you renew your own blessing before it drops (see ns.REFRESH_THRESHOLD).
ns.REFRESH_LINES = {
    "%t, your blessing grows faint. %b, renewed.",
    "The Light does not tire, %t. Neither do I. %b, again.",
    "%t, time to renew %b.",
    "%t, %b was fading. Not on my watch.",
    "%t, let me top up %b.",
    "Another hour of %b for you, %t.",
    "%t, the Light renews what time wears down. %b.",
    "%t, one more %b for the road.",
    "%t, %b again. The Light keeps its promises.",
    "%t, a fresh %b before the old one fades.",
}
