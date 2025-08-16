from datetime import timedelta
from typing import List, Optional, Dict, Any
from dataclasses import dataclass
from datetime import datetime
from ..utils.schemas import TransactionEvent
from ..utils import dao

@dataclass
class EventRow:
    timestamp: datetime
    amount: float
    lat: Optional[float]
    lon: Optional[float]
    device_id: Optional[str]
    merchant_id: Optional[str]
    channel: str

class OracleMemoryStore:
    def add_event(self, evt: TransactionEvent):
        dao.insert_transaction(evt)
        dao.upsert_device_seen(evt.account_id, evt.device_id)

    def recent_events(self, account_id: str, window: timedelta) -> List[EventRow]:
        rows: List[Dict[str, Any]] = dao.recent_events(account_id, window)
        out: List[EventRow] = []
        for r in rows:
            out.append(EventRow(
                timestamp=r.get("TS_UTC"),
                amount=float(r.get("AMOUNT")) if r.get("AMOUNT") is not None else 0.0,
                lat=r.get("LATITUDE"),
                lon=r.get("LONGITUDE"),
                device_id=r.get("DEVICE_ID"),
                merchant_id=r.get("MERCHANT_ID"),
                channel=r.get("CHANNEL")
            ))
        return out

    def has_seen_device_recently(self, account_id: str, device_id: Optional[str]) -> bool:
        return dao.is_device_seen(account_id, device_id)

    def is_blacklisted(self, merchant_id: Optional[str]) -> bool:
        return dao.is_merchant_blacklisted(merchant_id)
