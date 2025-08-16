import json
from typing import Callable, Optional
from kafka import KafkaProducer, KafkaConsumer
from kafka.errors import NoBrokersAvailable
from ..config import settings as config

class KafkaBus:
    def __init__(self, bootstrap_servers: Optional[str] = None):
        self.bootstrap_servers = bootstrap_servers or config.BOOTSTRAP_SERVERS
        try:
            self.producer = KafkaProducer(
                bootstrap_servers=self.bootstrap_servers,
                value_serializer=lambda v: json.dumps(v).encode("utf-8"),
                key_serializer=lambda k: k.encode("utf-8") if isinstance(k, str) else k,
                acks="all",
                linger_ms=10,
                retries=5,
            )
        except NoBrokersAvailable as e:
            raise RuntimeError(f"Cannot connect to Kafka at {self.bootstrap_servers}. Ensure broker is up.") from e

    def publish(self, topic: str, value: dict, key: Optional[str] = None):
        self.producer.send(topic, value=value, key=key)
        self.producer.flush()

    def consume(self, topic: str, group_id: str, handler: Callable[[dict], None], auto_offset_reset: str = "latest"):
        consumer = KafkaConsumer(
            topic,
            bootstrap_servers=self.bootstrap_servers,
            group_id=group_id,
            value_deserializer=lambda v: json.loads(v.decode("utf-8")),
            auto_offset_reset=auto_offset_reset,
            enable_auto_commit=True,
        )
        for msg in consumer:
            try:
                handler(msg.value)
            except Exception as e:
                # In production, log and route to a DLQ
                print(f"[KafkaBus] Handler error: {e}")
