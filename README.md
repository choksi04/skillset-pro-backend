# Skillset Pro Backend

Backend repository for the Skillset Pro migration from Supabase to a Spring Boot API backed by self-hosted PostgreSQL.

## Status

Repository initialized. Application implementation and build configuration have not been added yet.

## Planned responsibilities

- Validate Microsoft Entra ID API access tokens and enforce server-side authorization.
- Provide REST APIs for users, domains, skills, questions, assessments, reviews, registries, and reporting.
- Manage the target PostgreSQL schema through Flyway migrations.
- Provide repeatable tooling to import and reconcile approved existing data.
- Integrate with an approved AI provider for question generation and assessment evaluation.

## Related repository

[Skillset Pro Frontend](https://github.com/choksi04/skillset-pro-frontend)

## Configuration

Runtime versions, setup commands, and environment configuration will be documented when the backend is initialized. Keep credentials, database exports, and employee data out of this repository.
