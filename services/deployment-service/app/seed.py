"""Seed script to populate the database with demo deployment data."""

from datetime import datetime, timezone, timedelta

from app.extensions import db
from app.models.deployment import Deployment


def run_seed():
    """Insert demo deployment records."""
    now = datetime.now(timezone.utc)

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
    db.session.commit()
    print("Deployment database seeded successfully.")
