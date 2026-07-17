variable "project_id" {
  type        = string
  description = "Identifiant du projet GCP."
}

variable "region" {
  type    = string
  default = "europe-west1"
}

variable "location" {
  type    = string
  default = "EU"
  description = "Localisation du dataset BigQuery."
}
