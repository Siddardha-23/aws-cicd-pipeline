#!/bin/bash
set -e

# Run migrations only in development (docker-compose).
# In production, migrations run as a separate ECS task via migrate.sh
if [ "$FLASK_ENV" != "production" ]; then
    if [ ! -f migrations/env.py ]; then
        echo "Initialising Flask-Migrate..."
        flask db init
    fi

    echo "Running database migrations..."
    flask db migrate -m "auto" 2>/dev/null || true
    flask db upgrade
fi

echo "Starting deployment-service..."
exec gunicorn --bind 0.0.0.0:5001 --workers 2 --threads 2 --timeout 120 wsgi:app
