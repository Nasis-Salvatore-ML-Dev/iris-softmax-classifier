# Dockerfile (multi-stage)
# Stage 1: builder - install deps and train model
FROM python:3.11-slim AS builder

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Install system deps needed for building some packages (kept minimal)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gcc \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# Copy dependency manifest and install build deps
COPY requirements.txt .
RUN python -m pip install --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt

# Copy project code and data
COPY . .

# Run training to produce artifact/model.pkl in artifacts/
# If training is slow you can pretrain and check in artifact for production,
# but building it here guarantees model is inside the final image.
RUN python -m src.train

# Stage 2: runtime - small, non-root image
FROM python:3.11-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    APP_HOME=/app

# Create a non-root user
RUN useradd --create-home --shell /bin/bash appuser

WORKDIR $APP_HOME

# Copy only the runtime pieces: app, src, artifacts, and requirements (reinstall slim runtime deps)
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /workspace/app ./app
COPY --from=builder /workspace/src ./src
COPY --from=builder /workspace/artifacts ./artifacts
COPY --from=builder /workspace/requirements.txt ./requirements.txt

# Expose the port Cloud Run expects (can be overridden)
ENV PORT=8080
EXPOSE 8080

# Set ownership & switch to non-root
RUN chown -R appuser:appuser $APP_HOME
USER appuser

# Entrypoint uses uvicorn
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080", "--workers", "1"]
