# Alluvial diagram of TZ cereal cropping systems
# M. Walsh, December 2017

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
download("https://www.dropbox.com/s/3q5i7km8ejpg1p6/TZ_cereal_system.csv.zip?raw=1", "TZ_cereal_system.csv.zip", mode="wb")
unzip("TZ_cereal_system.csv.zip", overwrite=T)
crps <- read.table("TZ_cereal_system.csv", header=T, sep=",")

# extract frequency table
cereal <- as.data.frame(table(crps$CCP, crps$MZP, crps$SGP, crps$RIP, crps$LCP, crps$RCP, crps$OCP, crps$LVP))
colnames(cereal) <- c("Cereal","Maize","Sorghum","Rice","Legume","Root","Other","Livestock","Freq")

# <alluvial> diagram ------------------------------------------------------
alluvial(cereal[,1:8], freq=cereal$Freq, border=NA,
         hide = cereal$Freq < quantile(cereal$Freq, 0.975),
         col=ifelse(cereal$Cereal == "Y", "red", "gray"))
