# Database migration, evidence and recovery

Updated 2026-11-13.
[Setup](../README.md) | [Backend development](BACKEND_DEVELOPMENT.md)

## Current checkpoint

The selected path is migration WITH existing application data. Empty-start planning is
superseded; changing that scope requires an explicit business decision.
Local preparation, import and recovery are complete for the named exported snapshot.
This is not a production cutover or permission to modify the live source.

| Milestone | Current evidence |
| --- | --- |
| Source history review | 31 Supabase and 2 Drizzle SQL migrations reviewed; frontend copies had matching hashes |
| Live metadata review | 17 user-supplied CSV exports; 31 application tables and 381 columns |
| Source-subset rehearsal | User reported successful restore into isolated PostgreSQL 18.4 |
| Development baseline | Five Liquibase changesets applied; status up to date and lock false |
| Definition comparison | User reported zero differences across all six selected object-definition sections |
| Controlled import | User reported transaction committed after in-transaction checks |
| Post-import validation | All 31 table counts matched; total 96,106 records; five business triggers normally enabled |
| Rehearsal/development contents | User reported all 31 counts and all-column fingerprints matched |
| Development backup/checkpoint | User reported custom archive created and readable; 33 table/data sections including Liquibase history |
| Recovery restore | User reported pg_restore exit 0 into skillset_pro_recovery_test |
| Development/recovery contents | User reported all 31 counts and fingerprints matched; recovery history had five changesets and lock false |
| Java database integration | Directly verified: both PostgreSQL API tests passed with the real development changelog in a disposable container |
| Business / identity / production acceptance | Still pending; authentication integration deferred |

Migration database results above are user-supplied terminal evidence, not an independently
connected inspection by the agent. The migration-checkpoint.json created before the recovery
exercise is a historical backup manifest; later recovery PASS evidence is recorded separately.
Do not assume that original manifest automatically contains later results.

### Database identities

All three preserved local databases use 127.0.0.1:5432 on reported PostgreSQL 18.4.

| Database | Owner | Purpose |
| --- | --- | --- |
| skillset_pro_rehearsal_20261112 | skillset_rehearsal_owner | Preserved selected source restore / comparison reference |
| skillset_pro_backend_dev | skillset_dev_owner | Liquibase-created development schema with imported data |
| skillset_pro_recovery_test | skillset_recovery_owner | Disposable recovery proof from the new development backup |

Keep rehearsal and development intact. No application or API test should write to them
as part of documentation/build verification. Do not restore over these validated databases.
Docker integration tests create their own separate database.

### Source archive and local evidence

| Item | Recorded value |
| --- | --- |
| Archive | skillset-pro_261112.backup, custom format / zstd, 8,751,394 bytes |
| Original location | C:\Users\RahulChoksi\Project\skillset-pro_261112.backup\skillset-pro_261112.backup |
| SHA-256 | 80412501C7B34BD272CFF49D2CFCF4CD2CC36492CAA08BEF7C1B14E3C4CD0A1D |
| Source / dump writer | PostgreSQL 17.6 / pg_dump 18.6 |
| Local restore client | pg_restore 18.4 read the archive; restore was subsequently reported successful |
| External work directory | C:\Users\RahulChoksi\Project\skillset-pro-rehearsal-work\20261112 |
| Checkpoint directory | validated-checkpoint under that external work directory |
| Development backup | skillset-pro-backend-dev_validated.backup under validated-checkpoint |

Expected external evidence includes schema-rehearsal.json, schema-development.json,
fingerprints-rehearsal.json, fingerprints-development.json, fingerprint-comparison.json,
validated-checkpoint/migration-checkpoint.json, fingerprints-recovery.json and
recovery-fingerprint-comparison.json. The checkpoint records the development backup's actual
hash/size; do not substitute the source archive hash for that new backup.
Use approved restricted storage, named ownership, encryption and retention for these artifacts.
Do not attach, print or commit the backup or generated employee-data SQL.

Committed non-row evidence remains available:

