-- Dimension : methode d'embedding, avec sa famille (lexical vs semantique).
with methods as (
    select distinct embedding from {{ ref('stg_eval_results') }}
)
select
    embedding                                   as embedding_key,
    embedding,
    case when embedding in ('tfidf','hashing') then 'lexical'
         else 'semantique' end                  as embedding_family,
    case embedding
        when 'tfidf'   then 'TF-IDF (vocabulaire appris, ponderation IDF)'
        when 'hashing' then 'Hashing trick (sans vocabulaire, stateless)'
        else embedding end                       as description
from methods
