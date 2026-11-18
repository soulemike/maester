# Draft: AD 02-groups-spns

Compare: https://github.com/soulemike/maester/compare/split/ad-01-collector-overlaps...split/ad-02-groups-spns?expand=1

Base: `split/ad-01-collector-overlaps`. This is an ordered stack; do not open against upstream main until its parent is merged/rebased.

## Scope

- `powershell/tests/functions/ADGroupSpnChecks.Tests.ps1`
- `tests/ad/group/Test.AD-GCHG-01.md`
- `tests/ad/group/Test.AD-GMC-01.md`
- `tests/ad/group/Test.AD-GMC-01.ps1`
- `tests/ad/group/Test.AD-GMC-02.md`
- `tests/ad/group/Test.AD-GMC-02.ps1`
- `tests/ad/group/Test.AD-GMC-03.md`
- `tests/ad/group/Test.AD-GMC-03.ps1`
- `tests/ad/group/Test.AD-GMC-04.md`
- `tests/ad/group/Test.AD-GMC-04.ps1`
- `tests/ad/group/Test.AD-GMC-05.md`
- `tests/ad/group/Test.AD-GMC-05.ps1`
- `tests/ad/group/Test.AD-GMC-06.md`
- `tests/ad/group/Test.AD-GMC-06.ps1`
- `tests/ad/group/Test.AD-GMC-07.md`
- `tests/ad/group/Test.AD-GMC-07.ps1`
- `tests/ad/group/Test.AD-GMC-08.md`
- `tests/ad/group/Test.AD-GMC-08.ps1`
- `tests/ad/group/Test.AD-GMC-09.md`
- `tests/ad/group/Test.AD-GMC-09.ps1`
- `tests/ad/group/Test.AD-GMC-10.md`
- `tests/ad/group/Test.AD-GMC-10.ps1`
- `tests/ad/group/Test.AD-GMC-11.md`
- `tests/ad/group/Test.AD-GMC-11.ps1`
- `tests/ad/group/Test.AD-GRP-01.md`
- `tests/ad/group/Test.AD-GRP-01.ps1`
- `tests/ad/group/Test.AD-GRP-02.md`
- `tests/ad/group/Test.AD-GRP-02.ps1`
- `tests/ad/group/Test.AD-GRP-03.md`
- `tests/ad/group/Test.AD-GRP-03.ps1`
- `tests/ad/group/Test.AD-GRP-04.md`
- `tests/ad/group/Test.AD-GRP-04.ps1`
- `tests/ad/group/Test.AD-GRP-05.md`
- `tests/ad/group/Test.AD-GRP-05.ps1`
- `tests/ad/group/Test.AD-GRP-06.md`
- `tests/ad/group/Test.AD-GRP-06.ps1`
- `tests/ad/group/Test.AD-GRP-07.md`
- `tests/ad/group/Test.AD-GRP-07.ps1`
- `tests/ad/group/Test.AD-GRP-08.md`
- `tests/ad/group/Test.AD-GRP-08.ps1`
- `tests/ad/group/Test.AD-GRP-09.md`
- `tests/ad/group/Test.AD-GRP-09.ps1`
- `tests/ad/group/Test.AD-GRP-10.md`
- `tests/ad/group/Test.AD-GRP-10.ps1`
- `tests/ad/spn/Test.AD-SPN-01.md`
- `tests/ad/spn/Test.AD-SPN-01.ps1`
- `tests/ad/spn/Test.AD-SPN-02.md`
- `tests/ad/spn/Test.AD-SPN-02.ps1`
- `tests/ad/spn/Test.AD-SPN-03.md`
- `tests/ad/spn/Test.AD-SPN-03.ps1`
- `tests/ad/spn/Test.AD-SPN-04.md`
- `tests/ad/spn/Test.AD-SPN-04.ps1`
- `tests/ad/spn/Test.AD-SPN-05.md`
- `tests/ad/spn/Test.AD-SPN-05.ps1`
- `tests/ad/spn/Test.AD-SPN-06.md`
- `tests/ad/spn/Test.AD-SPN-06.ps1`
- `tests/ad/spn/Test.AD-SPN-07.md`
- `tests/ad/spn/Test.AD-SPN-07.ps1`
- `tests/ad/spn/Test.AD-SPN-08.md`
- `tests/ad/spn/Test.AD-SPN-08.ps1`
- `tests/ad/spn/Test.AD-SPN-09.md`
- `tests/ad/spn/Test.AD-SPN-09.ps1`
- `tests/ad/spn/Test.AD-SPN-10.md`
- `tests/ad/spn/Test.AD-SPN-10.ps1`
- `tests/ad/spn/Test.AD-SPN-11.md`
- `tests/ad/spn/Test.AD-SPN-11.ps1`
- `tests/ad/spn/Test.AD-SPN-12.md`
- `tests/ad/spn/Test.AD-SPN-12.ps1`
- `tests/ad/spn/Test.AD-SPN-13.md`
- `tests/ad/spn/Test.AD-SPN-13.ps1`

## Migration status

Original source: `bf1709daaf89373886caf332e1dcd68fc91af528`. Current fork/upstream main: `512a076de7bb173045a2ebe62b0493d613ddd0b5`. Nonconflicted source changes use the three-way merged tree, preserving main changes. Conflicted chains remain main versions and are staged in the separate reconciliation branch. No claims that issues #2796 or #2405 are fully fixed.

## Review blockers

- Per-branch validation pending; historical full-suite results do not validate this migration.
- Review open-PR overlap matrix in the master packet.
- Redirects/global acceptance changes arrive in the final catalog/docs branch; do not deploy intermediate retirements without URL compatibility.
- GitHub CLI authentication unavailable: this is a local draft body, not a published PR.