- [Column definitions/provenance](schema-reference/COLUMNS.csv).
- [Source migration hashes](schema-reference/MIGRATION_MANIFEST.csv).
- [Live metadata export manifest](schema-reference/LIVE_METADATA_MANIFEST.csv).
- [Exact archive selection manifest](../scripts/restore-rehearsal/archive-20261112/manifest.json).
- [Expected counts for all 31 tables](../scripts/restore-rehearsal/archive-20261112/expected-row-counts.csv).
- [Read-only source inventory SQL](../scripts/source-validation/schema-inventory.sql).

The original 21 Markdown files were archived before consolidation at
C:\Users\RahulChoksi\Project\skillset-pro-rehearsal-work\documentation-archive\backend-markdown-before-consolidation-20261113-155557.zip.
This historical prose archive is outside Git; the three maintained documents describe current status.
The archive selection manifest's prepared-not-restored status describes its creation stage,
not the current restore checkpoint above. Keep that original selection evidence unchanged.

The static source comparison used reference commit
617a45161b014e88efefddc4dfb65209f76a506c.
Live exports were collected at different times and are design evidence, not a single final
cutover snapshot. Record verified source project/role/visibility and final snapshot separately.

## Scope, mapping and observed differences

All 31 public application tables, including users, legacy history and legitimately empty
tables, are retained. Preserve existing IDs, foreign-key/reference UUIDs, timestamps/audit
values, JSONB state, numeric precision, soft-deleted history and historical AI evaluations.
No blanket text-to-UUID conversion, identity restamping or new seed UUIDs is part of this import.

The combined rehearsal selection contains 190 entries; schema review selects 159 and
application data selects 31. These TOC IDs and selection files are bound to the exact archive
hash. Never reuse them for another export without regenerated/reviewed selection.

Exclude Supabase-managed Auth, Storage, Vault, Realtime and source migration history from
blind restore, along with source ownership/ACL replay, source permissive policies,
publications/subscriptions, event triggers, tablespaces and unrelated extensions.
Uploaded Storage objects, if used, need a separate file backup; database metadata alone is
not a copy of uploaded files. Application public.users is retained; it is not auth.users.

Source RLS policies were permissive allow-all policies. The local target retains RLS on all
31 tables without those 31 policies or broad source anon/authenticated grants.
This preserves schema flags, not source access behavior. Dedicated owners bypass ordinary RLS
restrictions; production runtime-role grants/RLS remain a separate design.

Local restored extensions: pg_trgm 1.6 in public and plpgsql 1.0 in pg_catalog.
pg_trgm supports the question-text trigram index. pgcrypto, uuid-ossp, pg_stat_statements and
supabase_vault were not selected for this application baseline. Reviewed public DDL uses
gen_random_uuid() without requiring a managed extension schema.

Live versus static source observations retained in the baseline:

- assessments.duration_minutes defaults to 45 live, versus 30 in the local historical reconstruction.
- skills.tags has an equivalent cast representation; preserve text-array semantics.
- Confidence uses numeric(3,2), skill weight uses unconstrained numeric, and 86 observed timestamps
  are timezone-aware with precision 6. Do not normalize scores/time zones by guess.
- Source roles/status fields and many logical relationships lack enforcing constraints.
  Matching metadata/row fingerprints do not establish correctness of those business links.
- The empty drizzle/schema.ts is not a schema specification; Drizzle SQL extends the Supabase
  history, including the corrected archive function's text-ID comparisons.
- Source history includes destructive cleanup/backfill/seed steps. Use reviewed final DDL plus
  the controlled data copy; never replay historical DELETE/backfill operations on imported history.

Six live indexes were absent from the checked local migration names:
idx_assessment_attempts_assessment_started, idx_assessment_questions_question,
idx_questions_skill_type_status_level_active, idx_questions_text_trgm,
idx_skill_self_ratings_skill and idx_users_domain.

Seven old explicit names were absent live:
idx_attempts_assessment, idx_answers_attempt, idx_evaluations_attempt, idx_skill_scores_attempt,
idx_questions_skill_type_status_active, idx_ai_evaluations_attempt and idx_attempt_skill_scores_attempt.
Preserve the reviewed live definitions initially; name differences alone do not justify
dropping/recreating indexes. Exact current definitions are in the baseline SQL.

