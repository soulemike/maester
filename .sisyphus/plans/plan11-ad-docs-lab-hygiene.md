# Plan 11: AD Documentation & Lab Hygiene Update

## TL;DR

> **Quick Summary**: Update 22+ companion `.md` files to remove references to deprecated ActiveDirectory/GroupPolicy/DnsServer modules, add `Connect-Maester` AD parameter documentation, remove plaintext lab secrets, and fix minor code hygiene issues.
>
> **Deliverables**: Updated companion `.md` files, modernized connect docs, secured lab scripts, fixed `.gitignore` and helper scripts, restored build test assertions.
>
> **Estimated Effort**: Small-Medium
> **Parallel Execution**: YES — 2 waves. Can execute in parallel with ALL other streams. No code behavior changes.
> **Critical Path**: Inventory → .md updates → connect docs → lab security → hygiene fixes → validation

---

## Context

### Original Request
Issue #2282 identified documentation gaps and security issues in Maester's Active Directory companion documentation and lab infrastructure after the protocol migration.

### Interview Summary
**Key Discussions**:
- 22 companion `.md` files still reference `Get-ADDefaultDomainPasswordPolicy`, `Get-ADTrust`, `Get-ADForest`, etc.
- `Connect-Maester` AD parameters are undocumented in the advanced connect guide.
- Lab scripts write plaintext passwords to disk and pass them on CLI.
- `.gitignore` contains personal entries.
- `Enable-WindowsOpenSSH.ps1` regex is broken without `(?m)`.
- `Build-MaesterModule.Tests.ps1` is missing two assertions.

**Research Findings**:
- Exact line numbers verified via grep and read for all 22 `.md` files.
- Git history (`git show 0d45ef06`) confirmed the two removed assertions.
- `Connect-Maester.ps1:176-196` defines all 6 AD parameters.
- Lab scripts confirmed to persist plaintext passwords via direct file reads.

### Metis Review
**Identified Gaps** (addressed in plan):
- Guardrail added: No hand-editing of generated docs.
- Guardrail added: No changes to check logic or thresholds.
- Edge case: `config.json` deletion must not break scheduled-task finalize logic.
- Edge case: `--admin-password` may be unavoidable due to Azure CLI limitations; documented with `# SECURITY:` comment requirement.

---

## Work Objectives

### Core Objective
Bring AD documentation and lab infrastructure into alignment with the protocol-migrated codebase, removing references to removed modules and eliminating plaintext credential persistence.

### Concrete Deliverables
- 22 updated companion `.md` files under `powershell/public/ad/`
- New AD section in `website/docs/connect-maester/connect-maester-advanced.md`
- Encrypted/deleted credentials in `New-DomainController.ps1`
- Mitigated `--admin-password` exposure in `New-RunnerVm.ps1`
- Clean `.gitignore`
- Fixed regex in `Enable-WindowsOpenSSH.ps1`
- Restored assertions in `Build-MaesterModule.Tests.ps1`

### Definition of Done
- [ ] `grep` for all banned module names in `.md` files returns empty.
- [ ] `grep` for plaintext password persistence in lab scripts returns empty (or only `# SECURITY:` documented exceptions).
- [ ] `pwsh -NoProfile -File ./powershell/tests/pester.ps1` passes.
- [ ] `cd website && npm run build` completes without errors (if connect docs changed).

### Must Have
- Every `powershell/public/ad/**/*.md` file audited for `Get-AD*`, `Get-GPO*`, `Get-DnsServer*` references and updated to describe protocol-based collection.
- `website/docs/connect-maester/connect-maester-advanced.md` updated with AD parameter matrix.
- Lab scripts use SecureString/credential objects instead of plaintext JSON; temp files deleted after use.
- `.gitignore` personal entries removed or moved to user-level git config.
- `Enable-WindowsOpenSSH.ps1` regex fixed.
- `Build-MaesterModule.Tests.ps1` assertions restored.

### Must NOT Have (Guardrails)
- No hand-editing of generated docs under `website/docs/commands/`, `website/docs/tests/`, or versioned docs.
- No changes to check logic, thresholds, or collector behavior.
- No breaking changes to public APIs.
- No removal of legitimate `.gitignore` entries (e.g., build artifacts).

---

## Verification Strategy

> **ZERO HUMAN INTERVENTION** — ALL verification is agent-executed. No exceptions.

### Test Decision
- **Infrastructure exists**: YES (Pester, Docusaurus)
- **Automated tests**: Tests-after (no new test files; existing pester.ps1 + grep validation)
- **Framework**: Pester (via `./powershell/tests/pester.ps1`)

