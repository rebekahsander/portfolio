/***********************************************************************/
/******************** Coding Final - Fall 2023 ********************/
/***********************************************************************/

/*Rebekah Sander*/


/*Do all three varieties of iris have the same PetalWidth? 
Use the sashelp.iris data set and alpha = .05 to make your decision.

Unit of observation: One Iris
Categorical: Species; levels= Setosa, Versicolor, Virginica
Quantitative: PetalWidth; unit= mm
Proc contents data = sashelp.iris; run;

*/
/*
FORMAT OF CODE ANALYSIS
1.	Import the data set. 5 points
2.  Make a new data set within SAS. Keep ONLY the variables you are testing.  5 points
3.  Check for miscoding (typos in the entries) and whether the variable types are coming in as the correct 
    variable type (quantitative or categorical). Check for misspellings or data entry errors, 
    e.g. January vs Jan. will be analyzed as different.  Correct any errors in SAS. 5 points
4.	Check for missing values (get rid if necessary) NA, periods, blanks, -1, 99999 within SAS. 5 points
5.  Change the variable name for PetalWidth to Petal Width for the analysis within SAS. 5 points
6.  Check for the normality within SAS. 5 points
7.  Check for homogeneity within SAS.  5 points
8.  Determine which of the methods to use.  10 points
9.	State Ho/Ha 5 points Make sure to say if you are testing means or medians.
10.	Interpret alpha 5 points
11.	Interpret the test statistic 5 points
12.	Interpret the p-value 5 points
13.	Make a conclusion applied to the data. 5 points
14.	Run the post hoc test and interpret. 5 points
15.	Run the graphic to tell the story and interpret. 10 points
16.	Run a second graphic and interpret. 10 points
17.	Action of why your analysis is important...how will you use it? 5 points

Total 100 points that will be proportioned to 100 points
*/


/*******************************************************/
/*******BEGINNING: 1. IMPORT DATA  ********************/
/*******************************************************/

data work.iris;
set sashelp.iris;
run;

/*******************************************************/
/*******END: IMPORT DATA  ********************/
/*******************************************************/


/******************************************************************/
/*******BEGINNING: 2. KEEP VARIABLES OF INTEREST ********************/
/********************************************************************/

data work.iris;
set sashelp.iris (keep = Species PetalWidth);
rename Species='Iris Species'n PetalWidth='Petal Width (mm)'n;
run;

/******************************************************************/
/*******END KEEP VARIABLES OF INTEREST ********************/
/********************************************************************/


/******************************************************************/
/*******BEGINNING: 3. CHECK FOR MISCODING*********/
/******************************************************************/

Proc Means data = work.iris MAXDEC=2 n mean stddev median Qrange RANGE min Q1 Q3 max;
	var 'Petal Width (mm)'n; 
run;

PROC FREQ DATA=WORK.iris;
TABLE 'Iris Species'n 'Petal Width (mm)'n;
run;

Proc Contents data=work.iris varnum;
run; 

/*Data types read in correctly. No typos in the different species.*/

/******************************************************************/
/*******END: CHECK FOR MISCODING *********/
/******************************************************************/


/******************************************************************/
/*******BEGINNING: 4. CHECK FOR MISSING VALUES *********/
/******************************************************************/

Proc Means data = work.iris MAXDEC=2 n mean stddev median Qrange RANGE min Q1 Q3 max;
	var 'Petal Width (mm)'n; 
run;

PROC FREQ DATA=WORK.iris;
TABLE 'Iris Species'n 'Petal Width (mm)'n;
run;

Proc Contents data=work.iris varnum;
run; 

/*There were no missing values also no NA or -1 or 9999 values.*/

/******************************************************************/
/*******END: CHECK FOR MISSING VALUES *********/
/******************************************************************/

/*******************************************************************/
/**** BEGINNING: 5. CHANGE VARIABLE NAME *****/
/*******************************************************************/

/*same code from 2. rename line changed the names*/
data work.iris;
set sashelp.iris (keep = Species PetalWidth);
rename Species='Iris Species'n PetalWidth='Petal Width (mm)'n;
run;

