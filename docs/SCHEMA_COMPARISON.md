# Local schema comparison: Supabase and Drizzle

Reviewed: 2026-11-04. Status: repository evidence only; live database not inspected.

## Scope and result

Inspected all **31 Supabase SQL migrations and 2 Drizzle SQL migrations** in the
reference repository at commit `617a45161b014e88efefddc4dfb65209f76a506c`.
Compared each SQL file with its copy in the new frontend: all 33 SHA-256 hashes match.

These are complementary histories, not two competing full schemas:

| Source | Contribution | Target treatment |
|---|---|---|
| supabase/migrations | Tables, columns, constraints, indexes, open RLS policies, functions, triggers, data transformations/seeds and realtime publication changes | Consolidate the reviewed final schema; do not replay operational/data cleanup history blindly |
| drizzle/migrations/0000 | Archived-employee guard function and four triggers on existing Supabase-defined tables | Decide database versus backend enforcement and preserve required behavior |
| drizzle/migrations/0001 | Replaces the guard function's UUID assumptions with text comparisons | Review the corrected final definition, not the original UUID variable |
| drizzle/schema.ts | Intentionally blank | Not a schema specification |
| drizzle/migrations/meta | Journal plus snapshots; not evidence that changes ran in production | Compare with actual deployed history/functions/triggers |

Static reconstruction yields **31 surviving application tables and 381 columns**.
Table names, column names and nullable/non-nullable declarations match the generated
TypeScript `Row` definitions for all 31 tables. This does not prove PostgreSQL types,
constraints, defaults, indexes, permissions, deployed state or business data match:
TypeScript collapses UUID/text/timestamps into strings and several numeric types into numbers.

Evidence artifacts:

- [Column definitions and provenance](schema-reference/COLUMNS.csv)
- [Source-file hashes](schema-reference/MIGRATION_MANIFEST.csv)
- [Constraints, indexes, policies, routines and trigger inventory](schema-reference/OBJECTS.md)
- [Read-only live-validation procedure](LIVE_DATABASE_VALIDATION.md)

Method: read SQL files in filename order within each directory; account for table rename/drop
and subsequent ADD/DROP/TYPE/nullability changes; apply Drizzle as an extension after its
required tables exist. This is static analysis, not a database replay or SQL parser correctness
proof. `IF NOT EXISTS`, existing data, external schema changes, grants, search_path and
independent migration histories can change actual outcomes. No SQL was executed.
The CSV retains source SQL definitions for review; it is not deployable DDL.

## Consolidated surviving table inventory

Every table is in public under the intended search_path. Early unqualified DDL assumes
that search_path; verify the actual source schema. Column counts include audit fields.
For UUID keys, the source declares gen_random_uuid(); text keys have no generated default.

