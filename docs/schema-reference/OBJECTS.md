# Local SQL object inventory

Static evidence only. See [comparison and limitations](../SCHEMA_COMPARISON.md).
Implicit indexes backing primary keys and unique constraints are not included in the
explicit-index table. Policies/indexes assume the ordered histories applied successfully.

## Table-level constraints

### assessment_config

- `UNIQUE(tenant_id, config_type, reference_id, question_type)`

### assessment_questions

- `ADD CONSTRAINT assessment_questions_target_level_fkey FOREIGN KEY (target_level) REFERENCES public.competency_levels(id)`

### competency_levels

- `UNIQUE(tenant_id, level)`

### employee_domain_assignments

- `UNIQUE(employee_id, domain_id)`

### manager_reviews

- `UNIQUE(assessment_id)`

### questions

- `ADD CONSTRAINT questions_competency_level_fkey FOREIGN KEY (competency_level) REFERENCES public.competency_levels(id)`

### registry_review_items

- `UNIQUE (review_id, skill_id)`

### review_skill_entries

- `UNIQUE(review_id, skill_id)`

### skill_registries

- `CONSTRAINT skill_registries_employee_version_unique UNIQUE (employee_id, version_number)`

### skill_registry_items

- `CONSTRAINT skill_registry_items_score_range CHECK (self_score >= 1 AND self_score <= 5)`

### skill_registry_submissions

- `UNIQUE(employee_id, cycle)`

### skill_self_ratings

- `UNIQUE(submission_id, skill_id)`

Column-level PRIMARY KEY, UNIQUE, CHECK and REFERENCES clauses are retained verbatim in
[COLUMNS.csv](COLUMNS.csv), including users.email uniqueness and template/status checks.

## Explicit foreign keys (12)

| Child table | Declaration |
|---|---|
| `assessment_questions` | `assessment_id UUID REFERENCES public.assessments(id) ON DELETE CASCADE NOT NULL` |
| `assessment_questions` | `ADD CONSTRAINT assessment_questions_target_level_fkey FOREIGN KEY (target_level) REFERENCES public.competency_levels(id)` |
| `assessment_attempts` | `assessment_id UUID REFERENCES public.assessments(id) ON DELETE CASCADE NOT NULL` |
| `attempt_answers` | `attempt_id UUID REFERENCES public.assessment_attempts(id) ON DELETE CASCADE NOT NULL` |
| `ai_evaluations` | `attempt_id UUID REFERENCES public.assessment_attempts(id) ON DELETE CASCADE NOT NULL` |
| `attempt_skill_scores` | `attempt_id UUID REFERENCES public.assessment_attempts(id) ON DELETE CASCADE NOT NULL` |
| `questions` | `ADD CONSTRAINT questions_competency_level_fkey FOREIGN KEY (competency_level) REFERENCES public.competency_levels(id)` |
| `skill_self_ratings` | `submission_id text NOT NULL REFERENCES skill_registry_submissions(id) ON DELETE CASCADE` |
| `review_skill_entries` | `review_id text NOT NULL REFERENCES manager_reviews(id) ON DELETE CASCADE` |
| `skill_registry_items` | `registry_id uuid NOT NULL REFERENCES public.skill_registries(id) ON DELETE CASCADE` |
| `assessment_template_skills` | `template_id uuid NOT NULL REFERENCES public.assessment_templates(id) ON DELETE CASCADE` |
| `assessment_template_questions` | `template_id uuid NOT NULL REFERENCES public.assessment_templates(id) ON DELETE CASCADE` |

## Explicit indexes (36 unique names)

