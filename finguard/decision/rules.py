from typing import List, Tuple
from uuid import uuid4
from datetime import datetime
from ..utils.schemas import PerceivedEvent, DecisionOutcome
from ..memory.oracle_store import OracleMemoryStore as MemoryStore
from ..config import settings as config

def score_rules(p: PerceivedEvent, memory: MemoryStore) -> Tuple[float, List[str]]:
    f = p.features
    evt = p.event
    score = 0.0
    reasons: List[str] = []

    # Baseline risks
    score += f.get("channel_base_risk", 0)
    if f.get("channel_base_risk", 0) > 0:
        reasons.append(f"Channel risk +{f['channel_base_risk']} ({evt.channel})")

    if f.get("mcc_risk", 0) > 0:
        score += f["mcc_risk"]
        reasons.append(f"MCC risk +{f['mcc_risk']} ({evt.mcc})")

    # Amount
    if f["amount"] >= 100000:  # 1 lakh
        score += 30; reasons.append("High amount (>=100k) +30")
    elif f["amount"] >= 50000:
        score += 18; reasons.append("Mid-high amount (>=50k) +18")
    elif f["amount"] >= 20000:
        score += 10; reasons.append("Moderate amount (>=20k) +10")

    # Velocity
    cnt = f.get("tx_count_last_window", 0)
    if cnt >= 5:
        score += 25; reasons.append(f"High burst velocity {cnt}/min +25")
    elif cnt >= 3:
        score += 12; reasons.append(f"Elevated velocity {cnt}/min +12")

    # Geo velocity
    gv = f.get("geo_velocity_km_per_min", 0.0)
    if gv >= 50:
        score += 30; reasons.append(f"Impossible travel {gv:.1f} km/min +30")
    elif gv >= 10:
        score += 12; reasons.append(f"Suspicious travel {gv:.1f} km/min +12")

    # Night
    if f.get("is_night", 0) == 1:
        score += 8; reasons.append("Nighttime +8")

    # New device
    if f.get("is_new_device", False):
        score += 15; reasons.append("New/unknown device +15")

    # Blacklist
    if memory.is_blacklisted(evt.merchant_id):
        score += 40; reasons.append(f"Blacklisted merchant +40 ({evt.merchant_id})")

    return score, reasons

def decide(p: PerceivedEvent, memory: MemoryStore) -> DecisionOutcome:
    score, reasons = score_rules(p, memory)
    # Optional LLM delta
    delta, rationale = llm_adjustment(p)
    if delta:
        score += delta
        reasons.append(f"LLM adjustment +{delta:.1f}: {rationale}")
    # Get LLM tool-workflow plan (S10-style)
    plan = plan_workflow(p)
    if plan and plan.get('workflow'):
        reasons.append(f"LLM plan expected_action={plan.get('expected_action')} :: steps={len(plan.get('workflow',[]))}")

    action = "ALLOW"
    if score >= config.BLOCK_THRESHOLD:
        action = "BLOCK"
    elif score >= config.CHALLENGE_THRESHOLD:
        action = "CHALLENGE"
    return DecisionOutcome(
        decision_id=str(uuid4()),
        event_id=p.event.event_id,
        action=action,
        risk_score=round(score, 2),
        reasons=reasons,
        created_at=datetime.utcnow(),
    )
