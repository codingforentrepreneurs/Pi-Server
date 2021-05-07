#!/bin/bash
RUN_PORT=${PORT:-8000}
exec /app/bin/gunicorn --bind 0.0.0.0:$RUN_PORT  wsgi:app