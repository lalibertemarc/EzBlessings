# EzBlessings

## v1.13.1

- **Orcs still offer.** In the orc accent, "Would you like...?" lines stay questions ("You want...?") instead of turning into orders.
- **Camps count.** At a camp, the Fish Bowl, Mana Well and Lodestone already give Kings, Wisdom and Might, and a paladin's blessing of that kind won't land on top. The button now sees them on your target ("from camp" in the tooltip) and suggests the next blessing instead, and the announce line stays quiet if you cast it anyway.
- **No speech for a blessing that won't land.** When a stronger blessing of the same kind is already on your target (a Greater one, or a higher rank), the cast fails with "A more powerful spell is already active", and now the announce line stays quiet too. The button also stops suggesting to refresh another paladin's blessing you can't replace, and its tooltip says when only the Greater blessing (right-click) can.

## v1.13.0

- **Every accent, light or thick.** Announce lines can now be said in a dwarf, orc, troll or undead accent, on any paladin: `/ezb accent dwarf` (or `orc`, `troll`, `undead`, `none`, or the Accent dropdown on the options page). `/ezb thick` (or the new Thick accent checkbox) makes it heavier: "Och! Anduin Lothar, may the Licht guide ye. Ah grant ye Blessing of Kings, lad." For the undead, thick is the jawless voice; `/ezb accent locked` and `jawless` still work. The default is By race: dwarves speak dwarf, everyone else plainly. Every line, your own included, is respelled live as it goes out, a little different each time, and a woman hears "lass" instead of "lad". Per character, takes effect on the next line.
- Dwarf lines are now spoken live by the same accent engine instead of a fixed set of translated lines, so they vary each time and your own lines get the accent too.
- With EzAccent, changing its accent now sets the same accent and thickness here (it used to set only the undead one).
- Your 1.12 choice carries over: locked jaw becomes Undead, jawless becomes Undead with Thick accent on.
- **A tidier options page.** It now looks like the other Ez addons' pages: Announce, Your character and Button sections in Blizzard's own settings list, with dropdowns for the announce channel and accent and a Preview button that prints a few sample lines to your chat. Your own lines moved to a page of their own, Your lines (the Edit button, or under EzBlessings in the list on the left).

## v1.12.0

- **The Light, through clenched teeth.** Forsaken paladins can announce their blessings in an undead accent: `/ezb accent locked` (or `jawless`, or the Accent dropdown on the options page) respells every line live as it goes out, a little different each time. Locked jaw squeezes its vowels and strains at the end: "Huld fesst, Anduin Lothar. Blessing of Kings will see yuu thruugh. Nnn." Jawless slurs and gurgles: "Anduin Lothar, I hhrayed hhor you. Hhk. Hhe Light ansh'ered: Blessing of Kings. Hhkk." Names and the blessing are never respelled, so the target's link still works, and your own lines get the accent too. A line the accent would push past 255 characters goes out plain. Per character, off by default, takes effect right away; `/ezb accent` shows the current one with a sample, `/ezb accent none` turns it off. With EzAccent, changing its accent sets this one too (undead is locked jaw, thick undead is jawless, anything else is none). Dwarves keep their dwarf lines and get no undead accent. The rules are EzAccent's.

## v1.11.0

- **The Light reaches Classic Era.** EzBlessings now loads in Classic Era too (1.15.9). There, blessings last 5 minutes, so the yellow border and renewal come with 2 minutes left; Kings is a talent, shown as "not learned" when you didn't take it; Blessing of Sanctuary is back for marked tanks (Kings > Might > Sanctuary > Light for warriors and druids, Kings > Sanctuary > Wisdom > Light > Might for paladins), with 5 announce lines of its own; and the button stays in dungeons and raids, since Era doesn't hide buffs there. Players from another realm are named "Name-Realm".
- **Och, the Light provides.** Dwarf paladins now announce their blessings in a dwarf accent: "Here, Anduin. Blessing of Kings, straight frae the Light. No charge." Every built-in line has a dwarf version (refusals, renewals and Might-on-a-caster included), calling the target "lad" or "lass". Your own lines stay as you wrote them.

## v1.10.0

- **A vow, not a grudge.** With `/ezb olympus` on and announcing turned on, clicking an unworthy target no longer does nothing in silence: you tell them, in /say or by whisper, why no blessing comes, and how to earn it back. One of 20 lines, firm but never cruel, each leaving the way open: "Repent. The Light has not closed its door to you, and neither have I." At most one refusal every 10 seconds, however often you click.
- **Honesty is a virtue too.** When Blessing of Might is all that's left for a priest, mage or warlock, the announce no longer pretends it helps: one of 15 lines admits it, from "Purely ceremonial" to "about as useful as boots on a murloc".
- **Credit where it's due.** When other paladins already cover everything and the button offers a "(refresh)", the announce says so and names them: one of 10 lines, like "Bob beat me to it. Here's Blessing of Kings again, freshly blessed." Renewing your own fading blessing keeps its own 10 lines.
- "Try a line" on the options page shows a refusal while your target is unworthy.

## v1.9.1

- Announces now name your target in full, first name and surname, and in your own chat that name becomes a class-colored player link: click it to whisper them, or Alt+click it with EzMark to mark them. Only you see the link; everyone else reads the plain name.

## v1.9.0

