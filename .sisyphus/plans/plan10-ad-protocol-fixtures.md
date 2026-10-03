# Plan 10: AD Protocol Fixture-Based Unit Tests

## TL;DR

> **Quick Summary**: Add fixture-based Pester tests for Maester's Active Directory protocol layer (LDAP value converters, security descriptor parsing, paging, SMB client output parsing) to catch platform-specific and edge-case bugs before production. Includes authorized source changes to normalize `objectSid` return types and make security descriptors testable cross-platform.
>
> **Deliverables**:
> - `ConvertFrom-MtLdapValue` fixture tests (GeneralizedTime, FILETIME, interval→TimeSpan, UAC bits, SID, GUID, `[long]::MinValue` → "never", null/empty)
> - `ConvertFrom-MtLdapSecurityDescriptor` fixture tests (valid descriptor → ACE list, local SID resolution, foreign SID fallback, non-Windows sentinel, malformed descriptor)
> - `Invoke-MtLdapSearch` paging mock tests (single page, multi-page with cookie, empty result, server error)
> - `Get-MtLdapRangedValue` mock tests (single range, multiple ranges, duplicates, invalid DNs)
> - `Get-MtSysvolContent` smbclient output parsing fixture tests (normal listing, permission-denied, empty share, path-not-found)
> - Cross-platform CI execution in existing `build-validation.yaml` matrix
>
> **Estimated Effort**: Medium
> **Parallel Execution**: YES — 3 waves + source-fix prerequisite wave
> **Critical Path**: Source fixes (Wave 0) → Converter fixtures (Wave 1) → Paging/SMB fixtures (Wave 2) → CI verification (Wave 3)

---

## Context

### Original Request
GitHub issue #2282 identified test coverage gaps in the AD protocol layer. Existing tests mock away the parts most likely to break: LDAP paging, value converters, security descriptor parsing, and SMB client output parsing. This plan adds fixture-based tests that exercise real converter logic with deterministic inputs.

### Interview Summary
**Key Decisions**:
- **Source changes authorized**: Minimal refactors to `ConvertFrom-MtLdapValue.ps1` (normalize `objectSid` return type) and `ConvertFrom-MtLdapSecurityDescriptor.ps1` (injectable parsed descriptor) to enable cross-platform fixture tests.
- **Bug characterization vs fix**: `objectSid` type divergence treated as bug to fix — normalize to uniform return shape across platforms.
- **Test location**: New tests placed in `powershell/tests/functions/` (already in CI) rather than `powershell/tests/ad/transport/` (dead code risk).

**Research Findings**:
- All 4 source files exist with confirmed line counts and line ranges.
- `pester.ps1` runner uses Pester 5.7.1 with inline config; tests in `functions/` are automatically discovered.
- `build-validation.yaml` runs cross-platform matrix: ubuntu-latest, windows-latest, macos-latest, plus Windows PowerShell 5.1 (4 legs total).
- `MtSendRequestOverride` seam at `Invoke-MtLdapSearch.ps1:193-195` enables paging mocks without network.
- `SearchResultEntry` has zero public constructors — fake entries must be `[pscustomobject]@{ DistinguishedName=...; Attributes=@{...} }`.
- `[long]::MinValue` handling exists in TWO places (lines 67-69 and 225-232).
  - smbclient parsing is in `powershell/internal/ad/transport/Get-MtSysvolContent.ps1:616-631` (`Invoke-MtSysvolUnixAdapter`, `List` branch).

### Metis Review
**Identified Gaps** (addressed in plan):
- Security descriptor function is uncallable on non-Windows due to `RawSecurityDescriptor` ctor — resolved by authorized source change.
- `objectSid` returns `SecurityIdentifier` on Windows, `PSCustomObject` on Linux — resolved by authorized bug fix.
- Pre-existing dead AD tests in `ad/transport/` — avoided by placing new tests in `functions/`.
- 4 CI legs, not 3 — plan includes Windows PowerShell 5.1.
- pester.ps1 dual-branch path lists — plan notes both must be updated if runner touched.
- PSScriptAnalyzer scans new files — plan requires `SuppressMessageAttribute` headers.

---

## Work Objectives

### Core Objective
Create a safety net of fixture-based tests that catch converter, parser, and platform-compatibility regressions without requiring a live AD domain, plus minimal source changes to make the code testable cross-platform.

### Concrete Deliverables
- `powershell/tests/functions/ConvertFrom-MtLdapValue.Tests.ps1`
- `powershell/tests/functions/ConvertFrom-MtLdapSecurityDescriptor.Tests.ps1`
- `powershell/tests/functions/Invoke-MtLdapSearch.Paging.Tests.ps1`
- `powershell/tests/functions/Get-MtLdapRangedValue.Tests.ps1`
- `powershell/tests/functions/Get-MtSysvolContent.SmbClient.Tests.ps1`
- Source changes to `ConvertFrom-MtLdapValue.ps1` (objectSid normalization)
- Source changes to `ConvertFrom-MtLdapSecurityDescriptor.ps1` (injectable descriptor)

### Definition of Done
- All new test files pass on Windows PS7, Windows PS5.1, and Ubuntu PS7.
- `pwsh -NoProfile -File ./powershell/tests/pester.ps1` passes with new tests included.
- No analyzer regressions on new files.
- Module build and validation still pass.

### Must Have
- Fixture tests covering all 5 gap areas from issue #2282.
- Cross-platform execution on all 4 CI legs.
- Agent-executable QA scenarios for every task.

### Must NOT Have (Guardrails)
- No live AD domain required for test execution.
- No changes to public check contracts or thresholds.
- No generated-doc hand edits (AGENTS.md hard rule).
- No new CI workflows or matrix legs — reuse existing `build-validation.yaml`.
- No coverage thresholds or gates.
- No new helper modules or fixture DSLs — at most one `*.Fixtures.ps1` dot-sourced file.
- No fixing bugs discovered beyond the two authorized source changes (document in PR description instead).
- No touching `powershell/tests/functions/ActiveDirectoryProtocol.Tests.ps1` or `ActiveDirectoryOptIn.Tests.ps1`.
- No integration tests requiring `smbclient` to be installed on runners.

---

## Verification Strategy

> **ZERO HUMAN INTERVENTION** — ALL verification is agent-executed. No exceptions.

### Test Decision
- **Infrastructure exists**: YES (Pester 5.7.1, pester.ps1 runner)
- **Automated tests**: YES (Tests-after for source changes, fixtures for new tests)
- **Framework**: Pester 5.7.1
- **Agent-Executed QA**: ALWAYS — every task includes concrete QA scenarios with exact commands, fixture data, and assertions.

### QA Policy
Every task MUST include agent-executed QA scenarios. Evidence saved to `.sisyphus/evidence/plan10-task-{N}-{slug}.{ext}`.

- **PowerShell tests**: Use `pwsh -NoProfile -Command "..."` or `pwsh -NoProfile -File ./powershell/tests/pester.ps1`
- **Module build**: Use `pwsh -File ./build/Build-MaesterModule.ps1`
- **Analyzer check**: Use `Invoke-ScriptAnalyzer -Path ... -Recurse`

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 0 (Source fixes — prerequisite, must complete first):
├── Task 1: Normalize objectSid return type in ConvertFrom-MtLdapValue [quick]
└── Task 2: Make ConvertFrom-MtLdapSecurityDescriptor testable cross-platform [quick]

Wave 1 (After Wave 0 — converter fixtures + mock framework, MAX PARALLEL):
├── Task 3: ConvertFrom-MtLdapValue fixture tests [unspecified-high]
├── Task 4: ConvertFrom-MtLdapSecurityDescriptor fixture tests [unspecified-high]
└── Task 5: Shared fixture helpers dot-source file [quick]

