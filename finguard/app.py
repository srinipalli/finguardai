import json
from datetime import datetime
from .utils.kafka_bus import KafkaBus
from .memory.oracle_store import OracleMemoryStore as MemoryStore
from .perception.features import perceive
from .decision.rules import decide
from .utils.schemas import TransactionEvent
from .config import settings as config

def handle_event(payload: dict, memory: MemoryStore, bus: KafkaBus):
    print("handle_event: payload", payload.get("event_id") or "no-id");
    evt = TransactionEvent(**payload)
    print("handle_event: evt", evt.event_id);
    # Perception (needs a view of past data)
    p = perceive(evt, memory)
    print("handle_event: evt after perceive :", evt.event_id);

    # Update memory (persist in Oracle)
    print ("handle_event: adding to memory :", evt.event_id);
    memory.add_event(evt)
    print ("handle_event: added to memory :", evt.event_id);
    # Decision
    print ("handle_event: deciding :", evt.event_id);
    outcome = decide(p, memory)
    print ("handle_event: decided :", evt.event_id, " outcome:", outcome.action if outcome else "no outcome");
    # Action → persist + Kafka
    from .action.dispatcher import dispatch
    print ("handle_event: dispatching outcome :", evt.event_id);
    dispatch(outcome, bus)
    print ("handle_event: dispatched outcome :", evt.event_id);

def run():
    memory = MemoryStore()
    bus = KafkaBus()
    print(f"[FinGuard] Consuming from {config.TRANSACTIONS_TOPIC} @ {config.BOOTSTRAP_SERVERS}")
    def _handler(msg: dict):
        handle_event(msg, memory, bus)
    bus.consume(config.TRANSACTIONS_TOPIC, group_id=config.CONSUMER_GROUP, handler=_handler)

if __name__ == "__main__":
    run()
