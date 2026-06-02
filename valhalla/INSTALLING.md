```
docker build -t valhalla . && docker run \
  --name valhalla \
  --restart unless-stopped \
  -p 127.0.0.1:8002:8002 \
  -v valhalla_data:/custom_files \
  -e tile_urls=https://download.geofabrik.de/europe/great-britain-latest.osm.pbf \
  --label app.name=valhalla \
  valhalla
  ```

```
docker container stop valhalla && docker rm -f valhalla && docker volume rm valhalla_data
```

