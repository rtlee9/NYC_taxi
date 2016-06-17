# ****************************************************************************
# Sankey - neighborhood to neighborhood (# trips)
# ****************************************************************************

names(dt) <- c("source", "target", "value", "type")

sankeyPlot <- rCharts$new()
d3_path <- paste0(data_path, "rCharts_d3_sankey-gh-pages")
sankeyPlot$setLib(paste0(d3_path, 'libraries/widgets/d3_sankey'))
sankeyPlot$setTemplate(paste0(d3_path, script = "layouts/chart.html"))

sankeyPlot$set(
    data = dt,
    nodeWidth = 10,
    nodePadding = 5,
    layout = 32,
    width = 1300,
    height = 800,
    units = "$MM",
    title = "Sankey Diagram"
)

sankeyPlot$setTemplate(
    afterScript = "
    <script>
    // to be specific in case you have more than one chart
    d3.selectAll('#{{ chartId }} svg path.link')
    .style('stroke', function(d){
    //here we will use the source color
    //if you want target then sub target for source
    //or if you want something other than gray
    //supply a constant
    //or use a categorical scale or gradient
    return d.source.color;
    })
    //note no changes were made to opacity
    //to do uncomment below but will affect mouseover
    //so will need to define mouseover and mouseout
    //happy to show how to do this also
    // .style('stroke-opacity', .7)
    </script>
    ")
sankeyPlot
sankeyPlot$save(paste0(file, ".html"), cdn = TRUE)


# ****************************************************************************
# Sankey - neighborhood to neighborhood (dollars)
# ****************************************************************************
