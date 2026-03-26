"""Incident model."""

from datetime import datetime, timezone

from app.extensions import db


class Incident(db.Model):
    __tablename__ = "incidents"

    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text, nullable=True)
    severity = db.Column(
        db.Enum("critical", "high", "medium", "low", name="incident_severity"),
        nullable=False,
        default="medium",
    )
    status = db.Column(
        db.Enum(
            "open", "investigating", "resolved", "closed", name="incident_status"
        ),
        nullable=False,
        default="open",
    )
    assigned_to = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=True)
    service_id = db.Column(db.Integer, db.ForeignKey("services.id"), nullable=True)
    created_at = db.Column(
        db.DateTime, nullable=False, default=lambda: datetime.now(timezone.utc)
    )
    resolved_at = db.Column(db.DateTime, nullable=True)

    # Relationships
    assignee = db.relationship("User", back_populates="incidents")
    service = db.relationship("Service", back_populates="incidents")

    def __repr__(self):
        return f"<Incident {self.id} {self.title}>"
