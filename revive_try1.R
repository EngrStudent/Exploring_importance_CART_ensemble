
#load libraries
library(randomForest) #for relatively fast importance estimation
library(pracma)     #for Savitzky-Golay smoothing (savgol)

#stage for reproducibility
set.seed(45627) 

#control variables
N_repeats_per_rate <- 300 #repeats per value of rate
N_samples_per_run  <- 300 #how many samples per run

#make rate variable
rate <- seq(from = 0, to = 1, by =0.01)

#for each rate, for each variable, we compute
#    5th percentile, median, 95th percentile
rate_store <- data.frame(matrix(0,nrow=N_repeats_per_rate,ncol=3*3+1))




for (i in 1:length(rate)){
     
     #what is this rate
     this_rate <- rate[i]
     
     #stage for inner loop
     run_store <- data.frame(matrix(0,nrow=length(rate),ncol=3))
     #make importance samples
     for (j in 1:N_samples_per_run){
          
          #make values x1, x2, x3
          x1 <- runif(n = N_samples_per_run)
          x2 <- runif(n = N_samples_per_run)
          x3 <- runif(n = N_samples_per_run)
          x4 <- runif(n = N_samples_per_run) 
          
          sw <- rbinom(n = N_samples_per_run, size = 1, prob = this_rate)
          
          #make y
          y <- x1 + sw*x2 + 0*x3 + (1-sw)*x4
          
          
          #populate data frame
          mydata <- data.frame(x1,x2,x3,y)
          
          
          #fit via random forest
          my_rf_fit <- randomForest(y~.,
                                     data = mydata, 
                                     ntree = 300)
          
          
          #compute variable importance
          run_store[j,] <- importance(my_rf_fit)
          
          #store
          
     }
     
     #compute summary values and store
     rate_store[i, 1] <- this_rate
     
     temp <- quantile(x = run_store[,1], probs = c(0.05, 0.5, 0.95))
     rate_store[i, 2] <- temp[1] 
     rate_store[i, 3] <- temp[2] 
     rate_store[i, 4] <- temp[3] 
     
     temp <- quantile(x = run_store[,2], probs = c(0.05, 0.5, 0.95))
     rate_store[i, 5] <- temp[1] 
     rate_store[i, 6] <- temp[2] 
     rate_store[i, 7] <- temp[3] 
     
     temp <- quantile(x = run_store[,3], probs = c(0.05, 0.5, 0.95))
     rate_store[i, 8] <- temp[1] 
     rate_store[i, 9] <- temp[2] 
     rate_store[i, 10] <- temp[3] 
}

#this part is to save redo-redo-redo time when making markdown
names(rate_store) <- c("rate",
                       "LCL_x1",
                       "Med_x1",
                       "UCL_x1",
                       "LCL_x2",
                       "Med_x2",
                       "UCL_x2",
                       "LCL_x3",
                       "Med_x3",
                       "UCL_x3")

rate_store <- rate_store[1:length(rate),]
#write it
write.csv(x = rate_store, file = "my_rate_store.csv")

rm(list=ls())

#read it
rate_store <- read.csv("my_rate_store.csv")
rate_store <- rate_store[,-1]
rate_store <- rate_store[c(1:101),]

rate <- rate_store[,1]
#so how do we print it?

for (i in 1:length(rate)){
     
     # s_max <- sum(rate_store[i,c(3,6,9)])
     s_max <- sum(rate_store[i,c(3)])
     s_min <- 0
     
     rate_store[i,2] <- ( rate_store[i,2] - s_min)/(s_max-s_min)
     rate_store[i,3] <- ( rate_store[i,3] - s_min)/(s_max-s_min)
     rate_store[i,4] <- ( rate_store[i,4] - s_min)/(s_max-s_min)
     
     rate_store[i,5] <- ( rate_store[i,5] - s_min)/(s_max-s_min)
     rate_store[i,6] <- ( rate_store[i,6] - s_min)/(s_max-s_min)
     rate_store[i,7] <- ( rate_store[i,7] - s_min)/(s_max-s_min)
     
     rate_store[i,8] <- ( rate_store[i,8] - s_min)/(s_max-s_min)
     rate_store[i,9] <- ( rate_store[i,9] - s_min)/(s_max-s_min)
     rate_store[i,10] <- ( rate_store[i,10] - s_min)/(s_max-s_min)
}

x_range <- c(min(rate),max(rate))
y_range <- c(-0.05,1.25)

plot(rate_store$rate,  rate_store$Med_x1, 
     xlim=x_range, ylim=y_range,
     col="Green", pch=19)
lines(smooth.spline(rate,rate_store$LCL_x1,spar = 0.8), col="Green")
lines(smooth.spline(rate,rate_store$UCL_x1,spar = 0.8), col="Green")

points(rate_store$rate, rate_store$Med_x2, col="Blue", pch=19)
lines(smooth.spline(rate,rate_store$LCL_x2,spar = 0.8), col="Blue")
lines(smooth.spline(rate,rate_store$UCL_x2,spar = 0.8), col="Blue")

points(rate_store$rate, rate_store$Med_x3, col="Red",  pch=19)
lines(smooth.spline(rate,rate_store$LCL_x3,spar = 0.8), col="Red")
lines(smooth.spline(rate,rate_store$UCL_x3,spar = 0.8), col="Red")
grid()
