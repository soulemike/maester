# Administrative reconciliation — DO NOT OPEN AN UPSTREAM PR

# Draft: AD 16-main-reconciliation

Compare: https://github.com/soulemike/maester/compare/main...split/ad-16-main-reconciliation?expand=1

Base: `main`. This is an ordered stack; do not open against upstream main until its parent is merged/rebased.

## Scope

- `powershell/tests/functions/engine/Frameworks.Tests.ps1`
- `tests/ad/computer/Test.AD-COMP-02.md`
- `tests/ad/computer/Test.AD-COMP-02.ps1`
- `tests/ad/security/Test.AD-DCOMP-06.md`
- `tests/ad/security/Test.AD-DCOMP-06.ps1`
- `tests/ad/security/Test.AD-KRBTGT-01.md`
- `tests/ad/security/Test.AD-KRBTGT-01.ps1`
- `tests/ad/security/Test.AD-KRBTGT-02.md`
- `tests/ad/security/Test.AD-KRBTGT-03.md`
- `tests/ad/trust/Test.AD-TRUST-06.md`
- `tests/ad/trust/Test.AD-TRUST-06.ps1`
- `tests/ad/trust/Test.AD-TRUST-07.md`
- `tests/ad/trust/Test.AD-TRUST-07.ps1`
- `tests/ad/user/Test.AD-USER-02.md`
- `tests/ad/user/Test.AD-USER-02.ps1`

## Migration status

Original source: `bf1709daaf89373886caf332e1dcd68fc91af528`. Current fork/upstream main: `512a076de7bb173045a2ebe62b0493d613ddd0b5`. Nonconflicted source changes use the three-way merged tree, preserving main changes. Conflicted chains remain main versions and are staged in the separate reconciliation branch. No claims that issues #2796 or #2405 are fully fixed.

## Review blockers

- Per-branch validation pending; historical full-suite results do not validate this migration.
- Review open-PR overlap matrix in the master packet.
- Redirects/global acceptance changes arrive in the final catalog/docs branch; do not deploy intermediate retirements without URL compatibility.
- GitHub CLI authentication unavailable: this is a local draft body, not a published PR.
