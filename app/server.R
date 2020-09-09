library(shiny)
library(tidyverse)



server <- function(input, output, session) {
  
  source("download.R")
  
  output$table <- DT::renderDT({
    
    datatable(
     
      report_donors_implementors,
      options = list(
        pageLength = nrow(report_donors),
        dom = 'ft'
        
      ),
      rownames = FALSE,
      escape = FALSE
      
      ) %>%
      formatStyle(
        colnames(report_donors_implementors)[13:17],
        color = styleInterval(c(50, 100), c('black', 'black', 'white')),
        backgroundColor = styleInterval(c(99,100), c('#FFF9AE', 'white','#FB8D8F'))
      )  
      
    
  })
  
  
  
}