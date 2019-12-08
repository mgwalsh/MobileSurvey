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

# download MobileSurvey data
download("https://osf.io/t6h97?raw=1", "TZ_crop_scout_2019.csv.zip", mode="wb")
unzip("TZ_crop_scout_2019.csv.zip", overwrite = T)
msos <- read.table("TZ_crop_scout_2019.csv", header=T, sep=",")

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
coordinates(msos) <- ~lon+lat
projection(msos) <- projection(shape)
gadm <- msos %over% shape
msos <- as.data.frame(msos)
msos <- cbind(gadm[ ,c(5,7,9)], geos)
colnames(msos) <- c("region","district","ward","survey","time","id","observer","lat","lon","BP","CP","WP","rice","bloc","cgrid","BIC")
# extract gridded variables at MobileSurvey locations
msosgrid <- extract(grids, msos)
msdat <- as.data.frame(cbind(msos, msosgrid)) 
msdat <- na.omit(msdat) ## includes only complete cases
msdat <- msdat[!duplicated(msdat), ] ## removes any duplicates 

# Write output file -------------------------------------------------------
dir.create("Results", showWarnings=F)
write.csv(msdat, "./Results/TZ_msdat.csv", row.names = F)
