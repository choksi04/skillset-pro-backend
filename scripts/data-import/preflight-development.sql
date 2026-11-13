\set ON_ERROR_STOP on
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ, READ ONLY;
SET LOCAL statement_timeout = '60s';
DO $guard$
BEGIN
 IF current_database() <> 'skillset_pro_backend_dev' THEN
  RAISE EXCEPTION 'Wrong database for this preflight; no checks executed';
 END IF;
END
$guard$;

WITH counts(table_name, actual_rows) AS (
 SELECT 'ai_evaluations', (SELECT count(*) FROM public.ai_evaluations)
 UNION ALL
 SELECT 'assessment_assignments', (SELECT count(*) FROM public.assessment_assignments)
 UNION ALL
 SELECT 'assessment_attempts', (SELECT count(*) FROM public.assessment_attempts)
 UNION ALL
 SELECT 'assessment_config', (SELECT count(*) FROM public.assessment_config)
 UNION ALL
 SELECT 'assessment_questions', (SELECT count(*) FROM public.assessment_questions)
 UNION ALL
 SELECT 'assessment_template_questions', (SELECT count(*) FROM public.assessment_template_questions)
 UNION ALL
 SELECT 'assessment_template_skills', (SELECT count(*) FROM public.assessment_template_skills)
 UNION ALL
 SELECT 'assessment_templates', (SELECT count(*) FROM public.assessment_templates)
 UNION ALL
 SELECT 'assessments', (SELECT count(*) FROM public.assessments)
 UNION ALL
 SELECT 'attempt_answers', (SELECT count(*) FROM public.attempt_answers)
 UNION ALL
 SELECT 'attempt_skill_scores', (SELECT count(*) FROM public.attempt_skill_scores)
 UNION ALL
 SELECT 'competency_levels', (SELECT count(*) FROM public.competency_levels)
 UNION ALL
 SELECT 'domain_skill_mappings', (SELECT count(*) FROM public.domain_skill_mappings)
 UNION ALL
 SELECT 'domains', (SELECT count(*) FROM public.domains)
 UNION ALL
 SELECT 'employee_domain_assignments', (SELECT count(*) FROM public.employee_domain_assignments)
 UNION ALL
 SELECT 'manager_reviews', (SELECT count(*) FROM public.manager_reviews)
 UNION ALL
 SELECT 'notifications', (SELECT count(*) FROM public.notifications)
 UNION ALL
 SELECT 'official_skill_entries', (SELECT count(*) FROM public.official_skill_entries)
 UNION ALL
 SELECT 'questions', (SELECT count(*) FROM public.questions)
 UNION ALL
 SELECT 'reassessment_requests', (SELECT count(*) FROM public.reassessment_requests)
 UNION ALL
 SELECT 'registry_review_items', (SELECT count(*) FROM public.registry_review_items)
 UNION ALL
 SELECT 'registry_reviews', (SELECT count(*) FROM public.registry_reviews)
 UNION ALL
 SELECT 'review_skill_entries', (SELECT count(*) FROM public.review_skill_entries)
 UNION ALL
 SELECT 'skill_categories', (SELECT count(*) FROM public.skill_categories)
 UNION ALL
 SELECT 'skill_registries', (SELECT count(*) FROM public.skill_registries)
 UNION ALL
 SELECT 'skill_registry_items', (SELECT count(*) FROM public.skill_registry_items)
 UNION ALL
 SELECT 'skill_registry_submissions', (SELECT count(*) FROM public.skill_registry_submissions)
 UNION ALL
 SELECT 'skill_self_ratings', (SELECT count(*) FROM public.skill_self_ratings)
 UNION ALL
 SELECT 'skill_topics', (SELECT count(*) FROM public.skill_topics)
 UNION ALL
 SELECT 'skills', (SELECT count(*) FROM public.skills)
 UNION ALL
 SELECT 'users', (SELECT count(*) FROM public.users)
)
SELECT table_name, actual_rows, (actual_rows=0) AS is_empty
FROM counts ORDER BY table_name;

-- Expect 5 applied changesets and an unlocked history table.
SELECT count(*) AS applied_changesets FROM public.databasechangelog;
SELECT locked FROM public.databasechangeloglock;

-- Review only: no trigger or foreign-key state is changed.
SELECT c.relname AS table_name, t.tgname AS trigger_name, t.tgenabled AS enabled
FROM pg_trigger t JOIN pg_class c ON c.oid=t.tgrelid
JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE n.nspname='public' AND NOT t.tgisinternal
ORDER BY c.relname,t.tgname;
COMMIT;