Wave 2 (After Wave 1 — paging/SMB fixtures):
├── Task 6: Invoke-MtLdapSearch paging mock tests [unspecified-high]
├── Task 7: Get-MtLdapRangedValue mock tests [unspecified-high]
└── Task 8: Get-MtSysvolContent smbclient output parsing tests [unspecified-high]

Wave 3 (After Wave 2 — CI verification + final checks):
├── Task 9: Cross-platform CI execution verification [quick]
├── Task 10: PSScriptAnalyzer + meta-test validation [quick]
└── Task 11: Module build validation [quick]

Wave FINAL (After ALL tasks — 4 parallel reviews, then user okay):
├── Task F1: Plan compliance audit (oracle)
├── Task F2: Code quality review (unspecified-high)
├── Task F3: Real manual QA (unspecified-high)
└── Task F4: Scope fidelity check (deep)
-> Present results -> Get explicit user okay

Critical Path: Task 1 → Task 2 → Task 3-5 → Task 6-8 → Task 9-11 → F1-F4 → user okay
Parallel Speedup: ~60% faster than sequential
Max Concurrent: 3 (Wave 1 & 2)
```

### Dependency Matrix

| Task | Blocked By | Blocks |
|------|-----------|--------|
| 1 (objectSid fix) | — | 3, 4 |
| 2 (descriptor injectability) | — | 4 |
| 3 (LdapValue fixtures) | 1 | — |
| 4 (SecurityDescriptor fixtures) | 1, 2 | — |
| 5 (shared helpers) | — | 3, 4, 6, 7, 8 |
| 6 (paging mocks) | — | — |
| 7 (ranged value mocks) | — | — |
| 8 (smbclient parser) | — | — |
| 9 (CI verification) | 3-8 | — |
| 10 (analyzer + meta) | 3-8 | — |
| 11 (module build) | 3-8 | — |

---

## TODOs

- [ ] 1. **Normalize objectSid return type in ConvertFrom-MtLdapValue**

  **What to do**:
  - Modify `powershell/internal/ad/protocol/ConvertFrom-MtLdapValue.ps1` lines 166-176.
  - Current behavior: `SecurityIdentifier` ctor succeeds on Windows → returns `SecurityIdentifier` object; fails on Linux → catch returns `PSCustomObject` with `.Value`.
  - Fix: Always return a uniform object shape. Option A: always return `PSCustomObject` with `.Value` (minimal change, matches Linux behavior). Option B: always return `SecurityIdentifier` on all platforms (requires platform-agnostic SID string construction).
  - **Recommended**: Option A — change Windows path to also return `[pscustomobject]@{ Value = $Sid.Value }` for consistency. Update any internal consumers that rely on `-is [SecurityIdentifier]` (check via `lsp_find_references` on `ConvertFrom-MtLdapValue`).
  - Also verify the second code path at lines 225-232 handles `[long]::MinValue` consistently.

  **Must NOT do**:
  - Do not change the public API contract (still returns an object with `.Value`).
  - Do not modify any other attribute conversions.
  - Do not add new dependencies.

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Small, focused refactor with clear before/after behavior.
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES (with Task 2)
  - **Parallel Group**: Wave 0
  - **Blocks**: Task 3, Task 4
  - **Blocked By**: None

  **References**:
  - `powershell/internal/ad/protocol/ConvertFrom-MtLdapValue.ps1:166-176` — objectSid conversion block
  - `powershell/internal/ad/protocol/ConvertFrom-MtLdapValue.ps1:225-232` — second `[long]::MinValue` path
  - `powershell/tests/functions/ActiveDirectoryProtocol.Tests.ps1:27-32` — platform-gate pattern

  **Acceptance Criteria**:
  - [ ] `ConvertFrom-MtLdapValue -Value $sidBytes -AttributeName 'objectSid'` returns object with `.Value` property on both Windows and Linux.
  - [ ] Type is `PSCustomObject` on both platforms (not `SecurityIdentifier` on Windows).
  - [ ] Existing tests in `ActiveDirectoryProtocol.Tests.ps1` still pass.
  - [ ] `git diff --name-only origin/main -- powershell/internal` shows only expected file.

  **QA Scenarios**:

  ```
  Scenario: objectSid returns uniform shape on Windows
    Tool: Bash (pwsh)
    Preconditions: Windows runner
    Steps:
      1. pwsh -NoProfile -Command "Import-Module ./powershell/Maester.psd1; InModuleScope Maester { $r = ConvertFrom-MtLdapValue -Value ([byte[]]@(1,2,0,0,0,0,0,5,32,0,0,0,32,2,0,0)) -AttributeName 'objectSid'; Write-Output \"$($r.GetType().Name)|$($r.Value)\" }"
    Expected Result: Output is "PSCustomObject|S-1-5-32-544"
    Failure Indicators: "SecurityIdentifier|S-1-5-32-544" means type not normalized
    Evidence: .sisyphus/evidence/plan10-task-1-objectsid-windows.txt

  Scenario: objectSid returns uniform shape on Linux
    Tool: Bash (pwsh)
    Preconditions: Ubuntu runner
    Steps:
      1. pwsh -NoProfile -Command "Import-Module ./powershell/Maester.psd1; InModuleScope Maester { $r = ConvertFrom-MtLdapValue -Value ([byte[]]@(1,2,0,0,0,0,0,5,32,0,0,0,32,2,0,0)) -AttributeName 'objectSid'; Write-Output \"$($r.GetType().Name)|$($r.Value)\" }"
    Expected Result: Output is "PSCustomObject|S-1-5-32-544"
    Failure Indicators: No output or exception means regression
    Evidence: .sisyphus/evidence/plan10-task-1-objectsid-linux.txt
  ```

  **Evidence to Capture**:
  - [ ] task-1-objectsid-windows.txt
  - [ ] task-1-objectsid-linux.txt

  **Commit**: YES
  - Message: `fix(ad): normalize objectSid return type across platforms`
  - Files: `powershell/internal/ad/protocol/ConvertFrom-MtLdapValue.ps1`
  - Pre-commit: `pwsh -NoProfile -File ./powershell/tests/pester.ps1 -Include 'ActiveDirectoryProtocol.Tests.ps1'`

- [ ] 2. **Make ConvertFrom-MtLdapSecurityDescriptor testable cross-platform**

  **What to do**:
  - Modify `powershell/internal/ad/protocol/ConvertFrom-MtLdapSecurityDescriptor.ps1` to accept an optional pre-parsed descriptor.
  - Current behavior: Line 100 calls `[System.Security.AccessControl.RawSecurityDescriptor]::new($RawSecurityDescriptor, 0)` which throws `PlatformNotSupportedException` on Linux/macOS.
  - Fix: Add a `-ParsedDescriptor` parameter. If provided, skip the `RawSecurityDescriptor` construction and use the injected object directly. If not provided, retain current behavior (Windows-only).
  - Alternative: Wrap the ctor in a try/catch and return a sentinel object on non-Windows. Less testable but simpler.
  - **Recommended**: Add `-ParsedDescriptor` parameter for test injection. This is the minimal change that enables cross-platform fixture tests without altering the normal Windows code path.

  **Must NOT do**:
  - Do not change the default behavior on Windows.
  - Do not remove the `RawSecurityDescriptor` construction from the normal path.
  - Do not modify the ACE parsing logic.

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Parameter addition with conditional bypass.
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES (with Task 1)
  - **Parallel Group**: Wave 0
  - **Blocks**: Task 4
  - **Blocked By**: None

  **References**:
  - `powershell/internal/ad/protocol/ConvertFrom-MtLdapSecurityDescriptor.ps1:100` — RawSecurityDescriptor ctor
  - `powershell/internal/ad/protocol/ConvertFrom-MtLdapSecurityDescriptor.ps1:20` — SID.Translate() line
  - `powershell/tests/ad/transport/Get-MtSysvolContent.Tests.ps1:57-80` — Mock/InModuleScope pattern

  **Acceptance Criteria**:
  - [ ] Function accepts `-ParsedDescriptor` parameter.
  - [ ] When `-ParsedDescriptor` is provided, function skips `RawSecurityDescriptor` construction.
  - [ ] When `-ParsedDescriptor` is omitted, function behaves exactly as before on Windows.
  - [ ] Function still passes any existing tests.

  **QA Scenarios**:

  ```
  Scenario: Injected descriptor bypasses platform check
    Tool: Bash (pwsh)
    Preconditions: Any platform
    Steps:
      1. pwsh -NoProfile -Command "Import-Module ./powershell/Maester.psd1; $mockSd = [pscustomobject]@{ Owner = 'S-1-5-32-544'; Group = 'S-1-5-32-544'; DiscretionaryAcl = @() }; $r = ConvertFrom-MtLdapSecurityDescriptor -ParsedDescriptor $mockSd; Write-Output \"$($r.Owner)\""
    Expected Result: Output is "S-1-5-32-544" (no PlatformNotSupportedException)
    Failure Indicators: Exception thrown means bypass not working
    Evidence: .sisyphus/evidence/plan10-task-2-injected-descriptor.txt

  Scenario: Default path still works on Windows
    Tool: Bash (pwsh)
    Preconditions: Windows runner
    Steps:
      1. pwsh -NoProfile -Command "Import-Module ./powershell/Maester.psd1; $raw = [byte[]]::new(100); $r = ConvertFrom-MtLdapSecurityDescriptor -RawSecurityDescriptor $raw; Write-Output \"$($r.GetType().Name)\""
    Expected Result: Output is "PSCustomObject" (no exception)
    Failure Indicators: Exception means default path regressed
    Evidence: .sisyphus/evidence/plan10-task-2-default-windows.txt
  ```

  **Evidence to Capture**:
  - [ ] task-2-injected-descriptor.txt
  - [ ] task-2-default-windows.txt

  **Commit**: YES
  - Message: `fix(ad): add injectable parsed descriptor for cross-platform testing`
  - Files: `powershell/internal/ad/protocol/ConvertFrom-MtLdapSecurityDescriptor.ps1`
  - Pre-commit: `pwsh -NoProfile -File ./powershell/tests/pester.ps1 -Include 'ActiveDirectoryProtocol.Tests.ps1'`

- [ ] 3. **ConvertFrom-MtLdapValue fixture tests**

  **What to do**:
  - Create `powershell/tests/functions/ConvertFrom-MtLdapValue.Tests.ps1`.
  - Cover all conversion paths with fixture-based `-TestCases`:
    - **GeneralizedTime**: `"20231001120000.0Z"` → `[datetime]`, `"19991231235959Z"` → `[datetime]`, garbage → `$null`
    - **FILETIME / accountExpires**: valid filetime → `[datetime]`, `0` → `$null`, `9223372036854775807` → `$null`
    - **Interval / maxPwdAge / lockoutDuration**: `"-36000000000"` → `[timespan]` (1 hour), `"0"` → `[timespan]::Zero`, `[long]::MinValue` (string) → `$null` (never sentinel), `[long]::MinValue` (int) → `$null`
    - **UAC bits**: integer → hashtable with `Enabled`, `PasswordNeverExpires`, etc.
    - **objectSid**: byte array → `PSCustomObject` with `.Value` = `"S-1-5-32-544"`, malformed bytes → raw bytes fallback
    - **GUID**: byte array → `[guid]`
    - **Null/empty**: `$null` input → `$null`, empty string → empty string, empty byte array → empty byte array
    - **Integer / string fallthrough**: `"42"` → `42`, `"notanumber"` → `"notanumber"` (string fallthrough)
  - Use `BeforeAll { Import-Module ... }` pattern.
  - Add `[Diagnostics.CodeAnalysis.SuppressMessageAttribute(...)]` headers for any analyzer rules tripped.

  **Must NOT do**:
  - Do not mock `ConvertFrom-MtLdapValue` itself — test the real function.
  - Do not test `Get-MtLdap*` query functions.
  - Do not assert platform-specific types (e.g., `-BeOfType [SecurityIdentifier]`).

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: Requires understanding LDAP value semantics and edge cases.
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES (with Tasks 4, 5)
  - **Parallel Group**: Wave 1
  - **Blocks**: None
  - **Blocked By**: Task 1

  **References**:
  - `powershell/internal/ad/protocol/ConvertFrom-MtLdapValue.ps1:1-233` — full source
  - `powershell/internal/ad/protocol/ConvertFrom-MtLdapValue.ps1:67-69` — `[long]::MinValue` string path
  - `powershell/internal/ad/protocol/ConvertFrom-MtLdapValue.ps1:225-232` — `[long]::MinValue` non-string path
  - `powershell/tests/functions/Invoke-Maester.Tests.ps1` — `-TestCases` pattern
  - `powershell/tests/functions/ActiveDirectoryProtocol.Tests.ps1` — platform-gate pattern

  **Acceptance Criteria**:
  - [ ] Test file created at `powershell/tests/functions/ConvertFrom-MtLdapValue.Tests.ps1`.
  - [ ] `pwsh -NoProfile -File ./powershell/tests/pester.ps1 -Include 'ConvertFrom-MtLdapValue.Tests.ps1'` → PASS.
  - [ ] Tests execute (not skipped) on Linux with at least 80% of test cases passing.
  - [ ] `[long]::MinValue` tests catch the "never" mapping bug (assert `$null`, not `"never"` string).

  **QA Scenarios**:

  ```
  Scenario: maxPwdAge [long]::MinValue returns null (happy path)
    Tool: Bash (pwsh)
    Preconditions: Module imported
    Steps:
      1. pwsh -NoProfile -Command "Import-Module ./powershell/Maester.psd1; InModuleScope Maester { $r = ConvertFrom-MtLdapValue -Value '-9223372036854775808' -AttributeName 'maxPwdAge'; if ($r -eq $null) { Write-Output 'PASS' } else { Write-Output \"FAIL: got $r\" } }"
    Expected Result: Output is "PASS"
    Failure Indicators: "FAIL" means regression in never mapping
    Evidence: .sisyphus/evidence/plan10-task-3-maxpwdage-never.txt

  Scenario: maxPwdAge [long]::MinValue integer returns null (edge case)
    Tool: Bash (pwsh)
    Preconditions: Module imported
    Steps:
      1. pwsh -NoProfile -Command "Import-Module ./powershell/Maester.psd1; InModuleScope Maester { $r = ConvertFrom-MtLdapValue -Value ([long]::MinValue) -AttributeName 'maxPwdAge'; if ($r -eq $null) { Write-Output 'PASS' } else { Write-Output \"FAIL: got $r\" } }"
    Expected Result: Output is "PASS"
    Failure Indicators: "FAIL" means second code path not covered
    Evidence: .sisyphus/evidence/plan10-task-3-maxpwdage-int.txt

  Scenario: objectSid returns .Value string on Linux (platform parity)
    Tool: Bash (pwsh)
    Preconditions: Ubuntu runner, module imported
    Steps:
      1. pwsh -NoProfile -Command "Import-Module ./powershell/Maester.psd1; InModuleScope Maester { $bytes = [byte[]]@(1,2,0,0,0,0,0,5,32,0,0,0,32,2,0,0); $r = ConvertFrom-MtLdapValue -Value $bytes -AttributeName 'objectSid'; Write-Output $r.Value }"
    Expected Result: Output is "S-1-5-32-544"
    Failure Indicators: Exception or empty output means objectSid regression
    Evidence: .sisyphus/evidence/plan10-task-3-objectsid-linux.txt

  Scenario: Invalid GeneralizedTime returns null (error path)
    Tool: Bash (pwsh)
    Preconditions: Module imported
    Steps:
      1. pwsh -NoProfile -Command "Import-Module ./powershell/Maester.psd1; InModuleScope Maester { $r = ConvertFrom-MtLdapValue -Value 'notadate' -AttributeName 'whenCreated'; if ($r -eq $null) { Write-Output 'PASS' } else { Write-Output \"FAIL: got $r\" } }"
    Expected Result: Output is "PASS"
    Failure Indicators: "FAIL" means error handling regressed
    Evidence: .sisyphus/evidence/plan10-task-3-invalid-date.txt
  ```

  **Evidence to Capture**:
  - [ ] task-3-maxpwdage-never.txt
  - [ ] task-3-maxpwdage-int.txt
  - [ ] task-3-objectsid-linux.txt
  - [ ] task-3-invalid-date.txt

  **Commit**: YES
  - Message: `test(ad): add fixture tests for ConvertFrom-MtLdapValue`
  - Files: `powershell/tests/functions/ConvertFrom-MtLdapValue.Tests.ps1`
  - Pre-commit: `pwsh -NoProfile -File ./powershell/tests/pester.ps1 -Include 'ConvertFrom-MtLdapValue.Tests.ps1'`

- [ ] 4. **ConvertFrom-MtLdapSecurityDescriptor fixture tests**

  **What to do**:
  - Create `powershell/tests/functions/ConvertFrom-MtLdapSecurityDescriptor.Tests.ps1`.
  - Use the `-ParsedDescriptor` parameter from Task 2 to inject mock descriptors.
  - Cover:
    - **Valid descriptor**: injected descriptor with owner, group, DACL → returns PSCustomObject with `.Owner`, `.Group`, `.Dacl`
    - **Local SID resolution**: mock descriptor with known SIDs → assert `.OwnerName` resolved via `SID.Translate()`
    - **Foreign SID fallback**: mock descriptor with unresolvable SIDs → assert fallback to raw SID string
    - **Non-Windows**: on Linux/macOS, test with `-ParsedDescriptor` to verify no `PlatformNotSupportedException`
    - **Malformed descriptor**: injected descriptor with missing properties → graceful error or sentinel
    - **Empty DACL**: injected descriptor with empty `DiscretionaryAcl` → returns empty Dacl array
  - Use `InModuleScope` to access the function if it's not exported.

  **Must NOT do**:
  - Do not call the function without `-ParsedDescriptor` on non-Windows (will throw).
  - Do not test actual `RawSecurityDescriptor` parsing on non-Windows.
  - Do not modify the function beyond Task 2's changes.

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: Requires understanding security descriptor structure and mock injection.
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES (with Tasks 3, 5)
  - **Parallel Group**: Wave 1
  - **Blocks**: None
  - **Blocked By**: Task 1, Task 2

  **References**:
  - `powershell/internal/ad/protocol/ConvertFrom-MtLdapSecurityDescriptor.ps1:1-133` — full source
  - `powershell/internal/ad/protocol/ConvertFrom-MtLdapSecurityDescriptor.ps1:20` — SID.Translate()
  - `powershell/tests/ad/transport/Get-MtSysvolContent.Tests.ps1:57-80` — InModuleScope + Mock pattern

  **Acceptance Criteria**:
  - [ ] Test file created at `powershell/tests/functions/ConvertFrom-MtLdapSecurityDescriptor.Tests.ps1`.
  - [ ] `pwsh -NoProfile -File ./powershell/tests/pester.ps1 -Include 'ConvertFrom-MtLdapSecurityDescriptor.Tests.ps1'` → PASS.
  - [ ] Tests with `-ParsedDescriptor` pass on Linux.
  - [ ] Tests catch non-Windows `PlatformNotSupportedException` when default path is used (documented skip).

  **QA Scenarios**:

  ```
  Scenario: Injected descriptor returns ACE list (happy path)
    Tool: Bash (pwsh)
    Preconditions: Module imported
    Steps:
      1. pwsh -NoProfile -Command "Import-Module ./powershell/Maester.psd1; InModuleScope Maester { $mock = [pscustomobject]@{ Owner = 'S-1-5-32-544'; Group = 'S-1-5-32-544'; DiscretionaryAcl = @() }; $r = ConvertFrom-MtLdapSecurityDescriptor -ParsedDescriptor $mock; Write-Output \"$($r.Owner)|$($r.Dacl.Count)\" }"
    Expected Result: Output is "S-1-5-32-544|0"
    Failure Indicators: Exception or wrong output means injectability broken
    Evidence: .sisyphus/evidence/plan10-task-4-injected-ace.txt

  Scenario: Non-Windows with default path is skipped (platform guard)
    Tool: Bash (pwsh)
    Preconditions: Ubuntu runner
    Steps:
      1. pwsh -NoProfile -Command "Import-Module ./powershell/Maester.psd1; InModuleScope Maester { try { ConvertFrom-MtLdapSecurityDescriptor -RawSecurityDescriptor ([byte[]]::new(100)); Write-Output 'FAIL' } catch { Write-Output 'PASS' } }"
    Expected Result: Output is "PASS" (PlatformNotSupportedException caught)
    Failure Indicators: "FAIL" means exception not thrown (unexpected)
    Evidence: .sisyphus/evidence/plan10-task-4-platform-guard.txt
  ```

  **Evidence to Capture**:
  - [ ] task-4-injected-ace.txt
  - [ ] task-4-platform-guard.txt

  **Commit**: YES
  - Message: `test(ad): add fixture tests for ConvertFrom-MtLdapSecurityDescriptor`
  - Files: `powershell/tests/functions/ConvertFrom-MtLdapSecurityDescriptor.Tests.ps1`
  - Pre-commit: `pwsh -NoProfile -File ./powershell/tests/pester.ps1 -Include 'ConvertFrom-MtLdapSecurityDescriptor.Tests.ps1'`

- [ ] 5. **Shared fixture helpers dot-source file**

  **What to do**:
  - Create `powershell/tests/functions/ActiveDirectoryProtocol.Fixtures.ps1`.
  - Provide reusable fixture data and helper functions:
    - `New-MtMockLdapSearchResultEntry` — returns `[pscustomobject]@{ DistinguishedName='...'; Attributes=@{...} }` for paging tests.
    - `New-MtMockSecurityDescriptor` — returns a mock descriptor object for security descriptor tests.
    - `New-MtMockSmbClientOutput` — returns sample `smbclient` stdout strings for parser tests.
    - `New-MtMockLdapConnection` — returns an `[System.DirectoryServices.Protocols.LdapConnection]` with `MtSendRequestOverride` note property.
  - Keep helpers minimal — no custom Pester assertions, no DSL.

  **Must NOT do**:
  - Do not create a `.psm1` module.
  - Do not add external dependencies.
  - Do not over-engineer — helpers should be <150 lines total.

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Simple scaffolding, low complexity.
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES (with Tasks 3, 4)
  - **Parallel Group**: Wave 1
  - **Blocks**: Tasks 6, 7, 8
  - **Blocked By**: None

  **References**:
  - `powershell/tests/general/Build-MaesterModule.Tests.ps1:19-45` — Initialize-BuildFixture pattern
  - `powershell/internal/ad/protocol/Invoke-MtLdapSearch.ps1:193-195` — MtSendRequestOverride seam

  **Acceptance Criteria**:
  - [ ] File created at `powershell/tests/functions/ActiveDirectoryProtocol.Fixtures.ps1`.
  - [ ] `New-MtMockLdapSearchResultEntry` produces valid fake entries for `Convert-SearchEntry`.
  - [ ] `New-MtMockLdapConnection` works on Linux without network.
  - [ ] Helpers import without errors in `pwsh -NoProfile`.

  **QA Scenarios**:

  ```
  Scenario: Mock entry works with Convert-SearchEntry
    Tool: Bash (pwsh)
    Preconditions: Module imported
    Steps:
      1. pwsh -NoProfile -Command ". ./powershell/tests/functions/ActiveDirectoryProtocol.Fixtures.ps1; $entry = New-MtMockLdapSearchResultEntry -DN 'CN=test' -Attributes @{ cn = 'test' }; Write-Output \"$($entry.DistinguishedName)|$($entry.Attributes.cn)\""
    Expected Result: Output is "CN=test|test"
    Failure Indicators: Exception means helper broken
    Evidence: .sisyphus/evidence/plan10-task-5-mock-entry.txt

  Scenario: Mock connection constructs on Linux
    Tool: Bash (pwsh)
    Preconditions: Ubuntu runner
    Steps:
      1. pwsh -NoProfile -Command ". ./powershell/tests/functions/ActiveDirectoryProtocol.Fixtures.ps1; $conn = New-MtMockLdapConnection -Server 'fake.local'; Write-Output $conn.GetType().Name"
    Expected Result: Output is "LdapConnection"
    Failure Indicators: Exception means connection helper broken on Linux
    Evidence: .sisyphus/evidence/plan10-task-5-mock-conn.txt
  ```

  **Evidence to Capture**:
  - [ ] task-5-mock-entry.txt
  - [ ] task-5-mock-conn.txt

  **Commit**: YES (grouped with Tasks 3-4)
  - Message: `test(ad): add shared fixture helpers for AD protocol tests`
  - Files: `powershell/tests/functions/ActiveDirectoryProtocol.Fixtures.ps1`
  - Pre-commit: `pwsh -NoProfile -Command ". ./powershell/tests/functions/ActiveDirectoryProtocol.Fixtures.ps1; Write-Output 'OK'"`

- [ ] 6. **Invoke-MtLdapSearch paging mock tests**

  **What to do**:
  - Create `powershell/tests/functions/Invoke-MtLdapSearch.Paging.Tests.ps1`.
  - Use the `MtSendRequestOverride` seam to mock LDAP server responses without network.
  - Cover:
    - **Single page**: override returns one entry → result has one item, no paging cookie.
    - **Multi-page with cookie**: override returns page 1 with cookie, page 2 with empty cookie → result aggregates both pages.
    - **Empty result**: override returns zero entries → result is empty array.
    - **Server error**: override throws `OperationCanceledException` → mapped to `'LDAP search was cancelled.'`.
    - **Timeout exception**: override throws `TimeoutException` → message includes timeout value.
    - **Scalar collapse bug**: override returns single-valued attribute `cACertificate` → assert `.Count` returns `1`, not byte length.
    - **PageSize = 0**: no page control, single iteration.
    - **Non-advancing cookie**: override returns same cookie repeatedly → infinite loop risk (document, do not assert bounded iterations without source change).
  - Fake entries must be `[pscustomobject]@{ DistinguishedName='...'; Attributes=@{...} }` — `SearchResultEntry` has zero public constructors.

  **Must NOT do**:
  - Do not require a live LDAP connection.
  - Do not modify `Invoke-MtLdapSearch` source (except the existing `MtSendRequestOverride` seam).
  - Do not test query logic — only paging and error handling.

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: Requires understanding LDAP paging protocol and mock injection.
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES (with Tasks 7, 8)
  - **Parallel Group**: Wave 2
  - **Blocks**: None
  - **Blocked By**: Task 5

  **References**:
  - `powershell/internal/ad/protocol/Invoke-MtLdapSearch.ps1:1-195` — full source
  - `powershell/internal/ad/protocol/Invoke-MtLdapSearch.ps1:86-87` — scalar collapse lines
  - `powershell/internal/ad/protocol/Invoke-MtLdapSearch.ps1:193-195` — MtSendRequestOverride seam
  - `powershell/internal/ad/protocol/Invoke-MtLdapSearch.ps1:132` — absent attribute back-fill
  - `powershell/tests/functions/ActiveDirectoryProtocol.Fixtures.ps1` — shared helpers

  **Acceptance Criteria**:
  - [ ] Test file created at `powershell/tests/functions/Invoke-MtLdapSearch.Paging.Tests.ps1`.
  - [ ] `pwsh -NoProfile -File ./powershell/tests/pester.ps1 -Include 'Invoke-MtLdapSearch.Paging.Tests.ps1'` → PASS.
  - [ ] Multi-page test aggregates entries from both pages.
  - [ ] Scalar collapse test asserts `cACertificate.Count -eq 1` (not byte array length).
  - [ ] Error mapping tests verify exact exception messages.

  **QA Scenarios**:

  ```
  Scenario: Multi-page search aggregates entries (happy path)
    Tool: Bash (pwsh)
    Preconditions: Module imported, fixtures loaded
    Steps:
      1. pwsh -NoProfile -Command "Import-Module ./powershell/Maester.psd1; . ./powershell/tests/functions/ActiveDirectoryProtocol.Fixtures.ps1; InModuleScope Maester { $conn = New-MtMockLdapConnection; $page = 0; $conn | Add-Member -NotePropertyName MtSendRequestOverride -NotePropertyValue { param($req,$to) $page++; if ($page -eq 1) { return [pscustomobject]@{ Entries = @(New-MtMockLdapSearchResultEntry -DN 'CN=1'); Cookie = [byte[]]@(1) } } else { return [pscustomobject]@{ Entries = @(New-MtMockLdapSearchResultEntry -DN 'CN=2'); Cookie = $null } } }; $r = Invoke-MtLdapSearch -Connection $conn -SearchBase 'DC=test' -PageSize 1; Write-Output $r.Count }"
    Expected Result: Output is "2"
    Failure Indicators: "1" means paging not aggregating
    Evidence: .sisyphus/evidence/plan10-task-6-multipage.txt

  Scenario: Single-valued attribute Count is 1 not byte length (bug regression)
    Tool: Bash (pwsh)
    Preconditions: Module imported, fixtures loaded
    Steps:
      1. pwsh -NoProfile -Command "Import-Module ./powershell/Maester.psd1; . ./powershell/tests/functions/ActiveDirectoryProtocol.Fixtures.ps1; InModuleScope Maester { $conn = New-MtMockLdapConnection; $conn | Add-Member -NotePropertyName MtSendRequestOverride -NotePropertyValue { param($req,$to) return [pscustomobject]@{ Entries = @([pscustomobject]@{ DistinguishedName='CN=test'; Attributes=@{ cACertificate = [byte[]]@(1,2,3) } }); Cookie = $null } }; $r = Invoke-MtLdapSearch -Connection $conn -SearchBase 'DC=test' -Attributes 'cACertificate'; Write-Output $r.cACertificate.Count }"
    Expected Result: Output is "1"
    Failure Indicators: "3" means scalar collapse bug (byte length)
    Evidence: .sisyphus/evidence/plan10-task-6-scalar-collapse.txt

  Scenario: Server cancellation maps to correct message (error path)
    Tool: Bash (pwsh)
    Preconditions: Module imported, fixtures loaded
    Steps:
      1. pwsh -NoProfile -Command "Import-Module ./powershell/Maester.psd1; . ./powershell/tests/functions/ActiveDirectoryProtocol.Fixtures.ps1; InModuleScope Maester { $conn = New-MtMockLdapConnection; $conn | Add-Member -NotePropertyName MtSendRequestOverride -NotePropertyValue { throw [System.OperationCanceledException]::new('cancelled') }; try { Invoke-MtLdapSearch -Connection $conn -SearchBase 'DC=test'; Write-Output 'FAIL' } catch { Write-Output $_.Exception.Message } }"
    Expected Result: Output contains "LDAP search was cancelled"
    Failure Indicators: "FAIL" or wrong message means error mapping broken
    Evidence: .sisyphus/evidence/plan10-task-6-cancel-error.txt
  ```

  **Evidence to Capture**:
  - [ ] task-6-multipage.txt
  - [ ] task-6-scalar-collapse.txt
  - [ ] task-6-cancel-error.txt

  **Commit**: YES
  - Message: `test(ad): add paging mock tests for Invoke-MtLdapSearch`
  - Files: `powershell/tests/functions/Invoke-MtLdapSearch.Paging.Tests.ps1`
  - Pre-commit: `pwsh -NoProfile -File ./powershell/tests/pester.ps1 -Include 'Invoke-MtLdapSearch.Paging.Tests.ps1'`

- [ ] 7. **Get-MtLdapRangedValue mock tests**

  **What to do**:
  - Create `powershell/tests/functions/Get-MtLdapRangedValue.Tests.ps1`.
  - Mock `Invoke-MtLdapSearch` to simulate ranged attribute responses.
  - Cover:
    - **Single range**: first request returns `member;range=0-1499` with 1500 values, next returns `member;range=1500-*` with remaining → aggregated array.
    - **Multiple ranges**: simulate 3+ range requests → all values aggregated.
    - **Duplicates**: same value appears in multiple ranges → deduplicated or preserved (characterize current behavior).
    - **Invalid DN**: DN with special characters `(`, `)`, `*`, `\` → filter escaping works.
    - **Empty attribute**: no values returned → empty array.
    - **Non-advancing range**: server returns same range repeatedly → document infinite loop risk.
  - Use `Mock -CommandName Invoke-MtLdapSearch -ModuleName Maester` pattern.

  **Must NOT do**:
  - Do not require a live LDAP connection.
  - Do not modify `Get-MtLdapRangedValue` source.
  - Do not test beyond the range retrieval logic.

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: Requires understanding LDAP ranged retrieval and mock patterns.
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES (with Tasks 6, 8)
  - **Parallel Group**: Wave 2
  - **Blocks**: None
  - **Blocked By**: Task 5

  **References**:
  - `powershell/internal/ad/protocol/Get-MtLdapRangedValue.ps1:1-65` — full source
  - `powershell/internal/ad/protocol/Get-MtLdapRangedValue.ps1:22` — filter escaping
  - `powershell/tests/ad/transport/Get-MtSysvolContent.Tests.ps1:57-80` — Mock pattern

  **Acceptance Criteria**:
  - [ ] Test file created at `powershell/tests/functions/Get-MtLdapRangedValue.Tests.ps1`.
  - [ ] `pwsh -NoProfile -File ./powershell/tests/pester.ps1 -Include 'Get-MtLdapRangedValue.Tests.ps1'` → PASS.
  - [ ] Single range test aggregates 1500 + remaining values.
  - [ ] Invalid DN test verifies filter escaping does not throw.

  **QA Scenarios**:

  ```
  Scenario: Single range aggregates all values (happy path)
    Tool: Bash (pwsh)
    Preconditions: Test file exists, module imported
    Steps:
      1. pwsh -NoProfile -File ./powershell/tests/pester.ps1 -Include 'Get-MtLdapRangedValue.Tests.ps1'
    Expected Result: Exit code 0, output shows all tests passed
    Failure Indicators: Non-zero exit or failure message
    Evidence: .sisyphus/evidence/plan10-task-7-single-range.txt

  Scenario: Invalid DN with special characters (edge case)
    Tool: Bash (pwsh)
    Preconditions: Test file exists, module imported
    Steps:
      1. pwsh -NoProfile -File ./powershell/tests/pester.ps1 -Include 'Get-MtLdapRangedValue.Tests.ps1'
    Expected Result: Exit code 0, DN escaping test passes
    Failure Indicators: Non-zero exit or failure message
    Evidence: .sisyphus/evidence/plan10-task-7-invalid-dn.txt
  ```

  **Evidence to Capture**:
  - [ ] task-7-single-range.txt
  - [ ] task-7-invalid-dn.txt

  **Commit**: YES
  - Message: `test(ad): add mock tests for Get-MtLdapRangedValue`
  - Files: `powershell/tests/functions/Get-MtLdapRangedValue.Tests.ps1`
  - Pre-commit: `pwsh -NoProfile -File ./powershell/tests/pester.ps1 -Include 'Get-MtLdapRangedValue.Tests.ps1'`

- [ ] 8. **Get-MtSysvolContent smbclient output parsing tests**

  **What to do**:
  - Create `powershell/tests/functions/Get-MtSysvolContent.SmbClient.Tests.ps1`.
  - Mock `Invoke-MtSysvolSmbClient` to return sample stdout strings.
  - Cover:
    - **Normal listing**: standard `smbclient` output with files and directories → parsed inventory with correct names, sizes, attributes.
    - **Permission denied**: `smbclient` returns error → graceful handling, empty result or specific error.
    - **Empty share**: no files → empty inventory.
    - **Path not found**: `NT_STATUS_OBJECT_PATH_NOT_FOUND` → specific error handling.
    - **Filenames with spaces**: non-greedy regex `.+?` ambiguity → verify correct parsing.
    - **Empty attribute column**: Samba prints empty DOS attributes → file not silently dropped (document current behavior if it is dropped).
    - **CRLF vs LF**: output uses different line endings → parser handles both.
    - **`.` and `..` entries**: skipped correctly.
  - Use `Mock -CommandName Invoke-MtSysvolSmbClient -ModuleName Maester` pattern.

  **Must NOT do**:
  - Do not require `smbclient` to be installed.
  - Do not modify `Get-MtSysvolContent` source (characterize bugs, do not fix).
  - Do not test Windows adapter — only Unix `smbclient` parsing.

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: Requires understanding smbclient output format and regex edge cases.
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES (with Tasks 6, 7)
  - **Parallel Group**: Wave 2
  - **Blocks**: None
  - **Blocked By**: Task 5

  **References**:
  - `powershell/internal/ad/transport/Get-MtSysvolContent.ps1:616-631` — smbclient parsing (Invoke-MtSysvolUnixAdapter, List branch)
  - `powershell/internal/ad/transport/Get-MtSysvolContent.ps1:624` — regex with `[A-Z]+` attribute column
  - `powershell/tests/ad/transport/Get-MtSysvolContent.Tests.ps1` — existing mock patterns for Windows adapter
  - `powershell/tests/functions/ActiveDirectoryProtocol.Fixtures.ps1` — shared helpers

  **Acceptance Criteria**:
  - [ ] Test file created at `powershell/tests/functions/Get-MtSysvolContent.SmbClient.Tests.ps1`.
  - [ ] `pwsh -NoProfile -File ./powershell/tests/pester.ps1 -Include 'Get-MtSysvolContent.SmbClient.Tests.ps1'` → PASS.
  - [ ] Normal listing test parses at least 3 files correctly.
  - [ ] Permission denied test does not throw unhandled exception.

  **QA Scenarios**:

  ```
  Scenario: Normal smbclient listing parsed correctly (happy path)
    Tool: Bash (pwsh)
    Preconditions: Test file exists, module imported
    Steps:
      1. pwsh -NoProfile -File ./powershell/tests/pester.ps1 -Include 'Get-MtSysvolContent.SmbClient.Tests.ps1'
    Expected Result: Exit code 0, normal listing test passes
    Failure Indicators: Non-zero exit or failure message
    Evidence: .sisyphus/evidence/plan10-task-8-normal-listing.txt

  Scenario: Permission denied handled gracefully (error path)
    Tool: Bash (pwsh)
    Preconditions: Test file exists, module imported
    Steps:
      1. pwsh -NoProfile -File ./powershell/tests/pester.ps1 -Include 'Get-MtSysvolContent.SmbClient.Tests.ps1'
    Expected Result: Exit code 0, permission denied test passes
    Failure Indicators: Non-zero exit or failure message
    Evidence: .sisyphus/evidence/plan10-task-8-perm-denied.txt
  ```

  **Evidence to Capture**:
  - [ ] task-8-normal-listing.txt
  - [ ] task-8-perm-denied.txt

  **Commit**: YES
  - Message: `test(ad): add smbclient output parsing fixture tests`
  - Files: `powershell/tests/functions/Get-MtSysvolContent.SmbClient.Tests.ps1`
  - Pre-commit: `pwsh -NoProfile -File ./powershell/tests/pester.ps1 -Include 'Get-MtSysvolContent.SmbClient.Tests.ps1'`

- [ ] 9. **Cross-platform CI execution verification**

  **What to do**:
  - Verify all new test files pass on all 4 CI legs by running locally or in CI-equivalent environments.
  - Legs to verify:
    1. Windows + pwsh 7
    2. Windows + PowerShell 5.1
    3. Ubuntu + pwsh 7
    4. macOS + pwsh 7 (if available locally; otherwise document)
  - Run full pester suite: `pwsh -NoProfile -File ./powershell/tests/pester.ps1`.
  - Verify skip counts are acceptable (not everything skipped on Linux).
  - Document any leg-specific skips with inline comments.

  **Must NOT do**:
  - Do not add new CI workflows or matrix legs.
  - Do not modify `build-validation.yaml` unless necessary (tests in `functions/` are already discovered).

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Verification task, no new code.
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES (with Tasks 10, 11)
  - **Parallel Group**: Wave 3
  - **Blocks**: None
  - **Blocked By**: Tasks 3-8

  **References**:
  - `.github/workflows/build-validation.yaml` — CI matrix
  - `powershell/tests/pester.ps1` — test runner

  **Acceptance Criteria**:
  - [ ] `pwsh -NoProfile -File ./powershell/tests/pester.ps1` passes on Windows pwsh.
  - [ ] `powershell -NoProfile -File ./powershell/tests/pester.ps1` passes on Windows PS5.1.
  - [ ] `pwsh -NoProfile -File ./powershell/tests/pester.ps1` passes on Ubuntu.
  - [ ] At least 80% of new tests execute (not skipped) on Ubuntu.

  **QA Scenarios**:

  ```
  Scenario: Full suite passes on Ubuntu
    Tool: Bash (pwsh)
    Preconditions: Ubuntu runner
    Steps:
      1. pwsh -NoProfile -File ./powershell/tests/pester.ps1
    Expected Result: Exit code 0, output contains "All tests executed without a single failure!"
    Failure Indicators: Non-zero exit code or failure message
    Evidence: .sisyphus/evidence/plan10-task-9-ubuntu-full.txt

  Scenario: Skip count acceptable on Ubuntu
    Tool: Bash (pwsh)
    Preconditions: Ubuntu runner
    Steps:
      1. pwsh -NoProfile -Command "$r = Invoke-Pester -Path ./powershell/tests/functions -PassThru -Output None; Write-Output \"passed=$($r.PassedCount) skipped=$($r.SkippedCount) failed=$($r.FailedCount)\""
    Expected Result: failed=0, skipped < 20% of total
    Failure Indicators: skipped > 20% means too many platform-gated tests
    Evidence: .sisyphus/evidence/plan10-task-9-skip-count.txt
  ```

  **Evidence to Capture**:
  - [ ] task-9-ubuntu-full.txt
  - [ ] task-9-skip-count.txt

  **Commit**: NO (verification only)

- [ ] 10. **PSScriptAnalyzer + meta-test validation**

  **What to do**:
  - Run `Invoke-ScriptAnalyzer` on all new test files to catch analyzer regressions.
  - Run meta-tests (`PesterVersionPinning.Tests.ps1`, `Manifest.Tests.ps1`) to ensure pester.ps1 edits didn't break them.
  - Verify new test files carry `[Diagnostics.CodeAnalysis.SuppressMessageAttribute(...)]` headers where needed.

  **Must NOT do**:
  - Do not add new analyzer rules or settings files.
  - Do not modify meta-test files.

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Validation task, no new code.
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES (with Tasks 9, 11)
  - **Parallel Group**: Wave 3
  - **Blocks**: None
  - **Blocked By**: Tasks 3-8

  **References**:
  - `.github/workflows/psscriptanalyzer.yml` — analyzer workflow
  - `powershell/tests/general/PesterVersionPinning.Tests.ps1` — meta-test
  - `powershell/tests/general/Manifest.Tests.ps1` — meta-test
  - `powershell/tests/ad/transport/Invoke-MtADManagementCommand.Tests.ps1:1-10` — suppression header style

  **Acceptance Criteria**:
  - [ ] `Invoke-ScriptAnalyzer -Path ./powershell/tests/functions -Recurse | Where-Object Severity -in Error,Warning` returns no output.
  - [ ] `pwsh -NoProfile -File ./powershell/tests/pester.ps1 -Include 'PesterVersionPinning.Tests.ps1'` → PASS.
  - [ ] `pwsh -NoProfile -File ./powershell/tests/pester.ps1 -Include 'Manifest.Tests.ps1'` → PASS.

  **QA Scenarios**:

  ```
  Scenario: No analyzer errors on new files
    Tool: Bash (pwsh)
    Preconditions: Module imported
    Steps:
      1. pwsh -NoProfile -Command "Invoke-ScriptAnalyzer -Path ./powershell/tests/functions -Recurse | Where-Object Severity -in Error,Warning | Measure-Object | Select-Object -ExpandProperty Count"
    Expected Result: Output is "0"
    Failure Indicators: Non-zero means analyzer regressions
    Evidence: .sisyphus/evidence/plan10-task-10-analyzer.txt

  Scenario: Meta-tests still pass
    Tool: Bash (pwsh)
    Preconditions: None
    Steps:
      1. pwsh -NoProfile -File ./powershell/tests/pester.ps1 -Include 'PesterVersionPinning.Tests.ps1'
      2. pwsh -NoProfile -File ./powershell/tests/pester.ps1 -Include 'Manifest.Tests.ps1'
    Expected Result: Both exit with code 0
    Failure Indicators: Non-zero exit means meta-test regression
    Evidence: .sisyphus/evidence/plan10-task-10-meta.txt
  ```

  **Evidence to Capture**:
  - [ ] task-10-analyzer.txt
  - [ ] task-10-meta.txt

  **Commit**: NO (verification only)

- [ ] 11. **Module build validation**

  **What to do**:
  - Run the module build script: `pwsh -File ./build/Build-MaesterModule.ps1`.
  - Run the module output validation: `pwsh -File ./build/Test-MaesterModuleOutput.ps1`.
  - Verify the built module imports correctly with the source changes from Tasks 1 and 2.

  **Must NOT do**:
  - Do not modify build scripts.
  - Do not change module manifest version or exports.

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Validation task, no new code.
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES (with Tasks 9, 10)
  - **Parallel Group**: Wave 3
  - **Blocks**: None
  - **Blocked By**: Tasks 1, 2

  **References**:
  - `build/Build-MaesterModule.ps1` — build script
  - `build/Test-MaesterModuleOutput.ps1` — validation script

  **Acceptance Criteria**:
  - [ ] `pwsh -File ./build/Build-MaesterModule.ps1` exits with code 0.
  - [ ] `pwsh -File ./build/Test-MaesterModuleOutput.ps1` exits with code 0.
  - [ ] Built module imports in `pwsh -NoProfile` without errors.

  **QA Scenarios**:

  ```
  Scenario: Module builds successfully
    Tool: Bash (pwsh)
    Preconditions: None
    Steps:
      1. pwsh -File ./build/Build-MaesterModule.ps1
      2. pwsh -File ./build/Test-MaesterModuleOutput.ps1
    Expected Result: Both exit with code 0
    Failure Indicators: Non-zero exit means build regression
    Evidence: .sisyphus/evidence/plan10-task-11-build.txt
  ```

  **Evidence to Capture**:
  - [ ] task-11-build.txt

  **Commit**: NO (verification only)

---

## Final Verification Wave

> 4 review agents run in PARALLEL. ALL must APPROVE. Present consolidated results to user and get explicit "okay" before completing.

- [ ] F1. **Plan Compliance Audit** — `oracle`
  Read the plan end-to-end. For each "Must Have": verify implementation exists (read file, run command). For each "Must NOT Have": search codebase for forbidden patterns — reject with file:line if found. Check evidence files exist in `.sisyphus/evidence/`. Compare deliverables against plan.
  Output: `Must Have [N/N] | Must NOT Have [N/N] | Tasks [N/N] | VERDICT: APPROVE/REJECT`

- [ ] F2. **Code Quality Review** — `unspecified-high`
  Run `pwsh -NoProfile -File ./powershell/tests/pester.ps1` (full suite). Review all changed files for: `as any`/`@ts-ignore`, empty catches, `Write-Host`/`console.log`, commented-out code, unused imports. Check AI slop: excessive comments, over-abstraction, generic names (`data`/`result`/`item`/`temp`).
  Output: `Tests [PASS/FAIL] | Files [N clean/N issues] | VERDICT`

- [ ] F3. **Real Manual QA** — `unspecified-high`
  Start from clean state. Execute EVERY QA scenario from EVERY task — follow exact steps, capture evidence. Test cross-task integration (features working together). Test edge cases: empty state, invalid input, rapid actions. Save to `.sisyphus/evidence/final-qa/`.
  Output: `Scenarios [N/N pass] | Integration [N/N] | Edge Cases [N tested] | VERDICT`

- [ ] F4. **Scope Fidelity Check** — `deep`
  For each task: read "What to do", read actual diff (`git log --oneline -10`, `git diff`). Verify 1:1 — everything in spec was built, nothing beyond spec was built. Check "Must NOT do" compliance. Detect cross-task contamination. Flag unaccounted changes.
  Output: `Tasks [N/N compliant] | Contamination [CLEAN/N issues] | Unaccounted [CLEAN/N files] | VERDICT`

---

## Commit Strategy

- **Task 1**: `fix(ad): normalize objectSid return type across platforms`
  - Files: `powershell/internal/ad/protocol/ConvertFrom-MtLdapValue.ps1`
  - Pre-commit: `pwsh -NoProfile -File ./powershell/tests/pester.ps1 -Include 'ActiveDirectoryProtocol.Tests.ps1'`

- **Task 2**: `fix(ad): add injectable parsed descriptor for cross-platform testing`
  - Files: `powershell/internal/ad/protocol/ConvertFrom-MtLdapSecurityDescriptor.ps1`
  - Pre-commit: `pwsh -NoProfile -File ./powershell/tests/pester.ps1 -Include 'ActiveDirectoryProtocol.Tests.ps1'`

- **Tasks 3-5**: `test(ad): add fixture tests and helpers for AD protocol layer`
  - Files: `powershell/tests/functions/ConvertFrom-MtLdapValue.Tests.ps1`, `powershell/tests/functions/ConvertFrom-MtLdapSecurityDescriptor.Tests.ps1`, `powershell/tests/functions/ActiveDirectoryProtocol.Fixtures.ps1`
  - Pre-commit: Run once per file: `pwsh -NoProfile -File ./powershell/tests/pester.ps1 -Include 'ConvertFrom-MtLdapValue.Tests.ps1'` then `pwsh -NoProfile -File ./powershell/tests/pester.ps1 -Include 'ConvertFrom-MtLdapSecurityDescriptor.Tests.ps1'`

- **Tasks 6-8**: `test(ad): add paging, ranged value, and smbclient parser tests`
  - Files: `powershell/tests/functions/Invoke-MtLdapSearch.Paging.Tests.ps1`, `powershell/tests/functions/Get-MtLdapRangedValue.Tests.ps1`, `powershell/tests/functions/Get-MtSysvolContent.SmbClient.Tests.ps1`
  - Pre-commit: Run once per file: `pwsh -NoProfile -File ./powershell/tests/pester.ps1 -Include 'Invoke-MtLdapSearch.Paging.Tests.ps1'` then `pwsh -NoProfile -File ./powershell/tests/pester.ps1 -Include 'Get-MtLdapRangedValue.Tests.ps1'` then `pwsh -NoProfile -File ./powershell/tests/pester.ps1 -Include 'Get-MtSysvolContent.SmbClient.Tests.ps1'`

---

## Success Criteria

### Verification Commands
```bash
# Full suite green on Windows pwsh
pwsh -NoProfile -File ./powershell/tests/pester.ps1
# Expected: exit 0

