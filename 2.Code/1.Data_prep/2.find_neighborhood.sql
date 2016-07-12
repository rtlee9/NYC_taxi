
ALTER TABLE nyc_taxi_yellow_14 ADD COLUMN id BIGSERIAL PRIMARY KEY;
ALTER TABLE public.zillow_sp ADD PRIMARY KEY (regionid);

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
  ,spick.regionid as pick_regionid
  ,sdrop.regionid as drop_regionid
FROM temp_taxi_full t1
LEFT JOIN zillow_sp sdrop
  on ST_Within(t1.dropoff, sdrop.geom)
LEFT JOIN zillow_sp spick
  on ST_Within(t1.pickup, spick.geom)
;

DROP TABLE temp_taxi_full;

CREATE TABLE taxi_nhood_full as
SELECT
  t.*
  ,t.pickup_datetime::date as pick_date
  ,extract(hour from t.pickup_datetime::time) as pick_hour
  ,extract(epoch from (t.dropoff_datetime::timestamp - t.pickup_datetime::timestamp)) as elapsed
  ,g.pick_regionid
  ,g.pick_neigh
  ,g.drop_regionid
  ,g.drop_neigh
from temp_nyc_geo g
inner join nyc_taxi_yellow_14 t
  on g.id = t.id
;

DROP TABLE temp_nyc_geo;
CREATE INDEX idx_pick_id ON taxi_nhood_full (pick_regionid);
CREATE INDEX idx_drop_id ON taxi_nhood_full (drop_regionid);

CREATE MATERIALIZED VIEW pick_by_pick_neigh AS
select
  round(pickup_longitude::numeric, 4) as lon, round(pickup_latitude::numeric, 4) as lat
  ,pick_neigh
  ,count(*) as trips
from taxi_nhood_full t
left join zillow_sp z
  on t.pick_regionid = z.regionid
where 1=1
  and z.city = 'New York City-Manhattan'
group by
  round(pickup_longitude::numeric, 4), round(pickup_latitude::numeric, 4)
  ,pick_neigh
;

CREATE MATERIALIZED VIEW drop_by_pick_neigh AS
select
  round(dropoff_longitude::numeric, 4) as lon, round(dropoff_latitude::numeric, 4) as lat
  ,pick_neigh
  ,count(*) as trips
from taxi_nhood_full t
left join zillow_sp z
  on t.pick_regionid = z.regionid
where 1=1
  and z.city = 'New York City-Manhattan'
group by
  round(dropoff_longitude::numeric, 4), round(dropoff_latitude::numeric, 4)
  ,pick_neigh
;

CREATE INDEX indx_pick_neigh ON drop_by_pick_neigh (pick_neigh);
--SELECT COUNT(*) FROM drop_by_pick_neigh;

CREATE MATERIALIZED VIEW tow_nhood_sum AS
SELECT
  zpick.name as pick_neigh
  ,zpick.city as pick_city
  ,zdrop.name as drop_neigh
  ,zdrop.city as drop_city
  ,t.pick_hour
  ,d.dayofweek
  ,d.weekdayname
  ,d.weekend
  ,d.americanholiday
  ,t.payment_type
  ,sum(t.fare_amount) as fare
  ,sum(t.tip_amount) as tip
  ,sum(t.passenger_count) as passengers
  ,sum(t.trip_distance) as distance
  ,sum(t.elapsed) as elapsed
  ,count(*) as trips
FROM taxi_nhood_full t
left join zillow_sp zpick
  on t.pick_regionid = zpick.regionid
left join zillow_sp zdrop
  on t.drop_regionid = zdrop.regionid
left join date_dim d
  on t.pick_date = d.date
group by
  zpick.name
  ,zpick.city
  ,zdrop.name
  ,zdrop.city
  ,t.pick_hour
  ,d.dayofweek
  ,d.weekdayname
  ,d.weekend
  ,d.americanholiday
  ,t.payment_type
;

CREATE VIEW neighborhood_sum AS
SELECT
  pick_neigh
  ,pick_city
  ,drop_neigh
  ,drop_city
  ,sum(fare) as fare
  ,sum(tip) as tip
  ,sum(passengers) as passengers
  ,sum(distance) as distance
  ,sum(elapsed) as elapsed
  ,sum(trips) as trips
FROM tow_nhood_sum
WHERE payment_type = 'CRD'
group by
  pick_neigh
  ,pick_city
  ,drop_neigh
  ,drop_city
;

CREATE VIEW tow_pick AS
SELECT
  pick_neigh
  ,pick_city
  ,dayofweek
  ,pick_hour
  ,americanholiday
  ,sum(fare) as fare
  ,sum(tip) as tip
  ,sum(passengers) as passengers
  ,sum(distance) as distance
  ,sum(elapsed) as elapsed
  ,sum(trips) as trips
FROM tow_nhood_sum
group by
  pick_neigh
  ,pick_city
  ,dayofweek
  ,pick_hour
  ,americanholiday
;

CREATE VIEW tow_drop AS
SELECT
  drop_neigh
  ,drop_city
  ,dayofweek
  ,pick_hour
  ,americanholiday
  ,sum(fare) as fare
  ,sum(tip) as tip
  ,sum(passengers) as passengers
  ,sum(distance) as distance
  ,sum(elapsed) as elapsed
  ,sum(trips) as trips
FROM tow_nhood_sum
group by
  drop_neigh
  ,drop_city
  ,dayofweek
  ,pick_hour
  ,americanholiday
;

CREATE VIEW tow_flow AS
SELECT
  p.pick_neigh as nhood
  ,p.pick_city as city
  ,p.dayofweek
  ,p.pick_hour
  ,p.americanholiday
  ,coalesce(sum(p.trips), 0) as trips_out
  ,coalesce(sum(d.trips), 0) as trips_in
  ,coalesce(sum(d.trips), 0) - coalesce(sum(p.trips), 0) as net_trips_in
from tow_drop d
full outer join tow_pick p
  on d.drop_neigh = p.pick_neigh
  and d.dayofweek = p.dayofweek
  and d.pick_hour = p.pick_hour
  and d.americanholiday = p.americanholiday
group by
  p.pick_neigh
  ,p.dayofweek
  ,p.pick_hour
  ,p.americanholiday
;

-------

select
  zpick.name as pick_neigh
  ,case when t.trip_distance < 3 then 'Less than 3 miles'
    when t.trip_distance < 5 then '3-6 miles'
    when t.trip_distance < 8 then '6-9 miles'
    else '9 miles or more' end as dist_bin
  ,sum(t.tip_amount)/count(t.*) as tip_pct
FROM taxi_nhood_full t
left join zillow_sp zpick
  on t.pick_regionid = zpick.regionid
where 1=1
  and zpick.city = 'New York City-Manhattan'
  and t.payment_type = 'CRD'
  and t.trip_distance > 0
group by
  zpick.name
  ,case when t.trip_distance < 3 then 'Less than 3 miles'
    when t.trip_distance < 5 then '3-6 miles'
    when t.trip_distance < 8 then '6-9 miles'
    else '9 miles or more' end
;
