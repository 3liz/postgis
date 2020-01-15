#!/usr/bin/env bash
set -e

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
    local var="$1"
    local fileVar="${var}_FILE"
    local def="${2:-}"
    if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
        echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
        exit 1
    fi
    local val="$def"
    if [ "${!var:-}" ]; then
        val="${!var}"
    elif [ "${!fileVar:-}" ]; then
        val="$(< "${!fileVar}")"
    fi
    export "$var"="$val"
    unset "$fileVar"
}

docker_create_db_directories() {

    local user; user="$(id -u)"

    mkdir -p "$PGDATA"
    chmod 700 "$PGDATA"

    mkdir -p /var/run/postgresql || :
    chmod 775 /var/run/postgresql || :

    # Create the transaction log directory before initdb is run so the directory is owned by the correct user
    if [ "$POSTGRES_INITDB_WALDIR" ]; then
        mkdir -p "$POSTGRES_INITDB_WALDIR"
        if [ "$user" = '0' ]; then
            find "$POSTGRES_INITDB_WALDIR" \! -user postgres -exec chown postgres '{}' +
        fi
        chmod 700 "$POSTGRES_INITDB_WALDIR"
    fi

    # allow the container to be started with `--user`
    if [ "$user" = '0' ]; then
        find "$PGDATA" \! -user postgres -exec chown postgres '{}' +
        find /var/run/postgresql \! -user postgres -exec chown postgres '{}' +
    fi
}


# initialize empty PGDATA directory with new database via 'initdb'
# arguments to `initdb` can be passed via POSTGRES_INITDB_ARGS or as arguments to this function
# `initdb` automatically creates the "postgres", "template0", and "template1" dbnames
# this is also where the database user is created, specified by `POSTGRES_USER` env
docker_init_database_dir() {

    if [ "$POSTGRES_INITDB_WALDIR" ]; then
        set -- --waldir "$POSTGRES_INITDB_WALDIR" "$@"
    fi

    eval 'initdb --username="$POSTGRES_USER" --pwfile=<(echo "$POSTGRES_PASSWORD") '"$POSTGRES_INITDB_ARGS"' "$@"'
}


# print large warning if POSTGRES_PASSWORD is empty
docker_verify_minimum_env() {

    if [ -z "$POSTGRES_PASSWORD" ]; then
        # The - option suppresses leading tabs but *not* spaces. :)
        cat >&2 <<-'EOWARN'
			****************************************************
			WARNING: No password has been set for the database.
			         This will allow anyone with access to the
			         Postgres port to access your database. In
			         Docker's default configuration, this is
			         effectively any other container on the same
			         system.
			         Use "-e POSTGRES_PASSWORD=password" to set
			         it in "docker run".
			****************************************************
		EOWARN
    fi

}

# usage: docker_process_init_files [file [file [...]]]
#    ie: docker_process_init_files /always-initdb.d/*
# process initializer files, based on file extensions and permissions
docker_process_init_files() {

    echo
    local f
    for f; do
        case "$f" in
            *.sh)
                if [ -x "$f" ]; then
                    echo "$0: running $f"
                    "$f"
                else
                    echo "$0: sourcing $f"
                    . "$f"
                fi
                ;;
            *.sql)    echo "$0: running $f"; docker_process_sql -f "$f"; echo ;;
            *.sql.gz) echo "$0: running $f"; gunzip -c "$f" | docker_process_sql; echo ;;
            *)        echo "$0: ignoring $f" ;;
        esac
        echo
    done
}

# Execute sql script, passed via stdin (or -f flag of pqsl)
# usage: docker_process_sql [psql-cli-args]
#    ie: docker_process_sql --dbname=mydb <<<'INSERT ...'
#    ie: docker_process_sql -f my-file.sql
#    ie: docker_process_sql <my-file.sql
docker_process_sql() {
    local query_runner=( psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --no-password )
    if [ -n "$POSTGRES_DB" ]; then
        query_runner+=( --dbname "$POSTGRES_DB" )
    fi

    "${query_runner[@]}" "$@"
}

