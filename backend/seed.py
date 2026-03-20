"""Standalone seed runner (can also use `flask seed` CLI command)."""

from app import create_app
from app.seed import run_seed

app = create_app()
with app.app_context():
    run_seed()
