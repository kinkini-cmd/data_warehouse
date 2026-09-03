"""Database configuration and connection utilities for the LMS Data Warehouse ETL."""

import os
from pathlib import Path

from dotenv import load_dotenv
from sqlalchemy import create_engine

PROJECT_ROOT = Path(__file__).resolve().parent.parent
load_dotenv(PROJECT_ROOT / ".env")

DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5434")
DB_NAME = os.getenv("DB_NAME", "lms_warehouse")
DB_USER = os.getenv("DB_USER", "lms_user")
DB_PASSWORD = os.getenv("DB_PASSWORD", "")

DATABASE_URL = (
    f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
)

DATA_DIR = PROJECT_ROOT / "data"
LOG_DIR = PROJECT_ROOT / "logs"


def get_engine(echo: bool = False):
    """Return a SQLAlchemy engine connected to the warehouse database."""
    return create_engine(DATABASE_URL, echo=echo)


def get_raw_connection(engine):
    """Return a raw DBAPI connection (for psycopg2 COPY operations)."""
    return engine.raw_connection()
