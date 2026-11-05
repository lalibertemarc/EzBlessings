# EzBlessings

*None go unblessed.*

A WoW Forever and Classic Era addon for paladins. Target a friendly player and EzBlessings shows the blessing that player needs, picked by their class and role. Click the icon to cast it.

## The Three Virtues

Paladin lore rests on the Three Virtues of the Light that Uther the Lightbringer taught the Silver Hand: **Respect**, **Tenacity** and **Compassion**. EzBlessings is built around the third one. Everyone deserves the Light's blessing, so the addon always finds something to give:

- **Every class gets something.** When a class has no real use for any blessing left, it still gets Might as a last resort instead of nothing.
- **Every level gets something.** A low-level player who can't take the top rank gets the highest rank their level allows instead of nothing.
- **Every target gets something.** When other paladins already cover every blessing, you're offered a refresh of the most wanted one instead of nothing.

The paladin is the hand that always gives. Almost always: see `/ezb olympus`.

## Features

- **One-click blessing**: an icon next to the target frame shows the blessing to cast. Left-click casts it on your target, right-click casts the Greater version if you know it.
- **Class priorities**: warriors and rogues get Might first, mages and priests get Wisdom first, druids, paladins, shamans, hunters and warlocks get Kings first, and so on.
- **Tank mode**: mark tanks with `/ezb tank <name>` and they get Kings/Might priority, never Salvation.
- **Right rank for low levels**: casts the highest rank the target's level allows, so low-level players don't get "target too low" errors. The tooltip shows which rank will be cast.
- **Aware of other paladins**: blessings another paladin already cast are skipped, so you suggest the next one down. If they've covered everything, the button offers to refresh the top-priority one.
- **Refresh warnings**: the border turns yellow when your blessing on the target has under 20 minutes left (2 minutes in Classic Era, where blessings last 5).
- **Range warning**: the icon turns red when the target is out of range of the blessing.
- **Announce your blessings** (optional): say a line in /say or whisper it to the target when you cast, picked at random from about 100 built-in lines plus your own.
- **Accents** (per character): announce in a dwarf, orc, troll or undead accent, light or thick, respelled live. Dwarves speak in their own accent by default.
- **Full breakdown on hover**: the tooltip lists the target's whole priority, who cast what, and time left.
- **Works in any client language.**

## Install

Install from CurseForge or Wago, or download the zip from the [Releases](../../releases) page and extract the `EzBlessings` folder into:

```
World of Warcraft\_classic_beta_\Interface\AddOns\
```

## Options

Type `/ezb` (or open Esc > Options > AddOns > EzBlessings) for the options page, laid out like our other addons' (Blizzard's settings list):

- **Announce**: a dropdown (Off, /say, Whisper), "Use only my lines", and an Edit button for **Your lines**.
- **Your character**: Accent dropdown (By race, the default: dwarves speak dwarf, everyone else plainly; None, Orc, Troll, Dwarf or Undead), Thick accent, and Preview, which prints a few lines to your chat as they could go out on your target.
- **Button**: lock position, hide in dungeons and raids (Forever only), withhold blessings from the unworthy, Reset position, and a shortcut to the Key Bindings page.

**Your lines** is a subpage (also under EzBlessings in the list on the left): type a line and click Add (or press Enter); each one in the list has a Remove button. `%t` is the target's full name (a class-colored player link in your own chat), `%b` the blessing cast. "Try a line" shows a random line as it would go out on your target.

## Commands

Use `/ezb` or `/ezblessings`. `/ezb` alone opens the options page; `/ezb help` lists the commands.


| Command | Does |
|---|---|
| `/ezb tank [name]` | Mark a player (or your target) as a tank |
| `/ezb untank [name]` | Unmark a tank |
| `/ezb tanks` | List marked tanks |
| `/ezb lock` / `/ezb unlock` | Lock or unlock the button (Shift-drag always moves it) |
| `/ezb reset` | Reset the button position |
| `/ezb instances` | Toggle hiding the button in dungeons and raids (hidden by default, since the game hides buffs there) |
| `/ezb olympus` | Toggle skipping players whose guild name contains "Olympus" (off by default). The button shows "Unworthy" and casts nothing on them. With OlympusMute installed, its guild list, guild whitelist, player lists and name keywords are used; otherwise edit the list in `Data.lua` |
| `/ezb announce off \| say \| whisper` | Say a line in /say, or whisper it to the target, when you bless them from the button or a key binding (off by default) |
| `/ezb message` | List your own announce lines |
| `/ezb message add <text>` | Add a line. `%t` is replaced by the target's full name, `%b` by the blessing cast |
| `/ezb message remove <n>` / `/ezb message clear` | Remove one of your lines, or all of them |
| `/ezb message mine` | Toggle using only your lines instead of mixing them in with the built-in ones |
| `/ezb message test` | Show a line as it could go out on your target now |
| `/ezb accent [race\|none\|orc\|troll\|dwarf\|undead]` | Show or set this character's accent, with a sample |
| `/ezb thick [on\|off]` | Thicker accent for this character (undead: jawless); alone, it switches |