| Table | Index | SQL declaration |
|---|---|---|
| `assessments` | `idx_assessments_employee` | `CREATE INDEX idx_assessments_employee ON public.assessments(employee_id);` |
| `assessments` | `idx_assessments_tenant` | `CREATE INDEX idx_assessments_tenant ON public.assessments(tenant_id);` |
| `assessment_questions` | `idx_assessment_questions_assessment` | `CREATE INDEX idx_assessment_questions_assessment ON public.assessment_questions(assessment_id);` |
| `assessment_attempts` | `idx_attempts_assessment` | `CREATE INDEX idx_attempts_assessment ON public.assessment_attempts(assessment_id);` |
| `assessment_attempts` | `idx_attempts_employee` | `CREATE INDEX idx_attempts_employee ON public.assessment_attempts(employee_id);` |
| `attempt_answers` | `idx_answers_attempt` | `CREATE INDEX idx_answers_attempt ON public.attempt_answers(attempt_id);` |
| `ai_evaluations` | `idx_evaluations_attempt` | `CREATE INDEX idx_evaluations_attempt ON public.ai_evaluations(attempt_id);` |
| `attempt_skill_scores` | `idx_skill_scores_attempt` | `CREATE INDEX idx_skill_scores_attempt ON public.attempt_skill_scores(attempt_id);` |
| `ai_evaluations` | `idx_ai_evaluations_unique` | `CREATE UNIQUE INDEX IF NOT EXISTS idx_ai_evaluations_unique ON ai_evaluations(attempt_id, question_id);` |
| `attempt_skill_scores` | `idx_attempt_skill_scores_unique` | `CREATE UNIQUE INDEX IF NOT EXISTS idx_attempt_skill_scores_unique ON attempt_skill_scores(attempt_id, skill_id);` |
| `skill_registries` | `idx_skill_registries_employee_version` | `CREATE INDEX idx_skill_registries_employee_version ON public.skill_registries (employee_id, version_number DESC);` |
| `assessment_template_skills` | `idx_template_skills_template` | `CREATE INDEX idx_template_skills_template ON public.assessment_template_skills(template_id);` |
| `assessment_template_questions` | `idx_template_questions_template` | `CREATE INDEX idx_template_questions_template ON public.assessment_template_questions(template_id);` |
| `assessment_assignments` | `idx_assignments_employee_template_active` | `CREATE INDEX idx_assignments_employee_template_active ON public.assessment_assignments (employee_id, template_id) WHERE deleted_on IS NULL;` |
| `assessment_assignments` | `idx_assignments_template` | `CREATE INDEX idx_assignments_template ON public.assessment_assignments (template_id) WHERE deleted_on IS NULL;` |
| `assessment_assignments` | `idx_assignments_assessment` | `CREATE INDEX idx_assignments_assessment ON public.assessment_assignments (assessment_id) WHERE deleted_on IS NULL;` |
| `assessments` | `idx_assessments_is_adaptive` | `CREATE INDEX IF NOT EXISTS idx_assessments_is_adaptive ON public.assessments (is_adaptive) WHERE is_adaptive = true;` |
| `registry_reviews` | `idx_registry_reviews_registry_id` | `CREATE INDEX idx_registry_reviews_registry_id ON public.registry_reviews(registry_id);` |
| `registry_reviews` | `idx_registry_reviews_reviewer_id` | `CREATE INDEX idx_registry_reviews_reviewer_id ON public.registry_reviews(reviewer_id);` |
| `registry_review_items` | `idx_registry_review_items_review_id` | `CREATE INDEX idx_registry_review_items_review_id ON public.registry_review_items(review_id);` |
| `skills` | `idx_skills_category_id` | `CREATE INDEX IF NOT EXISTS idx_skills_category_id ON public.skills(category_id);` |
| `questions` | `idx_questions_skill_type_status_active` | `CREATE INDEX IF NOT EXISTS idx_questions_skill_type_status_active ON public.questions (skill_id, question_type, status) WHERE deleted_on IS NULL;` |
| `questions` | `idx_questions_created_at_active` | `CREATE INDEX IF NOT EXISTS idx_questions_created_at_active ON public.questions (created_at) WHERE deleted_on IS NULL;` |
| `skills` | `idx_skills_created_at_active` | `CREATE INDEX IF NOT EXISTS idx_skills_created_at_active ON public.skills (created_at) WHERE deleted_on IS NULL;` |
| `domain_skill_mappings` | `idx_domain_skill_mappings_domain_active` | `CREATE INDEX IF NOT EXISTS idx_domain_skill_mappings_domain_active ON public.domain_skill_mappings (domain_id) WHERE deleted_on IS NULL;` |
| `domain_skill_mappings` | `idx_domain_skill_mappings_skill_active` | `CREATE INDEX IF NOT EXISTS idx_domain_skill_mappings_skill_active ON public.domain_skill_mappings (skill_id) WHERE deleted_on IS NULL;` |
| `ai_evaluations` | `idx_ai_evaluations_attempt` | `CREATE INDEX IF NOT EXISTS idx_ai_evaluations_attempt ON public.ai_evaluations (attempt_id);` |
| `attempt_answers` | `idx_attempt_answers_attempt` | `CREATE INDEX IF NOT EXISTS idx_attempt_answers_attempt ON public.attempt_answers (attempt_id);` |
| `attempt_skill_scores` | `idx_attempt_skill_scores_attempt` | `CREATE INDEX IF NOT EXISTS idx_attempt_skill_scores_attempt ON public.attempt_skill_scores (attempt_id);` |
| `assessment_attempts` | `idx_assessment_attempts_started_at` | `CREATE INDEX IF NOT EXISTS idx_assessment_attempts_started_at ON public.assessment_attempts (started_at DESC);` |
| `assessment_attempts` | `idx_assessment_attempts_employee_assessment` | `CREATE INDEX IF NOT EXISTS idx_assessment_attempts_employee_assessment ON public.assessment_attempts (employee_id, assessment_id);` |
| `notifications` | `idx_notifications_target_user_created` | `CREATE INDEX IF NOT EXISTS idx_notifications_target_user_created ON public.notifications (target_user_id, created_at DESC);` |
| `notifications` | `idx_notifications_target_role_created` | `CREATE INDEX IF NOT EXISTS idx_notifications_target_role_created ON public.notifications (target_role, created_at DESC);` |
| `review_skill_entries` | `idx_review_skill_entries_review` | `CREATE INDEX IF NOT EXISTS idx_review_skill_entries_review ON public.review_skill_entries (review_id);` |
| `skill_registry_items` | `idx_skill_registry_items_registry` | `CREATE INDEX IF NOT EXISTS idx_skill_registry_items_registry ON public.skill_registry_items (registry_id);` |
| `domain_skill_mappings` | `domain_skill_mappings_active_domain_skill_uidx` | `CREATE UNIQUE INDEX IF NOT EXISTS domain_skill_mappings_active_domain_skill_uidx ON public.domain_skill_mappings (domain_id, skill_id) WHERE deleted_on IS NULL;` |

