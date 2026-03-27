#! /bin/bash
set -euo pipefail

INSTALL_MODE="${DOTFILES_INSTALL_MODE:-auto}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --container)
      INSTALL_MODE="container"
      shift
      ;;
    --mode)
      INSTALL_MODE="${2:-}"
      shift 2
      ;;
    --mode=*)
      INSTALL_MODE="${1#*=}"
      shift
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

case "$INSTALL_MODE" in
  auto|host|container) ;;
  *)
    echo "Unsupported install mode: $INSTALL_MODE" >&2
    exit 1
    ;;
esac

APPS="${HOME}/localapps"
APP_BIN="${APPS}/bin"
APP_ROOT="${APPS}/apps"
REPODIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_HOME="${HOME}/dotfiles"
OS_NAME="$(uname -s)"
ARCH_NAME="$(uname -m)"

echo "$REPODIR"

if [[ "$REPODIR" != "$DOTFILES_HOME" ]]; then
  ln -sfn "$REPODIR" "$DOTFILES_HOME"
fi

mkdir -p "$APP_ROOT" "$APP_BIN" "${HOME}/.ssh"
ln -sf "$REPODIR"/nbin/* "$APP_BIN"

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

curl_fetch() {
  curl --fail --silent --show-error --location --retry 3 "$@"
}

ensure_dir() {
  mkdir -p "$1"
}

require_supported_platform() {
  if [[ "$OS_NAME" != "Linux" ]]; then
    echo "Unsupported OS for binary install flow: $OS_NAME" >&2
    exit 1
  fi

  case "$ARCH_NAME" in
    x86_64|amd64)
      ;;
    *)
      echo "Unsupported architecture for binary install flow: $ARCH_NAME" >&2
      exit 1
      ;;
  esac
}

download_extract_tarball() {
  local url="$1"
  local dest_dir="$2"
  shift 2

  rm -rf "$dest_dir"
  ensure_dir "$dest_dir"
  curl_fetch "$url" | tar -xz -C "$dest_dir" "$@"
}

github_latest_tag() {
  local repo="$1"

  curl_fetch "https://api.github.com/repos/${repo}/releases/latest" \
    | sed -n 's/.*"tag_name":[[:space:]]*"\([^"]*\)".*/\1/p' \
    | head -n 1
}

install_symlink() {
  local target="$1"
  local link_path="$2"
  ln -sfn "$target" "$link_path"
}

install_cargo_binstall() {
  local package="$1"
  cargo-binstall -y "$package"
}

install_fzf() {
  local version url dest_dir
  version="$(github_latest_tag "junegunn/fzf")"
  [[ -n "$version" ]]
  dest_dir="${APP_ROOT}/fzf"
  url="https://github.com/junegunn/fzf/releases/download/${version}/fzf-${version#v}-linux_amd64.tar.gz"

  download_extract_tarball "$url" "$dest_dir"
  install_symlink "${dest_dir}/fzf" "${APP_BIN}/fzf"
}

install_lazygit() {
  local version url dest_dir
  version="$(github_latest_tag "jesseduffield/lazygit")"
  [[ -n "$version" ]]
  dest_dir="${APP_ROOT}/lazygit"
  url="https://github.com/jesseduffield/lazygit/releases/download/${version}/lazygit_${version#v}_Linux_x86_64.tar.gz"

  download_extract_tarball "$url" "$dest_dir"
  install_symlink "${dest_dir}/lazygit" "${APP_BIN}/lazygit"
}

install_neovim() {
  local version url dest_dir
  version="$(github_latest_tag "neovim/neovim")"
  [[ -n "$version" ]]
  dest_dir="${APP_ROOT}/nvim"
  url="https://github.com/neovim/neovim/releases/download/${version}/nvim-linux-x86_64.tar.gz"

  download_extract_tarball "$url" "$dest_dir" --strip-components=1
  install_symlink "${dest_dir}/bin/nvim" "${APP_BIN}/nvim"
}

install_zellij() {
  local version url dest_dir
  version="$(github_latest_tag "zellij-org/zellij")"
  [[ -n "$version" ]]
  dest_dir="${APP_ROOT}/zellij"
  url="https://github.com/zellij-org/zellij/releases/download/${version}/zellij-x86_64-unknown-linux-musl.tar.gz"

  download_extract_tarball "$url" "$dest_dir"
  install_symlink "${dest_dir}/zellij" "${APP_BIN}/zellij"
}

install_tpm() {
  local tpm_dir="${HOME}/.tmux/plugins/tpm"
  if [[ -d "$tpm_dir/.git" ]]; then
    git -C "$tpm_dir" pull --ff-only
  else
    git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
  fi
}

install_uv() {
  curl_fetch https://astral.sh/uv/install.sh | sh
}

install_shelltools() {
  echo "On random unix x86 system installing shelltools"
  require_supported_platform

  if ! have_cmd cargo-binstall; then
    curl_fetch --proto '=https' --tlsv1.2 \
      https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh \
      | bash
  fi
  export PATH="${HOME}/.cargo/bin:${PATH}"

  install_cargo_binstall bat
  install_cargo_binstall eza
  install_cargo_binstall ripgrep
  install_cargo_binstall starship
  install_cargo_binstall yazi-fm
  install_cargo_binstall zoxide

  install_fzf
  install_lazygit
  install_neovim
  install_zellij
  install_uv
}

should_install_shelltools() {
  case "$INSTALL_MODE" in
    container)
      return 1
      ;;
    host)
      return 0
      ;;
  esac

  ! command -v nix &>/dev/null || ! nix --version &>/dev/null
}

if should_install_shelltools; then
  install_shelltools
else
  echo "Skipping shelltools install for mode: $INSTALL_MODE"
fi

install_tpm

"${REPODIR}/linkconf.sh"
