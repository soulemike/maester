# Plan 12: AD Collector Contract Corrections

## TL;DR

> **Scope**: Fix the root causes of false passes, inverted status mappings, missing query object properties, and platform-incompatible parsing in Maester's AD LDAP collectors and check functions.
>
> **Deliverables**: Error-propagating collectors, corrected bit masks and status mappings, complete query object properties, non-Windows platform guards.
>
> **Estimated Effort**: Medium
> **Parallel Execution**: YES — 2 waves. Can execute immediately; no blockers. Foundation for Plans 05 and 07.
> **Critical Path**: Error propagation → bit mask/status fixes → property completeness → platform guards → validation

---

## Context

### Original Request
GitHub issue #2282 identified 5 "Must-fix" bugs in the merged AD protocol code (PR #2265). Plans 06-11 address test wrappers, transport, fixtures, and documentation, but NONE address the collector-level correctness issues that produce false pass/fail results.

### Interview Summary
**Key Discussions**:
- Plan 06 fixes wrapper-level silent passes but NOT the root cause: `Get-MtLdap*.ps1` files catch errors and return `@()`, which downstream checks interpret as "data exists" rather than "collection failed."
- Plan 10 makes security descriptors testable cross-platform but does NOT add production skip logic for non-Windows hosts.
- The remaining must-fix items require modifying LDAP query functions, check logic, and GPO state normalizers.

**Research Findings**:
- `Get-MtLdapComputer.ps1:29-31`, `Get-MtLdapUser.ps1:30-33`, `Get-MtLdapGpo.ps1:29-32`, `Get-MtLdapGpoLink.ps1:17-20` all catch errors and return `@()`. **All 20 `Get-MtLdap*.ps1` files in `powershell/internal/ad/queries/` have this pattern.**
- `Get-MtADDomainState.ps1` initializes category arrays to `@()` at lines 111–140 and overwrites them in per-category `try/catch` blocks (lines 142–363). When a collector throws, the catch block logs verbosely and the property retains its `@()` initialization.
- `Test-MtAdPasswordReversibleEncryption.ps1:38` uses `PwdProperties -band 2` (DOMAIN_PASSWORD_NO_ANON_CHANGE) instead of `-band 0x10` (DOMAIN_PASSWORD_STORE_CLEARTEXT).
- **GPO status consumers (NOT the producer) have inverted logic**: `Test-MtAdGpoSettingsDisabledCount.ps1` checks `$statusInt -in 0,1,2` which wrongly includes `AllSettingsEnabled (0)` as "disabled" and excludes `AllSettingsDisabled (3)`. `Test-MtAdGpoUserSettingsDisabledDetails.ps1` and `Test-MtAdGpoAllSettingsDisabledDetails.ps1` have comments and filters that invert the standard GroupPolicy enum semantics.
- `ConvertFrom-MtLdapSecurityDescriptor.ps1` and `ConvertFrom-MtLdapValue.ps1` do **NOT** currently handle `PlatformNotSupportedException` on non-Windows; they throw unhandled exceptions. `ConvertFrom-MtLdapSecurityDescriptor.ps1` calls `RawSecurityDescriptor` constructor with no try/catch. `ConvertFrom-MtLdapValue.ps1` catches exceptions for `ntsecuritydescriptor` at lines 188–189 but returns raw bytes (`$Value`) rather than `$null`. Task 5 must ADD explicit platform detection and graceful skip logic.
- `Get-MtSysvolContent.ps1:203` (exists on `main` branch only) counts every `cpassword` attribute including empty strings `cpassword=""`. **File absent in current branch — deferred.**
- Missing properties verified via grep across all `Get-MtLdap*.ps1` files and their consumers in `powershell/public/ad/**`.

### Metis Review
**Identified Gaps** (addressed in plan):
- Guardrail needed: Error propagation must NOT break `Get-MtADDomainState` per-category resilience; use `$null` for failed categories, not `@()`.
- Guardrail needed: GPO status fix must preserve backward compatibility for consumers expecting the current enum shape.
- Guardrail needed: Adding missing properties must NOT change existing property types or break current consumers.
- Guardrail needed: Non-Windows skip logic must use `-SkippedBecause NotSupported` or `-SkippedBecause Custom` with clear reason.
- Edge case: `Get-MtLdapDomainController.ps1:13-14` searches whole forest via `nTDSDSA` under `CN=Sites`; must scope to current domain only to match previous `Get-ADDomainController -Filter *` behavior.
- Edge case: `Get-MtLdapForest.ps1:32` `nCName -like 'DC=*'` matches DomainDnsZones and ForestDnsZones partitions.

