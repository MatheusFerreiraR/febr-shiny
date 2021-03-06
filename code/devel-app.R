# Title: Repositório Brasileiro Livre para Dados Abertos do Solo - aplicação Shiny
# Version: 0.2.7
# Date: 2019-05-28
# Authors: Matheus Ferreira Ramos (matheusramos@alunos.utfpr.edu.br),
#          Alessandro Samuel-Rosa (alessandrorosa@utfpr.edu.br)
# License: GPL (>= 2)
# Encoding: UTF-8

# Bibliotecas -------------------------------------------------------------

library(shiny)
library(DT)
library(RCurl)
library(dplyr)
library(lubridate)
library(leaflet)
library(leaflet.extras)
library(stringr)
library(magrittr)
#library(glue)
#library(rgdal)
#library(sp)
#library(mapview)

# Definicoes ----------------------------------------

#Separador decimal
sep_dec <- ','

#Separador de colunas 
sep_col <- '\t'

febr_catalog <- "http://coral.ufsm.br/febr/catalog/"

# Definição de língua a ser utilizada nas tabelas geradas usando DT::datatable
dt_lang <- '//cdn.datatables.net/plug-ins/1.10.19/i18n/Portuguese-Brasil.json'

# Descarregamento dos dados -------------------------

#Variavel que esta recebendo direto do github febr-team, o superconjunto.txt
dados <- 
  getURL("https://raw.githubusercontent.com/febr-team/febr-data/master/data/febr-superconjunto.txt") %>% 
  read.table(text = ., sep = ";", dec = ",", stringsAsFactors = FALSE, header = TRUE)

# Definindo Variaveis ------------------------

#Variavel para apresentacao da tabela "Informacoes gerais"
vars_infoGerais <-
  c('dataset_id', 'dataset_titulo', 'autor_nome', 'organizacao_nome', #'numero_observacoes',
     'palavras_chave', 'area_conhecimento', 'dataset_licenca')

vars_infoGerais_name <- 
  c("Código de identificação do conjunto de dados no repositório",
    "Título (nome) do conjunto de dados.",
    "Nome do(a) autor(a) ou responsável pelo do conjunto de dados.",
    "Nome da organização que gerou ou é responsável pelo conjunto de dados.",
    "Termos que descrevem aspectos importantes do conjunto de dados.",
    "Área de especialidade da Agronomia -- Ciência do Solo, segundo tabelas 
    da CAPES e CNPq, à qual o conjunto de dados está relacionado.",
    " Licença de uso do conjunto de dados.") %>% 
  paste("<code>", vars_infoGerais, "</code>", ": ", ., ". ", sep = "", collapse = " ")


# Variavel para apresentacao da tabela localizacao
vars_amb <- 
  c('dataset_id', 'observacao_id', 'observacao_data', 'coord_x', 'coord_y', 'taxon_sibcs',
    'municipio_id', 'estado_id')

vars_amb_name <- 
  c("Código de identificação do conjunto de dados no repositório",
    "Código de identificação da observação do solo no conjunto de dados",
    "Data de observação do solo",
    "Longitude (SIRGAS 2000, graus)",
    "Latitude (SIRGAS 2000, graus)",
    "Classificação taxonômica pelo Sistema Brasileiro de Classificação de Solos",
    "Nome do município onde a observação do solo foi realizada",
    "Sigla da unidade federativa onde a observação do solo foi realizada") %>% 
  paste("<code>", vars_amb, "</code>", ": ", ., ". ", sep = "", collapse = " ")

#variavel para apresentacao da tabela analitica
vars_analiticas <-
  c('dataset_id', 'observacao_id', 'profund_sup', 'profund_inf',
    'terrafina', 'argila', 'silte', 'areia', 'carbono', 'ctc', 'ph', 'ce', 'dsi')

vars_analiticas_name <- 
  c("Código de identificação do conjunto de dados no repositório",
    "Código de identificação da observação do solo no conjunto de dados",
    "Profundidade superior da camada (cm)",
    "Profundidade inferior da camada (cm)",
    "Conteúdo de terra fina (g/kg)",
    "Conteúdo de argila (g/kg)",
    "Conteúdo de silte (g/kg)",
    "Conteúdo de areia (g/kg)",
    "Conteúdo de carbono (g/kg)",
    "Capacidade de troca de cátions potencial (cmol<sub>c</sub>/kg)",
    "pH em água (adimensional)",
    "Condutividade elétrica (mS/cm)",
    "Densidade do solo inteiro (kg/dm<sup>3</sup>)") %>% 
  paste("<code>", vars_analiticas, "</code>", ": ", ., ". ", sep = "", collapse = " ")

