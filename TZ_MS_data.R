# Tanzania MobileSurvey 250m resolution data setup 
# M. Walsh, October 2017

# Required packages
# install.packages(c("downloader","rgdal","raster","leaflet","htmlwidgets")), dependencies=TRUE)
suppressPackageStartupMessages({
  require(downloader)
  require(rgdal)
  require(raster)
  require(leaflet)
  require(htmlwidgets)
})

# Data downloads -----------------------------------------------------------
# set working directory
dir.create("TZ_MS250", showWarnings=F)
setwd("./TZ_MS250")

# download MobileSurvey data
download("https://www.dropbox.com/s/vz6cxhsdrkznmkm/TZ_maize_system.csv.zip?raw=1", "TZ_maize_system.csv.zip", mode="wb")
unzip("TZ_maize_system.csv.zip", overwrite=T)
msos <- read.table("TZ_maize_system.csv", header=T, sep=",")

# download Tanzania Gtifs (note this is a big 750+ Mb download)
download("https://www.dropbox.com/s/pshrtvjf7navegu/TZ_250m_2017.zip?raw=1", "TZ_250m_2017.zip", mode="wb")
unzip("TZ_250m_2017.zip", overwrite=T)

# download Tanzania GeoSurvey predictions
download("https://www.dropbox.com/s/3px2xh9l4a6b38g/TZ_GS_preds.zip?raw=1", "TZ_GS_preds.zip", mode="wb")
unzip("TZ_GS_preds.zip", overwrite=T)

# stack grids
glist <- list.files(pattern="tif", full.names=T)
grids <- stack(glist)

# Geosurvey map widget ----------------------------------------------------
# render map
w <- leaflet() %>% 
  addProviderTiles(providers$OpenStreetMap.Mapnik) %>%
  addCircleMarkers(msos$lon, msos$lat, clusterOptions = markerClusterOptions())
w ## plot widget 

# save widget
saveWidget(w, 'TZ_MS.html', selfcontained = T)

# Data setup ---------------------------------------------------------------
# project MobileSurvey coords to grid CRS
msos.proj <- as.data.frame(project(cbind(msos$lon, msos$lat), "+proj=laea +ellps=WGS84 +lon_0=20 +lat_0=5 +units=m +no_defs"))
colnames(msos.proj) <- c("x","y")
msos <- cbind(msos, msos.proj)
coordinates(msos) <- ~x+y
projection(msos) <- projection(grids)

# extract gridded variables at GeoSurvey locations
msosgrid <- extract(grids, msos)
msdat <- as.data.frame(cbind(msos, msosgrid)) 
msdat <- na.omit(msdat) ## includes only complete cases
msdat <- msdat[!duplicated(msdat), ] ## removes any duplicates 

# Write output file -------------------------------------------------------
dir.create("Results", showWarnings=F)
write.csv(msdat, "./Results/TZ_msdat.csv", row.names = FALSE)
