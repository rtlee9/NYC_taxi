select
  t.*
  ,pick.name as pick_neigh
  ,zpick.bctcb2010 as pick_bctcb
  ,zpick.ct2010 as pick_ct
  ,drop.name as drop_neigh
  ,zdrop.bctcb2010 as drop_bctcb
  ,zdrop.ct2010 as drop_ct
  ,d.dayofweek
  ,d.weekdayname
  ,d.weekend
  ,d.americanholiday
from taxi_nhood_full t
inner join zillow_sp pick
  on t.pick_zgid = pick.gid
inner join zillow_sp drop
  on t.drop_zgid = drop.gid
left join public.nycb2010 zpick
  on t.pick_bgid = zpick.gid
left join public.nycb2010 zdrop
  on t.drop_bgid = zdrop.gid
left join date_dim d
  on t.pick_date = d.date
where 1=1
  and pick.city = 'New York City-Manhattan'
  and drop.city = 'New York City-Manhattan'
order by random()
limit 500000
;
