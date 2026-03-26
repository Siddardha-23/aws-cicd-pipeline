"""Incident business logic."""

from typing import Optional, List
from datetime import datetime, timezone

from app.extensions import db
from app.models.incident import Incident


def list_incidents(
    *,
    status: Optional[str] = None,
    severity: Optional[str] = None,
) -> List[Incident]:
    """Return incidents with optional filters, ordered newest first."""
    query = db.session.query(Incident)

    if status:
        query = query.filter(Incident.status == status)
    if severity:
        query = query.filter(Incident.severity == severity)

    return query.order_by(Incident.created_at.desc()).all()


def get_incident(incident_id: int) -> Optional[Incident]:
    """Fetch a single incident by primary key."""
    return db.session.get(Incident, incident_id)


def create_incident(data: dict) -> Incident:
    """Create and persist a new incident."""
    incident = Incident(
        title=data["title"],
        description=data.get("description"),
        severity=data["severity"],
        status=data.get("status", "open"),
        assigned_to=data.get("assigned_to"),
        service_id=data.get("service_id"),
    )
    db.session.add(incident)
    db.session.commit()
    return incident


def update_incident(incident: Incident, data: dict) -> Incident:
    """Update mutable fields on an incident."""
    for field in ("title", "description", "severity", "status", "assigned_to", "service_id"):
        if field in data:
            setattr(incident, field, data[field])

    # Automatically set resolved_at when status changes to resolved or closed.
    if data.get("status") in ("resolved", "closed") and incident.resolved_at is None:
        incident.resolved_at = datetime.now(timezone.utc)

    db.session.commit()
    return incident
