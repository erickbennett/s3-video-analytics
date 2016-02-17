library(dplyr)
library(ggvis)
library(shiny)


logs <- readRDS('videologs.rds')
source("DataLabels.R")


ui <- fluidPage(
  selectInput(inputId = "dataset", selected = 'Name Video Set 1', 
              label = "Data Source", choices = unique(logs$Video_Set)),
  checkboxGroupInput(inputId = "browser", selected = browser.types, 
              label = "Browser Type", choices = browser.types, inline = TRUE),
  checkboxGroupInput(inputId = "os", selected = os.types, label = "OS", 
              choices = os.types, inline = TRUE),
  checkboxGroupInput(inputId = "network", selected = ip.address, 
              label = "Network",
              choices = ip.address, inline = TRUE),
  HTML("<p><strong>Report Results</strong></p>"),
  verbatimTextOutput("stats"),
  ggvisOutput("plot")
)

server <- function(input, output, session) {
  
  datasetInput <- reactive({
    filter(logs, Video_Set == input$dataset)
  })
  
  viz <- reactive({
    datasetInput %>%
      ggvis(~Video, ~PlayCount,
            fill = ~factor(Video)) %>%
      
      filter(Browser %in% input$browser) %>%
      filter(OS %in% input$os) %>%
      filter(Remote_IP %in% input$network) %>%
      
      group_by(Video) %>%
      mutate(PlayCount = sum(PlayCount)) %>%
      layer_points(size := 100, size.hover := 200,
                   fillOpacity := 0.2, fillOpacity.hover := 0.5,
                   stroke := 'black', strokeWidth := 1) %>%
      add_axis("x", title = "",
               properties = axis_props(labels = list(align = "right", 
                                                     fontSize = 12, 
                                                     angle = -45, 
                                                     fontWeight = "bold"))) %>%
      add_axis("y", title = "Play Count", title_offset = 40) %>%
      hide_legend('fill') %>%
      add_tooltip(function(datasetInput) datasetInput$PlayCount)
  })
  
  viz %>% bind_shiny("plot")
  
  output$stats <- renderText({
    paste("Total views based on your selections: ", count(filter(datasetInput(), Browser %in% input$browser, OS %in% input$os, Remote_IP %in% input$network)))
  })
  
}

shinyApp(ui = ui, server = server)
