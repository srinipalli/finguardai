from typing import List, Optional, Dict, Any
from datetime import datetime, timedelta
from ..utils.db import get_connection
from ..config import settings as config
from ..utils.schemas import TransactionEvent, DecisionOutcome, Alert

def insert_transaction(evt: TransactionEvent):
    sql = f"""
        INSERT INTO {config.TBL_TRANSACTIONS}
        (EVENT_ID, ACCOUNT_ID, USER_ID, AMOUNT, CURRENCY, CHANNEL, MCC, MERCHANT_ID,
         TS_UTC, LATITUDE, LONGITUDE, DEVICE_ID, IP_ADDR, COUNTRY, STATE, CITY, EXTRA_JSON)
        VALUES (:1,:2,:3,:4,:5,:6,:7,:8,:9,:10,:11,:12,:13,:14,:15,:16,:17)
    """
    extra_json = None
    if evt.extra:
        import json as _json
        extra_json = _json.dumps(evt.extra)
    with get_connection() as con:
        with con.cursor() as cur:
            cur.execute(sql, [
                evt.event_id, evt.account_id, evt.user_id, evt.amount, evt.currency,
                evt.channel, evt.mcc, evt.merchant_id, evt.timestamp, evt.lat, evt.lon,
                evt.device_id, evt.ip, evt.country, evt.state, evt.city, extra_json
            ])
        con.commit()

def upsert_device_seen(account_id: str, device_id: Optional[str]):
    if not device_id:
        return
    sql = f"""
        MERGE INTO {config.TBL_DEVICES_SEEN} d
        USING (SELECT :account_id AS ACCOUNT_ID, :device_id AS DEVICE_ID FROM dual) s
        ON (d.ACCOUNT_ID = s.ACCOUNT_ID AND d.DEVICE_ID = s.DEVICE_ID)
        WHEN NOT MATCHED THEN INSERT (ACCOUNT_ID, DEVICE_ID, FIRST_SEEN_UTC)
        VALUES (s.ACCOUNT_ID, s.DEVICE_ID, SYSTIMESTAMP AT TIME ZONE 'UTC')
    """
    with get_connection() as con:
        with con.cursor() as cur:
            cur.execute(sql, dict(account_id=account_id, device_id=device_id))
        con.commit()

def is_device_seen(account_id: str, device_id: Optional[str]) -> bool:
    if not device_id:
        return False
    sql = f"SELECT 1 FROM {config.TBL_DEVICES_SEEN} WHERE ACCOUNT_ID=:1 AND DEVICE_ID=:2 FETCH FIRST 1 ROWS ONLY"
    with get_connection() as con:
        with con.cursor() as cur:
            cur.execute(sql, [account_id, device_id])
            return cur.fetchone() is not None

def is_merchant_blacklisted(merchant_id: Optional[str]) -> bool:
    if not merchant_id:
        return False
    sql = f"SELECT 1 FROM {config.TBL_MERCHANT_BLACKLIST} WHERE MERCHANT_ID=:1 AND IS_ACTIVE='Y'"
    with get_connection() as con:
        with con.cursor() as cur:
            cur.execute(sql, [merchant_id])
            return cur.fetchone() is not None

def recent_events(account_id: str, window: timedelta) -> List[Dict[str, Any]]:
    sql = f"""
        SELECT TS_UTC, AMOUNT, LATITUDE, LONGITUDE, DEVICE_ID, MERCHANT_ID, CHANNEL
        FROM {config.TBL_TRANSACTIONS}
        WHERE ACCOUNT_ID=:1 AND TS_UTC >= (SYSTIMESTAMP AT TIME ZONE 'UTC') - NUMTODSINTERVAL(:2, 'SECOND')
        ORDER BY TS_UTC
    """
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
        VALUES (:1,:2,:3,:4,:5,:6)
    """
    import json as _json
    with get_connection() as con:
        with con.cursor() as cur:
            cur.execute(sql, [
                dec.decision_id, dec.event_id, dec.action, dec.risk_score,
                _json.dumps(dec.reasons), dec.created_at
            ])
        con.commit()

def insert_alerts(alerts: List[Alert]):
    if not alerts:
        return
    sql = f"""
        INSERT INTO {config.TBL_ALERTS}
        (ALERT_ID, EVENT_ID, SEVERITY, TITLE, DESCRIPTION, CREATED_AT_UTC, TAGS_JSON)
        VALUES (:1,:2,:3,:4,:5,:6,:7)
    """
    import json as _json
    data = [
        (a.alert_id, a.event_id, a.severity, a.title, a.description, a.created_at, _json.dumps(a.tags))
        for a in alerts
    ]
    with get_connection() as con:
        with con.cursor() as cur:
            cur.executemany(sql, data)
        con.commit()


def upsert_blacklist(merchant_id: str, is_active: str = 'Y', reason: str = None):
    sql = f"""
        MERGE INTO {config.TBL_MERCHANT_BLACKLIST} t
        USING (SELECT :m AS MERCHANT_ID FROM dual) s
        ON (t.MERCHANT_ID = s.MERCHANT_ID)
        WHEN MATCHED THEN UPDATE SET IS_ACTIVE=:a, REASON=:r
        WHEN NOT MATCHED THEN INSERT (MERCHANT_ID, IS_ACTIVE, REASON)
        VALUES (:m, :a, :r)
    """
    with get_connection() as con:
        with con.cursor() as cur:
            cur.execute(sql, dict(m=merchant_id, a=is_active, r=reason))
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
