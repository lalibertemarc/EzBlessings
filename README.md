# PallyBuff

A WoW Forever addon for paladins. Target a friendly player and PallyBuff shows the blessing that player needs, picked by their class and role. Click the icon to cast it.

## Features

- **One-click blessing**: an icon next to the target frame shows the blessing to cast. Left-click casts it on your target, right-click casts the Greater version if you know it.
- **Class priorities**: warriors and rogues get Might first, casters and healers get Wisdom first, hunters get Kings first, and so on.
- **Tank mode**: mark tanks with `/pb tank <name>` and they get Kings/Might priority, never Salvation.
- **Right rank for low levels**: casts the highest rank the target's level allows, so low-level players don't get "target too low" errors. The tooltip shows which rank will be cast.
- **Aware of other paladins**: blessings another paladin already cast are skipped, so you suggest the next one down.
- **Refresh warnings**: the border turns yellow when your blessing on the target has under 5 minutes left.
- **Full breakdown on hover**: the tooltip lists the target's whole priority, who cast what, and time left.
- **Works in any client language.**

## Install

Install from CurseForge or Wago, or download the zip from the [Releases](../../releases) page and extract the `PallyBuff` folder into:

```
World of Warcraft\_classic_beta_\Interface\AddOns\
```

## Commands

| Command | Does |
|---|---|
| `/pb tank [name]` | Mark a player (or your target) as a tank |
| `/pb untank [name]` | Unmark a tank |
| `/pb tanks` | List marked tanks |
| `/pb lock` / `/pb unlock` | Lock or unlock the button (Shift-drag always moves it) |
| `/pb reset` | Reset the button position |

## Default priorities

| Class | Priority |
|---|---|
| Warrior, Rogue | Might > Kings > Salvation > Light |
| Hunter | Kings > Wisdom > Salvation > Might |
| Mage, Warlock, Priest, Druid | Wisdom > Kings > Salvation > Light > Might |
| Paladin | Wisdom > Kings > Might > Light |
| Shaman | Wisdom > Kings > Might > Light |
| Warrior, Druid (tank) | Kings > Might > Light |
| Paladin (tank) | Kings > Wisdom > Light > Might |

To change them, edit `Data.lua`.

## In combat

The game doesn't let addons change what a button casts during combat. If the right blessing changes mid-fight, the icon turns grey with a red border, and the button catches up when combat ends.

## Releasing (maintainer notes)

Releases are built by the [BigWigs packager](https://github.com/BigWigsMods/packager) through GitHub Actions (`.github/workflows/release.yml`).

1. Create the projects on CurseForge and/or Wago, then add their IDs to `PallyBuff.toc`:
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
