## Transferring data from production to local

### Create an sql dump

```
_goodways_wordpress_database_container
mysqldump -u root -p wordpress > /tmp/backup.sql
```

Enter password


### Transfer from docker to server

```
ssh _goodways_wordpress_server
docker container ls
docker cp mysql-m10g4kwa7ic9bljll3t0zx0z:/tmp/backup.sql ./backup.sql
```


### Transfer from server to local
```
scp _goodways_wordpress_server:backup.sql /home/toby/goodways/repos/infrastructure/wordpress/backup.sql
```

### Transfer from local to local docker container

```
docker cp backup.sql wordpress-mysql:/tmp/backup.sql

docker exec -it $(docker ps --filter 'name=wordpress-mysql' --format '{{.Names}}' | head -1) bash

```

### Import
```
cd /tmp
mysql -u root -p wordpress < /tmp/backup.sql
```






### Install the wp cli 
```
docker exec -it $(docker ps --filter 'name=wordpress-goodways' --format '{{.Names}}' | head -1) bash

curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
php wp-cli.phar --info
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp
```


### Migrate site URLs and config

```
docker exec -it $(docker ps --filter 'name=wordpress-goodways' --format '{{.Names}}' | head -1) \
  wp option update siteurl 'http://goodways.local:8081' --allow-root

docker exec -it $(docker ps --filter 'name=wordpress-goodways' --format '{{.Names}}' | head -1) \
  wp option update home 'http://goodways.local:8081' --allow-root

docker exec -it $(docker ps --filter 'name=wordpress-goodways' --format '{{.Names}}' | head -1) \
  wp search-replace 'https://goodways.org' 'http://goodways.local:8081' --allow-root
  
  ```



### Open the site

http://goodways.local:8081/