#!/usr/bin/env bash

# Run from the script's own directory so every relative path (custom_files,
# .env, the local copy destination) resolves the same no matter where build.sh
# is invoked from.
cd "$(dirname "$(readlink -f "$0")")"

# Load deployment settings (remote user/host/path). See .env.example.
if [ -f .env ]; then
  set -a
  source .env
  set +a
fi

set -euo pipefail

PBF_URL="${VALHALLA_TILE_URLS}"
PBF_FILE="custom_files/$(basename "$PBF_URL")"
TAR_FILE="custom_files/valhalla_tiles.tar"
HASHES_FILE="custom_files/.file_hashes.txt"
MIN_PBF_BYTES=1000000000  # ~1GB floor; the real GB extract is ~2GB, an error page is a few hundred bytes.

# Where the finished tileset goes. Set DESTINATION in .env:
#   local      -> copy into the goodways-api repo's custom_files (for Sail)
#   PRODUCTION -> scp to the remote server and restart Valhalla
DESTINATION="${DESTINATION:-local}"
LOCAL_DEST="${LOCAL_DEST:-../../goodways-api/custom_files}"

# The artifacts the Valhalla server actually loads: everything in custom_files
# EXCEPT the source .osm.pbf (use_tiles_ignore_pbf ignores it) and the unpacked
# valhalla_tiles/ build dir (serving uses valhalla_tiles.tar). Shipping only the
# .tar makes the image think the rest is missing and try to rebuild/enhance on
# boot, which core-dumps. Drop elevation_data if you don't use the /height
# endpoint or elevation costing at runtime (saves ~2GB).
ARTIFACTS=(
  custom_files/valhalla.json
  custom_files/valhalla_tiles.tar
  custom_files/admins.sqlite
  custom_files/timezones.sqlite
  custom_files/default_speeds.json
  custom_files/elevation_data
  custom_files/.file_hashes.txt
)

mkdir -p custom_files

echo "==> Downloading PBF..."
if [ -f "$PBF_FILE" ] && [ "$(stat -c%s "$PBF_FILE")" -ge "$MIN_PBF_BYTES" ]; then
  echo "    Already present; skipping (delete $PBF_FILE to refresh)."
else
  # Download to .part, confirm it's really the PBF (not an error/redirect page), then promote.
  curl -L --fail -o "$PBF_FILE.part" "$PBF_URL"
  if [ "$(stat -c%s "$PBF_FILE.part")" -lt "$MIN_PBF_BYTES" ]; then
    echo "ERROR: download too small -- got an error page, not the PBF." >&2
    rm -f "$PBF_FILE.part"
    exit 1
  fi
  mv -f "$PBF_FILE.part" "$PBF_FILE"
fi

echo "==> Building tiles..."
# --exit-code-from surfaces a failed build as a non-zero exit, so set -e stops us here
# instead of hashing a tar that was never produced.
docker compose -f docker-compose.build.yml up --build --exit-code-from valhalla
docker compose -f docker-compose.build.yml down

echo "==> Hashing tiles..."
md5sum "$TAR_FILE" > "$HASHES_FILE"

# Deploy the built tileset to wherever DESTINATION points.
case "$DESTINATION" in
  local)
    echo "==> Copying tileset to ${LOCAL_DEST} ..."
    mkdir -p "$LOCAL_DEST"
    cp -rv "${ARTIFACTS[@]}" "$LOCAL_DEST/"
    echo "==> Done. Bring Valhalla up in goodways-api to load the new tiles."
    ;;
  PRODUCTION)
    if [ -z "${VALHALLA_REMOTE_HOST:-}" ]; then
      echo "ERROR: DESTINATION=PRODUCTION but VALHALLA_REMOTE_HOST is empty in .env." >&2
      exit 1
    fi
    echo "==> Uploading tileset to ${VALHALLA_REMOTE_HOST} ..."
    scp -r "${ARTIFACTS[@]}" \
      "${VALHALLA_REMOTE_USER}@${VALHALLA_REMOTE_HOST}:${VALHALLA_REMOTE_PATH}/"
    echo "==> Done. Valhalla will load the new tiles on restart."
    ;;
  *)
    echo "ERROR: set DESTINATION=local or DESTINATION=PRODUCTION in .env (got '$DESTINATION')." >&2
    exit 1
    ;;
esac
