# FinGuard – Layered Fraud Decisioning (Perception → Memory → Decision → Action) with Kafka

This starter kit implements the FinGuard architecture you referenced:
- **Perception:** normalize and derive features (velocity, geo-velocity, device novelty, risk hints).
- **Memory:** lightweight in‑memory store for recent transactions, devices, and blacklists.
- **Decision:** rule‑based risk scoring with thresholds → `ALLOW` / `CHALLENGE` / `BLOCK`.
- **Action:** publish decisions and alerts to Kafka topics.

## Quick Start

1. **Install deps** (in a venv):
   ```bash
   pip install -r requirements.txt
   ```

2. **Run the consumer** (decision engine):
   ```bash
   python -m finguard.runner
   ```

3. **Send sample transactions** (demo producer):
   ```bash
   python -m finguard.producer_demo
   ```

### Environment Variables

- `KAFKA_BOOTSTRAP_SERVERS` (default `localhost:9092`)
- `KAFKA_TRANSACTIONS_TOPIC` (default `finguard.transactions`)
- `KAFKA_DECISIONS_TOPIC` (default `finguard.decisions`)
- `KAFKA_ALERTS_TOPIC` (default `finguard.alerts`)
- `KAFKA_CONSUMER_GROUP` (default `finguard-decisioner`)
- `FINGUARD_BLOCK_THRESHOLD` (default `80`)
- `FINGUARD_CHALLENGE_THRESHOLD` (default `55`)

### Where Kafka fits

- **Input:** Transactions are produced to `finguard.transactions` (e.g., by your core banking/ingest layer).
- **Decision Engine (this service):** Consumes from `finguard.transactions`, computes decisions.
- **Outputs:**
  - `finguard.decisions`: downstream services (payments gateway, core) act on `ALLOW/CHALLENGE/BLOCK`.
  - `finguard.alerts`: case management/SOC receives human‑readable alerts.

### Customize

- Tune risk weights in `perception.py` and `decision.py`.
- Replace `MemoryStore` with Redis/Postgres.
- Add ML scoring in `decision.py` (e.g., model.predict(features)).



## Oracle integration

This build uses **oracledb** connection pooling and persists:
- inbound transactions → `FG_TRANSACTIONS`
- device sightings → `FG_DEVICES_SEEN`
- decisions → `FG_DECISIONS`
- alerts → `FG_ALERTS`
- merchant blacklist lookup → `FG_MERCHANT_BLACKLIST`

> Align the table names/columns with your `fin_guard_oracle_schema.sql`. You can override table names via env vars:
`FG_TBL_*` in `config.py`.

### Env vars
```
ORACLE_DSN=localhost/orclpdb1
ORACLE_USER=FINGUARD
ORACLE_PASSWORD=FINGUARD
FG_TBL_TRANSACTIONS=FG_TRANSACTIONS
FG_TBL_DECISIONS=FG_DECISIONS
FG_TBL_ALERTS=FG_ALERTS
FG_TBL_DEVICES_SEEN=FG_DEVICES_SEEN
FG_TBL_MERCHANT_BLACKLIST=FG_MERCHANT_BLACKLIST
```

### Suggested indexes
- `FG_TRANSACTIONS(ACCOUNT_ID, TS_UTC)`
- `FG_DEVICES_SEEN(ACCOUNT_ID, DEVICE_ID)` unique
- `FG_DECISIONS(EVENT_ID)`
- `FG_ALERTS(EVENT_ID, CREATED_AT_UTC)`
- `FG_MERCHANT_BLACKLIST(MERCHANT_ID)`


### Modular package layout
See `finguard/` subpackages for action, decision, memory, perception, utils, and config.


## LLM integration
- Optional risk adjustment via LLM lives in `finguard/llm/service.py`.
- Enable with `FINGUARD_LLM_ENABLED=true` and set the provider API key.
- Supported providers: `mock`, `openai`, `gemini`.
- For OpenAI set `OPENAI_API_KEY`. For Google Gemini set `GOOGLE_API_KEY` and `FINGUARD_LLM_PROVIDER=gemini`.

## MCP-style Tool Server (FastAPI)
Expose FinGuard operations as simple tools:
- `POST /tools/ingest` – queue a transaction into Kafka.
- `GET /tools/decision/{event_id}` – fetch decision from Oracle.
- `POST /tools/blacklist` – upsert merchant blacklist record.
- `GET /stream/heartbeat` – SSE heartbeat channel (example).

Run:
```bash
uvicorn finguard.mcp_server.server:app --host 0.0.0.0 --port 8080
```

These endpoints can be bound into your MCP orchestrator as tools.


## S10-style LLM Tool Workflow
- The LLM now **plans a tool workflow** (not just a score). See `finguard/llm/planner.py`.
- The decision flow records the plan summary for traceability.
- MCP endpoints added:
  - `POST /plan` — returns the LLM JSON plan for a given event.
  - `POST /execute` — executes a given plan server-side (optional).

Example:
```bash
curl -X POST http://localhost:8080/plan -H "Content-Type: application/json" -d '{ "event_id":"evt-1", "account_id":"A1", "user_id":"U1", "amount":45000, "currency":"INR", "channel":"UPI", "timestamp":"2025-08-16T10:00:00Z" }'
```
Returns:
```json
{
  "workflow": [{"tool":"recent_events","args":{"account_id":"A1","window_sec":60}}, ...],
  "expected_action": "CHALLENGE",
  "rationale": "Velocity + amount"
}
```


## MCP Tools — ML & Risk Score
- `POST /tools/ml_score` → runs the **MLModelTool** to store a model score in `FG_MODEL_SCORES`.
  - body: `{"event": {...}, "features": {...}, "model_name": "gbm_txn", "threshold": 75.0}`
- `POST /tools/risk_score` → runs **RiskScoreTool** to combine latest model score with rules and return `final_score`, `action`, `reasons`.

### Env table names (override if your DDL differs)
```
FG_TBL_MODEL_VERSIONS=FG_MODEL_VERSIONS
FG_TBL_MODEL_SCORES=FG_MODEL_SCORES
```
