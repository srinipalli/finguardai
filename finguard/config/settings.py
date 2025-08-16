import os

# Kafka
BOOTSTRAP_SERVERS = os.getenv("KAFKA_BOOTSTRAP_SERVERS", "localhost:9092")
TRANSACTIONS_TOPIC = os.getenv("KAFKA_TRANSACTIONS_TOPIC", "finguard.transactions")
DECISIONS_TOPIC = os.getenv("KAFKA_DECISIONS_TOPIC", "finguard.decisions")
ALERTS_TOPIC = os.getenv("KAFKA_ALERTS_TOPIC", "finguard.alerts")
CONSUMER_GROUP = os.getenv("KAFKA_CONSUMER_GROUP", "finguard-decisioner")

# Risk thresholds
BLOCK_THRESHOLD = float(os.getenv("FINGUARD_BLOCK_THRESHOLD", "80"))
CHALLENGE_THRESHOLD = float(os.getenv("FINGUARD_CHALLENGE_THRESHOLD", "55"))

# Feature windows (seconds)
VELOCITY_WINDOW_SEC = int(os.getenv("FINGUARD_VELOCITY_WINDOW_SEC", "60"))
DEVICE_WINDOW_DAYS = int(os.getenv("FINGUARD_DEVICE_WINDOW_DAYS", "90"))


# Oracle DB
ORACLE_DSN = os.getenv("ORACLE_DSN", "localhost/orclpdb1")
ORACLE_USER = os.getenv("ORACLE_USER", "FINGUARD")
ORACLE_PASSWORD = os.getenv("ORACLE_PASSWORD", "FINGUARD")

# Table names (adjust if different in your fin_guard_oracle_schema.sql)
TBL_TRANSACTIONS = os.getenv("FG_TBL_TRANSACTIONS", "FG_TRANSACTIONS")
TBL_DECISIONS = os.getenv("FG_TBL_DECISIONS", "FG_DECISIONS")
TBL_ALERTS = os.getenv("FG_TBL_ALERTS", "FG_ALERTS")
TBL_DEVICES_SEEN = os.getenv("FG_TBL_DEVICES_SEEN", "FG_DEVICES_SEEN")
TBL_MERCHANT_BLACKLIST = os.getenv("FG_TBL_MERCHANT_BLACKLIST", "FG_MERCHANT_BLACKLIST")


# Model Registry & Scores tables
TBL_MODEL_VERSIONS = os.getenv("FG_TBL_MODEL_VERSIONS", "FG_MODEL_VERSIONS")
TBL_MODEL_SCORES   = os.getenv("FG_TBL_MODEL_SCORES",   "FG_MODEL_SCORES")
