-- Development baseline draft from reviewed application-only archive.
-- No business data, source ownership, grants or managed-schema objects.

ALTER TABLE ONLY public.ai_evaluations
    ADD CONSTRAINT ai_evaluations_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.assessment_assignments
    ADD CONSTRAINT assessment_assignments_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.assessment_attempts
    ADD CONSTRAINT assessment_attempts_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.assessment_config
    ADD CONSTRAINT assessment_config_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.assessment_config
    ADD CONSTRAINT assessment_config_tenant_id_config_type_reference_id_questi_key UNIQUE (tenant_id, config_type, reference_id, question_type);

ALTER TABLE ONLY public.assessment_questions
    ADD CONSTRAINT assessment_questions_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.assessment_template_questions
    ADD CONSTRAINT assessment_template_questions_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.assessment_template_skills
    ADD CONSTRAINT assessment_template_skills_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.assessment_templates
    ADD CONSTRAINT assessment_templates_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.assessments
    ADD CONSTRAINT assessments_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.attempt_answers
    ADD CONSTRAINT attempt_answers_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.attempt_skill_scores
    ADD CONSTRAINT attempt_skill_scores_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.domain_skill_mappings
    ADD CONSTRAINT domain_skill_mappings_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.domains
    ADD CONSTRAINT domains_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.employee_domain_assignments
    ADD CONSTRAINT employee_domain_assignments_employee_id_domain_id_key UNIQUE (employee_id, domain_id);

ALTER TABLE ONLY public.employee_domain_assignments
    ADD CONSTRAINT employee_domain_assignments_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.manager_reviews
    ADD CONSTRAINT manager_reviews_assessment_id_key UNIQUE (assessment_id);

ALTER TABLE ONLY public.manager_reviews
    ADD CONSTRAINT manager_reviews_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.official_skill_entries
    ADD CONSTRAINT official_skill_entries_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.competency_levels
    ADD CONSTRAINT question_settings_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.competency_levels
    ADD CONSTRAINT question_settings_tenant_id_level_key UNIQUE (tenant_id, level);

ALTER TABLE ONLY public.questions
    ADD CONSTRAINT questions_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.reassessment_requests
    ADD CONSTRAINT reassessment_requests_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.registry_review_items
    ADD CONSTRAINT registry_review_items_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.registry_review_items
    ADD CONSTRAINT registry_review_items_review_id_skill_id_key UNIQUE (review_id, skill_id);

ALTER TABLE ONLY public.registry_reviews
    ADD CONSTRAINT registry_reviews_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.registry_reviews
    ADD CONSTRAINT registry_reviews_registry_id_key UNIQUE (registry_id);

ALTER TABLE ONLY public.review_skill_entries
    ADD CONSTRAINT review_skill_entries_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.review_skill_entries
    ADD CONSTRAINT review_skill_entries_review_id_skill_id_key UNIQUE (review_id, skill_id);

ALTER TABLE ONLY public.skill_categories
    ADD CONSTRAINT skill_categories_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.skill_registries
    ADD CONSTRAINT skill_registries_employee_version_unique UNIQUE (employee_id, version_number);

ALTER TABLE ONLY public.skill_registries
    ADD CONSTRAINT skill_registries_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.skill_registry_items
    ADD CONSTRAINT skill_registry_items_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.skill_registry_submissions
    ADD CONSTRAINT skill_registry_submissions_employee_id_cycle_key UNIQUE (employee_id, cycle);

ALTER TABLE ONLY public.skill_registry_submissions
    ADD CONSTRAINT skill_registry_submissions_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.skill_self_ratings
    ADD CONSTRAINT skill_self_ratings_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.skill_self_ratings
    ADD CONSTRAINT skill_self_ratings_submission_id_skill_id_key UNIQUE (submission_id, skill_id);

