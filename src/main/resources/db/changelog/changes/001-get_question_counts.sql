-- Development baseline draft from reviewed application-only archive.
-- No business data, source ownership, grants or managed-schema objects.

CREATE FUNCTION public.get_question_counts() RETURNS json
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  SELECT json_build_object(
    'total', COUNT(*),
    'published', COUNT(*) FILTER (WHERE status = 'published'),
    'draft', COUNT(*) FILTER (WHERE status = 'draft'),
    'disabled', COUNT(*) FILTER (WHERE status = 'disabled'),
    'ai_generated', COUNT(*) FILTER (WHERE ai_generated = true)
  )
  FROM public.questions
  WHERE deleted_on IS NULL;
$$;
