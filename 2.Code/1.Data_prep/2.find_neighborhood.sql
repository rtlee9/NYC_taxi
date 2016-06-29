
ALTER TABLE nyc_taxi_yellow_14 ADD COLUMN id BIGSERIAL PRIMARY KEY;

CREATE TABLE temp_taxi_full AS
select
  id
  , ST_SetSRID(ST_MakePoint(pickup_longitude, pickup_latitude), 4269) as pickup
  , ST_SetSRID(ST_MakePoint(dropoff_longitude, dropoff_latitude), 4269) as dropoff
from public.nyc_taxi_yellow_14
;

CREATE TABLE temp_nyc_geo AS
SELECT
  t1.id
  ,spick.name as pick_neigh
  ,spick.city as pick_city
  ,spick.gid as pick_gid
  ,spick.state as pick_state
  ,spick.county as pick_county
  ,spick.regionid as pick_regionid
  ,sdrop.name as drop_neigh
  ,sdrop.city as drop_city
  ,sdrop.gid as drop_gid
  ,sdrop.state as drop_state
  ,sdrop.county as drop_county
  ,sdrop.regionid as drop_regionid
FROM temp_taxi_full t1
LEFT JOIN zillow_sp sdrop
  on ST_Within(t1.dropoff, sdrop.geom)
LEFT JOIN zillow_sp spick
  on ST_Within(t1.pickup, spick.geom)
;

SELECT *
from temp_nyc_geo
limit 10
;
