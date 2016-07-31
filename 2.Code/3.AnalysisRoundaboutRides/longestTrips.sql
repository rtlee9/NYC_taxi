-- Percent of trips that end w/ same pickup, dropoff coordinates
select
  case when pickup_longitude = dropoff_longitude
    and pickup_latitude = dropoff_latitude
    then 1 else 0 end as roundtrip_ind
  ,sum(t.fare_amount) as fare
  ,sum(t.tip_amount) as tip
  ,sum(t.passenger_count) as passengers
  ,sum(t.trip_distance) as distance
  ,sum(t.elapsed) as elapsed
  ,count(*) as trips
from taxi_nhood_full t
group by
  case when pickup_longitude = dropoff_longitude
    and pickup_latitude = dropoff_latitude
    then 1 else 0 end
;


-- Find top distance, by taxi recorded distance
select trip_distance, geom_distance, pickup_latitude, pickup_longitude, dropoff_latitude, dropoff_longitude, fare_amount, tip_amount
from taxi_nhood_full
order by trip_distance desc
limit 100
;

-- Find top distance, by taxi recorded distance
select trip_distance, geom_distance, pickup_latitude, pickup_longitude, dropoff_latitude, dropoff_longitude, fare_amount, tip_amount
from taxi_nhood_full
where 1=1
  and pickup_longitude not in (0, 180, -180)
  and dropoff_longitude not in (0, 180, -180)
  and pickup_latitude not in (0, 180, -180)
  and dropoff_latitude not in (0, 180, -180)
  and fare_amount > 100
order by geom_distance desc
limit 100
)
;

-- Find top distance, by taxi recorded distance
select trip_distance, geom_distance, pickup_latitude, pickup_longitude, dropoff_latitude, dropoff_longitude, fare_amount, tip_amount
from taxi_nhood_full
order by fare_amount desc
limit 100
;
