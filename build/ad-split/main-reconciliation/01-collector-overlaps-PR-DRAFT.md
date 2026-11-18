# Draft: AD 01-collector-overlaps

Compare: https://github.com/soulemike/maester/compare/split/ad-00-foundation...split/ad-01-collector-overlaps?expand=1

Base: `split/ad-00-foundation`. This is an ordered stack; do not open against upstream main until its parent is merged/rebased.

## Scope

- `powershell/internal/services/ad/queries/Get-MtLdapConfigurationContainer.ps1`
- `powershell/internal/services/ad/queries/Get-MtLdapServiceAccount.ps1`
- `powershell/public/services/ad/Get-MtADDomainState.ps1`
- `powershell/tests/functions/ADCollectorQueries.Tests.ps1`
- `powershell/tests/functions/ADSecondBatchCollectors.Tests.ps1`

## Migration status

Original source: `bf1709daaf89373886caf332e1dcd68fc91af528`. Current fork/upstream main: `512a076de7bb173045a2ebe62b0493d613ddd0b5`. Nonconflicted source changes use the three-way merged tree, preserving main changes. Conflicted chains remain main versions and are staged in the separate reconciliation branch. No claims that issues #2796 or #2405 are fully fixed.

## Review blockers

- Per-branch validation pending; historical full-suite results do not validate this migration.
- Review open-PR overlap matrix in the master packet.
- Redirects/global acceptance changes arrive in the final catalog/docs branch; do not deploy intermediate retirements without URL compatibility.
- GitHub CLI authentication unavailable: this is a local draft body, not a published PR.

## Actual migration validation

BLOCKED (exit 1).

- [-] Active Directory test source safety.Routes every public AD test command through a guarded collector before any AD operation 3.35s (3.35s|1ms)
- [-] Windows LAPS readiness accepts the production dictionary state.passes with an ordered dictionary, not only a PSCustomObject fixture 129ms (129ms|1ms)

Log: `TestResults/ad-split/validation.log`.

## Validation job stopped

Authoritative state: **BLOCKED**. The parent validation shell ended with `Shell.NotFoundError`; no process remains. No automatic restart or supplemental run occurred. Read `MERGE-REVIEW.md` for recorded blockers.
