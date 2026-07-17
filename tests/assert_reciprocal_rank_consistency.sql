-- Test singulier de coherence metier :
-- le rang reciproque (reciprocal_rank) doit etre 0 exactement quand hit = 0,
-- et strictement positif quand hit = 1. Toute ligne violant cette regle
-- signale une incoherence dans le calcul des metriques -> le test echoue.
select
    retrieval_key,
    hit,
    reciprocal_rank
from {{ ref('fct_retrieval') }}
where (hit = 0 and reciprocal_rank != 0)
   or (hit = 1 and reciprocal_rank <= 0)