| Table | Columns | Primary key | Creation source (before later changes) |
|---|---:|---|---|
| `ai_evaluations` | 13 | UUID / generated | [`20260310102120_0a19bac2-f26c-4ef1-9d4b-9480ee800e55.sql`](../../skillset-pro-frontend/supabase/migrations/20260310102120_0a19bac2-f26c-4ef1-9d4b-9480ee800e55.sql) |
| `assessment_assignments` | 17 | UUID / generated | [`20260427135409_278e56ed-c0b0-43cd-aaf5-45c6ca150696.sql`](../../skillset-pro-frontend/supabase/migrations/20260427135409_278e56ed-c0b0-43cd-aaf5-45c6ca150696.sql) |
| `assessment_attempts` | 18 | UUID / generated | [`20260310102120_0a19bac2-f26c-4ef1-9d4b-9480ee800e55.sql`](../../skillset-pro-frontend/supabase/migrations/20260310102120_0a19bac2-f26c-4ef1-9d4b-9480ee800e55.sql) |
| `assessment_config` | 11 | UUID / generated | [`20260408072954_7d891353-dc03-4b47-a5c5-bba35bf60405.sql`](../../skillset-pro-frontend/supabase/migrations/20260408072954_7d891353-dc03-4b47-a5c5-bba35bf60405.sql) |
| `assessment_questions` | 11 | UUID / generated | [`20260310102120_0a19bac2-f26c-4ef1-9d4b-9480ee800e55.sql`](../../skillset-pro-frontend/supabase/migrations/20260310102120_0a19bac2-f26c-4ef1-9d4b-9480ee800e55.sql) |
| `assessment_template_questions` | 5 | UUID / generated | [`20260427131822_ba3e4210-f4e1-432a-92e1-35972b404aa8.sql`](../../skillset-pro-frontend/supabase/migrations/20260427131822_ba3e4210-f4e1-432a-92e1-35972b404aa8.sql) |
| `assessment_template_skills` | 4 | UUID / generated | [`20260427131822_ba3e4210-f4e1-432a-92e1-35972b404aa8.sql`](../../skillset-pro-frontend/supabase/migrations/20260427131822_ba3e4210-f4e1-432a-92e1-35972b404aa8.sql) |
| `assessment_templates` | 22 | UUID / generated | [`20260427131822_ba3e4210-f4e1-432a-92e1-35972b404aa8.sql`](../../skillset-pro-frontend/supabase/migrations/20260427131822_ba3e4210-f4e1-432a-92e1-35972b404aa8.sql) |
| `assessments` | 18 | UUID / generated | [`20260310102120_0a19bac2-f26c-4ef1-9d4b-9480ee800e55.sql`](../../skillset-pro-frontend/supabase/migrations/20260310102120_0a19bac2-f26c-4ef1-9d4b-9480ee800e55.sql) |
| `attempt_answers` | 11 | UUID / generated | [`20260310102120_0a19bac2-f26c-4ef1-9d4b-9480ee800e55.sql`](../../skillset-pro-frontend/supabase/migrations/20260310102120_0a19bac2-f26c-4ef1-9d4b-9480ee800e55.sql) |
| `attempt_skill_scores` | 13 | UUID / generated | [`20260310102120_0a19bac2-f26c-4ef1-9d4b-9480ee800e55.sql`](../../skillset-pro-frontend/supabase/migrations/20260310102120_0a19bac2-f26c-4ef1-9d4b-9480ee800e55.sql) |
| `competency_levels` | 14 | UUID / generated | [`20260326081243_0e9af193-c552-4914-85b0-1c907c7d4e09.sql`](../../skillset-pro-frontend/supabase/migrations/20260326081243_0e9af193-c552-4914-85b0-1c907c7d4e09.sql) |
| `domain_skill_mappings` | 11 | text / supplied | [`20260310104648_5cfe7647-2795-4898-9e8d-a54a9a5b971f.sql`](../../skillset-pro-frontend/supabase/migrations/20260310104648_5cfe7647-2795-4898-9e8d-a54a9a5b971f.sql) |
| `domains` | 13 | text / supplied | [`20260310104648_5cfe7647-2795-4898-9e8d-a54a9a5b971f.sql`](../../skillset-pro-frontend/supabase/migrations/20260310104648_5cfe7647-2795-4898-9e8d-a54a9a5b971f.sql) |
| `employee_domain_assignments` | 6 | UUID / generated | [`20260310104648_5cfe7647-2795-4898-9e8d-a54a9a5b971f.sql`](../../skillset-pro-frontend/supabase/migrations/20260310104648_5cfe7647-2795-4898-9e8d-a54a9a5b971f.sql) |
| `manager_reviews` | 18 | text / supplied | [`20260310104648_5cfe7647-2795-4898-9e8d-a54a9a5b971f.sql`](../../skillset-pro-frontend/supabase/migrations/20260310104648_5cfe7647-2795-4898-9e8d-a54a9a5b971f.sql) |
| `notifications` | 10 | text / supplied | [`20260310104648_5cfe7647-2795-4898-9e8d-a54a9a5b971f.sql`](../../skillset-pro-frontend/supabase/migrations/20260310104648_5cfe7647-2795-4898-9e8d-a54a9a5b971f.sql) |
| `official_skill_entries` | 17 | text / supplied | [`20260310104648_5cfe7647-2795-4898-9e8d-a54a9a5b971f.sql`](../../skillset-pro-frontend/supabase/migrations/20260310104648_5cfe7647-2795-4898-9e8d-a54a9a5b971f.sql) |
| `questions` | 17 | text / supplied | [`20260310104648_5cfe7647-2795-4898-9e8d-a54a9a5b971f.sql`](../../skillset-pro-frontend/supabase/migrations/20260310104648_5cfe7647-2795-4898-9e8d-a54a9a5b971f.sql) |
| `reassessment_requests` | 9 | UUID / generated | [`20260326132626_dce3ff03-9264-48c4-92a6-1504a91468e5.sql`](../../skillset-pro-frontend/supabase/migrations/20260326132626_dce3ff03-9264-48c4-92a6-1504a91468e5.sql) |
| `registry_review_items` | 7 | UUID / generated | [`20260430135709_9dfcc989-d419-469b-8b59-f59cbc379781.sql`](../../skillset-pro-frontend/supabase/migrations/20260430135709_9dfcc989-d419-469b-8b59-f59cbc379781.sql) |
| `registry_reviews` | 13 | UUID / generated | [`20260430135709_9dfcc989-d419-469b-8b59-f59cbc379781.sql`](../../skillset-pro-frontend/supabase/migrations/20260430135709_9dfcc989-d419-469b-8b59-f59cbc379781.sql) |
| `review_skill_entries` | 10 | UUID / generated | [`20260310104648_5cfe7647-2795-4898-9e8d-a54a9a5b971f.sql`](../../skillset-pro-frontend/supabase/migrations/20260310104648_5cfe7647-2795-4898-9e8d-a54a9a5b971f.sql) |
| `skill_categories` | 11 | text / supplied | [`20260310104648_5cfe7647-2795-4898-9e8d-a54a9a5b971f.sql`](../../skillset-pro-frontend/supabase/migrations/20260310104648_5cfe7647-2795-4898-9e8d-a54a9a5b971f.sql) |
| `skill_registries` | 13 | UUID / generated | [`20260413171517_8909dba3-4333-4616-8a90-a81dd094828a.sql`](../../skillset-pro-frontend/supabase/migrations/20260413171517_8909dba3-4333-4616-8a90-a81dd094828a.sql) |
| `skill_registry_items` | 5 | UUID / generated | [`20260413171517_8909dba3-4333-4616-8a90-a81dd094828a.sql`](../../skillset-pro-frontend/supabase/migrations/20260413171517_8909dba3-4333-4616-8a90-a81dd094828a.sql) |
| `skill_registry_submissions` | 15 | text / supplied | [`20260310104648_5cfe7647-2795-4898-9e8d-a54a9a5b971f.sql`](../../skillset-pro-frontend/supabase/migrations/20260310104648_5cfe7647-2795-4898-9e8d-a54a9a5b971f.sql) |
| `skill_self_ratings` | 5 | UUID / generated | [`20260310104648_5cfe7647-2795-4898-9e8d-a54a9a5b971f.sql`](../../skillset-pro-frontend/supabase/migrations/20260310104648_5cfe7647-2795-4898-9e8d-a54a9a5b971f.sql) |
| `skill_topics` | 12 | text / supplied | [`20260326063827_1982980a-60c8-44d2-b8a0-47361224db3a.sql`](../../skillset-pro-frontend/supabase/migrations/20260326063827_1982980a-60c8-44d2-b8a0-47361224db3a.sql) |
| `skills` | 15 | text / supplied | [`20260310104648_5cfe7647-2795-4898-9e8d-a54a9a5b971f.sql`](../../skillset-pro-frontend/supabase/migrations/20260310104648_5cfe7647-2795-4898-9e8d-a54a9a5b971f.sql) |
| `users` | 17 | text / supplied | [`20260312132607_f427392e-7329-4169-b801-2ea32d52cc60.sql`](../../skillset-pro-frontend/supabase/migrations/20260312132607_f427392e-7329-4169-b801-2ea32d52cc60.sql) |