## Default priorities

| Class | Priority |
|---|---|
| Warrior, Rogue | Might > Kings > Salvation > Light |
| Hunter | Kings > Wisdom > Salvation > Might |
| Mage, Priest | Wisdom > Kings > Salvation > Light > Might |
| Warlock | Kings > Wisdom > Might > Salvation > Light |
| Druid | Kings > Wisdom > Salvation > Light > Might |
| Paladin, Shaman | Kings > Wisdom > Might > Light |
| Warrior, Druid (tank) | Kings > Might > Light |
| Paladin (tank) | Kings > Wisdom > Light > Might |
| Warrior, Druid (tank), Classic Era | Kings > Might > Sanctuary > Light |
| Paladin (tank), Classic Era | Kings > Sanctuary > Wisdom > Light > Might |

To change them, edit `Data.lua`.

## Classic Era

The same addon loads in Classic Era (1.15.9). There, Kings and Sanctuary are Protection talents: if you didn't take them, they show as "not learned" and the next blessing in line is suggested. Blessing of Sanctuary exists only there, for tanks. Buffs aren't hidden in dungeons and raids, so the button always shows there (no "Hide in dungeons and raids" option), and players from another realm are named "Name-Realm".

## Announcing

Each announce is one line picked at random (never the same twice in a row) from `Lines.lua`: 40 general lines, plus 5 for the blessing being cast and 3 for the target's class. Renewing your own blessing before it drops uses 10 renewal lines instead, and renewing another paladin's (the button's "(refresh)") uses 10 lines that name them (`%p`). With `/ezb olympus` on, clicking an unworthy target says one of 20 respectful refusals that invite them to repent (`ns.UNWORTHY_LINES`), at most once every 10 seconds. Might on a priest, mage or warlock gets 15 lines admitting it does nothing for them (`ns.MIGHT_ON_CASTER_LINES`; the classes are `ns.CASTER_CLASSES` in `Data.lua`). Lines you add with `/ezb message add` are mixed in. Edit `Lines.lua` to change the built-in ones.

Every line, your own included, is respelled live in this character's accent as it goes out, a little different each time: `/ezb accent` (or the options page) picks By race (the default: dwarves speak dwarf, everyone else plainly), None, Orc, Troll, Dwarf or Undead, and `/ezb thick` makes it thicker: heavier dialect ("Och! %t, may the Licht guide ye. Ah grant ye %b, lad."), and for the undead no jaw at all (locked jaw: "Huld fesst, %t. %b will see yuu thruugh. Nnn."; jawless: "%t, I hhrayed hhor you. Hhk. Hhe Light ansh'ered: %b. Hhkk."). A woman hears "lass" where the accent says "lad" (and "sistah" for "bruddah"). The accent works on the line before `%t`, `%b` and `%p` are filled in, so names and the blessing are never respelled; a line the accent would push past 255 characters goes out plain. With [EzAccent](../EzAccent) loaded, changing its accent sets this one to the same accent and thickness (a By race choice that already speaks it is kept); `/ezb accent` still sets this one alone. The rules are EzAccent's: `AccentRules.lua` is generated by its `tools/gen_rules.py --out ../EzBlessings/AccentRules.lua` from AccentTranslator's `rules.py` (don't edit it by hand), and `Accent.lua` is a copy of its engine, byte-identical below its header. `lua tests/lines.lua [print]` (Lua 5.1, also in CI) checks every built-in line in every accent, light and thick.

The line only goes out when you cast from the EzBlessings button or its key bindings (the game only lets addons send chat inside a click or key press), and only when the cast can succeed: never on yourself, and not while mounted, out of range, out of mana or on cooldown. Casts from your action bars stay silent. The game blocks addon chat during some encounters; the announce is skipped there.

## In combat

The game doesn't let addons change what a button casts during combat. If the right blessing changes mid-fight, the icon turns grey with a red border, and the button catches up when combat ends.

## Releasing (maintainer notes)

Releases are built by the [BigWigs packager](https://github.com/BigWigsMods/packager) through GitHub Actions (`.github/workflows/release.yml`).

1. Create the projects on CurseForge and/or Wago, then add their IDs to `EzBlessings.toc`:
   ```
   ## X-Curse-Project-ID: 123456
   ## X-Wago-ID: abcdef12
   ```
2. Add API keys as GitHub repo secrets: `CF_API_KEY` (CurseForge), `WAGO_API_TOKEN` (Wago), and optionally `WOWI_API_TOKEN` (WoWInterface). Sites without a secret are skipped.
3. Update `CHANGELOG.md`, then tag and push:
   ```
   git tag v1.0.0
   git push origin v1.0.0
   ```

The packager fills in `## Version` from the tag and reads `## Interface: 16001, 11509` as the Forever and Classic Era game versions.

## License

MIT
