from typing import List, Optional, Dict, Any
from datetime import datetime, timedelta
from ..utils.db import get_connection
from ..config import settings as config
from ..utils.schemas import TransactionEvent, DecisionOutcome, Alert

def insert_transaction(evt: TransactionEvent):
    # Insert into fg_transaction table. Map optional/extra fields using evt.extra when needed.
    sql = f"""
        INSERT INTO {config.TBL_TRANSACTIONS}
        (EVENT_ID, EVENT_TS, ACCOUNT_ID, COUNTERPARTY_ACCT, MERCHANT_ID, AMOUNT, CURRENCY,
         CHANNEL, GEOLAT, GEOLON, IP_ADDR, DEVICE_ID, STATUS, CREATED_AT)
        VALUES (:1,:2,:3,:4,:5,:6,:7,:8,:9,:10,:11,:12,:13,SYSTIMESTAMP AT TIME ZONE 'UTC')
    """
    # Use evt.extra for fields not present on the TransactionEvent model (e.g. counterparty, status)
    counterparty = evt.extra.get('counterparty_acct') if isinstance(evt.extra, dict) else None
    status = evt.extra.get('status') if isinstance(evt.extra, dict) else None
    with get_connection() as con:
        with con.cursor() as cur:
            cur.execute(sql, [
                evt.event_id,
                evt.timestamp,
                evt.account_id,
                counterparty,
                evt.merchant_id,
                evt.amount,
                evt.currency,
                evt.channel,
                evt.lat,
                evt.lon,
                evt.ip,
                evt.device_id,
                status
            ])
        con.commit()

def upsert_device_seen(account_id: str, device_id: Optional[str]):
    try:
        if not device_id:
            return
        sql = f"""
            MERGE INTO {config.TBL_DEVICES_SEEN} d
            USING (SELECT :account_id AS CUSTOMER_ID, :device_id AS DEVICE_FINGERPRINT FROM dual) s
            ON (d.CUSTOMER_ID = s.CUSTOMER_ID AND d.DEVICE_FINGERPRINT = s.DEVICE_FINGERPRINT)
            WHEN NOT MATCHED THEN INSERT (CUSTOMER_ID, DEVICE_ID, DEVICE_FINGERPRINT,LAST_SEEN_AT)
            VALUES (s.CUSTOMER_ID, fg_device_seq.NEXTVAL ,s.DEVICE_FINGERPRINT, SYSTIMESTAMP AT TIME ZONE 'UTC')
        """
        print("upsert_device_seen:", account_id, device_id,sql)
        with get_connection() as con:
            with con.cursor() as cur:
                cur.execute(sql, dict(account_id=account_id, device_id=device_id))
            con.commit()
        print("upsert_device_seen completed:", account_id, device_id)

    except Exception as e:
        import traceback
        traceback.print_exc()


        


def is_device_seen(account_id: str, device_id: Optional[str]) -> bool:
    
    try:
        if not device_id:
            return False
        sql = f"SELECT 1 FROM {config.TBL_DEVICES_SEEN} WHERE CUSTOMER_ID=:1 AND DEVICE_FINGERPRINT=:2 FETCH FIRST 1 ROWS ONLY"
        with get_connection() as con:
            with con.cursor() as cur:
                cur.execute(sql, [account_id, device_id])
                return cur.fetchone() is not None
    except Exception as e:
        import traceback
        traceback.print_exc()
        

def is_merchant_blacklisted(merchant_id: Optional[str]) -> bool:
    if not merchant_id:
        return False
    # fg_blacklist has columns: BL_ID, TYPE, VALUE, REASON, VALID_FROM, VALID_TO
    # A merchant is considered blacklisted if there's a row with TYPE='MERCHANT' and VALUE=merchant_id
    # and the VALID_TO is null or in the future.
    sql = f"""
        SELECT 1 FROM {config.TBL_MERCHANT_BLACKLIST}
        WHERE TYPE = 'MERCHANT' AND VALUE = :1
          AND (VALID_TO IS NULL OR VALID_TO > SYSTIMESTAMP AT TIME ZONE 'UTC')
        FETCH FIRST 1 ROWS ONLY
    """
    with get_connection() as con:
        with con.cursor() as cur:
            cur.execute(sql, [merchant_id])
            return cur.fetchone() is not None

def recent_events(account_id: str, window: timedelta) -> List[Dict[str, Any]]:
    # Select recent events using EVENT_TS (event timestamp). Also keep CREATED_AT for record insertion time.
    sql = f"""
        SELECT EVENT_TS AS CREATED_AT, AMOUNT, GEOLAT, GEOLON, DEVICE_ID, MERCHANT_ID, CHANNEL
        FROM {config.TBL_TRANSACTIONS}
        WHERE ACCOUNT_ID=:1 AND EVENT_TS >= (SYSTIMESTAMP AT TIME ZONE 'UTC') - NUMTODSINTERVAL(:2, 'SECOND')
        ORDER BY EVENT_TS
    """
    print('recent_events', sql, account_id, window)
    with get_connection() as con:
        with con.cursor() as cur:
            cur.execute(sql, [account_id, int(window.total_seconds())])
            rows = cur.fetchall()
            cols = [d[0] for d in cur.description]
            return [dict(zip(cols, r)) for r in rows]

