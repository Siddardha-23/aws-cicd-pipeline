"""Deployment business logic."""

from typing import Optional

from flask_sqlalchemy.pagination import Pagination

from app.extensions import db
from app.models.deployment import Deployment


def list_deployments(
    *,
    status: Optional[str] = None,
    environment: Optional[str] = None,
    page: int = 1,
    per_page: int = 20,
) -> Pagination:
    """Return a paginated list of deployments with optional filters."""
    query = db.session.query(Deployment)

    if status:
        query = query.filter(Deployment.status == status)
    if environment:
        query = query.filter(Deployment.environment == environment)

    query = query.order_by(Deployment.created_at.desc())
    return query.paginate(page=page, per_page=per_page, error_out=False)


def get_deployment(deployment_id: int) -> Optional[Deployment]:
    """Fetch a single deployment by primary key."""
    return db.session.get(Deployment, deployment_id)


def create_deployment(data: dict) -> Deployment:
    """Create and persist a new deployment."""
    deployment = Deployment(
        service_name=data["service_name"],
        environment=data["environment"],
        status=data.get("status", "in_progress"),
        commit_sha=data["commit_sha"],
        commit_message=data.get("commit_message"),
        deployed_by=data["deployed_by"],
        duration_seconds=data.get("duration_seconds"),
    )
    db.session.add(deployment)
    db.session.commit()
    return deployment
