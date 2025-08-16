\
import time, os
from typing import Dict, Any
from ..utils import dao
from ..config import settings as config

DEFAULT_MODEL_NAME = os.getenv("FG_MODEL_NAME", "gbm_txn")

def _dummy_model_predict(features: Dict[str, Any]) -> (float, dict):
    """
    Placeholder for your actual model inference (e.g., REST to SageMaker/Sklearn server).
    Returns (risk_score, explain_dict).
    """
    # naive heuristic -> replace with real model call
    score = 20.0
    if features.get("amount", 0) >= 100000: score += 35
    if features.get("tx_count_last_window", 0) >= 3: score += 18
    if features.get("geo_velocity_km_per_min", 0) >= 50: score += 20
    if features.get("is_new_device"): score += 10
    explain = {"top_factors": ["amount","velocity","geo","device"]}
    return min(score, 99.9), explain

def score_transaction(txn_id: str, features: Dict[str, Any], model_name: str = DEFAULT_MODEL_NAME, threshold: float = 75.0) -> Dict[str, Any]:
    """
    Execute model inference and persist to FG_MODEL_SCORES.
    """
    model_id = dao.get_active_model_id(model_name)
    t0 = time.time()
    risk_score, explain = _dummy_model_predict(features)
    inference_ms = int((time.time() - t0) * 1000)
    dao.insert_model_score(
        txn_id=txn_id,
        model_id=model_id,
        risk_score=risk_score,
        threshold_used=threshold,
        inference_ms=inference_ms,
        explain_json=explain
    )
    latest = dao.get_latest_model_score(txn_id)
    return {"model_id": model_id, "risk_score": risk_score, "threshold": threshold, "inference_ms": inference_ms, "explain": explain, "record": latest}
