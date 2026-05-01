#!/usr/bin/env bash
# scripts/cleanup-old-builds.sh
#
# Removes CoinOS build artifacts older than a configurable threshold,
# optionally archiving them to DigitalOcean Spaces first.
#
# Usage:
#   # Interactive (defaults):
#   bash scripts/cleanup-old-builds.sh
#
#   # Custom retention and Spaces upload:
#   DO_SPACES_BUCKET=my-bucket DO_SPACES_REGION=nyc3 \
#   DO_SPACES_KEY=<key> DO_SPACES_SECRET=<secret> \
#   MAX_AGE_DAYS=14 KEEP_LATEST=5 \
#   bash scripts/cleanup-old-builds.sh
#
# Environment variables:
#   BUILD_OUT_DIR     — directory containing build output (default: /opt/coinos-build/workspace/out/target/product/j7xelte)
#   MAX_AGE_DAYS      — delete files older than this many days (default: 30)
#   KEEP_LATEST       — always keep at least this many most-recent ZIP files (default: 3)
#   DRY_RUN           — if set to "true", only print what would be deleted (default: false)
#   DO_SPACES_KEY     — DigitalOcean Spaces access key (optional, for archiving before delete)
#   DO_SPACES_SECRET  — DigitalOcean Spaces secret key
#   DO_SPACES_BUCKET  — Spaces bucket name (default: coinos-builds)
#   DO_SPACES_REGION  — Spaces region (default: nyc3)

set -euo pipefail

# ─── Configuration ───────────────────────────────────────────────────────────
BUILD_OUT_DIR="${BUILD_OUT_DIR:-/opt/coinos-build/workspace/out/target/product/j7xelte}"
LOG_DIR="${BUILD_LOG_DIR:-/opt/coinos-build/workspace/out}"
MAX_AGE_DAYS="${MAX_AGE_DAYS:-30}"
KEEP_LATEST="${KEEP_LATEST:-3}"
DRY_RUN="${DRY_RUN:-false}"
DO_SPACES_KEY="${DO_SPACES_KEY:-}"
DO_SPACES_SECRET="${DO_SPACES_SECRET:-}"
DO_SPACES_BUCKET="${DO_SPACES_BUCKET:-coinos-builds}"
DO_SPACES_REGION="${DO_SPACES_REGION:-nyc3}"
S3CFG="${HOME}/.s3cfg_cleanup_$$"
# ─────────────────────────────────────────────────────────────────────────────

# Ensure the credentials file is removed on exit regardless of how the script ends
trap 'rm -f "${S3CFG}"' EXIT

log()  { echo "[$(date -u +"%Y-%m-%d %H:%M:%S")] [INFO]  $*"; }
warn() { echo "[$(date -u +"%Y-%m-%d %H:%M:%S")] [WARN]  $*" >&2; }

# ─── Helpers ─────────────────────────────────────────────────────────────────
bytes_to_human() {
  local b="$1"
  if   [ "${b}" -ge $((1024**3)) ]; then printf "%.1f GB" "$(echo "scale=1; ${b}/1073741824" | bc)"
  elif [ "${b}" -ge $((1024**2)) ]; then printf "%.1f MB" "$(echo "scale=1; ${b}/1048576"    | bc)"
  elif [ "${b}" -ge 1024 ];         then printf "%.1f KB" "$(echo "scale=1; ${b}/1024"        | bc)"
  else printf "%d B" "${b}"; fi
}

total_size_bytes() {
  # Sum byte counts of all given files; returns 0 if none
  local total=0
  for f in "$@"; do
    [ -f "${f}" ] || continue
    total=$((total + $(stat -c%s "${f}")))
  done
  echo "${total}"
}

# ─── Spaces archive ──────────────────────────────────────────────────────────
setup_s3cmd() {
  if [ -z "${DO_SPACES_KEY}" ] || [ -z "${DO_SPACES_SECRET}" ]; then
    return 1   # caller should check
  fi
  cat > "${S3CFG}" << EOF
[default]
access_key = ${DO_SPACES_KEY}
secret_key = ${DO_SPACES_SECRET}
host_base = ${DO_SPACES_REGION}.digitaloceanspaces.com
host_bucket = %(bucket)s.${DO_SPACES_REGION}.digitaloceanspaces.com
use_https = True
EOF
  chmod 600 "${S3CFG}"
  return 0
}

cleanup_s3cfg() {
  rm -f "${S3CFG}"
}

