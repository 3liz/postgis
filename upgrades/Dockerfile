# 
# Image for upgrading postgres installation
# 
# Derived from https://github.com/tianon/docker-postgres-upgrade
#
ARG REGISTRY_PREFIX=''
ARG PGVERSIONNEW
ARG POSTGISVERSIONNEW

FROM ${REGISTRY_PREFIX}postgis:${PGVERSIONNEW}-${POSTGISVERSIONNEW}
Label Maintainer="David Marteau" Vendor="3liz.com" Version="21.11.0"

ARG PGVERSIONNEW
ARG PGVERSIONOLD
ARG POSTGISVERSIONOLD

# In order to upgrade postgis we need to install the old version

USER root
RUN set -eux; export DEBIAN_FRONTEND=noninteractive;  \
    echo "deb http://apt.postgresql.org/pub/repos/apt/ focal-pgdg main" > /etc/apt/sources.list.d/pgdg.list; \
    apt-get -y update; \
    apt-get install -y postgresql-common  --no-install-recommends; \
    apt-get install -y postgresql-$PGVERSIONOLD-postgis-$POSTGISVERSIONOLD \
                       postgresql-$PGVERSIONOLD-postgis-$POSTGISVERSIONOLD-scripts \
                       postgresql-$PGVERSIONNEW-postgis-$POSTGISVERSIONOLD \
                       postgresql-$PGVERSIONNEW-postgis-$POSTGISVERSIONOLD-scripts \
                       postgresql-contrib-$PGVERSIONOLD \
                       postgresql-$PGVERSIONOLD-ogr-fdw \
                       postgresql-$PGVERSIONOLD-cron \
                       postgresql-$PGVERSIONOLD-pgrouting \
                       postgresql-$PGVERSIONOLD-pgrouting-scripts \
                      postgresql-contrib-$PGVERSIONOLD \
                       --no-install-recommends; \
    apt-get autoremove -y; rm -rf /var/lib/apt/lists/*

ENV PGBINOLD /usr/lib/postgresql/$PGVERSIONOLD/bin
ENV PGBINNEW /usr/lib/postgresql/$PGVERSIONNEW/bin

ENV PGDATAOLD /var/lib/postgresql/$PGVERSIONOLD/data
ENV PGDATANEW /var/lib/postgresql/$PGVERSIONNEW/data

RUN mkdir -p "$PGDATAOLD" "$PGDATANEW" /var/lib/postgresql/$PGVERSIONOLD-to-$PGVERSIONNEW \
    && chown -R postgres:postgres /var/lib/postgresql 

WORKDIR /var/lib/postgresql/$PGVERSIONOLD-to-$PGVERSIONNEW

COPY docker-upgrade update-extensions /usr/local/bin/

ENTRYPOINT ["docker-upgrade"]

CMD ["pg_upgrade"]

