#!/usr/bin/env bash
# scripts/do-build-init.sh
#
# DigitalOcean Droplet build environment initialization.
# Run once on a fresh Ubuntu 22.04 Droplet to install all dependencies,
# configure ccache, set up the build user, and generate an SSH key for GitHub.
#
# Usage:
#   curl -fL https://raw.githubusercontent.com/eoftisreal/Custom-re/main/scripts/do-build-init.sh | bash
#   # or, after cloning the repo:
#   bash scripts/do-build-init.sh
#
# Recommended Droplet: Ubuntu 22.04, 8 vCPU, 16GB RAM, 200GB SSD (s-8vcpu-16gb)

set -euo pipefail

# ─── Configuration ───────────────────────────────────────────────────────────
BUILD_USER="${BUILD_USER:-builder}"
WORKSPACE_ROOT="${WORKSPACE_ROOT:-/opt/coinos-build}"
CCACHE_DIR="${CCACHE_DIR:-${WORKSPACE_ROOT}/.ccache}"
CCACHE_SIZE="${CCACHE_SIZE:-100G}"
JAVA_VERSION="${JAVA_VERSION:-11}"
LOG_FILE="/tmp/do-build-init-$(date +%Y%m%d-%H%M%S).log"
# ─────────────────────────────────────────────────────────────────────────────

log()  { echo "[INFO]  $*" | tee -a "${LOG_FILE}"; }
warn() { echo "[WARN]  $*" | tee -a "${LOG_FILE}"; }
err()  { echo "[ERROR] $*" | tee -a "${LOG_FILE}" >&2; exit 1; }

require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    err "This script must be run as root (or with sudo)."
  fi
}

# ─── System update ───────────────────────────────────────────────────────────
update_system() {
  log "Updating system packages..."
  apt-get update -qq
  apt-get upgrade -y -qq
}

# ─── Build dependencies ──────────────────────────────────────────────────────
install_dependencies() {
  log "Installing build dependencies..."
  apt-get install -y --no-install-recommends \
    bc bison build-essential ccache curl flex g++-multilib gcc-multilib git \
    gnupg gperf imagemagick lib32ncurses5-dev lib32readline-dev lib32z1-dev \
    liblz4-tool libncurses5 libncurses5-dev libsdl1.2-dev libssl-dev libwxgtk3.0-gtk3-dev \
    libxml2 libxml2-utils lzop pngcrush rsync schedtool squashfs-tools xsltproc \
    zip zlib1g-dev python3 python-is-python3 "openjdk-${JAVA_VERSION}-jdk" \
    s3cmd xmllint jq wget unzip

  log "Build dependencies installed."
}

# ─── repo tool ───────────────────────────────────────────────────────────────
install_repo_tool() {
  if command -v repo >/dev/null 2>&1; then
    log "repo tool already installed: $(repo --version 2>&1 | head -1)"
    return
  fi
  log "Installing repo tool..."
  curl -fL --retry 5 https://storage.googleapis.com/git-repo-downloads/repo \
    -o /usr/local/bin/repo
  chmod a+x /usr/local/bin/repo
  log "repo installed: $(repo --version 2>&1 | head -1)"
}

# ─── Build user ──────────────────────────────────────────────────────────────
create_build_user() {
  if id "${BUILD_USER}" >/dev/null 2>&1; then
    log "Build user '${BUILD_USER}' already exists."
  else
    log "Creating build user '${BUILD_USER}'..."
    useradd -m -s /bin/bash -G sudo "${BUILD_USER}"
    # Allow passwordless sudo only for the specific commands required by build operations
    cat > "/etc/sudoers.d/${BUILD_USER}" << SUDOERS
${BUILD_USER} ALL=(ALL) NOPASSWD: /usr/bin/apt-get, /usr/bin/apt, /bin/mkdir, /bin/chown, /bin/chmod, /usr/bin/install, /bin/cp, /bin/mv
SUDOERS
    chmod 440 "/etc/sudoers.d/${BUILD_USER}"
  fi
}

