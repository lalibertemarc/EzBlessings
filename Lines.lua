-- EzBlessings lines: what you say or whisper on cast while /ezb announce is on. Edit them here.
-- One is picked at random (never the same twice in a row). %t = target's name, %b = blessing cast.
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
