# ****************************************************************************
# Lookup the neighborhood of a single coordinate
# ****************************************************************************
function(s, lon, lat) {
    names <- s$NAME
    for (name in names) {
        lons <- s[s$NAME == name,]@polygons[[1]]@Polygons[[1]]@coords[,1];
        lats <- s[s$NAME == name,]@polygons[[1]]@Polygons[[1]]@coords[,2];
        res <- point.in.polygon(lon, lat, lons, lats);
        if (res == 1) {
            return(name);
        }
    }
    return(NA)
}