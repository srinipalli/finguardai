from fastapi import FastAPI, HTTPException
from fastapi.responses import StreamingResponse, JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from typing import Dict, Any
import json
import asyncio
from ..utils.kafka_bus import KafkaBus
from ..utils import dao
from ..config import settings as config

app = FastAPI(title="FinGuard MCP Tool Server", version="1.0.0")

# Allow CORS from the React dev server during development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
def health():
    return {"status": "ok"}

@app.post("/tools/ingest")
def ingest_event(event: Dict[str, Any]):
    # Push incoming transaction into Kafka ingestion topic
    try:
        bus = KafkaBus()
        key = event.get("account_id") or event.get("user_id")
        bus.publish(config.TRANSACTIONS_TOPIC, value=event, key=key)
        return {"status":"queued","topic":config.TRANSACTIONS_TOPIC}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/tools/decision/{event_id}")
def get_decision(event_id: str):
    # Fetch a previously created decision by event_id
    sql = f"SELECT DECISION_ID, ACTION, RISK_SCORE, REASONS_JSON, CREATED_AT_UTC FROM {config.TBL_DECISIONS} WHERE EVENT_ID=:1 FETCH FIRST 1 ROWS ONLY"
    with dao.get_connection() as con:
        with con.cursor() as cur:
            cur.execute(sql, [event_id])
            row = cur.fetchone()
            if not row:
                raise HTTPException(status_code=404, detail="Not found")
            cols = [d[0] for d in cur.description]
            rec = dict(zip(cols, row))
            # normalize json
            try:
                import json as _json
                rec["REASONS_JSON"] = _json.loads(rec.get("REASONS_JSON") or "[]")
            except Exception:
                pass
            return rec

@app.post("/tools/blacklist")
def blacklist(merchant_id: str, active: bool = True, reason: str = None):
    dao.upsert_blacklist(merchant_id, 'Y' if active else 'N', reason)
    return {"merchant_id": merchant_id, "active": active}

@app.get("/stream/heartbeat")
async def stream_heartbeat():
    async def eventgen():
        i = 0
        while True:
            # emit a small JSON payload per SSE message
            yield f"data: {json.dumps({'tick': i})}\n\n"
            i += 1
            await asyncio.sleep(1.0)
    return StreamingResponse(eventgen(), media_type="text/event-stream")

from ..utils.schemas import TransactionEvent
from ..perception.features import perceive
from ..memory.oracle_store import OracleMemoryStore as MemoryStore
from ..llm.planner import plan_workflow as _plan_workflow
from ..orchestrator.executor import exec_workflow as _exec_workflow
from ..utils import dao as _dao
from ..utils.db import get_connection as _get_conn
from datetime import datetime, timedelta

@app.post("/plan")
def plan(event: dict):
    """
    Return an LLM-generated tool workflow for a given event (S10-style).
    """
    memory = MemoryStore()
    evt = TransactionEvent(**event)
    p = perceive(evt, memory)
    plan = _plan_workflow(p)
    return JSONResponse(plan)

@app.post("/execute")
def execute(plan: dict):
    """
    Execute a tool workflow plan server-side (optional convenience).
    """
    result = _exec_workflow(plan)
    return JSONResponse(result)

from ..tools.ml_model_tool import score_transaction as _ml_score_transaction
from ..tools.risk_score_tool import combine_scores as _combine_scores
from ..perception.features import perceive
from ..memory.oracle_store import OracleMemoryStore as _Memory
from ..utils.schemas import TransactionEvent

@app.post("/tools/ml_score")
def ml_score(payload: dict):
    """
    Run ML model inference for a perceived event and persist model score.
    Expects: {"event": {...}, "features": {...}, "model_name": "gbm_txn", "threshold": 75.0}
    """
    model_name = payload.get("model_name") or "gbm_txn"
    threshold = float(payload.get("threshold") or 75.0)
    evt = TransactionEvent(**payload["event"])
    res = _ml_score_transaction(evt.event_id, payload["features"], model_name=model_name, threshold=threshold)
    return res

@app.post("/tools/risk_score")
def risk_score(payload: dict):
    """
    Combine latest model score with rules to produce final decision.
    Expects: {"event": {...}}
    """
    memory = _Memory()
    evt = TransactionEvent(**payload["event"])
    perceived = perceive(evt, memory)
    out = _combine_scores(perceived, memory)
    return out


