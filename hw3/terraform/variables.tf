variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "db_instance_name" {
  type    = string
  default = "hw3-postgres"
}

variable "db_name" {
  type    = string
  default = "periodic_table"
}

variable "db_user" {
  type    = string
  default = "hw3user"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_tier" {
  type    = string
  default = "db-f1-micro"
}
