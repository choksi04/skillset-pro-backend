# Database Migration Runbook — Transfer Existing Data

## What this option means

Selected data is copied from the current Supabase PostgreSQL project into the new self-hosted PostgreSQL database. The source remains intact; this is a copy-and-validate process, not a destructive move.

This is the team's stated planning path; production scope and execution are not yet approved or executed. The local project files do not prove the live Supabase schema or contain a verified data export. Get explicit access and approval before profiling or exporting production data.

## What must be decided first

The migration owner and data owners must approve:

- tables/columns/rows to transfer and explicit exclusions;
- whether soft-deleted, inactive, test, and seeded records are included;
- whether assessment attempts, answers, scores, AI evaluations, reviews, and registry history are retained;
- how records map to verified Entra tenant/object identities and how unmapped users are handled; preserve application user IDs and historical foreign keys through a reviewed crosswalk rather than assuming Supabase auth IDs and application user IDs match;
- whether source auth-user records or storage objects are in scope;
- acceptable downtime and whether writes can be frozen;
- whether in-progress assessments must finish before the freeze or resume after migration, with validated saved answers, question order, timing, and evaluation state;
- acceptable row-count/reconciliation differences;
- source and target backup/retention requirements;
- who may access the data export and when it must be deleted.

Do not use the generated frontend types as the only schema specification. Reconcile all migration files, including SQL under both `supabase/migrations` and `drizzle/migrations`, against the deployed database before preparing an import. The latter includes archived-employee write-protection triggers; decide how approved historical imports interact with these controls and verify protection afterward.

## How the transfer should work

### 1. Profile and map

For each in-scope table, document:

- source and target table/field mapping;
- primary/foreign keys and import order;
- null/default/enum conversion;
- JSON, timestamp/timezone, numeric, and soft-delete handling;
- row filters and transformation rules;
- expected counts and business-level totals;
- owner who validates the result.

Profile the source for duplicates, missing parents, invalid statuses, unexpected nulls, and unsupported values. Resolve or explicitly disposition each issue before the production run.

### 2. Establish recoverable snapshots

Before a rehearsal:

1. Create a named, approved source snapshot/export.
2. Verify its checksum/provider status and restore it into an isolated environment.
3. Protect the export as sensitive data and restrict access.
4. Snapshot the target before each test import.
5. Record schema version, snapshot time, and migration-run identifier.

Before production:

1. Confirm backup/restore test remains valid and no relevant source change invalidated it.
2. Announce and start the approved write freeze, or start the tested delta-capture process.
3. Take the final consistent source export/restore point.
4. Take a target backup/snapshot before import.
5. Preserve source access and the final export through the rollback and retention windows.

If Supabase's available backup/export mechanisms, retention, or point-in-time recovery are unclear, stop and confirm them with the platform owner. Do not equate an application-level CSV export with a full database backup.

### 3. Rehearse the full process

Run the same schema, scripts, settings, access roles, and operator steps intended for cutover. The process should be repeatable and report progress without logging employee data or credentials.

Require:

- per-table source, imported, rejected, and intentionally excluded counts;
- foreign-key/orphan checks and unique-constraint validation;
- checks for key business totals (for example assignment/attempt/result counts);
- sampled record review by business owners;
- user-to-Entra crosswalk coverage and manual exception list;
- assessment workflow and permission tests using imported records;
- measured export/import/reconciliation duration;
- demonstrated recovery from a deliberately failed test batch.

### 4. Production cutover sequence

1. Confirm the owner, DBA/platform operator, application lead, identity administrator, data approver, and support contact are present.
2. Verify go/no-go checklist in the owner guide.
3. Put the old app into the approved write-freeze/read-only state. Enforce this on every source write path, including direct browser database calls, Edge Functions, administrative clients, and any scheduled writers; drain in-flight work and verify writes are blocked. A maintenance banner alone is insufficient. If writes cannot be frozen, use only a tested consistent-snapshot plus delta method.
4. Take the final source snapshot and target pre-import backup; record their identifiers.
5. Run import into the target. Import parent records before dependent records, respecting constraints.
6. Reconcile and validate before allowing user writes.
7. If all blocking checks pass, point the application at the new backend and run smoke tests.
8. Open the new application for writes only after the migration owner accepts the evidence.
9. Keep the old source available read-only through the agreed rollback/retention period.

## How to handle migration failures

### Stop conditions

Stop the run and do not open the new system for writes if any of these occur:

