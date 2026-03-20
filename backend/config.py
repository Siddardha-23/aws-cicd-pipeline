"""Application configuration loaded from environment variables."""

import os

from dotenv import load_dotenv

load_dotenv()


class Config:
    """Base configuration class."""

    FLASK_SECRET_KEY = os.getenv("FLASK_SECRET_KEY", "change-me-in-production")
    SECRET_KEY = FLASK_SECRET_KEY

    SQLALCHEMY_TRACK_MODIFICATIONS = False

    # Build database URI from individual env vars or fall back to DATABASE_URL.
    _db_url = os.getenv("DATABASE_URL")
    if _db_url:
        SQLALCHEMY_DATABASE_URI = _db_url
    else:
        _db_host = os.getenv("DB_HOST", "localhost")
        _db_name = os.getenv("DB_NAME", "opsboard")
        _db_user = os.getenv("DB_USERNAME", "postgres")
        _db_pass = os.getenv("DB_PASSWORD", "postgres")
        _db_port = os.getenv("DB_PORT", "5432")
        SQLALCHEMY_DATABASE_URI = (
            f"postgresql://{_db_user}:{_db_pass}@{_db_host}:{_db_port}/{_db_name}"
        )
