/************************************************************************************************/
/************************************** BEGIN: Introduction *************************************/
/************************************************************************************************/

/*
Rebekah Sander
Deliverable 10

Research Question: Does weight, age, years at the lower altitude and percent of the person's life 
                   at the lower altitude predict systolic blood pressure in mm of Mercury (mm/Hg)? 
alpha = 0.05                 
  
Unit of observation: One Person

Research Variables: 
   QUANTITATIVE  - Weight               What is the weight of          units: kg 
                                        this person?                  
                                   
                 - Age                  How old is this person?        units: years 
                                         

                 - Years at Low         How many years did this        units: years
                   Altitude             person live at a lower        
                                        altitude urban area?
                                       
                 - % Life               What percent of this           units: %
                                        person's life was spent
                                        at a lower altitude?
                  
                 
                 - Systolic             What is this person's          units: mm/Hg
                                        systolic blood pressure?

Determine hypothesis testing options for answering the question.
1. Multiple Linear Regression (Residuals are Normal and Homogeneous)
2. Loess (Residuals are Not Normal or Not Homogeneous)
3. Box Cox Transformations (To try making residuals normal)
*/

/************************************************************************************************/
/************************************** END: Introduction ***************************************/
/************************************************************************************************/



/************************************************************************************************/
/********************************** BEGIN: Import the data set **********************************/
/************************************************************************************************/

%web_drop_table(WORK.peru);

FILENAME REFFILE '/home/u62685438/sasuser.v94/stat3130/data/peru.xlsx';

PROC IMPORT DATAFILE=REFFILE
	DBMS=XLSX
	OUT=WORK.peru;
	GETNAMES=YES;
RUN;

PROC CONTENTS DATA=WORK.peru; RUN;

%web_open_table(WORK.peru);

/************************************************************************************************/
/*********************************** END: Import the data set ***********************************/
/************************************************************************************************/



/************************************************************************************************/
/********************************* BEGIN: Examining the data set ********************************/
/************************************************************************************************/

/*Keeping what we want*/
data work.peru;
	set work.peru (keep = Weight Age Years Systol);
	rename Years='Years at Low Altitude'n;
	rename Systol=Systolic;
run;

/* Check for and fix miscoding/missing values */
Proc Contents data=work.peru varnum;
run; 

proc freq data=work.peru;
tables Systolic Weight Age 'Years at Low Altitude'n;
run;

Proc Means data = work.peru MAXDEC=2 n mean stddev median Qrange RANGE min Q1 Q3 max;
	var Weight Age 'Years at Low Altitude'n Systolic; 
run;

/* Adding variable % Life */
data work.peru;
   set work.peru;
   '% Life'n = ('Years at Low Altitude'n / Age)*100; 
run;

/*Re-checking summary statistics with % Life*/
Proc Means data = work.peru MAXDEC=2 n mean stddev median Qrange RANGE min Q1 Q3 max;
	var Systolic Weight Age 'Years at Low Altitude'n '% Life'n; 
run;

/*
There were no NA, -1, 9999, period, or blank values initially. Data types read in correctly.
Re-checking statistics after the adding in variable also read in correctly.
*/

/************************************************************************************************/
/********************************** END: Examining the data set *********************************/
/************************************************************************************************/



/************************************************************************************************/
/******************************** BEGIN: Relationship of Variables ******************************/
/************************************************************************************************/

/* proc corr gets the correlation matrix*/
proc corr data=work.peru;
   var Systolic Weight Age 'Years at Low Altitude'n '% Life'n;
run;

/* proc sgscatter gets the scatterplot matrix */
proc sgscatter data=work.peru;
  matrix Systolic Weight Age 'Years at Low Altitude'n '% Life'n;
run;

/* 
Correlation Matrix: 
  Only the correlation between systolic and weight has a low p-value and is significant at 
  alpha = 0.05. When looking at the individual variables, only weight predicts systolic 
  blood pressure.
                    
Scatterplot Matrix:
  1. Systolic has a positive relationship with Weight
  2. Systolic has a positive relationship with Age
  3. Systolic has a negative relationship with Years at Low Altitude
  4. Systolic has a negative relationship with % Life
*/

/************************************************************************************************/
/******************************** END: Relationship of Variables ********************************/
/************************************************************************************************/



/************************************************************************************************/
/********************************** BEGIN: Assessing Normality **********************************/
/************************************************************************************************/

