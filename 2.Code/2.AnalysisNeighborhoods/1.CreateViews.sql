/********************************************************************
  Create views for frequently accessed cuts
********************************************************************/

CREATE MATERIALIZED VIEW pick_by_pick_neigh AS
select
  round(t.pickup_longitude::numeric, 4) as lon, round(t.pickup_latitude::numeric, 4) as lat
  ,z.name as pick_neigh
  ,count(*) as trips
from taxi_nhood_full t
left join zillow_sp z
  on t.pick_zgid = z.gid
where 1=1
  and z.city = 'New York City-Manhattan'
group by
  round(t.pickup_longitude::numeric, 4), round(t.pickup_latitude::numeric, 4)
  ,z.name
;

CREATE MATERIALIZED VIEW drop_by_pick_neigh AS
select
  round(t.dropoff_longitude::numeric, 4) as lon, round(t.dropoff_latitude::numeric, 4) as lat
  ,z.name as pick_neigh
  ,count(*) as trips
from taxi_nhood_full t
left join zillow_sp z
  on t.pick_zgid = z.gid
where 1=1
  and z.city = 'New York City-Manhattan'
group by
  round(t.dropoff_longitude::numeric, 4), round(t.dropoff_latitude::numeric, 4)
  ,z.name
;

-- Census blocks base summary
CREATE MATERIALIZED VIEW tow_ctb_sum AS
SELECT
  zpick.bctcb2010 as pick_bctcb
  ,zpick.ct2010 as pick_ct
  ,zpick.boroname as pick_borough
  ,zdrop.bctcb2010 as drop_bctcb
  ,zdrop.ct2010 as drop_ct
  ,zdrop.boroname as drop_borough
  ,sum(t.fare_amount) as fare
  ,sum(t.tip_amount) as tip
  ,sum(t.passenger_count) as passengers
  ,sum(t.trip_distance) as distance
  ,sum(t.elapsed) as elapsed
  ,count(*) as trips
FROM taxi_nhood_full t
left join public.nycb2010 zpick
  on t.pick_bgid = zpick.gid
left join public.nycb2010 zdrop
  on t.drop_bgid = zdrop.gid
left join date_dim d
  on t.pick_date = d.date
group by
  zpick.bctcb2010
  ,zpick.ct2010
  ,zpick.boroname
  ,zdrop.bctcb2010
  ,zdrop.ct2010
  ,zdrop.boroname
;

CREATE MATERIALIZED VIEW top10routes_full as
select t.*, zpick.bctcb2010 as pick_bctcb, zdrop.bctcb2010 as drop_bctcb, s.rank
from taxi_nhood_full t
left join public.nycb2010 zpick
  on t.pick_bgid = zpick.gid
left join public.nycb2010 zdrop
  on t.drop_bgid = zdrop.gid
inner join (
  select pick_bctcb, drop_bctcb, trips, row_number() over() as rank
  from tow_ctb_sum
  where pick_borough = 'Manhattan' and drop_borough = 'Manhattan'
    and pick_bctcb <> drop_bctcb
  order by trips desc limit 10
) s
  on zpick.bctcb2010 = s.pick_bctcb and zdrop.bctcb2010 = s.drop_bctcb
;

-- Neighborhood base summary
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
  on t.pick_zgid = zpick.gid
left join zillow_sp zdrop
  on t.drop_zgid = zdrop.gid
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
  ,p.pick_city
  ,p.dayofweek
  ,p.pick_hour
  ,p.americanholiday
;
