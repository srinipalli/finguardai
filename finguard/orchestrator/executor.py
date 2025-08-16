\
from typing import Dict, Any, List
from ..utils import dao
from ..config import settings as config
from ..utils.kafka_bus import KafkaBus

def exec_workflow(plan: Dict[str, Any]) -> Dict[str, Any]:
    """
    Execute a small subset of tools locally.
    """
    bus = None
    out = {"steps": []}
    for step in plan.get("workflow", []):
        tool = step.get("tool")
        args = step.get("args", {})
        if tool == "recent_events":
            rows = dao.recent_events(args["account_id"], __import__("datetime").timedelta(seconds=int(args.get("window_sec",60))))
            out["steps"].append({"tool": tool, "result_count": len(rows)})
        elif tool == "device_seen":
            res = dao.is_device_seen(args["account_id"], args.get("device_id"))
            out["steps"].append({"tool": tool, "seen": bool(res)})
        elif tool == "merchant_blacklist":
            res = dao.is_merchant_blacklisted(args.get("merchant_id"))
            out["steps"].append({"tool": tool, "blacklisted": bool(res)})
        elif tool == "score_rules":
            # Scoring is already done in service; in a real MCP, you'd call an internal scoring tool.
            out["steps"].append({"tool": tool, "status": "ok"})
        elif tool == "persist_decision":
            # Persist decision structure if provided
            evt = {
                "decision_id": args.get("decision_id",""),
                "event_id": args.get("event_id",""),
                "action": args.get("action","ALLOW"),
                "risk_score": float(args.get("risk_score",0.0)),
                "reasons": args.get("reasons", []),
                "created_at": __import__("datetime").datetime.utcnow()
            }
            # Build DecisionOutcome on the fly
            from ..utils.schemas import DecisionOutcome
            dec = DecisionOutcome(**evt)
            dao.insert_decision(dec)
            out["steps"].append({"tool": tool, "persisted": True})
        elif tool == "create_alert":
            from ..utils.schemas import Alert
            a = Alert(
                alert_id=args.get("alert_id",""),
                event_id=args.get("event_id",""),
                severity=args.get("severity","MEDIUM"),
                title=args.get("title",""),
                description=args.get("description",""),
                created_at=__import__("datetime").datetime.utcnow(),
                tags=args.get("tags", [])
            )
            dao.insert_alerts([a])
            out["steps"].append({"tool": tool, "alert": True})
        elif tool == "publish_kafka":
            if bus is None:
                bus = KafkaBus()
            bus.publish(args["topic"], key=args.get("key"), value=args.get("value", {}))
            out["steps"].append({"tool": tool, "published": args["topic"]})
        else:
            out["steps"].append({"tool": tool, "error": "unknown_tool"})
    return out
