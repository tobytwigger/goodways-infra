FROM ghcr.io/valhalla/valhalla-scripted:latest
# The scripted image handles the full lifecycle:
#   1. Downloads OSM PBF files listed in tile_urls (space-separated URLs)
#   2. Builds Valhalla routing tiles from them (skipped if tiles already exist)
#   3. Starts the Valhalla HTTP server on port 8002
#
# No entrypoint or CMD override needed — configure via environment variables
# in docker-compose or Coolify (tile_urls, min_x, etc.).
# See: https://github.com/valhalla/valhalla/tree/master?tab=readme-ov-file#with-docker
