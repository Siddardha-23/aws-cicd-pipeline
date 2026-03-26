"""Deployment Marshmallow schema."""

from marshmallow import fields, validate

from app.extensions import ma
from app.models.deployment import Deployment


class DeploymentSchema(ma.SQLAlchemyAutoSchema):
    class Meta:
        model = Deployment
        load_instance = True
        include_fk = True

    id = fields.Int(dump_only=True)
    service_name = fields.Str(required=True, validate=validate.Length(min=1, max=120))
    environment = fields.Str(
        required=True,
        validate=validate.OneOf(["production", "staging", "development"]),
    )
    status = fields.Str(
        validate=validate.OneOf(
            ["success", "failed", "in_progress", "rolled_back"]
        ),
    )
    commit_sha = fields.Str(
        required=True,
        validate=validate.Length(equal=8),
    )
    commit_message = fields.Str(validate=validate.Length(max=500))
    deployed_by = fields.Str(required=True, validate=validate.Length(min=1, max=80))
    duration_seconds = fields.Int(validate=validate.Range(min=0))
    created_at = fields.DateTime(dump_only=True)