#Variavel para fazer o descarregamento
vars_download <-
  c('dataset_id', 'observacao_id', 'sisb_id', 'ibge_id', 'observacao_data', 'coord_x', 'coord_y', 
    'coord_precisao', 'coord_fonte', 'pais_id', 'estado_id', 'municipio_id', 'amostra_tipo', 'amostra_quanti',
    'amostra_area', 'taxon_sibcs', 'taxon_st', 'taxon_wrb', 'camada_id', 'amostra_id', 'camada_nome',
    'profund_sup', 'profund_inf', 'terrafina', 'argila', 'silte', 'areia', 'carbono', 'ctc', 'ph', 'dsi', 'ce')

# Variavel para receber o valor maximo da profundidade
profun_max <- 
  dados$profund_inf %>% 
  max(na.rm = TRUE)

# variavel para acessar avaliação 
link_avaliacao <- c('https://forms.gle/4L8WU6HjoLSUZBLc7')

# Inicio -------------------------------------------------

ui <- 
  fluidPage(
    titlePanel(a(href = 'http://coral.ufsm.br/febr/', img(src = 'logo.png')), 'febr'),
    tags$hr(),  
    fluidRow(
      column(
        width = 2,
        wellPanel(
          selectInput(inputId = "est", label = "UF", choices = NULL),
          selectInput("cid", "Município", choices =  NULL),
          selectInput("clasTox", "Taxonomia", choices = NULL), 
          sliderInput("data", "Ano", min = 1900, max = 2019, value = c(1900, 2019), sep=''),
          sliderInput("profun", "Profundidade (cm)", sep = '', min = 0, max = profun_max, value = c(0, profun_max))
        )
      ),
      
      # main / tab-dados
      column(
        width = 10,
        tabsetPanel(
          id = 'maintabs',
          
          # Aba "Informações gerais" ----
          tabPanel(
            title = tags$h3('Informações gerais'),
            value = 'tabInfoGerais', 
            # tags$br(),
            tags$p(class = 'lead'), 
            # tags$hr(), 
            DT::dataTableOutput("outInfoGerais"),
            tags$br(),
            tags$hr(), 
            HTML(vars_infoGerais_name)
          ),
          
          # Aba "Informações Ambientais" ----
          tabPanel(
            title = tags$h3('Informações ambientais'),
            value = 'tabInfoAmb', 
            # tags$br(),
            tags$p(class = 'lead'), 
            # tags$hr(), 
            DT::dataTableOutput("outAmbientais"),
            tags$br(),
            tags$hr(), 
            HTML(vars_amb_name)
          ),
          
          # Aba "Dados analiticos" ----
          tabPanel(
            title = tags$h3('Dados analíticos'),
            value = 'tabAnaliticos', 
            # tags$br(),
            tags$p(class = 'lead'), 
            # tags$hr(), 
            DT::dataTableOutput("outAnaliticos"),
            tags$br(),
            tags$hr(), 
            HTML(vars_analiticas_name)
          ),
          
          # Aba "Localização" ----
          tabPanel(
            # title = tags$h3('Mapa'),
            title = tags$h3('Localização'),
            value = 'map',
            fluidRow(
              column(
                width = 12, 
                tags$br(),
                # tags$hr(),
                leafletOutput('outMapa', width = '100%', height = '600'),
                actionButton("reset_button", "Ver tudo"),
                tags$style("#reset_button {float:left; margin-top:-45px; margin-left:20px; position:relative;}")
                # ),
                # tags$br()
              )
            )
          ),
          
          # Aba 'Descarregar' ----
          tabPanel(
            title = tags$h3('Descarregar'), value = 'download', 
            tags$br(), 
            # tags$hr(),
            fluidRow(
              # tags$br(),
              column(
                width = 6, offset = 3, 
                wellPanel(
                  tags$br(), 
                  h3('Clique no botão abaixo para descarregar os dados'), 
                  tags$br(), 
                  # radioButtons('formato', h3('Clique no botão para descarregar os dados: '), 
                  # tags$br(), inline = TRUE, choices = c('TXT')), 
                  style = 'text-align:center', 
                  tags$br(),
                  downloadButton(outputId = 'outDown', label = 'Descarregar', class = 'dlb'),
                  tags$head(tags$style(".dlb{width: 100%;}"))
                )
              )
            )
          ),
          
          tabPanel(
            title = tags$h3('DEIXE SUA OPINIÃO'), 
            value = 'avaliacao', 
            tags$br(),
            fluidRow(
              column(
                width = 8, 
                offset = 2,
                wellPanel(
                  tags$br(), 
                  h3('Olá, tudo bem?'),
                  tags$br(),
                  p('Esperamos que você tenha gostado da nova ferramenta de busca e visualização de dados.', 
                    br(),
                    'Mas nós sabemos que você deve ter ótimas ideias para deixá-la ainda melhor.',
                    br(),
                    'Acesse o formulário que preparamos em',
                    a(href = link_avaliacao, glue::glue(link_avaliacao)),
                    ' e deixe a sua opinião.',
                    br(),
                    'São apenas 5 minutinhos!')
                )
              )
            )
          )
        )
      )
    )
  )

