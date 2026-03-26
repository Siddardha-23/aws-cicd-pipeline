"""Service model."""

from datetime import datetime, timezone

from app.extensions import db


class Service(db.Model):
    __tablename__ = "services"

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(120), unique=True, nullable=False)
    status = db.Column(
        db.Enum("healthy", "degraded", "down", name="service_status"),
        nullable=False,
        default="healthy",
    )
    uptime_percentage = db.Column(db.Float, nullable=False, default=100.0)
    last_checked = db.Column(
        db.DateTime, nullable=True, default=lambda: datetime.now(timezone.utc)
    )
    endpoint_url = db.Column(db.String(255), nullable=True)
    description = db.Column(db.Text, nullable=True)
    created_at = db.Column(
        db.DateTime, nullable=False, default=lambda: datetime.now(timezone.utc)
    )
    updated_at = db.Column(
        db.DateTime,
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )

    # Relationships
    incidents = db.relationship("Incident", back_populates="service", lazy="dynamic")

    def __repr__(self):
        return f"<Service {self.name}>"
