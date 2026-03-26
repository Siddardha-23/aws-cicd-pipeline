"""Import all models so they are registered with SQLAlchemy."""

from app.models.user import User
from app.models.service import Service
from app.models.incident import Incident

__all__ = ["User", "Service", "Incident"]
