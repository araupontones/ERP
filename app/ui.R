##### UI of QA system

library(shiny)
library(DT)
library(shinycssloaders)


navbarPage("ERP's Quality Assurance",
           tabPanel("Responses",
                    fluidRow(
                      column(12,
                             withSpinner(DTOutput("table"), type = 5)
                             )
                      ),
           tabPanel("Summary"),
           tabPanel("Table")
)
)

