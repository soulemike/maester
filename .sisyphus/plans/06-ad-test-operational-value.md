# AD Test Quality Improvement Plan

## TL;DR

> **Quick Summary**: Systematically fix all identified quality issues in the Maester Active Directory test suite (270 test wrappers, 92 hardcoded-$true functions, 28 missing .md files, 17 empty-table tests). Reclassify informational tests as `investigate` (Operational controls), add real security thresholds where applicable (Preventive/Detective controls), fix the silent-pass bug, and validate end-to-end via azure-lab with pre/post report comparison.
>
> **Deliverables**:
> - 270 test wrappers with fixed silent-pass bug
> - 92 functions audited and categorized (investigate vs threshold)
> - 28 missing companion .md files in gpostate/
> - 17 tests with suppressed empty tables
> - Pre-change and post-change HTML/JSON reports from azure-lab
> - Report comparison documenting status count deltas
>
> **Estimated Effort**: Large (250+ files across multiple categories)
> **Parallel Execution**: YES — 4 waves
> **Critical Path**: T1-T6 (silent-pass fix) → T9 (audit) → T10-T11 (reclassify/thresholds) → T13-T15 (baseline/validation)

---

## Context

### Original Request
Using the .sisyphus/drafts/AD_TESTS_ANALYSIS.md as context, build a plan to improve the test quality and value for the AD tests within the project. Ensure all tests align with the same project structure. Perform end to end testing as part of validation with comparison of reports between the pre-change and post-change results.

### Interview Summary
**Key Decisions**:
- **Scope**: ALL issues (P0, P1, P2) from AD_TESTS_ANALYSIS.md
- **Classification Strategy**: Hybrid approach
  - Reclassify purely informational tests as `investigate` status (Operational controls)
  - Add real security thresholds where possible (Preventive/Detective controls)
- **End-to-End Testing**: YES, using azure-lab + labconfig
  - Capture pre-change baseline reports
  - Capture post-change reports
  - Compare and validate improvements
- **AD Environment**: Available via build/activeDirectory/azure-lab/

### Research Findings
- "Investigate" is a first-class UI status (purple badge, sort order 4 between Failed and Passed)
- `Add-MtTestResultDetail` supports `-Investigate` flag
- Test wrappers use pattern: `if ($null -ne $result) { $result | Should -Be $true }` with no else block
- Good example: `Test-MtAdDomainNameStandardCompliance` computes real boolean from data
- AD runner: `build/activeDirectory/Run-ADTests-And-CopyReports.ps1`
- Report generated via `Get-MtHtmlReport.ps1` + `powershell/assets/ReportTemplate.html`

### Metis Review
**Identified Gaps** (addressed in plan):
- **Guardrails**: Restrict changes to AD tests only; no non-AD test modifications
- **Scope creep**: No new reporting formats; no broad reclassification beyond stated items
- **Assumptions**: Uniform else block for silent-pass fix; azure-lab stability noted as risk
- **Edge cases**: Flaky AD environment, race conditions, backward compatibility
- **Acceptance criteria**: All P0-P2 resolved; pre/post reports compared; zero regressions

---

## Work Objectives

### Core Objective
Transform the Maester AD test suite from a data-collection tool into a security validation framework by fixing structural bugs, adding meaningful pass/fail thresholds, and ensuring consistent documentation and reporting.

### Concrete Deliverables
- All 270 test wrappers emit `Skipped` when AD data cannot be retrieved (no silent passes)
- All 92 hardcoded-$true functions categorized and updated (investigate or threshold)
- 28 missing companion .md files created in `powershell/public/ad/gpostate/`
- 17 detail tests suppress empty markdown tables on pass
- Pre-change and post-change HTML/JSON reports captured from azure-lab
- Report comparison documenting status count deltas and new failures

### Definition of Done
- [ ] `Invoke-Maester` runs on AD tests with zero silent passes when AD is disconnected
- [ ] All AD tests have companion .md documentation
- [ ] No empty markdown tables in test output when findings count is zero
- [ ] Pre/post report comparison shows expected status shifts (retrievable→investigate, threshold tests→fail when misconfigured)
- [ ] Unit tests (`./powershell/tests/pester.ps1`) pass for modified module functions

### Must Have
- Silent-pass bug fixed in ALL 270 test wrappers
- 28 missing .md files created with consistent template
- 17 empty-table tests fixed
- Pre/post report comparison completed via azure-lab

### Must NOT Have (Guardrails)
- Changes to non-AD test trees (CIS, CISA, EIDSCA, MT, etc.)
- New reporting formats or dependencies
- Breaking changes to `Add-MtTestResultDetail` or `Get-MtHtmlReport` APIs
- Removal of existing test data — only change result classification and thresholds
- Hand-editing of generated content (website/docs/commands/, website/docs/tests/)

---

## Verification Strategy

> **ZERO HUMAN INTERVENTION** — ALL verification is agent-executed. No exceptions.

### Test Decision
- **Infrastructure exists**: YES — Pester tests in `./powershell/tests/pester.ps1`
- **Automated tests**: Tests-after — validate modified module functions via unit tests
- **Framework**: Pester (PowerShell)
- **Agent-Executed QA**: ALWAYS — every task includes explicit QA scenarios

### QA Policy
Every task MUST include agent-executed QA scenarios.
Evidence saved to `.sisyphus/evidence/task-{N}-{scenario-slug}.{ext}`.

- **PowerShell/Module**: Use Bash (pwsh) — Import module, call functions, compare output
- **Report Validation**: Use Bash (pwsh) — Run Invoke-Maester, assert HTML/JSON output exists, parse status counts
- **Test Wrapper Validation**: Use Bash (pwsh) — Run Pester on modified .Tests.ps1 files, assert no silent passes

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 0 (Baseline — run BEFORE any code changes):
└── T13: Build module and run pre-change baseline (azure-lab)