### Validation totals and limits

| Section | Expected / matched |
| --- | ---: |
| Application tables | 31 |
| Columns | 381 |
| Constraints excluding NOT NULL | 61: 31 PK, 12 FK, 11 UNIQUE, 7 CHECK |
| Non-null columns / PostgreSQL 18 NOT NULL constraints | 213 |
| PostgreSQL 18 total constraint entries | 274 |
| Indexes | 77: 42 constraint-backed and 35 additional |
| Non-extension application functions | 3 |
| Non-internal business triggers | 5 |
| RLS-enabled tables / copied source policies | 31 / 0 |
| Application records | 96,106 |

PostgreSQL 18 exposes NOT NULL constraints in pg_constraint; the earlier 274-versus-61 total
was a validation-query accounting issue. Separate 213 NOT NULL entries from the 61 other
constraints. It did not require another restore.

The six-section definition comparison checked object definitions, not just counts:
tables/RLS flags, column types/defaults/nullability/collations, constraint definitions/flags,
index definitions/validity, functions and triggers. Liquibase tracking tables were excluded.
All six matched between rehearsal and development.

That comparison excludes ownership, grants/default privileges, policies, extension versions,
database settings, views/sequences/custom types and row data. No application views/sequences/
custom enums were established by the reviewed schema; re-inventory if scope changes.
Recovery evidence confirms restored counts/history and row fingerprints; it does not claim a
separate complete recovery schema/grant/security comparison was performed.

Reported validation returned no unvalidated constraints or invalid/not-ready indexes.
Three functions belong to the appropriate local owner: block_archived_employee_writes,
enforce_single_draft_registry and get_question_counts. First and third are SECURITY DEFINER.

## Liquibase schema lifecycle

The default [application master](../src/main/resources/db/changelog/db.changelog-master.yaml)
is deliberately empty. The separate
[development changelog](../src/main/resources/db/changelog/db.changelog-development.yaml)
includes [the five baseline changesets](../src/main/resources/db/changelog/changes/001-initial-schema.yaml):

| ID (author skillset-pro) | Contents |
| --- | --- |
| 001-01-trigram-extension | pg_trgm |
| 001-02-application-tables | Final 31-table DDL |
| 001-03-application-routines | Three reviewed functions |
| 001-04-constraints-indexes | Reviewed constraints and indexes |
| 001-05-triggers-rls | Five triggers and RLS flags; no source policies |

The current development database already has all five applied. Keep their IDs, paths, content
and checksums unchanged. Add new reviewed changesets for future DDL; never clear checksums,
rewrite history, use changelog-sync on an empty target, or delete locks to suppress an issue.
History/lock tables coordinate schema execution; they are not backups or business audit logs.
Hibernate remains ddl-auto=validate; do not use automatic update/create against migrated data.

The liquibase-dev Maven profile and helper target ONLY the named local development
database/owner. They are not bound to a normal build and do not start Spring Boot or Entra.

Reference commands from the backend folder:

~~~powershell
.\scripts\liquibase\Invoke-DevelopmentSchema.ps1 -Action Validate
.\scripts\liquibase\Invoke-DevelopmentSchema.ps1 -Action Preview
.\scripts\liquibase\Invoke-DevelopmentSchema.ps1 -Action Status
~~~

The helper prompts securely and temporarily uses SKILLSET_DEV_DB_PASSWORD in the process.
Do not enable Maven debug output or save real credentials in command arguments.
Validate/Preview may create Liquibase tracking infrastructure; they do not apply application
changesets. Preview writes ignored target/liquibase/development-preview.sql.
Apply is a separate explicit action after review, not a step to repeat now.
Production migration-role separation, changelog selection, upgrade/failure recovery and
application startup deployment wiring are still to be designed.

## Reference runbook for reproduction

