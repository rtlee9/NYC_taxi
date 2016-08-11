#!/bin/bash

createdb nyc-taxi-data
psql nyc-taxi-data -c "CREATE EXTENSION postgis;"

shp2pgsql -s 2263:4326 1.Data/nycb2010_16b/nycb2010.shp | psql -d nyc-taxi-data
shp2pgsql -s 4269:4326 1.Data/ZillowNeighborhoods-NY/ZillowNeighborhoods-NY.shp zillow_sp | psql -d nyc-taxi-data

psql nyc-taxi-data -c "CREATE INDEX index_nycb_on_geom ON nycb2010 USING gist (geom);"
psql nyc-taxi-data -c "CREATE INDEX index_nycb_gid ON nycb2010 (gid);"
psql nyc-taxi-data -c "VACUUM ANALYZE nycb2010;"

psql nyc-taxi-data -c "CREATE INDEX index_geom ON zillow_sp USING gist (geom);"
psql nyc-taxi-data -c "CREATE INDEX index_sp_gid ON zillow_sp (gid);"
psql nyc-taxi-data -c "VACUUM ANALYZE zillow_sp;"

psql nyc-taxi-data -f 2.Code/1.DataPrep/GenDTDim.sql
