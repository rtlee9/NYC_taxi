/* Count rounding efficiency
http://stackoverflow.com/a/13571357
*/

-- Count Manhattan-only trips
select count(*)
from taxi_nhood_full t
inner join zillow_sp p
  on t.pick_zgid = p.gid
inner join zillow_sp d
  on t.drop_zgid = d.gid
where 1=1
  and p.city = 'New York City-Manhattan'
  and d.city = 'New York City-Manhattan'
;
-- Returns: 136057170

-- Count Manhattan-only trips, distinct rounded coordinates (4)
select count(*) from (
select distinct
  round(t.pickup_longitude::numeric, 4),
  round(t.pickup_latitude::numeric, 4),
  round(t.dropoff_longitude::numeric, 4),
  round(t.dropoff_latitude::numeric, 4)
from taxi_nhood_full t
inner join zillow_sp p
  on t.pick_zgid = p.gid
inner join zillow_sp d
  on t.drop_zgid = d.gid
where 1=1
  and p.city = 'New York City-Manhattan'
  and d.city = 'New York City-Manhattan'
) a
;
-- Returns: 130166526

-- Count Manhattan-only trips, distinct rounded coordinates (3)
select count(*) from (
select distinct
  round(t.pickup_longitude::numeric, 3),
  round(t.pickup_latitude::numeric, 3),
  round(t.dropoff_longitude::numeric, 3),
  round(t.dropoff_latitude::numeric, 3)
from taxi_nhood_full t
inner join zillow_sp p
  on t.pick_zgid = p.gid
inner join zillow_sp d
  on t.drop_zgid = d.gid
where 1=1
  and p.city = 'New York City-Manhattan'
  and d.city = 'New York City-Manhattan'
) a
;
-- Returns: 9873443

/*
Conclusion: rounding doesn't substantially reduce the number of records
Next steps: consider sampling along a grid or taking random trip samples
*/
