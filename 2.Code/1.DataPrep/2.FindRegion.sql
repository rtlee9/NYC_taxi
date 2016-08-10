/********************************************************************
  Map points to geographic areas
********************************************************************/

CREATE TABLE temp_taxi_full AS
select
  id
  , ST_SetSRID(ST_MakePoint(pickup_longitude, pickup_latitude), 4326) as pickup4326
  , ST_SetSRID(ST_MakePoint(dropoff_longitude, dropoff_latitude), 4326) as dropoff4326
from public.nyc_taxi_yellow_14
;

CREATE TABLE temp_nyc_geo AS
SELECT
  t1.id
  ,zpick.gid as pick_zgid
  ,zdrop.gid as drop_zgid
  ,bpick.gid as pick_bgid
  ,bdrop.gid as drop_bgid
FROM temp_taxi_full t1
LEFT JOIN zillow_sp zdrop
  on ST_Within(t1.dropoff4326, zdrop.geom)
LEFT JOIN zillow_sp zpick
  on ST_Within(t1.pickup4326, zpick.geom)
LEFT JOIN public.nycb2010 bdrop
  on ST_Within(t1.dropoff4326, bdrop.geom)
LEFT JOIN public.nycb2010 bpick
  on ST_Within(t1.pickup4326, bpick.geom)
;

CREATE TABLE taxi_nhood_full as
SELECT
  t.*
  ,t.pickup_datetime::date as pick_date
  ,extract(hour from t.pickup_datetime::time) as pick_hour
  ,extract(epoch from (t.dropoff_datetime::timestamp - t.pickup_datetime::timestamp)) as elapsed
  ,g.pick_zgid
  ,g.drop_zgid
  ,g.pick_bgid
  ,g.drop_bgid
  ,c.dropoff4326
  ,c.pickup4326
  ,ST_Distance(c.dropoff4326::geography, c.pickup4326::geography) as geom_distance
from temp_nyc_geo g
right join nyc_taxi_yellow_14 t
  on g.id = t.id
left join temp_taxi_full c
  on t.id = c.id
;

DROP TABLE temp_taxi_full;
DROP TABLE temp_nyc_geo;

CREATE INDEX idx_pick_bgid ON taxi_nhood_full (pick_bgid);
CREATE INDEX idx_drop_bgid ON taxi_nhood_full (drop_bgid);
