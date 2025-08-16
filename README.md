# 🌳 AGB and Carbon Stock Estimation Tool

This repository contains a **Shiny application** for estimating **Above-Ground Biomass (AGB)** and **Carbon Stock** in Miombo woodlands using **Artificial Neural Networks (ANNs)**, **Random Forests (RF)**, and a **stacked meta-learner**.

The app allows users to:
- Upload their own CSV dataset 📂
- Train hybrid models (ANN + RF + meta-learner) ⚙️
- Generate predictions for AGB and Carbon stock 🌱
- Download predicted results 📥
- View model accuracy metrics (MAE, RMSE, R², AIC, BIC) 📊

---

## 🚀 Features
- **Interactive Shiny UI**: Upload datasets, run models, and view results in one place.
- **Hybrid Modeling**: Combines ANN and RF with a linear meta-learner.
- **Accuracy Metrics**: Reports MAE, RMSE, R², AIC, and BIC.
- **Carbon Stock Calculation**: Estimated as 50% of predicted AGB.

---

## 📦 Requirements

You need **R (≥ 4.0.0)** and the following R packages:

```r
install.packages(c("shiny", "caret", "randomForest", "nnet"))

📂 Dataset Requirements
Your CSV file must include the following columns:
- AGB (Above-Ground Biomass, response variable)
- Dbh (Diameter at Breast Height)
- Ht (Tree Height)
- Elv (Elevation)
- Slp (Slope)
- SpH (Soil pH)
- NDVI (Normalized Difference Vegetation Index)
- EVI (Enhanced Vegetation Index)

📊 Output
1. Data Preview – Displays the first rows of uploaded data.
2. Predictions – Shows predicted AGB and Carbon stock.
3. Accuracy Metrics – Displays MAE, RMSE, R², AIC, and BIC.
4. Download Option – Save predictions as a CSV file.
