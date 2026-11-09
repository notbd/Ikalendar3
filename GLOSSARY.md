# ikalendar 3

ikalendar 3 shows Splatoon 3's public schedules: which battles and Salmon Run Shifts are on now and next, on the iPhone, iPad, Mac and Apple Watch. These are the words its code, docs and tickets use.

## Game structure

**Mode**:
A Battle Mode or Salmon Run, each with a Schedule of its own.
_Avoid_: game mode, category, section (that is a part of the feed)

**Battle Mode**:
A battle matchmaking queue with its own schedule, such as Regular Battle, Anarchy Series, Anarchy Open or X Battle.
_Avoid_: game mode, match type, queue

**Anarchy Series**:
The ranked form of Anarchy Battle, played in sets of games that count toward a rank.
_Avoid_: Anarchy Challenge, ranked (alone)

**Anarchy Open**:
The form of Anarchy Battle that friends can join together, one game at a time.
_Avoid_: casual Anarchy

**X Battle**:
The Battle Mode for the highest ranks, with its own rating.
_Avoid_: X Rank, X Match

**Challenge**:
A limited-time Battle Mode event with its own rules and restrictions, held in several fixed windows on one day.
_Avoid_: event match, league

**Rule**:
The set of rules a battle is played under, which fixes its objective, how it plays and how its Stage is laid out: Turf War, Splat Zones, Tower Control, Rainmaker or Clam Blitz.
_Avoid_: mode (for a Rule), game type

**Stage**:
A map that battles or Salmon Run Shifts are played on.
_Avoid_: map, arena, level

**King Salmonid**:
The boss that can appear at the end of a Salmon Run Shift: Cohozuna, Horrorboros, Megalodontia or Triumvirate.
_Avoid_: boss (alone), king

## Time

**Rotation**:
A fixed window during which one Battle Mode runs one Rule on its Stages.
_Avoid_: slot, schedule (for a single window), round

**Shift**:
A Salmon Run window with one Stage and one set of four weapons.
_Avoid_: rotation (for Salmon Run), job

**Schedule**:
The ordered list of Rotations or Shifts published for one Battle Mode or for Salmon Run.
_Avoid_: timetable, calendar, rotation list

**Splatfest**:
A time-limited community event in which players pick one of three teams, with its own battles while it runs.
_Avoid_: fest, festival (except when quoting the data source)

**Splatfest Battle**:
The Battle Mode that replaces Regular Battle, Anarchy Battle and X Battle while a Splatfest runs, in Open and Pro forms.
_Avoid_: fest battle, Splatfest mode

**Tricolor Turf War**:
A three-team Turf War played during the second half of a Splatfest.
_Avoid_: Tricolor Battle, tri-color

**Big Run**:
A Salmon Run held on a battle Stage for 48 hours.
_Avoid_: big run event, raid

**Eggstra Work**:
A 48-hour Salmon Run contest on one Stage with fixed weapons, scored by the Golden Eggs collected.
_Avoid_: egg contest, Eggstra Work shift (for the whole event)

## Product

**Surface**:
Any place outside or inside the app that shows schedule data: an app screen, a widget, a Live Activity, a watch complication, a Siri answer. CarPlay is not a surface: it only shows the widgets and Live Activities the system puts there.
_Avoid_: extension (that is a build target), view

**Tracking**:
Following one Battle Mode or Salmon Run in a Live Activity, from the moment the user starts it until it ends.
_Avoid_: pinning, following, subscribing

**Style**:
One of three looks the user picks in Settings for the app's own screens: Classic, Ink or Timeline. Widgets, Live Activities and the watch always use Ink.
_Avoid_: theme, skin, layout

**Support site**:
The public website shared by the ikalendar apps, carrying each app's home page, support page and privacy policy.
_Avoid_: landing page, homepage (for the whole site), docs

## Data

**Section**:
A part of the schedules feed that decodes on its own: one Battle Mode's Rotations, the Challenges, Salmon Run's regular Shifts and Big Runs, the Eggstra Works, or the current Splatfest. A Section that fails is empty and reported; the others stay intact.
_Avoid_: part, block