### QA Policy
Every task MUST include agent-executed QA scenarios. Evidence saved to `.sisyphus/evidence/plan11-task-{N}-{scenario-slug}.{ext}`.

- **Documentation**: Grep validation for banned patterns.
- **Lab scripts**: Grep validation for plaintext persistence.
- **Build tests**: `pwsh -NoProfile -File ./powershell/tests/pester.ps1`
- **Website**: `cd website && npm run build`

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Start Immediately - documentation updates, all parallel):
├── Task 1.1: Update password policy companion .md files [writing]
├── Task 1.2: Update trust, domain, site, gpo companion .md files [writing]
└── Task 1.3: Add Connect-Maester AD parameter documentation [writing]

Wave 2 (After Wave 1 - lab security + hygiene + validation):
├── Task 2.1: Eliminate plaintext password persistence in lab scripts [deep]
├── Task 2.2: Fix .gitignore personal entries and OpenSSH regex [quick]
├── Task 2.3: Restore build test assertions [quick]
└── Task 2.4: Automated validation & evidence collection [unspecified-low]

Critical Path: Task 1.1/1.2/1.3 → Task 2.1/2.2/2.3 → Task 2.4
Parallel Speedup: ~60% faster than sequential
Max Concurrent: 3 (Wave 1)
```

### Dependency Matrix

| Task | Depends On | Blocks |
|---|---|---|
| 1.1 | — | — |
| 1.2 | — | — |
| 1.3 | — | — |
| 2.1 | — | — |
| 2.2 | — | — |
| 2.3 | — | — |
| 2.4 | 1.1, 1.2, 1.3, 2.1, 2.2, 2.3 | — |

> All Wave 1 and Wave 2 implementation tasks are independent. Task 2.4 validation must wait for all implementation to complete.

### Agent Dispatch Summary

- **Wave 1**: 3 tasks → `writing` + `maester-test-expert`
- **Wave 2**: 3 implementation tasks → `deep` + `maester-test-expert` (2.1), `quick` + `git-master` (2.2), `quick` + `maester-test-expert` (2.3)
- **Wave 2 Validation**: 1 task → `unspecified-low`

---

## TODOs

- [ ] 1.1. **Update Password Policy Companion `.md` Files**

  **What to do**:
  - Edit 7 companion `.md` files under `powershell/public/ad/passwordpolicy/` to replace references to `Get-ADDefaultDomainPasswordPolicy` with descriptions of the protocol-based LDAP collection used by the actual check code (e.g., `Get-MtADDomainState -Categories PasswordPolicy`, `Invoke-MtLdapSearch`).
  - Edit 4 companion `.md` files under `powershell/public/ad/passwordpolicy/` to replace references to `Get-ADFineGrainedPasswordPolicy` with protocol-based descriptions.
  - For each file, read the corresponding `.ps1` to identify the actual collector function, then describe that in the `.md`.
  - Update "Prerequisites" sections to reference `Connect-Maester -Service ActiveDirectory` instead of "install the Active Directory module."

  **Must NOT do**:
  - Do not change `.ps1` check logic, thresholds, or test behavior.
  - Do not hand-edit generated docs under `website/docs/commands/` or `website/docs/tests/`.
  - Do not remove the "Prerequisites" section entirely.

  **Recommended Agent Profile**:
  - **Category**: `writing`
    - Reason: Documentation-heavy task requiring markdown editing and technical accuracy.
  - **Skills**: `maester-test-expert`
    - Reason: Need to understand protocol-based AD collection to describe it correctly.

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1.2, 1.3)
  - **Blocks**: None
  - **Blocked By**: None

  **References**:
  - `powershell/public/ad/passwordpolicy/Test-MtAdPasswordComplexityRequired.md:29`
  - `powershell/public/ad/passwordpolicy/Test-MtAdPasswordHistoryCount.md:25`
  - `powershell/public/ad/passwordpolicy/Test-MtAdPasswordMaxAge.md:25`
  - `powershell/public/ad/passwordpolicy/Test-MtAdPasswordMinLength.md:29`
  - `powershell/public/ad/passwordpolicy/Test-MtAdPasswordReversibleEncryption.md:31`
  - `powershell/public/ad/passwordpolicy/Test-MtAdAccountLockoutDuration.md:25`
  - `powershell/public/ad/passwordpolicy/Test-MtAdFineGrainedPolicyCount.md:31`
  - `powershell/public/ad/passwordpolicy/Test-MtAdFineGrainedPolicyAppliesTo.md:33`
  - `powershell/public/ad/passwordpolicy/Test-MtAdFineGrainedPolicyValueCount.md:30`
  - `powershell/public/ad/passwordpolicy/Test-MtAdFineGrainedPolicySettingCounts.md:32`
  - Pattern: Read corresponding `.ps1` to find collector function (e.g., `Get-MtADDomainState`, `Invoke-MtLdapSearch`).

  **Acceptance Criteria**:
  - [ ] Zero occurrences of `Get-ADDefaultDomainPasswordPolicy` remain in the 7 default-policy `.md` files.
  - [ ] Zero occurrences of `Get-ADFineGrainedPasswordPolicy` remain in the 4 FGPP `.md` files.
  - [ ] Each updated `.md` describes the protocol-based collection method.
  - [ ] No generated docs were modified.

  **QA Scenarios**:
  ```
  Scenario: Verify banned patterns removed from password policy docs
    Tool: Bash (grep)
    Preconditions: Task 1.1 edits committed
    Steps:
      1. Run: grep -rE 'Get-ADDefaultDomainPasswordPolicy|Get-ADFineGrainedPasswordPolicy' powershell/public/ad/passwordpolicy/*.md
    Expected Result: Command returns no output (exit 1 with no matches)
    Failure Indicators: Any match indicates incomplete update
    Evidence: .sisyphus/evidence/plan11-task-1.1-passwordpolicy-grep.log
  ```

  **Evidence to Capture**:
  - [ ] `plan11-task-1.1-passwordpolicy-grep.log` — grep output showing zero matches

  **Commit**: YES
  - Message: `docs(ad): update password policy companion docs for protocol-based collection`
  - Files: `powershell/public/ad/passwordpolicy/*.md`

- [ ] 1.2. **Update Trust, Domain, Site, and GPO Companion `.md` Files**

  **What to do**:
  - Edit 12 companion `.md` files under `powershell/public/ad/trust/`, `powershell/public/ad/domain/`, `powershell/public/ad/site/`, and `powershell/public/ad/gpo/` to replace `Get-ADTrust`, `Get-ADForest`, `Get-ADDomain`, `Get-ADRootDSE`, `Get-ADReplicationSubnet`, `Get-ADReplicationSite`, and `Get-ADOrganizationalUnit` references with protocol-based descriptions.
  - For each file, read the corresponding `.ps1` to identify the actual collector function, then describe that in the `.md`.
  - Update "Prerequisites" sections to reference `Connect-Maester -Service ActiveDirectory` instead of "install the Active Directory module."

  **Must NOT do**:
  - Do not change `.ps1` check logic.
  - Do not hand-edit generated docs.
  - Do not introduce new RSAT module references.

  **Recommended Agent Profile**:
  - **Category**: `writing`
    - Reason: Documentation-heavy task.
  - **Skills**: `maester-test-expert`
    - Reason: Need to understand protocol-based AD collection.

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1.1, 1.3)
  - **Blocks**: None
  - **Blocked By**: None

  **References**:
  - `powershell/public/ad/trust/Test-MtAdTrustTotalCount.md:24`
  - `powershell/public/ad/trust/Test-MtAdTrustStaleDetails.md:35,38`
  - `powershell/public/ad/domain/Test-MtAdCrossForestReferencesCount.md:25`
  - `powershell/public/ad/domain/Test-MtAdAllowedDnsSuffixesCount.md:25`
  - `powershell/public/ad/domain/Test-MtAdUpnSuffixesCount.md:21`
  - `powershell/public/ad/domain/Test-MtAdUpnSuffixesDetails.md:23`
  - `powershell/public/ad/domain/Test-MtAdSpnSuffixesCount.md:22`
  - `powershell/public/ad/domain/Test-MtAdTombstoneLifetime.md:25`
  - `powershell/public/ad/site/Test-MtAdSubnetTotalCount.md:23`
  - `powershell/public/ad/site/Test-MtAdSiteTotalCount.md:24`
  - `powershell/public/ad/gpo/Test-MtAdGpoBlockedInheritanceCount.md:24`
  - `powershell/public/ad/gpo/Test-MtAdGpoUnlinkedTargetCount.md:24`

  **Acceptance Criteria**:
  - [ ] Zero occurrences of `Get-ADTrust`, `Get-ADForest`, `Get-ADDomain`, `Get-ADRootDSE`, `Get-ADReplicationSubnet`, `Get-ADReplicationSite`, `Get-ADOrganizationalUnit` remain in these 12 `.md` files.
  - [ ] Each file accurately describes the LDAP/protocol collection method used by the corresponding `.ps1`.
  - [ ] Prerequisites sections no longer mention installing RSAT or the Active Directory module.

  **QA Scenarios**:
  ```
  Scenario: Verify banned patterns removed from trust/domain/site/gpo docs
    Tool: Bash (grep)
    Preconditions: Task 1.2 edits committed
    Steps:
      1. Run: grep -rE 'Get-AD(Trust|Forest|Domain|RootDSE|ReplicationSubnet|ReplicationSite|OrganizationalUnit)' powershell/public/ad/{trust,domain,site,gpo}/*.md
    Expected Result: Command returns no output
    Failure Indicators: Any match indicates incomplete update
    Evidence: .sisyphus/evidence/plan11-task-1.2-trust-domain-grep.log
  ```

  **Evidence to Capture**:
  - [ ] `plan11-task-1.2-trust-domain-grep.log` — grep output showing zero matches

  **Commit**: YES
  - Message: `docs(ad): update trust, domain, site, and gpo companion docs for protocol-based collection`
  - Files: `powershell/public/ad/{trust,domain,site,gpo}/*.md`

- [ ] 1.3. **Add `Connect-Maester` Active Directory Parameter Documentation**

  **What to do**:
  - Append a new "Active Directory" section to `website/docs/connect-maester/connect-maester-advanced.md` documenting the AD parameter matrix.
  - Document: `-ActiveDirectoryServer`, `-ActiveDirectoryDomain`, `-ActiveDirectoryForest`, `-ActiveDirectoryCredential`, `-ActiveDirectoryAuthMode` (`Negotiate` | `Basic` | `Kerberos`), `-ActiveDirectoryTlsMode` (`Auto` | `Ldaps` | `StartTls` | `None`).
  - Include examples for: (a) Windows implicit credentials, (b) non-Windows explicit credentials + LDAPS, (c) child domain with explicit credential.
  - Document non-Windows prerequisites: `System.DirectoryServices.Protocols` assembly, PS 7, no RSAT required.

  **Must NOT do**:
  - Do not modify generated command docs.
  - Do not document parameters that do not exist in `Connect-Maester.ps1`.
  - Do not break existing Docusaurus frontmatter or sidebar ordering.

  **Recommended Agent Profile**:
  - **Category**: `writing`
    - Reason: Technical documentation with code examples.
  - **Skills**: `maester-test-expert`
    - Reason: Need accurate AD parameter descriptions and examples.

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1.1, 1.2)
  - **Blocks**: None
  - **Blocked By**: None

  **References**:
  - `website/docs/connect-maester/connect-maester-advanced.md` (current end-of-file line 256)
  - `powershell/public/Connect-Maester.ps1:176-196` (parameter definitions)
  - `powershell/public/Connect-Maester.ps1:521-530` (AD connection logic)

  **Acceptance Criteria**:
  - [ ] New section added with heading `## Active Directory`.
  - [ ] Parameter matrix table covers all 6 AD parameters with allowed values.
  - [ ] At least 3 code examples: Windows implicit, non-Windows explicit LDAPS, child domain explicit.
  - [ ] Non-Windows prerequisites documented.
  - [ ] No syntax errors in markdown; Docusaurus builds successfully.

  **QA Scenarios**:
  ```
  Scenario: Verify AD parameters documented in connect advanced docs
    Tool: Bash (grep)
    Preconditions: Task 1.3 edits committed
    Steps:
      1. Run: grep -c 'ActiveDirectoryServer\|ActiveDirectoryCredential\|ActiveDirectoryAuthMode\|ActiveDirectoryTlsMode' website/docs/connect-maester/connect-maester-advanced.md
    Expected Result: Returns count >= 4
    Failure Indicators: Returns 0 or < 4
    Evidence: .sisyphus/evidence/plan11-task-1.3-connect-docs-grep.log

  Scenario: Verify Docusaurus builds without errors
    Tool: Bash
    Preconditions: Task 1.3 edits committed, node_modules present
    Steps:
      1. cd website && npm run build
    Expected Result: Exit code 0, no MDX/markdown errors
    Failure Indicators: Non-zero exit or error containing "MDX" or "markdown"
    Evidence: .sisyphus/evidence/plan11-task-1.3-docusaurus-build.log
  ```

  **Evidence to Capture**:
  - [ ] `plan11-task-1.3-connect-docs-grep.log` — grep count output
  - [ ] `plan11-task-1.3-docusaurus-build.log` — build output

  **Commit**: YES
  - Message: `docs(connect): add ActiveDirectory parameter matrix and examples`
  - Files: `website/docs/connect-maester/connect-maester-advanced.md`

- [ ] 2.1. **Eliminate Plaintext Password Persistence in Lab Scripts**

  **What to do**:
  1. In `New-DomainController.ps1`, change password parameters from `[string]` to `[SecureString]` where feasible, or accept `[PSCredential]` objects. If `ConvertTo-Json` serialization is required for the scheduled-task finalize script, encrypt sensitive values via `ConvertFrom-SecureString` before JSON serialization, and decrypt inside the scheduled task. After the scheduled task completes (or immediately after reading the config inside the finalize block), delete `C:\MaesterLab\config.json`.
  2. In `New-RunnerVm.ps1`, avoid passing `--admin-password` as a plaintext CLI argument. Use `--ssh-key-values` for Linux and Azure Key Vault reference or secure parameter passing for Windows where the Azure CLI supports it. If plaintext CLI passing is unavoidable due to Azure CLI limitations, document the risk and recommend Key Vault or SSH keys in a comment.

  **Must NOT do**:
  - Do not break the lab deployment sequence or the scheduled-task finalize logic.
  - Do not introduce new hardcoded secrets.
  - Do not remove the `config.json` read logic without ensuring the finalize script still receives its inputs.

  **Recommended Agent Profile**:
  - **Category**: `deep`
    - Reason: Requires careful refactoring of credential flow without breaking lab deployment.
  - **Skills**: `maester-test-expert`
    - Reason: Understanding of AD lab requirements and credential handling patterns.

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 2.2, 2.3)
  - **Blocks**: None
  - **Blocked By**: None

  **References**:
  - `build/activeDirectory/azure-lab/New-DomainController.ps1:380-412` (parameter declarations and JSON write)
  - `build/activeDirectory/azure-lab/New-DomainController.ps1:418-419` (JSON read inside `$finalizeScript`)
  - `build/activeDirectory/azure-lab/New-RunnerVm.ps1:286-298` (`az vm create` argument list)

  **Acceptance Criteria**:
  - [ ] `New-DomainController.ps1` no longer writes plaintext passwords to `config.json`; values are encrypted with `ConvertFrom-SecureString` or stored as SecureString.
  - [ ] `New-DomainController.ps1` deletes `config.json` after the finalize script completes (or the finalize script deletes it after reading).
  - [ ] `New-RunnerVm.ps1` no longer passes `--admin-password` with a plaintext string variable if an alternative exists; if unavoidable, a `# SECURITY:` comment documents the limitation and references Key Vault/SSH-key mitigation.
  - [ ] Lab README or inline comments updated to reflect secure credential handling.

  **QA Scenarios**:
  ```
  Scenario: Verify no plaintext passwords written to config.json
    Tool: Bash (grep)
    Preconditions: Task 2.1 edits committed
    Steps:
      1. Run: grep -n 'config.json' build/activeDirectory/azure-lab/New-DomainController.ps1
      2. Verify both Set-Content and Remove-Item lines present
      3. Run: grep -A 20 '$configuration = \[ordered\]@{' build/activeDirectory/azure-lab/New-DomainController.ps1 | grep -E 'TestUserPassword|SafeModePassword|PromotionPassword|DomainJoinUserPassword'
    Expected Result: No bare string password assignments in JSON serialization block; Remove-Item present
    Failure Indicators: Plaintext password properties still in ConvertTo-Json call; no Remove-Item
    Evidence: .sisyphus/evidence/plan11-task-2.1-lab-secrets-grep.log

  Scenario: Verify admin-password mitigation in runner script
    Tool: Bash (grep)
    Preconditions: Task 2.1 edits committed
    Steps:
      1. Run: grep -n '--admin-password' build/activeDirectory/azure-lab/New-RunnerVm.ps1
    Expected Result: Either absent or accompanied by # SECURITY: comment
    Failure Indicators: Plaintext --admin-password with no security comment
    Evidence: .sisyphus/evidence/plan11-task-2.1-runner-password-grep.log
  ```

  **Evidence to Capture**:
  - [ ] `plan11-task-2.1-lab-secrets-grep.log` — config.json grep output
  - [ ] `plan11-task-2.1-runner-password-grep.log` — runner password grep output

  **Commit**: YES
  - Message: `security(lab): encrypt lab credentials and delete temp config files`
  - Files: `build/activeDirectory/azure-lab/New-DomainController.ps1`, `build/activeDirectory/azure-lab/New-RunnerVm.ps1`

- [ ] 2.2. **Fix `.gitignore` Personal Entries and OpenSSH Regex**

  **What to do**:
  1. Remove `.gitignore` lines 535 (`PowerShellEditorServices.json`) and 538 (`.sisyphus/`). These are personal developer artifacts and should live in the user's global `~/.gitignore` or `.git/info/exclude`, not the project `.gitignore`.
  2. In `Enable-WindowsOpenSSH.ps1`, add the `(?m)` multiline regex option to the `-match` and `-replace` operations on lines 139-140 so they match `PasswordAuthentication` anywhere in the file, not just at the absolute start.

  **Must NOT do**:
  - Do not remove legitimate `.gitignore` entries (build artifacts, `node_modules/`, `module/`, `test-results/`, etc.).
  - Do not change any other behavior in `Enable-WindowsOpenSSH.ps1`.

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Small, targeted edits.
  - **Skills**: `git-master`
    - Reason: Understanding gitignore best practices.

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 2.1, 2.3)
  - **Blocks**: None
  - **Blocked By**: None

  **References**:
  - `.gitignore:535` (`PowerShellEditorServices.json`)
  - `.gitignore:538` (`.sisyphus/`)
  - `build/activeDirectory/azure-lab/Enable-WindowsOpenSSH.ps1:138-141`

  **Acceptance Criteria**:
  - [ ] `PowerShellEditorServices.json` and `.sisyphus/` no longer appear in `.gitignore`.
  - [ ] `Enable-WindowsOpenSSH.ps1` line 139 reads: `if ($sshdConfig -notmatch '(?m)^PasswordAuthentication no') {`
  - [ ] `Enable-WindowsOpenSSH.ps1` line 140 reads: `$sshdConfig = $sshdConfig -replace '(?m)^#?PasswordAuthentication.*$', 'PasswordAuthentication no'`

  **QA Scenarios**:
  ```
  Scenario: Verify personal entries removed from gitignore
    Tool: Bash (grep)
    Preconditions: Task 2.2 edits committed
    Steps:
      1. Run: grep -n 'PowerShellEditorServices.json\|\.sisyphus/' .gitignore
    Expected Result: No output
    Failure Indicators: Any match means entries still present
    Evidence: .sisyphus/evidence/plan11-task-2.2-gitignore-grep.log

  Scenario: Verify OpenSSH regex uses multiline flag
    Tool: Bash (grep)
    Preconditions: Task 2.2 edits committed
    Steps:
      1. Run: grep -n '(?m)^PasswordAuthentication' build/activeDirectory/azure-lab/Enable-WindowsOpenSSH.ps1
    Expected Result: Returns 2 matches (one for -notmatch, one for -replace)
    Failure Indicators: Returns 0 or 1 match
    Evidence: .sisyphus/evidence/plan11-task-2.2-openssh-regex-grep.log
  ```

  **Evidence to Capture**:
  - [ ] `plan11-task-2.2-gitignore-grep.log` — gitignore grep output
  - [ ] `plan11-task-2.2-openssh-regex-grep.log` — OpenSSH regex grep output

  **Commit**: YES
  - Message: `chore(hygiene): remove personal gitignore entries and fix OpenSSH regex`
  - Files: `.gitignore`, `build/activeDirectory/azure-lab/Enable-WindowsOpenSSH.ps1`

- [ ] 2.3. **Restore Build Test Assertions**

  **What to do**:
  - Re-add the two assertions removed from `powershell/tests/general/Build-MaesterModule.Tests.ps1` in commit `0d45ef06`.
  - Insert them immediately before the `$Psm1Content | Should -Match 'function Get-TestThing'` line in the "When building a valid fixture" context.
  - The two assertions are:
    - `$Psm1Content | Should -Match '# Fixture module preamble'`
    - `$Psm1Content | Should -Not -Match '# Fixture runtime body'`

  **Must NOT do**:
  - Do not remove the existing `foreach ($SessionKey in ...)` assertion block.
  - Do not modify the build script (`Build-MaesterModule.ps1`); the user explicitly stated it did not change.

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Simple assertion restoration.
  - **Skills**: `maester-test-expert`
    - Reason: Understanding of build test structure.

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 2.1, 2.2)
  - **Blocks**: None
  - **Blocked By**: None

  **References**:
  - `powershell/tests/general/Build-MaesterModule.Tests.ps1:174-178` (current assertion block)
  - Git diff from `0d45ef06` showing removed lines:
    - `$Psm1Content | Should -Match '# Fixture module preamble'`
    - `$Psm1Content | Should -Not -Match '# Fixture runtime body'`

  **Acceptance Criteria**:
  - [ ] Both original assertions are present in the test file.
  - [ ] All existing assertions (including the `foreach` session-key block) remain intact.
  - [ ] `pwsh -NoProfile -File ./powershell/tests/pester.ps1` passes.

  **QA Scenarios**:
  ```
  Scenario: Verify preamble and runtime body assertions restored
    Tool: Bash (grep)
    Preconditions: Task 2.3 edits committed
    Steps:
      1. Run: grep -n 'Fixture module preamble\|Fixture runtime body' powershell/tests/general/Build-MaesterModule.Tests.ps1
    Expected Result: Returns 2 matches
    Failure Indicators: Returns 0 or 1 match
    Evidence: .sisyphus/evidence/plan11-task-2.3-assertions-grep.log

  Scenario: Verify pester suite passes with restored assertions
    Tool: Bash
    Preconditions: Task 2.3 edits committed
    Steps:
      1. Run: pwsh -NoProfile -File ./powershell/tests/pester.ps1
    Expected Result: Exit code 0
    Failure Indicators: Non-zero exit or test failures in Build-MaesterModule context
    Evidence: .sisyphus/evidence/plan11-task-2.3-pester.log
  ```

  **Evidence to Capture**:
  - [ ] `plan11-task-2.3-assertions-grep.log` — assertion grep output
  - [ ] `plan11-task-2.3-pester.log` — pester test output

  **Commit**: YES
  - Message: `test(build): restore preamble and runtime body assertions in module build test`
  - Files: `powershell/tests/general/Build-MaesterModule.Tests.ps1`

- [ ] 2.4. **Automated Validation & Evidence Collection**

  **What to do**:
  1. Run the automated grep validation script to confirm zero banned module names remain in `.md` files.
  2. Run the automated grep validation script to confirm zero plaintext password patterns remain in lab scripts.
  3. Execute `pwsh -NoProfile -File ./powershell/tests/pester.ps1` and capture results.
  4. If `website/docs/connect-maester/connect-maester-advanced.md` was modified, run `cd website && npm ci && npm run build` to verify Docusaurus compiles.
  5. Write evidence files to `.sisyphus/evidence/plan11-task-{N}-{slug}.{ext}`.

  **Must NOT do**:
  - Do not commit evidence files to git.
  - Do not ignore pre-existing test failures; only assert that failures are pre-existing and unrelated.

  **Recommended Agent Profile**:
  - **Category**: `unspecified-low`
    - Reason: Script runner / orchestrator task.
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Sequential after Tasks 2.1–2.3 complete.
  - **Blocks**: None
  - **Blocked By**: Tasks 1.1, 1.2, 1.3, 2.1, 2.2, 2.3

  **References**:
  - `powershell/tests/pester.ps1`
  - `website/package.json`

  **Acceptance Criteria**:
  - [ ] Grep for banned patterns in `powershell/public/ad/**/*.md` returns zero matches.
  - [ ] Grep for plaintext password persistence in lab scripts returns zero matches (or only matches inside `# SECURITY:` documented exceptions).
  - [ ] `pwsh -NoProfile -File ./powershell/tests/pester.ps1` passes (or any failures are documented as pre-existing).
  - [ ] Docusaurus build succeeds (if connect docs changed).
  - [ ] Evidence files exist in `.sisyphus/evidence/`.

  **QA Scenarios**:
  ```
  Scenario: Final banned pattern validation
    Tool: Bash
    Preconditions: All implementation tasks complete
    Steps:
      1. Run: grep -rE 'Get-ADDefaultDomainPasswordPolicy|Get-ADTrust|Get-GPOReport|Get-DnsServer|Get-ADForest|Get-ADDomain|Get-ADRootDSE|Get-ADReplicationSubnet|Get-ADReplicationSite|Get-ADOrganizationalUnit|Get-ADFineGrainedPasswordPolicy' powershell/public/ad/**/*.md
      2. Run: grep -n 'TestUserPassword\|SafeModePassword\|PromotionPassword\|DomainJoinUserPassword' build/activeDirectory/azure-lab/New-DomainController.ps1
      3. Run: pwsh -NoProfile -File ./powershell/tests/pester.ps1
    Expected Result: (1) No output, (2) Only SecureString/encrypted contexts, (3) Exit 0
    Failure Indicators: Any banned pattern found, plaintext passwords found, or pester failures
    Evidence: .sisyphus/evidence/plan11-task-2.4-final-validation.log
  ```

  **Evidence to Capture**:
  - [ ] `plan11-task-2.4-final-validation.log` — consolidated validation output
  - [ ] `plan11-task-2.4-validation-summary.json` — structured summary of all checks

  **Commit**: NO (validation only)