Do not silently drop the legacy submission/review/official-entry tables just because
versioned registries were added. The files retain both families; profile usage and approve
what historical records are transferred.

## Findings requiring resolution before the Liquibase baseline

### 1. Historical migrations contain destructive data operations

- The March 10 expansion migration deletes duplicate ai_evaluations and attempt_skill_scores
  before adding unique indexes.
- April 27 `20260427131822` hard-deletes cycle-linked assessments and related attempts,
  answers, evaluations, scores, questions, reviews and reassessment requests. It drops
  assessments.cycle_id, review_cycles, cycle_domain_selections and the cycle-check function.
- Later files backfill verified_level/category_id and transform competency names to UUIDs.

A new target should receive approved final DDL and a separately reviewed historical import.
Do not rerun these source cleanup steps on imported history. Records already deleted from
the source cannot be recovered from schema migrations; determine backup/archive availability.

### 2. Identity keys are mixed and stable Entra mapping is absent

public.users.id is text, has no database default, and is not declared as an auth.users
foreign key. No Entra tid/oid columns or identity mapping table are added by either history.
users.email has ordinary UNIQUE uniqueness; the files do not establish case-insensitive
uniqueness. role and status are unconstrained text with employee/active defaults.

Preserve application IDs as stored, review normalized-email duplicates and define a unique
verified Entra identity crosswalk. Do not convert every legacy text ID to UUID merely because
the current login generates UUID strings. Text IDs also occur throughout reference tables.