/* 
Proc Reg to run the full model to get the 9-grid plots to check homogeneity and normality.
id makes the x variables show in the prediction interval table.
Model is specifying our regression model with the y variable(systolic), 
and our x variables(weight, age, years at low altitude, and % life).
output out with residuals specified will add the residuals as a variable to the outfile dataframe.
*/
Proc Reg data=work.peru;
	id Weight Age 'Years at Low Altitude'n '% Life'n;
	Model Systolic = Weight Age 'Years at Low Altitude'n '% Life'n; 
	output Out=outfile residual= resid;
run;

/*proc univariate with the outfile dataframe allows us to assess normality on the residuals*/
title 'Normality Tests and QQ plot for the Residuals';
proc univariate data=outfile normaltest plots;  
	var resid;
title;

/*
  -H0: The residuals of systolic blood pressure are normally distributed
  -Ha: The residuals of systolic blood pressure are not normally distributed
  -𝛼=0.05
  
  From the 9-grid plots output by the regression, the residuals follow the agreement line for 
  normality pretty closely. In the output from proc univariate ran on residuals, we see that same 
  QQ plot as well as the tests for normality. All four normality tests say that the residuals are 
  not significantly different from normality.
*/

/************************************************************************************************/
/*********************************** END: Assessing Normality ***********************************/
/************************************************************************************************/



/************************************************************************************************/
/********************************* BEGIN: Assessing Homogeneity *********************************/
/************************************************************************************************/

/* 
Proc Reg to run the full model to get the 9-grid plots to check homogeneity and normality.
id makes the x variables show in the prediction interval table.
Model is specifying our regression model with the y variable(systolic), 
and our x variables(weight, age, years at low altitude, and % life).
output out with residuals specified will add the residuals as a variable to the outfile dataframe.
*/
Proc Reg data=work.peru;
	id Weight Age 'Years at Low Altitude'n '% Life'n;
	Model Systolic = Weight Age 'Years at Low Altitude'n '% Life'n; 
	output Out=outfile residual= resid;
run;

/*
  -H0: The residuals of weight, age, years at low altitude, and % life have equal variances.
  -Ha: The residuals of weight, age, years at low altitude, and % life have unequal variances.
  
  From the 9-grid plots output by the regression, the residuals are evenly spread between -10 and 10. 
  There are a few points outside of these bounds, but that is to be expected with our residuals 
  following a normal distribution. Additionally in the output, we see our standardized residuals 
  within -2 to +2 standard deviations and about 5% of our residuals are beyond these bounds.
*/

/************************************************************************************************/
/********************************** END: Assessing Homogeneity **********************************/
/************************************************************************************************/



/************************************************************************************************/
/******************************** BEGIN: Choosing Hypothesis Test *******************************/
/************************************************************************************************/

/*
Since the data is normal enough, homogeneous enough, and centered at 0 enough, we will perform 
the multiple linear regression analysis.

To perform multiple linear regression, we must
  1.) Perform the Global F Test 
  2.) Assess Multicollinearity
  3.) Find the best model
  
The level of significance used through testing will be 𝛼=0.05
*/

/************************************************************************************************/
/********************************* END: Choosing Hypothesis Test ********************************/
/************************************************************************************************/



/************************************************************************************************/
/***************************** BEGIN: Performing the Global F Test ******************************/
/************************************************************************************************/

/* 
Same code from normality and homogeneity
We include /VIF to get the variance inflation factor
*/
Proc Reg data=work.peru;
	id Weight Age 'Years at Low Altitude'n '% Life'n;
	Model Systolic = Weight Age 'Years at Low Altitude'n '% Life'n/ VIF; 
run;

/*
The null hypothesis is,
	H0: Weight, age, years at low altitude, and % life do not predict systolic blood pressure. 
The alternative hypothesis is,
	Ha: At least one of the variables--weight, age, years at low altitude, and % life--predict 
	    systolic blood pressure. 
	
The level of significance, α=0.05, tells us that 5% of the time the analysis will conclude that at 
least one of the variables predicts systolic blood pressure when none of the terms predict systolic 
blood pressure. 
*/

/*
Output of interest--Analysis of Variance Table and the table below.

Model F-Value: 12.61
      p-value: <0.0001
      
Adjusted R-squared: 0.5500
*/

/*
Output Interpretations

F-Statistic: The model variance (975.43203) is 12.61 times the within combination
             variance (77.34435).
P-value: There is a less than 0.01% chance of getting an F-value of 3.97 or more when weight, 
         age, years at low altitude, and % life do not predict systolic blood pressure.
Conclusion: Since less than 0.01% is less than 5%, we reject H0. We are 95% confident that at 
            least one of the variables(weight, age, years at low altitude, % life) predicts 
            systolic blood pressure.
*/

