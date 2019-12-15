# Tanzania MobileSurvey 250m resolution data setup 
# M. Walsh, December 2019

# Required packages --------------------------------------------------------
# install.packages(c("downloader","rgdal","raster","leaflet","htmlwidgets")), dependencies=T)
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
dir.create("Results", showWarnings = F)

# download MobileSurvey data
download("https://osf.io/phu4b?raw=1", "TZ_msdat_2019.csv.zip", mode="wb")
unzip("TZ_msdat_2019.csv.zip", overwrite = T)
msdat <- read.table("TZ_msdat.csv", header=T, sep=",")

# download GADM-L3 shapefile (courtesy: http://www.gadm.org)
download("https://www.dropbox.com/s/bhefsc8u120uqwp/TZA_adm3.zip?raw=1", "TZA_adm3.zip", mode = "wb")
unzip("TZA_adm3.zip", overwrite = T)
shape <- shapefile("TZA_adm3.shp")

# download Grids (note this is a ~1Gb download)
download("https://osf.io/ke5ya?raw=1", "TZ_250m_2019.zip", mode = "wb")
unzip("TZ_250m_2019.zip", overwrite = T)
glist <- list.files(pattern="tif", full.names = T)
grids <- stack(glist)

# Data setup --------------------------------------------------------------
# attach GADM-L3 admin unit names from shape
coordinates(msdat) <- ~lon+lat
projection(msdat) <- projection(shape)
gadm <- msdat %over% shape
msdat <- as.data.frame(msdat)
msdat <- cbind(gadm[ ,c(5,7,9)], msdat)
colnames(msos)[1:3] <- c("region","district","ward")

# project MobileSurvey coords to grid CRS
msos.proj <- as.data.frame(project(cbind(msos$lon, msos$lat), "+proj=laea +ellps=WGS84 +lon_0=20 +lat_0=5 +units=m +no_defs"))
colnames(msos.proj) <- c("x","y")
msos <- cbind(msos, msos.proj)
coordinates(msos) <- ~x+y
projection(msos) <- projection(grids)

# extract gridded variables at MobileSurvey locations
msosgrid <- extract(grids, msos)
msdat <- as.data.frame(cbind(msos, msosgrid)) 

# Write output files ------------------------------------------------------
write.csv(msdat, "./Results/TZ_msdat.csv", row.names = F)

