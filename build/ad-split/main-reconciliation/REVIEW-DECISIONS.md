# AD split: review and merge decisions

Evidence snapshot: current fork and upstream main both `512a076de`; original consolidation `bf1709daa`. The original branch is retained. Public GitHub PR/issue data was read without authentication; SSH fetched relevant PR heads. Upstream open-PR file lists were collected completely. GitHub later rate-limited further API reads while reviewing fork PRs; relevant fork heads #10, #11 and #13 were fetched through Git instead.

## Segmentation and merge order

Use the ordered stack in `plan.json`: foundation; shared collector overlaps; groups/SPNs; users/passwords; computers; domains/controllers; tombstone overlap; topology; directory configuration; authentication-policy overlap; AD CS; GPO; schema/trust; DACL; DNS; final catalog/docs. Each branch compares against its immediate parent and is rebased to main only after that parent merges. This avoids duplicate shared-foundation diffs and sibling conflicts in generated legacy mappings.

Every retirement accompanies its surviving target, cumulative native replacement entries and regenerated legacy tag table. Cross-feature dependencies are explicit: USER-14→SPN-06; COMP-09/10→DCOMP-01/03; CFG-01→FOR-03; CFG-04→FEAT-01; CFG-05→FOR-04. USER-05 moves atomically to delegation. Do not merge individual branch diffs against main out of order.

Historical URL redirects arrive in the final catalog/docs branch. Intermediate retirement branches are review units, not independently deployable website snapshots. Merge/deploy with compatibility changes, or bring the agreed redirect mechanism forward before deployment.

## Main reconciliation — separate administrative branch

`git merge-tree` reports eleven genuinely conflicted paths. The staged unit includes paired guides/code and retirement chains, so it owns fifteen source-change paths:

- COMP-02 (deleted by consolidation, modified on main) and DCOMP-06 (the survivor): preserve current `MaximumInactiveDays` behavior when deciding how to combine inventories.
- TRUST-07 (deleted by consolidation, modified on main) and TRUST-06 (survivor): preserve current validation-age parameters and documented semantics.
- USER-02: reconcile current parameterized retention with consolidated disabled-user lifecycle behavior.
- KRBTGT-01 plus the guide changes for still-active KRBTGT-02/03: reconcile the current password-age parameter and combined evidence. KRBTGT-02/03 are not retirement mappings; their `.ps1` files remain. Their guide deletions are held for review rather than silently removing documentation from active checks.
- `Frameworks.Tests.ps1`: preserve current DISA/framework assertions; do not restore a stale whole-file fixture/count from the consolidation.

The administrative branch holds source patches, not executable resolutions. It must not become an upstream PR or be merged into main. Main's active versions remain in the feature stack; these chains' retirement mappings are excluded until an approved resolution removes the old IDs. The stack is therefore not a completed, fully integrated consolidation.

## Impacted PR areas