- **A blessing is also a word.** The Light flows through your hands, but your companions deserve to hear it too. `/ezb announce say` speaks a line when you bless your target, `/ezb announce whisper` murmurs it to them alone, and `/ezb announce off` (the default) keeps your blessings silent.
- **A hundred ways to say it.** Each blessing comes with one of 40 lines picked at random, never the same twice in a row, from Uther's name to "Kneel. Actually, don't." Every blessing has 5 lines of its own (Salvation tells the beasts to look elsewhere), every class 3 (warlocks are blessed despite their demons), and renewing your own fading blessing gets one of 10 lines about renewal.
- **Your own words.** `/ezb message add <text>` adds your own lines to the mix: `%t` becomes your target's name and `%b` the blessing you cast, Greater ones included. `/ezb message` lists them, `/ezb message remove <n>` and `/ezb message clear` take them away, `/ezb message mine` uses only yours, and `/ezb message test` shows a line as it would go out. The built-in lines live in `Lines.lua`.
- **An options page.** Esc > Options > AddOns > EzBlessings, or just `/ezb`: pick Off, Say or Whisper, type your own lines into a box and add or remove them with a click, try a random line, and set the button's lock, dungeon hiding and Olympus vow. `/ezb help` lists the slash commands.
- It only speaks when the blessing can land: never on yourself, never while mounted, out of range, out of mana or on cooldown, so hammering the key says it once.

## v1.8.0

- Warlocks now get Blessing of Kings first, then Wisdom, then Might (ahead of Salvation and Light).

## v1.7.0

- **The Light needs no altar.** A paladin who walks Azeroth with eyes on the horizon, not on their action bars, can still bless the faithful. Two new key bindings under Options > Keybindings > EzBlessings cast the recommended blessing (or its Greater form) on your target with a single word of prayer. They work even when the interface is hidden away, so you can bless your companions mid-cinematic with EzCinematic.
- With no worthy target in sight, the binding stays silent instead of calling down your last blessing on empty air.

## v1.6.0

- **Compassion has its limits.** Uther taught that the Light is for all, but even the Silver Hand never swore to bless those who kneel to a mountain of false gods. The new `/ezb olympus` vow (off by default) withholds your blessings from anyone whose guild name contains "Olympus", in every spelling they hide behind. The button reads "Unworthy", casts nothing, and the tooltip names the guild that sealed their fate.
- **The ledger of the fallen.** If you carry OlympusMute, EzBlessings reads from its book: guild names you've added, guilds you've pardoned, players you've marked by hand or chosen to spare, and its character-name keywords. A heretic whose guild tag hasn't loaded yet is still judged by the guild OlympusMute last saw them in.
- **The Light is never idle.** When other paladins have already covered every blessing a worthy target wants, the button no longer shrugs "Nothing". It offers to refresh the most wanted one, labeled "(refresh)", and the tooltip names the paladin whose blessing you'd renew.
- Fixed the button vanishing off the right edge of the screen after trying to drag it while locked. Buttons already lost that way come back next to the target frame.

## v1.5.0

- Druids, paladins and shamans now get Blessing of Kings first, then Wisdom. Mages, warlocks and priests still get Wisdom first.

## v1.4.0

- Refresh warning now triggers with 20 minutes left instead of 5, so your blessings are recommended for recast sooner.
- The button icon also turns red while you're mounted, since you can't cast blessings until you dismount.

## v1.3.0

- The button icon turns red when the target is out of range of the recommended blessing.

## v1.2.1

- First release on CurseForge. No gameplay changes from v1.2.0.

## v1.2.0

- The button is now hidden in dungeons and raids, where the game hides buffs from addons the whole time. Use `/ezb instances` to show it there anyway.
- Tooltip no longer blames combat when buffs are hidden, since it also happens outside combat.

## v1.1.0

- Renamed from PallyBuff to EzBlessings. None go unblessed.
- Slash commands are now `/ezb` and `/ezblessings` (was `/pb` and `/pallybuff`).
- Settings are stored under a new name, so marked tanks and the button position start fresh. Delete the old `PallyBuff` folder from `Interface\AddOns`.

## v1.0.6

- Casts the highest blessing rank the target's level allows, so low-level players no longer get "target too low" errors. Blessings with no rank that fits are skipped and shown as "target too low" in the tooltip.
- Tooltip shows exactly what will be cast, e.g. "Casts Blessing of Might(Rank 3)".
- Right-click picks the right Greater Blessing rank too.
- Code cleanup.

## v1.0.5

- Removed Blessing of Sanctuary, which doesn't exist in WoW Forever. Tank priorities are now Kings > Might > Light (Warrior, Druid) and Kings > Wisdom > Light > Might (Paladin).
- Refresh warning now triggers with 5 minutes left instead of 60 seconds, to suit Forever's 1-hour blessings.

## v1.0.4

- Tooltip role now matches the class: warriors, rogues, hunters, mages and warlocks show "DPS"; only healing classes show "DPS/Healer". Classes that can tank get a "Tanking? /pb tank" hint.
- Might is now the last-resort blessing for Mage, Warlock, Priest, Druid and tank Paladin, so they get something instead of nothing.

## v1.0.3

- Fixed "Auras cannot be accessed when secret" errors in combat. While the game hides buffs, PallyBuff keeps the last result for your target, or shows class priority for a target picked mid-fight, and refreshes when combat ends.

## v1.0.2

- Blessing name now sits to the right of the icon so it no longer overlaps the target frame.

## v1.0.1

- Salvation (group-only) is skipped for players outside your group; the next blessing in line is suggested instead.
- Right-click casts the normal blessing on players outside your group, since Greater blessings only reach group members.

## v1.0.0

- First release for WoW Forever.
- Icon button next to the target frame shows the blessing your friendly target needs, by class priority.
- Left-click casts the blessing, right-click casts the Greater version.
- Skips blessings other paladins already cast and blessings you haven't learned; warns when yours is about to expire.
- Tank priorities via `/pb tank <name>`.
