#!/usr/bin/env bash
# Verified cloud bootstrap script for Boltz-2 v2.2.1 on Runpod PyTorch Pods
# Supports both:
#   - Custom Image A (boltz2-runtime:2.2.1): detects /opt/boltz2_venv and skips pip install!
#   - Stock Runpod PyTorch image: creates clean venv (NO --system-site-packages) from requirements.lock.
# Usage: bash bootstrap_boltz2.sh [CACHE_PATH] [LOCKFILE_PATH]
set -euo pipefail

CACHE_PATH="${1:-/root/.boltz}"
LOCKFILE_PATH="${2:-}"
PREBUILT_VENV="/opt/boltz2_venv"
FALLBACK_VENV="/tmp/boltz2_venv"

echo "[1/4] Checking free disk space (require >= 25 GB for runtime + Boltz-2 cache)..."
df -h /

if [ -x "${PREBUILT_VENV}/bin/boltz" ]; then
  VENV_PATH="${PREBUILT_VENV}"
  echo "[2/4] Detected pre-built Boltz-2 runtime image at ${VENV_PATH} — skipping pip install."
else
  VENV_PATH="${FALLBACK_VENV}"
  echo "[2/4] Creating clean isolated venv at ${VENV_PATH} (NO --system-site-packages)..."
  python3 -m venv "${VENV_PATH}"
  "${VENV_PATH}/bin/pip" install --no-cache-dir --upgrade pip
  if [ -n "${LOCKFILE_PATH}" ] && [ -f "${LOCKFILE_PATH}" ]; then
    "${VENV_PATH}/bin/pip" install --no-cache-dir -r "${LOCKFILE_PATH}"
  else
    "${VENV_PATH}/bin/pip" install --no-cache-dir "boltz[cuda]==2.2.1"
  fi
fi

echo "[3/4] Verifying Boltz-2, PyTorch CUDA, NumPy < 2.0, and cuEquivariance..."
"${VENV_PATH}/bin/python" -c "
import torch, numpy, boltz.main, gemmi
assert torch.cuda.is_available(), 'CUDA not available!'
assert numpy.__version__.startswith('1.26.'), f'Unexpected NumPy: {numpy.__version__}'
print('OK:', torch.__version__, 'CUDA:', torch.version.cuda, 'NumPy:', numpy.__version__, 'GPU:', torch.cuda.get_device_name(0))
"

echo "[4/4] Ensuring Boltz-2 weights & CCD cache exist at ${CACHE_PATH} (~7.47 GB)..."
if [ -f "${CACHE_PATH}/boltz2_conf.ckpt" ] && [ -f "${CACHE_PATH}/boltz2_aff.ckpt" ] && [ -d "${CACHE_PATH}/mols" ]; then
  echo "Cached Boltz-2 weights already present at ${CACHE_PATH} — skipping download."
else
  mkdir -p "${CACHE_PATH}"
  "${VENV_PATH}/bin/python" -c "
from pathlib import Path
from boltz.main import download_boltz2
download_boltz2(Path('${CACHE_PATH}'))
print('Boltz-2 weights ready at ${CACHE_PATH}')
"
fi

echo "Bootstrap complete. Boltz binary: ${VENV_PATH}/bin/boltz"