### 3. Many relationships exist only by convention

Only **12 explicit foreign keys** are declared across the surviving tables. Examples of
logical links without a declared FK include users.domain_id, domains.domain_lead_id,
skills.category_id, questions.skill_id/topic_id, assessment employee/domain/template links,
assignment template/employee/assessment links, registry-review parent links and review-item
parent links. Most audit actor fields are also plain text.

There is no CREATE TABLE for a tenant master in these histories, despite tenant_id columns.
Do not invent a missing source tenants table. Profile orphan/cross-tenant links and decide
target constraints deliberately. Adding constraints requires data acceptance and cleanup
rules; absence of a source FK is not evidence that all values are valid.

### 4. Drizzle guard fixes types but does not implement complete archive protection

0000 declares the employee variable as UUID while users.id/employee_id are text. 0001 uses
a text variable and explicit casts for comparisons. The four trigger installations remain
those from 0000; applying only 0001 installs no triggers.

Declared coverage:
- registry_reviews: INSERT, UPDATE, DELETE.
- registry_review_items: INSERT, UPDATE, DELETE.
- assessment_questions: INSERT, UPDATE, DELETE.
- assessments: UPDATE, DELETE only.

No equivalent archive guards are declared for assessment INSERT, attempts, answers,
evaluations, scores, skill_registries or skill_registry_items. The function checks non-active
status only when a user can be resolved; missing parents/users do not trigger the rejection.
On UPDATE it resolves NEW relationships; changing an employee/parent can evade protection of
the old relationship. It is not caller authentication or tenant authorization.
Confirm the live function body, triggers and enabled state. Decide full target behavior,
including imports of archived employee history, before copying or replacing this code.

### 5. RLS policies are deliberately permissive

All 31 surviving tables enable RLS and have allow-all policies using true/check true.
No later tightening appears in these directories. This does not establish effective public
access without inspecting grants, owners, role memberships and RLS bypass privileges.

Reconstruct the required server authorization matrix separately; do not reproduce permissive
source policies as the target security design. Both users and historical data need denied-read
and denied-write checks.

### 6. Constraints and tenant/soft-delete behavior need explicit choices

- domain_skill_mappings replaces unconditional UNIQUE(domain_id, skill_id) with a partial
  unique index applying only where deleted_on IS NULL. Preserve active-only semantics.
- assessment_config uniqueness includes nullable reference_id; ordinary UNIQUE does not by
  itself guarantee one global row per tenant/type when reference_id is NULL.
- skill_registries has UNIQUE(employee_id, version_number), not tenant/domain-scoped uniqueness.
  registry_reviews.registry_id remains UNIQUE even after soft deletion.
- skill_registry_items checks self_score 1..5 but has no declared UNIQUE(registry_id, skill_id).
  Both assessment-template junction tables likewise lack a logical-pair unique constraint.
- Assessments and attempts have status CHECK constraints; many other role/status/rating fields
  remain unconstrained. Do not infer enums/ranges from UI alone.
- employee_domain_assignments has UNIQUE(employee_id, domain_id), independent of tenant.
- review_skill_entries.self_rating and official_skill_entries.self_rating become nullable.

Validate intended business behavior and actual duplicates before strengthening constraints.

### 7. Assessment/history representations must retain their meaning

questions.competency_level and assessment_questions.target_level are converted from text
names to UUID foreign keys to competency_levels. attempt_skill_scores.target_level remains
an integer level. These similarly named fields are not interchangeable.