- source snapshot cannot be verified or restored;
- record totals differ beyond the approved tolerance without explanation;
- a foreign key, uniqueness, or required-data constraint fails;
- identity matching is ambiguous or could grant an incorrect role/scope;
- data appears assigned to the wrong user, tenant, or domain;
- assessment scores/history do not reconcile or can be altered by client input;
- the import process partially applied data but cannot identify its committed boundary;
- target backup/restore or rollback path is unavailable.

### Recovery sequence

1. **Pause writes and stop the import.** Do not rerun blindly and do not continue past a blocking data-integrity issue.
2. **Preserve the run evidence.** Keep sanitized logs, run ID, snapshot ID, schema version, last committed batch/table, counts, and error categories.
3. **Classify the failure.**
   - transient infrastructure issue (connection, disk, timeout);
   - deterministic data issue (constraint, invalid value, missing parent);
   - mapping issue (wrong/missing identity or transformation);
   - target schema/process issue (migration version, trigger/default, permissions);
   - reconciliation/acceptance issue.
4. **Protect the last known-good state.** Do not overwrite or drop the target. Restore the pre-import target backup or reset only a disposable rehearsal target, as approved.
5. **Fix the cause in the mapping/schema/process.** Do not silently skip failed rows. Every exclusion needs an owner and written disposition.
6. **Retry from a clean checkpoint.** The import must be idempotent or have documented batch checkpoints. Record the new run ID and the relationship to the failed run.
7. **Re-run all dependent checks.** Recount affected tables and downstream records; a corrected parent batch may affect child tables.
8. **Escalate repeated failures.** If the same issue recurs, stop and reassess scope, schema, and downtime rather than repeatedly retrying production.
9. **If cutover had already opened:** declare the active system of record, freeze the relevant writes if needed, invoke the agreed rollback decision, and explicitly reconcile or accept new-system writes. There is no assumed automatic reverse sync to Supabase.

### Partial-import design requirement

The migration process must make partial success visible. Each unit should either commit atomically or be checkpointed with a verifiable manifest of committed keys/counts. On retry, it must not duplicate records or overwrite newer values without an explicit rule. If the chosen tooling cannot meet this requirement, use a fresh target restore for retry rather than guessing which rows completed.

## Reconciliation: what counts as success?

Do not define success as “the command exited zero.” Before cutover, approve thresholds and check:

- every included table: source count, target count, excluded count, rejected count, and explanation;
- primary-key and foreign-key validity, duplicates, and nullability;
- important aggregates and status distributions;
- selected records across old/new/active/deleted states;
- identity links, roles, tenant/domain assignments, and inactive status;
- assessment assignment → attempt → answers → evaluation linkage;
- timestamp and score/decimal behavior;
- application workflows and read/write authorization.

For critical business records, the default expectation should be exact reconciliation or an explicitly approved transformation—not a generic percentage tolerance.

## Rollback and post-cutover writes

Before cutover, decide one:

1. Freeze new-system writes during the rollback decision window.
2. Define and test a reverse-delta process for specific records.
3. Accept that post-cutover writes will remain only in the new system if rollback occurs.

Do not promise a lossless rollback unless reverse migration/synchronization has been implemented and tested. Keep the old app and data available, but make one system authoritative at a time.

## Sign-off evidence

- [ ] Source scope and transformation rules approved.
- [ ] Source backup/export restored successfully in isolation.
- [ ] Target pre-import backup restored successfully.
- [ ] Full rehearsal completed; duration and failures documented.
- [ ] Reconciliation, identity mapping, and workflow checks accepted.
- [ ] Every rejected/excluded record has an approved disposition.
- [ ] Production source freeze/delta plan and final snapshot confirmed.
- [ ] Rollback and post-cutover write policy approved.
- [ ] Data owner and migration owner accept cutover evidence.
## Liquibase schema baseline before transferring business data

The next activity is approved read-only source validation, not a production migration.
Use the backend's docs/LIVE_DATABASE_VALIDATION.md and
scripts/source-validation/schema-inventory.sql. Record schema differences, inspection
visibility, user identity exceptions, source restore evidence and mapping approvals.

After approval, implement the target baseline under src/main/resources/db/changelog.
Apply it to an isolated empty PostgreSQL database and compare the resulting objects with
the approved target mapping. Historical-data import is a separate repeatable process.
Retain application IDs, relationships, historical evaluations and audit values.

Record the master changelog revision, executed changeset identifiers/checksums, target
schema snapshot, import tooling revision, and source snapshot in every rehearsal/run manifest.
Do not run Liquibase update/changelog-sync against the Supabase source. Do not synchronize
an empty target instead of applying the baseline. Existing-target adoption needs a separate,
approved equivalence check. Recovery may require restore or a forward fix; do not assume
a Liquibase rollback can restore deleted data or reverse every schema change.