archive_to_spaces() {
  # Returns 0 on success (or when credentials are absent), 1 on upload failure.
  local file="$1"
  local dest="s3://${DO_SPACES_BUCKET}/coinos-archive/$(basename "${file}")"
  if setup_s3cmd; then
    log "  Archiving to Spaces: ${dest}"
    if [ "${DRY_RUN}" != "true" ]; then
      if ! s3cmd --config="${S3CFG}" put "${file}" "${dest}"; then
        warn "  Archive failed for ${file}; skipping local deletion to prevent data loss."
        return 1
      fi
    else
      log "  [DRY RUN] Would upload ${file} → ${dest}"
    fi
  else
    warn "  Spaces credentials not set — skipping archive for $(basename "${file}")"
  fi
  return 0
}

# ─── Main cleanup logic ──────────────────────────────────────────────────────
cleanup_zips() {
  log "=== CoinOS ROM ZIP cleanup ==="
  log "  Directory : ${BUILD_OUT_DIR}"
  log "  Max age   : ${MAX_AGE_DAYS} days"
  log "  Keep      : latest ${KEEP_LATEST} files"
  log "  Dry run   : ${DRY_RUN}"

  if [ ! -d "${BUILD_OUT_DIR}" ]; then
    warn "Build output directory not found: ${BUILD_OUT_DIR}"
    return
  fi

  # Collect all ROM ZIPs sorted newest-first
  mapfile -t ALL_ZIPS < <(
    find "${BUILD_OUT_DIR}" -maxdepth 1 -name "CoinOS*.zip" \
      -printf "%T@ %p\n" | sort -rn | awk '{print $2}'
  )
  local total=${#ALL_ZIPS[@]}
  log "  Found ${total} ROM ZIP(s)"

  if [ "${total}" -eq 0 ]; then
    log "  Nothing to clean up."
    return
  fi

  local deleted=0
  local deleted_bytes=0
  local idx=0

  for f in "${ALL_ZIPS[@]}"; do
    idx=$((idx + 1))

    # Always keep the most recent KEEP_LATEST builds
    if [ "${idx}" -le "${KEEP_LATEST}" ]; then
      log "  KEEP (latest ${idx}/${KEEP_LATEST}): $(basename "${f}")"
      continue
    fi

    # Check file age
    FILE_AGE_DAYS=$(( ( $(date +%s) - $(stat -c%Y "${f}") ) / 86400 ))
    if [ "${FILE_AGE_DAYS}" -lt "${MAX_AGE_DAYS}" ]; then
      log "  KEEP (${FILE_AGE_DAYS}d old, threshold ${MAX_AGE_DAYS}d): $(basename "${f}")"
      continue
    fi

    FSIZE=$(stat -c%s "${f}")
    log "  DELETE (${FILE_AGE_DAYS}d old, $(bytes_to_human "${FSIZE}")): $(basename "${f}")"
    if ! archive_to_spaces "${f}"; then
      # Archive failed — skip deletion to avoid data loss
      continue
    fi

    if [ "${DRY_RUN}" != "true" ]; then
      rm -f "${f}"
    fi

    deleted=$((deleted + 1))
    deleted_bytes=$((deleted_bytes + FSIZE))
  done

  log "  Deleted ${deleted} file(s), freed $(bytes_to_human "${deleted_bytes}")"
}

cleanup_logs() {
  log "=== Build log cleanup ==="
  log "  Directory : ${LOG_DIR}"
  log "  Max age   : ${MAX_AGE_DAYS} days"

  if [ ! -d "${LOG_DIR}" ]; then
    warn "Log directory not found: ${LOG_DIR}"
    return
  fi

  local deleted=0
  local deleted_bytes=0

  while IFS= read -r -d '' f; do
    FILE_AGE_DAYS=$(( ( $(date +%s) - $(stat -c%Y "${f}") ) / 86400 ))
    if [ "${FILE_AGE_DAYS}" -ge "${MAX_AGE_DAYS}" ]; then
      FSIZE=$(stat -c%s "${f}")
      log "  DELETE log (${FILE_AGE_DAYS}d old): $(basename "${f}")"
      if [ "${DRY_RUN}" != "true" ]; then
        rm -f "${f}"
      fi
      deleted=$((deleted + 1))
      deleted_bytes=$((deleted_bytes + FSIZE))
    fi
  done < <(find "${LOG_DIR}" -maxdepth 1 \( -name "build_*.log" -o -name "verbose.log.gz" \) \
    -printf "%p\0")

  log "  Deleted ${deleted} log file(s), freed $(bytes_to_human "${deleted_bytes}")"
}

print_disk_report() {
  log "=== Disk space report ==="
  df -h /opt/coinos-build 2>/dev/null || df -h /
}

# ─── Entry point ─────────────────────────────────────────────────────────────
main() {
  log "Starting cleanup (DRY_RUN=${DRY_RUN})"
  print_disk_report
  cleanup_zips
  cleanup_logs
  # cleanup_s3cfg is handled by the EXIT trap defined at the top of the script
  print_disk_report
  log "Cleanup complete."
}

# Allow sourcing without executing for unit-testing individual functions
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
