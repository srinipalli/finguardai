import time
import uuid
from datetime import datetime, timedelta
from random import choice, uniform, randint
from ..utils.kafka_bus import KafkaBus
from ..config import settings as config

CHANNELS = ["CARD", "UPI", "IMPS", "NEFT", "NETBANKING", "ATM"]
MCCS = ["4829", "7995", "5699", None]

def send_demo(n: int = 5, account_id: str = "ACC001", user_id: str = "USR001"):
    bus = KafkaBus()
    now = datetime.utcnow()
    lat, lon = 12.9716, 77.5946  # Bangalore
    for i in range(n):
        payload = {
            "event_id": str(uuid.uuid4()),
            "account_id": account_id,
            "user_id": user_id,
            "amount": round(uniform(100.0, 125000.0), 2),
            "currency": "INR",
            "channel": choice(CHANNELS),
            "mcc": choice(MCCS),
            "merchant_id": f"M{randint(100,999)}",
            "timestamp": (now + timedelta(seconds=i*10)).isoformat(),
            "lat": lat + uniform(-0.05, 0.05),
            "lon": lon + uniform(-0.05, 0.05),
            "device_id": f"D{randint(1,3)}",
            "ip": f"10.0.0.{randint(2,254)}",
            "country": "IN",
            "state": "KA",
            "city": "Bengaluru",
            "extra": {}
        }
        bus.publish(config.TRANSACTIONS_TOPIC, value=payload, key=payload["account_id"])
        print(f"[Demo] Sent {payload['event_id']} amount={payload['amount']} channel={payload['channel']}")
        time.sleep(0.2)

if __name__ == "__main__":
    send_demo(10)