---

## Final Verification Wave (MANDATORY — after ALL implementation tasks)

> 4 review agents run in PARALLEL. ALL must APPROVE. Present consolidated results to user and get explicit "okay" before completing.

- [ ] F1. **Plan Compliance Audit** — `oracle`
  Read the plan end-to-end. For each "Must Have": verify implementation exists (read file, grep for banned patterns, run pester). For each "Must NOT Have": search codebase for forbidden patterns — reject with file:line if found. Check evidence files exist in `.sisyphus/evidence/`.
  Output: `Must Have [N/N] | Must NOT Have [N/N] | Tasks [N/N] | VERDICT: APPROVE/REJECT`

- [ ] F2. **Code Quality Review** — `unspecified-high`
  Run `pwsh -NoProfile -File ./powershell/tests/pester.ps1`. Review all changed files for: empty catches, console.log in prod, commented-out code, unused imports. Check AI slop: excessive comments, over-abstraction.
  Output: `Tests [N pass/N fail] | Files [N clean/N issues] | VERDICT`

- [ ] F3. **Real Manual QA** — `unspecified-high`
  Execute EVERY QA scenario from EVERY task — follow exact steps, capture evidence. Test cross-task integration. Save to `.sisyphus/evidence/final-qa/`.
  Output: `Scenarios [N/N pass] | Integration [N/N] | VERDICT`

