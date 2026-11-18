# Draft: AD 09-auth-policy-overlap

Compare: https://github.com/soulemike/maester/compare/split/ad-08-directory-config...split/ad-09-auth-policy-overlap?expand=1

Base: `split/ad-08-directory-config`. This is an ordered stack; do not open against upstream main until its parent is merged/rebased.

## Scope

- `tests/ad/config/Test.AD-CFG-08.md`
- `tests/ad/config/Test.AD-CFG-08.ps1`

## Migration status

Original source: `bf1709daaf89373886caf332e1dcd68fc91af528`. Current fork/upstream main: `512a076de7bb173045a2ebe62b0493d613ddd0b5`. Nonconflicted source changes use the three-way merged tree, preserving main changes. Conflicted chains remain main versions and are staged in the separate reconciliation branch. No claims that issues #2796 or #2405 are fully fixed.

## Review blockers

- Per-branch validation pending; historical full-suite results do not validate this migration.
- Review open-PR overlap matrix in the master packet.
- Redirects/global acceptance changes arrive in the final catalog/docs branch; do not deploy intermediate retirements without URL compatibility.
- GitHub CLI authentication unavailable: this is a local draft body, not a published PR.
