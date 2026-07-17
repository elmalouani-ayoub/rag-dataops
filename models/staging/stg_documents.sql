-- Dimension source : les documents de la base de connaissances.
with source as (
    select * from {{ ref('raw_documents') }}
)
select
    doc_id,
    title,
    category,
    cast(word_count as integer) as word_count
from source
