from fastapi import FastAPI, HTTPException
from fastapi.responses import StreamingResponse, JSONResponse
from typing import Dict, Any
import json
import asyncio
from ..utils.kafka_bus import KafkaBus
from ..utils import dao
from ..config import settings as config

app = FastAPI(title="FinGuard MCP Tool Server", version="1.0.0")

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
            yield f"data: {{"tick": {i}}}\n\n"
            i += 1
            await asyncio.sleep(1.0)
    return StreamingResponse(eventgen(), media_type="text/event-stream")

from ..utils.schemas import TransactionEvent
from ..perception.features import perceive
from ..memory.oracle_store import OracleMemoryStore as MemoryStore
from ..llm.planner import plan_workflow as _plan_workflow
from ..orchestrator.executor import exec_workflow as _exec_workflow

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
