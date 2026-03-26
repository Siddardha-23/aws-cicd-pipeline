"""Deployment model."""

from datetime import datetime, timezone

from app.extensions import db


class Deployment(db.Model):
    __tablename__ = "deployments"

    id = db.Column(db.Integer, primary_key=True)
    service_name = db.Column(db.String(120), nullable=False)
    environment = db.Column(
        db.Enum("production", "staging", "development", name="deploy_environment"),
        nullable=False,
    )
    status = db.Column(
        db.Enum(
            "success", "failed", "in_progress", "rolled_back", name="deploy_status"
        ),
        nullable=False,
        default="in_progress",
    )
    commit_sha = db.Column(db.String(8), nullable=False)
    commit_message = db.Column(db.Text, nullable=True)
    deployed_by = db.Column(db.String(80), nullable=False)
    duration_seconds = db.Column(db.Integer, nullable=True)
    created_at = db.Column(
        db.DateTime, nullable=False, default=lambda: datetime.now(timezone.utc)
    )

    def __repr__(self):
        return f"<Deployment {self.id} {self.service_name}>"
