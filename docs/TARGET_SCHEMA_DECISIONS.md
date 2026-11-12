# Skillset Pro target-schema decisions

Prepared: 2026-11-05. Status: **DRAFT — owner decisions pending**.

This document consolidates repository analysis and the live metadata exports supplied by
the user. Recommendations are not approvals. No live connection was made by the reviewing
agent, no migration was executed, and the Liquibase master remains empty.

## Evidence and limits

The user ran read-only SQL in Lovable and provided 17 CSV exports. Files were reviewed
against both local migration histories. See [the evidence manifest](schema-reference/LIVE_METADATA_MANIFEST.csv)
for filenames, purposes and SHA-256 hashes; original exports remain outside Git.

The project/database identifier, inspection role, effective visibility, and source migration
history have not yet been independently established. Exports were collected at different
times, not from a single coordinated snapshot. Treat them as design evidence, not the final
cutover snapshot. Empty-result findings below were reported in chat, without a CSV artifact.

Local reference: [schema comparison](SCHEMA_COMPARISON.md), [column inventory](schema-reference/COLUMNS.csv)
and [object inventory](schema-reference/OBJECTS.md). These retain the original repository
expectations; this document records live differences rather than rewriting source evidence.

## Confirmed live findings

| Area | Result | Evidence |
|---|---|---|
| PostgreSQL | Source reports 17.6 | 11-37-54 export |
| Application columns | 31 public tables, 381 columns; names, underlying types and nullability match local inventory | 11-07-18 |
| Column defaults | assessments.duration_minutes is 45 live, 30 locally; skills.tags cast difference is equivalent | 11-07-18 |
| Numeric/timestamp details | confidence numeric(3,2); skill_weight unconstrained numeric; 86 timezone-aware timestamps at precision 6 | 11-37-54 |
| Constraints | 31 primary keys, 12 FKs, 11 UNIQUE constraints, 7 CHECK constraints; all reported validated | 11-08-48 |
| Indexes | 77 total: 42 backing PK/UNIQUE constraints and 35 additional; six additional and seven absent local explicit index names | 11-09-53 |
| Active mapping uniqueness | UNIQUE(domain_id, skill_id) WHERE deleted_on IS NULL is present | 11-09-53 |
| RLS | 31 enabled tables; none FORCE RLS; all owned by postgres | 11-34-19 |
| Policies | 31 permissive FOR ALL policies for public with USING true / WITH CHECK true | 11-33-32 |
| users grants | anon/authenticated/service_role have broad table privileges; two sandbox roles have SELECT/INSERT | 11-02-49 |
| Triggers | Five expected non-internal triggers, all enabled for normal/origin execution | 11-35-19 |
| Archive guard | Live body matches corrected text-ID logic in Drizzle 0001; SECURITY DEFINER, postgres owner, search_path=public | 11-06-26 |
| Other application functions | Single-draft and question-count functions match local final definitions | 11-36-07 |
| Routine inventory | Exactly three non-extension routines in public; no arguments | 12-06-28 |
| Extensions | pg_trgm 1.6/public; pgcrypto 1.3/extensions; uuid-ossp 1.1/extensions; pg_stat_statements 1.11/extensions; supabase_vault 0.3.1/vault; plpgsql 1.0/pg_catalog | 11-32-17 |
| Views/publications | No public views/materialized views or public publication members returned | User-reported empty results |

The users-specific exports additionally confirm 17 columns, PK(id), UNIQUE(email), no
returned incoming/outgoing FKs and no non-internal triggers directly on users.
Matching constraints do not prove the correctness of logical links without FKs. The
metadata does not establish effective anonymous API reachability or data quality.

## Decision register

All decisions below are **PENDING**. Record approver, date and rationale before setting a
decision to APPROVED. One person may hold multiple owner roles.

| ID | Recommended starting point | Owner role | Due gate |
|---|---|---|---|
| D01 | Preserve existing application IDs and compatible types, timestamp precision, JSONB and numeric semantics. Do not convert all text IDs to UUID. | Backend lead + data owner | Baseline approval |
| D02 | Use 45 minutes as the target assessment default to preserve live behavior. Confirm the business rule; this changes only new-record defaults, not existing durations. | Product/data owner | Baseline approval |
| D03 | Start index design from live definitions. Keep constraint-backed indexes and active-only uniqueness. Review the differences below; do not recreate every absent old index. | DBA + backend lead | Baseline approval |
| D04 | Evaluate a maintained PostgreSQL 17 patch release as the lowest-change target; confirm organizational support, extensions and operational platform. Source 17.6 is evidence, not a target patch prescription. | DBA/platform owner | Target provisioning |
| D05 | Retain pg_trgm if retaining trigram question search. Investigate actual dependencies before including pgcrypto/uuid-ossp/Vault; monitoring extensions are an operations decision. | DBA + backend/security leads | Baseline approval |
| D06 | Use Entra API access tokens and a unique verified tenant/object identity crosswalk to existing users.id. Preserve historical IDs; decide onboarding, unmapped/disabled users, role/scope ownership and admin recovery. | Identity admin + backend/data owners | Identity schema approval |
| D07 | Use a least-privilege target runtime role and server-enforced authorization. Do not copy source postgres ownership, sandbox roles or broad anon/authenticated grants. Explicitly decide target RLS versus backend enforcement. | Security approver + DBA/backend lead | Authorization design |
| D08 | Preserve archived-user read-only behavior through explicit backend checks; decide whether reviewed database triggers remain as defense in depth. Resolve coverage gaps and import behavior before implementation. | Product/data owner + backend/DBA | Baseline approval |
| D09 | Keep the one-draft-per-employee rule, with a race-safe implementation. Approve its tenant/domain and soft-delete semantics before choosing a partial unique index or locking strategy. | Product owner + backend/DBA | Baseline approval |
| D10 | Replace get_question_counts with an authorized backend aggregate. Retain SQL only if execution grants and tenant/user filtering are explicitly designed. | Backend + security lead | First reporting API |
| D11 | Preserve existing constraint behavior initially unless a specific correction is approved. Profile duplicates/orphans before adding FKs, enum/range checks or logical-pair uniqueness. | Data owner + DBA/backend lead | Baseline approval |
| D12 | Keep legacy submissions/reviews/official entries and versioned registries in scope until data owners approve exclusions. Separate approved reference-row imports from seeds so competency UUID links stay valid. | Data owner | Import mapping approval |
| D13 | Use reviewed final DDL in Liquibase; perform historical-data transfer through separately controlled import tooling. Never replay historical DELETE/backfill steps blindly or use changelog-sync to create an empty target. | Backend lead + DBA | Baseline approval |
| D14 | Do not provision realtime/publications or views merely because an older migration did. Confirm all custom schemas and any storage/auth/Vault dependencies before final scope acceptance. | Backend/platform/data owners | Scope approval |

