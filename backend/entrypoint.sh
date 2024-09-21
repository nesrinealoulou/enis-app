#!/bin/bash

# Run Django migrations
echo "Running migrations..."
python manage.py makemigrations
python manage.py migrate

# Start the Django development server
echo "Starting server..."
exec "$@"  # This runs the command passed to CMD in the Dockerfile

