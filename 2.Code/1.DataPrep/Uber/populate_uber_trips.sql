INSERT INTO trips
(vendor_id, pickup_datetime, pickup_longitude, pickup_latitude)
SELECT
  base_code,
  pickup_datetime,
  CASE WHEN pickup_longitude != 0 THEN pickup_longitude END,
	  CASE WHEN pickup_latitude != 0 THEN pickup_latitude END
				FROM
				  uber_trips_staging
				;

				TRUNCATE TABLE uber_trips_staging;
