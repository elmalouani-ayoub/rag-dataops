-- Dimension source : les questions du jeu d'evaluation.
with source as (
    select * from {{ ref('raw_questions') }}
)
select
    question_id,
    question,
    source_doc,
    answer
from source
