# Plan: AD Connection Logging, Certificate Detection, and Platform-Aware TLS Fallback

## TL;DR

> **Scope**: Add comprehensive verbose logging to the AD LDAP connection path, detect certificate misconfiguration errors with actionable guidance, and skip StartTLS fallback on Linux/macOS in Auto mode due to a known upstream .NET bug.
>
> **Deliverables**: Enhanced `Write-Verbose` output in `New-MtLdapConnection.ps1`, `Connect-MtAdTarget.ps1`, and `Connect-MtAdResolvedTarget`; certificate error detection with guidance messages; platform-aware TLS attempt lists; updated auth matrix; new tests; end-user troubleshooting documentation.
>
> **Estimated Effort**: Medium
> **Parallel Execution**: YES — 2 waves
> **Critical Path**: Wave 1 logging/cert/platform changes → Wave 2 tests + docs → Final verification

---

## Context

### Relationship to Plan 09
This plan is **independent** of Plan 09 (`09-ad-transport-resilience.md`). It does not supersede Plan 09.

- **Plan 09 Task 2** focuses on the **thrown error message** when both TLS modes fail (wrapping the exception with "DC does not support LDAPS or StartTLS...")
- **This plan** focuses on **verbose logging**, **certificate-specific detection**, and **platform-aware fallback** — complementary concerns that happen to touch the same file
- Both plans can execute independently. If Plan 09 executes first, this plan builds on the same file with additional capabilities. If this plan executes first, Plan 09 Task 2 still adds value by enhancing the thrown error message itself
- Plan 09's other tasks (WinRM fallback, cache scoping, SYSVOL fix, re-probe fix) are completely unrelated to this plan

**Research Findings**:
- AD connection path: `Connect-Maester` → `Connect-MtAdTarget` → `Connect-MtAdResolvedTarget` → `New-MtLdapConnection`
- `New-MtLdapConnection.ps1` (95 lines): only verbose message is failed disposal — no connection-stage logging
- `Connect-MtAdResolvedTarget` (lines 294-354): catches ANY exception, tries next TLS mode, throws only last exception — no per-attempt logging
- `Connect-MtAdTarget` outer flow (lines 356-477): sanitizes errors and rethrows — hides per-attempt failures from verbose output
- `Test-MtAdProtocolPrerequisites` returns `PlatformProfile`: `WindowsPS51`, `WindowsPS7`, `LinuxPS7`, `MacOSPS7`, `Unknown`
- `Get-MtAdSupportedAuthMatrix` lists `TlsModes = @('Ldaps', 'StartTls')` for ALL profiles including Linux/macOS
- `ActiveDirectoryProtocol.Tests.ps1` mocks `Test-MtAdProtocolPrerequisites`, `New-MtLdapConnection`, `Get-MtLdapRootDse`
- Existing TLS fallback test verifies Auto tries 636 then 389 (lines 348-431)
- DEPLOYMENT-ISSUES.md Issue 8 documents Linux StartTLS upstream bug

### Metis Review
**Identified Gaps** (addressed in plan):
- Guardrail needed: Do NOT add `-SkipCertificateCheck` to public `Connect-Maester` contract
- Guardrail needed: Do NOT change `ValidateSet` on `-ActiveDirectoryTlsMode`
- Edge case: Explicit `-TlsMode StartTls` on Linux should NOT be blocked — only `Auto` mode skips StartTLS
- Edge case: Certificate detection must handle case-insensitive matching and must not leak credentials
- Edge case: Unrecognized platform profile should fall back to current behavior

---

## Work Objectives

### Core Objective
Make AD TLS connection failures diagnosable through verbose logging, detect certificate misconfiguration with actionable guidance, and avoid false StartTLS fallback attempts on non-Windows platforms.

### Concrete Deliverables
- Modified `New-MtLdapConnection.ps1` with verbose logging at connection, StartTLS, bind, and error stages
- Modified `Connect-MtAdResolvedTarget` (in `Connect-MtAdTarget.ps1`) with per-attempt verbose logging, certificate error detection, and platform-aware TLS attempt lists
- Modified `Connect-MtAdTarget.ps1` outer flow with pre-connection and final-state verbose logging
- Modified `Get-MtAdSupportedAuthMatrix.ps1` to document the StartTLS limitation in `LinuxPS7`/`MacOSPS7` profile Notes (keeping `StartTls` in `TlsModes` to preserve explicit mode selection)
- Updated/added tests in `ActiveDirectoryProtocol.Tests.ps1`
- New website documentation page: `website/docs/connect-maester/ad-connection-troubleshooting.md`

### Definition of Done
- `pwsh -NoProfile -File ./powershell/tests/pester.ps1` passes
- All new tests pass with `Invoke-Pester`
- Verbose output contains expected messages at all specified log points
- Certificate error detection triggers guidance messages correctly
- Platform-aware fallback skips StartTLS on Linux/macOS in Auto mode only

### Must Have
- Verbose logging at all specified points in `New-MtLdapConnection`, `Connect-MtAdResolvedTarget`, and `Connect-MtAdTarget`
- Certificate error detection using case-insensitive string matching
- Actionable guidance messages when LDAPS cert fails and StartTLS fallback is attempted/succeeds/fails
- Platform-aware TLS fallback: non-Windows Auto mode skips StartTLS
- Updated auth matrix reflecting Linux/macOS StartTLS limitation
- New tests for platform fallback and certificate detection
- End-user troubleshooting documentation on website

