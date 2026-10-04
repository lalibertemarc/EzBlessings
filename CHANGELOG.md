# PallyBuff

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
