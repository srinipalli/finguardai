import oracledb
from typing import Optional
from ..config import settings as config

_pool: Optional[oracledb.ConnectionPool] = None

def get_pool() -> oracledb.ConnectionPool:
    global _pool
    if _pool is None:
        _pool = oracledb.ConnectionPool(
            user=config.ORACLE_USER,
            password=config.ORACLE_PASSWORD,
            dsn=config.ORACLE_DSN,
            min=1, max=8, increment=1,
            homogeneous=True,
            timeout=60
        )
    return _pool

def get_connection():
    return get_pool().acquire()
