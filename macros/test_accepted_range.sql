{#
  Test generique personnalise : verifie qu'une colonne reste dans un intervalle.
  Sans dependance externe (dbt_utils) pour garder la CI legere et reproductible.
  Utilisation dans un schema.yml :
      data_tests:
        - accepted_range: { min_value: 0, max_value: 1 }
#}
{% test accepted_range(model, column_name, min_value, max_value) %}

select {{ column_name }}
from {{ model }}
where {{ column_name }} < {{ min_value }}
   or {{ column_name }} > {{ max_value }}

{% endtest %}
