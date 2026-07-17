-- Dimension : une configuration d'hyperparametres unique.
with configs as (
    select distinct
        config_key, embedding, chunk_size, chunk_overlap, top_k
    from {{ ref('stg_eval_results') }}
)
select
    config_key,
    embedding,
    chunk_size,
    chunk_overlap,
    top_k,
    -- attribut derive utile pour l'analyse
    chunk_size - chunk_overlap                  as effective_step,
    concat(embedding, ' | size=', chunk_size,
           ' | ov=', chunk_overlap, ' | k=', top_k) as config_label
from configs
