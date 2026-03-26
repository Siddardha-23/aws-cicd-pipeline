#!/bin/bash
set -e

# This script runs as a one-time ECS task before deployment.
# It handles database migrations separately from the application startup.

if [ ! -f migrations/env.py ]; then
    echo "Initialising Flask-Migrate..."
    flask db init
fi

echo "Running database migrations..."
flask db migrate -m "auto" 2>/dev/null || true
flask db upgrade

echo "Migrations complete."
