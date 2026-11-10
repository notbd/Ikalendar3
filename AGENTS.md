# ikalendar 3

## Agent skills

### Issue tracker

Specs and tickets live in GitHub Issues on `notbd/Ikalendar3`; the planning map stays in local markdown under `.scratch/ikalendar3/`. See `docs/agents/issue-tracker.md`.

### Triage labels

The five default triage labels, each label string equal to its role name. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `GLOSSARY.md` and `docs/adr/` at the repo root. See `docs/agents/domain.md`.

## Build and verify

`CONTRIBUTING.md` covers the tools, `scripts/verify.sh`, the parallel worktree rules (own derived data, own simulators by UDID) and the test naming style. A ticket is done only when `scripts/verify.sh` passes in full.