## Surviving RLS policies (31)

| Table | Policy | SQL declaration before any rename |
|---|---|---|
| `assessments` | Allow all for assessments | `CREATE POLICY "Allow all for assessments" ON public.assessments FOR ALL USING (true) WITH CHECK (true);` |
| `assessment_questions` | Allow all for assessment_questions | `CREATE POLICY "Allow all for assessment_questions" ON public.assessment_questions FOR ALL USING (true) WITH CHECK (true);` |
| `assessment_attempts` | Allow all for assessment_attempts | `CREATE POLICY "Allow all for assessment_attempts" ON public.assessment_attempts FOR ALL USING (true) WITH CHECK (true);` |
| `attempt_answers` | Allow all for attempt_answers | `CREATE POLICY "Allow all for attempt_answers" ON public.attempt_answers FOR ALL USING (true) WITH CHECK (true);` |
| `ai_evaluations` | Allow all for ai_evaluations | `CREATE POLICY "Allow all for ai_evaluations" ON public.ai_evaluations FOR ALL USING (true) WITH CHECK (true);` |
| `attempt_skill_scores` | Allow all for attempt_skill_scores | `CREATE POLICY "Allow all for attempt_skill_scores" ON public.attempt_skill_scores FOR ALL USING (true) WITH CHECK (true);` |
| `domains` | Allow all | `CREATE POLICY "Allow all" ON domains FOR ALL USING (true) WITH CHECK (true);` |
| `skill_categories` | Allow all | `CREATE POLICY "Allow all" ON skill_categories FOR ALL USING (true) WITH CHECK (true);` |
| `skills` | Allow all | `CREATE POLICY "Allow all" ON skills FOR ALL USING (true) WITH CHECK (true);` |
| `questions` | Allow all | `CREATE POLICY "Allow all" ON questions FOR ALL USING (true) WITH CHECK (true);` |
| `domain_skill_mappings` | Allow all | `CREATE POLICY "Allow all" ON domain_skill_mappings FOR ALL USING (true) WITH CHECK (true);` |
| `skill_registry_submissions` | Allow all | `CREATE POLICY "Allow all" ON skill_registry_submissions FOR ALL USING (true) WITH CHECK (true);` |
| `skill_self_ratings` | Allow all | `CREATE POLICY "Allow all" ON skill_self_ratings FOR ALL USING (true) WITH CHECK (true);` |
| `employee_domain_assignments` | Allow all | `CREATE POLICY "Allow all" ON employee_domain_assignments FOR ALL USING (true) WITH CHECK (true);` |
| `manager_reviews` | Allow all | `CREATE POLICY "Allow all" ON manager_reviews FOR ALL USING (true) WITH CHECK (true);` |
| `review_skill_entries` | Allow all | `CREATE POLICY "Allow all" ON review_skill_entries FOR ALL USING (true) WITH CHECK (true);` |
| `official_skill_entries` | Allow all | `CREATE POLICY "Allow all" ON official_skill_entries FOR ALL USING (true) WITH CHECK (true);` |
| `notifications` | Allow all | `CREATE POLICY "Allow all" ON notifications FOR ALL USING (true) WITH CHECK (true);` |
| `users` | Allow all for users | `CREATE POLICY "Allow all for users" ON public.users FOR ALL USING (true) WITH CHECK (true);` |
| `skill_topics` | Allow all | `CREATE POLICY "Allow all" ON public.skill_topics FOR ALL TO public USING (true) WITH CHECK (true);` |
| `competency_levels` | Allow all for competency_levels | `CREATE POLICY "Allow all for question_settings" ON public.question_settings FOR ALL TO public USING (true) WITH CHECK (true);` |
| `reassessment_requests` | Allow all for reassessment_requests | `CREATE POLICY "Allow all for reassessment_requests" ON public.reassessment_requests FOR ALL TO public USING (true) WITH CHECK (true);` |
| `assessment_config` | Allow all for assessment_config | `CREATE POLICY "Allow all for assessment_config" ON public.assessment_config FOR ALL TO public USING (true) WITH CHECK (true);` |
| `skill_registries` | Allow all for skill_registries | `CREATE POLICY "Allow all for skill_registries" ON public.skill_registries FOR ALL USING (true) WITH CHECK (true);` |
| `skill_registry_items` | Allow all for skill_registry_items | `CREATE POLICY "Allow all for skill_registry_items" ON public.skill_registry_items FOR ALL USING (true) WITH CHECK (true);` |
| `assessment_templates` | Allow all for assessment_templates | `CREATE POLICY "Allow all for assessment_templates" ON public.assessment_templates FOR ALL USING (true) WITH CHECK (true);` |
| `assessment_template_skills` | Allow all for assessment_template_skills | `CREATE POLICY "Allow all for assessment_template_skills" ON public.assessment_template_skills FOR ALL USING (true) WITH CHECK (true);` |
| `assessment_template_questions` | Allow all for assessment_template_questions | `CREATE POLICY "Allow all for assessment_template_questions" ON public.assessment_template_questions FOR ALL USING (true) WITH CHECK (true);` |
| `assessment_assignments` | Allow all for assessment_assignments | `CREATE POLICY "Allow all for assessment_assignments" ON public.assessment_assignments FOR ALL USING (true) WITH CHECK (true);` |
| `registry_reviews` | Allow all for registry_reviews | `CREATE POLICY "Allow all for registry_reviews" ON public.registry_reviews FOR ALL USING (true) WITH CHECK (true);` |
| `registry_review_items` | Allow all for registry_review_items | `CREATE POLICY "Allow all for registry_review_items" ON public.registry_review_items FOR ALL USING (true) WITH CHECK (true);` |

