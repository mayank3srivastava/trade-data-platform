variable "snowflake_organization_name" {
  description = "Snowflake organization name"
  type        = string
}

variable "snowflake_account_name" {
  description = "Snowflake account name"
  type        = string
}

variable "snowflake_user" {
  description = "Snowflake user used by Terraform"
  type        = string
}

variable "snowflake_password" {
  description = "Password for the Snowflake Terraform user"
  type        = string
  sensitive   = true
}

variable "database_name" {
  description = "Name of the Snowflake database"
  type        = string
  default     = "TRADE_DB"
}

variable "warehouse_name" {
  description = "Name of the Snowflake virtual warehouse"
  type        = string
  default     = "TRADE_WH"
}

variable "pipeline_role_name" {
  description = "Snowflake role used by the trade data pipeline"
  type        = string
  default     = "TRADE_PIPELINE_ROLE"
}