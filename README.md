Variable Importance Metric Science
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

How to start? (method)
----------------------

#### First thoughts

-   Lots of folks like additive noise. They assume it is additive.
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

Imo a forest should be defined a decent full-pack hiking distance for a human at around 20 miles per day squared, or 400 square miles or 5180 hectares. I combine that with [this](https://www.quora.com/How-many-trees-are-required-to-make-forest) which says each hectare should have no less than 100 trees, to suggest a "real" forest should have about 518000, or about half a million trees. I guess we are making random groves or random orchards, which I hope is not a contradiction of terms.

#### Therefore:

-   "rate" will sweep from 0% to 100% in steps of 1%
-   for each value of "rate" there will be 300 repeats of the simulate-estimate process for importance.
-   for each simulate-estimate there will be 300 rows of x1, x2, x3, and y generated and fit.

Execution
---------

#### Stage for run

#### Main Loop

At this point we have a matrix that is 300 rows by 9 columns where each row a rate, and each column is a quantile of the three input variables.

This is an R Markdown format used for publishing markdown documents to GitHub. When you click the **Knit** button all R code chunks are run and a markdown file (.md) suitable for publishing to GitHub is generated.



You can also embed plots, for example:

![](revive_try1_files/figure-markdown_github/pressure-1.png)

Note that the `echo = FALSE` parameter was added to the code chunk to prevent printing of the R code that generated the plot.
