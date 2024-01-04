/************************************************************************************************/
/************************************** BEGIN: Introduction *************************************/
/************************************************************************************************/

/*
Rebekah Sander
Deliverable 9: Testing the centers of the amount spent on wine as predicted by
               marital status and education level.

Research Question: Does marital status and education level affect how much consumers spend on wine? 
alpha =.01                 
  
Unit of observation: Customer

Research Variables: 
   Categorical  -Marital Status      What is the customer's      levels: Married, Divorced, Together,
                                     relationship status?              Single, Widow
                                   
                -Education Level     What is the customer's      levels: Graduation, PhD, Master
                                     level of education?  

  Quantitative  -Wine Purchase       How much did the customer   units: USD
                                     spend on wine in the last 
                                     two years?

Determine hypothesis testing options for answering the question.
1. Two-Way ANOVA on Data (Normal and Homogeneous)
2. Two-Way ANOVA on Ranks (Not Normal or Not Homogeneous)
3. Transformations (To try making data normal)
*/

/************************************************************************************************/
/************************************** END: Introduction ***************************************/
/************************************************************************************************/



/************************************************************************************************/
/********************************** BEGIN: Import the data set **********************************/
/************************************************************************************************/

%web_drop_table(WORK.marketing);

FILENAME REFFILE '/home/u62685438/sasuser.v94/stat3130/data/marketing.xlsx';

PROC IMPORT DATAFILE=REFFILE
	DBMS=XLSX
	OUT=WORK.marketing;
	GETNAMES=YES;
RUN;

PROC CONTENTS DATA=WORK.marketing; RUN;

%web_open_table(WORK.marketing);

/************************************************************************************************/
/*********************************** END: Import the data set ***********************************/
/************************************************************************************************/



/************************************************************************************************/
/********************************* BEGIN: Examining the data set ********************************/
/************************************************************************************************/

/*Keeping what we want*/
data work.marketing;
	set work.marketing (keep = Marital_Status Education MntWines);
	rename Marital_Status='Marital Status'n;
	rename Education='Education Level'n;
	rename MntWines = 'Wine Purchase'n;
run;

/* Check for and fix miscoding/missing values */
Proc Contents data=work.marketing varnum;
run; 

PROC FREQ DATA=WORK.marketing;
TABLE 'Marital Status'n 'Education Level'n;
run;

Proc Means data = work.marketing MAXDEC=2 n mean stddev median Qrange RANGE min Q1 Q3 max;
	var 'Wine Purchase'n; 
run;

/* 
Deleting levels for marital status: YOLO, Absurd, Alone
Deleting levels for education level: Basic, 2n Cycle
*/
data work.marketing;
   set work.marketing;
   where 'Marital Status'n not in ("YOLO", "Absurd", "Alone") 
         and 'Education Level'n not in ("Basic", "2n Cycle"); 
run;

/*Re-checking levels for marital status and education level*/
PROC FREQ DATA=WORK.marketing;
TABLE 'Marital Status'n 'Education Level'n;
run;

/*Bivariate Analysis*/
PROC FREQ data=work.marketing;
tables 'Marital Status'n*'Education Level'n;
run;

/*
There were no NA or -1 or 9999 values initially. Data types read in correctly.
Re-checking levels after the deletions also read in correctly with no missing values.
*/

/************************************************************************************************/
/********************************** END: Examining the data set *********************************/
/************************************************************************************************/



/************************************************************************************************/
/********************************** BEGIN: Assessing Normality **********************************/
/************************************************************************************************/

/*Using proc univariate with normaltest and plots to check sample size, normality tests, & QQ plots*/
proc univariate data=work.marketing normaltest plots;
class 'Marital Status'n 'Education Level'n;
var 'Wine Purchase'n;
run;

/*
  -H0: The data came from a population where the wine purchases are normally distributed
  -Ha: The data came from a population where the wine purchases are not normally distributed.
  -𝛼=0.01
  
  -All samples contain sample sizes greater than 30 except for widows with a Masters and widows 
   with a PhD. The samples with sample sizes over 30 have a normal x-bar distribution.
  -Widows with a Masters and widows with a PhD show normality tests in which all are not 
   significantly different from normal. Additionally, the QQ plots for both groups show little 
   deviation from the agreement line. Hence, we can assume these samples have normal x distributions.
*/

/************************************************************************************************/
/*********************************** END: Assessing Normality ***********************************/
/************************************************************************************************/



/************************************************************************************************/
/********************************* BEGIN: Assessing Homogeneity *********************************/
/************************************************************************************************/

/*Using proc means to get the standard deviations of each sample*/
proc means data=work.marketing;
class 'Marital Status'n 'Education Level'n;
var 'Wine Purchase'n;
run;

