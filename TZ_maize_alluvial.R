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
download("https://www.dropbox.com/s/vz6cxhsdrkznmkm/TZ_maize_system.csv.zip?raw=1", "TZ_maize_system.csv.zip", mode="wb")
unzip("TZ_maize_system.csv.zip", overwrite=T)
crps <- read.table("TZ_maize_system.csv", header=T, sep=",")

maize <- as.data.frame(table(crps$MZP, crps$SGP, crps$LGP, crps$RCP, crps$OCP, crps$LVS))
colnames(maize) <- c("Maize","Sorghum","Legume","Root","Other","Livestock","Freq")

# <alluvial> diagram ------------------------------------------------------
alluvial(maize[,1:6], freq=maize$Freq, border=NA,
         hide = maize$Freq < quantile(maize$Freq, 0.50),
         col=ifelse(maize$Maize == "Y", "red", "gray"))
