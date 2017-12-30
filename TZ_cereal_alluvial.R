# Alluvial diagrams of TZ cropping & cereal systems
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

# Data setup --------------------------------------------------------------
crps$CRP <- ifelse(crps$CCP == "Y" | crps$LCP =="Y" | crps$RCP == "Y" | crps$OCP == "Y", "Y", "N") ## croplands
crop <- crps[ which(crps$CRP == "Y"),] ## cropping systems subset
cers <- crps[ which(crps$CCP == "Y"),] ## cereal systems subset

# cropping systems frequency table
crplnd <- as.data.frame(table(crop$CCP, crop$LCP, crop$RCP, crop$OCP, crop$LVP))
colnames(crplnd) <- c("Cereal","Legume","Root","Other","Livestock","Freq")

# cereal systems frequency table
cereal <- as.data.frame(table(cers$MZP, cers$SGP, cers$RIP, cers$LCP, cers$RCP, cers$OCP, cers$LVP))
colnames(cereal) <- c("Maize","Sorghum","Rice","Legume","Root","Other","Livestock","Freq")

# <alluvial> diagram ------------------------------------------------------
# main cropland systems
alluvial(crplnd[,1:5], freq=crplnd$Freq, border=NA,
         hide = crplnd$Freq < quantile(crplnd$Freq, 0.5),
         col=ifelse(crplnd$Cereal == "Y", "red", "gray"))

# cereal systems only
alluvial(cereal[,1:7], freq=cereal$Freq, border=NA,
         hide = cereal$Freq < quantile(cereal$Freq, 0.5),
         col=ifelse(cereal$Maize == "Y", "red", "grey"))
