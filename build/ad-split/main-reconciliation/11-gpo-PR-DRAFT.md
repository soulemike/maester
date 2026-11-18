# Draft: AD 11-gpo

Compare: https://github.com/soulemike/maester/compare/split/ad-10-adcs...split/ad-11-gpo?expand=1

Base: `split/ad-10-adcs`. This is an ordered stack; do not open against upstream main until its parent is merged/rebased.

## Scope

- `powershell/internal/services/ad/transport/Get-MtSysvolContent.ps1`
- `powershell/public/services/ad/Get-MtADGpoState.ps1`
- `powershell/tests/ad/transport/Get-MtSysvolContent.Tests.ps1`
- `powershell/tests/functions/ADGpoInventory.Tests.ps1`
- `powershell/tests/functions/ADGpoReports.Tests.ps1`
- `powershell/tests/functions/ActiveDirectoryGpoPermissions.Tests.ps1`
- `tests/ad/gpo-state/Test.AD-GPOREP-01.md`
- `tests/ad/gpo-state/Test.AD-GPOREP-01.ps1`
- `tests/ad/gpo-state/Test.AD-GPOREP-02.md`
- `tests/ad/gpo-state/Test.AD-GPOREP-02.ps1`
- `tests/ad/gpo-state/Test.AD-GPOREP-03.md`
- `tests/ad/gpo-state/Test.AD-GPOREP-03.ps1`
- `tests/ad/gpo-state/Test.AD-GPOREP-04.md`
- `tests/ad/gpo-state/Test.AD-GPOREP-04.ps1`
- `tests/ad/gpo-state/Test.AD-GPOREP-05.md`
- `tests/ad/gpo-state/Test.AD-GPOREP-06.md`
- `tests/ad/gpo-state/Test.AD-GPOREP-07.md`
- `tests/ad/gpo-state/Test.AD-GPOREP-07.ps1`
- `tests/ad/gpo-state/Test.AD-GPOREP-08.md`
- `tests/ad/gpo-state/Test.AD-GPOREP-08.ps1`
- `tests/ad/gpo-state/Test.AD-GPOREP-09.md`
- `tests/ad/gpo-state/Test.AD-GPOREP-10.md`
- `tests/ad/gpo-state/Test.AD-GPOREP-10.ps1`
- `tests/ad/gpo-state/Test.AD-GPOREP-11.md`
- `tests/ad/gpo-state/Test.AD-GPOREP-11.ps1`
- `tests/ad/gpo-state/Test.AD-GPOREP-12.md`
- `tests/ad/gpo-state/Test.AD-GPOREP-12.ps1`
- `tests/ad/gpo-state/Test.AD-GPOREP-13.md`
- `tests/ad/gpo-state/Test.AD-GPOREP-13.ps1`
- `tests/ad/gpo-state/Test.AD-GPOREP-14.md`
- `tests/ad/gpo-state/Test.AD-GPOREP-15.md`
- `tests/ad/gpo-state/Test.AD-GPOREP-15.ps1`
- `tests/ad/gpo-state/Test.AD-GPOREP-16.md`
- `tests/ad/gpo-state/Test.AD-GPOREP-16.ps1`
- `tests/ad/gpo-state/Test.AD-GPOREP-17.md`
- `tests/ad/gpo-state/Test.AD-GPOREP-17.ps1`
- `tests/ad/gpo-state/Test.AD-GPOREP-18.md`
- `tests/ad/gpo-state/Test.AD-GPOREP-18.ps1`
- `tests/ad/gpo-state/Test.AD-GPOREP-19.md`
- `tests/ad/gpo-state/Test.AD-GPOREP-19.ps1`
- `tests/ad/gpo-state/Test.AD-GPOREP-20.md`
- `tests/ad/gpo-state/Test.AD-GPOREP-20.ps1`
- `tests/ad/gpo-state/Test.AD-GPOS-01.md`
- `tests/ad/gpo-state/Test.AD-GPOS-02.md`
- `tests/ad/gpo-state/Test.AD-GPOS-03.md`
- `tests/ad/gpo-state/Test.AD-GPOS-04.md`
- `tests/ad/gpo-state/Test.AD-GPOS-05.md`
- `tests/ad/gpo-state/Test.AD-GPOS-06.md`
- `tests/ad/gpo-state/Test.AD-GPOS-07.md`
- `tests/ad/gpo-state/Test.AD-GPOS-08.md`
- `tests/ad/gpo-state/Test.AD-GPOS-09.md`
- `tests/ad/gpo/Test.AD-GPO-01.md`
- `tests/ad/gpo/Test.AD-GPO-01.ps1`
- `tests/ad/gpo/Test.AD-GPO-02.md`
- `tests/ad/gpo/Test.AD-GPO-02.ps1`
- `tests/ad/gpo/Test.AD-GPO-03.md`
- `tests/ad/gpo/Test.AD-GPO-03.ps1`
- `tests/ad/gpo/Test.AD-GPO-04.md`
- `tests/ad/gpo/Test.AD-GPO-04.ps1`
- `tests/ad/gpo/Test.AD-GPO-05.md`
- `tests/ad/gpo/Test.AD-GPO-05.ps1`
- `tests/ad/gpo/Test.AD-GPOL-01.md`
- `tests/ad/gpo/Test.AD-GPOL-02.md`
- `tests/ad/gpo/Test.AD-GPOL-02.ps1`
- `tests/ad/gpo/Test.AD-GPOL-03.md`
- `tests/ad/gpo/Test.AD-GPOL-03.ps1`
- `tests/ad/gpo/Test.AD-GPOL-04.md`
- `tests/ad/gpo/Test.AD-GPOL-04.ps1`
- `tests/ad/gpo/Test.AD-GPOL-05.md`
- `tests/ad/gpo/Test.AD-GPOL-05.ps1`
- `tests/ad/gpo/Test.AD-GPOL-06.md`
- `tests/ad/gpo/Test.AD-GPOL-06.ps1`

## Migration status

Original source: `bf1709daaf89373886caf332e1dcd68fc91af528`. Current fork/upstream main: `512a076de7bb173045a2ebe62b0493d613ddd0b5`. Nonconflicted source changes use the three-way merged tree, preserving main changes. Conflicted chains remain main versions and are staged in the separate reconciliation branch. No claims that issues #2796 or #2405 are fully fixed.

## Review blockers

- Per-branch validation pending; historical full-suite results do not validate this migration.
- Review open-PR overlap matrix in the master packet.
- Redirects/global acceptance changes arrive in the final catalog/docs branch; do not deploy intermediate retirements without URL compatibility.
- GitHub CLI authentication unavailable: this is a local draft body, not a published PR.

## Actual migration validation

BLOCKED (exit 1).

- [-] AD-CFG-22: KDS root key count.Skips when zero KDS root keys are found 501ms (471ms|30ms)
- [-] AD-CFG-22: KDS root key count.Investigates when exactly two KDS root keys exist 67ms (65ms|2ms)
- [-] Active Directory test source safety.Routes every public AD test command through a guarded collector before any AD operation 1.96s (1.96s|1ms)
- [-] Windows LAPS readiness accepts the production dictionary state.passes with an ordered dictionary, not only a PSCustomObject fixture 65ms (62ms|3ms)
- [-] Benchmark of the tests shipped with Maester.Carries Benchmark as null on every other test 21ms (20ms|1ms)

Log: `TestResults/ad-split/validation.log`.

## Validation job stopped

Authoritative state: **BLOCKED**. The parent validation shell ended with `Shell.NotFoundError`; no process remains. No automatic restart or supplemental run occurred. Read `MERGE-REVIEW.md` for recorded blockers.
