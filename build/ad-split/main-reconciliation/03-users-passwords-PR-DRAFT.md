# Draft: AD 03-users-passwords

Compare: https://github.com/soulemike/maester/compare/split/ad-02-groups-spns...split/ad-03-users-passwords?expand=1

Base: `split/ad-02-groups-spns`. This is an ordered stack; do not open against upstream main until its parent is merged/rebased.

## Scope

- `powershell/internal/checks/ad/ad/Get-MtAdPasswordPolicyUsage.ps1`
- `powershell/internal/checks/ad/ad/Get-MtAdUserPathFindings.ps1`
- `powershell/internal/checks/ad/ad/Test-MtAdPasswordPolicyConfiguration.ps1`
- `powershell/internal/checks/ad/ad/Test-MtAdUserOrdinaryIdentity.ps1`
- `powershell/tests/functions/ADPasswordPolicyBatch.Tests.ps1`
- `powershell/tests/functions/ADUserSecurityBatch.Tests.ps1`
- `tests/ad/delegation/Test.AD-USER-05.md`
- `tests/ad/delegation/Test.AD-USER-05.ps1`
- `tests/ad/password-policy/Test.AD-FGPP-01.md`
- `tests/ad/password-policy/Test.AD-FGPP-01.ps1`
- `tests/ad/password-policy/Test.AD-FGPP-02.md`
- `tests/ad/password-policy/Test.AD-FGPP-02.ps1`
- `tests/ad/password-policy/Test.AD-FGPP-03.md`
- `tests/ad/password-policy/Test.AD-FGPP-03.ps1`
- `tests/ad/password-policy/Test.AD-FGPP-04.md`
- `tests/ad/password-policy/Test.AD-FGPP-04.ps1`
- `tests/ad/password-policy/Test.AD-PWDPOL-01.md`
- `tests/ad/password-policy/Test.AD-PWDPOL-01.ps1`
- `tests/ad/password-policy/Test.AD-PWDPOL-02.md`
- `tests/ad/password-policy/Test.AD-PWDPOL-02.ps1`
- `tests/ad/password-policy/Test.AD-PWDPOL-03.md`
- `tests/ad/password-policy/Test.AD-PWDPOL-03.ps1`
- `tests/ad/password-policy/Test.AD-PWDPOL-04.md`
- `tests/ad/password-policy/Test.AD-PWDPOL-04.ps1`
- `tests/ad/password-policy/Test.AD-PWDPOL-05.md`
- `tests/ad/password-policy/Test.AD-PWDPOL-05.ps1`
- `tests/ad/password-policy/Test.AD-PWDPOL-06.md`
- `tests/ad/password-policy/Test.AD-PWDPOL-06.ps1`
- `tests/ad/password-policy/Test.AD-PWDPOL-07.md`
- `tests/ad/password-policy/Test.AD-PWDPOL-07.ps1`
- `tests/ad/security/Test.AD-MSA-01.md`
- `tests/ad/security/Test.AD-MSA-01.ps1`
- `tests/ad/user/Test.AD-USER-01.md`
- `tests/ad/user/Test.AD-USER-01.ps1`
- `tests/ad/user/Test.AD-USER-03.md`
- `tests/ad/user/Test.AD-USER-03.ps1`
- `tests/ad/user/Test.AD-USER-04.md`
- `tests/ad/user/Test.AD-USER-04.ps1`
- `tests/ad/user/Test.AD-USER-05.md`
- `tests/ad/user/Test.AD-USER-05.ps1`
- `tests/ad/user/Test.AD-USER-06.md`
- `tests/ad/user/Test.AD-USER-06.ps1`
- `tests/ad/user/Test.AD-USER-07.md`
- `tests/ad/user/Test.AD-USER-07.ps1`
- `tests/ad/user/Test.AD-USER-08.md`
- `tests/ad/user/Test.AD-USER-08.ps1`
- `tests/ad/user/Test.AD-USER-09.md`
- `tests/ad/user/Test.AD-USER-09.ps1`
- `tests/ad/user/Test.AD-USER-10.md`
- `tests/ad/user/Test.AD-USER-10.ps1`
- `tests/ad/user/Test.AD-USER-11.md`
- `tests/ad/user/Test.AD-USER-11.ps1`
- `tests/ad/user/Test.AD-USER-12.md`
- `tests/ad/user/Test.AD-USER-12.ps1`
- `tests/ad/user/Test.AD-USER-13.md`
- `tests/ad/user/Test.AD-USER-13.ps1`
- `tests/ad/user/Test.AD-USER-14.md`
- `tests/ad/user/Test.AD-USER-14.ps1`
- `tests/ad/user/Test.AD-USER-15.md`
- `tests/ad/user/Test.AD-USER-15.ps1`
- `tests/ad/user/Test.AD-USER-16.md`
- `tests/ad/user/Test.AD-USER-16.ps1`
- `tests/ad/user/Test.AD-USER-17.md`
- `tests/ad/user/Test.AD-USER-17.ps1`
- `tests/ad/user/Test.AD-USER-18.md`
- `tests/ad/user/Test.AD-USER-18.ps1`
- `tests/ad/user/Test.AD-USER-19.md`
- `tests/ad/user/Test.AD-USER-19.ps1`
- `tests/ad/user/Test.AD-USER-20.md`
- `tests/ad/user/Test.AD-USER-20.ps1`
- `tests/ad/user/Test.AD-USER-21.md`
- `tests/ad/user/Test.AD-USER-21.ps1`
- `tests/ad/user/Test.AD-USER-22.md`
- `tests/ad/user/Test.AD-USER-22.ps1`
- `tests/ad/user/Test.AD-USER-23.md`
- `tests/ad/user/Test.AD-USER-23.ps1`
- `tests/ad/user/Test.AD-USER-24.md`
- `tests/ad/user/Test.AD-USER-24.ps1`
- `tests/ad/user/Test.AD-USER-25.md`
- `tests/ad/user/Test.AD-USER-25.ps1`
- `tests/ad/user/Test.AD-USER-26.md`
- `tests/ad/user/Test.AD-USER-26.ps1`
- `tests/ad/user/Test.AD-USER-27.md`
- `tests/ad/user/Test.AD-USER-27.ps1`
- `tests/ad/user/Test.AD-USER-28.md`
- `tests/ad/user/Test.AD-USER-28.ps1`
- `tests/ad/user/Test.AD-USER-29.md`
- `tests/ad/user/Test.AD-USER-29.ps1`

## Migration status

Original source: `bf1709daaf89373886caf332e1dcd68fc91af528`. Current fork/upstream main: `512a076de7bb173045a2ebe62b0493d613ddd0b5`. Nonconflicted source changes use the three-way merged tree, preserving main changes. Conflicted chains remain main versions and are staged in the separate reconciliation branch. No claims that issues #2796 or #2405 are fully fixed.

## Review blockers

- Per-branch validation pending; historical full-suite results do not validate this migration.
- Review open-PR overlap matrix in the master packet.
- Redirects/global acceptance changes arrive in the final catalog/docs branch; do not deploy intermediate retirements without URL compatibility.
- GitHub CLI authentication unavailable: this is a local draft body, not a published PR.
