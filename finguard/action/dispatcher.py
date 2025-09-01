from uuid import uuid4
from datetime import datetime
from typing import List
from ..utils.schemas import DecisionOutcome, Alert
from ..utils.kafka_bus import KafkaBus
from ..config import settings as config
from ..utils import dao

def to_alerts(decision: DecisionOutcome) -> List[Alert]:
    alerts = []
    if decision.action in ("CHALLENGE", "BLOCK"):
        sev = "HIGH" if decision.action == "BLOCK" else "MEDIUM"
        alerts.append(Alert(
            event_id=decision.event_id,
            severity=sev,
            title=f"Decision: {decision.action} (risk={decision.risk_score})",
            description="; ".join(decision.reasons),
            risk_score=decision.risk_score
         ))
    return alerts

def dispatch(decision: DecisionOutcome, bus: KafkaBus):
    # Persist decision
    dao.insert_decision(decision)
    # Publish decisions
    # bus.publish(config.DECISIONS_TOPIC, value=decision.dict(), key=decision.event_id)
    # Alerts: persist and publish
    alerts = to_alerts(decision)
    if alerts:
        dao.insert_alerts(alerts)
    print(f"dispatch: decision {decision.event_id} action={decision.action} risk={decision.risk_score} alerts={len(alerts)}")    
"""        for alert in alerts:
            bus.publish(config.ALERTS_TOPIC, value=alert.dict(), key=alert.alert_id)
"""