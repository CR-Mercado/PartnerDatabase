#' UI :: 
#' 
#' instructions detailing how to change capabilities file 
#' 
#' words for keyword search, separated by commas, 
  #' it ignores words that aren't capabilities 
#' 
#' 
#' add partner to database 
    #' does webscrape + overwrite of database to add entry     
#'
#' download the top 20 results (can make 20 flexible later, but 20 is probably plenty)



library(shiny)

# Define UI for application 
shinyUI(fluidPage(
  
  # Application title
  titlePanel("The Partners Database"),
  
  # Sidebar 
  sidebarLayout(
    sidebarPanel(
      
      #' Provide inputs to search Capabilities
      
      h4("Search for Capabilities"),
        h6("Look over the capabilities document in this file folder, as words that aren't there will be ignored. I recommend 
           using singular words and splitting ideas into more smaller words. Such as health, communication instead of health communication."),
      textAreaInput(inputId = "capabilities.to.search", label = "Capabilities", value = "health, communication"),
      actionButton(inputId = "partner.search",label = "Search!"),
       #' Upload a New Partner csv and verify it is structured correctly
       
      h4("Uploading New Partners"),
        h6("Limited warnings for incorrect formatting, please see the Uploading New Partners Tab for instructions."),
      fileInput(inputId = "new.partners", label = "Choose Partner CSV file",
                multiple = FALSE,
                accept = c(".csv"), 
                buttonLabel = "Find csv"),
      checkboxInput("confirm",
                    "Please confirm the csv has the partner and website headers and that the website(s) have http://... or https://..."),
      actionButton(inputId = "partner.add", label = "Add!"),
      
       #  Download the sorted database 
      
      h4("Download the Partner Suggestions."),
        h6("when downloading, change the file name and add .csv to the end."),
        downloadButton("get.data",label = "Download to csv")
      
    ),
    
    # Show a 
    mainPanel(
     tabsetPanel(
       tabPanel("Partner Suggestions",
                tableOutput("top.partners")),
       tabPanel(title = "Database Design",
                ("The database is designed like a skills matrix. With Partners & Website as rows, and capabilities as columns. 
                   The contents is then 1s and 0s, if the partner has the capability in its set of websites, they get a 1 in that capability
                   column. Generally, the column is just a single word. So hud is a better search than housing and urban development. When searching,
                   the results are a sorted table for partners that have the most capabilities that you searched for. Note: Downloading the suggestions
                 only gives you the relevant subset of the database. To get the entire database, go to the file folder of this app.")
       ),
       tabPanel(title = "Capabilities File", 
                "The capabilities file is a csv inside this app folder that looks like an excel file of 1 column and no headers. 
                It is the list of all the capabilities searched for in the partners. This file can be edited from within the folder, 
                but please keep the exact name! When edited, you'll either need to refresh the entire database (very time consuming), 
                and/or no longer search for the capabilities you've removed. To refresh the database, get the current database and erase everything
                but the partner and website columns. Change the Capabilities file to your updated list of capabilities (without changing the file name)
                and re-upload the partner and website columns with Uploading New Partners. The Partner database will be refreshed inside the file folder
                of this app."
                ),
       tabPanel(title = "Uploading New Partners", 
                "This can be a time-consuming process, especially if there are hundreds of capabilities to search for and dozens of 
                   partners. Please upload a csv with the headers 'partner' 'website' and make sure that the website(s) 
                includes the http:// or https://"
                ),
       tabPanel(title = "Common Errors and Fixes", 
                "Be very careful making changes to the capabilities. All the CSVs are saved as CSV-UTF8 encoding in excel, and the app 
                should accurately read any csv made in excel that way. Changes to the capabilities list need to coincide with a change 
                in the partner database column names from column C (in Excel, i.e. the 3rd column, after partner and website). The easiest
                way to do that (which should only come up if you are doing a full database refresh) is to copy the capabilities list 
                and paste it (as transpose) to be the columns of the partners database."
       )
       
     )
    )
  )
))