## Index differences requiring D03 review

Six live indexes absent from the checked local SQL history:

| Index | Definition summary |
|---|---|
| idx_assessment_attempts_assessment_started | assessment_attempts(assessment_id, started_at DESC) |
| idx_assessment_questions_question | assessment_questions(question_id), active rows only |
| idx_questions_skill_type_status_level_active | questions(skill_id, question_type, status, competency_level), active rows only |
| idx_questions_text_trgm | GIN questions(question_text gin_trgm_ops), active rows only |
| idx_skill_self_ratings_skill | skill_self_ratings(skill_id) |
| idx_users_domain | users(domain_id) |

Seven local explicit index names absent from the live export:

- idx_attempts_assessment
- idx_answers_attempt
- idx_evaluations_attempt
- idx_skill_scores_attempt
- idx_questions_skill_type_status_active
- idx_ai_evaluations_attempt
- idx_attempt_skill_scores_attempt

Absence by name is not automatically a defect. Existing composite/unique indexes may
cover some access paths, but equivalence and performance require query-plan/workload
review. Do not drop or recreate indexes in the source during this planning step.

## Behavior gaps requiring explicit acceptance

- The archive guard covers four tables and does not protect every assessment/registry
  write. It uses NEW relationships on UPDATE and permits unresolved employee lookups.
- The single-draft trigger uses EXISTS; its presence does not prove concurrency safety.
- Nullable reference_id in assessment_config permits ordinary UNIQUE semantics that may
  allow duplicate global configurations; inspect actual records before strengthening it.
- Soft-deleted registry reviews retain UNIQUE(registry_id). Decide whether that is intended.
- Many employee/domain/skill/template/review references lack FKs. No tenant master or stable
  Entra identity columns are established by the inspected public schema.
- Audit fields differ between tables and can be nullable. Do not impose a mandatory shared
  audit base or restamp imported historical records without an approved mapping.

## Execution gates and remaining work

### Gate A: authorize the target schema design

- [ ] Source project/environment, inspection role/visibility and reference revisions recorded.
- [ ] D01-D03, D05, D08-D09, D11 and D13 approved; target-related exclusions recorded.
- [ ] Identity schema decision D06 and authorization design D07 defined before related tables/roles.
- [ ] Additional custom schemas, source migration-history records and extension dependencies reviewed.
- [ ] Owners accept the distinction between local history, observed live state and proposed target state.

### Gate B: implement and verify the baseline on isolated PostgreSQL

- [ ] Target PostgreSQL version/platform approved; development database isolated from the source.
- [ ] Author reviewed changes/001-initial-schema.yaml and explicitly include it from the master.
- [ ] Inspect generated SQL; validate and apply to an empty target with migration credentials.
- [ ] Compare resulting schema/indexes/constraints against the approved mapping.
- [ ] Prove repeat execution, next-version upgrade and failure recovery; retain Hibernate validation.
- [ ] Add PostgreSQL-backed integration coverage; current foundation tests do not prove database behavior.

### Gate C: qualify historical-data transfer and production cutover separately

- [ ] Aggregate profiling, duplicates/orphans, tenant boundaries and identity exceptions accepted.
- [ ] Reference data, legacy history, archived users and in-progress assessments mapped.
- [ ] Approved source backup restored in isolation; target backup/restore proven.
- [ ] Repeatable import, reconciliation, downtime and rollback/write-handling rehearsed.
- [ ] Actual Entra authentication and permitted/denied backend workflows tested.
- [ ] Business/security/platform owners approve production execution and retention arrangements.

Baseline development may proceed after its design gates; this document does not authorize
production execution. No new changesets or imports have been created by this review.

## Approval record

| Decision IDs | Final choice / exception | Named approver | Date | Evidence / rationale |
|---|---|---|---|---|
| Pending | Pending owner review | Unassigned | — | — |

Immediate action: review D02 (45-minute default), D03 (live indexes), D05 (extensions),
D06-D09 (identity, authorization and archive/draft behavior), and assign the owner roles.
