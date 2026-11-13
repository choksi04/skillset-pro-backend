\set ON_ERROR_STOP on
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ, READ ONLY;
SET LOCAL statement_timeout = '60s';
DO $guard$
BEGIN
 IF current_database() <> 'skillset_pro_rehearsal_20261112' THEN
  RAISE EXCEPTION 'Wrong database for this preflight; no checks executed';
 END IF;
END
$guard$;

-- Historical INSERTs into these tables can be rejected by archived-user guards.
-- Aggregate counts only; no employee identities or answers are returned.
SELECT 'assessment_questions' AS guarded_table, count(*) AS rows_with_nonactive_employee
FROM public.assessment_questions q
JOIN public.assessments a ON a.id=q.assessment_id
JOIN public.users u ON u.id=a.employee_id
WHERE u.status IS NOT NULL AND u.status<>'active'
UNION ALL
SELECT 'registry_reviews',count(*)
FROM public.registry_reviews r
JOIN public.skill_registries s ON s.id=r.registry_id
JOIN public.users u ON u.id=s.employee_id
WHERE u.status IS NOT NULL AND u.status<>'active'
UNION ALL
SELECT 'registry_review_items',count(*)
FROM public.registry_review_items i
JOIN public.registry_reviews r ON r.id=i.review_id
JOIN public.skill_registries s ON s.id=r.registry_id
JOIN public.users u ON u.id=s.employee_id
WHERE u.status IS NOT NULL AND u.status<>'active';

-- The current draft trigger can reject soft-deleted drafts if another live draft exists.
SELECT count(*) AS employees_with_multiple_live_drafts
FROM (
 SELECT employee_id FROM public.skill_registries
 WHERE status='draft' AND deleted_on IS NULL
 GROUP BY employee_id HAVING count(*)>1
) duplicates;
SELECT count(*) AS soft_deleted_drafts_with_other_live_draft
FROM public.skill_registries old_draft
WHERE old_draft.status='draft' AND old_draft.deleted_on IS NOT NULL
AND EXISTS (
 SELECT 1 FROM public.skill_registries live_draft
 WHERE live_draft.employee_id=old_draft.employee_id
 AND live_draft.status='draft' AND live_draft.deleted_on IS NULL
 AND live_draft.id<>old_draft.id
);

-- Unresolved links can cause the existing archive guard to fail open.
SELECT 'assessments_without_user' AS finding,count(*) AS rows_affected
FROM public.assessments a LEFT JOIN public.users u ON u.id=a.employee_id WHERE u.id IS NULL
UNION ALL
SELECT 'registries_without_user',count(*)
FROM public.skill_registries s LEFT JOIN public.users u ON u.id=s.employee_id WHERE u.id IS NULL
UNION ALL
SELECT 'registry_reviews_without_registry',count(*)
FROM public.registry_reviews r LEFT JOIN public.skill_registries s ON s.id=r.registry_id WHERE s.id IS NULL
UNION ALL
SELECT 'registry_review_items_without_review',count(*)
FROM public.registry_review_items i LEFT JOIN public.registry_reviews r ON r.id=i.review_id WHERE r.id IS NULL;

-- FK load ordering must use the declared graph; logical links require separate mapping.
SELECT c.conrelid::regclass::text AS child_table,
       c.confrelid::regclass::text AS parent_table,
       pg_get_constraintdef(c.oid,false) AS definition
FROM pg_constraint c JOIN pg_class t ON t.oid=c.conrelid
JOIN pg_namespace n ON n.oid=t.relnamespace
WHERE n.nspname='public' AND c.contype='f'
ORDER BY child_table,parent_table;
COMMIT;
