# Infrastructure (Terraform) — cible BigQuery

Provisionne l'entrepot **BigQuery** qui accueille les modeles dbt en production,
ainsi qu'un compte de service pour la CI/CD.

```bash
terraform init
terraform plan  -var="project_id=mon-projet-gcp"
terraform apply -var="project_id=mon-projet-gcp"
```

Une fois le dataset cree, lancer dbt sur la cible cloud :

```bash
GCP_PROJECT=mon-projet-gcp GCP_KEYFILE=/chemin/gcp.json \
  dbt build --profiles-dir . --target prod
```

> Le pipeline tourne a l'identique en local (DuckDB) et sur BigQuery : **les memes
> modeles dbt, sans changement de code**. Cette portabilite est le point cle des
> postes Data Platform (Ofi Invest) et DataOps/GCP (Doctolib).