### Must NOT Have (Guardrails)
- No new public parameters on `Connect-Maester` or `Connect-MtAdTarget`
- No changes to `-ActiveDirectoryTlsMode` `ValidateSet`
- No certificate bypass or security posture changes
- No credential leakage in verbose output
- No blocking of explicit `-TlsMode StartTls` on any platform
- No refactoring of connection logic beyond logging and conditional attempt lists

---

## Verification Strategy

> **ZERO HUMAN INTERVENTION** — ALL verification is agent-executed. No exceptions.

### Test Decision
- **Infrastructure exists**: YES
- **Automated tests**: Tests-after (mocked transport and platform fixtures)
- **Framework**: Pester (via `./powershell/tests/pester.ps1`)
- **Agent-Executed QA**: ALWAYS (mandatory for all tasks regardless of test choice)

### QA Policy
Every task MUST include agent-executed QA scenarios.
Evidence saved to `.sisyphus/evidence/ad-logging-task-{N}-{slug}.{ext}`.

- **PowerShell/Module**: Use Bash (`pwsh`) — Import module, run functions, assert output
- **Platform fixtures**: Use mocked `Test-MtAdProtocolPrerequisites` to simulate cross-platform behavior

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Foundation — logging, certificate detection, platform fallback):
├── Task 1: Verbose logging in New-MtLdapConnection.ps1 [quick]
├── Task 2: Verbose logging + certificate detection + platform fallback in Connect-MtAdResolvedTarget [unspecified-high]
├── Task 3: Verbose logging in Connect-MtAdTarget outer flow [quick]
└── Task 4: Update Get-MtAdSupportedAuthMatrix for platform-aware TLS [quick]

Wave 2 (Tests + documentation):
├── Task 5: Update ActiveDirectoryProtocol.Tests.ps1 with platform and certificate tests [unspecified-high]
└── Task 6: Add AD connection troubleshooting documentation to website [writing]

Wave FINAL (After ALL tasks — 4 parallel reviews, then user okay):
├── Task F1: Plan compliance audit (oracle)
├── Task F2: Code quality review (unspecified-high)
├── Task F3: Real manual QA (unspecified-high)
└── Task F4: Scope fidelity check (deep)
-> Present results -> Get explicit user okay

