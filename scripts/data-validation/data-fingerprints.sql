\set ON_ERROR_STOP on
\encoding UTF8
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ, READ ONLY;
SET LOCAL statement_timeout='300s';
SET LOCAL search_path=pg_catalog,public;
SET LOCAL TimeZone='UTC';
SET LOCAL DateStyle='ISO,YMD';
SET LOCAL IntervalStyle='postgres';
SET LOCAL extra_float_digits=3;
DO $guard$
BEGIN
 IF current_database() NOT IN ('skillset_pro_rehearsal_20261112','skillset_pro_backend_dev','skillset_pro_recovery_test') THEN
  RAISE EXCEPTION 'Wrong database for application fingerprint comparison';
 END IF;
 IF (SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
     WHERE n.nspname='public' AND c.relkind IN ('r','p')
     AND c.relname NOT IN ('databasechangelog','databasechangeloglock'))<>31 THEN
  RAISE EXCEPTION 'Unexpected application table inventory';
 END IF;
END
$guard$;
WITH fingerprints AS (
SELECT 'ai_evaluations' AS table_name, count(*) AS row_count,
 encode(sha256(convert_to(coalesce(string_agg(row_hash,'' ORDER BY row_hash COLLATE "C"),''),'UTF8')),'hex') AS fingerprint
 FROM (SELECT encode(sha256(convert_to(to_jsonb(r)::text,'UTF8')),'hex') AS row_hash FROM public.ai_evaluations r) rows_hashed
UNION ALL
SELECT 'assessment_assignments' AS table_name, count(*) AS row_count,
 encode(sha256(convert_to(coalesce(string_agg(row_hash,'' ORDER BY row_hash COLLATE "C"),''),'UTF8')),'hex') AS fingerprint
 FROM (SELECT encode(sha256(convert_to(to_jsonb(r)::text,'UTF8')),'hex') AS row_hash FROM public.assessment_assignments r) rows_hashed
UNION ALL
SELECT 'assessment_attempts' AS table_name, count(*) AS row_count,
 encode(sha256(convert_to(coalesce(string_agg(row_hash,'' ORDER BY row_hash COLLATE "C"),''),'UTF8')),'hex') AS fingerprint
 FROM (SELECT encode(sha256(convert_to(to_jsonb(r)::text,'UTF8')),'hex') AS row_hash FROM public.assessment_attempts r) rows_hashed
UNION ALL
SELECT 'assessment_config' AS table_name, count(*) AS row_count,
 encode(sha256(convert_to(coalesce(string_agg(row_hash,'' ORDER BY row_hash COLLATE "C"),''),'UTF8')),'hex') AS fingerprint
 FROM (SELECT encode(sha256(convert_to(to_jsonb(r)::text,'UTF8')),'hex') AS row_hash FROM public.assessment_config r) rows_hashed
UNION ALL
SELECT 'assessment_questions' AS table_name, count(*) AS row_count,
 encode(sha256(convert_to(coalesce(string_agg(row_hash,'' ORDER BY row_hash COLLATE "C"),''),'UTF8')),'hex') AS fingerprint
 FROM (SELECT encode(sha256(convert_to(to_jsonb(r)::text,'UTF8')),'hex') AS row_hash FROM public.assessment_questions r) rows_hashed
UNION ALL
SELECT 'assessment_template_questions' AS table_name, count(*) AS row_count,
 encode(sha256(convert_to(coalesce(string_agg(row_hash,'' ORDER BY row_hash COLLATE "C"),''),'UTF8')),'hex') AS fingerprint
 FROM (SELECT encode(sha256(convert_to(to_jsonb(r)::text,'UTF8')),'hex') AS row_hash FROM public.assessment_template_questions r) rows_hashed
UNION ALL
SELECT 'assessment_template_skills' AS table_name, count(*) AS row_count,
 encode(sha256(convert_to(coalesce(string_agg(row_hash,'' ORDER BY row_hash COLLATE "C"),''),'UTF8')),'hex') AS fingerprint
 FROM (SELECT encode(sha256(convert_to(to_jsonb(r)::text,'UTF8')),'hex') AS row_hash FROM public.assessment_template_skills r) rows_hashed
UNION ALL
SELECT 'assessment_templates' AS table_name, count(*) AS row_count,
 encode(sha256(convert_to(coalesce(string_agg(row_hash,'' ORDER BY row_hash COLLATE "C"),''),'UTF8')),'hex') AS fingerprint
 FROM (SELECT encode(sha256(convert_to(to_jsonb(r)::text,'UTF8')),'hex') AS row_hash FROM public.assessment_templates r) rows_hashed
UNION ALL
SELECT 'assessments' AS table_name, count(*) AS row_count,
 encode(sha256(convert_to(coalesce(string_agg(row_hash,'' ORDER BY row_hash COLLATE "C"),''),'UTF8')),'hex') AS fingerprint
 FROM (SELECT encode(sha256(convert_to(to_jsonb(r)::text,'UTF8')),'hex') AS row_hash FROM public.assessments r) rows_hashed
UNION ALL
SELECT 'attempt_answers' AS table_name, count(*) AS row_count,
 encode(sha256(convert_to(coalesce(string_agg(row_hash,'' ORDER BY row_hash COLLATE "C"),''),'UTF8')),'hex') AS fingerprint
 FROM (SELECT encode(sha256(convert_to(to_jsonb(r)::text,'UTF8')),'hex') AS row_hash FROM public.attempt_answers r) rows_hashed
UNION ALL
SELECT 'attempt_skill_scores' AS table_name, count(*) AS row_count,
 encode(sha256(convert_to(coalesce(string_agg(row_hash,'' ORDER BY row_hash COLLATE "C"),''),'UTF8')),'hex') AS fingerprint
 FROM (SELECT encode(sha256(convert_to(to_jsonb(r)::text,'UTF8')),'hex') AS row_hash FROM public.attempt_skill_scores r) rows_hashed
UNION ALL
SELECT 'competency_levels' AS table_name, count(*) AS row_count,
 encode(sha256(convert_to(coalesce(string_agg(row_hash,'' ORDER BY row_hash COLLATE "C"),''),'UTF8')),'hex') AS fingerprint
 FROM (SELECT encode(sha256(convert_to(to_jsonb(r)::text,'UTF8')),'hex') AS row_hash FROM public.competency_levels r) rows_hashed
UNION ALL
SELECT 'domain_skill_mappings' AS table_name, count(*) AS row_count,
 encode(sha256(convert_to(coalesce(string_agg(row_hash,'' ORDER BY row_hash COLLATE "C"),''),'UTF8')),'hex') AS fingerprint
 FROM (SELECT encode(sha256(convert_to(to_jsonb(r)::text,'UTF8')),'hex') AS row_hash FROM public.domain_skill_mappings r) rows_hashed
UNION ALL
SELECT 'domains' AS table_name, count(*) AS row_count,
 encode(sha256(convert_to(coalesce(string_agg(row_hash,'' ORDER BY row_hash COLLATE "C"),''),'UTF8')),'hex') AS fingerprint
 FROM (SELECT encode(sha256(convert_to(to_jsonb(r)::text,'UTF8')),'hex') AS row_hash FROM public.domains r) rows_hashed
UNION ALL
SELECT 'employee_domain_assignments' AS table_name, count(*) AS row_count,
 encode(sha256(convert_to(coalesce(string_agg(row_hash,'' ORDER BY row_hash COLLATE "C"),''),'UTF8')),'hex') AS fingerprint
 FROM (SELECT encode(sha256(convert_to(to_jsonb(r)::text,'UTF8')),'hex') AS row_hash FROM public.employee_domain_assignments r) rows_hashed
UNION ALL
SELECT 'manager_reviews' AS table_name, count(*) AS row_count,
 encode(sha256(convert_to(coalesce(string_agg(row_hash,'' ORDER BY row_hash COLLATE "C"),''),'UTF8')),'hex') AS fingerprint
 FROM (SELECT encode(sha256(convert_to(to_jsonb(r)::text,'UTF8')),'hex') AS row_hash FROM public.manager_reviews r) rows_hashed
UNION ALL
SELECT 'notifications' AS table_name, count(*) AS row_count,
 encode(sha256(convert_to(coalesce(string_agg(row_hash,'' ORDER BY row_hash COLLATE "C"),''),'UTF8')),'hex') AS fingerprint
 FROM (SELECT encode(sha256(convert_to(to_jsonb(r)::text,'UTF8')),'hex') AS row_hash FROM public.notifications r) rows_hashed
UNION ALL
SELECT 'official_skill_entries' AS table_name, count(*) AS row_count,
 encode(sha256(convert_to(coalesce(string_agg(row_hash,'' ORDER BY row_hash COLLATE "C"),''),'UTF8')),'hex') AS fingerprint
 FROM (SELECT encode(sha256(convert_to(to_jsonb(r)::text,'UTF8')),'hex') AS row_hash FROM public.official_skill_entries r) rows_hashed
UNION ALL
SELECT 'questions' AS table_name, count(*) AS row_count,
 encode(sha256(convert_to(coalesce(string_agg(row_hash,'' ORDER BY row_hash COLLATE "C"),''),'UTF8')),'hex') AS fingerprint
 FROM (SELECT encode(sha256(convert_to(to_jsonb(r)::text,'UTF8')),'hex') AS row_hash FROM public.questions r) rows_hashed
UNION ALL
SELECT 'reassessment_requests' AS table_name, count(*) AS row_count,
 encode(sha256(convert_to(coalesce(string_agg(row_hash,'' ORDER BY row_hash COLLATE "C"),''),'UTF8')),'hex') AS fingerprint
 FROM (SELECT encode(sha256(convert_to(to_jsonb(r)::text,'UTF8')),'hex') AS row_hash FROM public.reassessment_requests r) rows_hashed
UNION ALL
SELECT 'registry_review_items' AS table_name, count(*) AS row_count,
 encode(sha256(convert_to(coalesce(string_agg(row_hash,'' ORDER BY row_hash COLLATE "C"),''),'UTF8')),'hex') AS fingerprint
 FROM (SELECT encode(sha256(convert_to(to_jsonb(r)::text,'UTF8')),'hex') AS row_hash FROM public.registry_review_items r) rows_hashed
UNION ALL
SELECT 'registry_reviews' AS table_name, count(*) AS row_count,
 encode(sha256(convert_to(coalesce(string_agg(row_hash,'' ORDER BY row_hash COLLATE "C"),''),'UTF8')),'hex') AS fingerprint
 FROM (SELECT encode(sha256(convert_to(to_jsonb(r)::text,'UTF8')),'hex') AS row_hash FROM public.registry_reviews r) rows_hashed
UNION ALL
SELECT 'review_skill_entries' AS table_name, count(*) AS row_count,
 encode(sha256(convert_to(coalesce(string_agg(row_hash,'' ORDER BY row_hash COLLATE "C"),''),'UTF8')),'hex') AS fingerprint
 FROM (SELECT encode(sha256(convert_to(to_jsonb(r)::text,'UTF8')),'hex') AS row_hash FROM public.review_skill_entries r) rows_hashed
UNION ALL
SELECT 'skill_categories' AS table_name, count(*) AS row_count,
 encode(sha256(convert_to(coalesce(string_agg(row_hash,'' ORDER BY row_hash COLLATE "C"),''),'UTF8')),'hex') AS fingerprint
 FROM (SELECT encode(sha256(convert_to(to_jsonb(r)::text,'UTF8')),'hex') AS row_hash FROM public.skill_categories r) rows_hashed
UNION ALL
SELECT 'skill_registries' AS table_name, count(*) AS row_count,
 encode(sha256(convert_to(coalesce(string_agg(row_hash,'' ORDER BY row_hash COLLATE "C"),''),'UTF8')),'hex') AS fingerprint
 FROM (SELECT encode(sha256(convert_to(to_jsonb(r)::text,'UTF8')),'hex') AS row_hash FROM public.skill_registries r) rows_hashed
UNION ALL
SELECT 'skill_registry_items' AS table_name, count(*) AS row_count,
 encode(sha256(convert_to(coalesce(string_agg(row_hash,'' ORDER BY row_hash COLLATE "C"),''),'UTF8')),'hex') AS fingerprint
 FROM (SELECT encode(sha256(convert_to(to_jsonb(r)::text,'UTF8')),'hex') AS row_hash FROM public.skill_registry_items r) rows_hashed
UNION ALL
SELECT 'skill_registry_submissions' AS table_name, count(*) AS row_count,
 encode(sha256(convert_to(coalesce(string_agg(row_hash,'' ORDER BY row_hash COLLATE "C"),''),'UTF8')),'hex') AS fingerprint
 FROM (SELECT encode(sha256(convert_to(to_jsonb(r)::text,'UTF8')),'hex') AS row_hash FROM public.skill_registry_submissions r) rows_hashed
UNION ALL
SELECT 'skill_self_ratings' AS table_name, count(*) AS row_count,
 encode(sha256(convert_to(coalesce(string_agg(row_hash,'' ORDER BY row_hash COLLATE "C"),''),'UTF8')),'hex') AS fingerprint
 FROM (SELECT encode(sha256(convert_to(to_jsonb(r)::text,'UTF8')),'hex') AS row_hash FROM public.skill_self_ratings r) rows_hashed
UNION ALL
SELECT 'skill_topics' AS table_name, count(*) AS row_count,
 encode(sha256(convert_to(coalesce(string_agg(row_hash,'' ORDER BY row_hash COLLATE "C"),''),'UTF8')),'hex') AS fingerprint
 FROM (SELECT encode(sha256(convert_to(to_jsonb(r)::text,'UTF8')),'hex') AS row_hash FROM public.skill_topics r) rows_hashed
UNION ALL
SELECT 'skills' AS table_name, count(*) AS row_count,
 encode(sha256(convert_to(coalesce(string_agg(row_hash,'' ORDER BY row_hash COLLATE "C"),''),'UTF8')),'hex') AS fingerprint
 FROM (SELECT encode(sha256(convert_to(to_jsonb(r)::text,'UTF8')),'hex') AS row_hash FROM public.skills r) rows_hashed
UNION ALL
SELECT 'users' AS table_name, count(*) AS row_count,
 encode(sha256(convert_to(coalesce(string_agg(row_hash,'' ORDER BY row_hash COLLATE "C"),''),'UTF8')),'hex') AS fingerprint
 FROM (SELECT encode(sha256(convert_to(to_jsonb(r)::text,'UTF8')),'hex') AS row_hash FROM public.users r) rows_hashed
)
SELECT jsonb_build_object(
 'format_version',1,
 'algorithm','sha256-jsonb-row-multiset-v1',
 'database',current_database(),
 'server_version',current_setting('server_version'),
 'generated_at_utc',to_char(current_timestamp AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),
 'tables',(SELECT jsonb_agg(jsonb_build_object('table',table_name,'rows',row_count,'sha256',fingerprint)
             ORDER BY table_name) FROM fingerprints)
);
COMMIT;
