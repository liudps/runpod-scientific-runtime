# Phase 4 Production Dockerfile — Boltz-2 v2.2.1
# Audited against Phase 3 verified A100-SXM4-80GB run (Pod 1qc7czpes377ak, US-WA-1)
#
# Image variants:
#   - Variant A (Default, Recommended): boltz2-runtime:2.2.1  (INCLUDE_WEIGHTS=false)
#       Contains ONLY verified open-source runtime (~8.4 GB venv). Zero weights, zero secrets.
#   - Variant B (Optional):             boltz2-full:2.2.1     (INCLUDE_WEIGHTS=true)
#       Adds ~7.47 GB Boltz-2 MIT weights + CCD cache at build time.
#
# Security guarantees:
#   - Base image pinned by immutable SHA-256 digest.
#   - Clean isolated venv (/opt/boltz2_venv) WITHOUT --system-site-packages (avoids torchvision::nms ABI conflict).
#   - Exact 110-package lockfile (requirements.lock) from Phase 3 verified environment.
#   - Zero API keys, SSH keys, or proprietary scientific data embedded.

FROM runpod/pytorch:1.0.2-cu1281-torch280-ubuntu2404@sha256:0a360022e8de4375af99430f84e8b38951acc397252163a37ceac7204d01be35

ARG INCLUDE_WEIGHTS=false

LABEL org.opencontainers.image.title="runpod-boltz2-runtime" \
      org.opencontainers.image.description="Reproducible Boltz-2 v2.2.1 CUDA runtime for Runpod AI drug design" \
      org.opencontainers.image.version="2.2.1" \
      org.opencontainers.image.licenses="MIT"

ENV DEBIAN_FRONTEND=noninteractive \
    BOLTZ_VENV=/opt/boltz2_venv \
    BOLTZ_CACHE=/root/.boltz \
    PIP_NO_CACHE_DIR=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# Minimal OS tools required for verified rsync result transfer and diagnostics
RUN apt-get update && \
    apt-get install -y --no-install-recommends rsync ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Copy ONLY the audited lockfile (never secrets or research data)
COPY requirements.lock /tmp/requirements.lock

# Create 100% isolated Python 3.12 venv (NO --system-site-packages) and install exact Phase 3 lockfile
# Note: force-reinstall pinned nvidia-nccl-cu13==2.30.7 last so nvidia-nccl-cu12 cannot overwrite libnccl.so.2
RUN python3 -m venv "${BOLTZ_VENV}" && \
    "${BOLTZ_VENV}/bin/pip" install --no-cache-dir --upgrade pip && \
    "${BOLTZ_VENV}/bin/pip" install --no-cache-dir -r /tmp/requirements.lock && \
    "${BOLTZ_VENV}/bin/pip" install --no-cache-dir --no-deps --force-reinstall "nvidia-nccl-cu13==2.30.7" && \
    rm -f /tmp/requirements.lock

# Verify critical imports & pinned versions at build time (CPU-safe check; CUDA verified at pod runtime)
RUN "${BOLTZ_VENV}/bin/python" -c "\
import boltz.main, torch, numpy, gemmi, rdkit, pytorch_lightning; \
assert numpy.__version__.startswith('1.26.'), f'Unexpected numpy: {numpy.__version__}'; \
print('Boltz-2 runtime verified:', torch.__version__, numpy.__version__, pytorch_lightning.__version__)"

# Optional Variant B: bake MIT-licensed Boltz-2 weights + CCD cache (~7.47 GB)
RUN if [ "${INCLUDE_WEIGHTS}" = "true" ]; then \
      mkdir -p "${BOLTZ_CACHE}" && \
      "${BOLTZ_VENV}/bin/python" -c "from pathlib import Path; from boltz.main import download_boltz2; download_boltz2(Path('${BOLTZ_CACHE}'))"; \
    fi

ENV PATH="${BOLTZ_VENV}/bin:${PATH}"
WORKDIR /workspace