Keep adaptive_state JSONB, evaluation_error, paused_at, remaining_seconds, parent assessment,
assignment attempt counts/revoke_reason, verified levels and nullable self-ratings in the
mapping. Historical evaluations are transferred records, not a request to regenerate scores.
The six original assessment tables receive nullable audit columns in later migrations; a
mandatory shared Auditable mapping cannot be assumed without a target-schema decision.

### 8. Registry and RPC rules need backend replacements or reviewed retention

enforce_single_draft_registry is replaced in June to set search_path=public; its INSERT/UPDATE
trigger remains. The function uses an EXISTS check rather than a unique partial index, so
the intended single-draft invariant needs concurrent-write testing and a race-safe design.
It scopes by employee and ignores deleted existing drafts; review handling of NEW.deleted_on.

get_question_counts is STABLE SECURITY DEFINER, filters deleted_on but has no tenant/user
filter. Replace with an authorized backend aggregate or explicitly review retained SQL.
Inspect function owners, execution grants and definition in the live source.

### 9. Realtime and extension dependencies are not fully specified by table DDL

skill_registries is added to supabase_realtime in April and removed in July. Thus these files
do not leave it published there. Confirm actual live publication membership and frontend usage.
A fresh plain PostgreSQL target should not replay publication commands for an absent
Supabase-managed publication.

No extension creation, custom enum creation or view creation is declared in these migration
files. Generated types also mention show_limit/show_trgm, suggesting additional extension
surface outside this history; confirm pg_extension rather than assuming its origin or use.
Inventory Supabase-managed auth/storage objects separately if selected for transfer.

### 10. Some indexes overlap and source seeds are tenant-specific

Potential duplicate index pairs on identical keys include idx_evaluations_attempt /
idx_ai_evaluations_attempt, idx_answers_attempt / idx_attempt_answers_attempt, and
idx_skill_scores_attempt / idx_attempt_skill_scores_attempt. registry_reviews.registry_id
also has an explicit non-unique index plus its unique constraint's index.
Review actual definitions and query needs before consolidating. An IF NOT EXISTS statement
with an existing name does not create a second index merely because it appears twice.

Competency levels and global assessment configuration are seeded for tenant-001. Their
UUIDs/defaults and numeric ranges matter when importing records that reference them.
Choose between importing approved reference rows and deterministic seeds; do not create
unrelated replacement UUIDs before loading source questions. Historical seed/backfill SQL
is not an automatic production import plan.

## Dependency order for target design and import

This is a design starting point, not executable import instructions. Actual FKs and
application mappings must be validated, including any user-domain circular link.

1. Reference/identity configuration: competency_levels, categories, users and domains
   with an explicit plan for users.domain_id / domains.domain_lead_id.
2. Skills/topics, domain mappings, question bank and assessment configuration.
3. Legacy submissions/self-ratings and versioned registries/items as approved.
4. Templates and template skills/questions.
5. Assessments and assignments, resolving optional cross-links/self-references explicitly.
6. Attempts, answers, evaluations and per-skill scores.
7. Manager reviews/review items, registry reviews/items, reassessment requests and official
   records; resolve any mutual links in staged passes.
8. Notifications and approved ancillary history.

Reconcile IDs, parent links, tenant boundaries, status distributions, score values,
timestamps and JSON state, not row counts alone.

## Required live checks and next action

- Confirm Supabase migration history and Drizzle application records independently.
- Confirm exact function definitions and all five surviving trigger installations.
- Export approved public schema metadata; compare it with the column/object inventory.
- Check text/UUID types, defaults, CHECK/UNIQUE/FK definitions, nullable ratings and partial indexes.
- Confirm users identity/role/status values and normalized-email collisions using aggregates.
- Profile missing parents, duplicate logical keys and cross-tenant links before proposing new FKs.
- Confirm legacy cycle remnants: skill_registry_submissions.cycle_id remains even though
  review_cycles is dropped; skill_registry_submissions.cycle and official_skill_entries.cycle
  remain text fields. Do not infer a valid cycle parent from these values.
- Record owners, grants, RLS bypass, extensions, publications, views/routines outside migration files.
- Verify source backup restore and approve reference-data/archived-history scope.

Leave db.changelog-master.yaml empty until these checks and the target mapping are approved.
Then implement reviewed final schema changesets, test on isolated PostgreSQL, and rehearse
the separate data transfer. This report does not certify live parity or execution readiness.