ALTER TABLE ONLY public.skill_topics
    ADD CONSTRAINT skill_topics_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.skills
    ADD CONSTRAINT skills_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.ai_evaluations
    ADD CONSTRAINT ai_evaluations_attempt_id_fkey FOREIGN KEY (attempt_id) REFERENCES public.assessment_attempts(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.assessment_attempts
    ADD CONSTRAINT assessment_attempts_assessment_id_fkey FOREIGN KEY (assessment_id) REFERENCES public.assessments(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.assessment_questions
    ADD CONSTRAINT assessment_questions_assessment_id_fkey FOREIGN KEY (assessment_id) REFERENCES public.assessments(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.assessment_questions
    ADD CONSTRAINT assessment_questions_target_level_fkey FOREIGN KEY (target_level) REFERENCES public.competency_levels(id);

ALTER TABLE ONLY public.assessment_template_questions
    ADD CONSTRAINT assessment_template_questions_template_id_fkey FOREIGN KEY (template_id) REFERENCES public.assessment_templates(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.assessment_template_skills
    ADD CONSTRAINT assessment_template_skills_template_id_fkey FOREIGN KEY (template_id) REFERENCES public.assessment_templates(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.attempt_answers
    ADD CONSTRAINT attempt_answers_attempt_id_fkey FOREIGN KEY (attempt_id) REFERENCES public.assessment_attempts(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.attempt_skill_scores
    ADD CONSTRAINT attempt_skill_scores_attempt_id_fkey FOREIGN KEY (attempt_id) REFERENCES public.assessment_attempts(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.questions
    ADD CONSTRAINT questions_competency_level_fkey FOREIGN KEY (competency_level) REFERENCES public.competency_levels(id);

ALTER TABLE ONLY public.review_skill_entries
    ADD CONSTRAINT review_skill_entries_review_id_fkey FOREIGN KEY (review_id) REFERENCES public.manager_reviews(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.skill_registry_items
    ADD CONSTRAINT skill_registry_items_registry_id_fkey FOREIGN KEY (registry_id) REFERENCES public.skill_registries(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.skill_self_ratings
    ADD CONSTRAINT skill_self_ratings_submission_id_fkey FOREIGN KEY (submission_id) REFERENCES public.skill_registry_submissions(id) ON DELETE CASCADE;

CREATE UNIQUE INDEX domain_skill_mappings_active_domain_skill_uidx ON public.domain_skill_mappings USING btree (domain_id, skill_id) WHERE (deleted_on IS NULL);

CREATE UNIQUE INDEX idx_ai_evaluations_unique ON public.ai_evaluations USING btree (attempt_id, question_id);

CREATE INDEX idx_assessment_attempts_assessment_started ON public.assessment_attempts USING btree (assessment_id, started_at DESC);

CREATE INDEX idx_assessment_attempts_employee_assessment ON public.assessment_attempts USING btree (employee_id, assessment_id);

CREATE INDEX idx_assessment_attempts_started_at ON public.assessment_attempts USING btree (started_at DESC);

CREATE INDEX idx_assessment_questions_assessment ON public.assessment_questions USING btree (assessment_id);

CREATE INDEX idx_assessment_questions_question ON public.assessment_questions USING btree (question_id) WHERE (deleted_on IS NULL);

CREATE INDEX idx_assessments_employee ON public.assessments USING btree (employee_id);

CREATE INDEX idx_assessments_is_adaptive ON public.assessments USING btree (is_adaptive) WHERE (is_adaptive = true);

CREATE INDEX idx_assessments_tenant ON public.assessments USING btree (tenant_id);

CREATE INDEX idx_assignments_assessment ON public.assessment_assignments USING btree (assessment_id) WHERE (deleted_on IS NULL);

CREATE INDEX idx_assignments_employee_template_active ON public.assessment_assignments USING btree (employee_id, template_id) WHERE (deleted_on IS NULL);

CREATE INDEX idx_assignments_template ON public.assessment_assignments USING btree (template_id) WHERE (deleted_on IS NULL);

CREATE INDEX idx_attempt_answers_attempt ON public.attempt_answers USING btree (attempt_id);

CREATE UNIQUE INDEX idx_attempt_skill_scores_unique ON public.attempt_skill_scores USING btree (attempt_id, skill_id);

CREATE INDEX idx_attempts_employee ON public.assessment_attempts USING btree (employee_id);

CREATE INDEX idx_domain_skill_mappings_domain_active ON public.domain_skill_mappings USING btree (domain_id) WHERE (deleted_on IS NULL);

CREATE INDEX idx_domain_skill_mappings_skill_active ON public.domain_skill_mappings USING btree (skill_id) WHERE (deleted_on IS NULL);

CREATE INDEX idx_notifications_target_role_created ON public.notifications USING btree (target_role, created_at DESC);

CREATE INDEX idx_notifications_target_user_created ON public.notifications USING btree (target_user_id, created_at DESC);

CREATE INDEX idx_questions_created_at_active ON public.questions USING btree (created_at) WHERE (deleted_on IS NULL);

CREATE INDEX idx_questions_skill_type_status_level_active ON public.questions USING btree (skill_id, question_type, status, competency_level) WHERE (deleted_on IS NULL);

CREATE INDEX idx_questions_text_trgm ON public.questions USING gin (question_text public.gin_trgm_ops) WHERE (deleted_on IS NULL);

CREATE INDEX idx_registry_review_items_review_id ON public.registry_review_items USING btree (review_id);

CREATE INDEX idx_registry_reviews_registry_id ON public.registry_reviews USING btree (registry_id);

CREATE INDEX idx_registry_reviews_reviewer_id ON public.registry_reviews USING btree (reviewer_id);

CREATE INDEX idx_review_skill_entries_review ON public.review_skill_entries USING btree (review_id);

CREATE INDEX idx_skill_registries_employee_version ON public.skill_registries USING btree (employee_id, version_number DESC);

CREATE INDEX idx_skill_registry_items_registry ON public.skill_registry_items USING btree (registry_id);

CREATE INDEX idx_skill_self_ratings_skill ON public.skill_self_ratings USING btree (skill_id);

CREATE INDEX idx_skills_category_id ON public.skills USING btree (category_id);

CREATE INDEX idx_skills_created_at_active ON public.skills USING btree (created_at) WHERE (deleted_on IS NULL);

CREATE INDEX idx_template_questions_template ON public.assessment_template_questions USING btree (template_id);

CREATE INDEX idx_template_skills_template ON public.assessment_template_skills USING btree (template_id);

CREATE INDEX idx_users_domain ON public.users USING btree (domain_id);
