# AD feature split summary

Created and pushed 17 branches, worktrees and parked OpenCode sessions. The first 16 form an ordered stack; the last is a separate administrative reconciliation branch. Original `ad-test-consolidation` is unchanged.

Fork and upstream main both start at `512a076de`. Every nonquarantined product path matches the clean three-way merged tree. Fifteen source paths (eleven real conflicts plus paired code/guides and retirement chains) remain pending as patches; this is not full consolidation acceptance.

| Branch / compare | Feature | Owned source paths | Session | Validation |
| --- | --- | ---: | --- | --- |
| [00-foundation](https://github.com/soulemike/maester/compare/main...split/ad-00-foundation?expand=1) | Shared collectors, formatting and catalogue support | 26 | `<local-session-id>` | BLOCKED |
| [01-collector-overlaps](https://github.com/soulemike/maester/compare/split/ad-00-foundation...split/ad-01-collector-overlaps?expand=1) | Configuration/state/gMSA collector PR overlaps | 5 | `<local-session-id>` | PENDING |
| [02-groups-spns](https://github.com/soulemike/maester/compare/split/ad-01-collector-overlaps...split/ad-02-groups-spns?expand=1) | Groups, membership and SPNs | 70 | `<local-session-id>` | PENDING |
| [03-users-passwords](https://github.com/soulemike/maester/compare/split/ad-02-groups-spns...split/ad-03-users-passwords?expand=1) | Users, delegation and password policies | 88 | `<local-session-id>` | PENDING |
| [04-computers](https://github.com/soulemike/maester/compare/split/ad-03-users-passwords...split/ad-04-computers?expand=1) | Computer lifecycle and security | 35 | `<local-session-id>` | PENDING |
| [05-domains-controllers](https://github.com/soulemike/maester/compare/split/ad-04-computers...split/ad-05-domains-controllers?expand=1) | Domains, forests, DCs and FSMO | 59 | `<local-session-id>` | PENDING |
| [06-tombstone-overlap](https://github.com/soulemike/maester/compare/split/ad-05-domains-controllers...split/ad-06-tombstone-overlap?expand=1) | Tombstone advisory versus PR #2699 | 2 | `<local-session-id>` | PENDING |
| [07-topology](https://github.com/soulemike/maester/compare/split/ad-06-tombstone-overlap...split/ad-07-topology?expand=1) | Sites, subnets, OUs, replication and printers | 60 | `<local-session-id>` | PENDING |
| [08-directory-config](https://github.com/soulemike/maester/compare/split/ad-07-topology...split/ad-08-directory-config?expand=1) | Directory configuration and KDS | 26 | `<local-session-id>` | PENDING |
| [09-auth-policy-overlap](https://github.com/soulemike/maester/compare/split/ad-08-directory-config...split/ad-09-auth-policy-overlap?expand=1) | Authentication policy versus PR #2783 | 2 | `<local-session-id>` | PENDING |
| [10-adcs](https://github.com/soulemike/maester/compare/split/ad-09-auth-policy-overlap...split/ad-10-adcs?expand=1) | CA, certificate and template inventory | 21 | `<local-session-id>` | PENDING |
| [11-gpo](https://github.com/soulemike/maester/compare/split/ad-10-adcs...split/ad-11-gpo?expand=1) | GPO inventory, permissions and SYSVOL | 72 | `<local-session-id>` | PENDING |
| [12-schema-trust](https://github.com/soulemike/maester/compare/split/ad-11-gpo...split/ad-12-schema-trust?expand=1) | Schema and nonconflicted trust changes | 20 | `<local-session-id>` | PENDING |
| [13-dacl](https://github.com/soulemike/maester/compare/split/ad-12-schema-trust...split/ad-13-dacl?expand=1) | DACL consolidation | 35 | `<local-session-id>` | PENDING |
| [14-dns](https://github.com/soulemike/maester/compare/split/ad-13-dacl...split/ad-14-dns?expand=1) | DNS guide updates | 16 | `<local-session-id>` | PENDING |
| [15-catalog-docs](https://github.com/soulemike/maester/compare/split/ad-14-dns...split/ad-15-catalog-docs?expand=1) | Cross-suite regressions, redirects and upgrade guidance | 11 | `<local-session-id>` | PENDING |
| [16-main-reconciliation](https://github.com/soulemike/maester/compare/main...split/ad-16-main-reconciliation?expand=1) | Pending main conflict chains — administrative, not for PR | 15 | `<local-session-id>` | PENDING |

Worktree root: `<local-worktree-path>`.

Each worktree contains `TestResults/ad-split/PR-DRAFT.md`, `MERGE-REVIEW.md` and its validation log. The drafts are local text with compare links, not published GitHub PRs: CLI authentication is unavailable.

Read `REVIEW-DECISIONS.md` for area-specific existing-PR coordination and issue dispositions. #2796 remains outstanding (Markdown escaping and independent regex replacement expansion). #2405 fixes were substantially merged via #2437; remaining KDS/gMSA policy and reconciled regression behavior need a decision, not replay of the old fix branch.

The administrative branch contains the committed handoff/draft packet and pending source patches. Do not merge it into main or open it as an upstream PR. Existing #2734/fork #13/#2812 were not modified or closed.

Commit batches have at most 24 changed paths. Sessions are parked with `resume=false`; no live tenant jobs, automatic agent implementation or credentials were copied.