These steps document the completed local sequence. They are not instructions to import again.
Current development is populated; emptiness guards should reject a repeat.
Preparation/export helpers refuse existing outputs; choose a new restricted evidence directory
when taking fresh snapshots. Several helpers are fixed to these exact local database names and
archive hash; do not repoint them to production or reuse the manifests with a newer backup.

### 1. Source inspection and isolated rehearsal

Run only approved read-only source inspection through the owner's SQL Editor or
schema-inventory.sql. Preserve source project/snapshot/role/visibility evidence, schema mappings,
object dependencies, row scope, exceptions and named approvals.

Prepare the checked archive without any connection:

~~~powershell
$archive = 'C:\Users\RahulChoksi\Project\skillset-pro_261112.backup\skillset-pro_261112.backup'
$pgBin = 'C:\Program Files\PostgreSQL\18\bin'
$work = 'C:\Users\RahulChoksi\Project\skillset-pro-rehearsal-work\20261112'
.\scripts\restore-rehearsal\Prepare-Rehearsal.ps1 -ArchivePath $archive -OutputDirectory $work -PgRestorePath (Join-Path $pgBin 'pg_restore.exe')
~~~

Review generated review-schema.sql, exclusions and function bodies. Provision a fresh isolated
database with a dedicated owner, no application traffic, restricted access and a retention date.
The helper does not create databases/roles. Bootstrap using
[scripts/restore-rehearsal/bootstrap.sql](../scripts/restore-rehearsal/bootstrap.sql):
it installs pg_trgm, restricts schema CREATE and default public function EXECUTE for that owner.
Use the same role for bootstrap and restore; extension rights may require DBA provisioning.

The completed rehearsal used skillset_pro_rehearsal_20261112 / skillset_rehearsal_owner.
For an approved fresh recreation only, the selected restore command is:

~~~powershell
& (Join-Path $pgBin 'pg_restore.exe') --host=127.0.0.1 --port=5432 --username=skillset_rehearsal_owner --dbname=skillset_pro_rehearsal_20261112 --use-list (Join-Path $work 'application.list') --no-owner --no-acl --no-tablespaces --no-comments --no-security-labels --no-publications --no-subscriptions --single-transaction --exit-on-error $archive
if ($LASTEXITCODE -ne 0) { throw 'Restore failed; stop and preserve restricted evidence.' }
~~~

Do not add --clean, --create, --disable-triggers, --enable-row-security or parallel jobs.
Data loads before post-data FK/index/trigger/RLS installation in archive order.
Validate with psql -X, ON_ERROR_STOP=1 and
[validate-rehearsal.sql](../scripts/restore-rehearsal/validate-rehearsal.sql).
Inspect comparison rows; successful command exit alone does not establish all checks passed.
Keep the original rehearsal intact for subsequent comparisons.

### 2. Empty development baseline and schema comparison

The separate skillset_pro_backend_dev database was created under skillset_dev_owner,
confirmed empty and initialized through the reviewed Liquibase Validate/Preview/Apply/Status
sequence. Application tables must be absent before initial baseline creation.

For definition comparison, export read-only metadata and compare from the backend:

~~~powershell
.\scripts\schema-comparison\Export-SchemaSnapshot.ps1 -Database Rehearsal -OutputPath (Join-Path $work 'schema-rehearsal.json')
.\scripts\schema-comparison\Export-SchemaSnapshot.ps1 -Database Development -OutputPath (Join-Path $work 'schema-development.json')
.\scripts\schema-comparison\Compare-SchemaSnapshots.ps1 -RehearsalSnapshot (Join-Path $work 'schema-rehearsal.json') -DevelopmentSnapshot (Join-Path $work 'schema-development.json')
~~~

These are separate read-only snapshots, not one atomic cross-database snapshot.
Coordinate a quiet schema window and keep snapshots outside Git.

### 3. Controlled application-data import

Run read-only [preflight-development.sql](../scripts/data-import/preflight-development.sql)
only at the pre-import stage: expect 31 empty tables, five changesets, unlocked history and
five business triggers in normal O state.
Run [preflight-rehearsal.sql](../scripts/data-import/preflight-rehearsal.sql) on rehearsal
for aggregate historical-trigger conflicts, draft conflicts, logical links and the 12-FK graph.