/*******************************************************************/
/**** END: CHANGE VARIABLE NAME *****/
/*******************************************************************/



/******************************************************************/
/**** BEGINNING: 6. CHECK NORMALITY **********/
/********************************************************************/

/*Using proc univariate with normaltest and plots to check sample size, normality tests, & QQ plots*/
proc univariate data=work.iris normaltest plots;
class 'Iris Species'n;
var 'Petal Width (mm)'n;
run;

/*
  -H0: The data came from a population where the iris petal widths are normally distributed
  -Ha: The data came from a population where the iris petal widths are not normally distributed.
  -𝛼=0.05
  
  -All samples contain sample sizes greater than 30 and thus follow normal x-bar distributions.
*/

/******************************************************************/
/**** END: CHECK NORMALITY **********/
/********************************************************************/



/********************************************************************/
/**** BEGINNING: 7. CHECK HOMOGENEITY **********/
/********************************************************************/

/*Using proc means to get the standard deviations of each sample*/
proc means data=work.iris;
class 'Iris Species'n;
var 'Petal Width (mm)'n;
run;

/*
  -H0: All data sets come from populations that have the same variances.
  -Ha: All data sets come from populations that do not have the same variances.
       At least one variance is different than the rest.
  
  -We will look at the ratio of standard deviations (Largest SD/Smallest SD) to test homogeneity.
  -The ratio of the largest and smallest standard deviations 
   (Virginica/Setosa) = (2.7465/1.0539) = 2.6060 > 2
  -Since the ratio is greater than 2, the standard deviations are not close enough to assume the 
   data is homogeneous.

/********************************************************************/
/**** END: CHECK HOMOGENEITY **********/
/********************************************************************/



/******************************************************************/
/**** BEGINNING: 8. DETERMINE WHICH METHOD TO USE **********/
/********************************************************************/
/* Since the data is normal and not homogeneous, we will perform the Welch's Test on Raw Data.*/

/* Running Welch's Test on Data*/
TITLE "Welch Nonparametric Test for Mean Casual Counts across Days of the Week";
PROC GLM data=work.iris order=internal;
	class 'Iris Species'n;
	model 'Petal Width (mm)'n = 'Iris Species'n;
	means 'Iris Species'n / hovtest=levene(TYPE=square) welch;
run;
quit;

Proc Means data=work.iris n mean std;
var 'Petal Width (mm)'n;
run;
title;


/******************************************************************/
/**** END: DETERMINE WHICH METHOD TO USE **********/
/********************************************************************/



/******************************************************************/
/**** BEGINNING: 9. STATE Ho/Ha  **********/
/********************************************************************/

/*
H0: All iris species have the same mean petal widths (in mm).
Ha:  At least one iris species has a different average petal width (in mm) than the rest.
*/

/******************************************************************/
/**** END: STATE Ho/Ha  **********/
/********************************************************************/



/******************************************************************/
/**** BEGINNING: 10. INTERPRET Alpha  **********/
/********************************************************************/

/*
The level of significance, 𝛼=0.05, tells us that 5% of the time the analysis will conclude
that at least one mean is different when all means are equal for all iris species.
*/

/******************************************************************/
/**** END: INTERPRET Alpha **********/
/********************************************************************/



/******************************************************************/
/**** BEGINNING: 11. INTERPRET THE TEST STATISTIC **********/
/********************************************************************/

/*
F Statistic: The variance between each iris species average petal width (in mm) from the overall
             average petal width (11.99 mm) for all 150 irises recorded is 1276.88 times the 
             variance within the three iris species combined.
*/

/******************************************************************/
/**** END: INTERPRET THE TEST STATISTIC **********/
/********************************************************************/



/******************************************************************/
/**** BEGINNING: 12. INTERPRET THE P-VALUE **********/
/********************************************************************/

/*
P-value: There is a less than 0.01% chance of getting an F-value of 1276.88 or more when 
         the average petal width (in mm) of is the same for three iris species.  
*/

/******************************************************************/
/**** END: INTERPRET THE P-VALUE **********/
/********************************************************************/



/******************************************************************/
/**** BEGINNING: 13. MAKE A CONCLUSION  **********/
/********************************************************************/

