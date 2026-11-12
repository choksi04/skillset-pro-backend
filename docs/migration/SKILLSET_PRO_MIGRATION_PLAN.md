# Skillset Pro Migration Owner's Guide

## What this guide is for

This is a decision and oversight guide for moving Skillset Pro from Supabase to an on-premises application and database. It focuses on how the change should be controlled, what the owner must decide, what can go wrong, and what evidence is required before proceeding. It is not a software implementation task list.

The project files show a React/Vite frontend, direct Supabase database access, Microsoft MSAL sign-in, and three Supabase Edge Functions for Entra user validation, assessment evaluation, and question generation. The target direction is Spring Boot, self-hosted PostgreSQL, and Microsoft Entra ID. Hosting platform and AI provider remain undecided. The team is planning to migrate the database with existing data; exact transfer scope and production cutover still require owner approval.

The supplied migration reference is for a different product (1Rivet Wiki). Its product-specific database, Keycloak, storage, hosting, and data decisions are not authoritative for Skillset Pro.

## The migration in plain terms

The application currently lets the browser communicate directly with Supabase. The intended end state is:

1. The browser continues to show the existing Skillset Pro UI.
2. The browser calls a new backend API instead of querying Supabase.
3. The backend verifies the user's Microsoft Entra access token and decides what the user is allowed to do.
4. The backend reads and writes a self-hosted PostgreSQL database.
5. Assessment evaluation and question generation go through a backend-controlled AI integration only if an approved provider and data policy are selected.

This is not just a database copy. It changes the security boundary, authentication/API contract, database schema and operations, and potentially how AI features work.

## The first decision: what happens to existing data?

The current planning path is to migrate existing data. Approve the exact scope before production cutover. Starting without existing data is an alternative only if the business explicitly changes that scope:

| Choice | What users get in the new application | Main trade-off |
|---|---|---|
| **Migrate existing data** | Approved users, reference data, assessments, attempts, results, reviews, and other selected records are transferred and reconciled. | More work and risk; identity mapping and historical-data correctness must be proven. |
| **Start without existing data** | The new database is initialized without legacy business records. Users and approved setup data are provisioned anew. | Simpler cutover, but old records do not appear in the new app. Retaining an archive is a separate responsibility. |

Detailed decision/runbooks:

- [Migration with existing data](./DATABASE_MIGRATION_WITH_DATA.md)
- [Start without existing data](./DATABASE_MIGRATION_WITHOUT_DATA.md)
- [Technical requirements and readiness](./SKILLSET_PRO_TECHNICAL_REQUIREMENTS.md)

Do not treat “no migration” as “delete the old database.” Data retention and decommissioning need a separate explicit decision.

## Who needs to own what

Assign named people before a rehearsal. One person may fill multiple roles, but each responsibility must have an owner.

| Role | Accountable for |
|---|---|
| **Migration owner / business decision-maker** | Chooses data path, approves scope and acceptable downtime, chairs go/no-go, accepts known limitations, authorizes rollback or continuation. |
| **Data owner / business SMEs** | Defines which records matter, validates samples and totals, resolves exceptions, confirms user-visible behavior and historical-data acceptance. |
| **Database/platform operator** | Source export and target provisioning, backups, restore tests, database access, capacity, monitoring, and recovery evidence. |
| **Application/backend lead** | API and workflow readiness, data transformation/import behavior, authorization, error handling, smoke tests, and technical stop/go recommendation. |
| **Identity administrator** | Entra app registration, API audience/scopes, redirect URIs, token claims, user matching/provisioning, and emergency access process. |
| **Security/privacy approver** | Approves handling of employee data, exports, AI-provider data flows, secret handling, access, retention, and audit evidence. |
| **Communications/support owner** | User notice, downtime/change guidance, support route, and post-cutover issue triage. |

## How to govern the migration

### Gate 1 — Establish facts

Before deciding the transfer scope, get a reliable inventory of the actual source database and application behavior. The repository has migration files and generated types, but no live database schema/data was inspected for these documents. Confirm that the migration history matches the deployed Supabase project.

Require these artifacts before approving a rehearsal:

