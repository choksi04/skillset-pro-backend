# Schema changesets

The initial target schema is pending live-source validation. Do not add placeholder tables.

After approval, add 001-initial-schema.yaml and explicitly include it in the master.
Use unique author/id pairs and stable file paths. Add new changesets for corrections
after deployment to a shared environment; do not rewrite applied changesets or clear
checksums to hide mismatches. Use preconditions and review rollback/recovery plans.

Schema changesets are separate from the controlled historical-data import.