Wave 1 (Foundation — all independent, start after T13):
├── T1: Fix silent-pass bug in domain/ tests (~20 files)
├── T2: Fix silent-pass bug in gpo/ tests (~30 files)
├── T3: Fix silent-pass bug in gpostate/ tests (~50 files)
├── T4: Fix silent-pass bug in user/ tests (~30 files)
├── T5: Fix silent-pass bug in computer/, config/, dacl/, dns/ tests (~40 files)
├── T6: Fix silent-pass bug in remaining categories (~100 files)
├── T7: Create 28 missing .md files for gpostate/ tests
├── T8: Fix empty tables in 17 detail tests
└── T9: Audit and categorize 92 hardcoded-$true functions

Wave 2 (Core logic — depends on T9 categorization):
├── T10: Convert informational tests to investigate status
├── T11: Add security thresholds to threshold-eligible tests
└── T12: Update .md files with Operational/Preventive/Detective classifications

Wave 3 (Post-change validation — after all code changes):
├── T14: Run post-change tests and capture reports (azure-lab)
└── T15: Compare pre/post reports and document deltas

Wave FINAL (Verification — after ALL tasks):
├── F1: Plan compliance audit (oracle)
├── F2: Code quality review (unspecified-high)
├── F3: Real manual QA — re-run azure-lab end-to-end (unspecified-high)
└── F4: Scope fidelity check (deep)
-> Present results -> Get explicit user okay