def insert_decision(dec: DecisionOutcome):
    sql = f"""
        INSERT INTO {config.TBL_DECISIONS}
        (DECISION_ID, EVENT_ID, ACTION, RISK_SCORE, REASONS_JSON, CREATED_AT_UTC)
        VALUES (fg_decision_seq.NEXTVAL, :1,:2,:3,:4,sysdate)
    """
    print("insert_decision:", dec)
    import json as _json
    with get_connection() as con:
        with con.cursor() as cur:
            cur.execute(sql, [
                  dec.event_id, dec.action, dec.risk_score,
                _json.dumps(dec.reasons)
            ])
        con.commit()

def insert_alerts(alerts: List[Alert]):
    print(f"insert_alerts: {len(alerts)} alerts")
    if not alerts:
        return
    sql = f"""
        INSERT INTO {config.TBL_ALERTS}
        (ALERT_ID, EVENT_ID, TITLE,RISK_SCORE, DECISION, REASON_SUMMARY,CREATED_AT, DECIDED_AT)
        VALUES (fg_alerts_seq.NEXTVAL,:1,:2,:3,:4,:5,sysdate,sysdate)
    """
 
    data = [
        ( a.event_id,  a.title,a.risk_score,a.severity, a.description)
        for a in alerts
    ]
    with get_connection() as con:
        with con.cursor() as cur:
            cur.executemany(sql, data)
        con.commit()
    print(f"insert_alerts: done")

def upsert_blacklist(merchant_id: str, is_active: str = 'Y', reason: str = None):
    # Use MERGE semantics but align to fg_blacklist schema (TYPE, VALUE, REASON, VALID_FROM, VALID_TO)
    # When activating (is_active='Y'): ensure a row exists with VALID_FROM set and VALID_TO NULL.
    # When deactivating (is_active!='Y'): set VALID_TO to now.
    sql = f"""
        MERGE INTO {config.TBL_MERCHANT_BLACKLIST} t
        USING (SELECT :type AS TYPE, :value AS VALUE FROM dual) s
        ON (t.TYPE = s.TYPE AND t.VALUE = s.VALUE)
        WHEN MATCHED THEN UPDATE SET
            REASON = :r,
            VALID_FROM = NVL(t.VALID_FROM, SYSTIMESTAMP AT TIME ZONE 'UTC'),
            VALID_TO = CASE WHEN :a = 'Y' THEN NULL ELSE SYSTIMESTAMP AT TIME ZONE 'UTC' END
        WHEN NOT MATCHED THEN
            INSERT (TYPE, VALUE, REASON, VALID_FROM, VALID_TO)
            VALUES (:type, :value, :r, SYSTIMESTAMP AT TIME ZONE 'UTC', NULL)
    """
    params = dict(type='MERCHANT', value=merchant_id, a=is_active, r=reason)
    with get_connection() as con:
        with con.cursor() as cur:
            cur.execute(sql, params)
        con.commit()


# ---- Model registry / scores --------------------------------------------------
def get_active_model_id(model_name: str) -> str:
    """
    Return the active model_id for a model name from FG_MODEL_VERSIONS.
    Expected columns: MODEL_ID, MODEL_NAME, VERSION, IS_ACTIVE ('Y'/'N').
    """
    sql = f"SELECT MODEL_ID FROM {config.TBL_MODEL_VERSIONS} WHERE MODEL_NAME=:1 AND IS_ACTIVE='Y' FETCH FIRST 1 ROWS ONLY"
    with get_connection() as con:
        with con.cursor() as cur:
            cur.execute(sql, [model_name])
            row = cur.fetchone()
            if not row:
                raise RuntimeError(f"No active model for {model_name}")
            return row[0]

def insert_model_score(txn_id: str, model_id: str, risk_score: float, threshold_used: float, inference_ms: int, explain_json: dict):
    sql = f"""
        INSERT INTO {config.TBL_MODEL_SCORES}
        (TXN_ID, MODEL_ID, RISK_SCORE, THRESHOLD_USED, INFERENCE_MS, EXPLAIN_JSON, CREATED_AT_UTC)
        VALUES (:1,:2,:3,:4,:5,:6,SYSTIMESTAMP AT TIME ZONE 'UTC')
    """
    import json as _json
    with get_connection() as con:
        with con.cursor() as cur:
            cur.execute(sql, [
                txn_id, model_id, float(risk_score), float(threshold_used), int(inference_ms),
                _json.dumps(explain_json or {})
            ])
        con.commit()

def get_latest_model_score(txn_id: str):
    sql = f"""
        SELECT TXN_ID, MODEL_ID, RISK_SCORE, THRESHOLD_USED, INFERENCE_MS, EXPLAIN_JSON, CREATED_AT_UTC
        FROM {config.TBL_MODEL_SCORES}
        WHERE TXN_ID=:1
        ORDER BY CREATED_AT_UTC DESC
        FETCH FIRST 1 ROWS ONLY
    """
    with get_connection() as con:
        with con.cursor() as cur:
            cur.execute(sql, [txn_id])
            row = cur.fetchone()
            if not row:
                return None
            cols = [d[0] for d in cur.description]
            rec = dict(zip(cols, row))
            try:
                import json as _json
                rec["EXPLAIN_JSON"] = _json.loads(rec.get("EXPLAIN_JSON") or "{}")
            except Exception:
                pass
            return rec
