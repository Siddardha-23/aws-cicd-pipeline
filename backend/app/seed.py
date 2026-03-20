"""Seed script to populate the database with demo data."""

from datetime import datetime, timezone, timedelta

from app.extensions import db
from app.models.user import User
from app.models.service import Service
from app.models.deployment import Deployment
from app.models.incident import Incident


def run_seed():
    """Insert demo records into the database."""
    now = datetime.now(timezone.utc)

    # --- Users ---
    demo_user = User(
        username="demo_admin",
        email="admin@opsboard.dev",
        role="admin",
    )
    engineer = User(
        username="jane_engineer",
        email="jane@opsboard.dev",
        role="engineer",
    )
    db.session.add_all([demo_user, engineer])
    db.session.flush()  # get IDs

    # --- Services ---
    api_svc = Service(
        name="api-gateway",
        status="healthy",
        uptime_percentage=99.95,
        endpoint_url="https://api.opsboard.dev",
        description="Main API gateway",
    )
    auth_svc = Service(
        name="auth-service",
        status="healthy",
        uptime_percentage=99.99,
        endpoint_url="https://auth.opsboard.dev",
        description="Authentication micro-service",
    )
    payment_svc = Service(
        name="payment-service",
        status="degraded",
        uptime_percentage=98.50,
        endpoint_url="https://payments.opsboard.dev",
        description="Payment processing service",
    )
    worker_svc = Service(
        name="background-worker",
        status="healthy",
        uptime_percentage=99.80,
        description="Async job processor",
    )
    db.session.add_all([api_svc, auth_svc, payment_svc, worker_svc])
    db.session.flush()

    # --- Deployments ---
    deployments = [
        Deployment(
            service_name="api-gateway",
            environment="production",
            status="success",
            commit_sha="a1b2c3d4",
            commit_message="Add rate-limiting middleware",
            deployed_by="jane_engineer",
            duration_seconds=45,
            created_at=now - timedelta(hours=2),
        ),
        Deployment(
            service_name="auth-service",
            environment="staging",
            status="success",
            commit_sha="e5f6a7b8",
            commit_message="Upgrade JWT library",
            deployed_by="demo_admin",
            duration_seconds=32,
            created_at=now - timedelta(hours=5),
        ),
        Deployment(
            service_name="payment-service",
            environment="production",
            status="failed",
            commit_sha="c9d0e1f2",
            commit_message="Migrate to Stripe v3",
            deployed_by="jane_engineer",
            duration_seconds=120,
            created_at=now - timedelta(hours=8),
        ),
        Deployment(
            service_name="payment-service",
            environment="production",
            status="rolled_back",
            commit_sha="c9d0e1f2",
            commit_message="Rollback Stripe v3 migration",
            deployed_by="jane_engineer",
            duration_seconds=15,
            created_at=now - timedelta(hours=7),
        ),
        Deployment(
            service_name="background-worker",
            environment="development",
            status="success",
            commit_sha="11223344",
            commit_message="Add retry logic for failed jobs",
            deployed_by="demo_admin",
            duration_seconds=28,
            created_at=now - timedelta(days=1),
        ),
    ]
    db.session.add_all(deployments)

    # --- Incidents ---
    incidents = [
        Incident(
            title="Payment gateway timeouts",
            description="Intermittent 504 errors on /charge endpoint",
            severity="critical",
            status="investigating",
            assigned_to=engineer.id,
            service_id=payment_svc.id,
            created_at=now - timedelta(hours=3),
        ),
        Incident(
            title="High memory usage on worker pods",
            description="Memory exceeding 85% on background-worker pods",
            severity="medium",
            status="open",
            assigned_to=engineer.id,
            service_id=worker_svc.id,
            created_at=now - timedelta(hours=12),
        ),
        Incident(
            title="SSL certificate expiring soon",
            description="Certificate for auth.opsboard.dev expires in 7 days",
            severity="high",
            status="open",
            service_id=auth_svc.id,
            created_at=now - timedelta(days=1),
        ),
    ]
    db.session.add_all(incidents)

    db.session.commit()
    print("Database seeded successfully.")
