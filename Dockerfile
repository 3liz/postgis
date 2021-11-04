ARG REGISTRY_PREFIX=''

FROM ${REGISTRY_PREFIX}ubuntu:20.04
Label Maintainer="David Marteau" Vendor="3liz.com" Version="21.11.0"

# Build argument: docker build --build-arg
ARG POSTGRES_VER=12
ARG POSTGIS_VER=2.5
ARG POSTGRES_UID=999
ARG POSTGRES_GID=999
ARG LANGUAGE=en_US

ENV PG_MAJOR ${POSTGRES_VER}
ENV POSTGIS_MAJOR ${POSTGIS_VER}
ENV LANGUAGE ${LANGUAGE}

RUN  set -eux; export DEBIAN_FRONTEND=noninteractive; \
     apt-get -y update && apt-get upgrade -y && apt-get install -y --no-install-recommends wget ca-certificates gnupg2 dirmngr gosu locales; \
     rm -rf /var/lib/apt/lists/*; \
     localedef -i $LANGUAGE -c -f UTF-8 -A /usr/share/locale/locale.alias $LANGUAGE.UTF-8; \
     wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -; \
     apt-get -y purge wget

ENV LANG $LANGUAGE.utf8

# explicitly set user/group IDsV
RUN set -eux; export DEBIAN_FRONTEND=noninteractive; \
    groupadd -r postgres --gid=${POSTGRES_GID}; \
    useradd -r -g postgres --uid=${POSTGRES_UID} --home-dir=/var/lib/postgres postgres; \
    mkdir -p /var/lib/postgresql; \
    chown -R postgres:postgres /var/lib/postgresql

# Add PostgreSQL's repository.
COPY postgis.preference /etc/apt/preferences.d/pgdg

RUN set -eux; export DEBIAN_FRONTEND=noninteractive;  \
    echo "deb http://apt.postgresql.org/pub/repos/apt/ focal-pgdg main"  > /etc/apt/sources.list.d/pgdg.list; \
    apt-get -y update; \
    apt-get install -y postgresql-common  --no-install-recommends; \
    sed -ri 's/#(create_main_cluster) .*$/\1 = false/' /etc/postgresql-common/createcluster.conf; \
    apt-get install -y postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR \
                       postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR-scripts \
                       postgresql-contrib-$PG_MAJOR \
                       postgresql-$PG_MAJOR-ogr-fdw \
                       postgresql-$PG_MAJOR-cron \
                       postgresql-$PG_MAJOR-pgrouting \
                       postgresql-$PG_MAJOR-pgrouting-scripts \
                       --no-install-recommends; \
    apt-get autoremove -y; rm -rf /var/lib/apt/lists/*

# make the sample config easier to munge (and "correct by default")
RUN set -eux; export DEBIAN_FRONTEND=noninteractive; \
    dpkg-divert --add --rename --divert "/usr/share/postgresql/postgresql.conf.sample.dpkg" "/usr/share/postgresql/$PG_MAJOR/postgresql.conf.sample"; \
    cp -v /usr/share/postgresql/postgresql.conf.sample.dpkg /usr/share/postgresql/postgresql.conf.sample; \
    ln -sv ../postgresql.conf.sample "/usr/share/postgresql/$PG_MAJOR/"; \
    sed -ri "s!^#?(listen_addresses)\s*=\s*\S+.*!\1 = '*'!" /usr/share/postgresql/postgresql.conf.sample; \
    grep -F "listen_addresses = '*'" /usr/share/postgresql/postgresql.conf.sample

ENV PATH /usr/lib/postgresql/$PG_MAJOR/bin:$PATH
ENV PGDATA /var/lib/postgresql/data

RUN set -eux; export DEBIAN_FRONTEND=noninteractive; \
    mkdir -p "$PGDATA" && chown -R postgres:postgres "$PGDATA" && chmod 777 "$PGDATA"; \
    mkdir -p /var/run/postgresql && chown -R postgres:postgres /var/run/postgresql && chmod 2777 /var/run/postgresql; \
    mkdir /docker-entrypoint-initdb.d

# We will run any commands in this when the container starts
COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

VOLUME /var/lib/postgresql/data

# Open port 5432 so linked containers can see them
EXPOSE 5432
CMD ["postgres"]



