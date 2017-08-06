Variable Importance Metric Science (draft)
================

Why do it? (motivation)
-----------------------

The two most common Classification and Regression Tree based ensembles are the pure parallel (random forest) and pure serial (gradient boosted tree) ensembles.  A strong understanding of variable importance can inform better execution of variable selection.  It might also lead to more effective splitting, coupling, and aggregating approaches.

I wanted to understand what the term "Variable Importance", from random forests means in a way that was more intuitive to me: "probability of contribution". I needed a framework to engage some relevant questions that I regularly ask myself.

Questions:
- If something has twice the importance, does it contribute twice as much?
- Is there a threshold of importance below which a contributing variable is indistinguishable from random?
- How does this work for different "breeds" of importance like Z vs. Gini?
- When I use a library like ["Boruta"](https://cran.r-project.org/web/packages/Boruta/Boruta.pdf), [h2o](https://cran.r-project.org/web/packages/h2o/h2o.pdf), or the canonical [randomForest](https://cran.r-project.org/web/packages/randomForest/randomForest.pdf) what does the output really mean?
- There are typically 3 versions of importance: raw, raw over max, and raw over sum.  Is there one of these that is more useful than others?  

How to start? (method)
----------------------

#### First thoughts

-   Lots of folks like additive noise. They assume it is additive.  Let's look at additive noise.
-   Random number generators are pretty good, and stochastic simulations can be a way to get at the "physics" without presuming (much) of a model.
-   the 95% confidence interval is a window within which, in theory, 90% of data should reside. The likelihood of finding a sample above the upper 95% level or below the lower 95% level should happen something near or below 5% of the time.

#### Rough Plan

1.  make 3 input variables,
    -   one that is "always important" (x1)
    -   one whose importance (aka rate) is known, and that much of the "time" informs output (x2)
    -   one that is "never important" (x3)

2.  at each "row", randomly generate values for x1, x2, and x3, then make an output variable (y) that is the sum of x1 all the time, x2 for a rate-th part of the time, and x3 never.
3.  use a random forest to relate x1, x2, and x3 to y, and then determine variable importance for the inputs.

#### More thoughts:

-   If the rate were swept from 0% to 100% then I could look at how importance of x2 compares to x1 and x3 and get a sense of what it means.
-   The stepsize of the sweep should be small enough that the trend is defined and large enough that it is reasonably quick.
-   I would have to make asure that I repeated the process hundreds of times at each fixed value of rate to make sure my mean was good, and to make sure that my upper and lower confidence levels were relatively stable and high quality.
-   I know that the lower 95% binomial confidence interval for 300 of 300 samples is below 1%, so I will use this. There will be 300 samples of importance per value of rate. There will be 300 samples of x1, x2, x3, and y for each estimation of importance.
-   For x2, if I substitute the value with "0" when I want it to not count in importance, then it will still be participating, so we have to replace its position in the sum with a different random value.
-   I find 50 to 100 trees is often plenty, but random forests don't over-fit, so I'm going to also use 300 trees per forest.
-   If there is a particular analytic form that fits the mean of the Importance it might point to how importance relates to spliltting and aggregation.

Imo a forest should be defined as a decent, full-pack, hiking distance for a human at around 20 miles per day squared, or 400 square miles or 5180 hectares. I combine that with [this](https://www.quora.com/How-many-trees-are-required-to-make-forest) which says each hectare should have no less than 100 trees, to suggest a "real" forest should have about 518000, or about half a million trees. I guess we are making random groves or random orchards, which I hope is not a contradiction of terms.

#### Therefore:

-   "rate" will sweep from 0% to 100% in steps of 1%
-   for each value of "rate" there will be 300 repeats of the simulate-estimate process for importance.
-   for each simulate-estimate there will be 300 rows of x1, x2, x3, and y generated and fit.

Execution
---------

#### Stage for run
```{r, echo=TRUE, message=FALSE, collapse=TRUE}
#load libraries
library(randomForest) #for relatively fast importance estimation

#stage for reproducibility
set.seed(45627) 

#control variables
N_repeats_per_rate <- 300 #repeats per value of rate
N_samples_per_run  <- 300 #how many samples per run

#make rate variable
rate <- seq(from = 0, to = 1, by =0.01)

#for each rate, for each variable, we compute
#    5th percentile, median, 95th percentile
rate_store <- data.frame(matrix(0,nrow=length(rate),ncol=3*3+1))
```


#### Main Loop

```{r, echo=TRUE, message=FALSE}

for (i in 1:length(rate)){
     
     #what is this rate
     this_rate <- rate[i]
     
     #stage for inner loop
     run_store <- data.frame(matrix(0,nrow=N_repeats_per_rate,ncol=3))
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
```

At this point we have a matrix that is 300 rows by 9 columns where each row a rate, and each column is a quantile of the three input variables.

Here is a plot of it.

```{r Importance_plot, echo=FALSE}
x_range <- c(min(rate),max(rate))
y_range <- c(-0.05,1.25)

plot(rate_store$rate,  rate_store$Med_x1, 
     xlim=x_range, ylim=y_range,
     col="Green", pch=19)
lines(smooth.spline(rate,rate_store$LCL_x1,spar = 0.8), col="Green")
lines(smooth.spline(rate,rate_store$UCL_x1,spar = 0.8), col="Green")

points(rate_store$rate, rate_store$Med_x2, col="Blue", pch=19)
lines(smooth.spline(rate,z-_store$LCL_x2,spar = 0.8), col="Blue")
lines(smooth.spline(rate,rate_store$UCL_x2,spar = 0.8), col="Blue")

points(rate_store$rate, rate_store$Med_x3, col="Red",  pch=19)
lines(smooth.spline(rate,rate_store$LCL_x3,spar = 0.8), col="Red")
lines(smooth.spline(rate,rate_store$UCL_x3,spar = 0.8), col="Red")
grid()
```

[Image:](https://github.com/EngrStudent/Exploring_importance_CART_ensemble_part1/blob/master/Rplot.png)
 

Some observations can be made at this point about "cross-overs".  
- When the upper control limit (UCL) of the varying importance variable starts being larger than the UCL of the zero-value variable, then I call it "initial emergence".  I think this is the first detection of non-zero importance. If I was trying to squeeze blood from a stone, I would look at the upper confidence levels, the right tails, to make a comparison.  
- If the mean importance for a variable value term was larger than the UCL for zero value term, what I call "clear emergence", then the mean importance stops leading to false negative dispositions.  
- If Lower confidence limit (LCL) of variable value term is greater than the UCL of the zero value term, then it is completely emergede from the shadow of the zero value term.

- When the UCL of the varying value term is equal to the LCL of the 100% value term, then we start entering a region of ambiquous max-value.  
