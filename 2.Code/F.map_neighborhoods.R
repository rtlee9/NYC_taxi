# ****************************************************************************
# Lookup the neighborood of a vector of coordinates
#
# Dependencies: F.neighborhood.R
#
# Need to make this faster; two potential solutions: vectorize the
# map_neighborhood function, remove duplicate coordinate pairs before calling
# lookup, and/or aggregate coordinates
# ****************************************************************************
function(s, lons, lats) {
    library(tcltk)
    library(doSNOW)
    library(foreach)
    neighborhood <- dget(paste0(lib_path, "F.neighborhood.R"))

    n <- length(lons)
    pb <- tkProgressBar(max=n)
    progress <- function(n) setTkProgressBar(pb, n)
    opts <- list(progress=progress)

    names <- s$NAME
    neighborhoods  <- rep(NA, n)

    cl<-makeCluster(4)
    registerDoSNOW(cl)
    neighborhoods <- foreach (i = 1:n, .packages="sp", .export="neighborhood", .options.snow=opts, .combine = "c") %dopar% neighborhood(s, lons[i], lats[i]);
    stopCluster(cl)
    return(neighborhoods)
}