Critical Path: T13 (baseline) → T1-T6 → T9 → T10-T11 → T14-T15 → F1-F4 → user okay
Parallel Speedup: ~60% faster than sequential
Max Concurrent: 9 (Wave 1)
```

### Dependency Matrix

| Task | Blocked By | Blocks |
|------|-----------|--------|
| T13 | None | T1-T15 (baseline must exist before comparison) |
| T1-T8 | None | T10-T12 (indirectly) |
| T9 | None | T10-T12 |
| T10 | T9 | T14 |
| T11 | T9 | T14 |
| T12 | T9 | T14 |
| T14 | T10-T12 | T15 |
| T15 | T14 | F1-F4 |
| F1-F4 | T15 | user okay |
| F1-F4 | T15 | user okay |

### Agent Dispatch Summary

- **Wave 0**: **1** task — T13 → `unspecified-high`
- **Wave 1**: **9** tasks — T1-T6 → `quick`, T7 → `writing`, T8 → `quick`, T9 → `deep`
- **Wave 2**: **3** tasks — T10-T11 → `deep`, T12 → `writing`
- **Wave 3**: **2** tasks — T14-T15 → `unspecified-high`
- **FINAL**: **4** tasks — F1 → `oracle`, F2 → `unspecified-high`, F3 → `unspecified-high`, F4 → `deep`

---

## TODOs

- [ ] 1. Fix silent-pass bug in domain/ test wrappers

  **What to do**:
  - Find all `.Tests.ps1` files in `tests/ad/domain/`
  - Locate the pattern: `if ($null -ne $result) { $result | Should -Be $true -Because "..." }`
  - Add an `else` block: `Set-ItResult -Skipped -Because "Active Directory data could not be retrieved"`
  - Ensure the `It` block description still makes sense after changes

  **Must NOT do**:
  - Do NOT change the test logic or assertions inside the `if` block
  - Do NOT modify the corresponding `.ps1` functions in `powershell/public/ad/`
  - Do NOT change non-AD test wrappers

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Pattern replacement across multiple files with consistent structure
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with T2-T9)
  - **Blocks**: None
  - **Blocked By**: None

  **References**:
  - **Pattern to follow**: `tests/ad/domain/Test-MtAdDomainNameStandardCompliance.Tests.ps1` — wrapper pattern
  - **Fix pattern**: Add `else { Set-ItResult -Skipped -Because "Active Directory data could not be retrieved" }` after the `if ($null -ne $result)` block
  - **Pester docs**: `Set-ItResult` is the standard Pester way to mark a test as skipped

  **Acceptance Criteria**:
  - [ ] All `.Tests.ps1` files in `tests/ad/domain/` have the `else` block added
  - [ ] `grep -r "if (\$null -ne \$result)" tests/ad/domain/ | wc -l` shows zero occurrences without matching `else`

  **QA Scenarios**:

  ```
  Scenario: Verify no silent-pass pattern remains in domain tests
    Tool: Bash (grep)
    Preconditions: T1 changes applied
    Steps:
      1. Run: grep -r "if (\$null -ne \$result)" tests/ad/domain/*.Tests.ps1
      2. For each match, verify the next non-empty line contains "else" or "Set-ItResult"
    Expected Result: Zero files with `if ($null -ne $result)` lacking an `else` block
    Failure Indicators: Any file where `if ($null -ne $result)` is not followed by `else`
    Evidence: .sisyphus/evidence/task-1-domain-silent-pass-fix.txt
  ```

  **Evidence to Capture**:
  - [ ] Screenshot or text file showing grep results before and after fix

  **Commit**: YES
  - Message: `fix(ad-tests): silent-pass bug in domain test wrappers`
  - Files: `tests/ad/domain/*.Tests.ps1`

- [ ] 2. Fix silent-pass bug in gpo/ test wrappers

  **What to do**:
  - Find all `.Tests.ps1` files in `tests/ad/gpo/`
  - Apply the same fix as T1: add `else { Set-ItResult -Skipped -Because "Active Directory data could not be retrieved" }`

  **Must NOT do**:
  - Do NOT change test logic inside `if` blocks
  - Do NOT modify `powershell/public/ad/gpo/*.ps1` functions

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with T1, T3-T9)
  - **Blocks**: None
  - **Blocked By**: None

  **References**:
  - Same pattern as T1, applied to `tests/ad/gpo/`

  **Acceptance Criteria**:
  - [ ] All `.Tests.ps1` files in `tests/ad/gpo/` have the `else` block
  - [ ] grep shows zero silent-pass patterns

  **QA Scenarios**:

  ```
  Scenario: Verify no silent-pass pattern remains in gpo tests
    Tool: Bash (grep)
    Preconditions: T2 changes applied
    Steps:
      1. Run: grep -r "if (\$null -ne \$result)" tests/ad/gpo/*.Tests.ps1
      2. Verify every match has a corresponding else block
    Expected Result: Zero silent-pass patterns
    Evidence: .sisyphus/evidence/task-2-gpo-silent-pass-fix.txt
  ```

  **Commit**: YES
  - Message: `fix(ad-tests): silent-pass bug in gpo test wrappers`
  - Files: `tests/ad/gpo/*.Tests.ps1`

- [ ] 3. Fix silent-pass bug in gpostate/ test wrappers

  **What to do**:
  - Find all `.Tests.ps1` files in `tests/ad/gpostate/`
  - Apply the same fix as T1: add `else { Set-ItResult -Skipped -Because "Active Directory data could not be retrieved" }`

  **Must NOT do**:
  - Do NOT change test logic inside `if` blocks
  - Do NOT modify `powershell/public/ad/gpostate/*.ps1` functions

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with T1-T2, T4-T9)
  - **Blocks**: None
  - **Blocked By**: None

  **References**:
  - Same pattern as T1, applied to `tests/ad/gpostate/`

  **Acceptance Criteria**:
  - [ ] All `.Tests.ps1` files in `tests/ad/gpostate/` have the `else` block

  **QA Scenarios**:

  ```
  Scenario: Verify no silent-pass pattern remains in gpostate tests
    Tool: Bash (grep)
    Preconditions: T3 changes applied
    Steps:
      1. Run: grep -r "if (\$null -ne \$result)" tests/ad/gpostate/*.Tests.ps1
      2. Verify every match has a corresponding else block
    Expected Result: Zero silent-pass patterns
    Evidence: .sisyphus/evidence/task-3-gpostate-silent-pass-fix.txt
  ```

  **Commit**: YES
  - Message: `fix(ad-tests): silent-pass bug in gpostate test wrappers`
  - Files: `tests/ad/gpostate/*.Tests.ps1`

- [ ] 4. Fix silent-pass bug in user/ test wrappers

  **What to do**:
  - Find all `.Tests.ps1` files in `tests/ad/user/`
  - Apply the same fix as T1: add `else { Set-ItResult -Skipped -Because "Active Directory data could not be retrieved" }`

  **Must NOT do**:
  - Do NOT change test logic inside `if` blocks
  - Do NOT modify `powershell/public/ad/user/*.ps1` functions

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with T1-T3, T5-T9)
  - **Blocks**: None
  - **Blocked By**: None

  **Acceptance Criteria**:
  - [ ] All `.Tests.ps1` files in `tests/ad/user/` have the `else` block

  **QA Scenarios**:

  ```
  Scenario: Verify no silent-pass pattern remains in user tests
    Tool: Bash (grep)
    Preconditions: T4 changes applied
    Steps:
      1. Run: grep -r "if (\$null -ne \$result)" tests/ad/user/*.Tests.ps1
      2. Verify every match has a corresponding else block
    Expected Result: Zero silent-pass patterns
    Evidence: .sisyphus/evidence/task-4-user-silent-pass-fix.txt
  ```

  **Commit**: YES
  - Message: `fix(ad-tests): silent-pass bug in user test wrappers`
  - Files: `tests/ad/user/*.Tests.ps1`

- [ ] 5. Fix silent-pass bug in computer/, config/, dacl/, dns/ test wrappers

  **What to do**:
  - Find all `.Tests.ps1` files in `tests/ad/computer/`, `tests/ad/config/`, `tests/ad/dacl/`, `tests/ad/dns/`
  - Apply the same fix as T1: add `else { Set-ItResult -Skipped -Because "Active Directory data could not be retrieved" }`

  **Must NOT do**:
  - Do NOT change test logic inside `if` blocks
  - Do NOT modify corresponding `.ps1` functions

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with T1-T4, T6-T9)
  - **Blocks**: None
  - **Blocked By**: None

  **Acceptance Criteria**:
  - [ ] All `.Tests.ps1` files in the four directories have the `else` block

  **QA Scenarios**:

  ```
  Scenario: Verify no silent-pass pattern remains in computer/config/dacl/dns tests
    Tool: Bash (grep)
    Preconditions: T5 changes applied
    Steps:
      1. Run: grep -r "if (\$null -ne \$result)" tests/ad/{computer,config,dacl,dns}/*.Tests.ps1
      2. Verify every match has a corresponding else block
    Expected Result: Zero silent-pass patterns
    Evidence: .sisyphus/evidence/task-5-computer-config-dacl-dns-silent-pass-fix.txt
  ```

  **Commit**: YES
  - Message: `fix(ad-tests): silent-pass bug in computer/config/dacl/dns test wrappers`
  - Files: `tests/ad/{computer,config,dacl,dns}/*.Tests.ps1`

- [ ] 6. Fix silent-pass bug in remaining AD category test wrappers

  **What to do**:
  - Find all `.Tests.ps1` files in remaining `tests/ad/` subdirectories:
    `domaincontroller/`, `group/`, `ou/`, `passwordpolicy/`, `printer/`, `replication/`, `schema/`, `security/`, `site/`, `spn/`, `trust/`
  - Apply the same fix as T1: add `else { Set-ItResult -Skipped -Because "Active Directory data could not be retrieved" }`

  **Must NOT do**:
  - Do NOT change test logic inside `if` blocks
  - Do NOT modify corresponding `.ps1` functions

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with T1-T5, T7-T9)
  - **Blocks**: None
  - **Blocked By**: None

  **Acceptance Criteria**:
  - [ ] All `.Tests.ps1` files in remaining directories have the `else` block
  - [ ] Global check: `grep -r "if (\$null -ne \$result)" tests/ad/ | grep -v "else" | wc -l` returns 0

  **QA Scenarios**:

  ```
  Scenario: Global verification — zero silent-pass patterns across all AD tests
    Tool: Bash (grep)
    Preconditions: T1-T6 all applied
    Steps:
      1. Run: grep -r "if (\$null -ne \$result)" tests/ad/ | grep -v "else"
      2. Count results
    Expected Result: Zero lines returned (all if blocks have else)
    Evidence: .sisyphus/evidence/task-6-remaining-silent-pass-fix.txt
  ```

  **Commit**: YES
  - Message: `fix(ad-tests): silent-pass bug in remaining AD category test wrappers`
  - Files: `tests/ad/{domaincontroller,group,ou,passwordpolicy,printer,replication,schema,security,site,spn,trust}/*.Tests.ps1`

- [ ] 7. Create 28 missing companion .md files for gpostate/ tests

  **What to do**:
  - For each of the 28 `.ps1` files in `powershell/public/ad/gpostate/` that lacks a `.md` companion, create one
  - Follow the established pattern from existing AD `.md` files:
    ```markdown
    #### Test-MtAdXxx

    #### Why This Test Matters
    [Explanation of security relevance]

    #### Security Recommendation
    [Remediation guidance]

    #### How the Test Works
    [Technical details]

    #### Related Tests
    - `Test-MtAdYyy` - Description
    ```
  - For tests that are purely informational (count/enumerate without threshold), identify as **Operational control**
  - For tests that check security configurations, identify as **Detective control**
  - Read the corresponding `.ps1` file to understand what the test does and write accurate documentation

  **Must NOT do**:
  - Do NOT copy-paste identical content across all 28 files
  - Do NOT invent security relevance where none exists — be honest about informational tests
  - Do NOT modify existing `.md` files (that is T12)

  **Recommended Agent Profile**:
  - **Category**: `writing`
    - Reason: Documentation creation requiring accurate technical content
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with T1-T6, T8-T9)
  - **Blocks**: T12 (updates to .md files)
  - **Blocked By**: None

  **References**:
  - **Pattern to follow**: `powershell/public/ad/domain/Test-MtAdDomainNameStandardCompliance.md` — existing companion .md
  - **Source functions**: `powershell/public/ad/gpostate/*.ps1` — read each to understand test purpose
  - **Missing files list**: See AD_TESTS_ANALYSIS.md Section 3 for the 28 missing files

  **Acceptance Criteria**:
  - [ ] 28 new `.md` files created in `powershell/public/ad/gpostate/`
  - [ ] Each file follows the established 4-section pattern
  - [ ] Each file accurately describes the test's purpose based on its `.ps1` implementation
  - [ ] `ls powershell/public/ad/gpostate/*.md | wc -l` equals number of `.ps1` files in same directory

  **QA Scenarios**:

  ```
  Scenario: Verify all gpostate functions have companion .md files
    Tool: Bash (ls + diff)
    Preconditions: T7 changes applied
    Steps:
      1. List all .ps1 files: ls powershell/public/ad/gpostate/*.ps1 | xargs -n1 basename | sed 's/.ps1//'
      2. List all .md files: ls powershell/public/ad/gpostate/*.md | xargs -n1 basename | sed 's/.md//'
      3. Compare — every .ps1 should have a matching .md
    Expected Result: Zero missing .md files
    Evidence: .sisyphus/evidence/task-7-gpostate-md-files.txt
  ```

  **Evidence to Capture**:
  - [ ] List of created files with descriptions

  **Commit**: YES
  - Message: `docs(ad-tests): add missing gpostate companion markdown files`
  - Files: `powershell/public/ad/gpostate/*.md`

- [ ] 8. Fix empty markdown tables in 17 detail tests

  **What to do**:
  - For each of the 17 detail tests listed in AD_TESTS_ANALYSIS.md Section 4:
    - Locate the table generation code in the `.ps1` function
    - Wrap table generation in a conditional: only generate the table when there are findings
    - When findings count is 0, omit the table entirely (show summary message only)
    - Example fix pattern:
      ```powershell
      if ($findingsCount -gt 0) {
          $testResultMarkdown = "$recommendation`n`n%TestResult%"
          $testResultMarkdown = $testResultMarkdown -replace '%TestResult%', $table
      } else {
          $testResultMarkdown = $recommendation
      }
      ```
  - Also limit table sizes to 25 rows with "... and N more" for all detail tables

  **Must NOT do**:
  - Do NOT remove the table generation logic entirely — just make it conditional
  - Do NOT change the test result boolean logic
  - Do NOT modify non-detail tests (tests without tables)

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Pattern-based fix across known files
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with T1-T7, T9)
  - **Blocks**: None
  - **Blocked By**: None

  **References**:
  - **Files to fix**: See AD_TESTS_ANALYSIS.md Section 4 for the 17 file list
  - **Example fix**: `powershell/public/ad/gpostate/Test-MtAdGpoNoAuthenticatedUsersDetails.ps1` — wrap table in `if ($noAuthenticatedUsersCount -gt 0)`

  **Acceptance Criteria**:
  - [ ] All 17 files generate tables conditionally (only when findings > 0)
  - [ ] All detail tables limited to 25 rows max
  - [ ] Test result boolean logic unchanged

  **QA Scenarios**:

  ```
  Scenario: Verify empty tables are suppressed in detail tests
    Tool: Bash (grep)
    Preconditions: T8 changes applied
    Steps:
      1. For each of the 17 files, verify table generation is inside an if block
      2. Verify the if condition checks findings/count > 0
    Expected Result: All 17 files have conditional table generation
    Evidence: .sisyphus/evidence/task-8-empty-tables-fix.txt
  ```

  **Commit**: YES
  - Message: `fix(ad-tests): suppress empty markdown tables and limit table sizes`
  - Files: `powershell/public/ad/{gpostate,gpo,dacl}/*Details.ps1`

- [ ] 9. Audit and categorize 92 hardcoded-$true functions

  **What to do**:
  - Find all functions in `powershell/public/ad/**/*.ps1` that hardcode `$testResult = $true`
  - For each function, determine:
    1. **What does it actually test?** (read the function body)
    2. **Can a security threshold be defined?**
       - YES → Mark as **Threshold candidate** (Preventive/Detective)
       - NO → Mark as **Investigate candidate** (Operational)
    3. **What is the recommended classification?**
  - Produce an audit document: `.sisyphus/drafts/ad-test-audit.md` with a table:
    | Function | File | Current Logic | Can Threshold? | Recommended | Control Type |
  - Examples of threshold candidates:
    - `Test-MtAdPasswordMinLength` → fail if < 14
    - `Test-MtAdPasswordMaxAge` → fail if > 90 days or = 0
    - `Test-MtAdRecycleBinStatus` → fail if disabled
    - `Test-MtAdDomainFunctionalLevel` → fail if < Windows Server 2016
  - Examples of investigate candidates:
    - `Test-MtAdOptionalFeatureCount` → just counts features
    - `Test-MtAdSiteTotalCount` → just counts sites
    - `Test-MtAdTrustTotalCount` → just counts trusts

  **Must NOT do**:
  - Do NOT modify any `.ps1` files in this task — this is audit-only
  - Do NOT make assumptions about thresholds without security justification

  **Recommended Agent Profile**:
  - **Category**: `deep`
    - Reason: Requires reading and understanding 92 functions, making security judgments
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with T1-T8)
  - **Blocks**: T10-T12 (all depend on this audit)
  - **Blocked By**: None

  **References**:
  - **Source files**: `powershell/public/ad/**/*.ps1` — search for `$testResult = $true`
  - **Good example**: `powershell/public/ad/domain/Test-MtAdDomainNameStandardCompliance.ps1` — real threshold logic
  - **Investigate usage**: `report/src/lib/testStatus.ts` — Investigate is a first-class status
  - **Add-MtTestResultDetail**: `powershell/public/Add-MtTestResultDetail.ps1` — supports `-Investigate` flag

  **Acceptance Criteria**:
  - [ ] Audit document created at `.sisyphus/drafts/ad-test-audit.md`
  - [ ] All 92 functions categorized as Threshold or Investigate
  - [ ] Each categorization has a 1-sentence security justification
  - [ ] At least 10 functions identified as Threshold candidates
  - [ ] At least 50 functions identified as Investigate candidates

  **QA Scenarios**:

  ```
  Scenario: Verify audit document completeness
    Tool: Bash (wc + grep)
    Preconditions: T9 completed
    Steps:
      1. Count lines in .sisyphus/drafts/ad-test-audit.md
      2. Verify document contains "Threshold candidate" and "Investigate candidate"
      3. Count table rows — should be ~92
    Expected Result: Document exists, has ~92 rows, both categories present
    Evidence: .sisyphus/evidence/task-9-audit-document.txt
  ```

  **Commit**: YES
  - Message: `docs(ad-tests): audit and categorize hardcoded-$true functions`
  - Files: `.sisyphus/drafts/ad-test-audit.md`

- [ ] 10. Convert informational tests to investigate status

  **What to do**:
  - Using the audit document from T9, find all functions marked as **Investigate candidate**
  - For each function:
    1. Keep the function returning `$true` (so the wrapper's `Should -Be $true` passes)
    2. Add `Add-MtTestResultDetail -Result $testResultMarkdown -Investigate` to mark the test as Investigate
    3. The wrapper's `else { Set-ItResult -Skipped }` from T1-T6 only triggers when the function returns `$null` (AD not connected) — this is correct and should remain
    4. Update the companion `.md` file to identify the test as an **Operational control**
  - The test will show as **Investigate** (purple badge) in the report, not Passed or Failed
  - Example pattern:
    ```powershell
    # In the function
    Add-MtTestResultDetail -Result $testResultMarkdown -Investigate
    return $true  # wrapper's Should -Be $true passes, but Investigate flag overrides status
    ```
  - Update the test wrapper It block description from "should be retrievable" to "should be investigated" or similar

  **Must NOT do**:
  - Do NOT change functions marked as Threshold candidates
  - Do NOT remove data collection logic — only change the result classification
  - Do NOT change non-AD tests

  **Recommended Agent Profile**:
  - **Category**: `deep`
    - Reason: Requires understanding each function, modifying result logic, updating wrappers and docs
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES (with T11-T12)
  - **Parallel Group**: Wave 2
  - **Blocks**: T14 (post-change run)
  - **Blocked By**: T9 (audit document)

  **References**:
  - **Audit document**: `.sisyphus/drafts/ad-test-audit.md` — lists all Investigate candidates
  - **Investigate flag**: `powershell/public/Add-MtTestResultDetail.ps1` — `-Investigate` parameter
  - **Status UI**: `report/src/lib/testStatus.ts` — Investigate is sort order 4
  - **Example wrapper pattern**: `tests/ad/domain/Test-MtAdDomainNameStandardCompliance.Tests.ps1`

  **Acceptance Criteria**:
  - [ ] All Investigate-candidate functions from T9 updated
  - [ ] Functions call `Add-MtTestResultDetail -Investigate`
  - [ ] Test wrappers updated to reflect investigate classification
  - [ ] Companion .md files updated to identify as Operational control

  **QA Scenarios**:

  ```
  Scenario: Verify investigate functions emit correct status
    Tool: Bash (pwsh)
    Preconditions: T10 changes applied
    Steps:
      1. Import Maester module
      2. Mock AD connection to return sample data
      3. Call an investigate-classified function
      4. Verify Add-MtTestResultDetail was called with -Investigate
    Expected Result: Function returns investigate signal, not $true
    Evidence: .sisyphus/evidence/task-10-investigate-status.ps1
  ```

  **Commit**: YES
  - Message: `refactor(ad-tests): reclassify informational tests as investigate`
  - Files: `powershell/public/ad/**/*.ps1`, `tests/ad/**/*.Tests.ps1`, `powershell/public/ad/**/*.md`

- [ ] 11. Add security thresholds to threshold-eligible tests

  **What to do**:
  - Using the audit document from T9, find all functions marked as **Threshold candidate**
  - For each function, replace the hardcoded `$testResult = $true` with actual security logic:
    - `Test-MtAdPasswordMinLength` → `$testResult = $minLength -ge 14`
    - `Test-MtAdPasswordMaxAge` → `$testResult = $maxAge -le 90 -and $maxAge -ne 0`
    - `Test-MtAdPasswordReversibleEncryption` → `$testResult = -not $reversibleEncryptionEnabled`
    - `Test-MtAdRecycleBinStatus` → `$testResult = $recycleBinEnabled`
    - `Test-MtAdDomainFunctionalLevel` → `$testResult = $functionalLevel -ge 'Windows2016'`
    - `Test-MtAdTombstoneLifetimeConfig` → `$testResult = $tombstoneLifetime -ge 180`
  - Update the test wrapper It block description from "should be retrievable" to a meaningful security assertion (e.g., "should have minimum password length of at least 14")
  - Update the companion `.md` file to identify as **Preventive** or **Detective control**
  - Ensure the function still calls `Add-MtTestResultDetail` with the result markdown

  **Must NOT do**:
  - Do NOT change functions marked as Investigate candidates
  - Do NOT invent arbitrary thresholds — use industry-standard baselines (CIS, Microsoft recommendations)
  - Do NOT change the data retrieval logic — only the assertion logic

  **Recommended Agent Profile**:
  - **Category**: `deep`
    - Reason: Security threshold decisions require domain expertise
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES (with T10, T12)
  - **Parallel Group**: Wave 2
  - **Blocks**: T14 (post-change run)
  - **Blocked By**: T9 (audit document)

  **References**:
  - **Audit document**: `.sisyphus/drafts/ad-test-audit.md` — lists all Threshold candidates
  - **Good example**: `powershell/public/ad/domain/Test-MtAdDomainNameStandardCompliance.ps1` — real boolean from data
  - **CIS benchmarks**: Use CIS Active Directory benchmarks for threshold values where applicable
  - **Microsoft recommendations**: Use Microsoft security baseline recommendations

  **Acceptance Criteria**:
  - [ ] All Threshold-candidate functions from T9 updated with real security logic
  - [ ] No function hardcodes `$testResult = $true` (unless intentionally investigate)
  - [ ] Test wrapper descriptions updated to reflect security assertions
  - [ ] Companion .md files updated to identify as Preventive/Detective control

  **QA Scenarios**:

  ```
  Scenario: Verify threshold functions fail when misconfigured
    Tool: Bash (pwsh)
    Preconditions: T11 changes applied
    Steps:
      1. Import Maester module
      2. Mock AD data with misconfigured values (e.g., password min length = 8)
      3. Call Test-MtAdPasswordMinLength
      4. Verify function returns $false
    Expected Result: Function returns $false for non-compliant configuration
    Evidence: .sisyphus/evidence/task-11-threshold-fail.ps1

  Scenario: Verify threshold functions pass when compliant
    Tool: Bash (pwsh)
    Preconditions: T11 changes applied
    Steps:
      1. Import Maester module
      2. Mock AD data with compliant values (e.g., password min length = 16)
      3. Call Test-MtAdPasswordMinLength
      4. Verify function returns $true
    Expected Result: Function returns $true for compliant configuration
    Evidence: .sisyphus/evidence/task-11-threshold-pass.ps1
  ```

  **Commit**: YES
  - Message: `feat(ad-tests): add security thresholds to eligible tests`
  - Files: `powershell/public/ad/**/*.ps1`, `tests/ad/**/*.Tests.ps1`, `powershell/public/ad/**/*.md`

- [ ] 12. Update .md files with Operational/Preventive/Detective control classifications

  **What to do**:
  - For ALL AD companion `.md` files in `powershell/public/ad/**/*.md`:
    - Add a **Control Type** section identifying the test as:
      - **Operational** — for investigate/informational tests
      - **Preventive** — for tests that enforce a security configuration
      - **Detective** — for tests that detect a security misconfiguration
    - Update the "Why This Test Matters" section to reflect the actual purpose
    - Update the "Security Recommendation" section with actionable guidance
  - Ensure consistency across all 241+ existing .md files plus the 28 new ones from T7

  **Must NOT do**:
  - Do NOT change non-AD .md files
  - Do NOT remove existing sections — only add/update

  **Recommended Agent Profile**:
  - **Category**: `writing`
    - Reason: Documentation updates across many files
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES (with T10-T11)
  - **Parallel Group**: Wave 2
  - **Blocks**: T14 (post-change run)
  - **Blocked By**: T9 (audit document), T7 (new .md files)

  **References**:
  - **Existing pattern**: `powershell/public/ad/domain/Test-MtAdDomainNameStandardCompliance.md`
  - **Control types**: NIST SP 800-53 control families (Operational, Preventive, Detective)

  **Acceptance Criteria**:
  - [ ] All AD `.md` files have a Control Type designation
  - [ ] All classifications are consistent with T9/T10/T11 decisions

  **QA Scenarios**:

  ```
  Scenario: Verify all .md files have Control Type section
    Tool: Bash (grep)
    Preconditions: T12 changes applied
    Steps:
      1. Run: grep -r "#### Control Type" powershell/public/ad/**/*.md | wc -l
      2. Count total .md files in powershell/public/ad/
    Expected Result: Counts match (every .md has Control Type)
    Evidence: .sisyphus/evidence/task-12-control-type-classification.txt
  ```

  **Commit**: YES
  - Message: `docs(ad-tests): update control classifications in markdown files`
  - Files: `powershell/public/ad/**/*.md`

- [ ] 13. Build module and run pre-change baseline (azure-lab)

  **What to do**:
  - **IMPORTANT**: Run this task BEFORE applying any code changes from T1-T12. This captures the baseline.
  - Build the local Maester module from the current (unmodified) source: `./build/Build-LocalMaester.ps1 -BuildReport`
  - Validate build: `./build/Test-MaesterModuleOutput.ps1`
  - Run AD tests via azure-lab:
    ```powershell
    # Connect to AD
    Connect-Maester -Service ActiveDirectory -ActiveDirectoryServer "<DC>" `
      -ActiveDirectoryCredential (Get-Credential) `
      -ActiveDirectoryAuthMode Negotiate -ActiveDirectoryTlsMode Auto
    
    # Run AD tests
    Invoke-Maester -Path "./tests/ad" -Tag "AD" `
      -OutputFolder "./test-results" `
      -OutputHtmlFile "AD-TestResults-pre-change.html" `
      -OutputJsonFile "AD-TestResults-pre-change.json" `
      -NonInteractive
    ```
  - Or use the dedicated runner: `build/activeDirectory/Run-ADTests-And-CopyReports.ps1`
  - Copy the generated reports to `.sisyphus/evidence/baseline/` for archiving
  - Record status counts from the JSON report:
    - Total tests, Passed, Failed, Investigate, Skipped, Error

  **Must NOT do**:
  - Do NOT run this after applying T1-T12 changes — this is the BASELINE (pre-change)
  - Do NOT skip this step — the comparison depends on it

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: Requires running full test suite against live AD environment
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: NO — must run FIRST (before any code changes)
  - **Parallel Group**: Wave 0
  - **Blocks**: T1-T15 (baseline must be captured before comparison)
  - **Blocked By**: None

  **References**:
  - **Build script**: `./build/Build-LocalMaester.ps1`
  - **AD runner**: `build/activeDirectory/Run-ADTests-And-CopyReports.ps1`
  - **Invoke-Maester**: `powershell/public/Invoke-Maester.ps1`
  - **Prerequisites**: `build/activeDirectory/azure-lab/Test-ADProtocolPrerequisites.ps1`

  **Acceptance Criteria**:
  - [ ] Module builds successfully
  - [ ] HTML and JSON reports generated
  - [ ] Reports copied to `.sisyphus/evidence/baseline/`
  - [ ] Status counts recorded in `.sisyphus/evidence/baseline/status-counts.json`

  **QA Scenarios**:

  ```
  Scenario: Verify baseline reports exist and are valid
    Tool: Bash (ls + file)
    Preconditions: T13 completed
    Steps:
      1. List .sisyphus/evidence/baseline/
      2. Verify HTML and JSON files exist
      3. Verify JSON file is valid JSON (jq empty)
    Expected Result: Both files exist, JSON is valid
    Evidence: .sisyphus/evidence/task-13-baseline-reports.txt
  ```

  **Commit**: NO (baseline is evidence, not code)

- [ ] 14. Run post-change tests and capture reports (azure-lab)

  **What to do**:
  - Build the module WITH all changes from T1-T12: `./build/Build-LocalMaester.ps1 -BuildReport`
  - Validate build: `./build/Test-MaesterModuleOutput.ps1`
  - Run AD tests via azure-lab using the same configuration as T13
  - Generate post-change reports:
    - `AD-TestResults-post-change.html`
    - `AD-TestResults-post-change.json`
  - Copy reports to `.sisyphus/evidence/post-change/`
  - Record status counts from JSON report

  **Must NOT do**:
  - Do NOT change AD environment configuration between T13 and T14
  - Do NOT use different Invoke-Maester parameters than T13

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: NO — must run after T10-T12 (all code changes)
  - **Parallel Group**: Wave 3
  - **Blocks**: T15 (comparison)
  - **Blocked By**: T10-T12 (all code changes must be applied first)

  **References**:
  - Same as T13

  **Acceptance Criteria**:
  - [ ] Module builds successfully with all changes
  - [ ] HTML and JSON reports generated
  - [ ] Reports copied to `.sisyphus/evidence/post-change/`
  - [ ] Status counts recorded

  **QA Scenarios**:

  ```
  Scenario: Verify post-change reports exist and are valid
    Tool: Bash (ls + file)
    Preconditions: T14 completed
    Steps:
      1. List .sisyphus/evidence/post-change/
      2. Verify HTML and JSON files exist
      3. Verify JSON is valid
    Expected Result: Both files exist, JSON is valid
    Evidence: .sisyphus/evidence/task-14-post-change-reports.txt
  ```

  **Commit**: NO

- [ ] 15. Compare pre/post reports and document deltas

  **What to do**:
  - Parse both JSON reports (baseline and post-change)
  - Compare status counts:
    - Expected changes:
      - Passed count may decrease (some "retrievable" tests now show as Investigate or Skipped)
      - Investigate count should increase (informational tests reclassified)
      - Failed count may increase (threshold tests now fail when misconfigured)
      - Skipped count may increase (silent-pass bug fixed, AD disconnections properly skipped)
    - Unexpected changes to flag:
      - New errors
      - Tests that disappeared
      - Status changes that don't align with T10-T11 modifications
  - Generate a comparison report: `.sisyphus/evidence/report-comparison.md`
    - Table: Status | Baseline Count | Post-Change Count | Delta | Expected?
    - List of tests that changed status with explanation
    - Any unexpected changes flagged for investigation
  - Verify NO tests silently pass when AD is disconnected:
    - Temporarily disconnect AD (or mock disconnect)
    - Run a subset of AD tests
    - Verify all show as Skipped (not Passed)

  **Must NOT do**:
  - Do NOT ignore unexpected changes — flag them for review
  - Do NOT manually edit the JSON reports

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: Requires parsing JSON, comparing data, making judgments
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: NO — must run after T14
  - **Parallel Group**: Wave 3
  - **Blocks**: F1-F4 (final verification)
  - **Blocked By**: T14 (post-change reports)

  **References**:
  - **Baseline reports**: `.sisyphus/evidence/baseline/`
  - **Post-change reports**: `.sisyphus/evidence/post-change/`
  - **JSON structure**: Parse `AD-TestResults-*.json` — array of test results with `Result` field

  **Acceptance Criteria**:
  - [ ] Comparison report generated at `.sisyphus/evidence/report-comparison.md`
  - [ ] All expected deltas documented and explained
  - [ ] Zero unexpected changes OR unexpected changes flagged with investigation notes
  - [ ] Silent-pass verification confirms zero silent passes when AD disconnected

  **QA Scenarios**:

  ```
  Scenario: Verify report comparison shows expected deltas
    Tool: Bash (pwsh + jq)
    Preconditions: T15 completed
    Steps:
      1. Parse baseline JSON: jq '[.[] | .Result] | group_by(.) | map({status: .[0], count: length})' baseline.json
      2. Parse post-change JSON: same command
      3. Compare counts — Investigate should increase, Passed may decrease
    Expected Result: Deltas match expected changes from T10-T11
    Evidence: .sisyphus/evidence/task-15-report-comparison.md

  Scenario: Verify no silent passes when AD disconnected
    Tool: Bash (pwsh)
    Preconditions: T1-T6 applied
    Steps:
      1. Disconnect AD (or use invalid server)
      2. Run a sample of AD tests: Invoke-Maester -Path ./tests/ad/domain -Tag AD
      3. Parse results — verify no "Passed" results when AD is unreachable
    Expected Result: All tests show Skipped, zero Passed
    Evidence: .sisyphus/evidence/task-15-no-silent-pass-verify.txt
  ```

  **Commit**: NO (evidence only)

---

## Final Verification Wave

> 4 review agents run in PARALLEL. ALL must APPROVE. Present consolidated results to user and get explicit "okay" before completing.

- [ ] F1. **Plan Compliance Audit** — `oracle`
  Read the plan end-to-end. For each "Must Have": verify implementation exists (read file, run command). For each "Must NOT Have": search codebase for forbidden patterns — reject with file:line if found. Check evidence files exist in `.sisyphus/evidence/`. Compare deliverables against plan.
  Output: `Must Have [N/N] | Must NOT Have [N/N] | Tasks [N/N] | VERDICT: APPROVE/REJECT`

- [ ] F2. **Code Quality Review** — `unspecified-high`
  Run `./powershell/tests/pester.ps1` on modified files. Review all changed files for: hardcoded credentials, empty catches, Write-Host in prod, commented-out code, unused imports. Check AI slop: excessive comments, over-abstraction, generic names.
  Output: `Build [PASS/FAIL] | Tests [N pass/N fail] | Files [N clean/N issues] | VERDICT`

- [ ] F3. **Real Manual QA — Azure-Lab End-to-End** — `unspecified-high`
  Start from clean state. Run full AD test suite via `build/activeDirectory/Run-ADTests-And-CopyReports.ps1`. Execute EVERY QA scenario from EVERY task — follow exact steps, capture evidence. Test edge cases: AD disconnected, empty results, rapid re-runs. Save to `.sisyphus/evidence/final-qa/`.
  Output: `Scenarios [N/N pass] | Integration [N/N] | Edge Cases [N tested] | VERDICT`

- [ ] F4. **Scope Fidelity Check** — `deep`
  For each task: read "What to do", read actual diff (`git diff`). Verify 1:1 — everything in spec was built (no missing), nothing beyond spec was built (no creep). Check "Must NOT do" compliance. Detect cross-task contamination. Flag unaccounted changes.
  Output: `Tasks [N/N compliant] | Contamination [CLEAN/N issues] | Unaccounted [CLEAN/N files] | VERDICT`

---

## Commit Strategy

- **Wave 0** (baseline — no code commits, evidence only):
  - Baseline reports archived to `.sisyphus/evidence/baseline/`
- **Wave 1 commits** (grouped by category):
  - `fix(ad-tests): silent-pass bug in domain tests` — T1 files
  - `fix(ad-tests): silent-pass bug in gpo tests` — T2 files
  - `fix(ad-tests): silent-pass bug in gpostate tests` — T3 files
  - `fix(ad-tests): silent-pass bug in user tests` — T4 files
  - `fix(ad-tests): silent-pass bug in computer/config/dacl/dns tests` — T5 files
  - `fix(ad-tests): silent-pass bug in remaining AD categories` — T6 files
  - `docs(ad-tests): add missing gpostate companion markdown files` — T7 files
  - `fix(ad-tests): suppress empty markdown tables on pass` — T8 files
  - `refactor(ad-tests): audit and categorize hardcoded-$true functions` — T9 (audit doc)
- **Wave 2 commits**:
  - `refactor(ad-tests): reclassify informational tests as investigate` — T10 files
  - `feat(ad-tests): add security thresholds to eligible tests` — T11 files
  - `docs(ad-tests): update control classifications in markdown files` — T12 files
- **Wave 3 commits** (evidence only):
  - Post-change reports archived to `.sisyphus/evidence/post-change/`
  - Comparison report archived to `.sisyphus/evidence/report-comparison.md`

---

## Success Criteria

### Verification Commands
```powershell
# Build and validate module
./build/Build-LocalMaester.ps1
./build/Test-MaesterModuleOutput.ps1

# Run unit tests on modified functions
./powershell/tests/pester.ps1

# Run AD tests via azure-lab (pre/post comparison)
build/activeDirectory/Run-ADTests-And-CopyReports.ps1

# Verify no silent passes — check that Skipped count is explicit
# (not hidden as Passed)
```

### Final Checklist
- [ ] All 270 test wrappers have explicit else block (no silent passes)
- [ ] All 92 hardcoded-$true functions categorized and updated
- [ ] All 28 missing .md files created with consistent template
- [ ] All 17 empty-table tests fixed
- [ ] Pre-change baseline report captured and archived
- [ ] Post-change report captured and compared
- [ ] Report comparison shows expected deltas (no unexpected regressions)
- [ ] `./powershell/tests/pester.ps1` passes for modified files
- [ ] No changes to non-AD test trees
- [ ] No breaking changes to Add-MtTestResultDetail or Get-MtHtmlReport APIs
