# Phase 6 Production Dockerfile — Chai-1 (chai_lab==0.6.1)
# Independent runtime image; does NOT overwrite boltz2-runtime.
#
# Security & reproducibility guarantees:
#   - Base image pinned by immutable SHA-256 digest.
#   - 100% isolated Python 3.12 venv (/opt/chai1_venv) WITHOUT --system-site-packages
#     (chai_lab==0.6.1 requires torch<2.7,>=2.3.1, incompatible with base image torch 2.8.0).
#   - Zero model weights baked into image (weights downloaded on demand to CHAI_DOWNLOADS_DIR).
#   - Zero API keys, SSH keys, or proprietary research data embedded.

FROM runpod/pytorch:1.0.2-cu1281-torch280-ubuntu2404@sha256:0a360022e8de4375af99430f84e8b38951acc397252163a37ceac7204d01be35

LABEL org.opencontainers.image.title="runpod-chai1-runtime" \
      org.opencontainers.image.description="Reproducible Chai-1 (chai_lab 0.6.1) CUDA runtime for Runpod AI drug design" \
      org.opencontainers.image.version="0.6.1" \
      org.opencontainers.image.licenses="Apache-2.0"

ENV DEBIAN_FRONTEND=noninteractive \
    CHAI_VENV=/opt/chai1_venv \
    CHAI_DOWNLOADS_DIR=/root/.chai1 \
    PIP_NO_CACHE_DIR=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

RUN apt-get update && \
    apt-get install -y --no-install-recommends rsync ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Create 100% isolated Python 3.12 venv (NO --system-site-packages)
# Install PyTorch 2.6.0+cu124 first (satisfies chai_lab torch<2.7,>=2.3.1), then chai_lab==0.6.1
RUN python3 -m venv "${CHAI_VENV}" && \
    "${CHAI_VENV}/bin/pip" install --no-cache-dir --upgrade pip && \
    "${CHAI_VENV}/bin/pip" install --no-cache-dir "torch==2.6.0" --index-url https://download.pytorch.org/whl/cu124 && \
    "${CHAI_VENV}/bin/pip" install --no-cache-dir "chai_lab==0.6.1" && \
    "${CHAI_VENV}/bin/pip" freeze > "${CHAI_VENV}/requirements.lock"

# Build-time import & version verification (CPU-safe; CUDA verified at Pod runtime)
RUN "${CHAI_VENV}/bin/python" -c "\
import chai_lab.chai1, torch, numpy, gemmi, rdkit; \
assert torch.__version__.startswith('2.6.'), f'Unexpected torch: {torch.__version__}'; \
assert numpy.__version__.startswith('1.'), f'Unexpected numpy: {numpy.__version__}'; \
print('Chai-1 runtime verified:', torch.__version__, numpy.__version__)"

ENV PATH="${CHAI_VENV}/bin:${PATH}"
WORKDIR /workspace
