"""Dashboard business logic - aggregated statistics."""

from datetime import datetime, timezone, timedelta

from app.extensions import db
from app.models.deployment import Deployment
from app.models.service import Service
from app.models.incident import Incident
from app.schemas.deployment import DeploymentSchema


deployment_schema = DeploymentSchema(many=True)


def get_dashboard_stats() -> dict:
    """Build and return aggregated dashboard statistics."""
    now = datetime.now(timezone.utc)
    start_of_today = now.replace(hour=0, minute=0, second=0, microsecond=0)

    # Deployment stats
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

    # Service stats
    total_services = db.session.query(Service).count()
    healthy_services = (
        db.session.query(Service).filter(Service.status == "healthy").count()
    )
    degraded_services = (
        db.session.query(Service).filter(Service.status == "degraded").count()
    )
    down_services = (
        db.session.query(Service).filter(Service.status == "down").count()
    )

    # Incident stats
    open_incidents = (
        db.session.query(Incident)
        .filter(Incident.status.in_(["open", "investigating"]))
        .count()
    )
    critical_incidents = (
        db.session.query(Incident)
        .filter(
            Incident.severity == "critical",
            Incident.status.in_(["open", "investigating"]),
        )
        .count()
    )

    # Recent deployments
    recent = (
        db.session.query(Deployment)
        .order_by(Deployment.created_at.desc())
        .limit(5)
        .all()
    )

    return {
        "total_deployments": total_deployments,
        "deployments_today": deployments_today,
        "success_rate": success_rate,
        "total_services": total_services,
        "healthy_services": healthy_services,
        "degraded_services": degraded_services,
        "down_services": down_services,
        "open_incidents": open_incidents,
        "critical_incidents": critical_incidents,
        "recent_deployments": deployment_schema.dump(recent),
    }
