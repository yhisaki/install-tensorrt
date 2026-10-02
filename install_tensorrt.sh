#!/usr/bin/env bash
# Install TensorRT 10.8.0 into $HOME without root.
# Target: x86_64 / Ubuntu 22.04 / CUDA 12.8 (/usr/local/cuda-12.8) / system python3 (3.10)
#
# Usage:
#   curl -fsSL https://yhisaki.github.io/install-tensorrt/install_tensorrt.sh | bash
#   ./install_tensorrt.sh   (PREFIX=... to change the install location)
# Works from bash / zsh / fish (the script itself runs under bash).
# Generates env.sh (bash/zsh) and env.fish, and prints the line to add to your shell rc.

set -euo pipefail

TRT_BUILD="10.8.0.43"
CUDA_VER="12.8"
TAR_NAME="TensorRT-${TRT_BUILD}.Linux.x86_64-gnu.cuda-${CUDA_VER}.tar.gz"
URL="https://developer.nvidia.com/downloads/compute/machine-learning/tensorrt/10.8.0/tars/${TAR_NAME}"

PREFIX="${PREFIX:-$HOME/.local/opt/tensorrt}"
INSTALL_DIR="${PREFIX}/TensorRT-${TRT_BUILD}"
TARBALL="${PREFIX}/downloads/${TAR_NAME}"
CUDA_HOME="/usr/local/cuda-${CUDA_VER}"

log() { printf '\033[1;32m[install-trt]\033[0m %s\n' "$*"; }
die() { printf '\033[1;31m[install-trt]\033[0m %s\n' "$*" >&2; exit 1; }

# Everything runs inside main() so that a truncated `curl | bash` download
# never executes a partial script.
main() {
    [[ -d "$CUDA_HOME" ]] || die "$CUDA_HOME not found."
    mkdir -p "${PREFIX}/downloads"

    # --- Download (resumable, cached) ---
    if ! tar -tzf "$TARBALL" >/dev/null 2>&1; then
        log "Downloading ${TAR_NAME}"
        curl -fL --retry 3 -C - -o "$TARBALL" "$URL"
        tar -tzf "$TARBALL" >/dev/null || die "Broken tarball: $TARBALL"
    fi

    # --- Extract ---
    if [[ ! -f "$INSTALL_DIR/lib/libnvinfer.so.10" ]]; then
        log "Extracting to ${INSTALL_DIR}"
        rm -rf "$INSTALL_DIR"
        tar -xzf "$TARBALL" -C "$PREFIX"
    fi
    ln -sfn "$INSTALL_DIR" "${PREFIX}/current"

    # --- Environment for fish ---
    cat > "${PREFIX}/env.fish" <<EOF
set -gx TENSORRT_ROOT ${PREFIX}/current
set -gx TensorRT_ROOT \$TENSORRT_ROOT
set -gx CUDA_HOME ${CUDA_HOME}
set -gx --path LD_LIBRARY_PATH \$TENSORRT_ROOT/lib \$CUDA_HOME/lib64 \$LD_LIBRARY_PATH
set -gx --path CPATH \$TENSORRT_ROOT/include \$CPATH
set -gx --path CMAKE_LIBRARY_PATH \$TENSORRT_ROOT/lib \$CMAKE_LIBRARY_PATH
fish_add_path -g \$TENSORRT_ROOT/bin \$CUDA_HOME/bin
EOF
    # --- Environment for bash / zsh (POSIX sh syntax) ---
    cat > "${PREFIX}/env.sh" <<EOF
export TENSORRT_ROOT=${PREFIX}/current
export TensorRT_ROOT=\$TENSORRT_ROOT
export CUDA_HOME=${CUDA_HOME}
export LD_LIBRARY_PATH=\$TENSORRT_ROOT/lib:\$CUDA_HOME/lib64\${LD_LIBRARY_PATH:+:\$LD_LIBRARY_PATH}
export CPATH=\$TENSORRT_ROOT/include\${CPATH:+:\$CPATH}
export CMAKE_LIBRARY_PATH=\$TENSORRT_ROOT/lib\${CMAKE_LIBRARY_PATH:+:\$CMAKE_LIBRARY_PATH}
export PATH=\$TENSORRT_ROOT/bin:\$CUDA_HOME/bin:\$PATH
EOF

    # --- Python wheel (into active venv if any, else --user) ---
    local pytag wheel user_flag
    pytag="$(python3 -c 'import sys; print(f"cp{sys.version_info[0]}{sys.version_info[1]}")')"
    wheel="$(ls "$INSTALL_DIR"/python/tensorrt-"${TRT_BUILD}"-"${pytag}"-*.whl)"
    user_flag="--user"
    [[ -n "${VIRTUAL_ENV:-}${CONDA_PREFIX:-}" ]] && user_flag=""
    log "Installing $(basename "$wheel")"
    python3 -m pip install $user_flag --no-deps --force-reinstall "$wheel" </dev/null

    # --- Verify ---
    source "${PREFIX}/env.sh"
    trtexec --help 2>&1 | grep -m1 "TensorRT.v" || die "trtexec failed to run."
    python3 -c 'import tensorrt as trt; print("python tensorrt", trt.__version__)'

    # --- Shell setup instructions ---
    local login_shell rc env_file
    login_shell="$(basename "${SHELL:-bash}")"
    case "$login_shell" in
        fish) rc="~/.config/fish/config.fish"; env_file="${PREFIX}/env.fish" ;;
        zsh)  rc="~/.zshrc";                   env_file="${PREFIX}/env.sh" ;;
        *)    rc="~/.bashrc";                  env_file="${PREFIX}/env.sh" ;;
    esac

    cat <<EOF

Done: ${INSTALL_DIR}
Add to ${rc} (detected shell: ${login_shell}):
  source ${env_file}

Other shells:
  bash (~/.bashrc)                 : source ${PREFIX}/env.sh
  zsh  (~/.zshrc)                  : source ${PREFIX}/env.sh
  fish (~/.config/fish/config.fish): source ${PREFIX}/env.fish
EOF
}

main "$@"
