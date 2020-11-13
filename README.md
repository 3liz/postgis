# Postgis Docker image


## Description

This is an image adapted from the [official docker postgres image](https://github.com/docker-library/docs/blob/master/postgres) that include the postgis extension.

## Usage


See the [docker postgres documentation](https://github.com/docker-library/docs/blob/master/postgres/README.md). 

This image is fully adapted from the original docker image with respect to configuration variables

The images may be run as simply as

```
docker run postgis:12-2.5 -p 127.0.0.1:5432:5432
```

The directory /var/lib/postgresql/data is mounted as persistent volume.


### Using local environment 

Example:

```
docker run --name=$PG_CONTAINER --hostname=postgres \
    -e POSTGRES_PASSWORD=<md5password> \
    -p 127.0.0.1:5432:5432 \
    -v /custom/mount:/var/lib/postgresql/data \
    -v /custom/run:/var/run/postgresql \
    postgis:12-2.5
```

From the command above, you may connect to your server using your psql
local command:

```
psql -h /custom/run/
```

This may be convenient if you want to run multiple postgres instances with different versions.

### User

By default, the image will execute the entry point as root; then, after creating postgres directories if necessary,
will switch to the `postgres` user as determined at build time from build arguments `POSTGRES_UID`

The postgres uid:gid is internally set to `999:999`: if started as root, ownership of `$PGDATA` directory is checked against 
the default values and the *uid* and *gid* of the *postgres* user will be changed accordingy. 

### Using the `--user` option

The container support `--user` option, this is effective with mounted volumes from the host. Do not forget
to precreate the directories before running the container.


