# Draft: AD 12-schema-trust

Compare: https://github.com/soulemike/maester/compare/split/ad-11-gpo...split/ad-12-schema-trust?expand=1

Base: `split/ad-11-gpo`. This is an ordered stack; do not open against upstream main until its parent is merged/rebased.

## Scope

- `tests/ad/schema/Test.AD-SCH-01.md`
- `tests/ad/schema/Test.AD-SCH-01.ps1`
- `tests/ad/schema/Test.AD-SCH-02.md`
- `tests/ad/schema/Test.AD-SCH-02.ps1`
- `tests/ad/schema/Test.AD-SCH-03.md`
- `tests/ad/schema/Test.AD-SCH-03.ps1`
- `tests/ad/schema/Test.AD-SCH-04.md`
- `tests/ad/schema/Test.AD-SCH-04.ps1`
- `tests/ad/schema/Test.AD-SCH-05.md`
- `tests/ad/schema/Test.AD-SCH-05.ps1`
- `tests/ad/trust/Test.AD-TRUST-01.md`
- `tests/ad/trust/Test.AD-TRUST-01.ps1`
- `tests/ad/trust/Test.AD-TRUST-02.md`
- `tests/ad/trust/Test.AD-TRUST-02.ps1`
- `tests/ad/trust/Test.AD-TRUST-03.md`
- `tests/ad/trust/Test.AD-TRUST-03.ps1`
- `tests/ad/trust/Test.AD-TRUST-04.md`
- `tests/ad/trust/Test.AD-TRUST-04.ps1`
- `tests/ad/trust/Test.AD-TRUST-05.md`
- `tests/ad/trust/Test.AD-TRUST-05.ps1`

## Migration status

Original source: `bf1709daaf89373886caf332e1dcd68fc91af528`. Current fork/upstream main: `512a076de7bb173045a2ebe62b0493d613ddd0b5`. Nonconflicted source changes use the three-way merged tree, preserving main changes. Conflicted chains remain main versions and are staged in the separate reconciliation branch. No claims that issues #2796 or #2405 are fully fixed.

## Review blockers

- Per-branch validation pending; historical full-suite results do not validate this migration.
- Review open-PR overlap matrix in the master packet.
- Redirects/global acceptance changes arrive in the final catalog/docs branch; do not deploy intermediate retirements without URL compatibility.
- GitHub CLI authentication unavailable: this is a local draft body, not a published PR.

## Actual migration validation

BLOCKED (exit 1).

- [-] AD-CFG-22: KDS root key count.Skips when zero KDS root keys are found 1s (910ms|93ms)
- [-] AD-CFG-22: KDS root key count.Investigates when exactly two KDS root keys exist 42ms (40ms|2ms)
- [-] Active Directory test source safety.Routes every public AD test command through a guarded collector before any AD operation 1.51s (1.51s|1ms)
- [-] Benchmark of the tests shipped with Maester.Carries Benchmark as null on every other test 21ms (20ms|1ms)

Log: `TestResults/ad-split/validation.log`.

## Validation job stopped

Authoritative state: **BLOCKED**. The parent validation shell ended with `Shell.NotFoundError`; no process remains. No automatic restart or supplemental run occurred. Read `MERGE-REVIEW.md` for recorded blockers.
