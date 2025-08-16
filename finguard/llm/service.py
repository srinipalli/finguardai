import os
from typing import Dict, Any, Tuple, Optional
from ..utils.schemas import PerceivedEvent
from ..config import settings as config

# Provider: "openai" or "mock"
PROVIDER = os.getenv("FINGUARD_LLM_PROVIDER", "mock").lower()
MODEL = os.getenv("FINGUARD_LLM_MODEL", "gpt-4o-mini")
ENABLE = os.getenv("FINGUARD_LLM_ENABLED", "false").lower() in ("1","true","yes")

def _openai_score(prompt: str) -> Tuple[float, str]:
    try:
        from openai import OpenAI
        client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
        resp = client.chat.completions.create(
            model=MODEL,
            messages=[
                {"role":"system","content":"You are a risk analyst. Return a JSON with fields: delta (0-40) and rationale (short)."},
                {"role":"user","content":prompt}
            ],
            temperature=0.2,
        )
        text = resp.choices[0].message.content
        import json as _json, re
        # extract json
        m = re.search(r'\{[\s\S]*\}', text)
        if m:
            data = _json.loads(m.group(0))
            return float(data.get("delta", 0.0)), str(data.get("rationale",""))
        return 0.0, "No JSON returned"
    except Exception as e:
        return 0.0, f"LLM error: {e}"

def llm_adjustment(p: PerceivedEvent) -> Tuple[float, str]:
    if not ENABLE:
        return 0.0, "LLM disabled"
    prompt = f"""
Given these transaction features, provide a risk adjustment delta between 0 and 40 and a brief rationale.
Features: {p.features}
Channel: {p.event.channel}, MCC: {p.event.mcc}, Amount: {p.event.amount}, Time: {p.event.timestamp.isoformat()}
Respond as JSON: {{"delta": <0-40>, "rationale": "<short>"}}
"""
    if PROVIDER == "openai":
        return _openai_score(prompt)
    # Mock provider for offline/dev
    base = 0.0
    if p.features.get("is_new_device"): base += 5
    if p.features.get("geo_velocity_km_per_min", 0) >= 50: base += 10
    if p.features.get("amount", 0) >= 100000: base += 8
    delta = min(40.0, base)
    return delta, "Mock heuristic adjustment"
