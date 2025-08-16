from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field
from datetime import datetime

class TransactionEvent(BaseModel):
    event_id: str
    account_id: str
    user_id: str
    amount: float
    currency: str = Field(default="INR")
    channel: str  # CARD/UPI/IMPS/NEFT/NETBANKING/ATM, etc.
    mcc: Optional[str] = None
    merchant_id: Optional[str] = None
    timestamp: datetime
    lat: Optional[float] = None
    lon: Optional[float] = None
    device_id: Optional[str] = None
    ip: Optional[str] = None
    country: Optional[str] = None
    state: Optional[str] = None
    city: Optional[str] = None
    extra: Dict[str, Any] = Field(default_factory=dict)

class PerceivedEvent(BaseModel):
    event: TransactionEvent
    features: Dict[str, Any]

class DecisionOutcome(BaseModel):
    decision_id: str
    event_id: str
    action: str  # ALLOW | CHALLENGE | BLOCK
    risk_score: float
    reasons: List[str] = Field(default_factory=list)
    created_at: datetime

class Alert(BaseModel):
    alert_id: str
    event_id: str
    severity: str  # LOW | MEDIUM | HIGH | CRITICAL
    title: str
    description: str
    created_at: datetime
    tags: List[str] = Field(default_factory=list)
