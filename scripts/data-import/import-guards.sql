\set ON_ERROR_STOP on
-- psql --single-transaction must wrap this file, data, and finish checks together.
SET LOCAL lock_timeout='10s';
SET LOCAL statement_timeout='120s';
DO $guard$
BEGIN
 IF current_database()<>'skillset_pro_backend_dev' OR current_user<>'skillset_dev_owner' THEN
  RAISE EXCEPTION 'Wrong target or owner; import is restricted to the isolated development database';
 END IF;
END
$guard$;
LOCK TABLE public.ai_evaluations, public.assessment_assignments, public.assessment_attempts, public.assessment_config, public.assessment_questions, public.assessment_template_questions, public.assessment_template_skills, public.assessment_templates, public.assessments, public.attempt_answers, public.attempt_skill_scores, public.competency_levels, public.domain_skill_mappings, public.domains, public.employee_domain_assignments, public.manager_reviews, public.notifications, public.official_skill_entries, public.questions, public.reassessment_requests, public.registry_review_items, public.registry_reviews, public.review_skill_entries, public.skill_categories, public.skill_registries, public.skill_registry_items, public.skill_registry_submissions, public.skill_self_ratings, public.skill_topics, public.skills, public.users, public.databasechangelog, public.databasechangeloglock IN ACCESS EXCLUSIVE MODE;
DO $guard$
DECLARE item record; actual bigint;
BEGIN
 IF (SELECT count(*) FROM public.databasechangelog)<>5
 OR (SELECT count(*) FROM public.databasechangelog
     WHERE author='skillset-pro' AND filename='db/changelog/changes/001-initial-schema.yaml'
     AND id IN ('001-01-trigram-extension','001-02-application-tables',
       '001-03-application-routines','001-04-constraints-indexes','001-05-triggers-rls'))<>5 THEN
  RAISE EXCEPTION 'Unexpected Liquibase baseline history';
 END IF;
 IF (SELECT count(*) FROM public.databasechangeloglock)<>1
 OR EXISTS(SELECT 1 FROM public.databasechangeloglock WHERE locked) THEN
  RAISE EXCEPTION 'Liquibase history is locked or unexpected';
 END IF;
 FOR item IN SELECT * FROM (VALUES
('users'),
('domains'),
('skill_categories'),
('competency_levels'),
('skills'),
('skill_topics'),
('domain_skill_mappings'),
('questions'),
('assessment_config'),
('employee_domain_assignments'),
('skill_registry_submissions'),
('skill_self_ratings'),
('skill_registries'),
('skill_registry_items'),
('assessment_templates'),
('assessment_template_skills'),
('assessment_template_questions'),
('assessments'),
('assessment_assignments'),
('assessment_attempts'),
('assessment_questions'),
('attempt_answers'),
('ai_evaluations'),
('attempt_skill_scores'),
('manager_reviews'),
('review_skill_entries'),
('registry_reviews'),
('registry_review_items'),
('reassessment_requests'),
('official_skill_entries'),
('notifications')
 ) tables(table_name) LOOP
  EXECUTE format('SELECT count(*) FROM public.%I',item.table_name) INTO actual;
  IF actual<>0 THEN RAISE EXCEPTION 'Destination table % is not empty; repeat import refused',item.table_name; END IF;
 END LOOP;
 IF (SELECT count(*) FROM pg_catalog.pg_trigger t
     JOIN pg_catalog.pg_class c ON c.oid=t.tgrelid
     JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace
     WHERE n.nspname='public' AND NOT t.tgisinternal)<>5
 OR EXISTS (SELECT 1 FROM pg_catalog.pg_trigger t
     JOIN pg_catalog.pg_class c ON c.oid=t.tgrelid
     JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace
     WHERE n.nspname='public' AND t.tgenabled<>'O') THEN
  RAISE EXCEPTION 'Trigger count/state differs from reviewed preflight';
 END IF;
 IF NOT EXISTS(SELECT 1 FROM pg_catalog.pg_trigger
    WHERE tgrelid='public.assessment_questions'::regclass
      AND tgname='trg_archived_ro_assessment_questions' AND NOT tgisinternal AND tgenabled='O') THEN
  RAISE EXCEPTION 'Reviewed archive trigger missing';
 END IF;
 IF (SELECT count(*) FROM pg_catalog.pg_constraint c
     JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
     JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
     WHERE n.nspname='public' AND c.contype='f')<>12 THEN
  RAISE EXCEPTION 'Foreign-key graph differs from reviewed preflight';
 END IF;
END
$guard$;
-- Only this INSERT guard blocks 22 approved historical rows. FK triggers stay enabled.
ALTER TABLE public.assessment_questions DISABLE TRIGGER trg_archived_ro_assessment_questions;