# ─── Workspace directory ─────────────────────────────────────────────────────
setup_workspace() {
  log "Setting up workspace at ${WORKSPACE_ROOT}..."
  mkdir -p "${WORKSPACE_ROOT}/workspace"
  mkdir -p "${CCACHE_DIR}"
  chown -R "${BUILD_USER}:${BUILD_USER}" "${WORKSPACE_ROOT}"
}

# ─── ccache ──────────────────────────────────────────────────────────────────
configure_ccache() {
  log "Configuring ccache (size: ${CCACHE_SIZE}, dir: ${CCACHE_DIR})..."
  sudo -u "${BUILD_USER}" env CCACHE_DIR="${CCACHE_DIR}" ccache -M "${CCACHE_SIZE}"
  sudo -u "${BUILD_USER}" env CCACHE_DIR="${CCACHE_DIR}" \
    ccache --set-config=compression=true

  # Persist env vars for build user
  cat >> "/home/${BUILD_USER}/.bashrc" << EOF

# ccache — set by do-build-init.sh
export USE_CCACHE=1
export CCACHE_DIR=${CCACHE_DIR}
export CCACHE_COMPILERCHECK="%compiler% -dumpmachine; %compiler% -dumpversion"
export CCACHE_NOHASHDIR=true
export CCACHE_HARDLINK=true
EOF
  log "ccache configured."
}

# ─── Git configuration ───────────────────────────────────────────────────────
configure_git() {
  log "Configuring global Git settings for ${BUILD_USER}..."
  sudo -u "${BUILD_USER}" git config --global user.name  "DigitalOcean CI Build"
  sudo -u "${BUILD_USER}" git config --global user.email "action@github.com"
  sudo -u "${BUILD_USER}" git config --global color.ui   false
  sudo -u "${BUILD_USER}" git config --global core.compression 0
}

# ─── SSH key for GitHub ──────────────────────────────────────────────────────
generate_ssh_key() {
  SSH_DIR="/home/${BUILD_USER}/.ssh"
  KEY_FILE="${SSH_DIR}/id_ed25519_github"

  if [ -f "${KEY_FILE}" ]; then
    log "SSH key already exists at ${KEY_FILE}."
  else
    log "Generating SSH key for GitHub access..."
    mkdir -p "${SSH_DIR}"
    chown "${BUILD_USER}:${BUILD_USER}" "${SSH_DIR}"
    chmod 700 "${SSH_DIR}"
    sudo -u "${BUILD_USER}" ssh-keygen -t ed25519 -C "coinos-do-runner" \
      -f "${KEY_FILE}" -N ""
  fi

  echo ""
  echo "======================================================================"
  echo " Add the following public key to your GitHub account or organisation:"
  echo " Settings → SSH and GPG keys → New SSH key"
  echo "======================================================================"
  cat "${KEY_FILE}.pub"
  echo "======================================================================"
  echo ""
}

# ─── GitHub Actions runner hint ──────────────────────────────────────────────
print_runner_hint() {
  cat << 'HINT'
======================================================================
 Next step: register this Droplet as a GitHub Actions self-hosted runner
----------------------------------------------------------------------
 1. Go to your repository on GitHub
 2. Settings → Actions → Runners → New self-hosted runner
 3. Select Linux / x64 and follow the download + configure steps
 4. Run the runner as a service:
      sudo ./svc.sh install builder
      sudo ./svc.sh start
======================================================================
HINT
}

# ─── Summary ─────────────────────────────────────────────────────────────────
print_summary() {
  log "=== Initialization complete ==="
  log "  Build user    : ${BUILD_USER}"
  log "  Workspace     : ${WORKSPACE_ROOT}/workspace"
  log "  ccache dir    : ${CCACHE_DIR} (${CCACHE_SIZE})"
  log "  Java          : openjdk-${JAVA_VERSION}"
  log "  Log file      : ${LOG_FILE}"
  df -h "${WORKSPACE_ROOT}"
}

# ─── Main ────────────────────────────────────────────────────────────────────
main() {
  require_root
  log "Starting DigitalOcean build environment initialization..."
  log "Log: ${LOG_FILE}"

  update_system
  install_dependencies
  install_repo_tool
  create_build_user
  setup_workspace
  configure_ccache
  configure_git
  generate_ssh_key
  print_summary
  print_runner_hint
}

main "$@"