- table-by-table source and target mapping, including excluded data;
- user identity/role/tenant mapping rules;
- list of Supabase functions, RLS policies, triggers, extensions, and storage/realtime usage, with a disposition for each;
- field-level treatment for secrets, personal data, soft-deleted/test records, timestamps/time zones, JSON, and legacy values;
- a list of reports/workflows whose results must match after transfer.

### Gate 2 — Prove restore and rehearse

Do not rely on a backup label or a successful export command. Restore the backup into an isolated environment and prove that the source can be recovered. Run the entire migration at least once with representative data, record elapsed time and errors, and rehearse rollback.

The rehearsal should use the same scripts, schema, settings, and operating steps planned for production. A rehearsal that depends on manual undocumented fixes does not qualify as repeatable.

### Gate 3 — Approve cutover

The migration owner calls go/no-go only after:

- backup and restore evidence is accepted;
- unresolved critical/high data or authorization defects are zero;
- reconciliation is within approved thresholds;
- business owners have validated representative workflows and samples;
- Entra login and role mapping work;
- expected downtime and user communications are approved;
- rollback criteria, decision-maker, and write-handling approach are explicit;
- required operators are present and reachable.

### Gate 4 — Stabilize and retire deliberately

Keep the old system and its recoverable data available, preferably read-only, for the approved rollback/retention period. Monitor errors and user reports. Decommission only after the data owner and migration owner sign off on the retention obligation and the rollback window has ended.

## Backup and recovery: minimum owner requirements

### Before any rehearsal or production migration

1. Capture a source backup/export at a named point in time. Record who created it, when, the source project/database identity, method, and checksum or provider verification.
2. Protect the backup as sensitive employee data: encrypt it in transit and at rest, restrict access, record access, and set a retention/deletion date.
3. Back up the target before each import attempt. A failed import must not destroy the prior known-good target state.
4. Store database backups separately from application hosts and separately from the credentials needed to access them.
5. Back up schema/migration files, deployment configuration, and required recovery instructions. Store secrets in an approved secret store, not in the backup bundle or Markdown.
6. Perform a restore test into an isolated environment. Verify database starts, constraints validate, and authorized application workflows can read the restored data.
7. Record recovery time and recovery point achieved. Business owners must decide whether those figures meet their service needs.

### During production cutover

- Establish and verify the source write freeze before taking the final consistent source export/restore point. If writes must continue, use a tested snapshot-plus-delta process and reconcile through the final cutover boundary.
- Keep the source untouched; do not make a migration script drop, truncate, or rewrite the source.
- Keep an independent copy of the final export until after the rollback period and retention approval.
- Take a target backup after successful import and before opening writes to users.
- Record which system is authoritative at every point. Avoid simultaneous independent writes to both systems.

### Gray areas that require an explicit owner decision

- What is the approved source backup mechanism and who can restore it? The current local files do not establish whether source-side backups or exports are available.
- Is point-in-time recovery available, and what retention window is needed?
- Where are backups stored, who can decrypt them, and how are restore credentials recovered if the primary identity service is unavailable?
- What are the acceptable recovery point (maximum data loss) and recovery time after a failed cutover?
- How long must source exports, old Supabase data, and audit records be retained?
- Who confirms backups are restorable rather than merely present?

## Failure handling and rollback principles

1. **Stop on an unexplained integrity or security failure.** Do not continue to “see if the rest works.”
2. **Preserve evidence.** Record run ID, source snapshot, target migration version, table/batch, error category and count, and logs with sensitive values removed.
3. **Keep the source of truth clear.** During rehearsals, source remains authoritative. During production cutover, do not accept writes in both systems unless a tested synchronization design exists.
4. **Do not repair production rows ad hoc.** Agree a correction, rerun/import strategy, and validation before applying a fix.
5. **Rollback is a business decision, not just a button.** Define the threshold, decision-maker, deadline, and treatment of writes made after the new system opens.
6. **Never assume reverse migration exists.** Data created in the new system generally will not flow back to Supabase automatically.
7. **Do not delete the source on successful import.** Retire it only after retention and acceptance sign-off.

