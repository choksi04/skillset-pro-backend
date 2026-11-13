# Backend development and API contract

Updated 2026-11-13.
[Setup](../README.md) | [Migration and recovery](MIGRATION.md)

## Implemented endpoints

| Method | Route | Access / result |
| --- | --- | --- |
| GET | /actuator/health | Public, standard health response with hidden internal details |
| GET | /api/v1/skills | Authenticated skills reader; paged non-deleted skills in the application tenant |
| GET | /api/v1/skills/count | Same access and filters as the list; returns a count |
| GET | /api/v1/skills/{id} | Same access; one visible skill or 404 |

Health subpaths are also public. All other requests require authentication.
Local OpenAPI/Swagger routes are authenticated and enabled only in the local profile.
Category/topic and business write endpoints have not been implemented.

Application responses use GenericResponse<T>:

~~~json
{
  "data": {
    "items": [],
    "page": 0,
    "size": 20,
    "totalElements": 0,
    "totalPages": 0
  },
  "error": null
}
~~~

Count data is a number; detail data is one SkillDto.
Errors return null data and a safe error string with the appropriate HTTP status.
Actuator and OpenAPI retain their standard formats.

### Skills request contract

| Parameter | Routes | Behavior |
| --- | --- | --- |
| page | List | Zero-based, default 0; must be at least 0 |
| size | List | Default 20; range 1..100 |
| search | List/count | Optional literal substring of skill name, case-insensitive, maximum 200 characters; blank means no search |
| categoryId | List/count | Optional exact category ID, nonblank if supplied, maximum 200 characters |
| status | List/count | Optional active or disabled |
| id | Detail path | Existing text ID; do not enforce UUID format |

Ordering is creation time ascending, then ID ascending for stable pagination.
Search treats %, _ and backslash literally rather than as user-supplied LIKE wildcards.
Filtering uses category_id, never the denormalized category display name.
Every query applies tenant_id equality and deleted_on IS NULL.
A missing, soft-deleted or cross-tenant detail returns the same 404.

Skill DTO JSON fields preserve the frontend's existing names:

~~~text
id, tenant_id, skill_name, skill_description, category_id, skill_category,
tags, status, created_at, updated_at
~~~

Tags remain an array. Nullable description/category values normalize to empty strings,
matching the frontend store. Dates use timezone-aware values.
No persistence entities or audit actor identities are exposed as the API response.
The frontend has not yet been switched to this contract; its current Supabase calls remain.

### Response statuses

| Status | Meaning |
| --- | --- |
| 200 | Successful list/count/detail |
| 400 | Invalid page/size/type/filter or request body |
| 401 | Missing/invalid bearer token |
| 403 | Missing read scope or required application tenant mapping |
| 404 | Missing or invisible record |
| 500 | Unexpected failure; configured generic message, no internal exception payload |

## Authentication boundary and deferred identity work

The resource server is configured for JWT validation using an issuer and audience.
The skills controller and service require SCOPE_skills.read through a shared authority constant.
The provisional TenantContext accepts a nonblank string app_tenant_id only from the
validated JWT principal. It rejects missing/malformed mapping with 403.

It never uses a request tenant header/parameter, defaults to tenant-001, or interprets Entra
tid as an application tenant. A client cannot override the token tenant. JWT mocks are
test-only; do not create unsigned tokens or disable security for manual endpoint testing.

This contract is a development boundary, not completed Entra login/authorization integration.
Before using real users, the identity/security owners must define and test:

1. Backend API registration, issuer, audience, delegated access-token scopes and frontend token acquisition.
2. Trusted issuer-side app_tenant_id provisioning, or replacement with a server-side application-user/tenant lookup.
3. Unique verified Entra tid/oid-to-users.id mapping; preserve historical application text IDs.
4. Application roles, domain/ownership checks, unmapped-user handling, disabled/archived users,
   onboarding, first-admin recovery and permission/revocation timing.
5. Token expiry, wrong issuer/audience, signing-key rotation, denied reads and forged identity inputs.

Do not match identities solely by email or use an ID token as a substitute for the backend API
access token. Frontend route guards are UX only. Scopes do not automatically establish
application roles or active-user status.

The database baseline retains RLS with no permissive source policies. Decide least-privilege
runtime grants/RLS separately from migration ownership, including SECURITY DEFINER function
ownership, search_path and execution grants. Owner-based container tests do not prove ordinary
runtime-role permissions or final row-level security.

## Implementation conventions

Use the teammate's java-spring-enterprise-standards instructions, adapted to this application's
actual PostgreSQL schema. Keep the Java 17 target and package com.skillsetpro.
Do not copy unrelated Keycloak, SQL Server, API-key or workflow-engine examples into this app.

| Layer | Responsibility |
| --- | --- |
| controllers | Plural versioned routes, OpenAPI operations/security metadata, input validation, response envelope |
| services | Small business service interfaces |
| services/impl | Constructor-injected implementations, authorization and transaction boundaries |
| repositories | Spring Data JPA persistence and reusable query specifications |
| model/entities | Schema-compatible JPA mappings; immutable Skill for this read-only slice |
| model/records and model/mappers | Immutable DTO/page/filter contracts and entity-to-DTO mapping |
| model/responses | GenericResponse<T> |
| exceptions | Domain exception hierarchy and safe centralized error handling |
| security | Trusted application tenant/identity resolution |
| config and config/security | Typed properties, CORS, OpenAPI and resource-server configuration |
| utils | Shared authority constants and genuinely cross-cutting helpers |

