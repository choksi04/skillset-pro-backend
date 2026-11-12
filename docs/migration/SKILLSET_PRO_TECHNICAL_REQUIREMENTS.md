# Skillset Pro Migration — Technical Requirements and Readiness

## Purpose

This document describes the technical capabilities, infrastructure, integrations, and evidence needed to move Skillset Pro from Lovable/Supabase to a self-hosted application. It is intended to help the migration owner and technical leads identify prerequisites and open decisions before implementation or cutover.

It complements:

- [Migration Owner's Guide](./SKILLSET_PRO_MIGRATION_PLAN.md) — governance, ownership, risk, backup, go/no-go, and rollback.
- [Database Migration Runbook — With Existing Data](./DATABASE_MIGRATION_WITH_DATA.md).
- [Database Setup Runbook — Start Without Existing Data](./DATABASE_MIGRATION_WITHOUT_DATA.md).

## Fact, proposal, and open-question labels

- **Current fact** means visible in the inspected project files; it may still need comparison with the live Supabase project.
- **Proposed requirement** means a technical control or capability needed for the target design.
- **Open question** means a technical or operational choice that must be answered before the related deployment or migration decision is final.

The supplied `MIGRATION_PLAN.md` and `LOVEABLE_SUPABASE_MIGRATION_BRIEF 1.md` were reviewed as references. The 1Rivet Wiki plan's Keycloak, Azure cloud hosting, MongoDB/GridFS, and empty-data decisions are product-specific and are not adopted here. Its layered-backend, API-contract, authorization, security, operations, and phased-validation topics are relevant patterns.

## 1. Current technical baseline

### Current facts from Skillset Pro project files

- Frontend is Vite, React, and TypeScript. It uses React Router, TanStack Query, Zustand, and `@supabase/supabase-js`.
- Authentication UI uses Microsoft MSAL. The current browser flow sends an ID token to the `validate-azure-token` Supabase Edge Function; that function validates the token and looks up or creates a Supabase `users` row.
- Frontend code directly calls Supabase for database reads and writes. The question store also invokes `get_question_counts`.
- Supabase Edge Functions are present for `validate-azure-token`, `evaluate-assessment`, and `generate-questions`.
- The assessment and question-generation functions currently call Lovable's hosted AI gateway.
- Local Supabase migration files and generated TypeScript database types are present. `drizzle/schema.ts` is intentionally blank, but `drizzle/migrations` contains SQL for archived-employee write protection and a type correction. Include both migration directories in the inventory and verify which changes are deployed. The live Supabase schema, RLS configuration, and data have not been independently inspected for this document.
- Existing UI route guards do not establish authorization for backend APIs.

### Approved target direction

- Preserve the existing frontend experience and framework.
- Build a Spring Boot backend and use self-hosted PostgreSQL.
- Retain Microsoft Entra ID as the identity provider.
- Plan to migrate approved existing data, as requested by the team. Confirm exact scope and acceptance criteria; an empty start requires a separate business decision.
- Decide the on-premises deployment environment and AI integration separately.

## 2. Target technical topology

```text
Users / managed browsers
          |
          | HTTPS
          v
On-prem reverse proxy / ingress
    |                         \
    | static frontend          \ /api/* (HTTPS)
    v                            v
React/Vite build             Spring Boot API
                                  |
                    +-------------+-------------+
                    |             |             |
                  Entra ID    PostgreSQL    Approved AI
                  (OIDC)       (on-prem)    gateway/provider
```

This is a logical view, not a selected product deployment. Frontend hosting, reverse proxy, application runtime, database HA, and AI connectivity still need to match the organization's on-prem standards.

## 3. Infrastructure and network requirements

### Required capabilities

- Separate development, test/staging, and production configuration and data. Avoid sharing production credentials or employee data with lower environments unless explicitly approved and protected.
- A supported host/runtime for the React static build and Spring Boot application.
- A supported self-hosted PostgreSQL service, with an application database/user separate from administrative accounts.
- Internal/external DNS and TLS certificates appropriate to user access and Entra redirect requirements.
- A reverse proxy or ingress that routes the frontend and API safely. Define request-size, timeout, and header-forwarding behavior; do not expose PostgreSQL to browsers or general networks.
- Network egress from the backend to Entra metadata/JWKS endpoints for token validation and, only if approved, to the AI endpoint. Restrict outbound access to necessary destinations.
- Firewall rules that permit only intended frontend-to-API and API-to-database traffic. Enforce TLS on user-facing endpoints and protect database connections according to organizational policy.
- A secrets-management method for database credentials, AI credentials if any, signing/configuration secrets, and operational credentials. Do not put secrets in Vite variables, source files, images, or committed `.env` files.
- Monitoring, log collection, alerting, backup storage, and a tested restore path.

### Deployment choices to resolve

| Area | Options to evaluate | Required owner input |
|---|---|---|
| Application runtime | VM/service, Docker Compose, Kubernetes/OpenShift or approved platform | Supported platform, operations ownership, patching model |
| Frontend hosting | Static files served by approved web server/reverse proxy or packaged with another approved web tier | DNS, TLS, caching, SPA fallback routing |
| API exposure | Same-origin reverse-proxy path such as `/api`, or separately hosted API hostname | CORS policy, DNS/certificates, firewall, Entra registration |
| PostgreSQL | Dedicated on-prem database host/service or approved database platform | Version, HA, capacity, backup/PITR, DBA support |
| Deployment automation | Existing CI/CD standard | Build, test, artifact storage, approvals, rollback |
| Environment availability | Single host, redundant application instances, database HA/standby | Availability target and recovery objectives |

Do not size compute/storage by guess. Measure current usage: active user concurrency, database size and growth, largest tables, query patterns, assessment peak periods, attachment/storage usage if any, and AI request volume. Set CPU, memory, disk, IOPS, and connection limits from measurements plus agreed headroom.

## 4. Backend and API requirements

### Backend service

**Proposed requirement:** one Spring Boot deployable organized as a modular monolith, unless the organization has a specific deployment constraint requiring otherwise. Keep clear boundaries for authentication/users, skills/domains, questions, assessment setup/execution/evaluation, reviews, registries, reporting/dashboard, and external integrations. Do not assume every module/resource needs a separate service.

The backend must provide:

- REST API controllers with request/response DTOs; persistence entities should not be exposed as the public contract.
- Service-layer business rules, authorization, transaction boundaries, and validation.
- A repository/data-access layer using parameterized queries and least-privilege database credentials.
- Centralized, non-sensitive API error responses and structured server-side logs with correlation/request IDs.
- Readiness/liveness or equivalent health checks that do not reveal secrets or database details.
- Configurable request/body limits, timeouts, rate limits where needed, and safe handling of duplicate/retried requests.
- Explicit API versioning/compatibility policy and an OpenAPI contract shared with the frontend team.
- Pagination/filter limits for potentially large result sets and stable sort behavior where current screens rely on it.
- Audit events for privileged operations, role changes, assessment evaluation, and data-import actions where required by policy.

### API contract and frontend integration

- Browser communicates with the backend API only for migrated application data; browser never receives database credentials or privileged service keys.
- Define a typed frontend API client, API base URL per environment, bearer token handling, request cancellation/timeout behavior, and consistent error parsing.
- Preserve existing route behavior, forms, data views, loading states, and user-facing errors except where security requires behavior changes.
- Keep contract tests or generated types synchronized with the API's OpenAPI specification.
- Establish CORS rules if the frontend and API use different origins; allow only configured origins, methods, and headers.
- Search all frontend sources, build configuration, CI variables, and deploy artifacts for leftover Supabase endpoints/keys before cutover.

The final endpoint inventory must be based on actual SDK call sites and workflows, not copied from the other project's wiki API list.

## 5. Authentication and authorization requirements

### Entra identity flow

**Current fact:** the existing login uses MSAL, then passes an ID token to a Supabase function.

**Proposed target:** register/configure the backend API audience in Entra; have the frontend obtain an access token intended for that API; have Spring Security validate the bearer token's signature, issuer, audience, expiry, and required claims. The backend derives the user identity from verified claims—not local storage, request parameters, or a caller-supplied user ID.

Required configuration and tests:

- Entra tenant/issuer and API audience/application ID URI.
- Frontend client registration, redirect/logout URIs, delegated scopes, and supported account types.
- Backend JWKS/metadata discovery, issuer and audience validation, clock-skew policy, and key-rotation behavior.
- Mapping from verified Entra tenant and object identity (`tid` plus `oid`), or an explicitly scoped subject identity, to the application user record. The current login lookup uses email; establish a reviewed crosswalk without replacing application user IDs referenced by historical records.
- New-user provisioning policy, default role, active/disabled status, and admin bootstrap/recovery process.
- Token expiration, refresh, sign-out, revoked/disabled users, and role-change behavior.
- No client secret in the browser. Do not send an ID token as API authorization unless the API registration and token semantics explicitly establish it as the correct access credential.

### Authorization

- Treat frontend route guards as UX only.
- Enforce authentication and authorization on every API read and write.
- Reconstruct the existing role, tenant, domain, ownership, assignment, and status rules from database policies and application call sites.
- Test unauthorized reads as carefully as unauthorized writes.
- Reject forged user IDs, roles, scores, employee IDs, and question/evaluation data from the client when those values must be derived from trusted server state.
- Decide whether authorization uses application database roles, Entra app roles/groups, or a defined combination. Do not assume token claims currently contain the required roles.
- Define role-change/revocation timing; a valid cached access token may remain usable until expiry unless additional revocation/introspection controls are used.

## 6. PostgreSQL schema and data requirements

### Schema readiness

- Treat the ordered Supabase migrations, SQL under `drizzle/migrations`, and an approved live schema snapshot as source evidence; reconcile differences before designing the new schema.
- Inventory tables, columns, keys, constraints, indexes, views, enums, extensions, RLS policies, SQL functions, triggers, and soft-delete/audit conventions.
- Decide which Supabase-specific features are replaced, retained temporarily, or removed, and document why.
- Use Liquibase version-controlled changelogs and uniquely identified changesets for the target; test both clean initialization and upgrade from the prior version.
- Preserve relational integrity, uniqueness, precision, and business invariants. Choose PostgreSQL-native types intentionally for UUID, JSON/JSONB, timestamps, numeric scores, and status values.
- Explicitly inspect ID defaults/sequences, triggers, time zones, collation, case-sensitive email behavior, and index coverage.
- Use schema migration roles distinct from runtime application roles where operationally supported.
- Keep development/test/prod schema versions traceable and prevent unreviewed manual production schema changes.

### Data-path specific requirements

If existing data is migrated:

- Approve table-level scope and field mappings, identity crosswalk, transformation rules, exclusions, and reconciliation tolerances.
- Use consistent source snapshots and a repeatable, restart-safe import with clear batch checkpoints.
- Test counts, key relationships, orphan records, representative workflows, identity/role mapping, and evaluation history.
- Inventory assessment state and business rules in `src/stores/adaptiveEngineStore.ts` and `src/components/assessment/AdaptiveRunner.tsx`; move authoritative scoring, progression, and completion rules into backend transactions. Decide whether in-progress attempts finish before the freeze or resume from validated persisted state, including timing and retry behavior.
- Preserve the source and verify restore before cutover; plan final snapshot/write freeze or a tested delta strategy.
- Have a documented response to partial import, rejected rows, duplicate retries, and target restore.
- Follow [DATABASE_MIGRATION_WITH_DATA.md](./DATABASE_MIGRATION_WITH_DATA.md).

If starting without legacy data:

- Prove the target can be initialized from an empty database using Liquibase migrations.
- Define and approve the minimum curated seed/reference data and initial-admin workflow.
- Test first login, user provisioning, empty-state UI, and end-to-end workflows.
- Preserve or archive the legacy source according to a separate retention decision.
- Follow [DATABASE_MIGRATION_WITHOUT_DATA.md](./DATABASE_MIGRATION_WITHOUT_DATA.md).

## 7. AI and other external integrations

**Current fact:** the Edge Functions call Lovable's hosted AI gateway for question generation and assessment evaluation.

Before any replacement calls a model, decide:

- Self-hosted model/gateway or approved external provider.
- Whether questions, employee answers, names, or other sensitive data may leave the on-prem boundary.
- Provider region, retention/training policy, contractual/privacy approval, network restrictions, budget, rate limits, and service ownership.
- Model/version change policy and how evaluation consistency is managed.
- Timeouts, retry limits, idempotency, rate-limit behavior, provider outage behavior, and auditability.
- Whether AI workflows may be disabled or use a manual fallback if approval/connectivity is unavailable.

Technical requirements:

- Make AI calls server-to-server. Keep keys in a secret store and never expose them in Vite/client bundles.
- Treat model output as untrusted input: validate schema, ranges, counts, question formats, and response size before persistence or display.
- Use trusted database questions/attempt state for evaluation; do not allow client-provided answer keys or score values to become authoritative.
- Record provider/model/version and operational metadata as policy permits, but minimize sensitive prompt/answer logging.
- Test provider failures, malformed output, rate limiting, timeouts, and retry behavior.

No separate file-storage or realtime service should be selected unless the audit confirms those features are in active use.

## 8. Security, privacy, and operations

### Security controls

- TLS at the user/API boundary; secure database transport where required by network topology.
- Least-privilege service accounts and environment-specific credentials.
- Secret rotation and emergency revocation process.
- Input validation, parameterized database access, output encoding, and safe error messages.
- Restricted CORS, request size, upload size if uploads are confirmed, and API rate limits for expensive operations.
- Server-side authorization regression tests for roles, tenant/domain boundaries, ownership, inactive users, and direct object access.
- Dependency and container/build artifact scanning under the organization's standard.
- Avoid logging tokens, passwords, database row payloads, AI prompts containing employee content, and unredacted exports.
- Define data retention, audit trail access, and secure deletion for exports/backups.

### Observability and support

- Central logs, API error rates, latency, request correlation, database health/capacity, connection pool saturation, migration/import progress, and backup job status.
- Alerts routed to a named support/on-call group.
- Readiness checks distinguish application availability from database readiness without disclosing sensitive configuration.
- Document support escalation and who may operate production database restores.

### Backup and disaster recovery

- Define RPO/RTO and retention with business owners; do not invent targets from the reference project.
- Select and configure full/incremental backup and point-in-time recovery if supported by the selected PostgreSQL platform.
- Keep backup copies separate from the primary host and restrict access.
- Test restores, not just backup creation. Record restore duration, recovered schema/data version, and validation outcomes.
- Back up target before imports and risky schema changes. Keep source recoverable through the approved rollback/retention period.
- Document recovery if Entra, DNS, secret management, or AI provider is unavailable.

## 9. CI/CD and environment configuration

Required:

- Reproducible frontend and backend builds pinned to approved toolchain versions.
- Automated backend unit/integration tests, frontend build/lint/tests, API contract checks, schema migration tests, and security-sensitive authorization tests.
- Build artifacts promoted between environments rather than rebuilt differently for production.
- Deployment approvals and auditable change history for production.
- Database migration execution with explicit permissions, logs, and a tested recovery procedure.
- Environment variables documented in a template with placeholders only; secrets supplied at runtime from an approved secret store.
- Separate frontend public configuration from backend secrets. Vite-exposed values are public by design.
- A rollback strategy for application artifacts and an independently defined database rollback/forward-fix strategy. Schema changes are not automatically reversible just because app rollback is possible.

### Configuration categories to plan

Exact names/values depend on implementation; never commit production values.

- Frontend: API base URL, Entra tenant/client IDs, API scope/audience, redirect/logout URIs.
- Backend: active profile, port/bind address, allowed origins, issuer/JWKS/audience, database URL/user/password, pool and timeout limits.
- Operations: log level, health/metrics settings, upload/request limits if relevant, proxy/trusted-header configuration.
- AI, only if approved: endpoint, model/deployment identifier, credential reference, timeout/rate limits.
- Database migration: Liquibase enablement, master changelog, DATABASECHANGELOG/DATABASECHANGELOGLOCK history, and migration user/connection. Keep drop-first and checksum clearing disabled.

## 10. Required technical evidence before go-live

- [ ] Complete Supabase feature/call-site and schema/RLS/function inventory with disposition for each feature.
- [ ] API contract and frontend integration tested against a staging backend.
- [ ] Entra access-token validation and user provisioning verified end-to-end.
- [ ] Server-side authorization tests pass for permitted and forbidden reads and writes.
- [ ] Clean schema initialization and schema upgrade tests pass.
- [ ] Data import reconciliation and failure/restart drill pass if migrating data; otherwise clean-start/seed proof passes.
- [ ] Backup and restore tested for both source retention needs and new target.
- [ ] AI endpoint/data handling is approved or AI functions have an explicit disabled/manual behavior.
- [ ] Logs, metrics, alerts, health checks, and support ownership are ready.
- [ ] TLS, DNS, CORS, firewall, secret management, and environment separation are verified.
- [ ] Production deployment, application rollback, database recovery, and user communications are rehearsed.

## 11. Technical decisions still open

Track each with an owner, due gate, decision, and rationale:

1. On-prem platform and frontend/API hosting topology.
2. PostgreSQL version, HA/backup platform, capacity, and operational DBA ownership.
3. API hostname/origin strategy and Entra API registration details.
4. Application roles: database-managed, Entra-managed, or hybrid; user onboarding and first-admin process.
5. Data path and exact included/excluded record scope.
6. AI gateway/provider and employee-data handling.
7. Whether any Supabase storage/realtime service is actually used and needs a replacement.
8. Availability target, RPO/RTO, backup retention, and audit retention.
9. CI/CD and production change-approval standard.
10. Source system archive/decommission date and access after cutover.

## Reference usage note

The attached general migration brief informs the audit discipline: ground claims in repository/database evidence, distinguish facts from proposals/open questions, inventory actual SDK calls, and examine read authorization separately from write authorization. The 1Rivet Wiki migration plan informs document structure and layered architecture considerations only. Its identity provider, storage technology, cloud hosting, data decision, endpoints, scale, and feature inventory must not be copied into Skillset Pro without separate evidence and approval.
## Liquibase baseline and change-tracking procedure

- The backend uses liquibase-core and spring.liquibase.change-log pointing to
  db/changelog/db.changelog-master.yaml. The current master contains no changesets.
- Validate the deployed schema read-only before writing changes/001-initial-schema.yaml.
  A generated changelog is a draft; inspect unsupported objects and Supabase dependencies separately.
- Explicitly include approved files in dependency order. Keep author/id/path identifiers stable.
  Do not rewrite applied shared-environment changesets or clear checksums to hide differences.
- For a fresh target, apply the baseline to create objects before the controlled business-data import.
  Do not use changelog-sync to initialize an empty target: it records execution without creating objects.
- DATABASECHANGELOG and DATABASECHANGELOGLOCK track schema execution, not all database drift
  or business-data changes. Retain schema comparisons, reconciliation and tested backup/recovery.
- Test parsing/validation, generated SQL review, clean PostgreSQL initialization, repeated execution,
  upgrades and failure recovery. Foundation tests alone do not establish PostgreSQL compatibility.
- Use the backend's docs/LIVE_DATABASE_VALIDATION.md and read-only schema inventory script
  to collect source evidence; never start the backend against the live source for inspection.
