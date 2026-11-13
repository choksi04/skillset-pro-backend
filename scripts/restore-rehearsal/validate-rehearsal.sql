-- ISOLATED REHEARSAL DATABASE ONLY. Aggregates/metadata only.
\set ON_ERROR_STOP on
BEGIN TRANSACTION READ ONLY;
SET LOCAL statement_timeout = '60s';

WITH counts(table_name, expected_rows, actual_rows) AS (
  SELECT 'ai_evaluations', 15744::bigint, (SELECT count(*) FROM public.ai_evaluations)
  UNION ALL
  SELECT 'assessment_assignments', 501::bigint, (SELECT count(*) FROM public.assessment_assignments)
  UNION ALL
  SELECT 'assessment_attempts', 479::bigint, (SELECT count(*) FROM public.assessment_attempts)
  UNION ALL
  SELECT 'assessment_config', 3::bigint, (SELECT count(*) FROM public.assessment_config)
  UNION ALL
  SELECT 'assessment_questions', 16325::bigint, (SELECT count(*) FROM public.assessment_questions)
  UNION ALL
  SELECT 'assessment_template_questions', 246::bigint, (SELECT count(*) FROM public.assessment_template_questions)
  UNION ALL
  SELECT 'assessment_template_skills', 524::bigint, (SELECT count(*) FROM public.assessment_template_skills)
  UNION ALL
  SELECT 'assessment_templates', 78::bigint, (SELECT count(*) FROM public.assessment_templates)
  UNION ALL
  SELECT 'assessments', 501::bigint, (SELECT count(*) FROM public.assessments)
  UNION ALL
  SELECT 'attempt_answers', 15907::bigint, (SELECT count(*) FROM public.attempt_answers)
  UNION ALL
  SELECT 'attempt_skill_scores', 3549::bigint, (SELECT count(*) FROM public.attempt_skill_scores)
  UNION ALL
  SELECT 'competency_levels', 5::bigint, (SELECT count(*) FROM public.competency_levels)
  UNION ALL
  SELECT 'domain_skill_mappings', 490::bigint, (SELECT count(*) FROM public.domain_skill_mappings)
  UNION ALL
  SELECT 'domains', 15::bigint, (SELECT count(*) FROM public.domains)
  UNION ALL
  SELECT 'employee_domain_assignments', 0::bigint, (SELECT count(*) FROM public.employee_domain_assignments)
  UNION ALL
  SELECT 'manager_reviews', 447::bigint, (SELECT count(*) FROM public.manager_reviews)
  UNION ALL
  SELECT 'notifications', 1622::bigint, (SELECT count(*) FROM public.notifications)
  UNION ALL
  SELECT 'official_skill_entries', 69::bigint, (SELECT count(*) FROM public.official_skill_entries)
  UNION ALL
  SELECT 'questions', 23491::bigint, (SELECT count(*) FROM public.questions)
  UNION ALL
  SELECT 'reassessment_requests', 0::bigint, (SELECT count(*) FROM public.reassessment_requests)
  UNION ALL
  SELECT 'registry_review_items', 68::bigint, (SELECT count(*) FROM public.registry_review_items)
  UNION ALL
  SELECT 'registry_reviews', 127::bigint, (SELECT count(*) FROM public.registry_reviews)
  UNION ALL
  SELECT 'review_skill_entries', 3545::bigint, (SELECT count(*) FROM public.review_skill_entries)
  UNION ALL
  SELECT 'skill_categories', 93::bigint, (SELECT count(*) FROM public.skill_categories)
  UNION ALL
  SELECT 'skill_registries', 510::bigint, (SELECT count(*) FROM public.skill_registries)
  UNION ALL
  SELECT 'skill_registry_items', 9721::bigint, (SELECT count(*) FROM public.skill_registry_items)
  UNION ALL
  SELECT 'skill_registry_submissions', 0::bigint, (SELECT count(*) FROM public.skill_registry_submissions)
  UNION ALL
  SELECT 'skill_self_ratings', 0::bigint, (SELECT count(*) FROM public.skill_self_ratings)
  UNION ALL
  SELECT 'skill_topics', 1183::bigint, (SELECT count(*) FROM public.skill_topics)
  UNION ALL
  SELECT 'skills', 568::bigint, (SELECT count(*) FROM public.skills)
  UNION ALL
  SELECT 'users', 295::bigint, (SELECT count(*) FROM public.users)
)
SELECT table_name, expected_rows, actual_rows, (expected_rows = actual_rows) AS matches
FROM counts ORDER BY table_name;

