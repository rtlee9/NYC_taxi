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
    neighborhoods  <- rep(NA, length(lons));
    for (i in 1:length(lons)) {
        neighborhoods[i] <- neighborhood(s, lons[i], lats[i]);
    }
    return(neighborhoods);
}