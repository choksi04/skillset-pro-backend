-- Development baseline draft from reviewed application-only archive.
-- No business data, source ownership, grants or managed-schema objects.

CREATE TABLE public.ai_evaluations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    attempt_id uuid NOT NULL,
    question_id text NOT NULL,
    score integer DEFAULT 0 NOT NULL,
    feedback text DEFAULT ''::text NOT NULL,
    dimensions jsonb DEFAULT '[]'::jsonb NOT NULL,
    confidence numeric(3,2) DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    created_by text,
    modified_by text,
    modified_at timestamp with time zone,
    deleted_by text,
    deleted_on timestamp with time zone
);

CREATE TABLE public.assessment_assignments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    tenant_id text DEFAULT 'tenant-001'::text NOT NULL,
    template_id uuid NOT NULL,
    employee_id text NOT NULL,
    domain_id text,
    status text DEFAULT 'new'::text NOT NULL,
    attempt_count integer DEFAULT 0 NOT NULL,
    max_attempts integer DEFAULT 1 NOT NULL,
    assessment_id uuid,
    assigned_at timestamp with time zone DEFAULT now() NOT NULL,
    assigned_by text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    modified_at timestamp with time zone,
    modified_by text,
    deleted_on timestamp with time zone,
    deleted_by text,
    revoke_reason text
);

CREATE TABLE public.assessment_attempts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    assessment_id uuid NOT NULL,
    tenant_id text NOT NULL,
    employee_id text NOT NULL,
    status text DEFAULT 'in_progress'::text NOT NULL,
    total_ai_score integer,
    started_at timestamp with time zone DEFAULT now() NOT NULL,
    submitted_at timestamp with time zone,
    evaluated_at timestamp with time zone,
    created_by text,
    modified_by text,
    modified_at timestamp with time zone,
    deleted_by text,
    deleted_on timestamp with time zone,
    paused_at timestamp with time zone,
    remaining_seconds integer,
    adaptive_state jsonb DEFAULT '{}'::jsonb NOT NULL,
    evaluation_error text,
    CONSTRAINT assessment_attempts_status_check CHECK ((status = ANY (ARRAY['in_progress'::text, 'submitted'::text, 'evaluated'::text, 'reviewed'::text])))
);

CREATE TABLE public.assessment_config (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    tenant_id text DEFAULT 'tenant-001'::text NOT NULL,
    config_type text DEFAULT 'global'::text NOT NULL,
    reference_id text,
    question_type text NOT NULL,
    min_questions integer DEFAULT 2 NOT NULL,
    max_questions integer DEFAULT 6 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    modified_at timestamp with time zone,
    created_by text,
    modified_by text
);

CREATE TABLE public.assessment_questions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    assessment_id uuid NOT NULL,
    question_id text NOT NULL,
    skill_id text NOT NULL,
    target_level uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    created_by text,
    modified_by text,
    modified_at timestamp with time zone,
    deleted_by text,
    deleted_on timestamp with time zone
);

CREATE TABLE public.assessment_template_questions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    template_id uuid NOT NULL,
    question_id text NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE public.assessment_template_skills (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    template_id uuid NOT NULL,
    skill_id text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE public.assessment_templates (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    tenant_id text DEFAULT 'tenant-001'::text NOT NULL,
    name text NOT NULL,
    description text DEFAULT ''::text,
    type text NOT NULL,
    status text DEFAULT 'draft'::text NOT NULL,
    duration_minutes integer DEFAULT 45 NOT NULL,
    max_attempts integer DEFAULT 1 NOT NULL,
    reattempt_enabled boolean DEFAULT false NOT NULL,
    domain_id text,
    skill_selection_mode text,
    skills_per_assessment integer DEFAULT 5,
    questions_per_skill integer DEFAULT 4,
    question_types jsonb DEFAULT '["mcq"]'::jsonb,
    shuffle_questions boolean DEFAULT false,
    shuffle_options boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    modified_at timestamp with time zone,
    created_by text,
    modified_by text,
    deleted_on timestamp with time zone,
    deleted_by text,
    CONSTRAINT assessment_templates_max_attempts_check CHECK ((max_attempts >= 1)),
    CONSTRAINT assessment_templates_skill_selection_mode_check CHECK ((skill_selection_mode = ANY (ARRAY['top_n'::text, 'custom'::text]))),
    CONSTRAINT assessment_templates_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'active'::text]))),
    CONSTRAINT assessment_templates_type_check CHECK ((type = ANY (ARRAY['adaptive'::text, 'fixed'::text])))
);

