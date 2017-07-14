# Alluvial diagram of NG maize cropping systems
# M. Walsh, April 2016

# install alluvial package
# require(devtools)
# install_github("mbojan/alluvial")

require(downloader)
require(alluvial)

# Data setup --------------------------------------------------------------
# Create a data folder in  your current working directory
dir.create("NG_data", showWarnings=F)
setwd("./NG_data")

# Download
download("https://www.dropbox.com/s/jd3gd4qifoknuqb/OCP_crop_scout.csv?raw=1", "OCP_crop_scout.csv", mode="wb")
crps <- read.table("OCP_crop_scout.csv", header=T, sep=",")

maize <- as.data.frame(table(crps$Maize, crps$Legume, crps$Root, crps$Other, crps$Livestock))
colnames(maize) <- c("Maize","Legume","Root","Other","Livestock","Freq")

# <alluvial> diagram ------------------------------------------------------
alluvial(maize[,1:5], freq=maize$Freq, border=NA,
         hide = maize$Freq < quantile(maize$Freq, 0.50),
         col=ifelse(maize$Maize == "Yes", "red", "gray"))