/*
  -H0: All data sets come from populations that have the same variances.
  -Ha: All data sets come from populations that do not have the same variances.
       At least one variance is different than the rest.
  
  -We will look at the ratio of standard deviations (Largest SD/Smallest SD) to test homogeneity.
  -The ratio of the largest and smallest standard deviations 
   (Married with PhD/Widow with Graduation) = (413.0864/282.8625) = 1.4604 < 2
  -Since the ratio is less than 2, the standard deviations are close enough to assume the data
   is homogeneous.
*/

/************************************************************************************************/
/********************************** END: Assessing Homogeneity **********************************/
/************************************************************************************************/



/************************************************************************************************/
/******************************** BEGIN: Choosing Hypothesis Test *******************************/
/************************************************************************************************/

/*
Since the data is normal and homogeneous, we will perform the two-way ANOVA on Data.

To perform the two-way ANOVA, we must
  1.) Perform the Global F Test 
  2.) Test the Interaction
  
The level of significance used through testing will be 𝛼=0.01
*/

/************************************************************************************************/
/********************************* END: Choosing Hypothesis Test ********************************/
/************************************************************************************************/



/************************************************************************************************/
/***************************** BEGIN: Performing the Global F Test ******************************/
/************************************************************************************************/

/*
Performing Two-Way ANOVA on data using proc GLM. MAXPOINTS = none because lots of data 
The model line creates a model for our quantitative variable wine purchase with what we are testing as
predictors marital status, education level, and a combination of marital status and education level.  
*/
proc GLM data=work.marketing PLOTS(MAXPOINTS= none);
title1 "Table 1: Does a combination of customer marital status 
        and education level result in a larger wine purchase?";
class 'Marital Status'n 'Education Level'n;
model 'Wine Purchase'n= 'Marital Status'n 'Education Level'n 'Marital Status'n*'Education Level'n /SS3;
run;
quit;

/*
The null hypothesis is,
	H0: Marital Status, Education Level, and a combination of the two do not predict the average 
	    wine purchase.
The alternative hypothesis is,
	Ha: At least one of the terms--Marital Status, Education Level, or a combination of the two-- 
	    predicts the average wine purchase.
	
The level of significance, α=0.01, tells us that 1% of the time the analysis will conclude that at 
least one term in the model predicts wine purchase when none of the terms predict wine purchase. 
*/

/*
Output--First table in GLM Procedure

Model F-Value: 3.97
      p-value: <0.0001
*/

/*
Output Interpretations

F-Statistic: The variance for the model using marital status, education level, and the interaction(456,683.6 USD^2) 
             is 3.97 times the pooled within combination variance (114,950.3 USD^2)

P-value: There is a less than 0.01% chance of getting an F-value of 3.97 or more when marital status,
         education level, and the interaction do not predict the average wine purchase.  

Conclusion: Since less than 0.01% is less than 1%, we reject H0. We are 99% confident that at least one of
            these terms(marital status, education level, or interaction) predicts average wine purchase.
*/

/************************************************************************************************/
/****************************** END: Performing the Global F Test *******************************/
/************************************************************************************************/



/************************************************************************************************/
/******************************* BEGIN: Testing The Interaction *********************************/
/************************************************************************************************/

/*same code rom global F-test*/
proc GLM data=work.marketing PLOTS(MAXPOINTS= none);
title1 "Table 1: Does a combination of customer marital status 
        and education level result in a larger wine purchase?";
class 'Marital Status'n 'Education Level'n;
model 'Wine Purchase'n= 'Marital Status'n 'Education Level'n 'Marital Status'n*'Education Level'n/SS3;
run;
quit;

/*
The null hypothesis is,
	H0: There is no interaction between marital status and education level.
The alternative hypothesis is,
	Ha: There is interaction between marital status and education level. 
	
The level of significance, α=0.01, tells us that 1% of the time the analysis will conclude that 
there is an interaction when there is not an interaction between marital status and education level.
*/

/*
Output--Third table in GLM procedure with Type III SS
Marital Status*Education Level F-value: 1.19
                               p-value: 0.3024
*/

/*
Output Interpretations

F-Statistic: The variance between the combinations of marital status and education level (136,528.42 USD^2)
             is 1.19 times the variance within the combinations (114,950.3 USD^2)

P-value: There is a 30.24% chance of getting an F-value of 1.19 or more when there is no 
         interaction between marital status and education level.  

Conclusion: Since 30.24% is greater than 1%, we cannot reject H0. We cannot say that there 
            is an interaction at an 0.01 level of of significance(p=0.3024).
*/

/************************************************************************************************/
/********************************* END: Testing the Interaction *********************************/
/************************************************************************************************/



/************************************************************************************************/
/******************************* BEGIN: Testing The Main Effects ********************************/
/************************************************************************************************/

