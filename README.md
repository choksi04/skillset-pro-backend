# Skillset Pro Backend

Backend repository for the Skillset Pro migration from Supabase to a Spring Boot API backed by self-hosted PostgreSQL.

## Status

Spring Boot foundation initialized. Business APIs, application-user mapping, and source-data migration are not implemented yet.

## Planned responsibilities

- Validate Microsoft Entra ID API access tokens and enforce server-side authorization.
- Provide REST APIs for users, domains, skills, questions, assessments, reviews, registries, and reporting.
- Manage the target PostgreSQL schema through Flyway migrations.
- Provide repeatable tooling to import and reconcile approved existing data.
- Integrate with an approved AI provider for question generation and assessment evaluation.

## Related repository

[Skillset Pro Frontend](https://github.com/choksi04/skillset-pro-frontend)

## Configuration

Keep credentials, database exports, and employee data out of this repository. See `.env.example` for configuration names and `docs/BACKEND_STANDARDS.md` for implementation conventions.
## Toolchain and verification

- Java 17 target; CI uses Temurin 17. Use a JDK 17 installation for the team baseline.
- Spring Boot 3.5.16 and Maven 3.9.16 (downloaded by the included Maven Wrapper).
- Local verification may run on a newer compatible JDK while compiling with release 17;
  this does not replace the Java 17 CI run.

From this folder in PowerShell:

```powershell
.\mvnw.cmd --batch-mode --no-transfer-progress verify
```

Verification checks Java formatting, runs foundation tests, enforces 80% line coverage,
and packages the application. It does not require PostgreSQL or an Entra connection.
On Linux/macOS use `bash mvnw verify`. To apply Java formatting: `.\mvnw.cmd spotless:apply`.
Reports are under `target/surefire-reports` and `target/site/jacoco`.

## Local application startup

Do not point this application at the existing production database. First provision an
isolated development PostgreSQL database and approve an Entra backend API registration.

Set `DB_URL`, `DB_USERNAME`, `DB_PASSWORD`, `ENTRA_ISSUER_URI`, and `ENTRA_AUDIENCE`
as process environment variables or in your IDE. A shell-style `.env` is not loaded
implicitly. The issuer must identify the approved Entra tenant and token version; the
audience must match the backend API access token, not an ID token. Optionally set
`CORS_ALLOWED_ORIGINS` to a comma-separated list (for example, `http://localhost:8080`).

Then run:

```powershell
.\mvnw.cmd spring-boot:run '-Dspring-boot.run.profiles=local'
```

Default backend port: 8081. `/actuator/health` is public and hides internal details.
Local OpenAPI endpoints are enabled but still require a bearer token; they are disabled
in the base configuration. All other requests require authentication. Fine-grained role,
user status and tenant checks will be added with the first business workflow.

Flyway is enabled, clean is disabled, and Hibernate uses `ddl-auto: validate`. No schema
migration files are included until the live schema and source-to-target mapping are
reviewed. Startup requires a reachable development database and valid Entra settings.

## Next milestone

Validate the live source schema and identity crosswalk, then implement the application
user lookup and first authenticated API. Preserve existing IDs and audit history in the
migration design. Add business services as interface/implementation pairs and test
permissions and PostgreSQL queries as those features are introduced.
