\set ON_ERROR_STOP on
SET LOCAL statement_timeout='120s';
ALTER TABLE public.assessment_questions ENABLE TRIGGER trg_archived_ro_assessment_questions;
DO $verify$
DECLARE item record; actual bigint;
BEGIN
 IF current_database()<>'skillset_pro_backend_dev' OR current_user<>'skillset_dev_owner' THEN
  RAISE EXCEPTION 'Unexpected import target';
 END IF;
 FOR item IN SELECT * FROM (VALUES
('ai_evaluations',15744::bigint),
('assessment_assignments',501::bigint),
('assessment_attempts',479::bigint),
('assessment_config',3::bigint),
('assessment_questions',16325::bigint),
('assessment_template_questions',246::bigint),
('assessment_template_skills',524::bigint),
('assessment_templates',78::bigint),
('assessments',501::bigint),
('attempt_answers',15907::bigint),
('attempt_skill_scores',3549::bigint),
('competency_levels',5::bigint),
('domain_skill_mappings',490::bigint),
('domains',15::bigint),
('employee_domain_assignments',0::bigint),
('manager_reviews',447::bigint),
('notifications',1622::bigint),
('official_skill_entries',69::bigint),
('questions',23491::bigint),
('reassessment_requests',0::bigint),
('registry_review_items',68::bigint),
('registry_reviews',127::bigint),
('review_skill_entries',3545::bigint),
('skill_categories',93::bigint),
('skill_registries',510::bigint),
('skill_registry_items',9721::bigint),
('skill_registry_submissions',0::bigint),
('skill_self_ratings',0::bigint),
('skill_topics',1183::bigint),
('skills',568::bigint),
('users',295::bigint)
 ) expected(table_name,expected_rows) LOOP
  EXECUTE format('SELECT count(*) FROM public.%I',item.table_name) INTO actual;
  IF actual<>item.expected_rows THEN
   RAISE EXCEPTION 'Count mismatch for %: expected %, actual %',item.table_name,item.expected_rows,actual;
  END IF;
 END LOOP;
 IF (SELECT count(*) FROM public.assessment_questions q
     JOIN public.assessments a ON a.id=q.assessment_id
     JOIN public.users u ON u.id=a.employee_id
     WHERE u.status IS NOT NULL AND u.status<>'active')<>22 THEN
  RAISE EXCEPTION 'Inactive employee assessment-question history differs from approved 22 rows';
 END IF;
 IF EXISTS(SELECT 1 FROM public.registry_reviews r
     JOIN public.skill_registries s ON s.id=r.registry_id
     JOIN public.users u ON u.id=s.employee_id WHERE u.status IS NOT NULL AND u.status<>'active')
 OR EXISTS(SELECT 1 FROM public.registry_review_items i
     JOIN public.registry_reviews r ON r.id=i.review_id
     JOIN public.skill_registries s ON s.id=r.registry_id
     JOIN public.users u ON u.id=s.employee_id WHERE u.status IS NOT NULL AND u.status<>'active') THEN
  RAISE EXCEPTION 'Registry archive preflight differs from reviewed source';
 END IF;
 IF EXISTS(SELECT 1 FROM public.skill_registries WHERE status='draft' AND deleted_on IS NULL
     GROUP BY employee_id HAVING count(*)>1) THEN
  RAISE EXCEPTION 'Duplicate live draft registries';
 END IF;
 IF EXISTS(SELECT 1 FROM public.skill_registries old_draft
     WHERE old_draft.status='draft' AND old_draft.deleted_on IS NOT NULL AND EXISTS(
      SELECT 1 FROM public.skill_registries live_draft WHERE live_draft.employee_id=old_draft.employee_id
      AND live_draft.status='draft' AND live_draft.deleted_on IS NULL AND live_draft.id<>old_draft.id)) THEN
  RAISE EXCEPTION 'Soft-deleted draft conflicts differ from reviewed source';
 END IF;
 IF EXISTS(SELECT 1 FROM public.assessments a LEFT JOIN public.users u ON u.id=a.employee_id WHERE u.id IS NULL)
 OR EXISTS(SELECT 1 FROM public.skill_registries s LEFT JOIN public.users u ON u.id=s.employee_id WHERE u.id IS NULL)
 OR EXISTS(SELECT 1 FROM public.registry_reviews r LEFT JOIN public.skill_registries s ON s.id=r.registry_id WHERE s.id IS NULL)
 OR EXISTS(SELECT 1 FROM public.registry_review_items i LEFT JOIN public.registry_reviews r ON r.id=i.review_id WHERE r.id IS NULL) THEN
  RAISE EXCEPTION 'Unresolved logical link differs from reviewed preflight';
 END IF;
 IF EXISTS(SELECT 1 FROM pg_catalog.pg_constraint c
     JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
     JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
     WHERE n.nspname='public' AND NOT c.convalidated) THEN
  RAISE EXCEPTION 'Unvalidated constraint found';
 END IF;
 IF EXISTS(SELECT 1 FROM pg_catalog.pg_index i JOIN pg_catalog.pg_class x ON x.oid=i.indexrelid
     JOIN pg_catalog.pg_namespace n ON n.oid=x.relnamespace
     WHERE n.nspname='public' AND (NOT i.indisvalid OR NOT i.indisready)) THEN
  RAISE EXCEPTION 'Invalid index found';
 END IF;
 IF EXISTS(SELECT 1 FROM pg_catalog.pg_trigger t JOIN pg_catalog.pg_class c ON c.oid=t.tgrelid
     JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace
     WHERE n.nspname='public' AND t.tgenabled<>'O') THEN
  RAISE EXCEPTION 'A trigger was not restored to normal state';
 END IF;
 IF (SELECT count(*) FROM public.databasechangelog)<>5
 OR EXISTS(SELECT 1 FROM public.databasechangeloglock WHERE locked) THEN
  RAISE EXCEPTION 'Liquibase history changed during import';
 END IF;
 RAISE NOTICE 'Import checks passed: 31 table counts, 96106 rows, 22 inactive-history rows, trigger restoration and integrity checks';
END
$verify$;
-- No COMMIT here: psql --single-transaction controls commit only after all files succeed.