CREATE TABLE public.assessments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    tenant_id text NOT NULL,
    employee_id text NOT NULL,
    submission_id text NOT NULL,
    domain_id text NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    duration_minutes integer DEFAULT 45 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by text,
    modified_by text,
    modified_at timestamp with time zone,
    deleted_by text,
    deleted_on timestamp with time zone,
    is_reassessment boolean DEFAULT false NOT NULL,
    parent_assessment_id uuid,
    template_id uuid,
    is_adaptive boolean DEFAULT false NOT NULL,
    CONSTRAINT assessments_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'in_progress'::text, 'completed'::text, 'reviewed'::text])))
);

CREATE TABLE public.attempt_answers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    attempt_id uuid NOT NULL,
    question_id text NOT NULL,
    answer_text text DEFAULT ''::text NOT NULL,
    time_spent_seconds integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    created_by text,
    modified_by text,
    modified_at timestamp with time zone,
    deleted_by text,
    deleted_on timestamp with time zone
);

CREATE TABLE public.attempt_skill_scores (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    attempt_id uuid NOT NULL,
    skill_id text NOT NULL,
    avg_score integer DEFAULT 0 NOT NULL,
    calculated_level integer DEFAULT 1 NOT NULL,
    question_count integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    created_by text,
    modified_by text,
    modified_at timestamp with time zone,
    deleted_by text,
    deleted_on timestamp with time zone,
    target_level integer DEFAULT 1 NOT NULL
);

CREATE TABLE public.competency_levels (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    tenant_id text DEFAULT 'tenant-001'::text NOT NULL,
    level integer NOT NULL,
    name text NOT NULL,
    label text NOT NULL,
    description text DEFAULT ''::text NOT NULL,
    score_range_min integer DEFAULT 0 NOT NULL,
    score_range_max integer DEFAULT 100 NOT NULL,
    min_questions integer DEFAULT 3 NOT NULL,
    status text DEFAULT 'active'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    modified_at timestamp with time zone,
    created_by text,
    modified_by text
);

CREATE TABLE public.domain_skill_mappings (
    id text NOT NULL,
    domain_id text NOT NULL,
    skill_id text NOT NULL,
    tenant_id text NOT NULL,
    skill_weight numeric DEFAULT 1 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by text,
    modified_by text,
    modified_at timestamp with time zone,
    deleted_by text,
    deleted_on timestamp with time zone
);

CREATE TABLE public.domains (
    id text NOT NULL,
    tenant_id text NOT NULL,
    name text NOT NULL,
    description text DEFAULT ''::text,
    status text DEFAULT 'active'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by text,
    modified_by text,
    modified_at timestamp with time zone,
    deleted_by text,
    deleted_on timestamp with time zone,
    domain_lead_id text
);

CREATE TABLE public.employee_domain_assignments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    employee_id text NOT NULL,
    domain_id text NOT NULL,
    tenant_id text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by text
);

CREATE TABLE public.manager_reviews (
    id text NOT NULL,
    tenant_id text NOT NULL,
    assessment_id uuid NOT NULL,
    attempt_id uuid NOT NULL,
    employee_id text NOT NULL,
    employee_name text NOT NULL,
    domain_id text NOT NULL,
    reviewer_id text NOT NULL,
    overall_comment text DEFAULT ''::text,
    status text DEFAULT 'pending'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    completed_at timestamp with time zone,
    created_by text,
    modified_by text,
    modified_at timestamp with time zone,
    deleted_by text,
    deleted_on timestamp with time zone
);

CREATE TABLE public.notifications (
    id text NOT NULL,
    tenant_id text NOT NULL,
    target_role text NOT NULL,
    target_user_id text,
    message text NOT NULL,
    type text NOT NULL,
    reference_id text NOT NULL,
    read boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    action_link text
);

CREATE TABLE public.official_skill_entries (
    id text NOT NULL,
    employee_id text NOT NULL,
    tenant_id text NOT NULL,
    skill_id text NOT NULL,
    final_level integer NOT NULL,
    assessment_reference text NOT NULL,
    manager_comments text DEFAULT ''::text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    cycle text NOT NULL,
    self_rating integer,
    ai_level integer NOT NULL,
    review_id text NOT NULL,
    created_by text,
    modified_by text,
    modified_at timestamp with time zone,
    deleted_by text,
    deleted_on timestamp with time zone
);

CREATE TABLE public.questions (
    id text NOT NULL,
    tenant_id text NOT NULL,
    skill_id text NOT NULL,
    competency_level uuid NOT NULL,
    question_type text NOT NULL,
    question_text text NOT NULL,
    evaluation_guidelines text DEFAULT ''::text,
    status text DEFAULT 'draft'::text NOT NULL,
    ai_generated boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by text,
    modified_by text,
    modified_at timestamp with time zone,
    deleted_by text,
    deleted_on timestamp with time zone,
    topic_id text
);

