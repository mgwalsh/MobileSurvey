# Tanzania cropping system productivity indicators
# M. Walsh, June 2017

require(downloader)
require(rgdal)
require(raster)
require(quantreg)

# Data setup --------------------------------------------------------------
# Create a data folder in  your current working directory
dir.create("TZ_npp", showWarnings=F)
setwd("./TZ_npp")

# Download
# MobileSurvey data
download("https://www.dropbox.com/s/vz6cxhsdrkznmkm/TZ_maize_system.csv.zip?raw=1", "TZ_maize_system.csv.zip", mode="wb")
unzip("TZ_maize_system.csv.zip", overwrite=T)
crps <- read.table("TZ_maize_system.csv", header=T, sep=",")

# Productivity grids (NPP parameters & RUE)
download("https://www.dropbox.com/s/hrnkbpkabt3a5kj/TZ_npp.zip?raw=1", "TZ_npp.zip", mode="wb")
unzip("TZ_npp.zip", overwrite=T)
glist <- list.files(pattern="tif", full.names=T)
grids <- stack(glist)

# Overlay with gridded covariates -----------------------------------------
# Project survey coords to grid CRS
crps.proj <- as.data.frame(project(cbind(crps$lon, crps$lat), "+proj=laea +ellps=WGS84 +lon_0=20 +lat_0=5 +units=m +no_defs"))
colnames(crps.proj) <- c("x","y") ## laea coordinates
crps <- cbind(crps, crps.proj)
coordinates(crps) <- ~x+y
projection(crps) <- projection(grids)

# Extract gridded variables at MobileSurvey locations
crpsgrid <- extract(grids, crps)
crps <- as.data.frame(crps)
crps <- cbind.data.frame(crps, crpsgrid)
crps <- unique(na.omit(crps)) ## includes only unique & complete records

# Quantile regressions ----------------------------------------------------
# Net Primary Productivity (NPP, t/ha yr)
NPP <- rq(I(NPP*10)~MZP+SGP+LGP+RCP+OCP+LVS, tau=c(0.10,0.5,0.9), data=crps)
print(NPP)

# Mean Annual Rainfall (MAP, mm/yr)
crps$MAP <- ifelse(crps$MAP==0, NA, crps$MAP)
MAP <- rq(MAP~MZP+SGP+LGP+RCP+OCP+LVS, tau=c(0.10,0.5,0.9), data=crps)
print(MAP)

# Rain Use Efficiency (NPP/MAP)
crps$RUE <- (crps$NPPa*10000)/crps$MAP
RUE <- rq(RUE~MZP+SGP+LGP+RCP+OCP+LVS, tau=c(0.10,0.5,0.9), data=crps)
print(RUE)
