select t.*
from taxi_nhood_full t
inner join zillow_sp p
  on t.pick_zgid = p.gid
inner join zillow_sp d
  on t.drop_zgid = d.gid
where 1=1
  and p.city = 'New York City-Manhattan'
  and d.city = 'New York City-Manhattan'
order by random()
limit 2500
;
