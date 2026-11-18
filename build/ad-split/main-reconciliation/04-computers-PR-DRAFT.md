# Draft: AD 04-computers

Compare: https://github.com/soulemike/maester/compare/split/ad-03-users-passwords...split/ad-04-computers?expand=1

Base: `split/ad-03-users-passwords`. This is an ordered stack; do not open against upstream main until its parent is merged/rebased.

## Scope

- `powershell/tests/functions/ADComputerChecks.Tests.ps1`
- `tests/ad/computer/Test.AD-COMP-01.md`
- `tests/ad/computer/Test.AD-COMP-01.ps1`
- `tests/ad/computer/Test.AD-COMP-03.md`
- `tests/ad/computer/Test.AD-COMP-03.ps1`
- `tests/ad/computer/Test.AD-COMP-04.md`
- `tests/ad/computer/Test.AD-COMP-04.ps1`
- `tests/ad/computer/Test.AD-COMP-05.md`
- `tests/ad/computer/Test.AD-COMP-05.ps1`
- `tests/ad/computer/Test.AD-COMP-06.md`
- `tests/ad/computer/Test.AD-COMP-06.ps1`
- `tests/ad/computer/Test.AD-COMP-07.md`
- `tests/ad/computer/Test.AD-COMP-07.ps1`
- `tests/ad/computer/Test.AD-COMP-08.md`
- `tests/ad/computer/Test.AD-COMP-08.ps1`
- `tests/ad/computer/Test.AD-COMP-09.md`
- `tests/ad/computer/Test.AD-COMP-09.ps1`
- `tests/ad/computer/Test.AD-COMP-10.md`
- `tests/ad/computer/Test.AD-COMP-10.ps1`
- `tests/ad/security/Test.AD-DCOMP-01.md`
- `tests/ad/security/Test.AD-DCOMP-01.ps1`
- `tests/ad/security/Test.AD-DCOMP-02.md`
- `tests/ad/security/Test.AD-DCOMP-02.ps1`
- `tests/ad/security/Test.AD-DCOMP-03.md`
- `tests/ad/security/Test.AD-DCOMP-03.ps1`
- `tests/ad/security/Test.AD-DCOMP-04.md`
- `tests/ad/security/Test.AD-DCOMP-04.ps1`
- `tests/ad/security/Test.AD-DCOMP-05.md`
- `tests/ad/security/Test.AD-DCOMP-05.ps1`
- `tests/ad/security/Test.AD-DCOMP-07.md`
- `tests/ad/security/Test.AD-DCOMP-07.ps1`
- `tests/ad/security/Test.AD-DCOMP-08.md`
- `tests/ad/security/Test.AD-DCOMP-08.ps1`
- `tests/ad/security/Test.AD-DCOMP-09.md`
- `tests/ad/security/Test.AD-DCOMP-09.ps1`

## Migration status

Original source: `bf1709daaf89373886caf332e1dcd68fc91af528`. Current fork/upstream main: `512a076de7bb173045a2ebe62b0493d613ddd0b5`. Nonconflicted source changes use the three-way merged tree, preserving main changes. Conflicted chains remain main versions and are staged in the separate reconciliation branch. No claims that issues #2796 or #2405 are fully fixed.

## Review blockers

- Per-branch validation pending; historical full-suite results do not validate this migration.
- Review open-PR overlap matrix in the master packet.
- Redirects/global acceptance changes arrive in the final catalog/docs branch; do not deploy intermediate retirements without URL compatibility.
- GitHub CLI authentication unavailable: this is a local draft body, not a published PR.

## Actual migration validation

BLOCKED (exit 1).

- [-] Active Directory test source safety.Routes every public AD test command through a guarded collector before any AD operation 2.42s (2.42s|2ms)
- [-] Windows LAPS readiness accepts the production dictionary state.passes with an ordered dictionary, not only a PSCustomObject fixture 94ms (94ms|1ms)

Log: `TestResults/ad-split/validation.log`.

## Validation job stopped

Authoritative state: **BLOCKED**. The parent validation shell ended with `Shell.NotFoundError`; no process remains. No automatic restart or supplemental run occurred. Read `MERGE-REVIEW.md` for recorded blockers.
