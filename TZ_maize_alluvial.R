# Alluvial diagram of TZ maize cropping systems
# M. Walsh, February 2016

# install alluvial package
# require(devtools)
# install_github("mbojan/alluvial")

require(downloader)
require(alluvial)

# Data setup --------------------------------------------------------------
# Create a data folder in  your current working directory
dir.create("TZ_data", showWarnings=F)
setwd("./TZ_data")

# Download
download("https://www.dropbox.com/s/5io90qtmwdzewmi/TZ_crop_scout.csv?dl=0", "TZ_crop_scout.csv", mode="wb")
crps <- read.table("TZ_crop_scout.csv", header=T, sep=",")

maize <- as.data.frame(table(crps$Maize, crps$Sorghum, crps$Legume, crps$Root, crps$Other, crps$Livestock))
colnames(maize) <- c("Maize","Sorghum","Legume","Root","Other","Livestock","Freq")

# <alluvial> diagram ------------------------------------------------------
alluvial(maize[,1:6], freq=maize$Freq, border=NA,
         hide = maize$Freq < quantile(maize$Freq, 0.75),
         col=ifelse(maize$Maize == "Yes", "red", "gray"))
