#!/bin/sh
set -e

if [ "$1" = "api" ]; then
    echo "Running database schema migrations..."
    alembic upgrade head
    echo "Starting Uvicorn application server..."
    exec uvicorn src:app --host 0.0.0.0 --port 8000
elif [ "$1" = "worker" ]; then
    echo "Starting Celery background worker..."
    exec celery -A src.celery_tasks.c_app worker --loglevel=INFO
elif [ "$1" = "flower" ]; then
    echo "Starting Celery Flower dashboard..."
    exec celery -A src.celery_tasks.c_app flower --port=5555
else
    exec "$@"
fi
