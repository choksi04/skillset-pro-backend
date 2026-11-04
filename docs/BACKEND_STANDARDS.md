# Backend conventions

Follow the team's java-spring-enterprise-standards skill for Java 17 / Spring Boot 3.

- Base package: com.skillsetpro. Use the skill's technical-layer packages as classes are added.
- Every business service has an interface and implementation with constructor injection.
- Controllers use OpenAPI annotations, validated request DTOs, and permission constants.
- Application responses use GenericResponse<T>; Actuator/OpenAPI keep their standard formats.
- Entra API tokens require issuer, audience and timestamp validation. Scopes are not
  application roles; user/tenant/permission mapping is the next identity milestone.
- Flyway owns schema changes; Hibernate validates. Do not apply source SQL automatically.
- Add Auditable/JPA auditing after schema and identity mapping are validated; preserve
  historical audit fields during import.
- Services need JUnit/Mockito tests; controllers need MVC tests including denied access
  and invalid input; custom queries need PostgreSQL integration tests.
- CI enforces formatting and 80% line coverage; only the application launcher is excluded.
- Use process/IDE environment variables or a secret manager. A shell-style .env is not
  loaded automatically. Never commit secrets or database exports.
- Add caches/jobs only when required; include tenant/access context in cache keys and
  invoke cached methods through a Spring proxy. Test invalidation and revocation.
- Do not copy Keycloak, SQL Server, API-key or workflow-engine examples into this app.

Foundation tests mock decoding and disable persistence auto-configuration. Real Entra
token validation and PostgreSQL/Flyway integration remain required before business go-live.
