##### UI of QA system

library(shiny)
library(DT)


navbarPage("EPR's Quality Assurance",
           tabPanel("Responses",
                    fluidRow(
                      column(12,
                             DTOutput("table")
                             )
                      ),
           tabPanel("Summary"),
           tabPanel("Table")
)
)