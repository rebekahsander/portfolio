#%% imports

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import statsmodels.api as sm

#%%

#load in the dataset
airbnb = pd.read_csv("C:/Users/rebek/data4140/project/newyork.csv")

#see if data was read in and check datatypes
print(airbnb.shape)
print(airbnb.head())
print(airbnb.info())

#%% Separating categorical and quantitative variables

# Initialize lists to store categorical and quantitative variable names
categorical = []
quantitative = []

# Iterate over the columns and check if each one is categorical or quantitative
for col in airbnb.columns:
    if airbnb[col].dtype == 'object':
        categorical.append(col)
    else:
        quantitative.append(col)

# Print the lists of categorical and quantitative variable names
print("Categorical Variables:", categorical)
print("Quantitative Variables:", quantitative)


#%% Explore variables PRE preprocessing

# Explore categorical variables
for i in categorical:
    print(airbnb[i].value_counts())

# Explore quantitative variables
for i in quantitative:
    print(airbnb[i].describe())
    
# Calculate the percentage of missing values for each column
missing_percentage = (airbnb.isnull().mean()) * 100
print("Percentage of missing values in each column:")
print(missing_percentage)


#%%
# host_response_rate from categorical to quantitative
airbnb['host_response_rate'] = airbnb['host_response_rate'].str.rstrip('%').astype(float)


#dropping features
airbnb = airbnb.drop(columns=['square_feet']) #high % missing
airbnb = airbnb.drop_duplicates().dropna(axis=0, how='all') #duplicates
airbnb = airbnb.drop(columns=['id', 'latitude', 'longitude', 
                              'minimum_nights','maximum_nights']) #not interested

airbnb = airbnb[airbnb['price'] >= 50]
#%%
#update categorical and quantitative variables
categorical = []
quantitative = []
for col in airbnb.columns:
    if airbnb[col].dtype == 'object':
        categorical.append(col)
    else:
        quantitative.append(col)
#%% 
location = airbnb['neighbourhood_cleansed']
airbnb_clean = airbnb.drop(columns = categorical)
airbnb = pd.concat([airbnb_clean,location],axis=1)

#%%
#imputing missing values
airbnb[quantitative] = airbnb[quantitative].fillna(airbnb[quantitative].median())

#%%
# Re-exploring the variables POST preprocessing

for i in quantitative:
    print(airbnb[i].describe())
   
print(airbnb['neighbourhood_cleansed'].value_counts())

#check missing values
print(airbnb.isnull().sum())

#%%
# creating target variable (price*how many occupied nights in a month)
airbnb["revenue"] = (airbnb['price'] * (30 - airbnb['availability_30']))
airbnb = airbnb.drop(columns=['price', 'availability_30'])

#remove outliers
airbnb = airbnb[np.abs(airbnb.revenue-airbnb.revenue.mean())<=(3*airbnb.revenue.std())]

airbnb_grp = airbnb.groupby('neighbourhood_cleansed')
revenue_location = airbnb_grp['revenue'].agg("mean")

airbnb_merge=pd.merge (airbnb, revenue_location, on='neighbourhood_cleansed', how='inner')
airbnb_merge["relative_revenue"]= ((airbnb_merge['revenue_x']) / (airbnb_merge['revenue_y']))

airbnb = airbnb_merge.drop(columns=['revenue_x', 'revenue_y', 'neighbourhood_cleansed'])

#%% train,validate,test
from sklearn.model_selection import train_test_split

# Split the dataset into train and test.
X = airbnb.drop('relative_revenue', axis=1) # Features
y = airbnb['relative_revenue'] # Target variable
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

#%%

airbnb_train=pd.concat([X_train,y_train],axis=1)
airbnb_test=pd.concat([X_test,y_test],axis=1)

airbnb_train.to_csv('airbnb_train.csv', index=False)
airbnb_test.to_csv('airbnb_test.csv', index=False)

#%%
# Individual scatterplots
for feature in X_train.columns:
    plt.scatter(airbnb[feature], airbnb['relative_revenue'])
    plt.xlabel(feature)
    plt.ylabel('Relative Revenue')
    plt.title(f'Scatter plot of {feature} vs. Relative Revenue')
    plt.show()
 
#residual scatterplot
while feature in airbnb_train.columns:
    sns.residplot(x=feature, y='relative_revenue', data=airbnb_train)
    plt.xlabel(feature)
    plt.show()


# Correlation matrix
correlation_matrix = airbnb_train.corr()

# Scatterplot matrix
sns.pairplot(airbnb_train)
plt.show()

#%%

# Add a constant term to the features (for intercept)
X = sm.add_constant(X)

# Fit the multiple linear regression model
model = sm.OLS(y_train, X_train)
results = model.fit()

# Print the summary of the regression results
print(results.summary())

# Get the predicted values on the test set
y_pred = results.predict(X_test)

# Calculate Adjusted R-squared
adj_rsq = 1 - (1 - results.rsquared) * (len(y_train) - 1) / (len(y_train) - len(X_train.columns) - 1)
print("Adjusted R-squared:", adj_rsq)

# Calculate RMSE (Root Mean Squared Error)
rmse = np.sqrt(np.mean((y_pred - y_test)**2))
print("RMSE:", rmse)



