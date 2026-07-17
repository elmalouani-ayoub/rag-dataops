-- Table de faits centrale (schema en etoile).
-- Grain : une ligne par (configuration, question). Cles etrangeres vers les dimensions.
select
    r.retrieval_key,
    r.config_key                as config_key,      -- FK -> dim_config
    r.question_id               as question_key,    -- FK -> dim_question
    r.embedding                 as embedding_key,   -- FK -> dim_embedding
    -- mesures
    r.hit,
    r.reciprocal_rank,
    r.span_recall,
    r.precision
from {{ ref('stg_eval_results') }} r
