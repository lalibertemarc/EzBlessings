# EzBlessings

## Unreleased

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