- [ ] F4. **Scope Fidelity Check** — `deep`
  For each task: read "What to do", read actual diff (git log/diff). Verify 1:1 — everything in spec was built, nothing beyond spec was built. Check "Must NOT do" compliance.
  Output: `Tasks [N/N compliant] | Contamination [CLEAN/N issues] | VERDICT`

---

## Commit Strategy

- **Task 1.1**: `docs(ad): update password policy companion docs for protocol-based collection`
- **Task 1.2**: `docs(ad): update trust, domain, site, and gpo companion docs for protocol-based collection`
- **Task 1.3**: `docs(connect): add ActiveDirectory parameter matrix and examples`
- **Task 2.1**: `security(lab): encrypt lab credentials and delete temp config files`
- **Task 2.2**: `chore(hygiene): remove personal gitignore entries and fix OpenSSH regex`
- **Task 2.3**: `test(build): restore preamble and runtime body assertions in module build test`

---

## Success Criteria

### Verification Commands
```bash
# Zero deprecated refs in .md files
grep -rE 'Get-ADDefaultDomainPasswordPolicy|Get-ADTrust|Get-GPOReport|Get-DnsServer|Get-ADForest|Get-ADDomain|Get-ADRootDSE|Get-ADReplicationSubnet|Get-ADReplicationSite|Get-ADOrganizationalUnit|Get-ADFineGrainedPasswordPolicy' powershell/public/ad/**/*.md
# Expected: no output

# Zero plaintext passwords on disk
grep -n 'TestUserPassword\|SafeModePassword\|PromotionPassword\|DomainJoinUserPassword' build/activeDirectory/azure-lab/New-DomainController.ps1
# Expected: only in SecureString/encrypted contexts

# Build test assertions restored
grep -c 'Fixture module preamble\|Fixture runtime body' powershell/tests/general/Build-MaesterModule.Tests.ps1
# Expected: 2

# OpenSSH regex fixed
grep -c '(?m)^PasswordAuthentication' build/activeDirectory/azure-lab/Enable-WindowsOpenSSH.ps1
# Expected: 2

# Personal gitignore removed
grep -c 'PowerShellEditorServices.json\|\.sisyphus/' .gitignore
# Expected: 0

# Pester suite passes
pwsh -NoProfile -File ./powershell/tests/pester.ps1
# Expected: exit 0

# Docusaurus builds (if connect docs changed)
cd website && npm run build
# Expected: exit 0
```

### Final Checklist
- [ ] All "Must Have" present
- [ ] All "Must NOT Have" absent
- [ ] All tests pass
- [ ] All evidence files captured in `.sisyphus/evidence/`
