#%% imports

import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

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

# missing values
airbnb=airbnb.dropna()

#dropping duplicates
airbnb = airbnb.drop_duplicates().dropna(axis=0, how='all')

#dropping observations that dont make sense
airbnb = airbnb[airbnb['price'] >= 50]

#%%
#dropping features
airbnb = airbnb.drop(columns=['square_feet']) #high % missing
airbnb = airbnb.drop(columns=['id', 'latitude', 'longitude', 
                              'minimum_nights','maximum_nights']) #not interested
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

airbnb_grp = airbnb.groupby('neighbourhood_cleansed')
revenue_location = airbnb_grp['revenue'].agg("mean")

airbnb_merge=pd.merge (airbnb, revenue_location, on='neighbourhood_cleansed', how='inner')
airbnb_merge["relative_revenue"]= ((airbnb_merge['revenue_x']) / (airbnb_merge['revenue_y']))

airbnb = airbnb_merge.drop(columns=['revenue_x', 'revenue_y', 'neighbourhood_cleansed'])

# Drop rows where 'relative_revenue' is 0
airbnb = airbnb[airbnb['relative_revenue'] != 0]

airbnb=airbnb.dropna()

#%%
#robust scaler for outliers
from sklearn import preprocessing

scaler = preprocessing.RobustScaler()
robust = scaler.fit_transform(airbnb[airbnb.columns])
robust = pd.DataFrame(robust,columns=airbnb.columns)


#%%
#variable clustering
from varclushi import VarClusHi

var_clus_model = VarClusHi(airbnb, maxeigval2 = .7, maxclus = None)
var_clus_model.varclus()

vr = var_clus_model.rsquare

vi = var_clus_model.info

vi["N_Vars"]=vi["N_Vars"].astype(float)

total_var_prop = sum(vi["VarProp"] * vi["N_Vars"])/sum(vi["N_Vars"])

min_rs_ratio = vr.groupby(by="Cluster")["RS_Ratio"].min().reset_index()

result = pd.merge(min_rs_ratio, vr, on=["Cluster", "RS_Ratio"], how="inner")
result


airbnb = airbnb[list(result['Variable'])]


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
    plt.scatter(airbnb_train[feature], airbnb_train['relative_revenue'])
    plt.xlabel(feature)
    plt.ylabel('Relative Revenue')
    plt.title(f'Scatter plot of {feature} vs. Relative Revenue')
    plt.show()

#%%
# multiple linear regression

# f. Implement Linear Regression
from sklearn.linear_model import LinearRegression
from sklearn.metrics import mean_squared_error

model = LinearRegression().fit(X_train, y_train)
print("Coefficients:", model.coef_)
print("Intercept:", model.intercept_) 

# Train the model
model.fit(X_train, y_train)

# Test the model
rsq = model.score(X_test, y_test)
print("R-squared:", rsq)

# Evaluate the model
# Predict the target values
y_pred = model.predict(X_test)

# Calculate Mean Squared Error
mse = mean_squared_error(y_test, y_pred)
rmse = mse ** 0.5
print("RMSE:", rmse)


#%%
# RandomForest Regression

from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_squared_error

# Define the model
model = RandomForestRegressor(random_state=42)
# Train the model
model.fit(X_train, y_train)

# Test the model
rsq = model.score(X_test, y_test)
print("R-squared:", rsq)

# Evaluate the model
# Predict the target values
y_pred = model.predict(X_test)

# Calculate Mean Squared Error
mse = mean_squared_error(y_test, y_pred)
rmse = mse ** 0.5
print("RMSE:", rmse)


#%%
# XGBoost Regression
#imports
import xgboost as xgb

model = xgb.XGBRegressor(objective="reg:squarederror", random_state=42)  
model.fit(X_train, y_train)

# Test the model
rsq = model.score(X_test, y_test)
print("R-squared:", rsq)

# Evaluate the model
# Predict the target values
y_pred = model.predict(X_test)

# Calculate Mean Squared Error
mse = mean_squared_error(y_test, y_pred)
rmse = mse ** 0.5
print("RMSE:", rmse)



#%%
#correlation heatmap
correlation_matrix = airbnb.corr()

plt.figure(figsize=(10, 8))
sns.heatmap(correlation_matrix, annot=True, cmap='coolwarm', fmt=".2f", vmin=-1, vmax=1)
plt.title('Figure 1: Correlation Heatmap')
plt.show()

#%%
# Plot actual vs. predicted values
plt.figure(figsize=(8, 6))
plt.scatter(y_test, y_pred, color='blue', alpha=0.4)
plt.plot([y_test.min(), y_test.max()], [y_pred.min(), y_pred.max()])  # Add diagonal line for reference
plt.title('Figure 2: Actual vs. Predicted Values')
plt.xlabel('Actual Values')
plt.ylabel('Predicted Values')
plt.grid(True)
plt.show()