Use interface/implementation pairs for every business service; controllers depend on interfaces.
Use constructor injection and explicit DTO mapping. Keep database queries out of controllers.
Use Specifications for composable filters and bound query values; never concatenate request
values into SQL. Every list needs bounded pagination, stable order and a count route with
identical visibility/filter rules. Check tenant/ownership on detail reads as well as writes.

Use read-only transactions for reads. Write transactions and retries must preserve business
invariants and idempotency; no write APIs exist yet. Add caches/jobs only when a concrete need
exists. Include tenant/access context in cache keys, call cached methods through Spring proxies,
and test invalidation/revocation.

The current Skill entity maps 15 existing columns and extends the mapped Auditable base.
Historical nullable fields are preserved. Write-side auditing is not enabled until application
identity resolution is designed; it must not stamp imported history or assume every table has
the same mandatory audit fields. Do not derive audit actors from client request fields.

Liquibase owns DDL; Hibernate validates it. Add new uniquely identified changesets for future
schema changes. Keep the five applied 001 changesets unchanged.
See [the schema lifecycle](MIGRATION.md#liquibase-schema-lifecycle).

Secrets belong in runtime configuration/approved secret storage. Vite values are public.
Never log bearer tokens, employee row payloads, passwords or sensitive AI prompts.
Maintain safe errors, configured CORS and issuer/audience validation.

## Test strategy and completed verification

Latest local verification on 2026-11-13:

| Check | Result |
| --- | --- |
| Maven verify | BUILD SUCCESS |
| Tests | 38 passed; zero failures, zero errors, zero skipped |
| PostgreSQL repository tests | Both ran successfully against a disposable PostgreSQL 18 container |
| Line coverage | 98.18%; required minimum 80% |
| Formatting and packaging | Passed |
| Real Entra integration / Java 17 CI | Separate verification still required |

Test classes and scope:

- FoundationTest: health, JWT rejection, response/error handling, CORS, security and OpenAPI.
- SkillControllerTest: endpoint contract, filtering/pagination forwarding, request validation,
  missing-token 401 and missing-scope 403.
- SkillServiceTest: mapping, pagination, repository access, not-found and tenant-context failure.
- TenantContextTest: missing/invalid tenant rejection and no Entra-directory-ID fallback.
- SkillAccessTest: controller/service security together; no database query without tenant/scope;
  request tenant cannot override trusted context.
- LiquibaseChangelogTest: default application master remains intentionally empty.
- DevelopmentBaselineTest: offline generated baseline shape and exclusions.
- SkillRepositoryPostgresTest: actual development changelog plus Hibernate validation, tenant/
  soft-delete filtering, exact category IDs, PostgreSQL text arrays, LIKE escaping and pagination/counts.

Use JUnit/Mockito service tests, MVC/controller tests with denied access, and real PostgreSQL
integration tests for persistence behavior. Testcontainers uses synthetic data and does not
target the three preserved local databases. Do not substitute an in-memory database for
PostgreSQL-specific SQL/array/RLS behavior.

Docker Desktop must be running with Linux containers. A successful build with the two
PostgreSQL tests skipped is incomplete database verification. Maven tests start in UTC through
Surefire argLine while keeping the JaCoCo agent. This resolved the observed Asia/Calcutta
startup-parameter rejection. No OS timezone change or database workaround is required.

Run the [verification command](../README.md#toolchain-and-verification) after each slice.
CI verifies using Java 17 and requires Docker; local checks on JDK 24 do not replace that result.
The coverage gate excludes only the application launcher.

## Next development sequence

1. Review and push the current backend checkpoint, including documentation consolidation.
2. Implement read-only skill-category list/count/detail using existing text IDs and actual
   category fields. Include tenant, soft-delete, scope, validation and PostgreSQL tests.
3. Implement read-only skill-topic list/count/detail scoped to both skill and application tenant.
4. Prepare a typed frontend API client, environment-specific API base URL, error handling,
   cancellation/timeouts and contract types. Complete trusted identity/token integration before
   real authenticated end-to-end use. Keep UI routes/loading/error states consistent.
5. Add domains/questions and then assessment/registry/review workflows in small tested slices,
   based on actual frontend SDK calls. Move authoritative scoring, progression and completion
   rules from adaptiveEngineStore/AdaptiveRunner into backend transactions.
6. Add writes only with identity/authorization, audit, concurrency and business-rule acceptance.
7. Stage full workflows, operations and cutover acceptance before replacing the live application.

Categories/topics are planned; their exact route/DTO contracts are not finalized by this document.
Do not describe future endpoints as available.

Broader integration work must replace the three Supabase Edge Functions (user validation,
question generation and evaluation) deliberately. AI provider/model, data residency, retention,
training use, cost and employee-data handling require owner approval. Keep AI calls server-side;
validate outputs, use trusted stored attempt/question state, record model/version as allowed,
and test timeouts, rate limits, malformed responses and duplicate retries.
Historical AI evaluations must remain unchanged, not regenerated during migration.

Inventory storage/realtime usage before selecting replacements. At frontend cutover, remove
remaining direct Supabase data calls, obsolete endpoints/keys and Edge Function dependencies
from source, configuration and built artifacts; this has not been completed yet.
