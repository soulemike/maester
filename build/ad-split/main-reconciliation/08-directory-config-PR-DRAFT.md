# Draft: AD 08-directory-config

Compare: https://github.com/soulemike/maester/compare/split/ad-07-topology...split/ad-08-directory-config?expand=1

Base: `split/ad-07-topology`. This is an ordered stack; do not open against upstream main until its parent is merged/rebased.

## Scope

- `tests/ad/config/Test.AD-CFG-01.md`
- `tests/ad/config/Test.AD-CFG-01.ps1`
- `tests/ad/config/Test.AD-CFG-02.md`
- `tests/ad/config/Test.AD-CFG-02.ps1`
- `tests/ad/config/Test.AD-CFG-03.md`
- `tests/ad/config/Test.AD-CFG-03.ps1`
- `tests/ad/config/Test.AD-CFG-04.md`
- `tests/ad/config/Test.AD-CFG-04.ps1`
- `tests/ad/config/Test.AD-CFG-05.md`
- `tests/ad/config/Test.AD-CFG-05.ps1`
- `tests/ad/config/Test.AD-CFG-06.md`
- `tests/ad/config/Test.AD-CFG-06.ps1`
- `tests/ad/config/Test.AD-CFG-07.md`
- `tests/ad/config/Test.AD-CFG-07.ps1`
- `tests/ad/config/Test.AD-CFG-09.md`
- `tests/ad/config/Test.AD-CFG-09.ps1`
- `tests/ad/config/Test.AD-CFG-10.md`
- `tests/ad/config/Test.AD-CFG-10.ps1`
- `tests/ad/config/Test.AD-CFG-11.md`
- `tests/ad/config/Test.AD-CFG-11.ps1`
- `tests/ad/config/Test.AD-CFG-22.md`
- `tests/ad/config/Test.AD-CFG-22.ps1`
- `tests/ad/config/Test.AD-CFG-23.md`
- `tests/ad/config/Test.AD-CFG-23.ps1`
- `tests/ad/config/Test.AD-CFG-24.md`
- `tests/ad/config/Test.AD-CFG-24.ps1`

## Migration status

Original source: `bf1709daaf89373886caf332e1dcd68fc91af528`. Current fork/upstream main: `512a076de7bb173045a2ebe62b0493d613ddd0b5`. Nonconflicted source changes use the three-way merged tree, preserving main changes. Conflicted chains remain main versions and are staged in the separate reconciliation branch. No claims that issues #2796 or #2405 are fully fixed.

## Review blockers

- Per-branch validation pending; historical full-suite results do not validate this migration.
- Review open-PR overlap matrix in the master packet.
- Redirects/global acceptance changes arrive in the final catalog/docs branch; do not deploy intermediate retirements without URL compatibility.
- GitHub CLI authentication unavailable: this is a local draft body, not a published PR.

## Actual migration validation

BLOCKED (exit 1).

- [-] AD-CFG-22: KDS root key count.Skips when zero KDS root keys are found 587ms (559ms|28ms)
- [-] AD-CFG-22: KDS root key count.Investigates when exactly two KDS root keys exist 43ms (41ms|2ms)
- [-] Active Directory test source safety.Routes every public AD test command through a guarded collector before any AD operation 2.43s (2.43s|2ms)
- [-] Windows LAPS readiness accepts the production dictionary state.passes with an ordered dictionary, not only a PSCustomObject fixture 63ms (58ms|5ms)
- [-] Benchmark of the tests shipped with Maester.Carries Benchmark as null on every other test 77ms (73ms|3ms)

Log: `TestResults/ad-split/validation.log`.

## Validation job stopped

Authoritative state: **BLOCKED**. The parent validation shell ended with `Shell.NotFoundError`; no process remains. No automatic restart or supplemental run occurred. Read `MERGE-REVIEW.md` for recorded blockers.