# Full suite green on Ubuntu
pwsh -NoProfile -File ./powershell/tests/pester.ps1
# Expected: exit 0

# Module builds
pwsh -File ./build/Build-MaesterModule.ps1
# Expected: exit 0

# Module output validates
pwsh -File ./build/Test-MaesterModuleOutput.ps1
# Expected: exit 0

# No analyzer regressions
pwsh -Command "Invoke-ScriptAnalyzer -Path ./powershell/tests/functions -Recurse | Where-Object Severity -in Error,Warning"
# Expected: no output

# No source files modified beyond Tasks 1-2
git diff --name-only origin/main -- powershell/internal powershell/public
# Expected: only ConvertFrom-MtLdapValue.ps1 and ConvertFrom-MtLdapSecurityDescriptor.ps1
```

### Final Checklist
- [ ] `ConvertFrom-MtLdapValue` fixtures catch the `[long]::MinValue` → "never" bug (both string and int paths).
- [ ] `ConvertFrom-MtLdapSecurityDescriptor` fixtures catch non-Windows `PlatformNotSupportedException` (with `-ParsedDescriptor` bypass).
- [ ] `Invoke-MtLdapSearch` mock tests catch single-valued attribute scalar collapse (`cACertificate.Count` returns `1`, not byte length).
- [ ] All fixtures pass on Windows PS7, Windows PS5.1, and Ubuntu PS7.
- [ ] `pwsh -NoProfile -File ./powershell/tests/pester.ps1` passes with new tests included.
- [ ] No analyzer errors on new test files.
- [ ] Meta-tests (`PesterVersionPinning`, `Manifest`) still pass.
- [ ] Module builds and validates successfully.


