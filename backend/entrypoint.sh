#!/bin/bash
set -e

# Initialise migrations directory if this is the first run
if [ ! -f migrations/env.py ]; then
    echo "Initialising Flask-Migrate..."
    flask db init
fi

echo "Running database migrations..."
flask db migrate -m "auto" 2>/dev/null || true
flask db upgrade

echo "Starting gunicorn..."
exec gunicorn --bind 0.0.0.0:5000 --workers 2 --threads 2 --timeout 120 wsgi:app
