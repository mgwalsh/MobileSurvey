# Stacked predictions of Tanzania maize cropland distribution
# M. Walsh, September 2017

# Required packages
# install.packages(c("caret","randomForest","gbm","nnet","glmnet","plyr","doParallel","dismo")), dependencies = T)
suppressPackageStartupMessages({
  require(caret)
  require(randomForest)
  require(gbm)
  require(nnet)
  require(glmnet)
  require(plyr)
  require(doParallel)
  require(dismo)
})

# Data setup --------------------------------------------------------------
# Run this first: https://github.com/mgwalsh/MobileSurvey/blob/master/TZ_MS_data.R
rm(list=setdiff(ls(), c("msdat","grids","glist"))) ## scrub extraneous objects in memory

# set calibration/validation set randomization seed
seed <- 1385321
set.seed(seed)

# split data into calibration and validation sets
msIndex <- createDataPartition(msdat$MZP, p = 4/5, list = FALSE, times = 1)
ms_cal <- msdat[ msIndex,]
ms_val <- msdat[-msIndex,]

# MobileSurvey calibration labels
cp_cal <- ms_cal$MZP ## Maize present? (Y/N)

# Raster calibration features
gf_cal <- ms_cal[,12:52] ## grid covariates

# Random forest <randomForest> --------------------------------------------
# start doParallel to parallelize model fitting
mc <- makeCluster(detectCores())
registerDoParallel(mc)

# control setup
set.seed(1385321)
tc <- trainControl(method = "cv", classProbs = TRUE,
                   summaryFunction = twoClassSummary, allowParallel = T)

# model training
tg <- expand.grid(mtry=seq(1, 10, by=1))
CP.rf <- train(gf_cal, cp_cal,
               preProc = c("center","scale"),
               method = "rf",
               ntree = 501,
               metric = "ROC",
               tuneGrid = tg,
               trControl = tc)

# model outputs & predictions
print(CP.rf) ## ROC's accross tuning parameters
plot(varImp(CP.rf)) ## relative variable importance
confusionMatrix(CP.rf) ## cross-validation performance
cprf.pred <- predict(grids, CP.rf, type = "prob") ## spatial predictions

stopCluster(mc)

# Generalized boosting <gbm> ----------------------------------------------
# start doParallel to parallelize model fitting
mc <- makeCluster(detectCores())
registerDoParallel(mc)

# control setup
set.seed(1385321)
tc <- trainControl(method = "cv", classProbs = TRUE, summaryFunction = twoClassSummary,
                   allowParallel = T)

# model training
CP.gb <- train(gf_cal, cp_cal, 
               method = "gbm", 
               preProc = c("center", "scale"),
               trControl = tc,
               metric = "ROC")

# model outputs & predictions
print(CP.gb) ## ROC's accross tuning parameters
plot(varImp(CP.gb)) ## relative variable importance
confusionMatrix(CP.gb) ## cross-validation performance
cpgb.pred <- predict(grids, CP.gb, type = "prob") ## spatial predictions

stopCluster(mc)

# Neural network <nnet> ---------------------------------------------------
# start doParallel to parallelize model fitting
mc <- makeCluster(detectCores())
registerDoParallel(mc)

# control setup
set.seed(1385321)
tc <- trainControl(method = "cv", classProbs = TRUE,
                   summaryFunction = twoClassSummary, allowParallel = T)

# model training
CP.nn <- train(gf_cal, cp_cal, 
               method = "nnet",
               preProc = c("center","scale"), 
               trControl = tc,
               metric ="ROC")

# model outputs & predictions
print(CP.nn) ## ROC's accross tuning parameters
plot(varImp(CP.nn)) ## relative variable importance
confusionMatrix(CP.nn) ## cross-validation performance
cpnn.pred <- predict(grids, CP.nn, type = "prob") ## spatial predictions

stopCluster(mc)

# Regularized regression <glmnet> -----------------------------------------
# start doParallel to parallelize model fitting
mc <- makeCluster(detectCores())
registerDoParallel(mc)

# control setup
set.seed(1385321)
tc <- trainControl(method = "repeatedcv", repeats=5, classProbs = TRUE,
                   summaryFunction = twoClassSummary, allowParallel = T)

# model training
CP.rr <- train(gf_cal, cp_cal, 
               method = "glmnet",
               family = "binomial",
               preProc = c("center","scale"), 
               trControl = tc,
               metric ="ROC")

