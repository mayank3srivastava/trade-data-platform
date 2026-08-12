resource "snowflake_database" "trade" {
  name    = var.database_name
  comment = "Trade data engineering case study"
}

resource "snowflake_warehouse" "trade" {
  name                = var.warehouse_name
  warehouse_size      = "XSMALL"
  auto_suspend        = 60
  auto_resume         = true
  initially_suspended = true
}

resource "snowflake_account_role" "pipeline" {
  name    = var.pipeline_role_name
  comment = "Runtime role for trade ETL"
}

resource "snowflake_schema" "schemas" {
  for_each = toset(["RAW", "CURATED", "AUDIT", "MONITORING"])
  database = snowflake_database.trade.name
  name     = each.value
}

resource "snowflake_grant_privileges_to_account_role" "warehouse_usage" {
  account_role_name = snowflake_account_role.pipeline.name
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.trade.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "database_usage" {
  account_role_name = snowflake_account_role.pipeline.name
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.trade.name
  }
}
