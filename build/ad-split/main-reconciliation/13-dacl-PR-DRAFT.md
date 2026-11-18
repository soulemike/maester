# Draft: AD 13-dacl

Compare: https://github.com/soulemike/maester/compare/split/ad-12-schema-trust...split/ad-13-dacl?expand=1

Base: `split/ad-12-schema-trust`. This is an ordered stack; do not open against upstream main until its parent is merged/rebased.

## Scope

- `powershell/tests/functions/ADDaclConsolidation.Tests.ps1`
- `powershell/tests/functions/ActiveDirectoryDacl.Tests.ps1`
- `tests/ad/dacl/Test.AD-DACL-01.md`
- `tests/ad/dacl/Test.AD-DACL-02.md`
- `tests/ad/dacl/Test.AD-DACL-03.md`
- `tests/ad/dacl/Test.AD-DACL-03.ps1`
- `tests/ad/dacl/Test.AD-DACL-04.md`
- `tests/ad/dacl/Test.AD-DACL-04.ps1`
- `tests/ad/dacl/Test.AD-DACL-05.md`
- `tests/ad/dacl/Test.AD-DACL-05.ps1`
- `tests/ad/dacl/Test.AD-DACL-06.md`
- `tests/ad/dacl/Test.AD-DACL-06.ps1`
- `tests/ad/dacl/Test.AD-DACL-07.md`
- `tests/ad/dacl/Test.AD-DACL-07.ps1`
- `tests/ad/dacl/Test.AD-DACL-08.md`
- `tests/ad/dacl/Test.AD-DACL-08.ps1`
- `tests/ad/dacl/Test.AD-DACL-09.md`
- `tests/ad/dacl/Test.AD-DACL-09.ps1`
- `tests/ad/dacl/Test.AD-DACL-10.md`
- `tests/ad/dacl/Test.AD-DACL-10.ps1`
- `tests/ad/dacl/Test.AD-DACL-11.md`
- `tests/ad/dacl/Test.AD-DACL-11.ps1`
- `tests/ad/dacl/Test.AD-DACL-12.md`
- `tests/ad/dacl/Test.AD-DACL-12.ps1`
- `tests/ad/dacl/Test.AD-DACL-13.md`
- `tests/ad/dacl/Test.AD-DACL-13.ps1`
- `tests/ad/dacl/Test.AD-DACL-14.md`
- `tests/ad/dacl/Test.AD-DACL-15.md`
- `tests/ad/dacl/Test.AD-DACL-15.ps1`
- `tests/ad/dacl/Test.AD-DACL-16.md`
- `tests/ad/dacl/Test.AD-DACL-16.ps1`
- `tests/ad/dacl/Test.AD-DACL-17.md`
- `tests/ad/dacl/Test.AD-DACL-17.ps1`
- `tests/ad/dacl/Test.AD-DACL-18.md`
- `tests/ad/dacl/Test.AD-DACL-18.ps1`

## Migration status

Original source: `bf1709daaf89373886caf332e1dcd68fc91af528`. Current fork/upstream main: `512a076de7bb173045a2ebe62b0493d613ddd0b5`. Nonconflicted source changes use the three-way merged tree, preserving main changes. Conflicted chains remain main versions and are staged in the separate reconciliation branch. No claims that issues #2796 or #2405 are fully fixed.

## Review blockers

- Per-branch validation pending; historical full-suite results do not validate this migration.
- Review open-PR overlap matrix in the master packet.
- Redirects/global acceptance changes arrive in the final catalog/docs branch; do not deploy intermediate retirements without URL compatibility.
- GitHub CLI authentication unavailable: this is a local draft body, not a published PR.

## Validation job stopped

Authoritative state: **INCOMPLETE**. The parent validation shell ended with `Shell.NotFoundError`; no process remains. No automatic restart or supplemental run occurred. Read `MERGE-REVIEW.md` for recorded blockers.
