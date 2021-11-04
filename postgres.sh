#!/usr/bin/env bash

#
# Run a postgres in docker
#
# This scripts help runnig the postgres service
# without interfering with other postgres installation or running
# container. Use it to experiment with various version of postgres
#
# Usage
#
# - Start the service: `postgres.sh start`
# - Stop the service: `postgres.sh stop`
# - Run interactively: `postgres.sh it`
#
#
# Variables:
#
#   - PG_PREFIX: the prefix location of the postgres files (default: $HOME/.local)
#   - PG_VERSION: the postgres version you want to run (default 11)
#   - POSTGIS_VERSION: the postgis version you want to run (default 2.5)
#   - PG_IMAGE_TAG: the <postgres>-<postgis> version tag of the `postgis` image (default 11-2.5)
#   - PG_HOME: the location of the postgres files (default $PG_PREFIX/lib/postgresql/$PG_VERSION)
#   - PG_DATA: the location of the postgres data (default $PG_HOME/data)
#   - PG_RUN: the location of the unix socket for local connection (default $HOME/.local/run/postgresql) 
#
# Note: if you run several versions of postgis simultaneously 
# make sure that PG_RUN point to different locations.
#
#


PG_VERSION=${PG_VERSION:-"13"}
POSTGIS_VERSION=${POSTGIS_VERSION:-"3"}

PG_PREFIX=${PG_PREFIX:-"$HOME/.local"}

PG_IMAGE_TAG=${PG_IMAGE_TAG:-"$PG_VERSION-$POSTGIS_VERSION"}
PG_IMAGE=${PG_IMAGE:-"postgis:$PG_IMAGE_TAG"}
PG_HOME=${PG_HOME:-"$PG_PREFIX/lib/postgresql/$PG_VERSION"}
PG_DATA=${PG_DATA:-"$PG_HOME/data"}
PG_CONTAINER=${PG_CONTAINER:-"postgres"}
PG_PORT=${PG_PORT:-"127.0.0.1:5432"}
PG_RUN=$HOME/.local/run/postgresql

# Create posgresql data dir
mkdir -p $PG_DATA $PG_RUN

running=$(docker ps -a --filter "name=$PG_CONTAINER" --format "{{.Status}}")

function status_pg() {
    if [ -z "$running" ]; then
        echo "$PG_CONTAINER is not running"
    else
        echo $running
    fi
}

function start_pg() {
    if [ -z "$running" ]; then
      echo "Starting $PG_CONTAINER ..."
      echo "Unix socket: $PG_RUN"
      docker run --name=$PG_CONTAINER --hostname=postgres \
        -e POSTGRES_PASSWORD=$POSTGRES_PASSWORD_MD5 \
        -p $PG_PORT:5432 \
        -v $PG_DATA:/var/lib/postgresql/data \
        -v $PG_RUN:/var/run/postgresql \
        "${docker_args[@]}" $PG_IMAGE $@
      sleep 2
    else
      echo "$JUPYTER_CONTAINER already started"
    fi
}

function start_service() {
    docker_args=( --restart unless-stopped -d )
    start_pg "$@"
} 

function start_interactive() {
    docker_args=( -it --rm )
    start_pg "$@"
}

function stop_pg() {
    if [ ! -z "$running" ]; then
        echo "Stopping $PG_CONTAINER"
        docker stop $PG_CONTAINER
        docker rm $PG_CONTAINER
    else
      echo "$PG_CONTAINER not started"
    fi
}

case $1 in
  it)
    shift
    start_interactive "$@" 
    ;;
  start)
    shift;
    start_service "$@"
    ;;
  stop)
    stop_pg
    ;;
  status)
    status_pg
    ;;
  run)
    # Run command interactively in the container
    # as current user
    shift;
    docker run -it --rm -u $(id -u):$(id -u) --net host \
        -v $(pwd):/home/$USER -e HOME=/home/$USER -w /home/$USER \
        -v $PG_DATA:/var/lib/postgresql/data \
        -v $PG_PREFIX/lib/postgres:/var/lib/postgres \
        -v $PG_RUN:/var/run/postgresql \
        -v $HOME/.pgpass:/.pgpass:ro \
        -v $HOME/.pg_service.conf:/.pg_service.conf:ro \
        -e PGPASSFILE=/.pgpass \
        -e PGSERVICEFILE=/.pg_service.conf \
        $PG_IMAGE $@
    ;;
  *)
    start_service 
    ;;
esac



