# Step 2: validate the source before defining the Liquibase baseline

Status: LIVE METADATA PARTIALLY REVIEWED (2026-11-05). The user supplied SQL-editor
exports covering the public schema; no live connection or business-data export was
used by the reviewing agent. Source identity/visibility, data quality, identity mapping
and restore evidence remain pending. See [target-schema decisions](TARGET_SCHEMA_DECISIONS.md)
for confirmed findings, differences and approvals. Liquibase is configured only for the
new target database; the master changelog remains empty.

## 1. Establish source inspection access

Have the source owner confirm the Supabase project/environment, PostgreSQL version,
inspection role, authorized schemas, inspection window, and backup/restore owner.
Use approved read-only database access with visibility across the in-scope objects.
RLS and grants can hide records; document visibility before trusting aggregate counts.

Use scripts/source-validation/schema-inventory.sql through an approved database client.
It reads metadata in a read-only transaction and applies session-local timeouts.
Do not run the backend against the source. Do not run Liquibase update, changelog-sync,
clear-checksums, or migration-lock commands against the source during inspection.
Review metadata before sharing; policy expressions can contain organization details.

## 2. Compare the live schema

Start with [the local Supabase/Drizzle comparison](SCHEMA_COMPARISON.md), its column
inventory and object ledger. These are repository-derived expectations, not live evidence.

Compare the live snapshot with both supabase/migrations and drizzle/migrations in the
reference frontend, plus generated types as supporting evidence. Neither a blank
drizzle/schema.ts nor TypeScript types establish the actual deployed schema.

Begin with public.users: primary key type/default, unique email rules, role/status
values, tenant/domain links, incoming and outgoing foreign keys, RLS/grants, and
triggers. Inventory all selected tables, enums, indexes, views, functions, extensions,
and Supabase-specific dependencies before approving the full target baseline.

## 3. Profile data with the data owner

After confirming actual column names and approved inspection load, collect counts by
role/status, missing identity values, normalized-email duplicates, missing parents,
soft-deleted/inactive users, and historical records with unresolved user references.
Use one consistent snapshot for related reconciliation results; live counts at
different times are provisional. Run expensive profiling on the isolated restored
source where possible. Do not put employee records or exports in Git.

Map verified Entra tenant/object identities to existing application user IDs. Preserve
those IDs and historical foreign keys. Email-only or ambiguous matches require review.
Use synthetic records for development until real-data handling is approved.

## 4. Design the target changelog

The deployed Supabase schema is evidence, not an instruction to copy managed schemas.
Approve each table/column/object mapping and disposition for auth, RLS, grants,
functions, triggers, extensions, storage, and realtime dependencies.

Liquibase generate-changelog, if used with approved read-only access or an isolated
restored source, produces a draft only. Review its output and separately inventory
objects unsupported by the chosen tooling. Do not request table-data export as part
of schema generation. Do not automatically apply generated SQL.

For a fresh target, encode the reviewed schema in changes/001-initial-schema.yaml
and explicitly include it from db.changelog-master.yaml. Liquibase creates target
objects; a separate controlled process imports approved historical business data.
Do not use changelog-sync on an empty target: it marks changesets applied without
creating their objects. Adopting an existing populated target requires a separately
reviewed baseline-equivalence and synchronization procedure.

## 5. Prove changes on isolated PostgreSQL

Before committing the actual baseline, validate changelogs, review generated update
SQL, apply to an empty supported PostgreSQL instance, compare metadata with the
approved target mapping, and test repeat execution, next-version upgrade, failure
recovery, and permissions. No uncontrolled production update or rollback is implied.
Keep Hibernate ddl-auto=validate; Liquibase owns DDL.

DATABASECHANGELOG tracks executed changesets and checksums; DATABASECHANGELOGLOCK
coordinates execution. These tables do not replace drift detection, database backups,
business-data reconciliation, or an employee-data audit trail. Never manually edit
history/checksums or release locks without establishing the cause and active run state.
Use a dedicated migration credential/deployment job when production execution is designed.

## Evidence template

- Source project/environment and inspection timestamp:
- Source role, schemas, visibility/RLS limitations:
- Source schema snapshot identifier and reference commit:
- Source backup identifier, restore proof and owner:
- users schema/constraints/policy/trigger differences:
- Aggregate quality findings and identity exceptions:
- Table/field mappings and excluded Supabase dependencies:
- Target PostgreSQL version and baseline changeset identifiers:
- Isolated initialization/upgrade/recovery evidence:
- Open issues, owner, acceptance and approver:

Acceptance: no unexplained critical identity/integrity differences; schema mappings,
exceptions and baseline are approved before target changesets or data imports execute.
