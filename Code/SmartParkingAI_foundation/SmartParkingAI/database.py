"""
database.py
SQL Server connection helper for Smart Parking AI.

Before running:
1. Install Microsoft ODBC Driver for SQL Server.
2. Update DB_USER / DB_PASSWORD below, or set environment variables.
"""

import os
from contextlib import contextmanager
from typing import Any, Dict, List

import pyodbc


DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "1433")
DB_NAME = os.getenv("DB_NAME", "SmartParkingIOT102")
DB_USER = os.getenv("DB_USER", "sa")
DB_PASSWORD = os.getenv("DB_PASSWORD", "12345")

# If your computer uses ODBC Driver 18, change this to:
# ODBC Driver 18 for SQL Server
DB_DRIVER = os.getenv("DB_DRIVER", "ODBC Driver 17 for SQL Server")


def build_connection_string() -> str:
    """
    Build SQL Server connection string for pyodbc.

    encrypt=no is used for local student/demo SQL Server to avoid SSL certificate errors.
    In production, configure encryption properly.
    """
    return (
        f"DRIVER={{{DB_DRIVER}}};"
        f"SERVER={DB_HOST},{DB_PORT};"
        f"DATABASE={DB_NAME};"
        f"UID={DB_USER};"
        f"PWD={DB_PASSWORD};"
        "TrustServerCertificate=yes;"
        "Encrypt=no;"
    )


@contextmanager
def get_connection():
    """
    Usage:
        with get_connection() as conn:
            cursor = conn.cursor()
            ...
    """
    conn = pyodbc.connect(build_connection_string())
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


def rows_to_dicts(cursor) -> List[Dict[str, Any]]:
    """
    Convert pyodbc cursor rows to list[dict].
    """
    columns = [column[0] for column in cursor.description]
    return [dict(zip(columns, row)) for row in cursor.fetchall()]