question_settings and its policy are renamed to competency_levels. Policies on the two
dropped cycle tables are excluded. All surviving policies shown are permissive FOR ALL.

## Function revisions

| Function | Source | Final treatment in local history |
|---|---|---|
| `check_single_active_cycle` | supabase/migrations/20260326094913_408530b6-1ee9-40b5-821c-56bd574f9564.sql | Dropped April 27 with CASCADE |
| `get_question_counts` | supabase/migrations/20260410112705_f6d65264-0487-46a4-9733-a31f333c520b.sql | Retained; requires tenant authorization review |
| `enforce_single_draft_registry` | supabase/migrations/20260413171517_8909dba3-4333-4616-8a90-a81dd094828a.sql | Superseded June 3 |
| `enforce_single_draft_registry` | supabase/migrations/20260603141448_be3d012a-454c-4138-8dbb-d915235fa01d.sql | Final definition with search_path |
| `block_archived_employee_writes` | drizzle/migrations/0000_archived_employee_read_only.sql | Superseded by 0001 |
| `block_archived_employee_writes` | drizzle/migrations/0001_archived_employee_read_only_fix_types.sql | Final text-ID definition |

## Triggers

| Name | Declaration | Final local status |
|---|---|---|
| `trg_check_single_active_cycle` | `CREATE TRIGGER trg_check_single_active_cycle BEFORE INSERT OR UPDATE ON public.review_cycles FOR EACH ROW EXECUTE FUNCTION public.check_single_active_cycle();` | Removed with cycle function/table |
| `enforce_single_draft_registry_trigger` | `CREATE TRIGGER enforce_single_draft_registry_trigger BEFORE INSERT OR UPDATE ON public.skill_registries FOR EACH ROW EXECUTE FUNCTION public.enforce_single_draft_registry();` | Retained if both histories applied |
| `trg_archived_ro_registry_reviews` | `CREATE TRIGGER trg_archived_ro_registry_reviews BEFORE INSERT OR UPDATE OR DELETE ON public.registry_reviews FOR EACH ROW EXECUTE FUNCTION public.block_archived_employee_writes();` | Retained if both histories applied |
| `trg_archived_ro_registry_review_items` | `CREATE TRIGGER trg_archived_ro_registry_review_items BEFORE INSERT OR UPDATE OR DELETE ON public.registry_review_items FOR EACH ROW EXECUTE FUNCTION public.block_archived_employee_writes();` | Retained if both histories applied |
| `trg_archived_ro_assessment_questions` | `CREATE TRIGGER trg_archived_ro_assessment_questions BEFORE INSERT OR UPDATE OR DELETE ON public.assessment_questions FOR EACH ROW EXECUTE FUNCTION public.block_archived_employee_writes();` | Retained if both histories applied |
| `trg_archived_ro_assessments` | `CREATE TRIGGER trg_archived_ro_assessments BEFORE UPDATE OR DELETE ON public.assessments FOR EACH ROW EXECUTE FUNCTION public.block_archived_employee_writes();` | Retained if both histories applied |

Five trigger installations survive in the combined intended state. Drizzle's second migration
replaces only its function body and depends on the first migration's trigger installations.

## Publication operations

- `ALTER PUBLICATION supabase_realtime ADD TABLE public.skill_registries;` — supabase/migrations/20260413171517_8909dba3-4333-4616-8a90-a81dd094828a.sql
- `ALTER PUBLICATION supabase_realtime DROP TABLE public.skill_registries;` — supabase/migrations/20260702135359_2b763e24-655f-416b-bb52-5b88e553afae.sql

The operations cancel for this table in the local history. No active realtime dependency is
inferred from the earlier ADD alone.

## Excluded historical objects

- question_settings: renamed to competency_levels; not an additional final table.
- review_cycles: dropped April 27.
- cycle_domain_selections: dropped April 27.
- check_single_active_cycle and trg_check_single_active_cycle: removed.
