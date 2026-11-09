# ikalendar.app split by app, in its own repository

ikalendar 3's support site lives on `ikalendar.app`, ikalendar 2's existing domain, instead of a domain of its own, and every route names its app: ikalendar 3's pages under `/3`, ikalendar 2's under `/2`. Paths without a prefix redirect permanently, `/` to `/3` and `/privacy-policy` to `/2/privacy-policy`, so the links compiled into ikalendar 2's shipped app keep working. The site, with both apps' pages, moves out of the ikalendar 2 repository into its own public repository, `notbd/ikalendar.app`, so it stays where it is when a later app arrives. Decided with the owner on 2026-11-02 ([ticket 31](../../.scratch/ikalendar3/issues/31-release.md)).

## Considered Options

- A new domain, `ikalendar3.app`: matches the app's name and leaves ikalendar 2's site alone, but adds a yearly renewal and splits the name across two domains.
- A subdomain, `3.ikalendar.app`: free, but an unusual address.
- ikalendar 3 at the bare root, with ikalendar 2's policy left at the bare `/privacy-policy`: no redirects, but the unprefixed paths would belong to different apps.
- One privacy policy page for both apps: one URL for both listings, but ikalendar 3's policy would share a page with ikalendar 2's.
- The site in Ikalendar3's `docs/`, as ikalendar 2 does today: no new repository, but ikalendar 2's pages would live in ikalendar 3's repository and move again with the next app.
