#' @title Output module: InteractiveCovariateMap
#'
#' @description Plot a zoomable and scrollable map of a covariate layer.
#'
#' @param .model \strong{Internal parameter, do not use in the workflow function}. \code{.model} is list of a data frame (\code{data}) and a model object (\code{model}). \code{.model} is passed automatically in workflow, combining data from the model module(s) and process module(s), to the output module(s) and should not be passed by the user.#'
#'
#' @param .ras \strong{Internal parameter, do not use in the workflow function}. \code{.ras} is a raster layer, brick or stack object. \code{.ras} is passed automatically in workflow from the covariate module(s) to the output module(s) and should not be passed by the user.
#'
#' @param which which covariate to plot.
#' A single numeric giving the index of the covariate to plot
#' 
#' @param maxBytes The maximum number of bytes to allow for the projected image (before base64 encoding); defaults to 4MB.
#' 
#' @author ZOON Developers, David Wilkinson, \email{zoonproject@@gmail.com}
#' @section Version: 1.1
#' @section Date submitted: 2018-04-10
#' 
#' @name InteractiveCovariateMap
#' @family output
InteractiveCovariateMap <-
  function (.model, .ras, which = 1, maxBytes = 4.2e6) {
    
    # This function draws inspiration from a previous version of
    # the Rsenal package: https://github.com/environmentalinformatics-marburg/Rsenal
    # and of course relies heavily on the wonderful leaflet package whose
    # functions it relies on
    
    # load required packages
    zoon:::GetPackage('leaflet')
    zoon:::GetPackage('rgdal')
    zoon:::GetPackage('viridis')
    zoon:::GetPackage('htmlwidgets')
    
    # set up a map with background layers
    m <- leaflet::leaflet()
    m <- leaflet::addTiles(map = m, group = 'OpenStreetMap')
    m <- leaflet::addProviderTiles(map = m,
                                   provider = 'Esri.WorldImagery',
                                   group = 'Esri.WorldImagery')
    
    # get the required covariate
    .ras <- .ras[[which]]
    
    # get covariates colour palette
    cov_pal <- leaflet::colorNumeric(viridis(10), 
                                      domain = c(minValue(.ras),
                                                 maxValue(.ras)), 
                                      na.color = 'transparent')
    
    # reproject pred_ras, suppressing warnings
    suppressWarnings(ext <- raster::projectExtent(.ras,
                                                  crs = sp::CRS('+init=epsg:3857')))
    suppressWarnings(.ras <- raster::projectRaster(.ras,
                                                       ext))
    
    m <- leaflet::addRasterImage(map = m,
                                 x = .ras,
                                 colors = cov_pal,
                                 project = FALSE,
                                 opacity = 0.8,
                                 group = names(.ras),
                                 maxBytes = maxBytes)
    
    # add to list of overlay layers
    overlay_groups <- names(.ras)
    
    
    # get legend values
    legend_values <- round(seq(minValue(.ras),
                               maxValue(.ras),
                               length.out = 10), 3)
    
    # add legend
    m <- leaflet::addLegend(map = m,
                            pal = cov_pal,
                            opacity = 0.8, 
                            values = legend_values, 
                            title = names(.ras))
    
    # add training data
    df <- .model$data
    
    # color palettes for circles
    fill_pal <- colorFactor(grey(c(1, 0, 0.2)),
                            domain = c('presence',
                                       'absence',
                                       'background'))
    
    border_pal <- colorFactor(grey(c(0, 1, 1)),
                              domain = c('presence',
                                         'absence',
                                         'background'))
    
    for (type in c('background', 'absence', 'presence')) {
      if (any(df$type == type)) {
        idx <- df$type == type
        group_name <- paste(type, 'data')
        overlay_groups <- c(overlay_groups, group_name)
        m <- leaflet::addCircleMarkers(map = m,
                                       lng = df$lon[idx],
                                       lat = df$lat[idx],
                                       color = grey(0.4),
                                       fillColor = fill_pal(type),
                                       weight = 1,
                                       opacity = 1,
                                       fillOpacity = 1,
                                       radius = 5,
                                       group = group_name)
        
      }
    }
    
    # add toggle for the layers
    m <- leaflet::addLayersControl(map = m,
                                   position = "topleft",
                                   baseGroups = c('OpenStreetMap',
                                                  'Esri.WorldImagery'),
                                   overlayGroups = overlay_groups)
    
    htmlwidgets:::print.htmlwidget(x = m)
    
    return (NULL)
    
  }
