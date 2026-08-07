https://www.postgresql.org/download/linux/ubuntu/



# Upgrading

- Take a full Hetzner backup, just in case

- SSH into the api server where the DB is, and take an export:
```
docker exec <your-pg17-container> pg_dumpall -U postgres > ~/postgres17_backup.sql
```

- Copy this to the server, out of docker
```
docker cp backup.sql <conttainer>:/tmp/backup.sql
```


Stop the application container to prevent DB writes.
Create a full DB dump.
Stop the PostgreSQL container.
Rename (backup) the old DB data directory and create a new empty one in its place.
Increment the PostgreSQL version number in your Docker compose file and pull the new image.
Start the updated PostgreSQL container.
Import the DB dump.
Start the application container.
Clean up.