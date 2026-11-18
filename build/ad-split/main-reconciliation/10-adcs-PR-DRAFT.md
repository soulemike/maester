# Draft: AD 10-adcs

Compare: https://github.com/soulemike/maester/compare/split/ad-09-auth-policy-overlap...split/ad-10-adcs?expand=1

Base: `split/ad-09-auth-policy-overlap`. This is an ordered stack; do not open against upstream main until its parent is merged/rebased.

## Scope

- `powershell/tests/functions/ADCertificateInventoryBatch.Tests.ps1`
- `tests/ad/config/Test.AD-CFG-12.md`
- `tests/ad/config/Test.AD-CFG-12.ps1`
- `tests/ad/config/Test.AD-CFG-13.md`
- `tests/ad/config/Test.AD-CFG-13.ps1`
- `tests/ad/config/Test.AD-CFG-14.md`
- `tests/ad/config/Test.AD-CFG-14.ps1`
- `tests/ad/config/Test.AD-CFG-15.md`
- `tests/ad/config/Test.AD-CFG-15.ps1`
- `tests/ad/config/Test.AD-CFG-16.md`
- `tests/ad/config/Test.AD-CFG-16.ps1`
- `tests/ad/config/Test.AD-CFG-17.md`
- `tests/ad/config/Test.AD-CFG-17.ps1`
- `tests/ad/config/Test.AD-CFG-18.md`
- `tests/ad/config/Test.AD-CFG-18.ps1`
- `tests/ad/config/Test.AD-CFG-19.md`
- `tests/ad/config/Test.AD-CFG-19.ps1`
- `tests/ad/config/Test.AD-CFG-20.md`
- `tests/ad/config/Test.AD-CFG-20.ps1`
- `tests/ad/config/Test.AD-CFG-21.md`
- `tests/ad/config/Test.AD-CFG-21.ps1`

## Migration status

Original source: `bf1709daaf89373886caf332e1dcd68fc91af528`. Current fork/upstream main: `512a076de7bb173045a2ebe62b0493d613ddd0b5`. Nonconflicted source changes use the three-way merged tree, preserving main changes. Conflicted chains remain main versions and are staged in the separate reconciliation branch. No claims that issues #2796 or #2405 are fully fixed.

## Review blockers

- Per-branch validation pending; historical full-suite results do not validate this migration.
- Review open-PR overlap matrix in the master packet.
- Redirects/global acceptance changes arrive in the final catalog/docs branch; do not deploy intermediate retirements without URL compatibility.
- GitHub CLI authentication unavailable: this is a local draft body, not a published PR.

## Actual migration validation

BLOCKED (exit 1).

- [-] AD-CFG-22: KDS root key count.Skips when zero KDS root keys are found 593ms (563ms|30ms)
- [-] AD-CFG-22: KDS root key count.Investigates when exactly two KDS root keys exist 85ms (81ms|4ms)
- [-] Active Directory test source safety.Routes every public AD test command through a guarded collector before any AD operation 3.02s (3.02s|1ms)
- [-] Windows LAPS readiness accepts the production dictionary state.passes with an ordered dictionary, not only a PSCustomObject fixture 55ms (55ms|1ms)
- [-] Benchmark of the tests shipped with Maester.Carries Benchmark as null on every other test 36ms (35ms|1ms)

Log: `TestResults/ad-split/validation.log`.

## Validation job stopped

Authoritative state: **BLOCKED**. The parent validation shell ended with `Shell.NotFoundError`; no process remains. No automatic restart or supplemental run occurred. Read `MERGE-REVIEW.md` for recorded blockers.