server <- function (input, output, session) {
  
  # Funções auxiliares ------------------------------------------------------
  
  #Função para apresentação das tabelas
  dataTables <-
    function (x) {
      if (input$maintabs == 'tabInfoAmb') {
        x %>%
          DT::datatable(
            filter = 'top', escape = FALSE, rownames = FALSE, selection = 'none',
            options = list(lengthMenu = c(5, 10, 30, 50), pageLength = 5, rownames = FALSE,
                           language = list(url = dt_lang))) %>%
          # Função para alterar separador decimal
          formatCurrency(., c('coord_x', 'coord_y'), currency = "", digits = 8, dec.mark = ',')
        
      } else if (input$maintabs == 'tabAnaliticos') {
        x %>%
          DT::datatable(
            filter = 'top', escape = FALSE, rownames = FALSE, selection = 'none',
            options = list(lengthMenu = c(5, 10, 30, 50), pageLength = 5, rownames = FALSE,
                           language = list(url = dt_lang))) %>%
          formatCurrency(., c('carbono', 'ctc', 'ph', 'ce', 'dsi'), currency = "", digits = 1, dec.mark = ',')
          # formatCurrency(., c('Carbono', 'CTC', 'pH', 'CE', 'DSI'), currency = "", digits = 1, dec.mark = ',')
        
      } else if (input$maintabs == 'tabInfoGerais') {
        x %>%
          DT::datatable(
            filter = 'top', escape = FALSE, rownames = FALSE, selection = 'none',
            options = list(lengthMenu = c(5, 10, 30, 50), pageLength = 5, rownames = FALSE,
                           language = list(url = dt_lang)))
      }
    }
  
  # Função para adicionar marcadores/pontos no mapa. Primeiro são removidas as observações sem coordenadas
  # espacias.
  marks <-
    function (my.map, my.points) {
      my.points %<>% 
        dplyr::filter(!is.na(coord_x) | !is.na(coord_y))
      my.map %>%
        addAwesomeMarkers(
          lng = my.points$coord_x, lat = my.points$coord_y,
          icon = awesomeIcons(icon = "info-sign", markerColor = "#b22222", iconColor = "#fffff0"),
          clusterOptions = markerClusterOptions(),
          label = glue::glue('{my.points$observacao_id}@{my.points$dataset_id}'),
          popup = glue::glue(
            "<a href={febr_catalog}{my.points$dataset_id} target='_blank'> Mais informações?</a>"))
    }
  
  ### UpdateInputs ---------------------------------------------------------
  
  # funcao reativa para atualizao o selectInput do estado e ordenar alfabeticamente
  observe({ 
    estados <-
      dados %>%
      arrange(estado_id) %>%
      select(estado_id) %>% 
      unique() %>% 
      na.exclude()
    updateSelectInput(session, "est", "UF", choices = c("Todos", estados))
  })
  
  # funcao reativa para atualizao o selectInput da cidade para apresentar 
  # somente as cidades do estado dentro do superconjunto e ordenar alfabeticamente
  observe({ 
    cidades <- 
      dados %>% 
      filter(dados$estado_id == input$est) %>% 
      select(municipio_id) %>% 
      arrange(-desc(municipio_id))
    updateSelectInput(session, "cid", "Município", choices = c("Todos", unique(cidades)))
  })
  
  # funcao reativa para atualizao o selectInput da classificacao taxonomica apresentando
  # somente as taxonomia que tem no estado ou cidade selecionado e ordenar alfabeticamente 
  observe({ 
    if (input$cid != 'Todos') {
      classificacao <- dados %>% 
        filter((dados$estado_id == input$est) & (dados$municipio_id == input$cid )) %>% 
        select(taxon_sibcs) %>%
        arrange(-desc(taxon_sibcs))
      updateSelectInput(session, "clasTox", "Taxonomia", choices = c("Todos", unique(classificacao)))
      
    } else if (input$est == 'Todos') {
      classificacao <- 
        dados %>% 
        select(taxon_sibcs) %>% 
        arrange(-desc(taxon_sibcs))
      updateSelectInput(session, "clasTox", "Taxonomia", choices = c("Todos", unique(classificacao)))
      
    } else if (input$est != 'Todos') {
      classificacao <- dados %>% 
        filter(dados$estado_id == input$est) %>% 
        select(taxon_sibcs) %>% 
        arrange(-desc(taxon_sibcs))
      updateSelectInput(session, "clasTox", "Taxonomia", choices = c("Todos", unique(classificacao)))
    }
  })
  
  # Atualizar a profundida maxima
  observe({
    updateSliderInput(session, 'profun', 'Profundidade (cm)', min = '0',
                      max = profun_max, value = c(input$profun[1], input$profun[2]))
  })
  
  # Atualizar o ano minimo e maximo  
  observe({
    year_range <- dados$observacao_data %>% lubridate::year() %>% range(na.rm = TRUE) 
    updateSliderInput(
      session, "data", "Ano", min = year_range[1], max = year_range[2],
      value = c(input$data[1], input$data[2]) )
  })
  
  # Update do botao do mapa "home button"
  observe({
    input$reset_button
    leafletProxy("outMapa") %>% setView(lng = -50.8663589, lat = -12.9214564, zoom = 4)
  })
  
  # Update do Download 
  # observe({
  #   updateRadioButtons(session,'formato', selected = 'TXT')
  # })
  
  
  # filtragem -------------------------------------------------------------------
  
  # filtroTodos, ultilizado quando o usuario nao altera os estado, cidade e taxonomia
  filtroTodos <- 
    reactive({
      # Esse filter é usado em todos filtros, ele diz se a profundade esta entre o input profun
      # filtra tambem, os anos da observacao_data, se estao entre o input data
      # essa filtragem de profundidade e ano tambem eh aplicada nos outros filtros abaixo
      my.data <-
        dados %>%
        dplyr::filter(
          (
            profund_sup %in% input$profun[1]:input$profun[2] & 
              profund_inf %in% input$profun[1]:input$profun[2] | 
              is.na(profund_sup) | 
              is.na(profund_inf)
          ) & (
            year(observacao_data) %in% input$data[1]:input$data[2] | 
              is.na(observacao_data)
          )
        )
      
      #Condicoes para apresentacao das abas
      if (input$maintabs == 'tabInfoGerais') {
        # Para a tabela informacoes gerais, deixa-se somente um dataset_id, sem repeticao
        my.data %>% 
          select(vars_infoGerais) %>% 
          distinct(dataset_id, .keep_all = TRUE) %>% 
          #Funcao para colocar link no dataset_id
          mutate(
            dataset_id = glue::glue("<a href={febr_catalog}{dataset_id} target='_blank'>{dataset_id}</a>"))
        
      } else if (input$maintabs == 'tabInfoAmb') {
        # Para a tabela informacoes ambientais, remove-se as observacoes repetidas 
        my.data %>% 
          select(vars_amb) %>% 
          distinct(dataset_id, observacao_id, .keep_all = TRUE) %>% 
          mutate(
            dataset_id = glue::glue("<a href={febr_catalog}{dataset_id} target='_blank'>{dataset_id}</a>"))
        
      } else if (input$maintabs == 'tabAnaliticos') {
        # Para a tabela analitica, apresenta em condicao de ordem crescente da profundidade 
        my.data %>% 
          select(!!!vars_analiticas) %>%
          mutate(
            dataset_id = 
              glue::glue("<a href={febr_catalog}{dataset_id} target='_blank'>{dataset_id}</a>")) %>% 
          group_by(dataset_id, observacao_id) %>% 
          arrange(profund_sup, .by_group = TRUE)
        
      } else if (input$maintabs == 'download') {
        # Para a aba de download, seleciona a variavel que contem as informacoes para download definida no 
        # comeco do codigo
        my.data %>% 
          select(vars_download)
        
      } else {
        # Para a aba do mapa, Apresenta as variaveis para plotagem no mapa, apresentar o label e o popup 
        # corretamente
        # removendo tambem, as observacoes repetidas
        my.data %>% 
          select(vars_amb) %>% 
          distinct(dataset_id, observacao_id, .keep_all = TRUE)
      }
    })
  
  # Filtro de UF ----
  # filtroEst, filtra os estados, 
  # ultilizado quando o usuario altera somente o estado (input est)
  filtroEst <- 
    reactive({ 
      my.data <-
        dados %>%
        dplyr::filter(
          (
            estado_id == input$est 
          ) & (
            profund_sup %in% input$profun[1]:input$profun[2] &
              profund_inf %in% input$profun[1]:input$profun[2] |
              is.na(profund_sup) | 
              is.na(profund_inf)
          ) & (
            year(observacao_data) %in% input$data[1]:input$data[2] | 
              is.na(observacao_data)
          )
        )
      
      if (input$maintabs == 'tabInfoGerais') {
        my.data %>% 
          select(vars_infoGerais) %>% 
          distinct(dataset_id, .keep_all = TRUE) %>%
          mutate(
            dataset_id = glue::glue("<a href={febr_catalog}{dataset_id} target='_blank'>{dataset_id}</a>"))
        
      } else if (input$maintabs == 'tabInfoAmb') {
        my.data %>% 
          select(vars_amb) %>% 
          distinct(dataset_id, observacao_id, .keep_all = TRUE) %>% 
          mutate(
            dataset_id = glue::glue("<a href={febr_catalog}{dataset_id} target='_blank'>{dataset_id}</a>"))
        
      } else if (input$maintabs == 'tabAnaliticos') {
        my.data %>% 
          select(!!!vars_analiticas) %>%
          mutate(
            dataset_id = 
              glue::glue("<a href={febr_catalog}{dataset_id} target='_blank'>{dataset_id}</a>")) %>% 
          group_by(dataset_id, observacao_id) %>% 
          arrange(profund_sup, .by_group = TRUE)
        
      } else if (input$maintabs == 'download') {
        my.data %>% 
          select(vars_download)
        
      } else {
        my.data %>% 
          select(vars_amb) %>% 
          distinct(dataset_id, observacao_id, .keep_all = TRUE)
      }
    })
  
  # filtroCid, filtra as cidades que contem dentro do estado selecionado
  filtroCid <- reactive({
    my.data <-
      dados %>%
       dplyr::filter((dados$municipio_id == input$cid & dados$estado_id == input$est) & 
          (
          profund_sup %in% input$profun[1]:input$profun[2] &
          profund_inf %in% input$profun[1]:input$profun[2] |
          is.na(profund_sup) | 
          is.na(profund_inf)
      ) & (
          year(observacao_data) %in% input$data[1]:input$data[2] | 
          is.na(observacao_data)
        )
      )
        
    if (input$maintabs == 'tabInfoGerais') {
      my.data %>% 
        select(vars_infoGerais) %>% 
        distinct(dataset_id, .keep_all = TRUE) %>%
        mutate(
          dataset_id = glue::glue("<a href={febr_catalog}{dataset_id} target='_blank'>{dataset_id}</a>"))
      
    } else if (input$maintabs == 'tabInfoAmb') {
      my.data %>% 
        select(vars_amb) %>% 
        distinct(dataset_id, observacao_id, .keep_all = TRUE) %>% 
        mutate(
          dataset_id = glue::glue("<a href={febr_catalog}{dataset_id} target='_blank'>{dataset_id}</a>"))
      
    } else if (input$maintabs == 'tabAnaliticos') {
      my.data %>% 
        select(!!!vars_analiticas) %>%
        mutate(
          dataset_id = 
            glue::glue("<a href={febr_catalog}{dataset_id} target='_blank'>{dataset_id}</a>")) %>% 
        group_by(dataset_id, observacao_id) %>% 
        arrange(profund_sup, .by_group = TRUE)
      
    } else if (input$maintabs == 'download') {
      my.data %>% 
        select(vars_download)
      
    } else {
      my.data %>% 
        select(vars_amb) %>% 
        distinct(dataset_id, observacao_id, .keep_all = TRUE)
    }
  })
  
  # filtroEstTax, filtra a classificacao taxonomica pelo estado, 
  # ultilizado quando o usuario altera somente a taxonomia e o estado
  filtroEstTax <- reactive({
    my.data <-
      dados %>%
       dplyr::filter((input$est == dados$estado_id & input$clasTox == dados$taxon_sibcs) & 
        (
          profund_sup %in% input$profun[1]:input$profun[2] &
            profund_inf %in% input$profun[1]:input$profun[2] |
            is.na(profund_sup) | 
            is.na(profund_inf)
        ) & (
          year(observacao_data) %in% input$data[1]:input$data[2] | 
            is.na(observacao_data)
        )
      )
    
    if (input$maintabs == 'tabInfoGerais') {
      my.data %>% 
        select(vars_infoGerais) %>% 
        distinct(dataset_id, .keep_all = TRUE) %>%
        mutate(
          dataset_id = glue::glue("<a href={febr_catalog}{dataset_id} target='_blank'>{dataset_id}</a>"))
      
    } else if (input$maintabs == 'tabInfoAmb') {
      my.data %>% 
        select(vars_amb) %>% 
        distinct(dataset_id, observacao_id, .keep_all = TRUE) %>% 
        mutate(
          dataset_id = glue::glue("<a href={febr_catalog}{dataset_id} target='_blank'>{dataset_id}</a>"))
      
    } else if (input$maintabs == 'tabAnaliticos') {
      my.data %>% 
        select(!!!vars_analiticas) %>%
        mutate(
          dataset_id = 
            glue::glue("<a href={febr_catalog}{dataset_id} target='_blank'>{dataset_id}</a>")) %>% 
        group_by(dataset_id, observacao_id) %>% 
        arrange(profund_sup, .by_group = TRUE)
      
    } else if (input$maintabs == 'download') {
      my.data %>% 
        select(vars_download)
      
    } else {
      my.data %>% 
        select(vars_amb) %>% 
        distinct(dataset_id, observacao_id, .keep_all = TRUE)
    }
  })
  
  # filtroEstCidTax, filtra ultilizado quando o usuario altera todos inputs
  # taxonomia, cidade e estado
  
  filtroEstCidTax <- reactive({
    my.data <-
      dados %>%
       dplyr::filter((input$est == dados$estado_id & input$clasTox == dados$taxon_sibcs & 
          dados$municipio_id == input$cid) & 
        (
          profund_sup %in% input$profun[1]:input$profun[2] &
            profund_inf %in% input$profun[1]:input$profun[2] |
            is.na(profund_sup) | 
            is.na(profund_inf)
        ) & (
          year(observacao_data) %in% input$data[1]:input$data[2] | 
            is.na(observacao_data)
        )
      )
    
    if (input$maintabs == 'tabInfoGerais') {
      my.data %>% 
        select(vars_infoGerais) %>% 
        distinct(dataset_id, .keep_all = TRUE) %>%
        mutate(
          dataset_id = glue::glue("<a href={febr_catalog}{dataset_id} target='_blank'>{dataset_id}</a>"))
      
    } else if (input$maintabs == 'tabInfoAmb') {
      my.data %>% 
        select(vars_amb) %>% 
        distinct(dataset_id, observacao_id, .keep_all = TRUE) %>% 
        mutate(
          dataset_id = glue::glue("<a href={febr_catalog}{dataset_id} target='_blank'>{dataset_id}</a>"))
      
    } else if (input$maintabs == 'tabAnaliticos') {
      my.data %>% 
        select(!!!vars_analiticas) %>%
        mutate(
          dataset_id = 
            glue::glue("<a href={febr_catalog}{dataset_id} target='_blank'>{dataset_id}</a>")) %>% 
        group_by(dataset_id, observacao_id) %>% 
        arrange(profund_sup, .by_group = TRUE)
      
    } else if (input$maintabs == 'download') {
      my.data %>% 
        select(vars_download)
      
    } else {
      my.data %>% 
        select(vars_amb) %>% 
        distinct(dataset_id, observacao_id, .keep_all = TRUE)
    }
  })
  
  # filtroTax, filtra a classificacao taxonomica, 
  # ultilizado quando o usuario altera somente a taxonomia (input clasTox)
  filtroTax <- reactive({
    my.data <-
      dados %>%
      dplyr::filter((input$clasTox == dados$taxon_sibcs) & 
        (
          profund_sup %in% input$profun[1]:input$profun[2] &
            profund_inf %in% input$profun[1]:input$profun[2] |
            is.na(profund_sup) | 
            is.na(profund_inf)
        ) & (
          year(observacao_data) %in% input$data[1]:input$data[2] | 
            is.na(observacao_data)
        )
      )
    
    if (input$maintabs == 'tabInfoGerais') {
      my.data %>% 
        select(vars_infoGerais) %>% 
        distinct(dataset_id, .keep_all = TRUE) %>%
        mutate(
          dataset_id = glue::glue("<a href={febr_catalog}{dataset_id} target='_blank'>{dataset_id}</a>"))
      
    } else if (input$maintabs == 'tabInfoAmb') {
      my.data %>% 
        select(vars_amb) %>% 
        distinct(dataset_id, observacao_id, .keep_all = TRUE) %>% 
        mutate(
          dataset_id = glue::glue("<a href={febr_catalog}{dataset_id} target='_blank'>{dataset_id}</a>"))
      
    } else if (input$maintabs == 'tabAnaliticos') {
      my.data %>% 
        select(!!!vars_analiticas) %>%
        mutate(
          dataset_id = 
            glue::glue("<a href={febr_catalog}{dataset_id} target='_blank'>{dataset_id}</a>")) %>% 
        group_by(dataset_id, observacao_id) %>% 
        arrange(profund_sup, .by_group = TRUE)
      
    } else if (input$maintabs == 'download') {
      my.data %>% 
        select(vars_download)
      
    } else {
      my.data %>% 
        select(vars_amb) %>% 
        distinct(dataset_id, observacao_id, .keep_all = TRUE)
    }
  })
  
  # Tabela de Informacoes Gerais --------------------------------------------------------------
  
  output$outInfoGerais <- DT::renderDataTable({
    if (input$est == 'Todos' && input$clasTox == 'Todos') {
      filtroTodos() %>% 
        dataTables()
    } else if (((input$est != 'Todos') && (input$clasTox == 'Todos') && (input$cid == 'Todos'))) {
      filtroEst() %>% 
        dataTables()
    } else if (((input$est != 'Todos') && (input$clasTox == 'Todos') && (input$cid != 'Todos'))) {
      filtroCid() %>% 
        dataTables()
    } else if (((input$est != 'Todos') && (input$clasTox != 'Todos') && (input$cid == 'Todos'))) {
      filtroEstTax() %>% 
        dataTables()
    } else if (((input$est != 'Todos') && (input$clasTox != 'Todos') && (input$cid != 'Todos'))) {
      filtroEstCidTax() %>% 
        dataTables()
    } else if (((input$est == 'Todos') && (input$clasTox != 'Todos') && (input$cid == 'Todos'))) {
      filtroTax() %>% 
        dataTables()
    }
  })
  
  # Tabela de Informacoes ambientais --------------------------------------------------------------
  
  # Apresentacao da tabela localizacao conforme for filtrado. 
  output$outAmbientais <- 
    DT::renderDataTable({
      if (input$est == 'Todos' && input$clasTox == 'Todos') {
        filtroTodos() %>% 
          dataTables()
      } else if (input$est != 'Todos' && input$clasTox == 'Todos' && input$cid == 'Todos') {
        filtroEst() %>% 
          dataTables()
      } else if (input$est != 'Todos' && input$clasTox == 'Todos' && input$cid != 'Todos') {
        filtroCid() %>% 
          dataTables()
      } else if (input$est != 'Todos' && input$clasTox != 'Todos' && input$cid == 'Todos') {
        filtroEstTax() %>% 
          dataTables()
      } else if (input$est != 'Todos' && input$clasTox != 'Todos' && input$cid != 'Todos') {
        filtroEstCidTax() %>% 
          dataTables()
      } else if (input$est == 'Todos' && input$clasTox != 'Todos' && input$cid == 'Todos') {
        filtroTax() %>% 
          dataTables()
      }
    })
  
  # Tabela Analitica --------------------------------------------------------------------------------------------
  
  # Apresentacao da tabela analitica conforme for filtrado. 
  output$outAnaliticos <- DT::renderDataTable({
    if (input$est == 'Todos' && input$clasTox == 'Todos') {
      filtroTodos() %>% 
        dataTables()
    } else if (((input$est != 'Todos') && (input$clasTox == 'Todos') && (input$cid == 'Todos'))) {
      filtroEst() %>% 
        dataTables()
    } else if (((input$est != 'Todos') && (input$clasTox == 'Todos') && (input$cid != 'Todos'))) {
      filtroCid() %>% 
        dataTables()
    } else if (((input$est != 'Todos') && (input$clasTox != 'Todos') && (input$cid == 'Todos'))) {
      filtroEstTax() %>% 
        dataTables()
    } else if (((input$est != 'Todos') && (input$clasTox != 'Todos') && (input$cid != 'Todos'))) {
      filtroEstCidTax() %>% 
        dataTables()
    } else if (((input$est == 'Todos') && (input$clasTox != 'Todos') && (input$cid == 'Todos'))) {
      filtroTax() %>% 
        dataTables()
    }
  })
  
  
  # Mapa -------------------------------------------------------------------------------------------------    
  
  # Apresentacao do mapa conforme for filtrado. 
  output$outMapa <- renderLeaflet({
    
    #Variavel "m" esta recebendo as informacoes de providerTiles e miniMap
    m <- leaflet() %>% 
      #addResetMapButton() %>% 
      #setView(lng = -50.8663589, lat = -12.9214564, zoom = 4) %>%
      addProviderTiles("Esri.WorldStreetMap", group = "Esri.WorldStreetMap") %>% 
      # addProviderTiles("CartoDB.Positron", group = "CartoDB.Positron") %>% 
      addProviderTiles("Esri.WorldImagery", group = "Esri.WorldImagery") %>%
      addLayersControl(
        baseGroups = c("Esri.WorldStreetMap", "Esri.WorldImagery"),
        # baseGroups = c("Esri.WorldStreetMap", "CartoDB.Positron", "Esri.WorldImagery"),
        options = layersControlOptions(collapsed = TRUE)) %>%
      addMiniMap() 
    
    if (input$est == 'Todos' && input$clasTox == 'Todos') {
      #tmp e uma variavel temporaria para nao precisar ativar o filtro com muita frequencia
      tmp <- filtroTodos()
      
      # Aqui passamos a varia "m" e "tmp" para a funcao "marks" 
      # para adicionar os marcadores do mapa conforme for filtrado
      m %>% 
        marks(tmp)
    } else if (((input$est != 'Todos') && (input$clasTox == 'Todos') && (input$cid == 'Todos'))) {
      tmp <- filtroEst()
      m %>%
        marks(., tmp)
    } else if (((input$est != 'Todos') && (input$clasTox == 'Todos') && (input$cid != 'Todos'))) {
      tmp <- filtroCid()    
      m %>%
        marks(., tmp)
    } else if (((input$est != 'Todos') && (input$clasTox != 'Todos') && (input$cid == 'Todos'))) {
      tmp <- filtroEstTax()      
      m %>%
        marks(., tmp)
    } else if (((input$est != 'Todos') && (input$clasTox != 'Todos') && (input$cid != 'Todos'))) {
      tmp <- filtroEstCidTax()       
      m %>%
        marks(., tmp)
    } else if (((input$est == 'Todos') && (input$clasTox != 'Todos') && (input$cid == 'Todos'))) {
      tmp <- filtroTax()      
      m %>%
        marks(., tmp)
    }
  })
  
  
  # Download --------------------------------------------------------------------------------------------------
  
  # Variavel reativa conforme selecao do usuario (ainda nao ultilizada, pois ha apenas uma opcao)
  # fileExt <- reactive({
  #   switch (input$formato,
  #           'TXT' = 'txt')
  # })
  
  # write_json <-
  #   function (x, file) {
  #     x %>% 
  #       # dplyr::group_by(dataset_id) %>% 
  #       split(f = glue::glue("{.$observacao_id}@{.$dataset_id}")) %>%
  #       unname() %>%
  #       lapply(function (y) unname(split(x = y, f = y$camada_nome))) %>% 
  #       rjson::toJSON(indent = 2) %>% 
  #       jsonlite::write_json(path = file)
  #   }
  write_csv <-
    function (x, file) {
      write.table(x = x, file = file, sep = sep_col, dec = sep_dec, row.names = FALSE)
    }
  
  output$outDown <- downloadHandler(
    
    # funcao para o nome do arquivo que esta sendo descarregado
    filename = function () {
      # paste('dados-febr-', Sys.Date(), ".", fileExt(), sep = '')
      paste('dados-febr-', Sys.Date(), ".", "txt", sep = '')
      # paste('dados-febr-', Sys.Date(), ".", "json", sep = '')
    },
    
    # funcao para escreve arquivo que sera descarregado aplicado a filtragem
    content = function (file) {
      if (input$est == 'Todos' & input$clasTox == 'Todos') {
        out <- filtroTodos()
        write_csv(x = out, file = file)
        # write_json(x = out, file = file)
        
      } else if (((input$est != 'Todos') && (input$clasTox == 'Todos') && (input$cid == 'Todos'))) {
        out <- filtroEst()
        write_csv(x = out, file = file)
        # write_json(x = out, file = file)
        
      } else if (((input$est != 'Todos') && (input$clasTox == 'Todos') && (input$cid != 'Todos'))) {
        out <- filtroCid()
        write_csv(x = out, file = file)
        # write_json(x = out, file = file)
        
      } else if (((input$est != 'Todos') && (input$clasTox != 'Todos') && (input$cid == 'Todos'))) {
        out <- filtroEstTax()
        write_csv(x = out, file = file)
        # write_json(x = out, file = file)
        
      } else if (((input$est != 'Todos') && (input$clasTox != 'Todos') && (input$cid != 'Todos'))) {
        out <- filtroEstCidTax()
        write_csv(x = out, file = file)
        # write_json(x = out, file = file)
        
      } else if (((input$est == 'Todos') && (input$clasTox != 'Todos') && (input$cid == 'Todos'))) {
        out <- filtroTax()
        write_csv(x = out, file = file)
        # write_json(x = out, file = file)
      }
    }
  )
}

shinyApp(ui = ui, server = server)
