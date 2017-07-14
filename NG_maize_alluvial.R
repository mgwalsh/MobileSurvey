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
download("https://www.dropbox.com/s/jt913s924li8ruz/NG_crop_scout_0717.csv.zip?raw=1", "OCP_crop_scout.csv", mode="wb")
crps <- read.table("OCP_crop_scout.csv", header=T, sep=",")

maize <- as.data.frame(table(crps$MZP, crps$SGP, crps$LGP, crps$RCP, crps$OCP, crps$LVS))
colnames(maize) <- c("Maize","Sorghum","Legume","Root","Other","Livestock","Freq")

# <alluvial> diagram ------------------------------------------------------
alluvial(maize[,1:6], freq=maize$Freq, border=NA,
         hide = maize$Freq < quantile(maize$Freq, 0.50),
         col=ifelse(maize$Maize == "Y", "red", "gray"))
