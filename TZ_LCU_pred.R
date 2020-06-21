# Tanzania GS/MS-L3 land cover/use (LCU) predictions
# M. Walsh, June 2020

# Required packages
# install.packages(c("devtools","caret","MASS","plyr","doParallel","dismo")), dependencies=T)
suppressPackageStartupMessages({
  require(devtools)
  require(caret)
  require(MASS)
  require(plyr)
  require(doParallel)
  require(dismo)
})

# Data setup --------------------------------------------------------------
rm(list=setdiff(ls(), c("msdat","grids","glist"))) ## scrub extraneous objects in memory
msdat <- msdat[complete.cases(msdat[ ,c(7:60)]),] ## removes incomplete cases