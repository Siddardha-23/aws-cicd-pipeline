"""User model."""

from datetime import datetime, timezone

from app.extensions import db


class User(db.Model):
    __tablename__ = "users"

    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    role = db.Column(
        db.Enum("admin", "engineer", "viewer", name="user_role"),
        nullable=False,
        default="viewer",
    )
    created_at = db.Column(
        db.DateTime, nullable=False, default=lambda: datetime.now(timezone.utc)
    )

    # Relationships
    incidents = db.relationship("Incident", back_populates="assignee", lazy="dynamic")

    def __repr__(self):
        return f"<User {self.username}>"