# create initial database
# uses environment variables for input: POSTGRES_DB
docker_setup_db() {
    if [ "$POSTGRES_DB" != 'postgres' ]; then
        POSTGRES_DB= docker_process_sql --dbname postgres --set db="$POSTGRES_DB" <<-'EOSQL'
			CREATE DATABASE :"db" ;
		EOSQL
        echo
    fi
}


# Loads various settings that are used elsewhere in the script
# This should be called before any other functions
docker_setup_env() {
    file_env 'POSTGRES_PASSWORD'

    file_env 'POSTGRES_USER' 'postgres'
    file_env 'POSTGRES_DB' "$POSTGRES_USER"
    file_env 'POSTGRES_INITDB_ARGS'

    declare -g DATABASE_ALREADY_EXISTS
    # look specifically for PG_VERSION, as it is expected in the DB dir
    if [ -s "$PGDATA/PG_VERSION" ]; then
        DATABASE_ALREADY_EXISTS='true'
    fi
}


# append md5 or trust auth to pg_hba.conf based on existence of POSTGRES_PASSWORD
pg_setup_hba_conf() {
    local authMethod='md5'
    if [ -z "$POSTGRES_PASSWORD" ]; then
        authMethod='trust'
    fi

    {
        echo
        echo "host all all all $authMethod"
    } >> "$PGDATA/pg_hba.conf"
}


# start socket-only postgresql server for setting up or running scripts
# all arguments will be passed along as arguments to `postgres` (via pg_ctl)
docker_temp_server_start() {
    if [ "$1" = 'postgres' ]; then
        shift
    fi

    # internal start of server in order to allow setup using psql client
    # does not listen on external TCP/IP and waits until start finishes
    set -- "$@" -c listen_addresses='' -p "${PGPORT:-5432}"

    PGUSER="${PGUSER:-$POSTGRES_USER}" \
    pg_ctl -D "$PGDATA" \
        -o "$(printf '%q ' "$@")" \
        -w start
}


# stop postgresql server after done setting up user and running scripts
docker_temp_server_stop() {
    PGUSER="${PGUSER:-postgres}" \
    pg_ctl -D "$PGDATA" -m fast -w stop
}


# check arguments for an option that would cause postgres to stop
# return true if there is one
_pg_want_help() {
    local arg
    for arg; do
        case "$arg" in
            # postgres --help | grep 'then exit'
            # leaving out -C on purpose since it always fails and is unhelpful:
            # postgres: could not access the server configuration file "/var/lib/postgresql/data/postgresql.conf": No such file or directory
            -'?'|--help|--describe-config|-V|--version)
                return 0
                ;;
        esac
    done
    return 1
}


_main() {
    # if first arg looks like a flag, assume we want to run postgres server
    if [ "${1:0:1}" = '-' ]; then
        set -- postgres "$@"
    fi

    if [ "$1" = 'postgres' ] && ! _pg_want_help "$@"; then
        docker_setup_env
        # setup data directories and permissions (when run as root)
        docker_create_db_directories
        if [ "$(id -u)" = '0' ]; then
            # then restart script as postgres user
            exec gosu postgres "$BASH_SOURCE" "$@"
        fi

        # only run initialization on an empty data directory
        if [ -z "$DATABASE_ALREADY_EXISTS" ]; then
            docker_verify_minimum_env
            docker_init_database_dir
            pg_setup_hba_conf

            # PGPASSWORD is required for psql when authentication is required for 'local' connections via pg_hba.conf and is otherwise harmless
            # e.g. when '--auth=md5' or '--auth-local=md5' is used in POSTGRES_INITDB_ARGS
            export PGPASSWORD="${PGPASSWORD:-$POSTGRES_PASSWORD}"
            docker_temp_server_start "$@"

            docker_setup_db
            docker_process_init_files /docker-entrypoint-initdb.d/*

            docker_temp_server_stop
            unset PGPASSWORD

            echo
            echo 'PostgreSQL init process complete; ready for start up.'
            echo
        else
            echo
            echo 'PostgreSQL Database directory appears to contain a database; Skipping initialization'
            echo
        fi
    fi

    exec "$@"
}

_main "$@"