/************************************************************************************************/
/****************************** END: Performing the Global F Test *******************************/
/************************************************************************************************/



/************************************************************************************************/
/********************************** BEGIN: Multicollinearity ************************************/
/************************************************************************************************/

/* Same code from Global F Test--FULL MODEL with /VIF */
Proc Reg data=work.peru;
	id Weight Age 'Years at Low Altitude'n '% Life'n;
	Model Systolic = Weight Age 'Years at Low Altitude'n '% Life'n/ VIF; 
run;

/*
Output of interest--The third table down showing adjusted R-squared and the parameter estimates table.

Adjusted R-squared: 0.5500
*/

/*
Output Interpretations

-Adjusted R-squared = 0.5500. This is the same as the R-squared value from the Global F Test section.
-Age is negative (-0.95067) when it should be positive. Hence, there is multicollinearity.
-Highest p-value is age with 0.0050, further suggesting multicollinearity.
-Highest VIF is years at low altitude with 28.78739. Could be a candidate to drop
*/

/************************************************************************************************/
/************************************ END: Multicollinearity ************************************/
/************************************************************************************************/



/************************************************************************************************/
/******************************** BEGIN: Creating the Best Model ********************************/
/************************************************************************************************/

/* 1.Dropping age from the full model */
Proc Reg data=work.peru;
	id Weight 'Years at Low Altitude'n '% Life'n;
	Model Systolic = Weight 'Years at Low Altitude'n '% Life'n/ VIF; 
run;

/*
-Adjusted R-squared = 0.4468. This is a decrease, but not by too much.
-Highest p-value is Years at low altitude with 0.2819.
-Highest VIF is years at low altitude with 13.62958. 
*/


/* 2.Dropping years at a low altitude from the full model */
Proc Reg data=work.peru;
	id Weight Age '% Life'n;
	Model Systolic = Weight Age '% Life'n/ VIF; 
run;

/*
-Adjusted R-squared = 0.4446. This is also a decrease, but not by too much.
-Age is still negative when it should be positive.
-Highest p-value is age with 0.3120.
-Highest VIF is age with 1.33033, which is not too bad. 
*/


/* 3.Dropping age and years at a low altitude from the full model */
Proc Reg data=work.peru;
	id Weight '% Life'n;
	Model Systolic = Weight '% Life'n/ VIF; 
run;

/*
-Adjusted R-squared = 0.4438. This is also a decrease, but not by too much.
-For weight and % life--coefficients have the correct sign, p-values are low, 
 VIF scores are 1.09397 (near the lowest value of 1). 
 
-This is the best model. 
*/

/************************************************************************************************/
/******************************** END: Creating the Best Model **********************************/
/************************************************************************************************/



/************************************************************************************************/
/********************************* BEGIN: Best Model Explained **********************************/
/************************************************************************************************/

/*The best model*/
Proc Reg data=work.peru;
	id Weight '% Life'n;
	Model Systolic = Weight '% Life'n/ VIF; 
run;

/*
For weight,

Hypotheses:
  H0: Weight does not predict systolic blood pressure. The beta coefficient for weight is 0.
  Ha: Weight does predict systolic blood pressure. The beta coefficient for weight is  not 0. 
  Alpha: The level of significance, α=0.05, tells us that 5% of the time the analysis will 
          conclude that weight predicts systolic blood pressure when weight does not predict 
          systolic blood pressure. 
        
Model Interpretations:        
  t-statistic: The coefficient, 1.21686, is 5.21 standard errors to the right of the hypothesized
                beta of 0. 	
  p-value: There is less than a 0.01% chance of observing a t statistic of 5.21 or more in magnitude 
            when the beta coefficient for weight is 0.
  Conclusion: Since the p value (<0.0001) is less than the alpha of .05, we reject H0.
               We are 95% confident that weight is a good predictor of systolic blood pressure.

*/

/*
For % Life,

Hypotheses:
  H0: % Life does not predict systolic blood pressure. The beta coefficient for weight is 0.
  Ha: % Life does predict systolic blood pressure. The beta coefficient for weight is  not 0. 
  Alpha: The level of significance, α=0.05, tells us that 5% of the time the analysis will 
          conclude that % life predicts systolic blood pressure when % life does not predict 
          systolic blood pressure. 
        
Model Interpretations:        
  t-statistic: The coefficient, -0.26767, is 3.71 standard errors to the left of the hypothesized
                beta of 0. 	
  p-value: There is a 0.07% chance of observing a t statistic of 3.71 or less in magnitude 
            when the beta coefficient for weight is 0.
  Conclusion: Since the p value (0.0007) is less than the alpha of .05, we reject H0.
               We are 95% confident that % life is a good predictor of systolic blood pressure.

*/

