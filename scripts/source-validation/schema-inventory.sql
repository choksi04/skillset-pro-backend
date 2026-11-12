-- Run only with approved source inspection access. No employee rows are returned.
BEGIN TRANSACTION READ ONLY;
SET LOCAL statement_timeout = '30s';
SET LOCAL lock_timeout = '3s';

SELECT current_database() AS database_name,
       current_user AS inspection_role,
       current_timestamp AS inspected_at,
       current_setting('server_version') AS postgres_version;

-- Application objects; extend only to approved custom schemas discovered during review.
SELECT table_schema, table_name, table_type
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

SELECT table_schema, table_name, ordinal_position, column_name,
       data_type, udt_name, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'public'
ORDER BY table_name, ordinal_position;

SELECT ns.nspname AS schema_name, cls.relname AS table_name,
       con.conname AS constraint_name, con.contype AS constraint_type,
       pg_get_constraintdef(con.oid) AS definition, con.convalidated AS validated
FROM pg_constraint con
JOIN pg_class cls ON cls.oid = con.conrelid
JOIN pg_namespace ns ON ns.oid = cls.relnamespace
WHERE ns.nspname = 'public'
ORDER BY cls.relname, con.conname;

SELECT schemaname, tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

SELECT ns.nspname AS schema_name, cls.relname AS table_name,
       cls.relrowsecurity AS rls_enabled, cls.relforcerowsecurity AS rls_forced
FROM pg_class cls
JOIN pg_namespace ns ON ns.oid = cls.relnamespace
WHERE ns.nspname = 'public' AND cls.relkind IN ('r', 'p')
ORDER BY cls.relname;

SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

SELECT ns.nspname AS schema_name, cls.relname AS table_name,
       tr.tgname AS trigger_name, pg_get_triggerdef(tr.oid) AS definition,
       tr.tgenabled AS enabled
FROM pg_trigger tr
JOIN pg_class cls ON cls.oid = tr.tgrelid
JOIN pg_namespace ns ON ns.oid = cls.relnamespace
WHERE ns.nspname = 'public' AND NOT tr.tgisinternal
ORDER BY cls.relname, tr.tgname;

SELECT ns.nspname AS schema_name, proc.proname AS routine_name,
       pg_get_function_identity_arguments(proc.oid) AS arguments,
       proc.prokind AS routine_kind, proc.prosecdef AS security_definer
FROM pg_proc proc
JOIN pg_namespace ns ON ns.oid = proc.pronamespace
WHERE ns.nspname = 'public'
ORDER BY proc.proname, arguments;

SELECT grantee, table_schema, table_name, privilege_type
FROM information_schema.table_privileges
WHERE table_schema = 'public'
ORDER BY table_name, grantee, privilege_type;

SELECT ns.nspname AS schema_name, typ.typname AS enum_name, en.enumlabel
FROM pg_type typ
JOIN pg_namespace ns ON ns.oid = typ.typnamespace
JOIN pg_enum en ON en.enumtypid = typ.oid
WHERE ns.nspname = 'public'
ORDER BY typ.typname, en.enumsortorder;

SELECT extname, extversion FROM pg_extension ORDER BY extname;

-- Check schema existence first; inspect its tables/history separately with owner approval.
SELECT schema_name
FROM information_schema.schemata
WHERE schema_name IN ('supabase_migrations', 'drizzle');

COMMIT;