For table/batch failures, see the dedicated failure runbooks in the two database-option documents.

## Lookout list: issues most likely to be missed

- **Identity is not the same as email.** People may change names/addresses; never merge records solely on a matching email without a verified crosswalk and duplicate check.
- **RLS is not automatically equivalent to backend authorization.** Recreate and test read restrictions as well as writes; browser route guards do not protect API data.
- **Supabase-specific objects may not transfer.** Auth users, RLS policies, Edge Functions, extensions, storage objects, and database functions need explicit treatment; a table dump alone is not a complete migration.
- **Assessment history has business meaning.** Preserve relationship between assignment, attempt, answer, question version, score, evaluator output, and reviewer decisions. Decide whether deleted/inactive records are included.
- **Triggers/defaults may change imported data.** Imports can invoke defaults/triggers or fail to preserve original timestamps; decide whether those are suspended, bypassed, or deliberately replayed.
- **Generated IDs and sequence values can collide.** After import, verify identity/sequence generators are ahead of existing keys.
- **Time and numeric conversions can subtly change results.** Verify timezone handling, date-only values, decimal precision, score rounding, and JSON representation.
- **AI outputs may not be reproducible.** Existing evaluations are historical records; migrating them is not the same as being able to regenerate the same scores with a different model/provider.
- **AI data handling remains open.** Assessment answers may contain employee information. No third-party provider should receive them until privacy/security approval is documented.
- **Empty-start acceptance is a user-impact decision.** If the old data is only archived, users may still lose convenient access to previous results.
- **Rollback can lose new writes.** Decide on a write freeze, manual reconciliation, or accepted loss window before cutover.
- **Run duration may exceed the downtime window.** Measure a full rehearsal and define whether downtime can be extended, delta capture used, or cutover rescheduled.

## Decision log to keep current

Record decision, options, chosen answer, rationale, approver, date, and what would cause reconsideration:

1. Confirm the planned with-data migration and approve included/excluded records; any change to an empty start needs explicit business acceptance.
2. Scope: included/excluded tables, rows, soft-deleted records, historical evaluations and users.
3. Identity matching and first-login provisioning.
4. Source backup, restore, retention, and access ownership.
5. Downtime limit, write freeze, rollback trigger, and post-cutover write handling.
6. On-premises hosting/network/backup platform.
7. AI provider, data handling, manual/offline fallback.
8. Acceptance thresholds for reconciliation and unresolved exceptions.
9. Source system retention/decommission date and sign-off owners.

## Owner's final go/no-go checklist

- [ ] Data path and scope are approved and communicated.
- [ ] Source and target backups have been restored and verified.
- [ ] Rehearsal used production-equivalent procedures and met downtime expectations.
- [ ] All critical records and business workflows reconcile; exceptions are approved.
- [ ] Identity and server-side authorization have been tested for allowed and denied access.
- [ ] AI and employee-data handling are approved or affected features have an agreed disposition.
- [ ] Rollback triggers, decision authority, write-loss implications, and communications are understood.
- [ ] Support, monitoring, on-call, and data owners are available during cutover.
- [ ] Source retention and eventual decommissioning are explicitly approved.
## Current next step: read-only validation and Liquibase baseline design

The new backend uses Liquibase for target schema tracking. Its master changelog is empty;
no source schema has been approved or imported. Keep the existing source application unchanged.

1. Confirm source project, inspection permissions/visibility, and backup/restore ownership.
2. Inspect the live schema read-only, beginning with users, identity links, constraints,
   roles/status, policies, triggers, and historical references. Compare both migration directories.
3. Approve source-to-target mappings and Entra identity exceptions before authoring the baseline.
4. Create the reviewed initial changesets and test them on isolated PostgreSQL before any import.
5. Track future schema changes with new changesets; keep historical-data transfer separately controlled.

The backend contains docs/LIVE_DATABASE_VALIDATION.md and
scripts/source-validation/schema-inventory.sql for this step. Both require review by the
source owner before production inspection. No Liquibase update or changelog-sync is part
of source validation. Source retention and cutover gates remain unchanged.