/*
Conclusions about the best model:

BEST MODEL: Systolic = 60.89592 + 1.21686*Weight - 0.26767*% Life

Adjusted R-squared = 0.4438 
Interpretation: 44.38% of the variation in a person's systolic blood pressure can be explained by
                knowing the person's weight and knowing the percent of the person's life that was 
                spent living at a lower altitude.
*/

/************************************************************************************************/
/*********************************** END: Best Model Explained **********************************/
/************************************************************************************************/



/************************************************************************************************/
/********************************* BEGIN: Confidence Intervals **********************************/
/************************************************************************************************/

/*
Run THE BEST MODEL to get the confidence intervals for the coefficients. 
id makes the x-variable show in the prediction interval table
CLB gets the confidence intervals for the betas.
*/

Proc Reg data=work.peru;
	id Weight '% Life'n;
	Model Systolic = Weight '% Life'n/ CLB alpha=0.05; 
run;

/*
Output of interest--Parameter estimates table.

95% Confidence Limits
 -Weight: 0.74292 to 1.69080
 -% Life: -.41406 to -.12129
*/

/*
Output Interpretations

We are 95% confident for each 1 kg increase in the weight of a person, the person's systolic blood 
pressure will increase 0.74 to 1.69 mm/Hg on average. 

We are 95% confident that for each 1% increase in a persons percent of life spent at a lower altitude,
the person's systolic blood pressure will decrease 0.12 to 0.41 mm/Hg on average.
*/

/************************************************************************************************/
/********************************** END: Confidence Intervals ***********************************/
/************************************************************************************************/



/************************************************************************************************/
/************************************* BEGIN: Predictions ***************************************/
/************************************************************************************************/

/*
Estimate y values when X values are provided that are out of the data set. 
We can add the data in two steps,
 1) First data block: generate the new data with new x information.
 2) Second data block: attach the new data to the end of the original peru data set
*/
data work.peru_new;
input Weight Age 'Years at Low Altitude'n;
'% Life'n = ('Years at Low Altitude'n/Age)*100;
cards;
65 50 15
65 50 25
65 50 35
65 22 5
;
run;

data work.peru2;
set work.peru 
    work.peru_new;
run;


/* 
Make predictions from the FULL model for data values not in the original data set.
Add CLM and CLI to get predictions in the data set.
id makes the x-variable show in the prediction interval table.
CLM gets the confidence intervals for the mean.
CLI gets the confidence intervals for the specific individual.
*/
Proc Reg data=work.peru2;
id Weight Age 'Years at Low Altitude'n '% Life'n;
Model Systolic = Weight Age 'Years at Low Altitude'n '% Life'n/ CLM CLI alpha=0.05; 
run;

/*
Output of interest--Output Statistics table.

95% CL Mean
 Obs 40.) 119.1357 to 133.0153	
 Obs 41.) 121.2084 to 134.4985	
 Obs 42.) 119.8524 to 139.4105	
 
95% CL Predict
 Obs 40.) 106.9027 to 145.2482
 Obs 41.) 108.7854 to 146.9215
 Obs 42.) 109.2583 to 150.0045
*/

/*
Output Interpretations 

1. CLM: We are 95% confident that the true average systolic blood pressure for a person that is 65 kg, 
        50 years old, and has lived in a lower altitude urban area for 15 years is between
        119.1357 to 133.0153 mm/Hg.
   CLI: We are 95% confident that the actual systolic blood pressure for a specific person that is 65
        kg, 50 years old, and has lived in a lower altitude urban area for 15 years is between
        106.9027 to 145.2482 mm/Hg.
2. CLM: We are 95% confident that the true average systolic blood pressure for a person that is 65 kg, 
        50 years old, and has lived in a lower altitude urban area for 25 years is between
        121.2084 to 134.4985 mm/Hg.
   CLI: We are 95% confident that the actual systolic blood pressure for a specific person that is 65
        kg, 50 years old, and has lived in a lower altitude urban area for 25 years is between
        108.7854 to 146.9215 mm/Hg.
3. CLM: We are 95% confident that the true average systolic blood pressure for a person that is 65 kg, 
        50 years old, and has lived in a lower altitude urban area for 35 years is between
        119.8524 to 139.4105 mm/Hg.   
   CLI: We are 95% confident that the actual systolic blood pressure for a specific person that is 65
        kg, 50 years old, and has lived in a lower altitude urban area for 35 years is between
        109.2583 to 150.0045 mm/Hg.  
4. Using the full model and looking at the predicted systolic blood pressure for these three 
   observations, the longer the person of the same weight and age has been at the lower altitude, 
   the higher their systolic blood pressure in mm/Hg.
*/

