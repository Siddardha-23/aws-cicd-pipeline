"""Incidents CRUD endpoints."""

from flask import Blueprint, jsonify, request

from app.schemas.incident import IncidentSchema
from app.services.incident_service import (
    list_incidents,
    create_incident,
    get_incident,
    update_incident,
)

incidents_bp = Blueprint("incidents", __name__)

incident_schema = IncidentSchema()
incidents_schema = IncidentSchema(many=True)


@incidents_bp.route("/incidents", methods=["GET"])
def get_incidents():
    """List incidents with optional status/severity filters."""
    status = request.args.get("status")
    severity = request.args.get("severity")

    items = list_incidents(status=status, severity=severity)
    return jsonify(incidents_schema.dump(items))


@incidents_bp.route("/incidents", methods=["POST"])
def post_incident():
    """Create a new incident."""
    json_data = request.get_json()
    if not json_data:
        return jsonify({"error": "No input data provided"}), 400

    errors = incident_schema.validate(json_data)
    if errors:
        return jsonify({"errors": errors}), 422

    incident = create_incident(json_data)
    return jsonify(incident_schema.dump(incident)), 201


@incidents_bp.route("/incidents/<int:incident_id>", methods=["PATCH"])
def patch_incident(incident_id):
    """Update an incident (resolve, assign, etc.)."""
    json_data = request.get_json()
    if not json_data:
        return jsonify({"error": "No input data provided"}), 400

    incident = get_incident(incident_id)
    if incident is None:
        return jsonify({"error": "Incident not found"}), 404

    errors = incident_schema.validate(json_data, partial=True)
    if errors:
        return jsonify({"errors": errors}), 422

    updated = update_incident(incident, json_data)
    return jsonify(incident_schema.dump(updated))
