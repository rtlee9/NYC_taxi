# NYC_taxi

NYC taxi medallion analysis featured in my blog post _[NYC yellow cab trips: Neighborhood by neighborhood](https://eightportions.com/2016-07-14-NYC-yellow-cabs-neighborhoods/)_.

## Setup

The following steps assume you have R, PostgreSQL, and PostGIS installed on your machine.

1. Clone repo to local drive
1. Download [data](Resources.md#data) into the `./1.Data` path
1. Run scripts in the `2.Code/1.DataPrep` path sequentially; if running from a shell, make sure the working directory is set to the project root, then run:
  * `$ chmod +x 2.Code/1.DataPrep/0.PrepSchema.sh` followed by `$ ./2.Code/1.DataPrep/0.PrepSchema.sh`
  * `$ Rscript 2.Code/1.DataPrep/1.UploadData.R`
  * `$ psql nyc-taxi-data -f 2.Code/1.DataPrep/2.FindRegion.sql`
1. Run the  scripts in `2.Code/2.AnalysisNeighborhoods`; if running from a shell:
  * `$ psql nyc-taxi-data -f 2.Code/2.AnalysisNeighborhoods/1.CreateViews.sql`
  * `chmod +x 2.Code/2.AnalysisNeighborhoods/2.MakeMaps.sh` followed by `./2.Code/2.AnalysisNeighborhoods/2.MakeMaps.sh `

Run time is approximately 3 days on my MacBook Pro.

## Analysis
All analysis beyond the setup described [above](#setup) can be found in the R Markdown source code for my post [here](https://gitlab.com/rtlee/rtlee.gitlab.io/blob/master/_source/2016-07-14-NYC-yellow-cabs-neighborhoods.Rmd). This code was knit into markdown for Jekyll with the [knitr](http://yihui.name/knitr/) package.

## Credit
Special thanks to to Todd Schneider for his [instructions](https://github.com/toddwschneider/nyc-taxi-data).
