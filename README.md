# Skillset Pro Backend

Updated 2026-11-13. Start here for the current setup.
The project is migrating the existing React/Vite application and its data from Supabase
to a Spring Boot API and self-hosted PostgreSQL. Authentication integration remains deferred.

## Documentation

Only these three Markdown files are maintained in this backend repository:

| Document | Purpose |
| --- | --- |
| [README.md](README.md) | Current status, repository structure, configuration, build and startup |
| [Migration and recovery](docs/MIGRATION.md) | Confirmed database checkpoint, scope, runbook, evidence, decisions and production gates |
| [Backend development](docs/BACKEND_DEVELOPMENT.md) | API contract, authorization boundary, coding standards, tests and next implementation steps |

Earlier overlapping plans have been consolidated. Executable SQL/PowerShell, CSV inventories,
archive-selection manifests and Liquibase definitions remain in their existing folders.
Original planning prose is archived outside Git; it is historical context, not current instructions.

## Current status

| Area | Status |
| --- | --- |
| Backend foundation | Spring Boot, resource-server security, validation, error envelope, health, OpenAPI and CI implemented |
| Database baseline | Five development Liquibase changesets applied; 31 application tables |
| Historical data | 96,106 records imported and verified against rehearsal using all-column table fingerprints |
| Recovery | Development backup restored into a third database; all 31 counts/fingerprints matched |
| Skills read API | List, count and detail implemented with tenant and soft-delete filtering |
| Latest verification | 38 tests passed, zero failures/errors/skipped; 98.18% line coverage |
| Identity integration | Deferred; no completed Entra-to-application-user/role mapping |
| Frontend integration | New Java API has not replaced the frontend Supabase calls yet |
| Production readiness | Pending business, security, infrastructure, identity and cutover acceptance |

Database migration results are based on the user's terminal evidence.
The latest Maven verification was run directly on 2026-11-13 using a disposable PostgreSQL
18 container. Local checks compiled for Java 17 while running on JDK 24.0.2;
the Java 17 CI result must also pass before merge.

## Repositories and structure

- Backend: [skillset-pro-backend](https://github.com/choksi04/skillset-pro-backend)
- Frontend: [skillset-pro-frontend](https://github.com/choksi04/skillset-pro-frontend)
- Original reference checkout: skillset-pro-main; keep its existing application code unchanged.

Run backend commands from the backend repository, not the original reference checkout.

| Path | Contents |
| --- | --- |
| src/main/java/com/skillsetpro | Controllers, service interfaces/implementations, repositories, entities/DTOs, security and configuration |
| src/main/resources | Application YAML and Liquibase changelogs |
| src/test | Foundation, API, security, service, changelog and PostgreSQL integration tests |
| scripts/source-validation | Read-only source schema inventory |
| scripts/restore-rehearsal | Reviewed archive selection, bootstrap and rehearsal validation |
| scripts/liquibase | Development-only schema runner |
| scripts/schema-comparison | Read-only schema snapshots/comparison |
| scripts/data-import | Controlled import order, guards, transaction finalizer and validation |
| scripts/data-validation | Table fingerprints, comparison and checkpoint backup |
| docs/schema-reference | Non-row CSV column/source-migration/live-metadata inventories |
| .github/workflows/ci.yml | Java 17 verification and report artifacts |

## Toolchain and verification

- Java 17 is the team/CI baseline; Spring Boot 3.5.16.
- Maven Wrapper downloads Maven 3.9.16.
- PostgreSQL 18.4 is the reported local migration server; integration tests use a disposable PostgreSQL 18 container.
- Docker Desktop must be running with Linux containers for complete integration verification.
- PostgreSQL client executables are expected under C:\Program Files\PostgreSQL\18\bin by migration helpers.

From the backend folder in PowerShell:

~~~powershell
docker info
.\mvnw.cmd --batch-mode --no-transfer-progress verify
~~~

On Linux/macOS: bash mvnw --batch-mode --no-transfer-progress verify.

Verification checks formatting, runs tests, enforces at least 80% line coverage and packages
the application. Expected current result: 38 tests, zero failures, zero errors, zero skipped.
Without Docker, the two PostgreSQL tests are skipped; a successful build with skips is not
complete database verification. CI checks Docker availability before running verify.

The PostgreSQL tests apply the real development Liquibase baseline in a disposable container
and use synthetic fixtures. They do not target rehearsal, development or recovery databases.
Foundation/MVC tests mock JWT decoding and do not prove real Entra integration.

Surefire starts the test JVM in UTC while preserving the JaCoCo agent. This fixes the observed
PostgreSQL connection rejection of the host Asia/Calcutta timezone alias; it does not change
the operating-system timezone or application runtime configuration.

Reports: target/surefire-reports and target/site/jacoco.
Apply Java formatting when needed:

~~~powershell
.\mvnw.cmd spotless:apply
~~~

## Configuration and startup

The application is not yet verified end-to-end with real user tokens.
Continue API implementation/tests while identity integration is deferred.

Set configuration through process environment variables, IDE settings or an approved secret
manager. A shell-style .env file is not loaded automatically. [.env.example](.env.example)
contains placeholders; its sample database name is illustrative. For this project's migrated
local development database use the actual name below.

| Variable | Current meaning |
| --- | --- |
| DB_URL | jdbc:postgresql://127.0.0.1:5432/skillset_pro_backend_dev for isolated local development only |
| DB_USERNAME | Approved local credential; skillset_dev_owner is the current migration owner, not a finalized production runtime role |
| DB_PASSWORD | Supplied securely; never place real credentials in Markdown or command history |
| ENTRA_ISSUER_URI | Approved tenant/token-version issuer; final integration pending |
| ENTRA_AUDIENCE | Backend API access-token audience; final registration pending |
| CORS_ALLOWED_ORIGINS | Configured frontend origins, for example http://localhost:8080 |
| SERVER_PORT | Optional; defaults to 8081 |

After provisioning valid settings, the existing local startup command is:

~~~powershell
.\mvnw.cmd spring-boot:run '-Dspring-boot.run.profiles=local'
~~~

Only /actuator/health and its health subpaths are public; internal health details are hidden.
Local OpenAPI/Swagger endpoints are enabled but authenticated; base configuration disables them.
Business endpoints always require authentication. There is no local authentication bypass.

Hibernate uses ddl-auto=validate. Liquibase is enabled with drop-first and checksum clearing
disabled. The default application changelog is deliberately empty. The five applied baseline
changesets belong to the separate development changelog and liquibase-dev profile.
Starting the application does not automatically select that development changelog.
Do not edit already-applied changesets or silently wire a migration runner into startup.
See [schema lifecycle](docs/MIGRATION.md#liquibase-schema-lifecycle).

RLS remains enabled with no copied source policies. The current owner-based migration tests
do not establish access for a future ordinary runtime role. Runtime grants/RLS and user/status/
role mapping must be designed before deployment.

## Next action and Git checkpoint

The next implementation slice is skill-category reads, followed by skill-topic reads.
See the [development sequence](docs/BACKEND_DEVELOPMENT.md#next-development-sequence).
Do not rerun completed data imports or restore over validated databases as part of API work.

Before pushing, inspect the working tree and selected diff. Commit application code/tests,
configuration, the three documents, scripts and approved metadata/manifests together.
Keep generated SQL containing employee data, backups, fingerprints, checkpoint JSON, secrets
and logs outside Git. Existing ignore rules are defense in depth; inspect staged paths.

~~~powershell
git status --short
git diff --stat
git diff --cached --stat
~~~

Documentation consolidation does not perform a commit, push, database change or source checkout edit.
