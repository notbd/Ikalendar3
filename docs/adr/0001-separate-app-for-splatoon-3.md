# Separate app for Splatoon 3

ikalendar 3 ships as its own App Store app, `ikalendar3` with bundle ID `io.tianwei.ikalendar3`, instead of an update that teaches ikalendar 2 a second game. Splatoon 3 has more modes, a different data source and new surfaces (widgets, Live Activities, watch), so a fresh codebase avoids carrying Splatoon 2 assumptions, and ikalendar 2's users keep an app that keeps working for the game they play. Decided with the owner on 2026-11-01 ([ticket 08](../../.scratch/ikalendar3/issues/08-product-identity.md)).

## Considered Options

- Update ikalendar 2 to cover both games: one listing, but every model, decoder and screen would branch on the game.
- Drop the number and call it `ikalendar`: future-proof, but easy to confuse with the existing ikalendar2 listing, and the App Store name may be taken.
