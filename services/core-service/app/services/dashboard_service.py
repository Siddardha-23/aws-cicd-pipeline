"""Dashboard business logic - aggregated statistics.

This service queries local models (Service, Incident) and fetches
deployment stats from the deployment-service via HTTP.
"""

import requests
from flask import current_app

from app.extensions import db
from app.models.service import Service
from app.models.incident import Incident


def _get_deployment_stats() -> dict:
    """Fetch deployment statistics from the deployment-service."""
    url = f"{current_app.config['DEPLOYMENT_SERVICE_URL']}/internal/stats"
    try:
        resp = requests.get(url, timeout=3)
        resp.raise_for_status()
        return resp.json()
    except requests.RequestException:
        # Graceful degradation: return zeros if deployment-service is unreachable
        return {
            "total_deployments": 0,
            "deployments_today": 0,
            "success_rate": 0.0,
            "recent_deployments": [],
        }


def get_dashboard_stats() -> dict:
    """Build and return aggregated dashboard statistics."""
    # Fetch deployment stats from deployment-service
    deployment_stats = _get_deployment_stats()

    # Service stats (local DB)
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

    # Incident stats (local DB)
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

    return {
        "total_deployments": deployment_stats["total_deployments"],
        "deployments_today": deployment_stats["deployments_today"],
        "success_rate": deployment_stats["success_rate"],
        "total_services": total_services,
        "healthy_services": healthy_services,
        "degraded_services": degraded_services,
        "down_services": down_services,
        "open_incidents": open_incidents,
        "critical_incidents": critical_incidents,
        "recent_deployments": deployment_stats["recent_deployments"],
    }
