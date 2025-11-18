# Dockerfile (multi-stage)
FROM python:3.11-slim AS builder

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gcc \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /iris-softmax-classifier

COPY requirements.txt .
RUN python -m pip install --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt

# Copy everything including artifacts
COPY . .

# Debug: Show what files we have
RUN echo "📁 Checking artifacts directory:" && \
    ls -la artifacts/ || echo "❌ artifacts/ directory not found"

# Use the tuned model if it exists, otherwise train
RUN if [ -f "artifacts/tuned_model.pkl" ]; then \
        echo "✅ Using existing tuned model"; \
        cp artifacts/tuned_model.pkl artifacts/model.pkl; \
    else \
        echo "🔄 No tuned model found, training new model..."; \
        python -m src.train; \
    fi

FROM python:3.11-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    APP_HOME=/app

RUN useradd --create-home --shell /bin/bash appuser
WORKDIR $APP_HOME

# Copy Python packages AND executables (uvicorn, etc.)
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

COPY --from=builder /iris-softmax-classifier/app ./app
COPY --from=builder /iris-softmax-classifier/src ./src
COPY --from=builder /iris-softmax-classifier/artifacts ./artifacts
COPY --from=builder /iris-softmax-classifier/requirements.txt ./requirements.txt

ENV PORT=8080
EXPOSE 8080

RUN chown -R appuser:appuser $APP_HOME
USER appuser

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080", "--workers", "1"]