### Path Corrections Applied (from repo verification)
The following paths were corrected during plan generation to match the actual repository structure:
- `Get-MtADGpoState.ps1`: `powershell/internal/ad/gpostate/` → `powershell/public/Get-MtADGpoState.ps1`
- `Test-MtAdGpoUserSettingsDisabledDetails.ps1`: `powershell/public/ad/gpo/` → `powershell/public/ad/gpostate/`
- `Get-MtAdSupportedAuthMatrix.ps1`: `powershell/public/` → `powershell/internal/ad/`
- `ActiveDirectoryProtocol.Tests.ps1` / `ActiveDirectoryOptIn.Tests.ps1`: `tests/` → `powershell/tests/functions/`
- `Get-MtSysvolContent.ps1`: exists on `main` branch (PR #2265); current branch is `ad-multiforest-targeting-archive`

---

## Work Objectives

### Core Objective
Make AD collectors honest about failure, correct status mappings and bit masks, return complete property sets, and skip platform-incompatible checks gracefully.

### Concrete Deliverables
- Modified **all 20** `Get-MtLdap*.ps1` files in `powershell/internal/ad/queries/` that propagate query failures as `$null` instead of `@()`
- Modified `Get-MtADDomainState.ps1` that initializes categories to `$null` and preserves `$null` for failed categories
- Modified `Test-MtAdPasswordReversibleEncryption.ps1` with correct `-band 0x10`
- Modified GPO status consumer checks (`Test-MtAdGpoSettingsDisabledCount`, `Test-MtAdGpoUserSettingsDisabledDetails`, `Test-MtAdGpoAllSettingsDisabledDetails`, `Test-MtAdGpoComputerSettingsDisabledDetails`) with correct enum semantics
- Modified `Get-MtLdapDomainController.ps1`, `Get-MtLdapTrust.ps1`, `Get-MtLdapForest.ps1`, `Get-MtLdapReplicationConnection.ps1`, site link query, `Get-MtLdapGroupMember.ps1` with missing properties
- Modified `ConvertFrom-MtLdapSecurityDescriptor.ps1` and `ConvertFrom-MtLdapValue.ps1` to return `$null`/sentinel on non-Windows
- Modified descriptor/SID-dependent checks to skip on non-Windows with `.DESCRIPTION` notes
- Fixed `ConvertFrom-MtLdapValue.ps1` `[long]::MinValue` mapping to "never" sentinel
- Fixed null guards in `Test-MtAdPasswordComplexityRequired.ps1` and `Test-MtAdKrbtgtLastLogon.ps1`
- New/updated tests in `ActiveDirectoryProtocol.Tests.ps1` or `ActiveDirectoryOptIn.Tests.ps1`

### Definition of Done
- `pwsh -NoProfile -File ./powershell/tests/pester.ps1` passes
- Structural scan finds zero `@()` as error fallback in all 20 `Get-MtLdap*.ps1` files
- `Test-MtAdPasswordReversibleEncryption` returns `$false` when reversible encryption is enabled (bit 0x10)
- GPO status consumer checks report correctly for enabled vs disabled GPOs
- All checks that depend on parsed descriptors or SIDs skip on non-Windows with clear reason
- `[long]::MinValue` maps to "never" sentinel, not `$null`
- Zero pre-existing AD check regressions

### Must Have
- Query failures produce `$null` (skip) rather than `@()` (false pass) in all 20 collectors
- Reversible encryption tests bit `0x10`, not bit `2`
- GPO status consumer checks use correct GroupPolicy enum semantics (0=AllEnabled, 3=AllDisabled)
- All missing properties from #2282 item 5 are present in query objects
- Non-Windows hosts skip descriptor/SID checks with clear skip reason and `.DESCRIPTION` notes
- `[long]::MinValue` maps to "never" sentinel, not `$null`
- Empty `cpassword` attributes are deferred to main-branch plan

### Must NOT Have (Guardrails)
- No breaking changes to public check parameter contracts
- No changes to check thresholds beyond correcting inverted/false logic
- No removal of existing properties from query objects
- No suppression of legitimate errors with empty catch blocks
- No generated-doc hand edits (AGENTS.md hard rule)
- No changes to transport layer, WinRM, or SYSVOL adapters (belongs to Plan 09)

---

## Verification Strategy

> **ZERO HUMAN INTERVENTION** — ALL verification is agent-executed. No exceptions.

### Test Decision
- **Infrastructure exists**: YES (`pester.ps1`, `ActiveDirectoryProtocol.Tests.ps1`, `ActiveDirectoryOptIn.Tests.ps1`)
- **Automated tests**: Tests-after with fixtures and structural scans
- **Framework**: Pester 5.7.1
- **Agent-Executed QA**: ALWAYS — every task includes concrete QA scenarios

### QA Policy
Every task MUST include agent-executed QA scenarios.
Evidence saved to `.sisyphus/evidence/plan12-task-{N}-{slug}.{ext}`.

- **Structural scan**: Use `grep`/`ast_grep_search` to verify `@()` error fallback removal, bit mask correctness, status mapping
- **Fixture tests**: Use mocked LDAP data to verify property presence and null handling
- **Platform simulation**: Use `$IsWindows` override or mocked `RawSecurityDescriptor` to verify skip logic

---

## Execution Strategy

### Parallel Execution Waves

Wave 1 (Foundation — sequential start, then parallel):
- **Task 1** first (error propagation — blocks all others)
- **Tasks 2-3** in parallel after Task 1 completes (bit mask + GPO status)

Wave 2 (Consumer fixes + validation — all blocked by Task 1):
- **Tasks 4-6** in parallel after Task 1 completes
- **Task 7** sequential after Tasks 2-6 complete

### Dependency Matrix
| Task | Blocks | Blocked By |
|------|--------|------------|
| 1 | 2, 3, 4, 5, 6, 7 | — |
| 2 | 7 | 1 |
| 3 | 7 | 1 |
| 4 | 7 | 1 |
| 5 | 7 | 1 |
| 6 | 7 | 1 |
| 7 | F1–F4 | 2, 3, 4, 5, 6 |

### Agent Dispatch Summary
- Wave 1: 3 tasks — `deep` (error propagation, bit masks, status mapping)
- Wave 2: 4 tasks — `deep` (properties, platform guards, GPP fix, auth matrix)
- Final Verification: 4 parallel review agents

---

## TODOs

- [ ] 1. Fix collector error propagation: return $null instead of @()

  **What to do**:
  - Modify the **20** `Get-MtLdap*.ps1` files that currently catch errors and return `@()` (all except `Get-MtLdapDomain.ps1` and `Get-MtLdapForest.ps1`, which already return `$null`). The complete list:
    - `Get-MtLdapComputer.ps1`, `Get-MtLdapUser.ps1`, `Get-MtLdapGpo.ps1`, `Get-MtLdapGpoLink.ps1`
    - `Get-MtLdapDomainController.ps1`, `Get-MtLdapTrust.ps1`, `Get-MtLdapReplicationConnection.ps1`, `Get-MtLdapGroupMember.ps1`
    - `Get-MtLdapGroup.ps1`, `Get-MtLdapFineGrainedPasswordPolicy.ps1`, `Get-MtLdapReplicationSite.ps1`, `Get-MtLdapOptionalFeature.ps1`
    - `Get-MtLdapPrinter.ps1`, `Get-MtLdapReplicationSubnet.ps1`, `Get-MtLdapOrganizationalUnit.ps1`, `Get-MtLdapDacl.ps1`
    - `Get-MtLdapConfigurationContainer.ps1` (includes inner `Invoke-ConfigurationSearch` helper at lines 29–32; **also remove outer `@(...)` wrappers at lines 55–61**), `Get-MtLdapSiteContainer.ps1`, `Get-MtLdapSchemaObject.ps1`, `Get-MtLdapServiceAccount.ps1`
  - Modify `Get-MtADDomainState.ps1`:
    - Change initialization of category properties from `@()` to `$null` (lines 111–140).
    - In per-category `try/catch` blocks (lines 142–363), ensure failed categories remain `$null` rather than defaulting to `@()`.
    - **Remove `@(...)` wrappers around all `Get-MtLdap*` collector calls** so that a `$null` return from the collector is preserved as `$null` in the domain state object.
  - Verify that checks using `.Count -eq 0` or `-eq 0` on collection-derived variables now skip instead of pass when collection fails. **Note**: The actual fix for `.Count -eq 0` null guards across consumer checks is assigned to Task 6, not this task.

  **Must NOT do**: Do not remove all error handling — let errors propagate to `Get-MtADDomainState` or use `$null` return. Do not change check logic in this task.

  **Recommended Agent Profile**:
  - Category: `deep` — Reason: requires understanding collector/check interaction and null semantics
  - Skills: `[]`

  **Parallelization**: Can Parallel: NO | Wave 1 | Blocks: 2–7 | Blocked By: —

  **References**:
  - Pattern: `powershell/internal/ad/queries/Get-MtLdapComputer.ps1:29-31`
  - Pattern: `powershell/internal/ad/queries/Get-MtLdapUser.ps1:30-33`
  - Pattern: `powershell/internal/ad/queries/Get-MtLdapGpo.ps1:29-32`
  - Pattern: `powershell/internal/ad/queries/Get-MtLdapGpoLink.ps1:17-20`
  - Pattern: `powershell/public/Get-MtADDomainState.ps1:111-140` (initialization), `142-363` (per-category collection)

  **Acceptance Criteria**:
  - [ ] `grep -rn 'return @()' powershell/internal/ad/queries/` returns empty
  - [ ] Failed LDAP queries cause affected checks to skip instead of pass
  - [ ] `pwsh -NoProfile -File ./powershell/tests/pester.ps1` passes

  **QA Scenarios**:
  ```
  Scenario: Failed user query produces skip
    Tool: Bash (pwsh/Pester)
    Steps: Mock Get-MtLdapUser to throw; run Test-MtAdUserPasswordNeverExpiresCount
    Expected: Returns $null; Add-MtTestResultDetail called with -SkippedBecause
    Evidence: .sisyphus/evidence/plan12-task-1-user-skip.txt

  Scenario: Failed GPO query produces skip for -eq 0 checks
    Tool: Bash (pwsh/Pester)
    Steps: Mock Get-MtLdapGpo to throw; run Test-MtAdComputerNonDcUnconstrainedDelegationCount
    Expected: Returns $null; not $true
    Evidence: .sisyphus/evidence/plan12-task-1-eq0-skip.txt
  ```

  **Commit**: YES
  - Message: `fix(ad): propagate collector failures as $null instead of @()`
  - Files: `powershell/internal/ad/queries/Get-MtLdap*.ps1`, `powershell/public/Get-MtADDomainState.ps1`

- [ ] 2. Fix reversible encryption bit mask

  **What to do**:
  - Change `Test-MtAdPasswordReversibleEncryption.ps1:38` from `($pwdProperties -band 2) -ne 0` to `($pwdProperties -band 0x10) -ne 0`.
  - Update companion `.md` file if it references the old bit or behavior.
  - Verify null guard behavior: when domain query fails, the check should skip (handled by Task 1), not pass.

  **Must NOT do**: Do not change the check threshold semantics — reversible encryption should still be reported as a failure when enabled.

  **Recommended Agent Profile**:
  - Category: `quick` — Reason: single-line logic fix with test verification
  - Skills: `[]`

  **Parallelization**: Can Parallel: YES | Wave 1 | Blocks: 7 | Blocked By: 1

  **References**:
  - Pattern: `powershell/public/ad/passwordpolicy/Test-MtAdPasswordReversibleEncryption.ps1:38`
  - External: MS-ADTS `DOMAIN_PASSWORD_STORE_CLEARTEXT = 0x10`

  **Acceptance Criteria**:
  - [ ] `grep -n 'band 2' powershell/public/ad/passwordpolicy/Test-MtAdPasswordReversibleEncryption.ps1` returns empty
  - [ ] Fixture test: domain with `PwdProperties = 0x10` returns `$false` (reversible enabled = fail)
  - [ ] Fixture test: domain with `PwdProperties = 0x02` returns `$true` (reversible disabled = pass)

  **QA Scenarios**:
  ```
  Scenario: Reversible encryption enabled is detected
    Tool: Bash (pwsh/Pester)
    Steps: Mock domain with PwdProperties = 0x10; run test
    Expected: Returns $false
    Evidence: .sisyphus/evidence/plan12-task-2-reversible-enabled.txt

  Scenario: No-anon-change bit does not trigger false positive
    Tool: Bash (pwsh/Pester)
    Steps: Mock domain with PwdProperties = 0x02; run test
    Expected: Returns $true
    Evidence: .sisyphus/evidence/plan12-task-2-reversible-disabled.txt
  ```

  **Commit**: YES
  - Message: `fix(ad): correct reversible encryption bit mask to 0x10`
  - Files: `powershell/public/ad/passwordpolicy/Test-MtAdPasswordReversibleEncryption.ps1`

- [ ] 3. Fix GPO status inversion in consumers

  **What to do**:
  - **Do NOT modify `Get-MtADGpoState.ps1`** — the producer mapping `GpoStatus = ($flags -band 3)` is already correct. Raw AD `gPCFlags` map identically to the standard GroupPolicy module `GpoStatus` enum:
    - `flags=0` (both enabled) → `0` = `AllSettingsEnabled`
    - `flags=1` (user disabled) → `1` = `UserSettingsDisabled`
    - `flags=2` (computer disabled) → `2` = `ComputerSettingsDisabled`
    - `flags=3` (both disabled) → `3` = `AllSettingsDisabled`
  - Fix the **consumer checks** which have inverted comments, filter logic, and `Convert-GpoStatusToInt` switch mappings:
    - `Test-MtAdGpoSettingsDisabledCount.ps1`: change filter from `$statusInt -in 0,1,2` to `$statusInt -in 1,2,3` (exclude `AllSettingsEnabled`, include `AllSettingsDisabled`)
    - `Test-MtAdGpoUserSettingsDisabledDetails.ps1`: fix `Convert-GpoStatusToInt` switch block. Current mapping is inverted (`AllDisabled→0`, `AllEnabled→3`). Correct mapping: `AllSettingsEnabled = 0`, `UserSettingsDisabled = 1`, `ComputerSettingsDisabled = 2`, `AllSettingsDisabled = 3`.
    - `Test-MtAdGpoAllSettingsDisabledDetails.ps1`: change filter from `$statusInt -eq 0` to `$statusInt -eq 3`. Fix `Convert-GpoStatusToInt` switch block.
    - `Test-MtAdGpoComputerSettingsDisabledDetails.ps1`: verify and fix `Convert-GpoStatusToInt` switch block and filter if same inversion exists.
  - Verify `Test-MtAdGpoSettingsDisabledCount` counts only actually-disabled GPOs after the fix.

  **Must NOT do**: Do not change `Get-MtADGpoState.ps1` producer mapping. Do not change the public shape of `GpoStatus` property.

  **Recommended Agent Profile**:
  - Category: `deep` — Reason: requires understanding AD flags, GroupPolicy enum, and consumer mapping
  - Skills: `[]`

  **Parallelization**: Can Parallel: YES | Wave 1 | Blocks: 7 | Blocked By: 1

  **References**:
  - Pattern: `powershell/public/Get-MtADGpoState.ps1:98` (producer — correct, do not change)
  - Pattern: `powershell/public/ad/gpostate/Test-MtAdGpoSettingsDisabledCount.ps1`
  - Pattern: `powershell/public/ad/gpostate/Test-MtAdGpoUserSettingsDisabledDetails.ps1:53-56`
  - Pattern: `powershell/public/ad/gpostate/Test-MtAdGpoAllSettingsDisabledDetails.ps1`
  - Pattern: `powershell/public/ad/gpostate/Test-MtAdGpoComputerSettingsDisabledDetails.ps1`
  - External: MS-GPOL `gPCFlags` definition

  **Acceptance Criteria**:
  - [ ] Normal GPO (flags=0) reports as `AllSettingsEnabled` and is NOT counted as disabled
  - [ ] All-disabled GPO (flags=3) reports as `AllSettingsDisabled` and IS counted as disabled
  - [ ] `Test-MtAdGpoSettingsDisabledCount` counts only GPOs with `statusInt -in 1,2,3`

  **QA Scenarios**:
  ```
  Scenario: Normal GPO not reported as disabled
    Tool: Bash (pwsh/Pester)
    Steps: Mock GPO with flags=0; run Test-MtAdGpoSettingsDisabledCount
    Expected: Count excludes this GPO
    Evidence: .sisyphus/evidence/plan12-task-3-normal-gpo.txt

  Scenario: All-disabled GPO correctly counted
    Tool: Bash (pwsh/Pester)
    Steps: Mock GPO with flags=3; run Test-MtAdGpoSettingsDisabledCount
    Expected: Count includes this GPO
    Evidence: .sisyphus/evidence/plan12-task-3-disabled-gpo.txt
  ```

  **Commit**: YES
  - Message: `fix(ad): correct GPO status consumer logic to match standard enum`
  - Files: `powershell/public/ad/gpostate/Test-MtAdGpoSettingsDisabledCount.ps1`, `Test-MtAdGpoUserSettingsDisabledDetails.ps1`, `Test-MtAdGpoAllSettingsDisabledDetails.ps1`, `Test-MtAdGpoComputerSettingsDisabledDetails.ps1`

- [ ] 4. Add missing properties to LDAP query objects

  **What to do**:
  - `Get-MtLdapDomainController.ps1`: add `IsGlobalCatalog`, `IsReadOnly`, `LdapPort`, `SslPort`. Fix scope to current domain only (not whole forest). After resolving the parent server object, check whether `serverReference` is within the default naming context; exclude DCs whose `serverReference` DN does not end with the default naming context. **Note**: This function currently only accepts `ConfigurationNamingContext`; it will need `DefaultNamingContext` as an additional parameter. Update `Get-MtADDomainState.ps1:211` (the sole caller) to pass `-DefaultNamingContext $protocolRootDse.DefaultNamingContext`.
  - `Get-MtLdapTrust.ps1`: add `Direction`, `IntraForest`, `Quarantined`, `SelectiveAuthentication`, `Target`, `LastValidated`. Convert `TrustType` to enum.
  - `Get-MtLdapForest.ps1`: fix `nCName` filtering to exclude DomainDnsZones/ForestDnsZones partitions. Add filter: `$_.nCName -notlike '*DnsZones,*'`.
  - `Get-MtLdapUser.ps1`: `primaryGroupID` is **already requested and mapped** — no change needed here.
  - `Get-MtLdapReplicationConnection.ps1`: add `Enabled`, `AutoGenerated`.
  - Site links: add `ReplicationFrequencyInMinutes` from raw `replInterval`. The site link data is queried inside `Get-MtLdapConfigurationContainer.ps1` (line 39) where `replInterval` is already requested — add the computed property there or in `Get-MtADDomainState.ps1`.
  - `Get-MtLdapGroupMember.ps1`: include members via primary group (Domain Users, Domain Computers, Domain Controllers). Add an optional `-AdState` parameter. When provided, resolve primary group membership by looking up users/computers whose `primaryGroupID` matches the group's `primaryGroupToken` from `$AdState.Users` / `$AdState.Computers` (avoids N+1 LDAP queries). When `-AdState` is absent, fall back to an LDAP query for primary group members. Update `Get-MtADDomainState.ps1` to call `Get-MtLdapGroupMember` with `-AdState $domainState` when building group membership (if group members are added to domain state), or update direct check callers to pass `$adState` if available.

  **Must NOT do**: Do not remove existing properties. Do not change return types of existing properties. Do not break current consumers.

  **Recommended Agent Profile**:
  - Category: `deep` — Reason: requires LDAP attribute knowledge and consumer compatibility verification
  - Skills: `[]`

  **Parallelization**: Can Parallel: YES | Wave 2 | Blocks: 7 | Blocked By: 1

  **References**:
  - Pattern: `powershell/internal/ad/queries/Get-MtLdapDomainController.ps1:13-14,37-46`
  - Pattern: `powershell/internal/ad/queries/Get-MtLdapTrust.ps1:15`
  - Pattern: `powershell/internal/ad/queries/Get-MtLdapForest.ps1:32,39-41`
  - Pattern: `powershell/internal/ad/queries/Get-MtLdapUser.ps1:13`
  - Pattern: `powershell/internal/ad/queries/Get-MtLdapReplicationConnection.ps1:15`
  - Pattern: `powershell/internal/ad/queries/Get-MtLdapGroupMember.ps1:47`

  **Acceptance Criteria**:
  - [ ] Every missing property from #2282 item 5 is present
  - [ ] `Test-MtAdDcNonGlobalCatalogCount`, `Test-MtAdTrustInterForestCount`, `Test-MtAdUserNonStandardPrimaryGroupCount`, etc. return correct values
  - [ ] `Get-MtLdapDomainController` returns only current domain DCs
  - [ ] `Get-MtLdapForest` excludes DomainDnsZones and ForestDnsZones partitions

  **QA Scenarios**:
  ```
  Scenario: DC query returns GC/RODC/LdapPort/SslPort
    Tool: Bash (pwsh/Pester)
    Steps: Mock DC with options flags; run Get-MtLdapDomainController
    Expected: All four properties present and correctly typed
    Evidence: .sisyphus/evidence/plan12-task-4-dc-properties.txt

  Scenario: Trust query returns Direction/IntraForest
    Tool: Bash (pwsh/Pester)
    Steps: Mock trust objects; run Get-MtLdapTrust
    Expected: Direction and IntraForest correctly derived from trustDirection/trustAttributes
    Evidence: .sisyphus/evidence/plan12-task-4-trust-properties.txt

  Scenario: Group member includes primary group members
    Tool: Bash (pwsh/Pester)
    Steps: Mock group with primaryGroupID members; run Get-MtLdapGroupMember
    Expected: Members via primary group are included in output
    Evidence: .sisyphus/evidence/plan12-task-4-primary-group.txt

  Scenario: Forest query excludes DNS zones
    Tool: Bash (pwsh/Pester)
    Steps: Mock partitions including DomainDnsZones; run Get-MtLdapForest
    Expected: DomainDnsZones and ForestDnsZones excluded from domain list
    Evidence: .sisyphus/evidence/plan12-task-4-forest-dnszones.txt
  ```

  **Commit**: YES
  - Message: `fix(ad): add missing properties to LDAP query objects`
  - Files: `powershell/internal/ad/queries/Get-MtLdapDomainController.ps1`, `Get-MtLdapTrust.ps1`, `Get-MtLdapForest.ps1`, `Get-MtLdapReplicationConnection.ps1`, `Get-MtLdapGroupMember.ps1`, `Get-MtLdapConfigurationContainer.ps1`, `powershell/public/Get-MtADDomainState.ps1`, site link query

- [ ] 5. Add non-Windows platform guards at the converter layer

  **What to do**:
  - Modify `ConvertFrom-MtLdapSecurityDescriptor.ps1` to catch `PlatformNotSupportedException` around the `RawSecurityDescriptor` constructor (line 100) and return `$null`.
  - Modify `ConvertFrom-MtLdapValue.ps1` to catch `PlatformNotSupportedException` for `ntsecuritydescriptor` at lines 188–189 and return `$null` (not raw bytes `$Value`).
  - Add a null guard in `Get-MtADGpoState.ps1` before accessing `$descriptor.Access` (around line 184): `if ($null -eq $descriptor) { continue }`.
  - Ensure `Get-MtADDomainState.ps1` propagates `$null` for `DaclEntries` when `Get-MtLdapDacl` returns `$null` (covered by Task 1).
  - Add `.DESCRIPTION` notes to the 18 existing DACL checks in `powershell/public/ad/dacl/` indicating that DACL analysis requires Windows and will skip on non-Windows platforms. The checks themselves do NOT need platform guards — they consume pre-parsed `$adState.DaclEntries` and will naturally skip when `DaclEntries` is `$null` (handled by Task 1 + Task 6 null guards).

  **Must NOT do**: Do NOT add platform guards to individual check files. Do NOT create `Assert-MtWindowsPlatform`. Do NOT modify GPO permission checks (`Test-MtAdGpoNoPermissionsCount`, `Test-MtAdGpoDenyAceCount`) — they consume `GpoReports`, not raw security descriptors.

  **Recommended Agent Profile**:
  - Category: `deep` — Reason: platform-specific behavior and converter-layer architecture
  - Skills: `[]`

  **Parallelization**: Can Parallel: YES | Wave 2 | Blocks: 7 | Blocked By: 1

  **References**:
  - Pattern: `powershell/internal/ad/protocol/ConvertFrom-MtLdapSecurityDescriptor.ps1:100`
  - Pattern: `powershell/internal/ad/protocol/ConvertFrom-MtLdapValue.ps1:188-189`
  - Pattern: `powershell/public/Get-MtADGpoState.ps1:184`
  - Pattern: `powershell/internal/ad/queries/Get-MtLdapDacl.ps1:22` (already has `$null` guard)
  - Existing DACL checks: `powershell/public/ad/dacl/Test-MtAdDaclOuObjectCount.ps1`, `Test-MtAdDaclPrivilegedExtendedRightIdentity.ps1`, `Test-MtAdDaclInheritedObjectTypeCount.ps1`, `Test-MtAdDaclNonInheritedAceCount.ps1`, `Test-MtAdDaclPrivilegedExtendedRightCount.ps1`, `Test-MtAdDaclUnresolvedSidCount.ps1`, `Test-MtAdDaclPrivilegedExtendedRightDetails.ps1`, `Test-MtAdDaclPrivilegedAllowAceDetails.ps1`, `Test-MtAdDaclInheritedObjectTypeDetails.ps1`, `Test-MtAdDaclUnresolvedSidDetails.ps1`, `Test-MtAdDaclPrivilegedAllowAceCount.ps1`, `Test-MtAdDaclDenyAceCount.ps1`, `Test-MtAdDaclConflictObjectCount.ps1`, `Test-MtAdDaclDenyAceDetails.ps1`, `Test-MtAdDaclDistinctIdentityCount.ps1`, `Test-MtAdDaclConflictObjectDetails.ps1`, `Test-MtAdDaclDistinctObjectCount.ps1`, `Test-MtAdDaclIdentityAceDistribution.ps1`

  **Acceptance Criteria**:
  - [ ] `ConvertFrom-MtLdapSecurityDescriptor` returns `$null` on non-Windows instead of throwing
  - [ ] `ConvertFrom-MtLdapValue` returns `$null` for `ntsecuritydescriptor` on non-Windows
  - [ ] `Get-MtADGpoState` handles `$null` descriptor gracefully (no error at line 184)
  - [ ] All 18 DACL checks have `.DESCRIPTION` note about Windows-only requirement
  - [ ] Windows behavior unchanged

  **QA Scenarios**:
  ```
  Scenario: Security descriptor conversion returns null on non-Windows
    Tool: Bash (pwsh/Pester)
    Steps: Mock PlatformNotSupportedException from RawSecurityDescriptor; run ConvertFrom-MtLdapSecurityDescriptor
    Expected: Returns $null
    Evidence: .sisyphus/evidence/plan12-task-5-converter-null.txt

  Scenario: DACL check skips when DaclEntries is null
    Tool: Bash (pwsh/Pester)
    Steps: Mock $adState.DaclEntries = $null; run Test-MtAdDaclDistinctObjectCount
    Expected: Returns $null (skipped by Task 6 null guard), not error
    Evidence: .sisyphus/evidence/plan12-task-5-dacl-skip.txt
  ```

  **Commit**: YES
  - Message: `fix(ad): return $null from converters on non-Windows platforms`
  - Files: `powershell/internal/ad/protocol/ConvertFrom-MtLdapSecurityDescriptor.ps1`, `ConvertFrom-MtLdapValue.ps1`, `powershell/public/Get-MtADGpoState.ps1`, and `.DESCRIPTION` sections of 18 DACL checks in `powershell/public/ad/dacl/`

- [ ] 6. Fix null guards and value mapping edge cases across consumer checks

  **What to do**:
  - Fix `ConvertFrom-MtLdapValue.ps1:67-69` `[long]::MinValue` mapping: preserve it as a sentinel for "never" instead of converting to `$null`. Return `[timespan]::MaxValue` as the sentinel (preserves `.Days`/`.TotalMinutes` property access for existing consumers). Update the following consumers to handle the sentinel explicitly:
    - `Test-MtAdPasswordMaxAge.ps1` (lines 38-54): add branch for `[timespan]::MaxValue` meaning "never expires"
    - `Test-MtAdAccountLockoutDuration.ps1` (lines 38-49): add branch for `[timespan]::MaxValue` meaning "never"
    - `Test-MtAdFineGrainedPolicySettingCounts.ps1` (line 52): handle `[timespan]::MaxValue` in `MaxPwdAge` comparison
    - `Test-MtAdFineGrainedPolicyValueCount.ps1` (line 47): handle `[timespan]::MaxValue` in `MaxPwdAge` comparison
  - Fix null guards in `Test-MtAdPasswordComplexityRequired.ps1:38-41`:
    - Add explicit `$null` guard before bit mask: `if ($null -eq $passwordPolicy -or $null -eq $passwordPolicy.PwdProperties) { Add-MtTestResultDetail -SkippedBecause ...; return $null }`
    - Current bug: when `PwdProperties` is `$null`, `$complexityEnabled` evaluates to `$false`, and `$testResult = $null -ne $complexityEnabled` becomes `$true` (false pass).
  - Fix null guards in `Test-MtAdKrbtgtLastLogon.ps1:43`:
    - Add explicit `$null` guard: `if ($null -eq $users) { Add-MtTestResultDetail -SkippedBecause ...; return $null }` before filtering for krbtgt.
    - Current bug: after Task 1, `$adState.Users` will be `$null` on collection failure, but the check returns `$false` ("KRBTGT account not found") which is a test failure rather than a skip.
  - **Fix `.Count -eq 0` null guards across AD checks that currently lack explicit `$null` guards.** Even after Task 1's `$null` propagation, checks like `Test-MtAdComputerNonDcUnconstrainedDelegationCount` compute `($nonDcUnconstrainedCount -eq 0)` where `Measure-Object` on `$null` returns `0`, causing a false pass. Add explicit `$null -eq $collection` guards before counting. **Only target checks where the pattern is `if ($var.Count -eq 0)` without a preceding `$null -eq` guard.** Checks that already use `if ($null -eq $var -or $var.Count -eq 0)` are correct and should be skipped. Affected checks include (but are not limited to):
    - `Test-MtAdDcSmbv311EnabledCount.ps1`, `Test-MtAdDcSmbSigningEnabledCount.ps1`, `Test-MtAdDcSmbv1EnabledCount.ps1`
    - `Test-MtAdGroupEmptyNonPrivilegedDetails.ps1`
    - `Test-MtAdGroupMemberForeignSidDetails.ps1`
    - `Test-MtAdGroupPrivilegedWithMembersDetails.ps1`
    - `Test-MtAdDaclPrivilegedExtendedRightDetails.ps1`
    - `Test-MtAdDaclPrivilegedAllowAceDetails.ps1`
    - `Test-MtAdDaclIdentityAceDistribution.ps1`
    - `Test-MtAdComputerNonDcUnconstrainedDelegationCount.ps1` and other delegation/count checks
    - Any other AD check that accesses `.Count` on a collection derived from `Get-MtADDomainState` without a prior `$null -eq` guard.
  - **Note**: `Get-MtSysvolContent.ps1` (cpassword empty-string false positive) exists on `main` branch only. Defer to a separate main-branch plan. Do NOT include in this branch's work.

  **Must NOT do**: Do not change the threshold semantics — only fix the edge-case handling. Do not search for `Get-MtSysvolContent.ps1` in this branch.

  **Recommended Agent Profile**:
  - Category: `deep` — Reason: multiple small but precise fixes across several files
  - Skills: `[]`

  **Parallelization**: Can Parallel: YES | Wave 2 | Blocks: 7 | Blocked By: 1

  **References**:
  - Pattern: `powershell/internal/ad/protocol/ConvertFrom-MtLdapValue.ps1:67-69`
  - Pattern: `powershell/public/ad/passwordpolicy/Test-MtAdPasswordComplexityRequired.ps1:38-41`
  - Pattern: `powershell/public/ad/security/Test-MtAdKrbtgtLastLogon.ps1:43`
  - Pattern: `powershell/public/ad/security/Test-MtAdComputerNonDcUnconstrainedDelegationCount.ps1`

  **Acceptance Criteria**:
  - [ ] `[long]::MinValue` maps to "never" sentinel, not `$null`
  - [ ] Failed queries in password complexity and krbtgt checks skip instead of pass
  - [ ] All `.Count -eq 0` checks on collection-derived variables have explicit `$null` guards for failed collection

  **QA Scenarios**:
  ```
  Scenario: Never password age is detected
    Tool: Bash (pwsh/Pester)
    Steps: Mock maxPwdAge = [long]::MinValue; run Test-MtAdPasswordMaxAge
    Expected: Reaches "never expires" branch, not "Unable to retrieve"
    Evidence: .sisyphus/evidence/plan12-task-6-never-value.txt

  Scenario: Failed password complexity query skips
    Tool: Bash (pwsh/Pester)
    Steps: Mock domain state with $null complexity data; run Test-MtAdPasswordComplexityRequired
    Expected: Returns $null with skip reason, not $true
    Evidence: .sisyphus/evidence/plan12-task-6-complexity-skip.txt

  Scenario: Count check skips on null collection
    Tool: Bash (pwsh/Pester)
    Steps: Mock $adState.Computers = $null; run Test-MtAdComputerNonDcUnconstrainedDelegationCount
    Expected: Returns $null with skip reason, not $true
    Evidence: .sisyphus/evidence/plan12-task-6-count-null-skip.txt
  ```

  **Commit**: YES
  - Message: `fix(ad): add null guards and correct value mapping edge cases`
  - Files: `ConvertFrom-MtLdapValue.ps1`, `Test-MtAdPasswordComplexityRequired.ps1`, `Test-MtAdKrbtgtLastLogon.ps1`, `Test-MtAdPasswordMaxAge.ps1`, `Test-MtAdAccountLockoutDuration.ps1`, `Test-MtAdFineGrainedPolicySettingCounts.ps1`, `Test-MtAdFineGrainedPolicyValueCount.ps1`, and all AD checks with `.Count -eq 0` on collection-derived variables

- [ ] 7. Integration validation and regression testing

  **What to do**:
  - Run `./powershell/tests/pester.ps1`.
  - Run structural scan for `@()` error fallbacks across all 20 collectors.
  - Run structural scan for `.Count -eq 0` or `-eq 0` checks on collection-derived variables **without** explicit `$null` guards. Verify that Task 6 has addressed all such checks. **Use broad scan**: `grep -rn 'Count -eq 0' powershell/public/ad/ | grep -v 'null -eq'` to catch both `if ($var.Count -eq 0)` and `$testResult = ($count -eq 0)` patterns. Also scan for `Measure-Object` followed by `-eq 0` on variables derived from `$adState.*` properties.
  - Run fixture-based validation for all changes in Tasks 1–6.
  - Capture evidence of zero regressions in existing AD checks.

  **Must NOT do**: Do not skip tests or waive failures.

  **Recommended Agent Profile**:
  - Category: `unspecified-high` — Reason: broad validation across modified files
  - Skills: `[]`

  **Parallelization**: Can Parallel: NO | Wave 2 | Blocks: F1–F4 | Blocked By: 2, 3, 4, 5, 6

  **References**:
  - Pattern: `./powershell/tests/pester.ps1`

  **Acceptance Criteria**:
  - [ ] `pester.ps1` passes
  - [ ] Zero `@()` error fallbacks remain in all 20 collectors
  - [ ] Zero wrong bit masks
  - [ ] Zero inverted status mappings in consumers
  - [ ] All new properties present in fixtures
  - [ ] All `.Count -eq 0` checks on collection-derived variables have explicit `$null` guards for failed collection

  **QA Scenarios**:
  ```
  Scenario: Full regression test
    Tool: Bash (pwsh)
    Steps: Run pester.ps1; grep for banned patterns
    Expected: All pass; zero banned patterns
    Evidence: .sisyphus/evidence/plan12-task-7-regression.txt
  ```

  **Commit**: NO (evidence only)

---

## Final Verification Wave
> Run in parallel after Task 7. All must approve.

- [ ] F1. Plan Compliance Audit — `oracle`
  Verify: all must-fix items from #2282 are addressed (except cpassword deferred); no breaking changes to public contracts; no `@()` error fallbacks remain in any of the 20 collectors; GPO status fix is in consumers (not producer); producer mapping left untouched.
  Expected: `APPROVE`

- [ ] F2. Code Quality Review — `unspecified-high`
  Verify: no empty catch blocks, no `+=` in hot paths, no hardcoded credentials, analyzer clean.
  Expected: `APPROVE`

- [ ] F3. Real QA Execution — `unspecified-high`
  Verify: run pester.ps1; run fixture tests for bit mask, GPO status, properties, platform guards.
  Expected: `APPROVE`

- [ ] F4. Scope Fidelity Check — `deep`
  Verify: no transport changes, no check threshold changes beyond corrections, no generated-doc edits.
  Expected: `APPROVE`

---

## Commit Strategy
- `fix(ad): propagate collector failures as $null instead of @()`
- `fix(ad): correct reversible encryption bit mask to 0x10`
- `fix(ad): correct GPO status consumer logic to match standard enum`
- `fix(ad): add missing properties to LDAP query objects`
- `fix(ad): skip descriptor-dependent checks on non-Windows platforms`
- `fix(ad): correct value mapping edge cases and null guards`

---

## Success Criteria
- All must-fix items from #2282 are resolved (except cpassword empty-string, deferred to main branch)
- Zero false passes from failed collection across all 20 collectors
- Zero inverted status reports in GPO consumer checks
- Complete query object properties
- Non-Windows platform guards in place with `.DESCRIPTION` notes
- `pwsh -NoProfile -File ./powershell/tests/pester.ps1` passes
- Final verification wave approves

