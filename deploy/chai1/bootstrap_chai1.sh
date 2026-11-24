#!/usr/bin/env bash
# Verified cloud bootstrap script for Chai-1 (chai_lab==0.6.1) on Runpod GPU Pods
set -euo pipefail

CACHE_PATH="${1:-/root/.chai1}"
PREBUILT_VENV="/opt/chai1_venv"
FALLBACK_VENV="/tmp/chai1_venv"

echo "[1/3] Checking free disk space..."
df -h /

if [ -x "${PREBUILT_VENV}/bin/chai-lab" ]; then
  VENV_PATH="${PREBUILT_VENV}"
  echo "[2/3] Detected pre-built Chai-1 runtime at ${VENV_PATH} — skipping pip install."
else
  VENV_PATH="${FALLBACK_VENV}"
  echo "[2/3] Creating clean isolated venv at ${VENV_PATH} (NO --system-site-packages)..."
  python3 -m venv "${VENV_PATH}"
  "${VENV_PATH}/bin/pip" install --no-cache-dir --upgrade pip
  "${VENV_PATH}/bin/pip" install --no-cache-dir "torch==2.6.0" --index-url https://download.pytorch.org/whl/cu124
  "${VENV_PATH}/bin/pip" install --no-cache-dir "chai_lab==0.6.1"
fi

echo "[3/3] Verifying Chai-1 & CUDA availability..."
export CHAI_DOWNLOADS_DIR="${CACHE_PATH}"
mkdir -p "${CHAI_DOWNLOADS_DIR}"
"${VENV_PATH}/bin/python" -c "
import torch, numpy, chai_lab.chai1, gemmi
assert torch.cuda.is_available(), 'CUDA not available!'
print('Chai-1 OK:', torch.__version__, 'CUDA:', torch.version.cuda, 'NumPy:', numpy.__version__, 'GPU:', torch.cuda.get_device_name(0))
"