| Area / split owner | Open PRs | Evidence and merge decision |
| --- | --- | --- |
| Existing broad consolidation | upstream #2734 | Original PR remains open. Do not merge it in parallel with split replacements. After split acceptance, decide whether to supersede it; no PR was closed or changed. |
| Reconciliation / shared certificate parser / OU dates / optional-feature scopes | fork #13 (`codex/fix-ad-consolidation-on-main`) | Draft specifically resolves all eleven main conflicts and adds inventory/date/scope repairs. Review its incremental AD fixes as candidate resolutions; do not import its merged main ancestry or generated builder data. Preserve author credit. |
| NTAuth paths / AD CS | upstream #2812 | Includes the entire #2734 consolidation and fork #13 repair ancestry. Review its advertised five-file NTAuth increment separately, then rebase onto the accepted AD CS foundation. It is not an independent 568-file change to merge beside this stack. |
| AD CS configuration evidence | upstream #2804 then #2806 | #2806 explicitly depends on #2804. Shared configuration collector overlaps; merge their extra flags/EKU/publication evidence without undoing null-vs-empty distinctions, and keep parser/inventory contracts. These PRs are not imported by this migration. |
| gMSA collector | upstream #2786 | Additional `msDS-GroupMSAMembership` evidence collides directly with the service-account collector changes. Reconcile on collector-overlap branch; never request managed passwords. |
| Authentication policy / state categories | upstream #2783 | CFG-08 is a confirmed content conflict, not merely a shared path. Dedicated authentication-policy branch holds this area. Decide whether richer policy/silo posture replaces the consolidation inventory; preserve empty/unknown distinctions. |
| Replication and DNS state categories | upstream #2784, #2785 | Shared `Get-MtADDomainState` paths overlap, though no additional content conflict beyond preexisting main conflicts appeared in the merge-tree probe. Follow the authors' order #2786 → #2783 → #2784 → #2785 and rebase state-category additions rather than copying a whole older state helper. |
| Tombstone lifetime | upstream #2699 | Different outcome model for absent attributes. Dedicated tombstone branch preserves known-object effective 60-day default, errors on failed collection, and configurable advisory. Decide with the PR author; do not equate unset attribute with unreadable object. Its unrelated CIS lockbox fix remains separate. |
| Golden registry / global fixtures | upstream #2816, #2768–#2772 | Shared Golden/exporter edits; confirmed additional conflicts in exporter/Golden for #2768/#2769/#2771/#2772. Foundation and later generated catalogue commits must retain CISA replacement semantics, not replace generated JSON wholesale. #2816's own import fix is not the eleven inherited AD/main conflicts. |
| Framework assertions | upstream #2540, #2770, #2772, #2789, #2799 | Shared fixture paths; #2540/#2770 have confirmed framework content conflict in the source merge probe. Keep new framework facts and tests; reconcile source count/assertion changes separately. |
| Upgrade guidance / redirects | upstream #2683, #2768, #2769 | Shared upgrade guide and redirect mechanism. #2683's reported source merge conflicts are outside this split's changed paths; distinguish inherited/indirect conflicts from actual AD delta. Coordinate final documentation and legacy registry changes. |
| Older DNS targeting proposals | fork #10, #11 | Both propose old AD-command-based `ComputerName` changes in a now substantially redesigned state helper. Do not merge whole stale branches. Review whether current target/protocol/cache APIs already cover the requested behavior; port only a demonstrated missing capability in the collector-overlap session. |

The raw open-PR inventory and path intersections are retained beside this document. A shared path is a coordination risk, not proof of a content conflict; merge-tree results include main conflicts inherited by old PR heads and are labelled accordingly.

## Issue #2796: outstanding report safety work

Open. Consolidation formatters improve pipe/HTML handling but do not establish complete Markdown escaping. Examples still use narrower custom escaping; direct directory values and variable `-replace` calls remain. The issue comment identifies a second, independent defect: `$&`, `$$`, `$1` and named groups are interpreted in regex replacement strings. `Get-MtSafeMarkdown` does not fix that; literal `.Replace()` is needed where replacement text is literal.

Recommended separate follow-up after agreeing the split baseline: a report-safety ratchet/gate, then folder-sized escaping and literal-placeholder sweeps. Do not claim the existing formatting foundation closes this issue. No new ratchet or full escaping sweep is implemented in this migration, and no empty issue-fix branch is published as if it were a fix. The foundation and feature sessions carry the outstanding requirement for subsequent decisions.

## Issue #2405: merged fixes, remaining decisions

Open, but `origin/fix/ad-issues-2405` has no commits ahead of upstream main. PR #2437 merged that work (`21704fdbe`). Do not duplicate its already merged KDS-count, empty-result/query-error, DFS-R serverReference, DACL platform/skip, and stale-computer fixes by replaying the old branch.

The consolidation modifies several of those areas again. Review KDS zero-key policy in directory-config: operator-confirmed complete visibility is not proof that an organization requires gMSA use, so the optional zero-key failure still needs a requirements decision. Main now has configurable stale-computer behavior that belongs in the COMP-02/DCOMP-06 reconciliation chain. Preserve its parameter, not the consolidation's older implementation. Compare surviving DACL behaviors and actual DFS-R child-OU fixtures before asserting full acceptance. Issue #2331 disposition and GPO indentation acceptance have not been established here; no issue is closed by this migration.

## Validation and draft publication

Each executable branch must run Golden, Frameworks, RepositoryLayout, NativeTestAttributes/NativeTestLint and every existing `AD*.Tests.ps1` / `ActiveDirectory*.Tests.ps1`. Branch-specific failures are blockers, not a reason to weaken expected outcomes. Administrative patch branch is not executable migration acceptance.