# --- UI / Dashboard API proxies ------------------------------------------------
@app.get('/api/transactions/latest')
def api_latest_transactions(limit: int = 25):
    """Return recent transactions with latest model score (if any)."""
    # Use an analytic subquery to pick the latest model score per txn_id
    
    sql ="""
    Select distinct event_id , amount , channel, status,created_at from (
    SELECT   t.event_id, t.amount, t.channel, decisions.action status, TO_CHAR(t.created_at, 'YYYY-MM-DD HH24:MI:SS') as created_at,
    decisions.risk_score
    FROM fg_transactions t
    left join fg_decisions decisions
    on t.event_id = decisions.event_id)
    order by  event_id desc,created_at desc
       """ 
    
    with _get_conn() as con:
        with con.cursor() as cur:
            cur.execute(sql )   
            rows = cur.fetchall()
            cols = [d[0].lower() for d in cur.description]
            return [dict(zip(cols, r)) for r in rows]


@app.get('/api/alerts/open')
def api_open_alerts(limit: int = 25):
    sql = f"SELECT alert_id, txn_id, risk_score, decision, created_at FROM {config.TBL_ALERTS} WHERE decision IN ('PENDING','CHALLENGE') ORDER BY created_at DESC FETCH FIRST :1 ROWS ONLY"
    with _get_conn() as con:
        with con.cursor() as cur:
            cur.execute(sql, [int(limit)])
            rows = cur.fetchall()
            cols = [d[0].lower() for d in cur.description]
            return [dict(zip(cols, r)) for r in rows]


@app.get('/api/incidents')
def api_incidents(status: str = 'OPEN'):
    sql = f"SELECT incident_id, alert_id, status, priority, assignee, sla_due_at, created_at FROM {config.TBL_INCIDENTS} WHERE status = :1 ORDER BY created_at DESC"
    with _get_conn() as con:
        with con.cursor() as cur:
            cur.execute(sql, [status])
            rows = cur.fetchall()
            cols = [d[0].lower() for d in cur.description]
            return [dict(zip(cols, r)) for r in rows]


@app.get('/api/rule_hits/top')
def api_rule_hits_top(range: str = '24h', limit: int = 5):
    # range in '24h' or '7d'
    seconds = 24*3600
    if range.endswith('d'):
        seconds = int(range[:-1]) * 24 * 3600
    sql = f"SELECT r.rule_code, r.name, r.severity, COUNT(*) AS cnt FROM {config.TBL_RULE_HITS} h JOIN {config.TBL_RULES} r ON r.rule_id=h.rule_id WHERE h.hit_at >= (SYSTIMESTAMP AT TIME ZONE 'UTC') - NUMTODSINTERVAL(:1,'SECOND') GROUP BY r.rule_code, r.name, r.severity ORDER BY cnt DESC FETCH FIRST :2 ROWS ONLY"
    with _get_conn() as con:
        with con.cursor() as cur:
            cur.execute(sql, [int(seconds), int(limit)])
            rows = cur.fetchall()
            cols = [d[0].lower() for d in cur.description]
            items = [dict(zip(cols, r)) for r in rows]
            # Attempt to augment with false-positive ratio from fg_feedback (best-effort)
            for it in items:
                it['false_positive_ratio'] = 0.0
            return items


@app.get('/api/model_scores/distribution')
def api_model_scores_distribution():
    # Return a simple histogram and channel breakdown
    with _get_conn() as con:
        with con.cursor() as cur:
            cur.execute(f"SELECT risk_score FROM {config.TBL_MODEL_SCORES} WHERE risk_score IS NOT NULL")
            rows = [r[0] for r in cur.fetchall()]
            buckets = [0]*10
            for v in rows:
                idx = min(9, int((v or 0)//10))
                buckets[idx] += 1
            cur.execute(f"SELECT channel, COUNT(*) FROM {config.TBL_TRANSACTIONS} GROUP BY channel")
            channels = {r[0]: r[1] for r in cur.fetchall()}
            return {'buckets': buckets, 'channels': channels}


@app.get('/api/notifications/verification_status')
def api_verification_status():
    sql = f"SELECT status, COUNT(*) FROM {config.TBL_NOTIFICATIONS} GROUP BY status"
    with _get_conn() as con:
        with con.cursor() as cur:
            cur.execute(sql)
            rows = cur.fetchall()
            stats = {'sent':0,'delivered':0,'responded':0,'verified':0}
            for st,c in rows:
                key = (st or '').upper()
                if key == 'SENT': stats['sent'] = c
                elif key == 'DELIVERED': stats['delivered'] = c
                elif key == 'ACKED': stats['responded'] = c
                elif key == 'VERIFIED': stats['verified'] = c
            return stats
