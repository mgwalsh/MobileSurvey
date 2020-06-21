# Tanzania MobileSurvey 250m resolution data setup 
# M. Walsh, December 2019

# Required packages --------------------------------------------------------
# install.packages(c("downloader","rgdal","raster")), dependencies=T)
suppressPackageStartupMessages({
  require(downloader)
  require(rgdal)
  require(raster)
})

# Data downloads -----------------------------------------------------------
# set working directory
dir.create("TZ_ML", showWarnings=F)
setwd("./TZ_ML")
dir.create("Results", showWarnings = F)

# download MobileSurvey data
download("https://osf.io/phu4b?raw=1", "TZ_msdat_2019.csv.zip", mode="wb")
unzip("TZ_msdat_2019.csv.zip", overwrite = T)
msdat <- read.table("TZ_msdat_2019.csv", header=T, sep=",")

# download GADM-L3 shapefile (courtesy: http://www.gadm.org)
download("https://www.dropbox.com/s/bhefsc8u120uqwp/TZA_adm3.zip?raw=1", "TZA_adm3.zip", mode = "wb")
unzip("TZA_adm3.zip", overwrite = T)
shape <- shapefile("TZA_adm3.shp")

# download MobileSurvey predictions
download("https://osf.io/ec52h?raw=1", "TZ_cs_preds_2019.zip", mode = "wb")
unzip("TZ_cs_preds_2019.zip", overwrite = T)
glist <- list.files(pattern="tif", full.names = T)
grids <- stack(glist)

# Data setup --------------------------------------------------------------
# attach GADM-L3 admin unit names from shape
coordinates(msdat) <- ~lon+lat
projection(msdat) <- projection(shape)
gadm <- msdat %over% shape
msdat <- as.data.frame(msdat)
msdat <- cbind(gadm[ ,c(5,7,9)], msdat)
colnames(msdat)[1:3] <- c("region","district","ward")

# project MobileSurvey coords to grid CRS
msdat.proj <- as.data.frame(project(cbind(msdat$lon, msdat$lat), "+proj=laea +ellps=WGS84 +lon_0=20 +lat_0=5 +units=m +no_defs"))
colnames(msdat.proj) <- c("x","y")
msdat <- cbind(msdat, msdat.proj)
coordinates(msdat) <- ~x+y
projection(msdat) <- projection(grids)

# extract gridded variables at MobileSurvey locations
msdatgrid <- extract(grids, msdat)
msdat <- as.data.frame(cbind(msdat, msdatgrid)) 

# Write output files ------------------------------------------------------
write.csv(msdat, "./Results/TZ_mspreds.csv", row.names = F)
