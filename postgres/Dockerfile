FROM postgis/postgis:17-3.5

RUN apt-get update && apt-get install -y postgresql-17-h3 && rm -rf /var/lib/apt/lists/*

# Online reindex on every startup to repair glibc collation drift (corrupted
# text btree indexes after a base-image rebuild). Runs CONCURRENTLY in the
# background once Postgres is ready, so it blocks neither the deploy nor live
# queries. See reindex.sh / reindex-entrypoint.sh. Temporary — drops away when
# Postgres moves off Docker.
COPY reindex.sh /usr/local/bin/reindex.sh
COPY reindex-entrypoint.sh /usr/local/bin/reindex-entrypoint.sh
RUN chmod +x /usr/local/bin/reindex.sh /usr/local/bin/reindex-entrypoint.sh

# Wrap the stock entrypoint. CMD is inherited from the base image (["postgres"]).
ENTRYPOINT ["reindex-entrypoint.sh"]
CMD ["postgres"]
