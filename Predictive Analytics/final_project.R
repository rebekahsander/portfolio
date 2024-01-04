setwd("C:\\Users\\rebek\\OneDrive\\Desktop\\STAT4030\\final presentation")

#read in college_motivation dataset
college <- read.csv("college_motivation.csv")

#cleaning up the data
#first make dependent variable binary
college$will_go_to_college <- ifelse(college$will_go_to_college=="True",1,0)
college$parent_was_in_college <- ifelse(college$parent_was_in_college=="True",1,0)

# Load Required Packages and import dataset
library(mice)
library(glmnet)
library(pROC)
library(caret)
library(dplyr)
library(VIM)
library(ROCR)


set.seed(4030)

# Missing data visualization
college_missing <- aggr(college, col=c('green','red'), numbers=TRUE, sortVars=TRUE, 
                  labels=names(data), cex.axis=.55, gap=3, 
                  ylab=c("Histogram of missing data","Pattern"))
college_missing

#splitting the dataset 6:2:2
college_train <- sample_frac(college, 0.6)
train_index <- as.numeric(rownames(college_train))
college_transition <- college[-train_index,] 

college_validation <- sample_frac(college_transition, 0.5)
validation_index <- as.numeric(rownames(college_validation))
college_test <- college_transition[-validation_index,] 

#performing logistic regression using training dataset
class(college$will_go_to_college)
college_lmod <- glm(will_go_to_college ~ ., data = college_train, 
                    family = "binomial")
summary(college_lmod)


##########Validation
# Predict probability of student going to college on validation dataset
college_validation$predicted <- predict(college_lmod, newdata=college_validation, 
                                        type = "response")

## Optimize threshold for best accuracy the model can possibly achieve

max_accuracy <- 0
best_threshold <- 0

for (threshold in seq(0.01, 0.99, by = 0.01)) {
  college_validation$predicted_class <- ifelse(college_validation$predicted >= threshold, 1, 0)
  
  accuracy <- mean(college_validation$predicted_class == college_validation$will_go_to_college)
  
  if (accuracy > max_accuracy) {
    max_accuracy <- accuracy
    best_threshold <- threshold
  }
}

# Print the threshold and maximum accuracy
cat("Best Threshold:", best_threshold, "\n")
cat("Maximum Accuracy:", max_accuracy, "\n")


# At the best cutoff rate, will_go (1) for > cutoff and will_go (0) for < cutoff
college_validation$predicted_college <- ifelse(college_validation$predicted > best_threshold, 1, 0)

# Total number of students who are predicted to go to college
sum(college_validation$predicted_college)


## Build a confusion matrix showing TP, FP, TN, FN
confusionMatrix(factor(college_validation$predicted_college), 
                factor(college_validation$will_go_to_college),
                dnn = c("Prediction", "Reference"),
                positive = "1")

# calculating accuracy 
mean(college_validation$predicted_college == college_validation$will_go_to_college)

#calculating PMSE
(mean((college_validation$predicted - college_validation$will_go_to_college)^2))^0.5 

# Calculating AUC-ROC value using pROC module
auc(college_validation$will_go_to_college, college_validation$predicted)

# Visualizing AUC-ROC using ROCR module
pred <- prediction(college_validation$predicted, college_validation$will_go_to_college)
perf <- performance(pred,"tpr","fpr")
plot(perf)

########### END VALIDATION


# Predict probability of student going to college on test dataset
college_test$predicted <- predict(college_lmod, newdata=college_test, 
                                 type = "response")


# At best_threshold cutoff rate, will_go (1) for > best threshold and will_go (0) for < best threshold
college_test$predicted_college <- ifelse(college_test$predicted > best_threshold, 1, 0)

# Total number of students who are predicted to go to college
sum(college_test$predicted_college)


## Build a confusion matrix showing TP, FP, TN, FN
confusionMatrix(factor(college_test$predicted_college), 
                factor(college_test$will_go_to_college),
                dnn = c("Prediction", "Reference"),
                positive = "1")

# calculating accuracy 
mean(college_test$predicted_college == college_test$will_go_to_college)

#calculating PMSE
(mean((college_test$predicted - college_test$will_go_to_college)^2))^0.5 

# Calculating AUC-ROC value using pROC module
auc(college_test$will_go_to_college, college_test$predicted)

# Visualizing AUC-ROC using ROCR module
pred <- prediction(college_test$predicted, college_test$will_go_to_college)
perf <- performance(pred,"tpr","fpr")
plot(perf)



