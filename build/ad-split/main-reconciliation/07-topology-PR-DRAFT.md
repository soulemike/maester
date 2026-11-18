# Draft: AD 07-topology

Compare: https://github.com/soulemike/maester/compare/split/ad-06-tombstone-overlap...split/ad-07-topology?expand=1

Base: `split/ad-06-tombstone-overlap`. This is an ordered stack; do not open against upstream main until its parent is merged/rebased.

## Scope

- `powershell/internal/checks/ad/ad/Get-MtAdOrganizationalUnitOverview.ps1`
- `powershell/internal/checks/ad/ad/Get-MtAdSiteSubnetOverview.ps1`
- `powershell/internal/checks/ad/ad/Get-MtAdSubnetInventory.ps1`
- `powershell/tests/functions/ADSiteOuBatch.Tests.ps1`
- `tests/ad/ou/Test.AD-OU-01.md`
- `tests/ad/ou/Test.AD-OU-01.ps1`
- `tests/ad/ou/Test.AD-OU-02.md`
- `tests/ad/ou/Test.AD-OU-02.ps1`
- `tests/ad/ou/Test.AD-OU-03.md`
- `tests/ad/ou/Test.AD-OU-03.ps1`
- `tests/ad/ou/Test.AD-OU-04.md`
- `tests/ad/ou/Test.AD-OU-04.ps1`
- `tests/ad/ou/Test.AD-OU-05.md`
- `tests/ad/ou/Test.AD-OU-05.ps1`
- `tests/ad/printer/Test.AD-PRINT-01.md`
- `tests/ad/printer/Test.AD-PRINT-01.ps1`
- `tests/ad/replication/Test.AD-DFSR-01.md`
- `tests/ad/replication/Test.AD-FEAT-01.md`
- `tests/ad/replication/Test.AD-FEAT-01.ps1`
- `tests/ad/replication/Test.AD-FEAT-02.md`
- `tests/ad/replication/Test.AD-FEAT-02.ps1`
- `tests/ad/replication/Test.AD-REPL-01.md`
- `tests/ad/replication/Test.AD-REPL-02.md`
- `tests/ad/replication/Test.AD-ROOTDSE-01.md`
- `tests/ad/replication/Test.AD-ROOTDSE-01.ps1`
- `tests/ad/replication/Test.AD-ROOTDSE-02.md`
- `tests/ad/replication/Test.AD-ROOTDSE-02.ps1`
- `tests/ad/replication/Test.AD-ROOTDSE-03.md`
- `tests/ad/site/Test.AD-SITE-01.md`
- `tests/ad/site/Test.AD-SITE-01.ps1`
- `tests/ad/site/Test.AD-SITE-02.md`
- `tests/ad/site/Test.AD-SITE-02.ps1`
- `tests/ad/site/Test.AD-SITE-03.md`
- `tests/ad/site/Test.AD-SITE-03.ps1`
- `tests/ad/site/Test.AD-SITE-04.md`
- `tests/ad/site/Test.AD-SITE-04.ps1`
- `tests/ad/site/Test.AD-SITE-05.md`
- `tests/ad/site/Test.AD-SITE-05.ps1`
- `tests/ad/site/Test.AD-SUB-01.md`
- `tests/ad/site/Test.AD-SUB-01.ps1`
- `tests/ad/site/Test.AD-SUB-02.md`
- `tests/ad/site/Test.AD-SUB-02.ps1`
- `tests/ad/site/Test.AD-SUB-03.md`
- `tests/ad/site/Test.AD-SUB-03.ps1`
- `tests/ad/site/Test.AD-SUB-04.md`
- `tests/ad/site/Test.AD-SUB-04.ps1`
- `tests/ad/site/Test.AD-SUB-05.md`
- `tests/ad/site/Test.AD-SUB-05.ps1`
- `tests/ad/site/Test.AD-SUB-06.md`
- `tests/ad/site/Test.AD-SUB-06.ps1`
- `tests/ad/site/Test.AD-SUB-07.md`
- `tests/ad/site/Test.AD-SUB-07.ps1`
- `tests/ad/site/Test.AD-SUB-08.md`
- `tests/ad/site/Test.AD-SUB-08.ps1`
- `tests/ad/site/Test.AD-SUB-09.md`
- `tests/ad/site/Test.AD-SUB-09.ps1`
- `tests/ad/site/Test.AD-SUB-10.md`
- `tests/ad/site/Test.AD-SUB-10.ps1`
- `tests/ad/site/Test.AD-SUB-11.md`
- `tests/ad/site/Test.AD-SUB-11.ps1`

## Migration status

Original source: `bf1709daaf89373886caf332e1dcd68fc91af528`. Current fork/upstream main: `512a076de7bb173045a2ebe62b0493d613ddd0b5`. Nonconflicted source changes use the three-way merged tree, preserving main changes. Conflicted chains remain main versions and are staged in the separate reconciliation branch. No claims that issues #2796 or #2405 are fully fixed.

## Review blockers

- Per-branch validation pending; historical full-suite results do not validate this migration.
- Review open-PR overlap matrix in the master packet.
- Redirects/global acceptance changes arrive in the final catalog/docs branch; do not deploy intermediate retirements without URL compatibility.
- GitHub CLI authentication unavailable: this is a local draft body, not a published PR.

## Actual migration validation

BLOCKED (exit 1).

- [-] Active Directory test source safety.Routes every public AD test command through a guarded collector before any AD operation 2.37s (2.36s|6ms)
- [-] Windows LAPS readiness accepts the production dictionary state.passes with an ordered dictionary, not only a PSCustomObject fixture 65ms (63ms|3ms)
- [-] Benchmark of the tests shipped with Maester.Carries Benchmark as null on every other test 40ms (39ms|2ms)

Log: `TestResults/ad-split/validation.log`.

## Validation job stopped

Authoritative state: **BLOCKED**. The parent validation shell ended with `Shell.NotFoundError`; no process remains. No automatic restart or supplemental run occurred. Read `MERGE-REVIEW.md` for recorded blockers.
