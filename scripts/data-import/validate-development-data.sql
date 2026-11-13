\set ON_ERROR_STOP on
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ, READ ONLY;
DO $guard$
BEGIN
 IF current_database()<>'skillset_pro_backend_dev' THEN RAISE EXCEPTION 'Wrong validation database'; END IF;
END
$guard$;
WITH counts(table_name,expected_rows,actual_rows) AS (
 SELECT 'ai_evaluations',15744::bigint,(SELECT count(*) FROM public.ai_evaluations)
 UNION ALL
 SELECT 'assessment_assignments',501::bigint,(SELECT count(*) FROM public.assessment_assignments)
 UNION ALL
 SELECT 'assessment_attempts',479::bigint,(SELECT count(*) FROM public.assessment_attempts)
 UNION ALL
 SELECT 'assessment_config',3::bigint,(SELECT count(*) FROM public.assessment_config)
 UNION ALL
 SELECT 'assessment_questions',16325::bigint,(SELECT count(*) FROM public.assessment_questions)
 UNION ALL
 SELECT 'assessment_template_questions',246::bigint,(SELECT count(*) FROM public.assessment_template_questions)
 UNION ALL
 SELECT 'assessment_template_skills',524::bigint,(SELECT count(*) FROM public.assessment_template_skills)
 UNION ALL
 SELECT 'assessment_templates',78::bigint,(SELECT count(*) FROM public.assessment_templates)
 UNION ALL
 SELECT 'assessments',501::bigint,(SELECT count(*) FROM public.assessments)
 UNION ALL
 SELECT 'attempt_answers',15907::bigint,(SELECT count(*) FROM public.attempt_answers)
 UNION ALL
 SELECT 'attempt_skill_scores',3549::bigint,(SELECT count(*) FROM public.attempt_skill_scores)
 UNION ALL
 SELECT 'competency_levels',5::bigint,(SELECT count(*) FROM public.competency_levels)
 UNION ALL
 SELECT 'domain_skill_mappings',490::bigint,(SELECT count(*) FROM public.domain_skill_mappings)
 UNION ALL
 SELECT 'domains',15::bigint,(SELECT count(*) FROM public.domains)
 UNION ALL
 SELECT 'employee_domain_assignments',0::bigint,(SELECT count(*) FROM public.employee_domain_assignments)
 UNION ALL
 SELECT 'manager_reviews',447::bigint,(SELECT count(*) FROM public.manager_reviews)
 UNION ALL
 SELECT 'notifications',1622::bigint,(SELECT count(*) FROM public.notifications)
 UNION ALL
 SELECT 'official_skill_entries',69::bigint,(SELECT count(*) FROM public.official_skill_entries)
 UNION ALL
 SELECT 'questions',23491::bigint,(SELECT count(*) FROM public.questions)
 UNION ALL
 SELECT 'reassessment_requests',0::bigint,(SELECT count(*) FROM public.reassessment_requests)
 UNION ALL
 SELECT 'registry_review_items',68::bigint,(SELECT count(*) FROM public.registry_review_items)
 UNION ALL
 SELECT 'registry_reviews',127::bigint,(SELECT count(*) FROM public.registry_reviews)
 UNION ALL
 SELECT 'review_skill_entries',3545::bigint,(SELECT count(*) FROM public.review_skill_entries)
 UNION ALL
 SELECT 'skill_categories',93::bigint,(SELECT count(*) FROM public.skill_categories)
 UNION ALL
 SELECT 'skill_registries',510::bigint,(SELECT count(*) FROM public.skill_registries)
 UNION ALL
 SELECT 'skill_registry_items',9721::bigint,(SELECT count(*) FROM public.skill_registry_items)
 UNION ALL
 SELECT 'skill_registry_submissions',0::bigint,(SELECT count(*) FROM public.skill_registry_submissions)
 UNION ALL
 SELECT 'skill_self_ratings',0::bigint,(SELECT count(*) FROM public.skill_self_ratings)
 UNION ALL
 SELECT 'skill_topics',1183::bigint,(SELECT count(*) FROM public.skill_topics)
 UNION ALL
 SELECT 'skills',568::bigint,(SELECT count(*) FROM public.skills)
 UNION ALL
 SELECT 'users',295::bigint,(SELECT count(*) FROM public.users)
)
SELECT table_name,expected_rows,actual_rows,expected_rows=actual_rows AS matches
FROM counts ORDER BY table_name;
SELECT count(*) AS applied_changesets FROM public.databasechangelog;
SELECT locked FROM public.databasechangeloglock;
SELECT c.relname AS table_name,t.tgname,t.tgenabled
FROM pg_trigger t JOIN pg_class c ON c.oid=t.tgrelid
JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE n.nspname='public' AND NOT t.tgisinternal ORDER BY c.relname,t.tgname;
SELECT count(*) AS retained_inactive_history_question_rows
FROM public.assessment_questions q JOIN public.assessments a ON a.id=q.assessment_id
JOIN public.users u ON u.id=a.employee_id WHERE u.status IS NOT NULL AND u.status<>'active';
SELECT c.conrelid::regclass AS table_name,c.conname
FROM pg_constraint c JOIN pg_class t ON t.oid=c.conrelid
JOIN pg_namespace n ON n.oid=t.relnamespace WHERE n.nspname='public' AND NOT c.convalidated;
COMMIT;
