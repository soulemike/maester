# Draft: AD 15-catalog-docs

Compare: https://github.com/soulemike/maester/compare/split/ad-14-dns...split/ad-15-catalog-docs?expand=1

Base: `split/ad-14-dns`. This is an ordered stack; do not open against upstream main until its parent is merged/rebased.

## Scope

- `powershell/tests/functions/ADConfigurationChecks.Tests.ps1`
- `powershell/tests/functions/ADGuideContent.Tests.ps1`
- `powershell/tests/functions/ADResultPresentation.Tests.ps1`
- `powershell/tests/functions/ADReviewCorrections.Tests.ps1`
- `powershell/tests/functions/ADSchemaTrustChecks.Tests.ps1`
- `powershell/tests/functions/ActiveDirectoryIssues.Tests.ps1`
- `powershell/tests/functions/ActiveDirectoryOptIn.Tests.ps1`
- `website/docs/advanced/active-directory.md`
- `website/docs/upgrading-from-2x.md`
- `website/scripts/test-retired-test-redirects.mjs`
- `website/src/lib/redirects.mjs`

## Migration status

Original source: `bf1709daaf89373886caf332e1dcd68fc91af528`. Current fork/upstream main: `512a076de7bb173045a2ebe62b0493d613ddd0b5`. Nonconflicted source changes use the three-way merged tree, preserving main changes. Conflicted chains remain main versions and are staged in the separate reconciliation branch. No claims that issues #2796 or #2405 are fully fixed.

## Review blockers

- Per-branch validation pending; historical full-suite results do not validate this migration.
- Review open-PR overlap matrix in the master packet.
- Redirects/global acceptance changes arrive in the final catalog/docs branch; do not deploy intermediate retirements without URL compatibility.
- GitHub CLI authentication unavailable: this is a local draft body, not a published PR.

## Validation job stopped

Authoritative state: **INCOMPLETE**. The parent validation shell ended with `Shell.NotFoundError`; no process remains. No automatic restart or supplemental run occurred. Read `MERGE-REVIEW.md` for recorded blockers.
