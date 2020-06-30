# Postgis Docker image


## Description

This is an image adapted from the [official docker postgres image](https://github.com/docker-library/docs/blob/master/postgres) that include the postgis extension.


## Usage 

See the [docker postgres documentation](https://github.com/docker-library/docs/blob/master/postgres/README.md). 

This image is fully adapted from the original docker image with respect to configuration variables

Example:

```
docker run --name=$PG_CONTAINER --hostname=postgres \
    -e POSTGRES_PASSWORD=<md5password> \
    -p 127.0.0.1:5432:5432 \
    -v /custom/mount:/var/lib/postgresql/data \
    -v /custom/run:/var/run/postgresql \
    postgis:11
```

From the command above, you may connect to your server using your psql
local command:

```
psql -h /custom/run/
```

The image will execute the entry point as root; then, after creating postgres directories if necessary,
will switch to the `postgres` user as determined at build time from build arguments `POSTGRES_UID`

By default the the postgres uid:gid is set to 999:999.