/*
Since less than 0.01% is less than 5%, we reject 𝐻0. We are 95% confident that at least one 
iris species has a different mean petal width (in mm).
*/

/******************************************************************/
/**** END: MAKE A CONCLUSION **********/
/********************************************************************/



/******************************************************************/
/**** BEGINNING: 14. RUN THE POST HOC AND INTERPRET **********/
/********************************************************************/
/* There is no post-hoc in sas, use means table*/
Proc Means data=work.iris mean std;
class 'Iris Species'n;
var 'Petal Width (mm)'n;
run;
title;

/*
Interpretation: 
We know at the minimum, that the largest mean (Virginica Petal Width: 20.26 mm) is different
from the smallest mean (Setosa Petal Width: 2.46 mm). Thus, Virginica irises have a significantly
higher petal width (in mm) than Setosa iris' petal widths.
*/

/******************************************************************/
/**** END: RUN THE POST HOC AND INTERPRET **********/
/********************************************************************/


/******************************************************************/
/**** BEGINNING: 15. RUN THE GRAPHIC TO TELL THE STORY AND INTERPRET **********/
/********************************************************************/

/*Stratified Box Plot*/
TITLE 'Box Plot for Petal Widths(mm) by Iris Species';
PROC sgplot data= work.iris; 	
	vbox 'Petal Width (mm)'n / group= 'Iris Species'n;
	title 'Distribution of Petal Width (mm) by Iris Species';
	yaxis label= 'Petal Width (mm)';
	xaxis label= 'Iris Species';
	ODS graphics
		/	attrpriority=none;
RUN;
TITLE;

/*
Interpretation: 
There is clearly a difference in the petal widths of each iris species. Specifically, there is 
the biggest difference between Setosa and Virginica irises. You can also see from the boxplots that
Setosa also does not overlap with Versicolor, further supporting a difference between iris species.
This further visualizes our post-hoc with Setosa and Virginica having the smallest and largest means.
Additionally, the box plots support our Welch's test on raw data that says we have at least one iris 
species' average petal width different from the other species' petal widths.
*/

/******************************************************************/
/**** END: RUN THE GRAPHIC TO TELL THE STORY AND INTERPRET **********/
/********************************************************************/



/******************************************************************/
/**** BEGINNING: 16. RUN A SECOND GRAPHIC TO TELL THE STORY AND INTERPRET **********/
/********************************************************************/

/*Stratified Confidence Intervals for means*/
ods graphics on / height=2.5 in width=3.5 in;
TITLE1 "95% Confidence Intervals for Mean";
title2 "Petal Width (mm) by Iris Species";
proc sgplot data=work.iris;
	dot 'Iris Species'n / response='Petal Width (mm)'n stat=mean
		datalabelattrs=(size=10 color="#13478C")
		limitstat=CLM datalabel='Petal Width (mm)'n alpha=0.05;
	yaxis label="Iris Species";
	xaxis label="Petal Width (mm)";
run;
ods graphics off;

/*
Interpretation: 
There is clearly a difference in the petal widths of each iris species. Again, we see the biggest
gap in confidence intervals for the means of Setosa and Virginca petal widths. This not only further
visualizes our post-hoc with Setosa and Virginica petal widths having the smallest and largest means, but also
but also supports our Welch's test on raw data that says we have at least one iris species' average 
petal width different from the other species' petal widths.
*/

/******************************************************************/
/**** END: RUN A SECOND GRAPHIC TO TELL THE STORY AND INTERPRET **********/
/********************************************************************/



/******************************************************************/
/**** BEGINNING: 17. RECOMMENDED ACTION **********/
/********************************************************************/

/*
This analysis proves to be useful to anyone with an interest in plants. 
Suppose a park tasked an ecologist with labeling some of the plants on the park's nature walk.
If that ecologist were to run into what they knew was some sort of iris, they would be greatly
helped by the analysis we conducted. If the iris were to have larger petal widths, there is a good 
chance of it being a Virginica. If the iris were to have smaller petal widths, there is a good chance
of it being a Setosa.
*/

/******************************************************************/
/**** END: RECOMMENDED ACTION **********/
/********************************************************************/
