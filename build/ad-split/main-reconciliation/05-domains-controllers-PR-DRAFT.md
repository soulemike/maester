# Draft: AD 05-domains-controllers

Compare: https://github.com/soulemike/maester/compare/split/ad-04-computers...split/ad-05-domains-controllers?expand=1

Base: `split/ad-04-computers`. This is an ordered stack; do not open against upstream main until its parent is merged/rebased.

## Scope

- `powershell/internal/checks/ad/ad/Get-MtAdDomainControllerRelease.ps1`
- `powershell/internal/checks/ad/ad/Get-MtAdDomainControllersInScope.ps1`
- `powershell/internal/checks/ad/ad/Get-MtAdDomainNameFindings.ps1`
- `powershell/internal/checks/ad/ad/Get-MtAdFsmoPlacement.ps1`
- `powershell/internal/checks/ad/ad/Get-MtAdFunctionalLevelAssessment.ps1`
- `powershell/tests/functions/ADDomainForestBatch.Tests.ps1`
- `tests/ad/domain-controller/Test.AD-DC-01.md`
- `tests/ad/domain-controller/Test.AD-DC-01.ps1`
- `tests/ad/domain-controller/Test.AD-DC-02.md`
- `tests/ad/domain-controller/Test.AD-DC-03.md`
- `tests/ad/domain-controller/Test.AD-DC-04.md`
- `tests/ad/domain-controller/Test.AD-DC-05.md`
- `tests/ad/domain-controller/Test.AD-DC-05.ps1`
- `tests/ad/domain-controller/Test.AD-DC-06.md`
- `tests/ad/domain-controller/Test.AD-DC-06.ps1`
- `tests/ad/domain-controller/Test.AD-DC-07.md`
- `tests/ad/domain-controller/Test.AD-DC-07.ps1`
- `tests/ad/domain-controller/Test.AD-DC-08.md`
- `tests/ad/domain-controller/Test.AD-DC-08.ps1`
- `tests/ad/domain-controller/Test.AD-DCD-01.md`
- `tests/ad/domain-controller/Test.AD-DCD-01.ps1`
- `tests/ad/domain-controller/Test.AD-DCD-02.md`
- `tests/ad/domain-controller/Test.AD-DCD-02.ps1`
- `tests/ad/domain-controller/Test.AD-DCD-03.md`
- `tests/ad/domain-controller/Test.AD-DCD-03.ps1`
- `tests/ad/domain-controller/Test.AD-DCD-04.md`
- `tests/ad/domain-controller/Test.AD-DCD-04.ps1`
- `tests/ad/domain/Test.AD-DOM-01.md`
- `tests/ad/domain/Test.AD-DOM-01.ps1`
- `tests/ad/domain/Test.AD-DOM-02.md`
- `tests/ad/domain/Test.AD-DOM-02.ps1`
- `tests/ad/domain/Test.AD-DOM-03.md`
- `tests/ad/domain/Test.AD-DOM-03.ps1`
- `tests/ad/domain/Test.AD-DOM-04.md`
- `tests/ad/domain/Test.AD-DOM-04.ps1`
- `tests/ad/domain/Test.AD-DOM-05.md`
- `tests/ad/domain/Test.AD-DOM-05.ps1`
- `tests/ad/domain/Test.AD-DOM-06.md`
- `tests/ad/domain/Test.AD-DOM-06.ps1`
- `tests/ad/domain/Test.AD-DOM-07.md`
- `tests/ad/domain/Test.AD-DOM-07.ps1`
- `tests/ad/domain/Test.AD-DOM-08.md`
- `tests/ad/domain/Test.AD-DOM-08.ps1`
- `tests/ad/domain/Test.AD-DOMS-01.md`
- `tests/ad/domain/Test.AD-DOMS-01.ps1`
- `tests/ad/domain/Test.AD-FOR-01.md`
- `tests/ad/domain/Test.AD-FOR-01.ps1`
- `tests/ad/domain/Test.AD-FOR-02.md`
- `tests/ad/domain/Test.AD-FOR-02.ps1`
- `tests/ad/domain/Test.AD-FOR-04.md`
- `tests/ad/domain/Test.AD-FOR-04.ps1`
- `tests/ad/domain/Test.AD-FORS-01.md`
- `tests/ad/domain/Test.AD-FORS-01.ps1`
- `tests/ad/domain/Test.AD-FORS-02.md`
- `tests/ad/domain/Test.AD-FORS-02.ps1`
- `tests/ad/domain/Test.AD-FORS-03.md`
- `tests/ad/domain/Test.AD-FORS-03.ps1`
- `tests/ad/domain/Test.AD-FORS-04.md`
- `tests/ad/domain/Test.AD-FORS-04.ps1`

## Migration status

Original source: `bf1709daaf89373886caf332e1dcd68fc91af528`. Current fork/upstream main: `512a076de7bb173045a2ebe62b0493d613ddd0b5`. Nonconflicted source changes use the three-way merged tree, preserving main changes. Conflicted chains remain main versions and are staged in the separate reconciliation branch. No claims that issues #2796 or #2405 are fully fixed.

## Review blockers

- Per-branch validation pending; historical full-suite results do not validate this migration.
- Review open-PR overlap matrix in the master packet.
- Redirects/global acceptance changes arrive in the final catalog/docs branch; do not deploy intermediate retirements without URL compatibility.
- GitHub CLI authentication unavailable: this is a local draft body, not a published PR.

## Actual migration validation

BLOCKED (exit 1).

- [-] Active Directory test source safety.Routes every public AD test command through a guarded collector before any AD operation 2.59s (2.58s|4ms)
- [-] Windows LAPS readiness accepts the production dictionary state.passes with an ordered dictionary, not only a PSCustomObject fixture 89ms (88ms|1ms)

Log: `TestResults/ad-split/validation.log`.

## Validation job stopped

Authoritative state: **BLOCKED**. The parent validation shell ended with `Shell.NotFoundError`; no process remains. No automatic restart or supplemental run occurred. Read `MERGE-REVIEW.md` for recorded blockers.
