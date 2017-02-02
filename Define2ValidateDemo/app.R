#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(R4DSXML)
library(testthat)
library(validate)
source("https://raw.githubusercontent.com/mokjpn/Define2Validate/master/define2validate.R")
#source("../define2validate.R")
source("mybarplot.R")

# Define UI for application that draws a histogram
ui <- fluidPage(
   
   # Application title
   titlePanel("Define2Validate Demonstration"),
   
      # Sidebar with a slider input for number of bins 
   sidebarLayout(
      sidebarPanel(
        fileInput("definexml", "Choose your Define-XML v2.0", 
                  accept = c("text/plain", "text/xml", ".xml")
        ),
        tags$hr(),
        fileInput("datasetxml", "Choose your Dataset-XML v1.0",
                  accept = c("text/plain", "text/xml", ".xml")
        ),
        selectInput("domain", "Set the domain of your Dataset-XML", c("Please Select"="", "AE"="AE", "CM"="CM", "DA"="DA", "DM"="DM", "DS"="DS", "EG"="EG", 
            "EX"="EX", "IE"="IE", "LB"="LB","MH"="MH", "PE"="PE", "SC"="SC", "SE"="SE", "SV"="SV", "TA"="TA", "TE"="TE", "TI"="TI", "TS"="TS", "TV"="TV",
            "VS"="VS" )),
        actionButton("validate", "Validate"),
        p(),
        a("Source code",href="http://github.com/mokjpn/Define2Validate/")
      ),
      
      # Show a plot of the generated distribution
      mainPanel(
        tabsetPanel(
          tabPanel("Table",tableOutput("resultsTable")),
          tabPanel("Figure", plotOutput("resultsFigure", height="1280px"))
        )
      )
   )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
   doValidate <- reactive({
     define <- input$definexml
     dataset <- input$datasetxml
     domain <- input$domain
     if (is.null(define) || is.null(dataset) || domain == "")
       return(NULL)
     define2validate(domain, file="Rules.yaml", definexml=define$datapath,overwrite=TRUE)
     v <- validator(.file="Rules.yaml")
     x <- read.dataset.xml(dataset$datapath,define$datapath)
     CT <- getCT(define$datapath)
     "%notin%" <- function(x, table) !match(x, table, nomatch = 0) > 0
     confront(x,v)
   })
   output$resultsTable <- renderTable({
     res <- doValidate()
     if(is.null(res)) return(NULL)
     summary(doValidate())
   })
   output$resultsFigure <- renderPlot({
     mybarplot(doValidate())
   })
}

# Run the application 
shinyApp(ui = ui, server = server)

