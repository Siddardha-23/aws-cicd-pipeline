"""Services CRUD endpoints."""

from flask import Blueprint, jsonify, request

from app.schemas.service import ServiceSchema
from app.services.service_service import (
    list_services,
    get_service,
    update_service,
)

services_bp = Blueprint("services", __name__)

service_schema = ServiceSchema()
services_schema = ServiceSchema(many=True)


@services_bp.route("/services", methods=["GET"])
def get_services():
    """List all services."""
    items = list_services()
    return jsonify(services_schema.dump(items))


@services_bp.route("/services/<int:service_id>", methods=["GET"])
def get_single_service(service_id):
    """Get a single service by ID."""
    svc = get_service(service_id)
    if svc is None:
        return jsonify({"error": "Service not found"}), 404
    return jsonify(service_schema.dump(svc))


@services_bp.route("/services/<int:service_id>", methods=["PATCH"])
def patch_service(service_id):
    """Update a service (e.g. status)."""
    json_data = request.get_json()
    if not json_data:
        return jsonify({"error": "No input data provided"}), 400

    svc = get_service(service_id)
    if svc is None:
        return jsonify({"error": "Service not found"}), 404

    errors = service_schema.validate(json_data, partial=True)
    if errors:
        return jsonify({"errors": errors}), 422

    updated = update_service(svc, json_data)
    return jsonify(service_schema.dump(updated))
