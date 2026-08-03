.PHONY: generate bootstrap load dbt-build dashboard lint

generate:
	python data_generator/trade_generator.py --count 1000 --invalid-ratio 0.10 --output sample_data/trades.csv

bootstrap:
	snowsql -f snowflake/01_bootstrap.sql
	snowsql -f snowflake/02_raw_objects.sql
	snowsql -f snowflake/03_monitoring_objects.sql

load:
	python data_generator/load_to_snowflake.py --file sample_data/trades.csv

dbt-build:
	cd dbt_trade_project && dbt build --profiles-dir .

dashboard:
	streamlit run streamlit_dashboard/app.py

lint:
	ruff check data_generator airflow streamlit_dashboard
