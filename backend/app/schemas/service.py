"""Service Marshmallow schema."""

from marshmallow import fields, validate

from app.extensions import ma
from app.models.service import Service


class ServiceSchema(ma.SQLAlchemyAutoSchema):
    class Meta:
        model = Service
        load_instance = True
        include_fk = True

    id = fields.Int(dump_only=True)
    name = fields.Str(required=True, validate=validate.Length(min=1, max=120))
    status = fields.Str(
        validate=validate.OneOf(["healthy", "degraded", "down"]),
    )
    uptime_percentage = fields.Float(validate=validate.Range(min=0.0, max=100.0))
    last_checked = fields.DateTime(dump_only=True)
    endpoint_url = fields.Str(validate=validate.Length(max=255))
    description = fields.Str()
    created_at = fields.DateTime(dump_only=True)
    updated_at = fields.DateTime(dump_only=True)
