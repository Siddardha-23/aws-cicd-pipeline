"""Health endpoint tests."""

import os

import pytest

os.environ["DATABASE_URL"] = "sqlite:///:memory:"

from app import create_app


@pytest.fixture
def client():
    """Create a test client with an in-memory SQLite database."""
    app = create_app()
    app.config["TESTING"] = True

    with app.app_context():
        from app.extensions import db

        db.create_all()
        yield app.test_client()
        db.drop_all()


def test_health_returns_200(client):
    """GET /api/v1/health should return 200 with status healthy."""
    response = client.get("/api/v1/health")
    assert response.status_code == 200
    data = response.get_json()
    assert data["status"] == "healthy"
    assert data["service"] == "deployment-service"
    assert "timestamp" in data
