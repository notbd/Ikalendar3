# splatoon3.ink as the only data source, with a last-known-good cache

Every surface reads Splatoon 3 schedules from splatoon3.ink's public JSON and from nothing else. It is the only live source that needs no key or Nintendo Account; its JSON is Nintendo's own SplatNet 3 response, lightly post-processed. Because that pipeline depends on one Nintendo login and has stalled (the hourly archive misses 784 of 17,526 hours between 2024-11-01 and 2026-11-01, the longest gap 81 hours), every surface keeps the last good response, shows when it was fetched and treats stale data as a normal state rather than an error. The source's terms ask that any product using its data be free of charge, so ikalendar 3 has no ads, in-app purchases or tips, and it credits splatoon3.ink. Decided with the owner on 2026-11-01 ([ticket 13](../../.scratch/ikalendar3/issues/13-data-source-cache-refresh.md)); the evidence is research 02.

## Considered Options

- Query SplatNet 3 directly with the user's Nintendo Account: first-hand data, but it needs the user's login, a third-party token service and carries a ban risk.
- Add JelonzoBot as a fallback: it is live, but it calls itself unstable and runs on the same nxapi login path, so it tends to fail at the same moments.
- Bundle a static table of past schedules: no help, because rotations are published only about a day ahead.
