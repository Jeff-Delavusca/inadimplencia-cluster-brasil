# -----------------------------------------------------
# 1. CARREGAMENTO DAS BIBLIOTECAS E DADOS
# -----------------------------------------------------


library(readxl)
library(tidyr)
library(dplyr)
library(ggplot2)
library(lubridate)
library(ggdendro)
library(dendextend)
library(reshape2)
library(ggrepel)
library(tibble)

# Leitura da base
BaseCompleta <- read_xlsx("C:/Users/acer/OneDrive/Área de Trabalho/MONOGRAFIA_ESPECIALIZACAO/Base_Estados.xlsx")


# Transformação para formato longo
BaseCompletaLongo <- BaseCompleta %>% 
  pivot_longer(cols = -Data, names_to = "Estados", values_to = "Taxa")


# Extração do ano da data
BaseCompletaLongo$Ano <- year(BaseCompletaLongo$Data)


# Reorganizando a coluna do ano
BaseCompletaLongo <- BaseCompletaLongo %>% 
  relocate(Ano, .after = Data)


# -----------------------------------------------------
# 2. AGRUPAMENTO POR ESTADO E ANO
# -----------------------------------------------------


BaseMedia <- BaseCompletaLongo %>% 
  group_by(Estados, Ano) %>% 
  summarise(MediaTaxa = mean(Taxa, na.rm = TRUE)) %>% 
  ungroup()


# Transformação para o formato wide
base_wide <- BaseMedia %>% 
  pivot_wider(names_from = Ano, values_from = MediaTaxa)


# Transformar Estados em rownames
matriz <- base_wide %>% 
  column_to_rownames(var = "Estados")


# ----------------------------------------------------
# 3. ANÁLISE DE CLUSTER HIERÁRQUICA
# ----------------------------------------------------


# Matriz de distâncias euclidianas
dis_matrix <- dist(matriz, method = "euclidean")


# Agrupamento hierárquico (linkage complete)
hc <- hclust(dis_matrix, method = "complete")


# Dendrograma estilizado com ggplot2
dendo <- as.dendrogram(hc)
dend_colored <- dendo %>% color_branches(k = 2) %>% set("branches_lwd", 0.8)
ggdend <- as.ggdend(dend_colored)
altura_corte <- 12


ggplot() +
  geom_segment(data = segment(ggdend),
               aes(x = x, y = y, xend = xend, yend = yend), 
               linewidth = 0.7, color = segment(ggdend)$col) +
  geom_text(data = label(ggdend), 
            aes(x = x, y = y - 1, label = label),
            angle = 0, hjust = 0.5, size = 3.5) + ### !!!
  geom_hline(yintercept = altura_corte, linetype = "dashed", color = "red") + 
  labs(
    title = "Figura 1- Dendrograma dos Estados (2004-2023)",
    x = "Estados",
    y = "Distância Euclidiana",
    caption = "Fonte: Banco Central do Brasil"
  ) + 
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold"),
    axis.text.x = element_blank(),
    axis.ticks.x = element_blank(),
    panel.grid = element_blank()
  )


# -----------------------------------------------------
# 4. DEFINIÇÃO DOS GRUPOS DE ESTADOS
# -----------------------------------------------------


grupo1 <- c("PE", "CE", "PI", "BA", "MA", "SE", "RR", "RJ", "AL", "AM", "PA", "PB", "RN")
grupo2 <- c("AP", "MT", "MTS", "SC", "PR", "RS", "MG", "SP", "DF", "ES", "AC", "TO", "GO", "RO")

dados_long <- BaseCompleta %>%
  pivot_longer(-Data, names_to = "Estado", values_to = "Taxa") %>%
  mutate(Grupo = case_when(
    Estado %in% grupo1 ~ "Grupo 1",
    Estado %in% grupo2 ~ "Grupo 2",
    TRUE ~ "Fora"
  ))


# -----------------------------------------------------
# 5. ESTATÍSTICAS DESCRITIVA POR GRUPO
# -----------------------------------------------------


tabela_estatisticas <- dados_long %>%
  group_by(Grupo) %>%
  summarise(
    Média = mean(Taxa, na.rm = TRUE),
    Mediana = median(Taxa, na.rm = TRUE),
    Mínimo = min(Taxa, na.rm = TRUE),
    Máximo = max(Taxa, na.rm = TRUE),
    Desvio_Padrão = sd(Taxa, na.rm = TRUE),
    Q1 = quantile(Taxa, 0.25, na.rm = TRUE),
    Q3 = quantile(Taxa, 0.75, na.rm = TRUE),
    CV = (sd(Taxa, na.rm = TRUE) / mean(Taxa, na.rm = TRUE)) * 100,
    n = n()
  )


# -----------------------------------------------------
# 6. MÉDIA MENSAL POR GRUPO E EVENTOS ECONÔMICOS
# -----------------------------------------------------


estat_mensal_grupo <- dados_long %>%
  group_by(Data, Grupo) %>%
  summarise(media = mean(Taxa, na.rm = TRUE)) %>%
  ungroup()

eventos <- data.frame(
  Evento = c("Crise 2008", "Ajuste Fiscal 2015–16", "Pandemia COVID-19", "Alta de Juros 2022"),
  Início = as.Date(c("2008-01-01","2015-01-01","2020-03-01","2022-03-01")),
  Fim = as.Date(c("2008-12-01","2016-12-01","2021-12-01","2023-12-01"))
)

eventos$Início <- as.POSIXct(eventos$Início)
eventos$Fim <- as.POSIXct(eventos$Fim)

ggplot(estat_mensal_grupo, aes(x = Data, y = media, color = Grupo)) +
  geom_line(size = 1) +
  scale_color_manual(values = c("Grupo 1" = "#D55E00", "Grupo 2" = "#009E73")) +
  geom_rect(data = eventos, aes(xmin = Início, xmax = Fim, ymin = -Inf, ymax = Inf),
            fill = "gray70", alpha = 0.2, inherit.aes = FALSE) +
  geom_text_repel(data = eventos, aes(x = Início, y = 10, label = Evento),
                  inherit.aes = FALSE, size = 3, direction = "y", nudge_x = 0.5) +
  labs(title = "Figura 4 – Média Mensal da Inadimplência com Eventos Econômicos",
       x = "Data", y = "Média (%)",
       caption = "Fonte: Banco Central do Brasil") +
  theme_minimal()


# -----------------------------------------------------
# 8.BOXPLOT DAS TAXAS POR GRUPO  
# -----------------------------------------------------


ggplot(dados_long, aes(x = Grupo, y = Taxa, fill = Grupo)) +
  geom_boxplot() +
  scale_fill_manual(values = c("Grupo 1" = "#D55E00", "Grupo 2" = "#009E73")) +
  labs(title = "Figura 3 – Distribuição da Inadimplência por Grupo de Estados",
       x = "Grupo", y = "Taxa de Inadimplência (%)") +
  theme_minimal()
