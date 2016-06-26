CREATE EXTENSION postgis;

CREATE TABLE yellow_tripdata_staging (
  vendor_id varchar
  ,pickup_datetime timestamp without time zone
  ,dropoff_datetime timestamp without time zone
  ,passenger_count integer
  ,trip_distance numeric
  ,pickup_long numeric
  ,pickup_lat numeric
  ,rate_code integer
  ,store_and_fwd_flag char(1)
  ,dropoff_long numeric
  ,dropoff_lat numeric
  ,payment_type integer
  ,fare_amount numeric
  ,surcharge numeric
  ,mta_tax numeric
  ,tip_amount numeric
  ,tolls_amount numeric
  ,total_amount numeric
);

COPY yellow_tripdata_staging FROM '/Users/Ryan/Github/NYC_taxi/1.Data/nyc_taxi_data.csv' DELIMITER ',' CSV HEADER;

select count(*) from yellow_tripdata_staging;
