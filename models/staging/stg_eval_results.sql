-- Nettoyage de la table de faits brute (grain : configuration x question).
-- Construit une cle de configuration stable (config_key) et une cle de ligne.
with source as (
    select * from {{ ref('raw_eval_results') }}
)
select
    md5(
        concat_ws('|', embedding, cast(chunk_size as varchar),
                  cast(chunk_overlap as varchar), cast(top_k as varchar))
    )                                   as config_key,
    md5(
        concat_ws('|', embedding, cast(chunk_size as varchar),
                  cast(chunk_overlap as varchar), cast(top_k as varchar), question_id)
    )                                   as retrieval_key,
    embedding,
    cast(chunk_size as integer)         as chunk_size,
    cast(chunk_overlap as integer)      as chunk_overlap,
    cast(top_k as integer)              as top_k,
    question_id,
    cast(hit as integer)                as hit,
    cast(reciprocal_rank as double)     as reciprocal_rank,
    cast(span_recall as integer)        as span_recall,
    cast(precision as double)           as precision
from source
