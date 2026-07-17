-- Dimension : question d'evaluation, reliee a son document source.
select
    q.question_id      as question_key,
    q.question_id,
    q.question,
    q.answer,
    q.source_doc       as document_key   -- FK vers dim_document
from {{ ref('stg_questions') }} q
