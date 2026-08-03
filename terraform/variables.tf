variable "snowflake_organization_name" { type = string }
variable "snowflake_account_name" { type = string }
variable "snowflake_user" { type = string }
variable "snowflake_password" { type = string; sensitive = true }
variable "database_name" { type = string; default = "TRADE_DB" }
variable "warehouse_name" { type = string; default = "TRADE_WH" }
variable "pipeline_role_name" { type = string; default = "TRADE_PIPELINE_ROLE" }
