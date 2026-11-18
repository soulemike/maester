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
