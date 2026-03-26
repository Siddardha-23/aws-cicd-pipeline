"""Health check endpoint."""

from datetime import datetime, timezone

from flask import Blueprint, jsonify

health_bp = Blueprint("health", __name__)


@health_bp.route("/health", methods=["GET"])
def health_check():
    """Return service health status."""
    return jsonify(
        {
            "status": "healthy",
            "service": "deployment-service",
            "timestamp": datetime.now(timezone.utc).isoformat(),
        }
    )
