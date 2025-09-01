import os
from pathlib import Path

# Try to load a .env file automatically. Prefer python-dotenv if installed,
# otherwise fall back to a tiny parser that reads the project root .env.
try:
	from dotenv import load_dotenv
	# Let python-dotenv find and load .env from project root
	load_dotenv()
except Exception:
	# Fallback: look for .env two levels up (project root) and load key=val lines
	try:
		root = Path(__file__).resolve().parents[2]
		env_path = root / '.env'
		if env_path.exists():
			for line in env_path.read_text(encoding='utf-8').splitlines():
				line = line.strip()
				if not line or line.startswith('#'):
					continue
				if '=' not in line:
					continue
				k, v = line.split('=', 1)
				k = k.strip()
				v = v.strip().strip('"').strip("'")
				if k and os.getenv(k) is None:
					os.environ[k] = v
	except Exception:
		# best-effort loader; if it fails, environment variables must be set externally
		pass

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
print(f"Using Oracle DSN: {ORACLE_DSN}, User: {ORACLE_USER}")
# Table names (adjust if different in your fin_guard_oracle_schema.sql)
TBL_TRANSACTIONS = os.getenv("FG_TBL_TRANSACTIONS", "FG_TRANSACTIONS")
TBL_DECISIONS = os.getenv("FG_TBL_DECISIONS", "FG_DECISIONS")
TBL_ALERTS = os.getenv("FG_TBL_ALERTS", "FG_ALERTS")
TBL_DEVICES_SEEN = os.getenv("FG_TBL_DEVICES_SEEN", "FG_DEVICES_SEEN")
TBL_MERCHANT_BLACKLIST = os.getenv("FG_TBL_MERCHANT_BLACKLIST", "FG_BLACKLIST")


# Model Registry & Scores tables
TBL_MODEL_VERSIONS = os.getenv("FG_TBL_MODEL_VERSIONS", "FG_MODEL_VERSIONS")
TBL_MODEL_SCORES   = os.getenv("FG_TBL_MODEL_SCORES",   "FG_MODEL_SCORES")
