"""User Marshmallow schema."""

from marshmallow import fields, validate

from app.extensions import ma
from app.models.user import User


class UserSchema(ma.SQLAlchemyAutoSchema):
    class Meta:
        model = User
        load_instance = True
        include_fk = True

    id = fields.Int(dump_only=True)
    username = fields.Str(required=True, validate=validate.Length(min=1, max=80))
    email = fields.Email(required=True)
    role = fields.Str(
        required=True,
        validate=validate.OneOf(["admin", "engineer", "viewer"]),
    )
    created_at = fields.DateTime(dump_only=True)
