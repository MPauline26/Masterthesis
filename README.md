# Master Thesis Repository

This repository contains the code and LaTeX source code for my master thesis. The purpose of this repository is to document the code used in my thesis project and provide access to the LaTeX source for the thesis document.

## Thesis Abstract

This master thesis focuses on credit risk assessment using the Random Forest algorithm to estimate the Probability of Default. The study aims to enhance the accuracy of credit risk models by leveraging the ensemble functionality of Random Forest, which combines the strength of multiple decision trees. The research utilizes a comprehensive dataset of an American mortgage loan portfolio published by the Federal Home Loan Mortgage Corporation. 

The research begins by introducing the importance of credit risk assessment and the regulatory framework set by the Basel Committee on Banking Supervision. The study introduces the theoretical basis of modeling and validation processes, focusing on logistic regression and Random Forest algorithm. Empirical research is conducted to compare the performance of both approaches. 

Results obtained from the predictive models are thoroughly evaluated on out-of-sample datasets using metrics such as the area under the Receiver Operating Characteristic curve, Gini coefficient, F1-score and confusion matrix. The Random Forest outperforms the logistic regression model, with marginal performance improvement. Feature importance and interpretability methods within the Random Forest framework are explored to identify key variables influencing credit risk and increase transparency.

## Code Contents

### Python Notebook
The Python notebook contains code to develop the Random Forest model, including hyperparameter tuning with random and grid search. The final Random Forest model is benchmarked against the logistic regression model using metrics calculated on the training, test and validation samples. Interpretability methods such as feature importance, LIME, individual tree plots, PDP and ICE plots are also implemented.

### SAS Code
The SAS code includes data preparation steps to combine raw CSV files provided by Freddie Mac, approximate default flags, perform data cleaning, create new variables, conduct univariate analysis, normalize features and develop a logistic regression model.

## Dependencies

### Python Notebook
- pandas
- numpy
- matplotlib
- seaborn
- scikit-learn
- lightgbm
- lime
- shap

## Feedback and Contributions

If you have any feedback, encounter issues, or would like to contribute to this project, feel free to reach out.