/* same code from global f-test, but took out the interaction term*/
proc GLM data=work.marketing PLOTS(MAXPOINTS= none);
title1 "Table 2: Does customer marital status 
        or education level result in a larger wine purchase?";
class 'Marital Status'n 'Education Level'n;
model 'Wine Purchase'n= 'Marital Status'n 'Education Level'n /SS3;
run;
quit;

/*
The null hypothesis is,
	H0: Marital Status does not predict average wine purchase.
The alternative hypothesis is,
	Ha: Marital Status does predict average wine purchase. 
	
The level of significance, α=0.01, tells us that 1% of the time the analysis will conclude 
that marital status does predict average wine purchase when marital status does not predict 
average wine purchase.
*/

/*
Output--Third table in GLM procedure with Type III SS
Marital Satus F-value: 0.62
              p-value: 0.6460
*/

/*
Output Interpretations

F-Statistic: The variance between the sample means of all marital statuses and the overall 
             amount spent on wine (71,693.945 USD^2) is 0.62 of the pooled variance within
             each cell (115,038.0 USD^2).

P-value: There is a 64.60% chance of getting an F-value of 0.62 or more when marital status is 
         not predicting average wine purchase.  

Conclusion: Since 64.60% is greater than 1%, we cannot reject H0. We cannot say that marital status 
            predicts average wine purchase when it is in a model with education level at the 0.01 
            level of significance (p=0.6460).
*/


/*same code from global f-test but took out interation and marital status*/
proc GLM data=work.marketing PLOTS(MAXPOINTS= none);
title1 "Table 3: Does customer education level predict wine purchase?";
class 'Education Level'n;
model 'Wine Purchase'n= 'Education Level'n /SS3;
run;
quit;

/*
The null hypothesis is,
	H0: Education Level does not predict average wine purchase.
The alternative hypothesis is,
	Ha: Education Level does predict average wine purchase. 
	
The level of significance, α=0.01, tells us that 1% of the time the analysis will conclude 
that education level does predict average wine purchase when education level does not 
predict average wine purchase.
*/

/*
Output--Third table in GLM procedure with Type III SS
Marital Satus F-value: 21.81
              p-value: <0.0001
*/

/*
Output Interpretations

F-Statistic: The variance between the sample means of all education levels and the overall 
             amount spent on wine (2,507,283.32 USD^2) is 21.81 of the pooled variance within
             each cell (114,950.1 USD^2).

P-value: There is less than 0.01% chance of getting an F-value of 21.81 or more when education is 
         not predicting average wine purchase.  

Conclusion: Since less than 0.01% is less than 1%, we reject H0. We are 99% confident that 
            education level does predict average wine purchase.
*/

/************************************************************************************************/
/******************************** END: Testing the Main Effects *********************************/
/************************************************************************************************/



/************************************************************************************************/
/************************************ BEGIN: Post-Hoc Tests *************************************/
/************************************************************************************************/

/*Using proc anova to get bonferroni, tukey, and lsd post-hoc*/
proc anova data=work.marketing;
   class 'Education Level'n;
   model 'Wine Purchase'n = 'Education Level'n;
   means 'Education Level'n / bon lines tukey lines lsd lines alpha = .01;
run;

/*
Output Interpretation: The mean for PhD education level is significantly different than the means 
                       for graduate and masters education levels. This is the case for all three 
                       post-hoc tests, Bonferroni, LSD, and Tukey.
     
Conclusion: This further supports our conclusion that at least one sample mean in education levels 
            is different from the rest.
*/

/************************************************************************************************/
/************************************** END: Post-Hoc Tests *************************************/
/************************************************************************************************/



/************************************************************************************************/
/*************************************** BEGIN: Graphics ****************************************/
/************************************************************************************************/

/*Stratified Box Plot*/
proc sort data=work.marketing;
 by 'Education Level'n;
run;

title1 "Stratified Boxplot of Wine Purchase for Education Levels";
proc boxplot data=work.marketing;
plot ('Wine Purchase'n) * 'Education Level'n / boxstyle=schematic;
insetgroup n mean std;
run;
title;

/*
Output Interpretation: The stratified boxplot further shows how the different education levels 
                       compare with each other. The PhD level clearly has a higher mean than 
                       Graduation level and Masters level. This further supports our hypothesis test.  
*/

/************************************************************************************************/
/**************************************** END: Graphics *****************************************/
/************************************************************************************************/



/************************************************************************************************/
/************************************* BEGIN: Taking Action *************************************/
/************************************************************************************************/

/*
This analysis proves to be useful to wine companies as they are marketing to customers.
Since we saw that the customers with the PhD education level spends a significantly higher amount 
on wine than graduated and masters levels, the wine company could be a sponsor for PhD programs in
order to market more expensive wines to their future most profitable customers.
*/

/************************************************************************************************/
/*************************************** END: Taking Action *************************************/
/************************************************************************************************/