/* 
Make predictions from the BEST model for data values not in the original data set.
Add CLM and CLI to get predictions in the data set.
id makes the x-variable show in the prediction interval table.
CLM gets the confidence intervals for the mean.
CLI gets the confidence intervals for the specific individual.
*/
Proc Reg data=work.peru2;
	id Weight '% Life'n;
	Model Systolic = Weight '% Life'n/ CLM CLI alpha=0.05; 
run;

/*
Output of interest--Output Statistics table.

95% CL Mean
 Obs 40.) 128.3439 to 135.5790	
 Obs 41.) 123.0358 to 130.1802	
 Obs 42.) 115.8161 to 126.6930	
 
95% CL Predict
 Obs 40.) 111.8051 to 152.1178
 Obs 41.) 106.4597 to 146.7562
 Obs 42.) 100.6932 to 141.8159
*/

/*
Output Interpretations 

1. CLM: We are 95% confident that the true average systolic blood pressure for a person that is 65 kg, 
        50 years old, and has lived in a lower altitude urban area for 15 years is between
        128.3439 to 135.5790 mm/Hg.
   CLI: We are 95% confident that the actual systolic blood pressure for a specific person that is 65
        kg, 50 years old, and has lived in a lower altitude urban area for 15 years is between
        111.8051 to 152.1178 mm/Hg.
2. CLM: We are 95% confident that the true average systolic blood pressure for a person that is 65 kg, 
        50 years old, and has lived in a lower altitude urban area for 25 years is between
        123.0358 to 130.1802 mm/Hg.
   CLI: We are 95% confident that the actual systolic blood pressure for a specific person that is 65
        kg, 50 years old, and has lived in a lower altitude urban area for 25 years is between
        106.4597 to 146.7562 mm/Hg.
3. CLM: We are 95% confident that the true average systolic blood pressure for a person that is 65 kg, 
        50 years old, and has lived in a lower altitude urban area for 35 years is between
        115.8161 to 126.6930 mm/Hg.   
   CLI: We are 95% confident that the actual systolic blood pressure for a specific person that is 65
        kg, 50 years old, and has lived in a lower altitude urban area for 35 years is between
        100.6932 to 141.8159 mm/Hg.  
4. Using the best model and looking at the predicted systolic blood pressure for these three 
   observations, the longer the person of the same weight and age has been at the lower altitude, 
   the lower their systolic blood pressure in mm/Hg.
*/

/*
Conclusion: Comparing (4.) between the full model and the best model, the best model shows
            what we would expect--systolic blood pressure decreases as you spend more of your 
            life at lower altitudes. Although this shows relationship, we want to use the 
            full model for predictions.
*/

/************************************************************************************************/
/************************************** END: Predictions ****************************************/
/************************************************************************************************/



/************************************************************************************************/
/************************************* BEGIN: Taking Action *************************************/
/************************************************************************************************/

/*
Suppose you have a specific Peruvian friend who is 65 kg, 22 years old and moved to the lower altitude
5 years ago. We are able to predict their specific systolic blood pressure by using the full model.
*/
Proc Reg data=work.peru2;
id Weight Age 'Years at Low Altitude'n '% Life'n;
Model Systolic = Weight Age 'Years at Low Altitude'n '% Life'n/ CLM CLI alpha=0.05; 
run;

/*
We are 95% confident that the actual systolic blood pressure for this specific person that
is 65 kg, 22 years old, and has lived in a lower altitude urban area for 5 years is between
117.9265 to 156.3963 mm/Hg. 
*/


/*
This analysis proves to be useful to doctors and even individuals when it comes to good health.
If an individual has high blood pressure there could be outside factors that cause that as we saw.
Further, an individual may find this useful when moving somewhere as they may need to live in more
urban, low altitude areas.
*/

/************************************************************************************************/
/*************************************** END: Taking Action *************************************/
/************************************************************************************************/


