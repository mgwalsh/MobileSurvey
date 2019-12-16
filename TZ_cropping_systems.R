# Tanzania GS/MS-L3 cropping systems models
# M. Walsh, December 2019

# install.packages(c("downloader","rgdal","raster","arm","dismo")), dependencies=T)
suppressPackageStartupMessages({
  require(downloader)
  require(rgdal)
  require(raster)
  require(arm)
  require(dismo)
})
rm(list = ls())

# Data downloads -----------------------------------------------------------
# Create a data folder in your current working directory
dir.create("TZ_L3", showWarnings=F)
setwd("./TZ_L3")
dir.create("Results", showWarnings = F)

# MobileSurvey data (long format)
download("https://osf.io/4vrq3?raw=1", "TZ_mspreds.csv.zip", mode="wb")
unzip("TZ_mspreds.csv.zip", overwrite=T)
msos <- read.table("TZ_mspreds.csv", header=T, sep=",")

# download GADM-L3 shapefile (courtesy: http://www.gadm.org)
download("https://www.dropbox.com/s/bhefsc8u120uqwp/TZA_adm3.zip?raw=1", "TZA_adm3.zip", mode = "wb")
unzip("TZA_adm3.zip", overwrite = T)
shape <- shapefile("TZA_adm3.shp")

# Data setup --------------------------------------------------------------
# attach GADM-L3 admin unit names from shape
coordinates(msos) <- ~lon+lat
projection(msos) <- projection(shape)
gadm <- msos %over% shape
msos <- as.data.frame(msos)
msos <- cbind(gadm[ ,c(5,7,9)], msos)
colnames(msos)[1:3] <- c("region","district","ward")

# Mixed models ------------------------------------------------------------
# main model
py0 <- glmer(py~stprob+(stprob|ctype), family=binomial(link="logit"), data=msos)
summary(py0)
msos$score0 <- fitted(py0)

# Small Area Estimate model
py1 <- glmer(py~stprob+(stprob|ctype)+(1|region), family=binomial(link="logit"), data=msos)
summary(py1)
msos$score1 <- fitted(py1)
write.csv(msos, "./Results/msos_2019.csv", row.names=F)
