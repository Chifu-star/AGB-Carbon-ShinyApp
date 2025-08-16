library(shiny)
library(caret)
library(randomForest)
library(nnet)

# Define UI
ui <- fluidPage(
  titlePanel("AGB and Carbon Stock Estimation Tool"),
  
  sidebarLayout(
    sidebarPanel(
      fileInput("file", "Upload CSV Data", accept = c(".csv")),
      actionButton("runModel", "Run AGB & Carbon Estimation"),
      downloadButton("downloadData", "Download Predictions")
    ),
    
    mainPanel(
      tableOutput("headData"),
      tableOutput("predictions"),
      textOutput("accuracyMetrics")
    )
  )
)

# Define server logic
server <- function(input, output) {
  
  data <- reactive({
    req(input$file)
    read.csv(input$file$datapath)
  })
  
  output$headData <- renderTable({
    req(data())
    head(data())
  })
  
  predictions <- eventReactive(input$runModel, {
    req(data())
    results <- estimate_agb_carbon(data())
    results
  })
  
  output$predictions <- renderTable({
    req(predictions()$predictions)
    head(predictions()$predictions)
  })
  
  output$accuracyMetrics <- renderText({
    req(predictions())
    paste("MAE:", round(predictions()$MAE, 2), 
          "RMSE:", round(predictions()$RMSE, 2), 
          "R-squared:", round(predictions()$R2, 2),
          "AIC:", round(predictions()$AIC, 2),
          "BIC:", round(predictions()$BIC, 2))
  })
  
  output$downloadData <- downloadHandler(
    filename = function() { "AGB_Carbon_Predictions.csv" },
    content = function(file) {
      write.csv(predictions()$predictions, file, row.names = FALSE)
    }
  )
}

# Function for estimating AGB and Carbon Stock
estimate_agb_carbon <- function(data) {
  # Check if necessary columns exist
  required_columns <- c("AGB", "Dbh", "Ht", "Elv", "Slp", "SpH", "NDVI", "EVI")
  missing_columns <- setdiff(required_columns, colnames(data))
  
  if (length(missing_columns) > 0) {
    stop(paste("Missing required columns:", paste(missing_columns, collapse = ", ")))
  }
  
  # Step 1: Handle missing values
  data <- na.omit(data)  # Removing any rows with NA values
  
  # Step 2: Split the data
  set.seed(123)
  trainIndex <- createDataPartition(data$AGB, p = 0.8, list = FALSE, times = 1)
  trainData <- data[trainIndex, ]
  testData  <- data[-trainIndex, ]
  
  # Step 3: Define control for cross-validation
  control <- trainControl(method = "cv", number = 10)
  
  # Step 4: Train models
  set.seed(123)
  ann1 <- train(AGB ~ Dbh + Ht + Elv + Slp + SpH + NDVI + EVI, 
                data = trainData, method = "nnet", 
                trControl = control, linout = TRUE, trace = FALSE)
  
  ann2 <- train(AGB ~ Dbh + Ht + Elv + Slp + SpH + NDVI + EVI, 
                data = trainData, method = "nnet", 
                trControl = control, linout = TRUE, trace = FALSE, tuneLength = 5)
  
  rf <- randomForest(AGB ~ Dbh + Ht + Elv + Slp + SpH + NDVI + EVI, 
                     data = trainData, ntree = 400, mtry = 4, importance = TRUE)
  
  # Step 5: Meta-learner training
  train_preds <- data.frame(
    ann1 = predict(ann1, trainData),
    ann2 = predict(ann2, trainData),
    rf = predict(rf, trainData),
    AGB = trainData$AGB
  )
  
  meta_learner <- train(AGB ~ ann1 + ann2 + rf, data = train_preds, method = "lm")
  
  # Step 6: Prediction on test data
  test_preds <- data.frame(
    ann1 = predict(ann1, testData),
    ann2 = predict(ann2, testData),
    rf = predict(rf, testData)
  )
  stacked_preds <- predict(meta_learner, test_preds)
  
  # Step 7: Calculate accuracy metrics
  MAE <- mean(abs(stacked_preds - testData$AGB))
  RMSE <- sqrt(mean((stacked_preds - testData$AGB)^2))
  R2 <- cor(stacked_preds, testData$AGB)^2
  
  # Calculate AIC and BIC
  residuals <- testData$AGB - stacked_preds
  n <- length(residuals)
  k <- length(coef(meta_learner$finalModel))  # number of parameters in the meta-learner
  
  log_likelihood <- -n/2 * log(sum(residuals^2) / n)
  AIC <- -2 * log_likelihood + 2 * k
  BIC <- -2 * log_likelihood + log(n) * k
  
  # Step 8: Calculate Carbon Stock
  carbon_stock <- 0.5 * stacked_preds
  
  # Return the predictions along with the accuracy metrics
  return(list(predictions = data.frame(AGB_Predicted = stacked_preds, Carbon_Stock = carbon_stock), 
              MAE = MAE, RMSE = RMSE, R2 = R2, AIC = AIC, BIC = BIC))
}

# Run the application 
shinyApp(ui = ui, server = server)
