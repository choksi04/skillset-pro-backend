\set ON_ERROR_STOP on
\encoding UTF8
BEGIN TRANSACTION READ ONLY;
SET LOCAL statement_timeout = '60s';
SET LOCAL search_path = pg_catalog, public;
WITH application_tables AS (
 SELECT c.oid, c.relname, c.relkind, c.relrowsecurity, c.relforcerowsecurity
 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
 WHERE n.nspname='public' AND c.relkind IN ('r','p')
 AND c.relname NOT IN ('databasechangelog','databasechangeloglock')
), sections AS (
 SELECT 'tables' AS section, t.relname::text AS key,
        jsonb_build_object('kind',t.relkind,'rls_enabled',t.relrowsecurity,
          'rls_forced',t.relforcerowsecurity) AS definition
 FROM application_tables t
 UNION ALL
 SELECT 'columns', t.relname || '.' || a.attname,
        jsonb_build_object('position',a.attnum,'type',format_type(a.atttypid,a.atttypmod),
          'not_null',a.attnotnull,'default',pg_get_expr(d.adbin,d.adrelid,false),
          'identity',a.attidentity,'generated',a.attgenerated,
          'collation',CASE WHEN a.attcollation=0 THEN NULL ELSE
             (SELECT n.nspname || '.' || co.collname FROM pg_collation co
              JOIN pg_namespace n ON n.oid=co.collnamespace WHERE co.oid=a.attcollation) END)
 FROM application_tables t JOIN pg_attribute a ON a.attrelid=t.oid
 LEFT JOIN pg_attrdef d ON d.adrelid=t.oid AND d.adnum=a.attnum
 WHERE a.attnum>0 AND NOT a.attisdropped
 UNION ALL
 SELECT 'constraints', t.relname || '.' || c.conname,
        jsonb_build_object('type',c.contype,'definition',pg_get_constraintdef(c.oid,false),
          'validated',c.convalidated,'deferrable',c.condeferrable,'deferred',c.condeferred)
 FROM application_tables t JOIN pg_constraint c ON c.conrelid=t.oid
 UNION ALL
 SELECT 'indexes', t.relname || '.' || x.relname,
        jsonb_build_object('definition',pg_get_indexdef(x.oid,0,false),
          'valid',i.indisvalid,'ready',i.indisready)
 FROM application_tables t JOIN pg_index i ON i.indrelid=t.oid
 JOIN pg_class x ON x.oid=i.indexrelid
 UNION ALL
 SELECT 'functions', p.proname || '(' || pg_get_function_identity_arguments(p.oid) || ')',
        jsonb_build_object('definition',pg_get_functiondef(p.oid))
 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
 WHERE n.nspname='public' AND p.prokind IN ('f','p')
 AND NOT EXISTS (SELECT 1 FROM pg_depend d
                 WHERE d.classid='pg_proc'::regclass AND d.objid=p.oid AND d.deptype='e')
 UNION ALL
 SELECT 'triggers', t.relname || '.' || tr.tgname,
        jsonb_build_object('definition',pg_get_triggerdef(tr.oid,false),'enabled',tr.tgenabled)
 FROM application_tables t JOIN pg_trigger tr ON tr.tgrelid=t.oid
 WHERE NOT tr.tgisinternal
)
SELECT jsonb_build_object(
 'format_version',1,
 'database',current_database(),
 'server_version',current_setting('server_version'),
 'sections',(SELECT jsonb_object_agg(section,items) FROM (
    SELECT section,jsonb_agg(jsonb_build_object('key',key,'definition',definition) ORDER BY key) AS items
    FROM sections GROUP BY section
 ) grouped)
);
COMMIT;
