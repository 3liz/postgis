# Upgrade postgres database with Docker

Upgrade postgres database from OLD to NEW

*OLD* and *NEW* are related to the *major* version of postgres

Suppose the directory structure is

```bash
$ find DIR -mindepth 2 -maxdepth 2
DIR/OLD/data
DIR/NEW/data

$ docker run --rm -v DIR:/var/lib/postgresql postgis-upgrade:OLD-to-NEW [--link]
```

Alternatively, you may mount each data directory individually:

```
docker run --rm -v PGDATAOLD:/var/lib/postgresql/OLD/data \
                -v PGDATANEW:/var/lib/postgresql/NEW/data \
                postgis-upgrade:OLD-to-NEW [--link]
```

By default the container run `pg_upgrade`. 

If extensions must be upgraded, the script `update-extensions` will execute an `update_extensions.sql` file found 
in the path. 

See below for an example of `update_extensions.sql` file.

## Postgis version 

Given the postgres major version Postgis version may come to version 2.5 or version 3.

We assume that:

* For Postgresql 13+ then postgis is version 3
* For Postgresql 12 or lower then postgis is version 2.5

If your version scheme is different, ensure tag the upgrade image accordingly
to reflect the postgis  version used.

For upgrading Postgis after running `pg_upgrade`:

```
ALTER EXTENSION postgis UPDATE;
-- this next step repackages raster in its own extension
-- and upgrades all your other related postgis extensions
SELECT PostGIS_Extensions_Upgrade();
 
-- if you don't use raster, you can do below 
-- after the upgrade step
DROP EXTENSION postgis_raster;
```


 
## References:

* https://postgis.net/2019/10/20/postgis-3.0.0/
* https://github.com/tianon/docker-postgres-upgrade