# model outputs & predictions
print(CP.rr) ## ROC's accross tuning parameters
plot(varImp(CP.rr)) ## relative variable importance
confusionMatrix(CP.rr) ## cross-validation performance
cprr.pred <- predict(grids, CP.rr, type = "prob") ## spatial predictions

stopCluster(mc)

# Model stacking setup ----------------------------------------------------
preds <- stack(1-cprf.pred, 1-cpgb.pred, 1-cpnn.pred, 1-cprr.pred)
names(preds) <- c("rf","gb", "nn","rr")
plot(preds, axes=F)

# extract model predictions
coordinates(ms_val) <- ~x+y
projection(ms_val) <- projection(preds)
mspred <- extract(preds, ms_val)
mspred <- as.data.frame(cbind(ms_val, mspred))

# stacking model validation labels and features
cp_val <- mspred$MZP ## subset validation labels
gf_val <- mspred[,53:56] ## subset validation features

# Model stacking ----------------------------------------------------------
# start doParallel to parallelize model fitting
mc <- makeCluster(detectCores())
registerDoParallel(mc)

# control setup
set.seed(1385321)
tc <- trainControl(method = "repeatedcv", repeats = 5, classProbs = TRUE, 
                   summaryFunction = twoClassSummary, allowParallel = T)

# model training
CP.st <- train(gf_val, cp_val,
               method = "glmnet",
               family = "binomial",
               metric = "ROC",
               trControl = tc)

# model outputs & predictions
print(CP.st)
confusionMatrix(CP.st)
plot(varImp(CP.st))
cpst.pred <- predict(preds, CP.st, type = "prob") ## spatial predictions
plot(1-cpst.pred, axes=F)

stopCluster(mc)

# Receiver-operator characteristics ---------------------------------------
# validation-set ROC
cp_pre <- predict(CP.st, gf_val, type="prob")
cp_val <- cbind(cp_val, cp_pre)
cpp <- subset(cp_val, cp_val=="Y", select=c(Y))
cpa <- subset(cp_val, cp_val=="N", select=c(Y))
cp_eval <- evaluate(p=cpp[,1], a=cpa[,1]) ## calculate ROC on test set
plot(cp_eval, 'ROC') ## plot ROC curve

# complete-set ROC
# extract model predictions
coordinates(msdat) <- ~x+y
projection(msdat) <- projection(preds)
mspred <- extract(preds, msdat)
mspred <- as.data.frame(cbind(msdat, mspred))
write.csv(msdat, "./Results/TZ_MZP_pred.csv", row.names = FALSE) ## write dataframe

# stacking model labels and features
cp_all <- mspred$MZP ## subset validation labels
gf_all <- mspred[,53:56] ## subset validation features

# ROC calculation
cp_pre <- predict(CP.st, gf_all, type="prob")
cp_all <- cbind(cp_all, cp_pre)
cpp <- subset(cp_all, cp_all=="Y", select=c(Y))
cpa <- subset(cp_val, cp_all=="N", select=c(Y))
cp_eall <- evaluate(p=cpp[,1], a=cpa[,1]) ## calculate ROC on test set
plot(cp_eall, 'ROC') ## plot ROC curve

# Generate cropland mask --------------------------------------------------
t <- threshold(cp_eval) ## calculate thresholds based on validation ROC
r <- matrix(c(0, t[,4], 0, t[,4], 1, 1), ncol=3, byrow=TRUE) ## set threshold value <prevalence>
mask <- reclassify(1-cpst.pred, r) ## reclassify stacked predictions
plot(mask, axes=F)

# Write prediction files --------------------------------------------------
cppreds <- stack(preds, 1-cpst.pred, mask)
names(cppreds) <- c("cprf","cpgb","cpnn","cprr","cpst","cpmk")
writeRaster(cppreds, filename="./Results/TZ_mzpreds_2017.tif", datatype="FLT4S", options="INTERLEAVE=BAND", overwrite=T)

# Prediction map widget ---------------------------------------------------
# ensemble prediction map 
pred <- 1-cpst.pred ## MobileSurvey ensemble probability

# set color pallette
pal <- colorBin("Greens", domain = 0:1) 

# render map
w <- leaflet() %>% 
  addProviderTiles(providers$OpenStreetMap.Mapnik) %>%
  addRasterImage(pred, colors = pal, opacity = 0.5) %>%
  addLegend(pal = pal, values = values(pred), title = "Maize prob")
w ## plot widget 

# save widget
saveWidget(w, 'TZ_MZ_prob.html', selfcontained = T)
