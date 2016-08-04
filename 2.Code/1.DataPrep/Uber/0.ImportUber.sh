#!/bin/bash

# Create staging table
psql Ryan -f create_stg.sql

# load 2014 Uber data into unified `trips` table
for filename in ../../1.Data/uber*14.csv; do
	  echo "`date`: beginning load for $filename"
	    cat $filename | psql Ryan -c "SET datestyle = 'ISO, MDY'; COPY uber_trips_staging (pickup_datetime, pickup_latitude, pickup_longitude, base_code) FROM stdin CSV HEADER;"
	      echo "`date`: finished raw load for $filename"
	        psql Ryan -f populate_uber_trips.sql
		  echo "`date`: loaded trips for $filename"
	  done;
