"""Core service application factory."""

from flask import Flask

from config import Config
from app.extensions import db, migrate, ma, limiter, cors
from app.middleware.error_handler import register_error_handlers
from app.middleware.security import register_security_headers


def create_app(config_class=Config):
    """Create and configure the Flask application."""
    app = Flask(__name__)
    app.config.from_object(config_class)

    # Initialise extensions
    db.init_app(app)
    migrate.init_app(app, db)
    ma.init_app(app)
    cors.init_app(app)
    limiter.init_app(app)

    # Import models so Alembic can detect them
    from app import models as _models  # noqa: F401

    # Register blueprints
    from app.api.v1.health import health_bp
    from app.api.v1.dashboard import dashboard_bp
    from app.api.v1.services import services_bp
    from app.api.v1.incidents import incidents_bp

    app.register_blueprint(health_bp, url_prefix="/api/v1")
    app.register_blueprint(dashboard_bp, url_prefix="/api/v1")
    app.register_blueprint(services_bp, url_prefix="/api/v1")
    app.register_blueprint(incidents_bp, url_prefix="/api/v1")

    # Error handlers & security headers
    register_error_handlers(app)
    register_security_headers(app)

    # Custom CLI commands
    _register_cli(app)

    return app


def _register_cli(app: Flask):
    """Register custom CLI commands."""

    @app.cli.command("seed")
    def seed_command():
        """Populate the database with demo data."""
        from app.seed import run_seed

        run_seed()
