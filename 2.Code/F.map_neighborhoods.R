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
    require(progress)
    n <- length(lons)
    pb <- progress_bar$new(total = n)

    neighborhoods  <- rep(NA, n);
    for (i in 1:n) {
        neighborhoods[i] <- neighborhood(s, lons[i], lats[i]);
        pb$tick()
    }
    return(neighborhoods);
}