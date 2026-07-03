"""SQL Server connection helper for the Smart Parking YOLO server.

The YOLO server works without SQL Server by default:
    DB_ENABLED=0

Enable SQL logging only after the database has been created from:
    sql/smart_parking_refine.sql
"""

import os
from typing import Any


def env_bool(name: str, default: str = "0") -> bool:
    return os.getenv(name, default).strip().lower() in {"1", "true", "yes", "y", "on"}


DB_ENABLED = env_bool("DB_ENABLED", "0")

DB_CONNECTION_STRING = os.getenv("DB_CONNECTION_STRING", "").strip()
DB_DRIVER = os.getenv("DB_DRIVER", "ODBC Driver 17 for SQL Server")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "1433")
DB_NAME = os.getenv("DB_NAME", "SmartParkingIOT102")
DB_USER = os.getenv("DB_USER", "sa")
DB_PASSWORD = os.getenv("DB_PASSWORD", "12345")
DB_ENCRYPT = os.getenv("DB_ENCRYPT", "no")
DB_TRUST_CERT = os.getenv("DB_TRUST_SERVER_CERTIFICATE", "yes")


def build_connection_string() -> str:
    if DB_CONNECTION_STRING:
        return DB_CONNECTION_STRING

    server = DB_HOST
    if DB_PORT:
        server = f"{DB_HOST},{DB_PORT}"

    return (
        f"DRIVER={{{DB_DRIVER}}};"
        f"SERVER={server};"
        f"DATABASE={DB_NAME};"
        f"UID={DB_USER};"
        f"PWD={DB_PASSWORD};"
        f"Encrypt={DB_ENCRYPT};"
        f"TrustServerCertificate={DB_TRUST_CERT};"
    )


def get_connection() -> Any:
    if not DB_ENABLED:
        raise RuntimeError("Database logging is disabled. Set DB_ENABLED=1 to enable SQL Server logging.")

    try:
        import pyodbc  # imported lazily so no-SQL mode does not require pyodbc
    except ImportError as exc:
        raise RuntimeError("pyodbc is not installed. Run: pip install -r requirements-sql.txt") from exc

    return pyodbc.connect(build_connection_string(), autocommit=False)
