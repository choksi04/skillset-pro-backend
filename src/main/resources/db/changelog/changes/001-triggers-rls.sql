-- Development baseline draft from reviewed application-only archive.
-- No business data, source ownership, grants or managed-schema objects.

CREATE TRIGGER enforce_single_draft_registry_trigger BEFORE INSERT OR UPDATE ON public.skill_registries FOR EACH ROW EXECUTE FUNCTION public.enforce_single_draft_registry();

CREATE TRIGGER trg_archived_ro_assessment_questions BEFORE INSERT OR DELETE OR UPDATE ON public.assessment_questions FOR EACH ROW EXECUTE FUNCTION public.block_archived_employee_writes();

CREATE TRIGGER trg_archived_ro_assessments BEFORE DELETE OR UPDATE ON public.assessments FOR EACH ROW EXECUTE FUNCTION public.block_archived_employee_writes();

CREATE TRIGGER trg_archived_ro_registry_review_items BEFORE INSERT OR DELETE OR UPDATE ON public.registry_review_items FOR EACH ROW EXECUTE FUNCTION public.block_archived_employee_writes();

CREATE TRIGGER trg_archived_ro_registry_reviews BEFORE INSERT OR DELETE OR UPDATE ON public.registry_reviews FOR EACH ROW EXECUTE FUNCTION public.block_archived_employee_writes();

ALTER TABLE public.ai_evaluations ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.assessment_assignments ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.assessment_attempts ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.assessment_config ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.assessment_questions ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.assessment_template_questions ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.assessment_template_skills ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.assessment_templates ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.assessments ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.attempt_answers ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.attempt_skill_scores ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.competency_levels ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.domain_skill_mappings ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.domains ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.employee_domain_assignments ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.manager_reviews ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.official_skill_entries ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.reassessment_requests ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.registry_review_items ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.registry_reviews ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.review_skill_entries ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.skill_categories ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.skill_registries ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.skill_registry_items ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.skill_registry_submissions ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.skill_self_ratings ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.skill_topics ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.skills ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

REVOKE EXECUTE ON FUNCTION public.block_archived_employee_writes() FROM PUBLIC;

REVOKE EXECUTE ON FUNCTION public.enforce_single_draft_registry() FROM PUBLIC;

REVOKE EXECUTE ON FUNCTION public.get_question_counts() FROM PUBLIC;

REVOKE CREATE ON SCHEMA public FROM PUBLIC;