The accepted local findings were 22 assessment_questions rows for non-active employees;
zero such registry review/item rows, zero duplicate-live-draft groups, zero soft-deleted-draft
conflicts and zero missing links in the four focused checks.
These checks do not replace full logical orphan/tenant/business validation.

The import preserved all history. Only trg_archived_ro_assessment_questions was disabled
inside the transaction and restored before commit; the other four business triggers and all
PK/UNIQUE/CHECK/FK enforcement stayed enabled.
The assessments archive trigger has no INSERT event. Never use session_replication_role or
disable all triggers to force imported history through.

[import-order.list](../scripts/data-import/import-order.list) defines the exact parent-first
order, including users/reference data before logical dependents, competency levels before
question levels, templates before junctions, assessments before attempts/questions, attempts
before answers/evaluations/scores, and registry/review/submission parents before children.

Reference preparation and integrity check:

~~~powershell
$importWork = Join-Path $work 'controlled-import'
.\scripts\data-import\Prepare-ControlledImport.ps1 -ArchivePath $archive -OutputDirectory $importWork
.\scripts\data-import\Invoke-ControlledImport.ps1 -WorkDirectory $importWork -Action Check
~~~

Preparation verifies TOC selection/hash and generates employee-data SQL outside Git.
Check verifies package/template hashes without a database connection.
Apply is an explicit separate action targeting development only; it has already completed:

~~~powershell
# Historical reference only; do not repeat on the populated development database.
.\scripts\data-import\Invoke-ControlledImport.ps1 -WorkDirectory $importWork -Action Apply
~~~

Apply uses one transaction, locks all 31 tables and both history tables, rechecks emptiness/
baseline/trigger state, loads all selected records, restores the one guard and validates before
commit. On SQL failure the transaction, rows and trigger changes roll back together.
No truncate/upsert/overwrite/history rewrite is used. A successful rerun is refused.
If the connection drops near commit, inspect actual state before deciding whether to retry.

[validate-development-data.sql](../scripts/data-import/validate-development-data.sql)
confirmed all expected counts, five changesets, unlocked history, five O-state triggers,
22 retained inactive-history question rows and no unvalidated constraints.

### 4. Content fingerprints and development backup

Keep both databases free of application writes during export, comparison and backup.
All columns are represented by to_jsonb(row)::text with UTC/consistent formatting;
row SHA-256 hashes are sorted under C collation and hashed again as a fixed-width sequence.
Output contains one count/digest per table, no employee values or per-row hashes.
Ordering is independent of physical row order and preserves duplicate multiplicity.
Empty tables hash the empty sequence; Liquibase tables are excluded.

Matching fingerprints are strong evidence under that normalization, not physical storage
identity or business acceptance. Use the same PostgreSQL major and matching definitions.
Separate database snapshots require a quiet window; there is no atomic cross-database snapshot.

~~~powershell
.\scripts\data-validation\Export-DataFingerprints.ps1 -Database Rehearsal -OutputPath (Join-Path $work 'fingerprints-rehearsal.json')
.\scripts\data-validation\Export-DataFingerprints.ps1 -Database Development -OutputPath (Join-Path $work 'fingerprints-development.json')
.\scripts\data-validation\Compare-DataFingerprints.ps1 -RehearsalFile (Join-Path $work 'fingerprints-rehearsal.json') -DevelopmentFile (Join-Path $work 'fingerprints-development.json') -ReportPath (Join-Path $work 'fingerprint-comparison.json')
.\scripts\data-validation\New-DevelopmentCheckpoint.ps1 -ComparisonReport (Join-Path $work 'fingerprint-comparison.json') -OutputDirectory (Join-Path $work 'validated-checkpoint')
~~~

The comparison checks inventory, identities, format/algorithm, major version, expected counts
and digest validity. Any difference is a stop condition; do not overwrite records to hide it.
The backup helper verifies evidence hashes and archives development in custom format without
source ownership/ACL replay. Expected archive inventory: 33 public tables/data sections
(31 application plus two Liquibase tracking tables).
It records backup hash/size, source/evidence hashes, repository revision/dirty paths and
migration-file hashes. Archive readability alone is not restore proof.

