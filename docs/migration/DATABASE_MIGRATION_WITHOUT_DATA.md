# Database Setup Runbook — Start Without Existing Data

## What this option means

The new self-hosted PostgreSQL database is created from the approved schema and starts without existing Skillset Pro business records. This is not a database-data migration. Users, historical assessments, results, reviews, and registry history will not automatically appear in the new application.

“Start empty” does **not** mean delete the old Supabase database. Retention, archive access, and eventual deletion must be decided separately.

## Decisions and user impact

Before choosing this option, the migration owner must get explicit acceptance that:

- historic users, assignments, attempts, answers, evaluation results, reviews, registry history, and notifications will not be available in the new app unless separately recreated;
- users may need to rebuild or re-enter approved skills, domains, questions, templates, and other setup data;
- keeping Supabase read-only as an archive does not make that information available inside the new app;
- new records created after cutover will not automatically be copied back to Supabase if the application is rolled back.

Also decide who may create the first administrator, how new Entra users are approved, what default role/scope applies, and what small reference-data seeds are permitted.

## Backup and retention

Even when starting empty, backup controls are required:

### Existing Supabase source

1. Before cutover, capture an approved source backup/export or verify the source platform's recoverable backup point.
2. Record the backup/export identifier, timestamp, owner, restore method, access restrictions, checksum/provider verification, and retention/deletion date.
3. Restore a backup into an isolated environment if the organization expects to rely on it as an archive or recovery source.
4. Keep source data read-only/available until owners approve archive and retention arrangements.
5. Do not decommission Supabase solely because the new database is empty.

### New target

1. Back up the database after Liquibase schema initialization and approved seed data.
2. Test restore before go-live.
3. Enable and test the approved on-prem backup schedule before accepting user data.
4. Protect backups independently from the application host; restrict and audit access.
5. Record recovery-point and recovery-time expectations and verify them in a restore exercise.

## How cutover works

### 1. Prepare

- Decide whether the old application will become read-only, remain available as an archive, or be retired later.
- Identify every non-migrated data class and communicate the impact to users and data owners.
- Prepare an approved list of clean reference data and a source for re-entering it.
- Test the new app from a freshly initialized database, including empty states and first-admin provisioning.
- Configure and validate Entra API audience/token validation and server-side role/scope checks.
- Decide the AI feature disposition. If no approved provider exists, explicitly disable or defer the affected AI workflows or provide a reviewed manual fallback. Do not leave an implicit dependency on Lovable's hosted gateway.

### 2. Protect the old system

- Take/verify the source backup or archive point.
- Record who can retrieve and restore it.
- Decide and test how users/data owners will access historical records after cutover.
- Set a retention checkpoint; no deletion is part of the cutover task.

### 3. Initialize the new system

1. Create the target database in the approved on-prem environment.
2. Apply Liquibase migrations from a clean baseline.
3. Load only reviewed, versioned, idempotent reference seeds. No legacy employee/business records should be loaded under this path.
4. Verify schema, indexes, constraints, and backup/restore.
5. Provision the initial administrator through a controlled, auditable process; do not rely on whichever user logs in first becoming admin.

### 4. Go live

1. Announce that the new app has no historical records and explain any separate archive.
2. Freeze or redirect use of the old application according to the agreed policy.
3. Point the frontend to the new backend.
4. Test Entra sign-in, approved user provisioning, admin setup, empty dashboards, key create/assign/complete/review workflows, and authorization denials.
5. Open the application for normal writes after the migration owner accepts the checks.
6. Monitor user reports, onboarding, errors, database capacity, and backup success.

## Failure handling

### If schema initialization fails

1. Stop before opening the application to users.
2. Preserve Liquibase logs, database version, migration version, and failure point; remove credentials and sensitive values from shared logs.
3. Do not manually edit Liquibase history or run ad hoc SQL in production to make the error disappear.
4. Fix the migration in version control and test from a clean database in a non-production environment.
5. If the production target is only partially initialized, restore its pre-initialization snapshot or use the documented clean-target recovery procedure, then rerun the verified migrations.
6. Confirm the old Supabase application remains the active system until go-live is explicitly approved.

### If Entra, provisioning, or first-admin setup fails

- Keep the new app closed to general users.
- Use the approved break-glass/admin recovery process; never grant a role by editing frontend storage or trusting a client-supplied ID.
- Confirm Entra API audience, token claims, user mapping, and server-side authorization before retrying.
- Record whether any user rows were created, and ensure the retry is safe and does not create duplicates or grant elevated access.

### If the new app fails after opening

- Declare which system is authoritative and stop writes if necessary.
- Decide whether to roll back to the old app or repair forward based on approved cutover criteria.
- Account for records created in the new system after cutover; they will not appear in Supabase without an explicit reverse process.
- Do not delete the target or source. Preserve backups and logs, notify users, and reconcile any records created during the incident.
- Resume only after smoke tests, authorization checks, and backup status pass.

## Key gray areas

- Does “without data” mean no legacy business data, or do selected current skills/domains/questions need a clean curated seed?
- Is the source Supabase application still needed as a read-only historical archive? Who pays for and operates it, and how long?
- How do users retrieve historical assessment results if the archive is separate?
- Who approves first-user provisioning, initial admin assignment, and default employee role?
- How are existing employee identities associated with Entra accounts if no user data is imported?
- Which audit/retention rules apply to old data and exports?
- What AI behavior is expected when no external/self-hosted AI service has been approved?
- How long is the rollback window, and how are new-system writes handled if rollback occurs?

## Acceptance and sign-off

- [ ] Business/data owners accept the non-migrated data list and user impact.
- [ ] Old Supabase data backup/archive and retention/decommission plan are approved and tested.
- [ ] Clean database initialization and Liquibase recovery are tested.
- [ ] First administrator and user-provisioning process is secure and recoverable.
- [ ] Empty-state and critical user workflows pass.
- [ ] Entra identity and server-side authorization tests pass.
- [ ] AI-dependent features have an approved provider or explicit unavailable/manual disposition.
- [ ] New target backup/restore is tested before production data is created.
- [ ] Rollback authority, trigger, and treatment of new writes are agreed.
