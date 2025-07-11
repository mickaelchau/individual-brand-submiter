# ─────────────────────────────────────────────────────────────────
# Stage 1 – build the Python environment
# ─────────────────────────────────────────────────────────────────
FROM python:3.11-slim AS builder

# Install system libs needed by grpc + google-cloud packages
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        libffi-dev \
        && rm -rf /var/lib/apt/lists/*

# Enable pip cache layer-reuse & avoid byte-compilation
ENV PIP_NO_CACHE_DIR=1 \
    PYTHONUNBUFFERED=1

WORKDIR /src

# Copy only requirements first for better layer caching
COPY requirements.txt .

RUN pip install -r requirements.txt --prefix=/install

# ─────────────────────────────────────────────────────────────────
# Stage 2 – final runtime image (slim)
# ─────────────────────────────────────────────────────────────────
FROM python:3.11-slim

# same envs here
ENV PYTHONUNBUFFERED=1 \
    PORT=8080

# Copy runtime libs from builder stage
COPY --from=builder /install /usr/local

WORKDIR /app
COPY . .

# Expose Cloud Run port
EXPOSE 8080

# Gunicorn with 4 workers; tweak if memory-constrained
CMD ["gunicorn", "--bind", ":8080", "--workers", "4", "main:app"]