Keep an approved off-host backup copy and recovery credentials/configuration; a local backup
does not satisfy disaster recovery. Database dumps do not provision server roles or capture
external files, all configuration, secrets or platform access controls.

### 5. Third-database recovery test

The new development backup was restored into the fresh skillset_pro_recovery_test database
owned by skillset_recovery_owner, using pg_restore with ownership/ACL replay disabled,
single-transaction and exit-on-error. Do not use the source application-only list for this
backup: recovery must include both Liquibase history tables.
Roles and required extension rights must be provisioned separately; this is not a server-wide
role/configuration restore.

User evidence: restore exit 0, 31 application tables, five history entries, lock false.
Recovery fingerprints then matched the validated development snapshot for all 31 tables:

~~~powershell
.\scripts\data-validation\Export-DataFingerprints.ps1 -Database Recovery -OutputPath (Join-Path $work 'fingerprints-recovery.json')
.\scripts\data-validation\Compare-DataFingerprints.ps1 -ComparisonKind DevelopmentRecovery -ReferenceFile (Join-Path $work 'fingerprints-development.json') -CandidateFile (Join-Path $work 'fingerprints-recovery.json') -ReportPath (Join-Path $work 'recovery-fingerprint-comparison.json')
~~~

Retain the recovery PASS report alongside the original backup checkpoint. Full recovery
acceptance still needs its scoped schema/checksum/grant/security checks, measured RPO/RTO and
authorized application workflows. The observed successful local restore does not establish
production availability or recovery objectives.

## Decisions and remaining risks

The following records local implementation choices and remaining approval work; it does not
invent named approvals. Assign a named owner, date, rationale and evidence for each final decision.

| ID | Local treatment / remaining production decision | Accountable roles |
| --- | --- | --- |
| D01 IDs/types | Preserve text/UUID IDs, JSONB, precision and historical audits; identity crosswalk pending | Backend + data owner |
| D02 Default | Local baseline preserves live 45-minute default; business acceptance pending | Product/data owner |
| D03 Indexes | Preserve reviewed live indexes/active mapping uniqueness; workload/query-plan review pending | DBA + backend |
| D04 PostgreSQL | Local work tested on 18.4; production supported version/platform/patch policy still to approve | DBA/platform |
| D05 Extensions | pg_trgm retained; other dependencies/monitoring/storage inventory require scoped acceptance | DBA + security |
| D06 Identity | Entra API access tokens planned; unique tid/oid crosswalk, roles/onboarding/admin recovery deferred | Identity + backend/data |
| D07 Authorization | Source broad grants/policies excluded; final least-privilege runtime grants/RLS pending | Security + DBA/backend |
| D08 Archive guard | Existing corrected text-ID routines retained locally; complete write protection/coverage pending | Product + backend/DBA |
| D09 Draft rule | Existing trigger retained; race-safe tenant/domain/soft-delete semantics need approval/tests | Product + backend/DBA |
| D10 Counts RPC | Retained for parity; authorized backend replacement or restricted SQL execution design pending | Backend + security |
| D11 Constraints | Preserve source behavior; logical orphan/duplicate/tenant profiling before strengthening | Data + DBA/backend |
| D12 History/reference | All 31 tables retained, including legacy and reference UUIDs; production row scope/sign-off pending | Data owner |
| D13 Lifecycle | Final DDL in Liquibase, historical import separately controlled; production deployment/recovery process pending | Backend + DBA |
| D14 Managed features | Auth/Storage/Vault/realtime/history excluded from blind restore; actual custom/storage use to disposition | Platform + data/security |

Known business gaps requiring explicit review:

- Archive guard covers only four tables, omits assessment INSERT and several child writes,
  permits unresolved user lookups and checks NEW relationships on UPDATE.
- Single-draft EXISTS checks do not prove race safety. Review employee/tenant/domain scope
  and soft-deleted incoming drafts before choosing locking/partial uniqueness.