-- Expected totals; inspect definitions separately. Zero source policies is intentional.
SELECT 'tables' AS object_type, count(*) AS actual, 31 AS expected
FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE n.nspname='public' AND c.relkind IN ('r','p')
UNION ALL
SELECT 'columns', count(*), 381 FROM information_schema.columns WHERE table_schema='public'
UNION ALL
-- PostgreSQL 18 adds table NOT NULL entries to pg_constraint; compare those separately.
SELECT 'constraints_excluding_not_null', count(*), 61
FROM pg_constraint c JOIN pg_class t ON t.oid=c.conrelid
JOIN pg_namespace n ON n.oid=t.relnamespace
WHERE n.nspname='public' AND c.contype <> 'n'
UNION ALL
SELECT 'not_null_columns', count(*), 213 FROM information_schema.columns
WHERE table_schema='public' AND is_nullable='NO'
UNION ALL
SELECT 'indexes', count(*), 77 FROM pg_indexes WHERE schemaname='public'
UNION ALL
SELECT 'non_internal_triggers', count(*), 5
FROM pg_trigger t JOIN pg_class c ON c.oid=t.tgrelid
JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE n.nspname='public' AND NOT t.tgisinternal
UNION ALL
SELECT 'rls_enabled_tables', count(*), 31
FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE n.nspname='public' AND c.relkind IN ('r','p') AND c.relrowsecurity
UNION ALL
SELECT 'source_policies', count(*), 0 FROM pg_policies WHERE schemaname='public';

-- Diagnostic breakdown: p=31, u=11, f=12, c=7; PostgreSQL 18 also reports n=213.
-- PostgreSQL 17 stores table nullability outside pg_constraint, so n need not appear there.
SELECT c.contype AS constraint_type, count(*) AS actual
FROM pg_constraint c JOIN pg_class t ON t.oid=c.conrelid
JOIN pg_namespace n ON n.oid=t.relnamespace
WHERE n.nspname='public'
GROUP BY c.contype ORDER BY c.contype;

-- Both queries must return no rows.
SELECT c.conrelid::regclass AS table_name, c.conname
FROM pg_constraint c JOIN pg_class t ON t.oid=c.conrelid
JOIN pg_namespace n ON n.oid=t.relnamespace
WHERE n.nspname='public' AND NOT c.convalidated;
SELECT c.relname AS index_name
FROM pg_index i JOIN pg_class c ON c.oid=i.indexrelid
JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE n.nspname='public' AND (NOT i.indisvalid OR NOT i.indisready);

-- Expected default: 45.
SELECT column_default FROM information_schema.columns
WHERE table_schema='public' AND table_name='assessments' AND column_name='duration_minutes';
SELECT e.extname, e.extversion, n.nspname
FROM pg_extension e JOIN pg_namespace n ON n.oid=e.extnamespace ORDER BY e.extname;
SELECT p.proname, pg_get_userbyid(p.proowner) AS owner, p.prosecdef
FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
WHERE n.nspname='public'
AND NOT EXISTS (
 SELECT 1 FROM pg_depend d WHERE d.classid='pg_proc'::regclass AND d.objid=p.oid AND d.deptype='e'
) ORDER BY p.proname;

-- Excluded managed schemas must not be present.
SELECT schema_name FROM information_schema.schemata
WHERE schema_name IN ('auth','storage','vault','realtime','supabase_migrations','drizzle');
COMMIT;
