#!/bin/bash

Rscript 2.Code/2.AnalysisNeighborhoods/PrintMaps.R
convert -delay 100 -loop 0 5.Plots/Pick_neigh_*.png 5.Plots/drop_by_pick.gif
