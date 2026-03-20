"""Service business logic."""

from typing import Optional, List
from datetime import datetime, timezone

from app.extensions import db
from app.models.service import Service


def list_services() -> List[Service]:
    """Return all services ordered by name."""
    return db.session.query(Service).order_by(Service.name).all()


def get_service(service_id: int) -> Optional[Service]:
    """Fetch a single service by primary key."""
    return db.session.get(Service, service_id)


def update_service(service: Service, data: dict) -> Service:
    """Update mutable fields on a service."""
    for field in ("name", "status", "uptime_percentage", "endpoint_url", "description"):
        if field in data:
            setattr(service, field, data[field])

    service.updated_at = datetime.now(timezone.utc)
    db.session.commit()
    return service
