"""Incident Marshmallow schema."""

from marshmallow import fields, validate

from app.extensions import ma
from app.models.incident import Incident


class IncidentSchema(ma.SQLAlchemyAutoSchema):
    class Meta:
        model = Incident
        load_instance = True
        include_fk = True

    id = fields.Int(dump_only=True)
    title = fields.Str(required=True, validate=validate.Length(min=1, max=200))
    description = fields.Str()
    severity = fields.Str(
        required=True,
        validate=validate.OneOf(["critical", "high", "medium", "low"]),
    )
    status = fields.Str(
        validate=validate.OneOf(["open", "investigating", "resolved", "closed"]),
    )
    assigned_to = fields.Int(allow_none=True, load_default=None)
    service_id = fields.Int(allow_none=True, load_default=None)
    created_at = fields.DateTime(dump_only=True)
    resolved_at = fields.DateTime(dump_only=True)
