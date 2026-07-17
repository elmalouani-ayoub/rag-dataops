-- Mart d'analyse : metriques agregees par configuration (prete pour un outil BI /
-- Power BI). Reproduit, dans l'entrepot, le tableau de resultats du Projet 1.
with fct as (
    select * from {{ ref('fct_retrieval') }}
),
agg as (
    select
        config_key,
        count(*)                     as n_questions,
        avg(hit)                     as hit_rate,
        avg(reciprocal_rank)         as mrr,
        avg(span_recall)             as span_recall_rate,
        avg(precision)               as precision_at_k
    from fct
    group by 1
)
select
    c.config_label,
    c.embedding,
    c.chunk_size,
    c.chunk_overlap,
    c.top_k,
    a.n_questions,
    round(a.hit_rate, 4)          as hit_rate,
    round(a.mrr, 4)               as mrr,
    round(a.span_recall_rate, 4)  as span_recall_rate,
    round(a.precision_at_k, 4)    as precision_at_k,
    -- classement des configurations par qualite (span_recall puis MRR)
    row_number() over (
        order by a.span_recall_rate desc, a.mrr desc, a.precision_at_k desc
    )                             as quality_rank
from agg a
join {{ ref('dim_config') }} c using (config_key)
