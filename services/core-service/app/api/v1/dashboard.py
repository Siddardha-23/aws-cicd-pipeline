"""Dashboard aggregate statistics endpoint."""

from flask import Blueprint, jsonify

from app.services.dashboard_service import get_dashboard_stats

dashboard_bp = Blueprint("dashboard", __name__)


@dashboard_bp.route("/dashboard/stats", methods=["GET"])
def dashboard_stats():
    """Return aggregated dashboard statistics."""
    stats = get_dashboard_stats()
    return jsonify(stats)
