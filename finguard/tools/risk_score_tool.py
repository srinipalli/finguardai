\
from typing import Dict, Any, List
from ..utils import dao
from ..decision.rules import score_rules
from ..memory.oracle_store import OracleMemoryStore as MemoryStore
from ..utils.schemas import PerceivedEvent, TransactionEvent

def combine_scores(perceived: PerceivedEvent, memory: MemoryStore, model_threshold: float = 75.0):
    """
    Pull latest model score and combine with rule score.
    Strategy (example): final = 0.6 * model + 0.4 * rules, then compare to threshold.
    """
    rule_score, reasons = score_rules(perceived, memory)
    latest = dao.get_latest_model_score(perceived.event.event_id)
    model_score = float(latest["RISK_SCORE"]) if latest else 0.0
    final = round(0.6 * model_score + 0.4 * rule_score, 2)
    action = "ALLOW"
    if final >= model_threshold:
        action = "CHALLENGE" if final < (model_threshold + 15) else "BLOCK"
    if latest and "EXPLAIN_JSON" in latest:
        reasons.append(f"Model factors: {latest['EXPLAIN_JSON'].get('top_factors')}")
    reasons.append(f"Model score={model_score}, Rule score={rule_score}, Combined={final}")
    return {"final_score": final, "action": action, "reasons": reasons, "model_score": model_score, "rule_score": rule_score}
