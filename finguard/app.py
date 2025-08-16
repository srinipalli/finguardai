import json
from datetime import datetime
from .utils.kafka_bus import KafkaBus
from .memory.oracle_store import OracleMemoryStore as MemoryStore
from .perception.features import perceive
from .decision.rules import decide
from .utils.schemas import TransactionEvent
from .config import settings as config

def handle_event(payload: dict, memory: MemoryStore, bus: KafkaBus):
    evt = TransactionEvent(**payload)
    # Perception (needs a view of past data)
    p = perceive(evt, memory)
    # Update memory (persist in Oracle)
    memory.add_event(evt)
    # Decision
    outcome = decide(p, memory)
    # Action → persist + Kafka
    from .action.dispatcher import dispatch
    dispatch(outcome, bus)

def run():
    memory = MemoryStore()
    bus = KafkaBus()
    print(f"[FinGuard] Consuming from {config.TRANSACTIONS_TOPIC} @ {config.BOOTSTRAP_SERVERS}")
    def _handler(msg: dict):
        handle_event(msg, memory, bus)
    bus.consume(config.TRANSACTIONS_TOPIC, group_id=config.CONSUMER_GROUP, handler=_handler)

if __name__ == "__main__":
    run()
