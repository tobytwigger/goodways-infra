# Valhalla

Routing engine for Goodways. Tiles are built **locally** from an OSM extract,
then deployed either into the `goodways-api` repo (for local Sail) or to the
production server. The server only ever *serves* a pre-built tileset — it never
builds.

## Build

```bash
cp .env.example .env   # first time only, then edit
./build.sh
```

`build.sh` downloads the OSM PBF (cached in `custom_files/`), builds the tiles
in a Docker container, then copies the finished tileset to wherever
`DESTINATION` points. The build is capped at 4 threads / 12 GB in
[docker-compose.build.yml](docker-compose.build.yml) so it doesn't OOM on a
16 GB machine — close heavy apps before running it.

## Deploy

Deployment happens automatically at the end of `build.sh`, controlled by
`DESTINATION` in `.env`:

- **`DESTINATION=local`** — copies the tileset into `../../goodways-api/custom_files`
  (`LOCAL_DEST`). Then `cd ../../goodways-api && docker compose up -d valhalla`.
- **`DESTINATION=production`** — `scp`s the tileset to the remote server and
  restarts the `valhalla` container.

Only the artifacts the server loads are copied (config, tiles tar, admin /
timezone / speeds DBs, elevation). The source `.osm.pbf` and the unpacked
`valhalla_tiles/` build dir are skipped.

## `.env`

See [.env.example](.env.example). Copy it to `.env` (gitignored) and set:

| Variable | Purpose |
|---|---|
| `DESTINATION` | `local` (copy to goodways-api) or `production` (scp to server). |
| `LOCAL_DEST` | Local copy target. Default `../../goodways-api/custom_files`. |
| `VALHALLA_REMOTE_USER` / `VALHALLA_REMOTE_HOST` | SSH login for `production`. |
| `VALHALLA_REMOTE_PATH` | Absolute path to `custom_files` on the server. |
| `VALHALLA_TILE_URLS` | OSM extract to build from (e.g. Geofabrik great-britain). |
