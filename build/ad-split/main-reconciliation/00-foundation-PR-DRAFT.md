# Draft: AD 00-foundation

Compare: https://github.com/soulemike/maester/compare/main...split/ad-00-foundation?expand=1

Base: `main`. This is an ordered stack; do not open against upstream main until its parent is merged/rebased.

## Scope

- `build/golden/Export-MtLegacyTagTable.ps1`
- `build/golden/native-test-replacements.psd1`
- `powershell/assets/Maester.LegacyTags.json`
- `powershell/internal/checks/ad/ad/Assert-MtAdUserAccountControl.ps1`
- `powershell/internal/checks/ad/ad/ConvertTo-MtAdConfigurationInventoryCell.ps1`
- `powershell/internal/checks/ad/ad/Format-MtAdSiteInventoryValue.ps1`
- `powershell/internal/checks/ad/ad/Format-MtAdSummaryTable.ps1`
- `powershell/internal/checks/ad/ad/Format-MtAdUserSecurityTable.ps1`
- `powershell/internal/checks/ad/ad/Get-MtAdCertificateInventory.ps1`
- `powershell/internal/checks/ad/ad/Get-MtAdConfigurationInventory.ps1`
- `powershell/internal/checks/ad/ad/Get-MtAdConfigurationInventorySiteLinkTransport.ps1`
- `powershell/internal/checks/ad/ad/Get-MtAdStateCollection.ps1`
- `powershell/internal/checks/ad/ad/Invoke-MtAdConfigurationInventoryReport.ps1`
- `powershell/internal/services/ad/Test-MtAdDomainControllerAccount.ps1`
- `powershell/internal/services/ad/protocol/ConvertFrom-MtLdapValue.ps1`
- `powershell/internal/services/ad/queries/Get-MtLdapComputer.ps1`
- `powershell/internal/services/ad/queries/Get-MtLdapDomain.ps1`
- `powershell/internal/services/ad/queries/Get-MtLdapDomainController.ps1`
- `powershell/internal/services/ad/queries/Get-MtLdapFineGrainedPasswordPolicy.ps1`
- `powershell/internal/services/ad/queries/Get-MtLdapForest.ps1`
- `powershell/internal/services/ad/queries/Get-MtLdapOptionalFeature.ps1`
- `powershell/internal/services/ad/queries/Get-MtLdapPrinter.ps1`
- `powershell/internal/services/ad/queries/Get-MtLdapReplicationSite.ps1`
- `powershell/internal/services/ad/queries/Get-MtLdapSchemaObject.ps1`
- `powershell/internal/services/ad/queries/Get-MtLdapUser.ps1`
- `powershell/tests/functions/golden/Golden.Tests.ps1`

## Migration status

Original source: `bf1709daaf89373886caf332e1dcd68fc91af528`. Current fork/upstream main: `512a076de7bb173045a2ebe62b0493d613ddd0b5`. Nonconflicted source changes use the three-way merged tree, preserving main changes. Conflicted chains remain main versions and are staged in the separate reconciliation branch. No claims that issues #2796 or #2405 are fully fixed.

## Review blockers

- Per-branch validation pending; historical full-suite results do not validate this migration.
- Review open-PR overlap matrix in the master packet.
- Redirects/global acceptance changes arrive in the final catalog/docs branch; do not deploy intermediate retirements without URL compatibility.
- GitHub CLI authentication unavailable: this is a local draft body, not a published PR.

## Actual migration validation

BLOCKED (exit 1).

- [-] Active Directory test source safety.Routes every public AD test command through a guarded collector before any AD operation 2.46s (2.45s|4ms)

Log: `TestResults/ad-split/validation.log`.
