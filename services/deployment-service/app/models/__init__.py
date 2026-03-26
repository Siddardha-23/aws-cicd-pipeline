"""Import all models so they are registered with SQLAlchemy."""

from app.models.deployment import Deployment

__all__ = ["Deployment"]
