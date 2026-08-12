-- Run as a role with CREATE INTEGRATION privilege and replace the email.
CREATE NOTIFICATION INTEGRATION IF NOT EXISTS TRADE_EMAIL_INT
  TYPE=EMAIL ENABLED=TRUE
  ALLOWED_RECIPIENTS=('technicalt@gmail.com');

CREATE OR REPLACE ALERT TRADE_DB.MONITORING.NO_TRADE_ARRIVAL_ALERT
  WAREHOUSE=TRADE_WH
  SCHEDULE='15 MINUTE'
  IF (EXISTS (
    SELECT 1
    FROM TRADE_DB.RAW.RAW_TRADES
    HAVING datediff('minute', max(ingested_at), current_timestamp()) > 30
  ))
  THEN CALL SYSTEM$SEND_EMAIL(
    'TRADE_EMAIL_INT', 'technicalt@gmail.com',
    'Trade pipeline arrival delay',
    'No trade data has arrived for more than 30 minutes.'
  );

ALTER ALERT TRADE_DB.MONITORING.NO_TRADE_ARRIVAL_ALERT RESUME;
