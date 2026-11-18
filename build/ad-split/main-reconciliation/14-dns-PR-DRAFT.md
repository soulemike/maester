# Draft: AD 14-dns

Compare: https://github.com/soulemike/maester/compare/split/ad-13-dacl...split/ad-14-dns?expand=1

Base: `split/ad-13-dacl`. This is an ordered stack; do not open against upstream main until its parent is merged/rebased.

## Scope

- `tests/ad/dns/Test.AD-DNS-01.md`
- `tests/ad/dns/Test.AD-DNS-02.md`
- `tests/ad/dns/Test.AD-DNS-03.md`
- `tests/ad/dns/Test.AD-DNS-04.md`
- `tests/ad/dns/Test.AD-DNS-05.md`
- `tests/ad/dns/Test.AD-DNS-06.md`
- `tests/ad/dns/Test.AD-DNS-07.md`
- `tests/ad/dns/Test.AD-DNS-08.md`
- `tests/ad/dns/Test.AD-DNS-09.md`
- `tests/ad/dns/Test.AD-DNS-10.md`
- `tests/ad/dns/Test.AD-DNS-11.md`
- `tests/ad/dns/Test.AD-DNS-12.md`
- `tests/ad/dns/Test.AD-DNS-14.md`
- `tests/ad/dns/Test.AD-DNS-16.md`
- `tests/ad/dns/Test.AD-DNS-18.md`
- `tests/ad/dns/Test.AD-DNS-19.md`

## Migration status

Original source: `bf1709daaf89373886caf332e1dcd68fc91af528`. Current fork/upstream main: `512a076de7bb173045a2ebe62b0493d613ddd0b5`. Nonconflicted source changes use the three-way merged tree, preserving main changes. Conflicted chains remain main versions and are staged in the separate reconciliation branch. No claims that issues #2796 or #2405 are fully fixed.

## Review blockers

- Per-branch validation pending; historical full-suite results do not validate this migration.
- Review open-PR overlap matrix in the master packet.
- Redirects/global acceptance changes arrive in the final catalog/docs branch; do not deploy intermediate retirements without URL compatibility.
- GitHub CLI authentication unavailable: this is a local draft body, not a published PR.

## Validation job stopped

Authoritative state: **INCOMPLETE**. The parent validation shell ended with `Shell.NotFoundError`; no process remains. No automatic restart or supplemental run occurred. Read `MERGE-REVIEW.md` for recorded blockers.