Sessions are created at their worktree directories and handed a parked message with `resume=false`; no agents are automatically launched in those sessions. Local PR drafts and compare links are prepared per worktree. GitHub CLI authentication is unavailable, so published GitHub draft PRs are not claimed.

The handoffs are stored in each session's durable inbox, not yet delivered as conversation messages: `resume=false` intentionally leaves all seventeen sessions without assistant messages. Session locations and queued handoffs were read back through the API. Foundation and reconciliation root parents were separately verified as the pinned `512a076de` commit.

### Squash merge and hard dependencies

Commit batches respect the user's fewer-than-25-path preference, but intermediate commits inside a feature branch need not be independently catalogue-valid. Squash-merge each complete branch boundary; do not cherry-pick individual registry or retirement chunks.

- Collector-overlap branch 01 is a hard prerequisite: computer/delegation assessments require its service-account fields.
- Groups/SPNs branch 02 precedes USER-14 retirement; tombstone 06 precedes CFG-01 retirement in 08; topology 07 precedes CFG-04 retirement in 08.
- Authentication-policy branch 09 has no intrinsic downstream dependency, but its placement in this stack is an intentional review-order gate. It can be moved to the end in a future approved restack if PR #2783 blocks progress. Do not rewrite pushed branch histories silently.

### Structural review and remaining acceptance evidence

Final structural review found no dropped source changes or ownership errors. Its verdict was **INSUFFICIENT EVIDENCE for acceptance** while validation ran. The initial selected runner omits the separately located SYSVOL transport suite and broader analyzer/encoding/help/build checks. Supplemental validation is required before approval; no merge readiness is claimed. A mechanical per-branch check of Maester command references must distinguish repository-defined commands, binary/exported commands and unresolved dynamic calls.

The first completed boundary, 00-foundation, is **BLOCKED** by the existing `ActiveDirectoryOptIn` guarded-collector fixture: it requires pure assessment/formatting helpers to call a collector even when they perform no directory operation. The source fixture's distinction between native tests, transport/session access and pure helpers is currently owned by branch 15. Golden and native catalogue/layout/parameter/shim checks passed at boundary 00. This is a documented fixture-placement dependency to fix in the new sessions/restack, not a green foundation and not a reason to remove safety checks. Subsequent branch results remain in progress.

**Latest status supersedes the earlier progress wording:** the shell job ended with `Shell.NotFoundError`; no matching validation process remains. Complete result records exist for 00–12, all BLOCKED. Boundaries 13–15 are INCOMPLETE because no completed records were saved. The administrative boundary 16 has no executable acceptance run. No automatic restart occurred, and supplemental checks remain unexecuted.

Recorded blockers by area:

- Pure-helper guarded-collector fixture: 00–12; its source update currently arrives in 15.
- Ordered-dictionary Windows LAPS regression: 01–11; not reported in the completed 12-schema-trust result. The fixture is placed before its schema migration.
- Non-benchmark catalogue-count assertion: 07–12; the conflicting framework fixture remains quarantined rather than replaced wholesale.
- KDS zero-key and exactly-two-key fixture expectations: 08–12; main's old skip/wording expectations differ from the visibility-aware assessment and later fixture update. The zero-key gMSA requirement decision is still unresolved.

These failures demonstrate that branch-boundary acceptance needs further fixture/dependency work. The source changes have been preserved, but the current stack is not a set of approved independently deployable PRs.

Supplemental runner `TestResults/ad-split/supplemental-validation.py` is prepared but has not run. It adds per-boundary static Maester-command checks, analyzer/encoding/help/build selections, direct SYSVOL transport tests on 11–15, and final module validation. An optional `--full-representative` run covers complete suites at boundaries 00/03/05/07/11/15; that longer validation remains pending until explicitly launched. Do not describe prepared scripts as executed evidence.

Committed packet evidence was added after the reviewer snapshot: administrative commits `f91fbb376` and `6c1850b2c` contain the review matrix, draft bodies, session index and candidate repair patches. The source-first merge-tree evidence and main-first migration tree differ only by conflict-marker orientation; all hand-written nonquarantined migrated paths were compared to the actual migration tree and matched exactly.
