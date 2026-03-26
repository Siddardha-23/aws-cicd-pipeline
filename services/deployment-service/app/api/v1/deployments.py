"""Deployments CRUD endpoints."""

from flask import Blueprint, jsonify, request

from app.schemas.deployment import DeploymentSchema
from app.services.deployment_service import (
    list_deployments,
    get_deployment,
    create_deployment,
)

deployments_bp = Blueprint("deployments", __name__)

deployment_schema = DeploymentSchema()
deployments_schema = DeploymentSchema(many=True)


@deployments_bp.route("/deployments", methods=["GET"])
def get_deployments():
    """List deployments with optional filters and pagination."""
    status = request.args.get("status")
    environment = request.args.get("environment")
    page = request.args.get("page", 1, type=int)
    per_page = request.args.get("per_page", 20, type=int)

    pagination = list_deployments(
        status=status, environment=environment, page=page, per_page=per_page
    )
    return jsonify(
        {
            "items": deployments_schema.dump(pagination.items),
            "total": pagination.total,
            "page": pagination.page,
            "per_page": pagination.per_page,
            "pages": pagination.pages,
        }
    )


@deployments_bp.route("/deployments", methods=["POST"])
def post_deployment():
    """Create a new deployment."""
    json_data = request.get_json()
    if not json_data:
        return jsonify({"error": "No input data provided"}), 400

    errors = deployment_schema.validate(json_data)
    if errors:
        return jsonify({"errors": errors}), 422

    deployment = create_deployment(json_data)
    return jsonify(deployment_schema.dump(deployment)), 201


@deployments_bp.route("/deployments/<int:deployment_id>", methods=["GET"])
def get_single_deployment(deployment_id):
    """Get a single deployment by ID."""
    deployment = get_deployment(deployment_id)
    if deployment is None:
        return jsonify({"error": "Deployment not found"}), 404
    return jsonify(deployment_schema.dump(deployment))