- Many relationships lack FKs, including skills.category_id and employee/domain/template
  references. No source tenant master or stable Entra identity columns were established.
- Nullable assessment_config.reference_id can allow multiple global rows under ordinary UNIQUE.
  registry_reviews.registry_id uniqueness survives soft deletion; registry version uniqueness
  is employee/version rather than tenant/domain-scoped.
- Registry-item and template junction logical-pair uniqueness is not universally enforced.
  Ordinary users.email UNIQUE does not prove case-insensitive identity uniqueness.
- questions.competency_level and assessment_questions.target_level use competency UUIDs;
  attempt_skill_scores.target_level remains an integer. They are not interchangeable.
- Preserve adaptive_state, paused/remaining time, evaluation errors, assignment limits/revoke
  state, verified levels and nullable self-ratings. Import is not permission to recompute scores.
- get_question_counts is SECURITY DEFINER without tenant/user filtering; do not expose it as
  an unrestricted API or copy broad execution grants.
- Schemas/role grants/extensions/settings and logical business acceptance need independent review.
  The aggregate/fingerprint proofs are scoped to this exported snapshot, not later source changes.

## Production cutover and operational gates

Remaining architecture: browser -> HTTPS frontend/reverse proxy -> Spring Boot -> self-hosted
PostgreSQL, with Entra metadata/JWKS access and approved server-side AI only if authorized.
Choose hosting/runtime, DNS/TLS, proxy routing/body limits/timeouts, CORS/origins, network egress,
HA/capacity and secret management with platform/security owners.
Measure concurrency, database growth, query workload and assessment peaks before sizing.
Keep production credentials/data separated from lower environments.

Before production execution, require:

1. Named migration/business, data, DBA/platform, backend, identity, security/privacy and support
   owners; accepted mappings, row scope/exclusions, identity exceptions and decision register.
2. Complete backend/frontend workflows and permitted/denied authorization tests, including roles,
   tenant/domain/ownership, inactive users and authoritative assessment/AI behavior.
3. Entra access-token integration, onboarding/disabled-user/admin recovery and real user tests.
4. Fresh consistent source snapshot at an enforced write freeze, or a tested snapshot-plus-delta
   design. Freeze browser writes, Edge Functions, admin clients and scheduled writers; drain
   in-flight work. A maintenance banner alone is insufficient.
5. Rehearsal with production-like schema/tooling/roles, measured export/import/reconciliation
   duration, deliberate failure/restart exercise, safe next-version schema upgrades and rollback.
6. Reconciliation of counts, keys, logical orphans/duplicates/cross-tenant links, critical totals,
   samples, audits, scores/JSON/time zones, history and paused/in-progress assessment behavior.
7. Target pre-import backup and post-import checkpoint, tested restoration, off-host retention/
   encryption/access controls, separate role/config/secret recovery, and agreed RPO/RTO.
8. Monitored logs, API latency/error rates, database/pool/capacity, backups, alerts, support/on-call,
   dependency/container scanning and auditable CI/CD artifact promotion.
9. AI provider/model, region/retention/training/privacy and cost approval, or a documented disabled/
   manual fallback. No employee answers sent externally without approval.
10. Explicit go/no-go, user communications, downtime limits, rollback decision authority/deadline,
    new-system write handling and source retention/decommission acceptance.

Stop on unexplained count/hash/constraint mismatches, wrong user/tenant mappings, ambiguous
commit boundaries, broken backup/restore, security defects or unreconciled scores/history.
Preserve sanitized run IDs/snapshot/schema/script revisions and restricted diagnostics;
do not skip records, repair production ad hoc or retry blindly.

If failure occurs before opening writes, preserve the source and last known-good target and
retry only from a reviewed clean checkpoint/forward fix. After opening, declare one system
authoritative and apply the agreed write-freeze/reverse-delta/accepted-loss policy.
There is no automatic reverse synchronization to Supabase, and application rollback does not
reverse database changes. Keep the old system recoverable/read-only through the approved
rollback and retention period; decommission only on owner sign-off.
