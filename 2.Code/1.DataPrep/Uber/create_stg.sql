CREATE TABLE uber_trips_staging (
	  id serial primary key,
	  pickup_datetime timestamp without time zone,
	  pickup_latitude numeric,
	  pickup_longitude numeric,
	  base_code varchar
);

CREATE TABLE uber_trips_2015 (
	  id serial primary key,
	  dispatching_base_num varchar,
	  pickup_datetime timestamp without time zone,
	  affiliated_base_num varchar,
	  location_id integer,
	  nyct2010_ntacode varchar
);

CREATE TABLE uber_taxi_zone_lookups (
	  location_id integer primary key,
	  borough varchar,
	  zone varchar,
	  nyct2010_ntacode varchar
);

CREATE TABLE trips (
	  id serial primary key,
	  cab_type_id integer,
	  vendor_id varchar,
	  pickup_datetime timestamp without time zone,
	  dropoff_datetime timestamp without time zone,
	  store_and_fwd_flag char(1),
	  rate_code_id integer,
	  pickup_longitude numeric,
	  pickup_latitude numeric,
	  dropoff_longitude numeric,
	  dropoff_latitude numeric,
	  passenger_count integer,
	  trip_distance numeric,
	  fare_amount numeric,
	  extra numeric,
	  mta_tax numeric,
	  tip_amount numeric,
	  tolls_amount numeric,
	  ehail_fee numeric,
	  improvement_surcharge numeric,
	  total_amount numeric,
	  payment_type varchar,
	  trip_type integer,
	  pickup_nyct2010_gid integer,
	  dropoff_nyct2010_gid integer
);
