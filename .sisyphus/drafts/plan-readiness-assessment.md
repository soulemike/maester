# Assessment: Open Plans Readiness for Execution

## Plans Inventory

| File | Lines | Scope | Relationship |
|------|-------|-------|-------------|
| `ad-integration-protocol-targeting.md` | ~780 | Tasks 1–20 + F1–F4 | **Master plan** — canonical, fully detailed |
| `01-ad-protocol-foundation.md` | ~113 | Tasks 1–5 | **Reference view** of master plan Waves 1–3 |
| `02-ldap-collectors-and-analysis.md` | ~93 | Tasks 6–8, 14 | **Reference view** of master plan Waves 3–4, 6 |
| `03-cross-platform-transport.md` | ~109 | Tasks 9–13 | **Reference view** of master plan Waves 4–5 |
| `04-integration-docs-and-e2e.md` | ~132 | Tasks 16–20 | **Reference view** of master plan Waves 6–10 |
| `05-tier-model-alignment.md` | ~340 | Tasks 21–26 | **Independent plan** — Tier Model checks, depends on Plans 1–4 |

## User Decisions Applied

1. **Branch resolution**: Start fresh on `ad-multiforest-targeting` branch. Discard current `main` modifications and rejected experiment files; begin from clean `main` baseline.
2. **Plan hierarchy**: Execute from the master plan only. Segmented plans 01–04 are marked as reference views. Plan 5 is a separate dependent workstream.
3. **Execution policy**: Sequential plan execution per session. User explicitly requests which plan to work on for each `/start-work`.

## Actions Taken

- [x] Master plan updated with Pre-Flight section (plan hierarchy, execution policy, branch setup instructions)
- [x] Plans 01–04 marked as "Reference View" with pointer to master plan
- [x] Plan 5 enhanced with:
  - Definition of Done and Must NOT Have guardrails
  - Per-task Agent Profiles
  - Per-task Parallelization details
  - Per-task References (pattern/API/external)
  - Acceptance Criteria converted to checkboxes
  - Per-task QA Scenarios (happy path, failure path, edge cases)
  - Final Verification Wave (F1–F3)

## Remaining Pre-Flight Steps (Before First `/start-work`)

These are **execution steps**, not planning steps. They must be completed before any plan task begins:

1. **Create clean feature branch**:
   ```bash
   git checkout main
   git pull upstream main
   git branch -D codex/ad-multiforest-targeting 2>/dev/null || true
   git checkout -b ad-multiforest-targeting
   ```

2. **Remove rejected experiment** (if still present):
   ```bash
   rm -f powershell/public/Set-MtADTarget.ps1
   rm -f powershell/internal/ActiveDirectoryTargeting.ps1
   rm -f powershell/tests/functions/ActiveDirectoryTargeting.Tests.ps1
   ```

3. **Create evidence directory**:
   ```bash
   mkdir -p .sisyphus/evidence
   ```

4. **Verify baseline**:
   - `git branch --show-current` returns `ad-multiforest-targeting`
   - `main` is an ancestor
   - No `Set-MtADTarget|TargetMap|CurrentTargetKey` symbols in product source
   - PR #2002 `Get-MtADDomainState -ComputerName` behavior remains in `main`

## Readiness Status

| Plan | Status | Blockers |
|------|--------|----------|
| Master plan (Tasks 1–20) | **Ready for execution** | Pre-flight branch setup |
| Plan 5 (Tasks 21–26) | **Ready for execution** | Plan 2 query catalog stable (Tasks 23–25); Plan 4 E2E lab (Task 26) |

## Suggested First Session

Run `/start-work` on the master plan, Task 1 (branch alignment and scope reset). This is the foundation for everything else.
- Acceptance criteria, QA scenarios, and references in master plan: **Complete and agent-executable**
