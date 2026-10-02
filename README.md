# install-tensorrt

A script that installs TensorRT 10.8.0 under `$HOME` without root privileges.

## Requirements

- x86_64 / Ubuntu 22.04
- CUDA 12.8 (`/usr/local/cuda-12.8`)
- System python3 (3.10)
- Shell: bash / zsh / fish

## Install

```sh
curl -fsSL https://yhisaki.github.io/install-tensorrt/install_tensorrt.sh | bash
```

This works from bash, zsh, and fish. To change the install location, set `PREFIX` (default: `~/.local/opt/tensorrt`):

```sh
curl -fsSL https://yhisaki.github.io/install-tensorrt/install_tensorrt.sh | PREFIX=/path/to/dir bash
```

You can also clone this repository and run `./install_tensorrt.sh` directly.

The script does the following:

1. Downloads the TensorRT tarball (resumable; reused if already downloaded)
2. Extracts it to `$PREFIX/TensorRT-10.8.0.43` and creates the symlink `$PREFIX/current`
3. Generates environment files `env.sh` (bash/zsh) and `env.fish`
4. Installs the Python wheel (into the active venv/conda environment if any, otherwise with `--user`)
5. Verifies the install with `trtexec` and `import tensorrt`

## Shell setup

After installation, add the following line to your shell's rc file:

| Shell | rc file | Line to add |
|---|---|---|
| bash | `~/.bashrc` | `source ~/.local/opt/tensorrt/env.sh` |
| zsh  | `~/.zshrc` | `source ~/.local/opt/tensorrt/env.sh` |
| fish | `~/.config/fish/config.fish` | `source ~/.local/opt/tensorrt/env.fish` |

This sets `TENSORRT_ROOT`, `TensorRT_ROOT`, `CUDA_HOME`, `LD_LIBRARY_PATH`, `CPATH`, `CMAKE_LIBRARY_PATH`, and `PATH`.

## Uninstall

```sh
rm -rf ~/.local/opt/tensorrt
python3 -m pip uninstall tensorrt
```

Also remove the `source` line from your rc file.
