from __future__ import annotations

import os
import pandas as pd
import snowflake.connector
import streamlit as st

st.set_page_config(page_title="Trade Pipeline Dashboard", layout="wide")
st.title("Trade Processing Status")

@st.cache_resource
def connection():
    return snowflake.connector.connect(
        account=os.environ["SNOWFLAKE_ACCOUNT"],
        user=os.environ["SNOWFLAKE_USER"],
        password=os.environ["SNOWFLAKE_PASSWORD"],
        role=os.getenv("SNOWFLAKE_ROLE", "TRADE_PIPELINE_ROLE"),
        warehouse=os.getenv("SNOWFLAKE_WAREHOUSE", "TRADE_WH"),
        database=os.getenv("SNOWFLAKE_DATABASE", "TRADE_DB"),
    )

conn = connection()
status_df = pd.read_sql("""
    SELECT trade_status, COUNT(*) AS trade_count
    FROM TRADE_DB.CURATED.TRADE_STATUS
    GROUP BY trade_status ORDER BY trade_status
""", conn)
reject_df = pd.read_sql("""
    SELECT rejection_reason, COUNT(*) AS rejected_count
    FROM TRADE_DB.CURATED.REJECTED_TRADES
    GROUP BY rejection_reason ORDER BY rejected_count DESC
""", conn)

c1, c2 = st.columns(2)
with c1:
    st.subheader("Current trade status")
    st.bar_chart(status_df.set_index("TRADE_STATUS"))
with c2:
    st.subheader("Rejections by reason")
    st.bar_chart(reject_df.set_index("REJECTION_REASON"))

st.subheader("Latest rejected events")
st.dataframe(pd.read_sql("""
    SELECT trade_id, version, rejection_reason, rejected_at
    FROM TRADE_DB.CURATED.REJECTED_TRADES
    ORDER BY rejected_at DESC LIMIT 100
""", conn), use_container_width=True)
