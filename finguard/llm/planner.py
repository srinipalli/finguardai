\
import os, json, re
from typing import Dict, Any, List, Tuple
from ..utils.schemas import PerceivedEvent

TOOLS_SPEC = [
    {"name":"recent_events", "desc":"Fetch account's recent events from Oracle for velocity features", "args":{"account_id":"str","window_sec":"int"}},
    {"name":"device_seen", "desc":"Check if device was seen for the account", "args":{"account_id":"str","device_id":"str"}},
    {"name":"merchant_blacklist", "desc":"Check if merchant is blacklisted", "args":{"merchant_id":"str"}},
    {"name":"score_rules", "desc":"Apply deterministic rule score", "args":{"features":"dict"}},
    {"name":"persist_decision", "desc":"Persist decision to Oracle", "args":{"event_id":"str","action":"str","risk_score":"float","reasons":"list"}},
    {"name":"publish_kafka", "desc":"Publish to Kafka topic", "args":{"topic":"str","key":"str","value":"dict"}},
    {"name":"create_alert", "desc":"Create alert for CHALLENGE/BLOCK", "args":{"severity":"str","title":"str","description":"str","event_id":"str","tags":"list"}}
]

SYSTEM_INSTRUCTIONS = """You are a FinGuard Orchestrator. Produce a minimal, correct tool WORKFLOW for fraud decisioning.
- Available tools are strictly the following with exact names and arguments:
{tools}
- You MUST respond with **machine-only JSON** (no prose) in this schema:
{{
  "workflow": [{{"tool":"<name>","args":{{...}}}}...],
  "expected_action": "ALLOW|CHALLENGE|BLOCK",
  "rationale": "<short reason>"
}}
Rules:
- Always include 'recent_events', 'device_seen', 'merchant_blacklist', then 'score_rules'.
- If expected_action is CHALLENGE or BLOCK, include 'create_alert' and 'publish_kafka' for alerts.
- Always include 'persist_decision' and 'publish_kafka' for decisions.
- Do not invent tools or arguments.
- Keep arguments concise and serializable.
"""

def _openai_call(prompt: str) -> str:
    from openai import OpenAI
    client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
    model = os.getenv("FINGUARD_LLM_MODEL", "gpt-4o-mini")
    resp = client.chat.completions.create(
        model=model,
        messages=[
            {"role":"system","content":SYSTEM_INSTRUCTIONS.format(
                tools=json.dumps(TOOLS_SPEC, indent=2)
            )},
            {"role":"user","content":prompt},
        ],
        temperature=0.1,
    )
    return resp.choices[0].message.content

def plan_workflow(p: PerceivedEvent) -> Dict[str, Any]:
    """
    Returns a dict with keys: workflow, expected_action, rationale
    """
    enable = os.getenv("FINGUARD_LLM_ENABLED","false").lower() in ("1","true","yes")
    provider = os.getenv("FINGUARD_LLM_PROVIDER","mock").lower()
    if not enable:
        # deterministic fallback mini-plan
        expected = "ALLOW"
        if p.features.get("amount",0) >= 100000 or p.features.get("geo_velocity_km_per_min",0)>=50:
            expected = "CHALLENGE"
        plan = [
            {"tool":"recent_events","args":{"account_id":p.event.account_id,"window_sec":60}},
            {"tool":"device_seen","args":{"account_id":p.event.account_id,"device_id":p.event.device_id or ""}},
            {"tool":"merchant_blacklist","args":{"merchant_id":p.event.merchant_id or ""}},
            {"tool":"score_rules","args":{"features":p.features}},
            {"tool":"persist_decision","args":{"event_id":p.event.event_id,"action":expected,"risk_score":0.0,"reasons":["mock-plan"]}},
            {"tool":"publish_kafka","args":{"topic":"finguard.decisions","key":p.event.event_id,"value":{"event_id":p.event.event_id,"action":expected}}},
        ]
        if expected in ("CHALLENGE","BLOCK"):
            plan.append({"tool":"create_alert","args":{"severity":"MEDIUM" if expected=="CHALLENGE" else "HIGH","title":f"Decision: {expected}","description":"mock-plan","event_id":p.event.event_id,"tags":["fraud","decision"]}})
            plan.append({"tool":"publish_kafka","args":{"topic":"finguard.alerts","key":p.event.event_id,"value":{"event_id":p.event.event_id,"severity":"MEDIUM" if expected=="CHALLENGE" else "HIGH"}}})
        return {"workflow": plan, "expected_action": expected, "rationale": "LLM disabled; deterministic plan"}
    if provider == "openai":
        user_prompt = f"""Produce a tool workflow for this transaction.\nFeatures: {json.dumps(p.features, default=str)}\nEvent: {p.event.dict()}"""
        content = _openai_call(user_prompt)
        # Extract JSON
        m = re.search(r'\{[\s\S]*\}\s*$', content)
        if not m:
            return {"workflow": [], "expected_action": "ALLOW", "rationale": "No JSON from LLM"}
        try:
            return json.loads(m.group(0))
        except Exception as e:
            return {"workflow": [], "expected_action": "ALLOW", "rationale": f"Parse error: {e}"}
    # mock provider same as disabled
    return {"workflow": [], "expected_action": "ALLOW", "rationale": "Unknown provider; returning empty plan"}
