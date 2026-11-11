# Ink's light board, the tab bar's tint and the app accent

Three look decisions of the iPhone look pass that the code alone does not explain.

**Ink lies on the game's grey board in light appearance.** Ink used to stay black in light appearance while the system's glass turned light, so the screen and its bars disagreed. Ink now draws the game's Stages board: dark panels (#383838) on grey paper (#969793) in light appearance, the same panels on black in dark appearance. Widgets, the Live Activity and the watch keep the black ground.

**The selected tab takes its Mode's colour, at the nearest tint that reads.** ikalendar 2 tinted the selected tab in the Mode's colour, and ikalendar 3 does the same with the nearest tint that reaches 4.5:1 on the glass measured for the Style and appearance. Two cases have no tint that reads and still looks like the Mode's colour. Over Ink's grey board in light appearance the label is the primary colour and only the icon carries the Mode's colour, at 3:1. Over Timeline, whose page stays dark in both appearances, the tab bar is dark in both. The Splatfest tab is the primary colour: Splatfest Battle has no colour of its own, and a team's colour would favour that team.

**Settings, About, Credits and the welcome screen use ikalendar 2's orange.** Fills (the Get Started button, a switch that is on, the app icon's stand-in) take the orange under a dark label. Tinted text and glyphs take a darker tone in light appearance (#A25F00), since the orange itself reads only 2.2:1 on white.

On iPhone the Settings and Track buttons sit at the leading end, as in ikalendar 2, which leaves the trailing end to the Mode stamp in every Style.

Decided during the iPhone look pass on 2026-11-11, for the owner to confirm with the result.

## Consequences

- The glass colours are measured from simulator captures and pinned by `SelectedTabColorTests`. A system release that changes the glass needs a new measurement.
- Ink's light board and its tab rule are one decision: if Ink goes back to black in light appearance, its tab rule changes with it.
