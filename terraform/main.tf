# Infrastructure as Code (IaC) — provisionne l'entrepot BigQuery cible.
# Montre la portabilite vers le cloud (offres Doctolib : GCP + IaC ; Ofi Invest : BigQuery).
# Optionnel : necessite un compte GCP. Le pipeline tourne aussi 100 % en local (DuckDB).

terraform {
  required_version = ">= 1.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Dataset qui accueillera les modeles dbt (staging + marts).
resource "google_bigquery_dataset" "rag_dataops" {
  dataset_id                  = "rag_dataops"
  friendly_name               = "RAG DataOps"
  description                 = "Entrepot des resultats d'evaluation RAG (schema en etoile, gere par dbt)."
  location                    = var.location
  default_table_expiration_ms = null

  labels = {
    project     = "rag-dataops"
    managed_by  = "terraform"
    environment = "prod"
  }
}

# Compte de service dedie a l'execution du pipeline dbt en CI/CD.
resource "google_service_account" "dbt_runner" {
  account_id   = "dbt-runner"
  display_name = "dbt pipeline runner"
}

resource "google_bigquery_dataset_iam_member" "dbt_editor" {
  dataset_id = google_bigquery_dataset.rag_dataops.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.dbt_runner.email}"
}