CREATE TABLE public.reassessment_requests (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    assessment_id uuid NOT NULL,
    review_id text NOT NULL,
    tenant_id text NOT NULL,
    employee_id text NOT NULL,
    skill_ids jsonb DEFAULT '[]'::jsonb NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by text
);

CREATE TABLE public.registry_review_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    review_id uuid NOT NULL,
    skill_id text NOT NULL,
    manager_score integer,
    manager_comment text DEFAULT ''::text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    modified_at timestamp with time zone
);

CREATE TABLE public.registry_reviews (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    tenant_id text NOT NULL,
    registry_id uuid NOT NULL,
    reviewer_id text NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    overall_comment text DEFAULT ''::text,
    completed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by text,
    modified_at timestamp with time zone,
    modified_by text,
    deleted_on timestamp with time zone,
    deleted_by text
);

CREATE TABLE public.review_skill_entries (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    review_id text NOT NULL,
    skill_id text NOT NULL,
    self_rating integer,
    ai_calculated_level integer NOT NULL,
    ai_score integer DEFAULT 0 NOT NULL,
    manager_action text,
    manager_adjusted_level integer,
    manager_comment text DEFAULT ''::text,
    verified_level integer
);

CREATE TABLE public.skill_categories (
    id text NOT NULL,
    name text NOT NULL,
    description text DEFAULT ''::text,
    tenant_id text DEFAULT 'tenant-001'::text NOT NULL,
    status text DEFAULT 'active'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    modified_at timestamp with time zone,
    created_by text,
    modified_by text,
    deleted_on timestamp with time zone,
    deleted_by text
);

CREATE TABLE public.skill_registries (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    tenant_id text NOT NULL,
    employee_id text NOT NULL,
    domain_id text NOT NULL,
    version_number integer NOT NULL,
    status text DEFAULT 'draft'::text NOT NULL,
    submitted_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by text,
    modified_by text,
    modified_at timestamp with time zone,
    deleted_by text,
    deleted_on timestamp with time zone
);

CREATE TABLE public.skill_registry_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    registry_id uuid NOT NULL,
    skill_id text NOT NULL,
    self_score integer NOT NULL,
    comment text,
    CONSTRAINT skill_registry_items_score_range CHECK (((self_score >= 1) AND (self_score <= 5)))
);

CREATE TABLE public.skill_registry_submissions (
    id text NOT NULL,
    tenant_id text NOT NULL,
    employee_id text NOT NULL,
    domain_id text NOT NULL,
    cycle text NOT NULL,
    status text DEFAULT 'draft'::text NOT NULL,
    submitted_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by text,
    modified_by text,
    modified_at timestamp with time zone,
    deleted_by text,
    deleted_on timestamp with time zone,
    cycle_id text
);

CREATE TABLE public.skill_self_ratings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    submission_id text NOT NULL,
    skill_id text NOT NULL,
    rating integer NOT NULL,
    comment text
);

CREATE TABLE public.skill_topics (
    id text NOT NULL,
    skill_id text NOT NULL,
    tenant_id text DEFAULT 'tenant-001'::text NOT NULL,
    name text NOT NULL,
    description text DEFAULT ''::text,
    status text DEFAULT 'active'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    modified_at timestamp with time zone,
    deleted_on timestamp with time zone,
    created_by text,
    modified_by text,
    deleted_by text
);

CREATE TABLE public.skills (
    id text NOT NULL,
    tenant_id text NOT NULL,
    skill_name text NOT NULL,
    skill_description text DEFAULT ''::text,
    skill_category text DEFAULT ''::text,
    status text DEFAULT 'active'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by text,
    modified_by text,
    modified_at timestamp with time zone,
    deleted_by text,
    deleted_on timestamp with time zone,
    tags text[] DEFAULT '{}'::text[] NOT NULL,
    category_id text
);

CREATE TABLE public.users (
    id text NOT NULL,
    tenant_id text DEFAULT 'tenant-001'::text NOT NULL,
    full_name text NOT NULL,
    email text NOT NULL,
    role text DEFAULT 'employee'::text NOT NULL,
    domain_id text,
    department text DEFAULT ''::text,
    designation text DEFAULT ''::text,
    status text DEFAULT 'active'::text NOT NULL,
    avatar_url text DEFAULT ''::text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by text,
    modified_by text,
    modified_at timestamp with time zone,
    deleted_on timestamp with time zone,
    deleted_by text
);
