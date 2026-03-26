"""Internal stats endpoint for inter-service communication.

This endpoint is NOT exposed through the ALB — it is only reachable
within the VPC by other ECS services (e.g. core-service).
"""

from datetime import datetime, timezone

from flask import Blueprint, jsonify

from app.extensions import db
from app.models.deployment import Deployment
from app.schemas.deployment import DeploymentSchema

internal_bp = Blueprint("internal", __name__)

deployment_schema = DeploymentSchema(many=True)


@internal_bp.route("/stats", methods=["GET"])
def deployment_stats():
    """Return aggregated deployment statistics for the dashboard."""
    now = datetime.now(timezone.utc)
    start_of_today = now.replace(hour=0, minute=0, second=0, microsecond=0)

    total_deployments = db.session.query(Deployment).count()
    deployments_today = (
        db.session.query(Deployment)
        .filter(Deployment.created_at >= start_of_today)
        .count()
    )
    successful = (
        db.session.query(Deployment)
        .filter(Deployment.status == "success")
        .count()
    )
    success_rate = (
        round((successful / total_deployments) * 100, 1) if total_deployments else 0.0
    )

    recent = (
        db.session.query(Deployment)
        .order_by(Deployment.created_at.desc())
        .limit(5)
        .all()
    )

    return jsonify(
        {
            "total_deployments": total_deployments,
            "deployments_today": deployments_today,
            "success_rate": success_rate,
            "recent_deployments": deployment_schema.dump(recent),
        }
    )
