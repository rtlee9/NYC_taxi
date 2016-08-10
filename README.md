# NYC_taxi

NYC taxi medallion analysis featured in my blog post _[NYC yellow cab trips: Neighborhood by neighborhood](http://eightportions.com/2016-07-14-NYC-yellow-cabs-neighborhoods/)_.

## Setup

The following steps assume you have R, PostgreSQL, and PostGIS installed on your machine.

1. Clone repo to local drive
1. Download [data](Resources.md#data) into the `./1.Data` path
1. Run scripts in the `2.Code/1.DataPrep` path sequentially
  * `$ chmod +x /2.Code/1.DataPrep/0.PrepSchema.sh` followed by `$ ./2.Code/1.DataPrep/0.PrepSchema.sh`
  * `$ Rscript 1.UploadData.R`
  * `$ psql nyc-taxi-data -f 2.Code/1.DataPrep/2.FindRegion.sql`
1. Run the `2.Code/2.AnalysisNeighborhoods/1.CreateViews.sql` script: `$ psql nyc-taxi-data -f 2.Code/2.AnalysisNeighborhoods/1.CreateViews.sql`

## Analysis
All analysis beyond the setup described [above](#setup) can be found in the R Markdown source code for my post [here](4.Blog/2016-07-14-NYC-yellow-cabs-neighborhoods.Rmd). This code was knit into markdown for Jekyll with the [knitr](http://yihui.name/knitr/) package.

## Credit
Special thanks to to Todd Schneider for his [instructions](https://github.com/toddwschneider/nyc-taxi-data).
