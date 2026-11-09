# Three switchable styles for the app's screens

ikalendar 3 ships three complete visual styles for its own screens and lets the user pick one in Settings: Classic keeps ikalendar 2's look, Ink puts ikalendar 2's layout on the game's dotted backgrounds, torn panels and taped labels, and Timeline follows SplatNet 3's schedule page. Ink is the default. The owner wanted all three after seeing them side by side, so the screen code is split into a shared part (data, time logic, VoiceOver sentences) and a thin per-style view layer that is swapped as a whole. Widgets, Live Activities, complications and the Apple Watch app use Ink only, because three versions of every small system surface would roughly triple their design and testing for little visible difference. Every style keeps the native Liquid Glass tab bar and meets the same accessibility commitments. Decided with the owner on 2026-11-09 ([ticket 15](../../.scratch/ikalendar3/issues/15-visual-adaptation.md)).

## Consequences

- Every new app screen is designed, built and reviewed three times.
- A style never changes what a screen shows or how it behaves, only how it looks, so tests of the shared part cover all three.
