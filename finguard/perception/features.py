from math import radians, cos, sin, asin, sqrt
from datetime import timedelta
from typing import Dict, Any
from ..utils.schemas import TransactionEvent, PerceivedEvent
from ..memory.oracle_store import OracleMemoryStore as MemoryStore
from ..config import settings as config

def _haversine(lat1, lon1, lat2, lon2):
    # Distance in km
    r = 6371
    dlat = radians(lat2 - lat1)
    dlon = radians(lon2 - lon1)
    a = sin(dlat/2)**2 + cos(radians(lat1)) * cos(radians(lat2)) * sin(dlon/2)**2
    return 2 * r * asin(sqrt(a))

CHANNEL_BASE_RISK = {
    "CARD": 10, "UPI": 8, "IMPS": 12, "NEFT": 6, "NETBANKING": 7, "ATM": 9
}

MCC_RISK = {
    # Sample MCC risk hints
    "4829": 15,  # money transfer
    "7995": 20,  # betting
    "5699": 5,   # apparel
}

def perceive(evt: TransactionEvent, memory: MemoryStore) -> PerceivedEvent:
    feats: Dict[str, Any] = {}

    # Velocity features
    recent = memory.recent_events(evt.account_id, timedelta(seconds=config.VELOCITY_WINDOW_SEC))
    feats["tx_count_last_window"] = len(recent)
    feats["tx_sum_last_window"] = sum(r.amount for r in recent) if recent else 0.0
    print("perceive:", len(recent), feats["tx_sum_last_window"])
    # Geo-velocity (km/min) comparing with last event if coordinates exist
    if recent and evt.lat is not None and evt.lon is not None:
        last = recent[-1]
        if last.lat is not None and last.lon is not None:
            dist_km = _haversine(last.lat, last.lon, evt.lat, evt.lon)
            minutes = max( (evt.timestamp - last.timestamp).total_seconds() / 60.0, 0.001)
            feats["geo_velocity_km_per_min"] = dist_km / minutes
        else:
            feats["geo_velocity_km_per_min"] = 0.0
    else:
        feats["geo_velocity_km_per_min"] = 0.0
    print("perceive:", len(recent), feats["geo_velocity_km_per_min"])

    # New device
    print("has_seen_device_recently:", evt.account_id, evt.device_id)
    feats["is_new_device"] = not memory.has_seen_device_recently(evt.account_id, evt.device_id)
    print("is_new_device:", feats["is_new_device"])
    # Risk hints
    feats["channel_base_risk"] = CHANNEL_BASE_RISK.get(evt.channel.upper(), 5)
    feats["mcc_risk"] = MCC_RISK.get((evt.mcc or "").strip(), 0)

    # Time-of-day buckets
    hour = evt.timestamp.hour
    feats["is_night"] = 1 if (hour >= 22 or hour <= 5) else 0

    # Amount normalization (assume currency already normalized)
    feats["amount"] = evt.amount
    print("amount:", len(recent), feats["geo_velocity_km_per_min"])

    return PerceivedEvent(event=evt, features=feats)
