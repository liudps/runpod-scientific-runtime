# runpod-scientific-runtime

Clean, infrastructure-only repository for building reproducible open-source scientific computing container images on GitHub Actions and publishing them to GitHub Container Registry (GHCR).

## Images

- **`boltz2-runtime:2.2.1`** (Variant A — Default):
  - Pinned Runpod PyTorch CUDA base image (`@sha256:0a360022e8de4375af99430f84e8b38951acc397252163a37ceac7204d01be35`)
  - Isolated Python 3.12 virtual environment (`/opt/boltz2_venv`, no `--system-site-packages`)
  - Exact 110-package lockfile (`deploy/boltz2/requirements.lock`) including `boltz==2.2.1`, `torch==2.15.0`, `cuequivariance==0.13.0`, `numpy==1.26.4`, `pytorch-lightning==2.5.0`, `rdkit==2026.9.2`, `gemmi==0.6.5`
  - **No model weights, no secrets, no proprietary data included.** Weights are downloaded on demand at runtime in cloud compute Pods.

## License

MIT License. See `LICENSE`.
