# EzBlessings

*None go unblessed.*

A WoW Forever addon for paladins. Target a friendly player and EzBlessings shows the blessing that player needs, picked by their class and role. Click the icon to cast it.

## The Three Virtues

Paladin lore rests on the Three Virtues of the Light that Uther the Lightbringer taught the Silver Hand: **Respect**, **Tenacity** and **Compassion**. EzBlessings is built around the third one. Everyone deserves the Light's blessing, so the addon always finds something to give:

- **Every class gets something.** When a class has no real use for any blessing left, it still gets Might as a last resort instead of nothing.
- **Every level gets something.** A low-level player who can't take the top rank gets the highest rank their level allows instead of nothing.

The paladin is the hand that always gives.

## Features

- **One-click blessing**: an icon next to the target frame shows the blessing to cast. Left-click casts it on your target, right-click casts the Greater version if you know it.
- **Class priorities**: warriors and rogues get Might first, mages, warlocks and priests get Wisdom first, druids, paladins, shamans and hunters get Kings first, and so on.
- **Tank mode**: mark tanks with `/ezb tank <name>` and they get Kings/Might priority, never Salvation.
- **Right rank for low levels**: casts the highest rank the target's level allows, so low-level players don't get "target too low" errors. The tooltip shows which rank will be cast.
- **Aware of other paladins**: blessings another paladin already cast are skipped, so you suggest the next one down.
- **Refresh warnings**: the border turns yellow when your blessing on the target has under 20 minutes left.
- **Range warning**: the icon turns red when the target is out of range of the blessing.
- **Full breakdown on hover**: the tooltip lists the target's whole priority, who cast what, and time left.
- **Works in any client language.**

## Install

Install from CurseForge or Wago, or download the zip from the [Releases](../../releases) page and extract the `EzBlessings` folder into:

```
World of Warcraft\_classic_beta_\Interface\AddOns\
```

## Commands

Use `/ezb` or `/ezblessings`.


| Command | Does |
|---|---|
| `/ezb tank [name]` | Mark a player (or your target) as a tank |
| `/ezb untank [name]` | Unmark a tank |
| `/ezb tanks` | List marked tanks |
| `/ezb lock` / `/ezb unlock` | Lock or unlock the button (Shift-drag always moves it) |
| `/ezb reset` | Reset the button position |
| `/ezb instances` | Toggle hiding the button in dungeons and raids (hidden by default, since the game hides buffs there) |

## Default priorities

| Class | Priority |
|---|---|
| Warrior, Rogue | Might > Kings > Salvation > Light |
| Hunter | Kings > Wisdom > Salvation > Might |
| Mage, Warlock, Priest | Wisdom > Kings > Salvation > Light > Might |
| Druid | Kings > Wisdom > Salvation > Light > Might |
| Paladin, Shaman | Kings > Wisdom > Might > Light |
| Warrior, Druid (tank) | Kings > Might > Light |
| Paladin (tank) | Kings > Wisdom > Light > Might |

To change them, edit `Data.lua`.

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

The packager fills in `## Version` from the tag and reads `## Interface: 16001` as the Forever game version.

## License

MIT
