-- Dimension : document de la base de connaissances.
select
    doc_id      as document_key,
    doc_id,
    title,
    category,
    word_count
from {{ ref('stg_documents') }}