Critical Path: Task 1-4 (parallel) → Task 5 → F1-F4 → user okay
Parallel Speedup: Wave 1 tasks are all independent
Max Concurrent: 4 (Wave 1)
```

### Dependency Matrix

| Task | Blocked By | Blocks |
|------|-----------|--------|
| 1 (New-MtLdapConnection verbose) | — | 5 |
| 2 (Connect-MtAdResolvedTarget enhancements) | — | 5 |
| 3 (Connect-MtAdTarget outer verbose) | — | 5 |
| 4 (Auth matrix update) | — | 5 |
| 5 (Tests) | 1, 2, 3, 4 | F1-F4 |
| 6 (Docs) | — | F1-F4 |
| F1-F4 | 5, 6 | — |

---

## TODOs

- [ ] 1. Verbose Logging in New-MtLdapConnection.ps1

  **What to do**:
  - Add `Write-Verbose` calls at these specific points in `powershell/internal/ad/protocol/New-MtLdapConnection.ps1`:
    - **Before creating the connection** (around line 38): log server, port, AuthType, UseStartTls, SkipCertificateCheck
      ```powershell
      Write-Verbose "Creating LDAP connection to '$Server' on port $effectivePort with AuthType '$AuthType', UseStartTls: $($UseStartTls.IsPresent), SkipCertificateCheck: $($SkipCertificateCheck.IsPresent)"
      ```
    - **Before StartTLS negotiation** (around line 72): log that StartTLS is being negotiated
      ```powershell
      Write-Verbose "Negotiating StartTLS with server '$Server' on port $effectivePort"
      ```
    - **After StartTLS success** (after line 74): log completion
      ```powershell
      Write-Verbose "StartTLS negotiation completed successfully"
      ```
    - **Before Bind** (around line 77): log that bind is being attempted
      ```powershell
      Write-Verbose "Attempting LDAP bind to '$Server' on port $effectivePort with AuthType '$AuthType'"
      ```
    - **After Bind success** (after line 77, before return): log success
      ```powershell
      Write-Verbose "LDAP bind to '$Server' on port $effectivePort succeeded"
      ```
    - **In catch block** (around line 80): log the actual error message before rethrowing
      ```powershell
      Write-Verbose "LDAP connection to '$Server' on port $effectivePort failed: $($_.Exception.Message)"
      ```
  - Ensure NO credentials are logged (the exception message may contain server info but `New-MtLdapConnection` does not format credentials into its error)
  - Keep the existing catch block disposal logic intact

  **Must NOT do**:
  - Do NOT log the credential username or password
  - Do NOT change the error message format thrown to callers
  - Do NOT modify the connection creation or bind logic

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Small, focused additions of Write-Verbose to existing code
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 2, 3, 4)
  - **Blocks**: Task 5 (tests)
  - **Blocked By**: None

  **References**:

  **Pattern References**:
  - `powershell/internal/ad/protocol/New-MtLdapConnection.ps1:38-79` - Current connection creation and bind logic
  - `powershell/internal/ad/protocol/New-MtLdapConnection.ps1:80-91` - Current catch block

  **Test References**:
  - `powershell/tests/functions/ActiveDirectoryProtocol.Tests.ps1:258-345` - Factory-specific tests that mock New-Object; added Write-Verbose should not affect these

  **Acceptance Criteria**:
  - [ ] `New-MtLdapConnection` emits verbose messages for connection creation, StartTLS, bind, and errors
  - [ ] Verbose messages do NOT contain credential information
  - [ ] Existing factory-specific tests still pass

  **QA Scenarios**:

  ```
  Scenario: Verbose logging on successful LDAPS connection
    Tool: Bash (pwsh)
    Preconditions: Module imported, mocks set up for successful connection
    Steps:
      1. Mock New-Object to return a fake LdapConnection that succeeds on Bind
      2. $verboseOutput = New-MtLdapConnection -Server 'dc01.contoso.com' -Port 636 -AuthType Negotiate -Verbose 4>&1
    Expected Result: $verboseOutput contains messages about creating connection, attempting bind, and bind success
    Failure Indicators: No verbose messages emitted
    Evidence: .sisyphus/evidence/ad-logging-task-01-verbose-ldaps.txt

  Scenario: Verbose logging on StartTLS connection
    Tool: Bash (pwsh)
    Preconditions: Module imported, mocks set up for successful StartTLS
    Steps:
      1. Mock New-Object to return fake connection with StartTransportLayerSecurity script method
      2. $verboseOutput = New-MtLdapConnection -Server 'dc01.contoso.com' -Port 389 -UseStartTls -AuthType Basic -Credential $cred -Verbose 4>&1
    Expected Result: $verboseOutput contains StartTLS negotiation and completion messages
    Failure Indicators: No StartTLS verbose messages
    Evidence: .sisyphus/evidence/ad-logging-task-01-verbose-starttls.txt
  ```

  **Evidence to Capture**:
  - [ ] `task-01-verbose-ldaps.txt` - Verbose output from LDAPS connection test
  - [ ] `task-01-verbose-starttls.txt` - Verbose output from StartTLS connection test

  **Commit**: YES (grouped with Tasks 2-4)
  - Message: `fix(ad): add verbose logging, certificate detection, and platform-aware TLS fallback`
  - Files: `powershell/internal/ad/protocol/New-MtLdapConnection.ps1`

- [ ] 2. Verbose Logging, Certificate Detection, and Platform-Aware Fallback in Connect-MtAdResolvedTarget

  **What to do**:
  - Modify `Connect-MtAdResolvedTarget` in `powershell/internal/ad/Connect-MtAdTarget.ps1` (lines 294-354):

  **A. Platform-aware TLS attempt list**:
  - Before building `$tlsAttempts`, detect the platform using `$adPrerequisites.PlatformProfile` (already available in the outer scope of `Connect-MtAdTarget`)
  - On Windows (`$adPrerequisites.PlatformProfile -like 'Windows*'`): keep current behavior — try LDAPS 636 first, then StartTLS 389
  - On non-Windows: in `Auto` mode, ONLY attempt LDAPS 636 (skip StartTLS 389)
  - For explicit `Ldaps` or `StartTls` modes: respect the user's choice regardless of platform
  - Log the platform detection and resulting strategy:
    ```powershell
    if ($adPrerequisites.PlatformProfile -like 'Windows*') {
        Write-Verbose 'Windows runtime detected. TLS fallback order: LDAPS (636), StartTLS (389).'
    } else {
        Write-Verbose 'Non-Windows runtime detected. Skipping StartTLS in Auto mode due to known upstream .NET bug. Only LDAPS (636) will be attempted.'
    }
    ```
  - **Important**: The Auto-mode skip is driven by `PlatformProfile`, NOT by `Get-MtAdSupportedAuthMatrix.TlsModes`. Explicit `-TlsMode StartTls` must still be permitted on all platforms.

  **B. Per-attempt verbose logging**:
  - Before each TLS attempt: log the attempt name, port, and auth mode
    ```powershell
    Write-Verbose "Attempting TLS mode '$($tlsAttempt.Name)' to '$Server' on port $($tlsAttempt.Port) with AuthType '$AuthenticationMode'"
    ```
  - On success: log the resolved server, domain, forest, and which TLS mode succeeded
    ```powershell
    Write-Verbose "TLS mode '$($tlsAttempt.Name)' succeeded. Resolved server: $($targetMetadata.ResolvedServer), domain: $($targetMetadata.ResolvedDomain), forest: $($targetMetadata.ResolvedForest)"
    ```
  - On failure of each attempt: log the specific error for that attempt
    ```powershell
    Write-Verbose "TLS mode '$($tlsAttempt.Name)' failed: $($_.Exception.Message)"
    ```

  **C. Certificate error detection and guidance**:
  - In the catch block (currently line 347-350), after capturing `$lastException`, check if the exception message indicates a certificate-related error:
    ```powershell
    $isCertificateError = $_.Exception.Message -match '(?i)(certificate|trust|validation|expired|chain)'
    ```
  - If a certificate error is detected on port 636 (LDAPS) and there are more attempts remaining (StartTLS fallback is about to be tried), log:
    ```powershell
    Write-Verbose 'LDAPS connection failed due to certificate validation. Attempting StartTLS fallback on port 389...'
    ```
  - If StartTLS also fails with a certificate error, log:
    ```powershell
    Write-Verbose 'Both LDAPS and StartTLS failed due to certificate issues. Consider: (1) installing a valid server-auth certificate on the DC, (2) trusting the DC certificate, or (3) using -SkipCertificateCheck for test environments only.'
    ```
  - If StartTLS succeeds after LDAPS certificate failure, log:
    ```powershell
    Write-Verbose 'StartTLS fallback succeeded. Connected using TLS on port 389. Note: The DC LDAPS certificate (port 636) is misconfigured.'
    ```

  **D. Summary when all attempts fail**:
  - Before `throw $lastException`, log a summary:
    ```powershell
    Write-Verbose "All TLS attempts failed. Attempted: $($tlsAttempts.Name -join ', ')"
    ```

  **Must NOT do**:
  - Do NOT block explicit `-TlsMode StartTls` on non-Windows — only `Auto` mode should skip StartTLS
  - Do NOT leak credentials in verbose output
  - Do NOT change the thrown exception type or structure (only enhance verbose messages)

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: Requires careful modification of the TLS attempt loop with multiple conditional behaviors
  - **Skills**: [`maester-test-expert`]
    - `maester-test-expert`: Needed for AD connection test conventions and mock patterns

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 3, 4)
  - **Blocks**: Task 5 (tests)
  - **Blocked By**: None

  **References**:

  **Pattern References**:
  - `powershell/internal/ad/Connect-MtAdTarget.ps1:294-354` - Current Connect-MtAdResolvedTarget implementation
  - `powershell/internal/ad/Connect-MtAdTarget.ps1:375-405` - Platform validation and prerequisite checks
  - `powershell/internal/ad/Connect-MtAdTarget.ps1:310-319` - Current TLS attempt list construction

  **Test References**:
  - `powershell/tests/functions/ActiveDirectoryProtocol.Tests.ps1:348-431` - Existing TLS fallback order test
  - `powershell/tests/functions/ActiveDirectoryProtocol.Tests.ps1:507-536` - Non-Windows implicit targeting test

  **Acceptance Criteria**:
  - [ ] Windows Auto mode tries LDAPS 636 then StartTLS 389
  - [ ] Non-Windows Auto mode tries ONLY LDAPS 636
  - [ ] Explicit `StartTls` mode on non-Windows still attempts StartTLS
  - [ ] Certificate errors on 636 trigger guidance message before StartTLS fallback
  - [ ] All attempts failure logs summary of attempted modes
  - [ ] Existing TLS fallback test still passes on Windows profile

  **QA Scenarios**:

  ```
  Scenario: Windows Auto mode tries both LDAPS and StartTLS
    Tool: Bash (pwsh)
    Preconditions: Module imported, mocked Windows platform profile
    Steps:
      1. Mock Test-MtAdProtocolPrerequisites to return PlatformProfile 'WindowsPS7'
      2. Mock New-MtLdapConnection to fail on port 636, succeed on 389
      3. Connect-MtAdTarget -ActiveDirectoryDomain 'misoule02.local' -TlsMode Auto -Verbose 4>&1
    Expected Result: Verbose shows LDAPS attempt, then StartTLS fallback, then success; TlsMode resolves to 'StartTls'
    Failure Indicators: Only one connection attempt; no StartTLS fallback
    Evidence: .sisyphus/evidence/ad-logging-task-02-windows-auto.txt

  Scenario: Linux Auto mode skips StartTLS
    Tool: Bash (pwsh)
    Preconditions: Module imported, mocked Linux platform profile
    Steps:
      1. Mock Test-MtAdProtocolPrerequisites to return PlatformProfile 'LinuxPS7'
      2. Mock New-MtLdapConnection to throw on port 636
      3. { Connect-MtAdTarget -ActiveDirectoryServer 'dc01.contoso.com' -ActiveDirectoryCredential $cred -TlsMode Auto } | Should -Throw
    Expected Result: Only ONE New-MtLdapConnection call with Port 636; no call with Port 389
    Failure Indicators: Two connection attempts (StartTLS was not skipped)
    Evidence: .sisyphus/evidence/ad-logging-task-02-linux-auto-skip.txt

  Scenario: Certificate error triggers guidance on fallback
    Tool: Bash (pwsh)
    Preconditions: Module imported, mocked Windows platform
    Steps:
      1. Mock Test-MtAdProtocolPrerequisites to return PlatformProfile 'WindowsPS7'
      2. Mock New-MtLdapConnection to throw 'The remote certificate is invalid' on port 636, succeed on 389
      3. $verbose = Connect-MtAdTarget -ActiveDirectoryDomain 'misoule02.local' -TlsMode Auto -Verbose 4>&1
    Expected Result: Verbose contains 'LDAPS connection failed due to certificate validation. Attempting StartTLS fallback...' AND 'StartTLS fallback succeeded...'
    Failure Indicators: No certificate guidance message
    Evidence: .sisyphus/evidence/ad-logging-task-02-cert-guidance.txt
  ```

  **Evidence to Capture**:
  - [ ] `task-02-windows-auto.txt` - Verbose output showing Windows fallback
  - [ ] `task-02-linux-auto-skip.txt` - Test output showing Linux skips StartTLS
  - [ ] `task-02-cert-guidance.txt` - Verbose output showing certificate guidance

  **Commit**: YES (grouped with Tasks 1, 3, 4)
  - Message: `fix(ad): add verbose logging, certificate detection, and platform-aware TLS fallback`
  - Files: `powershell/internal/ad/Connect-MtAdTarget.ps1`

- [ ] 3. Verbose Logging in Connect-MtAdTarget Outer Flow

  **What to do**:
  - Modify `powershell/internal/ad/Connect-MtAdTarget.ps1` outer flow (around lines 356-477):
    - **Before attempting connection** (after target server is resolved, around line 424): log the resolved target server
      ```powershell
      Write-Verbose "Resolved target server: '$targetServer'. Attempting AD connection with AuthMode '$authenticationMode' and TlsMode '$TlsMode'."
      ```
    - **On successful connection** (after session state is set, around line 461): the existing verbose message is sufficient but can be enhanced
      ```powershell
      Write-Verbose "Connected to AD: $($resolvedConnection.Metadata.ResolvedServer) using TLS mode $($resolvedConnection.Metadata.TlsMode)"
      ```
    - **On failure** (in the catch block, around line 464): log the final connection state
      ```powershell
      Write-Verbose "Active Directory connection failed: $sanitizedError"
      ```

  **Must NOT do**:
  - Do NOT change the error sanitization logic
  - Do NOT change the session state management

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Small additions to existing verbose logging
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 2, 4)
  - **Blocks**: Task 5 (tests)
  - **Blocked By**: None

  **References**:

  **Pattern References**:
  - `powershell/internal/ad/Connect-MtAdTarget.ps1:356` - Existing "Validating Active Directory connectivity" verbose
  - `powershell/internal/ad/Connect-MtAdTarget.ps1:462` - Existing success verbose
  - `powershell/internal/ad/Connect-MtAdTarget.ps1:464-471` - Catch block with sanitization

  **Acceptance Criteria**:
  - [ ] Verbose output shows resolved target server before connection attempt
  - [ ] Verbose output shows failure reason on catch

  **QA Scenarios**:

  ```
  Scenario: Outer flow verbose on success
    Tool: Bash (pwsh)
    Preconditions: Module imported, mocked prerequisites and connection
    Steps:
      1. Mock Test-MtAdProtocolPrerequisites to return WindowsPS7
      2. Mock New-MtLdapConnection to succeed
      3. $verbose = Connect-MtAdTarget -ActiveDirectoryDomain 'misoule02.local' -Verbose 4>&1
    Expected Result: $verbose contains 'Resolved target server:' and 'Connected to AD:'
    Failure Indicators: Missing verbose messages
    Evidence: .sisyphus/evidence/ad-logging-task-03-outer-success.txt

  Scenario: Outer flow verbose on failure
    Tool: Bash (pwsh)
    Preconditions: Module imported, mocked prerequisites
    Steps:
      1. Mock Test-MtAdProtocolPrerequisites to return WindowsPS7
      2. Mock New-MtLdapConnection to throw 'Connection refused'
      3. $verbose = Connect-MtAdTarget -ActiveDirectoryDomain 'misoule02.local' -Verbose 4>&1 -ErrorAction SilentlyContinue
    Expected Result: $verbose contains 'Resolved target server:' and 'Active Directory connection failed:'
    Failure Indicators: Missing failure verbose message
    Evidence: .sisyphus/evidence/ad-logging-task-03-outer-failure.txt
  ```

  **Evidence to Capture**:
  - [ ] `task-03-outer-success.txt` - Verbose output on successful connection
  - [ ] `task-03-outer-failure.txt` - Verbose output on failed connection

  **Commit**: YES (grouped with Tasks 1, 2, 4)
  - Message: `fix(ad): add verbose logging, certificate detection, and platform-aware TLS fallback`
  - Files: `powershell/internal/ad/Connect-MtAdTarget.ps1`

- [ ] 4. Update Get-MtAdSupportedAuthMatrix for Platform-Aware TLS Reporting

  **What to do**:
  - Modify `powershell/internal/ad/Get-MtAdSupportedAuthMatrix.ps1`:
    - In the `LinuxPS7` profile (lines 35-48), keep `TlsModes = @('Ldaps', 'StartTls')` — do NOT remove `StartTls` from the matrix, because `Connect-MtAdTarget.ps1:403` validates explicit mode selections against this list and removing it would block users from explicitly requesting StartTLS
    - In the `MacOSPS7` profile (lines 50-63), keep `TlsModes = @('Ldaps', 'StartTls')` for the same reason
    - Add a prominent note to both profiles explaining the limitation:
      ```powershell
      Notes = @(
          'WARNING: StartTLS is known to fail on this platform due to an upstream .NET bug (dotnet/runtime#96988, dotnet/runtime#110391). Auto mode will use LDAPS only. Explicit StartTLS may still be attempted if requested.',
          ...
      )
      ```
  - This documents the limitation in the capability matrix without breaking explicit mode selection
  - The Auto-mode skip is implemented in `Connect-MtAdResolvedTarget` (Task 2) based on `PlatformProfile`, not on the matrix

  **Must NOT do**:
  - Do NOT change Windows profiles
  - Do NOT change `TlsModes` values (removing `StartTls` would break explicit mode selection at `Connect-MtAdTarget.ps1:403`)
  - Do NOT change SupportedAuthModes or other properties

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Simple data structure update with documentation
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 2, 3)
  - **Blocks**: Task 5 (tests)
  - **Blocked By**: None

  **References**:

  **Pattern References**:
  - `powershell/internal/ad/Get-MtAdSupportedAuthMatrix.ps1:35-48` - LinuxPS7 profile
  - `powershell/internal/ad/Get-MtAdSupportedAuthMatrix.ps1:50-63` - MacOSPS7 profile
  - `powershell/internal/ad/Connect-MtAdTarget.ps1:403` - TlsMode validation against prerequisite TlsModes

  **Test References**:
  - `powershell/tests/functions/ActiveDirectoryProtocol.Tests.ps1:36-44` - Mock Test-MtAdProtocolPrerequisites returning TlsModes

  **Acceptance Criteria**:
  - [ ] LinuxPS7 profile Notes contains warning about StartTLS upstream bug
  - [ ] MacOSPS7 profile Notes contains warning about StartTLS upstream bug
  - [ ] LinuxPS7 profile TlsModes still contains both 'Ldaps' and 'StartTls'
  - [ ] MacOSPS7 profile TlsModes still contains both 'Ldaps' and 'StartTls'

  **QA Scenarios**:

  ```
  Scenario: Auth matrix documents Linux limitation without breaking explicit StartTls
    Tool: Bash (pwsh)
    Preconditions: Module imported
    Steps:
      1. $matrix = Get-MtAdSupportedAuthMatrix
      2. $linux = $matrix.Profiles.LinuxPS7
    Expected Result: $linux.TlsModes contains 'Ldaps' and 'StartTls'; $linux.Notes contains 'StartTLS is known to fail'
    Failure Indicators: TlsModes missing 'StartTls' (would break explicit mode); Notes missing warning
    Evidence: .sisyphus/evidence/ad-logging-task-04-linux-matrix.txt

  Scenario: Auth matrix documents macOS limitation without breaking explicit StartTls
    Tool: Bash (pwsh)
    Preconditions: Module imported
    Steps:
      1. $matrix = Get-MtAdSupportedAuthMatrix
      2. $macos = $matrix.Profiles.MacOSPS7
    Expected Result: $macos.TlsModes contains 'Ldaps' and 'StartTls'; $macos.Notes contains 'StartTLS is known to fail'
    Failure Indicators: TlsModes missing 'StartTls'; Notes missing warning
    Evidence: .sisyphus/evidence/ad-logging-task-04-macos-matrix.txt
  ```

  **Evidence to Capture**:
  - [ ] `task-04-linux-matrix.txt` - LinuxPS7 TlsModes verification
  - [ ] `task-04-macos-matrix.txt` - MacOSPS7 TlsModes verification

  **Commit**: YES (grouped with Tasks 1-3)
  - Message: `fix(ad): add verbose logging, certificate detection, and platform-aware TLS fallback`
  - Files: `powershell/internal/ad/Get-MtAdSupportedAuthMatrix.ps1`

- [ ] 5. Update ActiveDirectoryProtocol.Tests.ps1 with Platform and Certificate Tests

  **What to do**:
  - Update `powershell/tests/functions/ActiveDirectoryProtocol.Tests.ps1`:

  **A. Update existing mocks**:
  - The existing `Test-MtAdProtocolPrerequisites` mocks return `TlsModes = @('Ldaps', 'StartTls')` for all profiles. Since Task 4 keeps `StartTls` in the matrix for all profiles, **no mock updates are needed for TlsModes**.
  - Verify that mocks for non-Windows platforms (e.g., `Non-Windows implicit targeting` at line 507) still work correctly with the updated code.

  **B. Add platform-aware fallback test**:
  - Add a new Describe block: `'Platform-aware TLS fallback on non-Windows'`
  - Mock `Test-MtAdProtocolPrerequisites` with `PlatformProfile = 'LinuxPS7'` and `TlsModes = @('Ldaps')`
  - Mock `New-MtLdapConnection` to throw on port 636
  - Call `Connect-MtAdTarget -ActiveDirectoryServer 'dc01.contoso.com' -ActiveDirectoryCredential $cred -TlsMode Auto`
  - Assert that `New-MtLdapConnection` is called exactly ONCE with Port 636
  - Assert that the error is thrown (since no fallback is attempted)

  **C. Add explicit StartTls on non-Windows test**:
  - Add a new It block verifying that explicit `-TlsMode StartTls` on Linux still attempts StartTLS
  - Mock `Test-MtAdProtocolPrerequisites` with `PlatformProfile = 'LinuxPS7'`
  - Mock `New-MtLdapConnection` to succeed on port 389 with `UseStartTls = $true`
  - Call `Connect-MtAdTarget -ActiveDirectoryServer 'dc01.contoso.com' -ActiveDirectoryCredential $cred -TlsMode StartTls`
  - Assert success and `TlsMode = 'StartTls'`

  **D. Add certificate detection test**:
  - Add a new Describe block: `'Certificate error detection and guidance'`
  - Mock `Test-MtAdProtocolPrerequisites` with `PlatformProfile = 'WindowsPS7'`
  - Mock `New-MtLdapConnection` to throw 'The remote certificate is invalid according to the validation procedure.' on port 636, then succeed on port 389
  - Capture verbose output with `4>&1`
  - Assert verbose contains 'LDAPS connection failed due to certificate validation. Attempting StartTLS fallback...'
  - Assert verbose contains 'StartTLS fallback succeeded. Connected using TLS on port 389.'
  - Assert connection succeeds with `TlsMode = 'StartTls'`

  **E. Add both-TLS-fail certificate test**:
  - Mock `New-MtLdapConnection` to throw certificate errors on BOTH port 636 and 389
  - Assert verbose contains 'Both LDAPS and StartTLS failed due to certificate issues.'
  - Assert the thrown error contains guidance text

  **F. Update existing TLS fallback test**:
  - The existing `'TLS fallback order'` test (lines 348-431) uses `PlatformProfile = 'WindowsPS7'` and mocks `TlsModes = @('Ldaps', 'StartTls')`. This should still pass, but verify the mock is consistent.

  **Must NOT do**:
  - Do NOT add tests requiring a real AD domain controller
  - Do NOT remove existing tests
  - Do NOT use real credentials

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: Requires careful test design with mocked AD transport and cross-platform fixtures
  - **Skills**: [`maester-test-expert`]
    - `maester-test-expert`: Essential for AD test patterns and mock conventions

  **Parallelization**:
  - **Can Run In Parallel**: NO (depends on Tasks 1-4)
  - **Parallel Group**: Wave 2 (with Task 6)
  - **Blocks**: F1-F4 (Final Verification)
  - **Blocked By**: Tasks 1, 2, 3, 4

  **References**:

  **Pattern References**:
  - `powershell/tests/functions/ActiveDirectoryProtocol.Tests.ps1:348-431` - Existing TLS fallback test
  - `powershell/tests/functions/ActiveDirectoryProtocol.Tests.ps1:507-536` - Non-Windows implicit targeting test
  - `powershell/tests/functions/ActiveDirectoryProtocol.Tests.ps1:28-95` - Root-forest implicit credentials test with mock patterns

  **Acceptance Criteria**:
  - [ ] All new tests pass
  - [ ] All existing tests still pass
  - [ ] Linux Auto mode test verifies only one connection attempt
  - [ ] Certificate detection test verifies guidance messages in verbose output
  - [ ] Explicit StartTls on Linux test verifies user can still force StartTLS

  **QA Scenarios**:

  ```
  Scenario: Full test suite passes
    Tool: Bash (pwsh)
    Preconditions: Module imported, all test dependencies available
    Steps:
      1. cd /home/azureuser/projects/maester/powershell/tests/functions
      2. Invoke-Pester -Path ./ActiveDirectoryProtocol.Tests.ps1
    Expected Result: All tests pass (0 failures)
    Failure Indicators: Any test failure
    Evidence: .sisyphus/evidence/ad-logging-task-05-full-test-run.txt
  ```

  **Evidence to Capture**:
  - [ ] `task-05-full-test-run.txt` - Full Pester output for ActiveDirectoryProtocol tests

  **Commit**: YES
  - Message: `test(ad): add platform fallback and certificate detection tests`
  - Files: `powershell/tests/functions/ActiveDirectoryProtocol.Tests.ps1`

- [ ] 6. Add AD Connection Troubleshooting Documentation

  **What to do**:
  - Create `website/docs/connect-maester/ad-connection-troubleshooting.md` with the following sections:

  **A. Overview**
  - Brief explanation that Maester uses `System.DirectoryServices.Protocols.LdapConnection` for cross-platform AD connectivity
  - Mention that TLS is required for all AD connections

  **B. Understanding TLS Modes**
  - Document the three `-ActiveDirectoryTlsMode` values:
    - `Auto` (default): Tries LDAPS (port 636) first, then StartTLS (port 389) on Windows. On Linux/macOS, only tries LDAPS.
    - `Ldaps`: Uses LDAPS on port 636 only.
    - `StartTls`: Uses StartTLS on port 389 only.
  - Explain that `Auto` mode adapts to the platform due to a known .NET limitation

  **C. Certificate Issues on the Domain Controller**
  - Common symptoms: connection fails with certificate, trust, validation, expired, or chain errors
  - Troubleshooting steps:
    1. Verify the DC has a valid server-authentication certificate installed
    2. Verify the certificate SAN includes the DC's FQDN
    3. Verify the certificate is not expired
    4. On the client, verify the DC's certificate chain is trusted
    5. For test environments only: `-SkipCertificateCheck` can be used with `New-MtLdapConnection` directly (not available on `Connect-Maester`)
  - If LDAPS fails but StartTLS succeeds, the DC's LDAPS certificate (port 636) is misconfigured — check the certificate on the DC

  **D. Linux and macOS StartTLS Limitation**
  - Document the known upstream .NET bug (dotnet/runtime#96988, dotnet/runtime#110391)
  - Explain that `StartTransportLayerSecurity()` fails on Linux/macOS regardless of certificate configuration
  - Recommendation: Use `Ldaps` mode or `Auto` mode on Linux/macOS (Auto will use LDAPS only)
  - Note: `ldapsearch -ZZ` may work on the same host — this is because the bug is in .NET's managed-to-native interop, not in OpenLDAP

  **E. Using Verbose Output for Diagnostics**
  - Explain how to use `-Verbose` with `Connect-Maester` or `Connect-MtAdTarget`
  - List what information is logged at each stage:
    - Resolved target server
    - TLS mode being attempted
    - StartTLS negotiation status
    - Bind success/failure
    - Certificate-specific guidance messages

  **F. Forcing a Specific TLS Mode**
  - Document that users can bypass Auto mode behavior by explicitly setting `-ActiveDirectoryTlsMode`:
    ```powershell
    Connect-Maester -Service ActiveDirectory -ActiveDirectoryTlsMode Ldaps
    Connect-Maester -Service ActiveDirectory -ActiveDirectoryTlsMode StartTls
    ```

  **Must NOT do**:
  - Do NOT document `-SkipCertificateCheck` as available on `Connect-Maester`
  - Do NOT suggest disabling certificate validation in production
  - Do NOT duplicate existing `Connect-Maester` parameter documentation

  **Recommended Agent Profile**:
  - **Category**: `writing`
    - Reason: Documentation creation
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES (can run alongside Task 5)
  - **Parallel Group**: Wave 2 (with Task 5)
  - **Blocks**: F1-F4 (Final Verification)
  - **Blocked By**: None (docs can be drafted independently, but should reflect final behavior)

  **References**:

  **Pattern References**:
  - `website/docs/connect-maester/connect-maester-advanced.md` - Existing advanced connection docs
  - `website/docs/connect-maester/readme.md` - Existing connect-maester overview
  - `build/activeDirectory/azure-lab/DEPLOYMENT-ISSUES.md:289-325` - Linux StartTLS bug documentation

  **Acceptance Criteria**:
  - [ ] New markdown file created at correct path
  - [ ] File follows Docusaurus frontmatter format (`---` with sidebar_label, sidebar_position, title)
  - [ ] Content covers all sections A-F
  - [ ] No credential leakage in examples
  - [ ] Accurate technical information matching code behavior

  **QA Scenarios**:

  ```
  Scenario: Documentation builds without errors
    Tool: Bash
    Preconditions: Node.js and npm available
    Steps:
      1. cd /home/azureuser/projects/maester/website
      2. npm ci
      3. npm run build
    Expected Result: Build completes without markdown/Docusaurus errors
    Failure Indicators: Build errors referencing the new file
    Evidence: .sisyphus/evidence/ad-logging-task-06-docs-build.txt
  ```

  **Evidence to Capture**:
  - [ ] `task-06-docs-build.txt` - Docusaurus build output

  **Commit**: YES
  - Message: `docs(ad): add AD connection troubleshooting guide`
  - Files: `website/docs/connect-maester/ad-connection-troubleshooting.md`

---

## Final Verification Wave

> 4 review agents run in PARALLEL. ALL must APPROVE. Present consolidated results to user and get explicit "okay" before completing.

- [ ] F1. **Plan Compliance Audit** — `oracle`
  Read the plan end-to-end. For each "Must Have": verify implementation exists (read file, run command). For each "Must NOT Have": search codebase for forbidden patterns — reject with file:line if found. Check evidence files exist in `.sisyphus/evidence/`. Compare deliverables against plan.
  Output: `Must Have [N/N] | Must NOT Have [N/N] | Tasks [N/N] | VERDICT: APPROVE/REJECT`

- [ ] F2. **Code Quality Review** — `unspecified-high`
  Run `./powershell/tests/pester.ps1`. Review all changed files for: empty catches, `Write-Verbose` without context, unused imports, commented-out code. Check AI slop: excessive comments, over-abstraction, generic names.
  Output: `Build [PASS/FAIL] | Lint [PASS/FAIL] | Tests [N pass/N fail] | Files [N clean/N issues] | VERDICT`

- [ ] F3. **Real Manual QA** — `unspecified-high`
  Start from clean state. Execute EVERY QA scenario from EVERY task — follow exact steps, capture evidence. Test cross-task integration. Save to `.sisyphus/evidence/final-qa/`.
  Output: `Scenarios [N/N pass] | Integration [N/N] | VERDICT`

- [ ] F4. **Scope Fidelity Check** — `deep`
  For each task: read "What to do", read actual diff (git log/diff). Verify 1:1 — everything in spec was built, nothing beyond spec was built. Check "Must NOT do" compliance. Flag unaccounted changes.
  Output: `Tasks [N/N compliant] | Contamination [CLEAN/N issues] | Unaccounted [CLEAN/N files] | VERDICT`

---

## Commit Strategy

- **Task 1-4**: `fix(ad): add verbose logging, certificate detection, and platform-aware TLS fallback`
- **Task 5**: `test(ad): add platform fallback and certificate detection tests`
- **Task 6**: `docs(ad): add AD connection troubleshooting guide`

---

## Success Criteria

### Verification Commands
```bash
# Run unit tests
pwsh -NoProfile -File ./powershell/tests/pester.ps1

# Expected: All tests pass, including ActiveDirectoryProtocol tests
```

### Final Checklist
- [ ] Verbose output shows connection parameters before bind
- [ ] Verbose output shows per-attempt TLS mode and result
- [ ] Certificate errors trigger specific guidance messages
- [ ] Non-Windows Auto mode skips StartTLS fallback
- [ ] Explicit `-TlsMode StartTls` still works on all platforms
- [ ] `pwsh -NoProfile -File ./powershell/tests/pester.ps1` passes
