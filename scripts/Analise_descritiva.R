# ======================================================================
# Análise Descritiva - Taxa de Inadimplência das Operações de Crédito PF
# Brasil - Jan/2004 a Dez/2024
# Autor: Jéferson Delavusca Gonçalves
# Última atualização: 18/06/2025
# ======================================================================

# =========================================================
# 1. Carregamento das Bibliotecas
# =========================================================

library(tidyverse)
library(lubridate)
library(scales)
library(e1071)
library(geobr)
library(sf)

# =========================================================
# 2. Importação e Tratamento Inicial dos Dados
# =========================================================

# Importação da base
BaseCompleta <- read.csv("C:/Users/acer/OneDrive/Área de Trabalho/MONOGRAFIA_ESPECIALIZACAO/inadimplencia_PF_estados.csv")


# Ajuste da coluna de datas
BaseCompleta <- BaseCompleta %>% 
  mutate(Date = ymd(Date)) %>% 
  filter(Date <= ymd("2024-12-01"))


# =========================================================
# 3. Transformação para Formato Longo
# =========================================================

BaseCompletaLongo <- BaseCompleta %>% 
  pivot_longer(cols = -Date, 
               names_to = "estados", 
               values_to = "inadimplencia")


# =========================================================
# 4. Estatísticas Descritivas por Estado
# =========================================================


estatisticas_por_estado = BaseCompletaLongo %>% 
  group_by(estados) %>% 
  summarise(
    n = sum(!is.na(inadimplencia)),
    media = round(mean(inadimplencia, na.rm = TRUE),2),
    mediana = round(median(inadimplencia, na.rm = TRUE),2),
    minimo = round(min(inadimplencia, na.rm = TRUE),2),
    maximo = round(max(inadimplencia, na.rm = TRUE),2),
    amplitude = round(max(inadimplencia, na.rm = TRUE) - min(inadimplencia, na.rm = TRUE),2),
    q1 = round(quantile(inadimplencia, 0.25, na.rm = TRUE),2),
    q3 = round(quantile(inadimplencia, 0.75, na.rm = TRUE),2),
    iqr = round(IQR(inadimplencia, na.rm = TRUE),2),
    desvio_padrao = round(sd(inadimplencia, na.rm = TRUE),2),
    coef_var = round(sd(inadimplencia, na.rm = TRUE) / mean(inadimplencia, na.rm = TRUE),2),
    assimetria = round(skewness(inadimplencia, na.rm = TRUE),2),
    curtose = round(kurtosis(inadimplencia, na.rm = TRUE),2),
    prop_na = mean(is.na(inadimplencia))
  )


# =========================================================
# 5. Boxplot por Estado (Distribuição da Inadimplência)
# =========================================================


ggplot(BaseCompletaLongo, 
       aes(x = reorder(estados, inadimplencia), y = inadimplencia)) +
  geom_boxplot(fill = "skyblue") + 
  labs(
       x = "Estados", 
       y = "Taxa de Inadimplência (%)",
       caption = "Fonte: Banco Central do Brasil") + 
  theme_minimal(base_size = 12) + 
  theme(axis.text = element_text(color = "black"))

# =========================================================
# 6. Identificação de Outliers
# =========================================================


outliers_df = BaseCompletaLongo %>% 
  group_by(estados) %>% 
  mutate(
    Q1 = round(quantile(inadimplencia, 0.25, na.rm = TRUE),2),
    Q3 = round(quantile(inadimplencia, 0.75, na.rm = TRUE),2),
    IQR = round(IQR(inadimplencia, na.rm = TRUE),2),
    limite_inferior = Q1 - 1.5 * IQR,
    limite_superior = Q3 + 1.5 * IQR,
    outliers = inadimplencia < limite_inferior | inadimplencia > limite_superior,
    dif_limiar = inadimplencia - limite_superior) %>% 
  filter(outliers) %>% 
  select(estados, Date, inadimplencia, limite_superior, dif_limiar)


# Quantidade de outliers por estado (gráfico de barras)
outliers_df %>% 
  count(estados, sort = TRUE) %>% 
  ggplot(aes(x = reorder(estados, n), y = n)) +
  geom_col(fill = "skyblue") + 
  coord_flip() +
  labs(
    x = "Estados",
    y = "Quantidade",
    caption = "Fonte: Banco Central do Brasil") +
  theme_minimal(base_size = 12)+ 
  theme(axis.text = element_text(color = "black"))


# =========================================================
# 7. Evolução Temporal dos Outliers - Top 5 Estados
# =========================================================


top_estados <- c("GO", "MT", "SE", "CE", "AP")


outliers_top5 <- outliers_df %>% 
  filter(estados %in% top_estados)


ggplot(outliers_top5, aes(x = Date, y = inadimplencia, color = estados)) +
  geom_line(size = 1) +
  geom_point(size = 2) +
  labs(
    x = "Ano",
    y = "Quantidade de outliers",
    color = "Estados",
    caption = "Fonte: Banco Central do Brasil"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 11),
    axis.text = element_text(color = "black")
  )


# =========================================================
# 8. Frequência Anual de Outliers (Todos os Estados)
# =========================================================
 

outliers_df %>% 
  ungroup() %>% 
  select(Date, inadimplencia) %>% 
  mutate(ano = year(Date)) %>% 
  count(ano) %>%
  ggplot(aes(x = ano, y = n)) +
  geom_line(color = "firebrick", size = 1) +
  geom_point(color = "firebrick", size = 3) +
  labs(
    x = "Ano",
    y = "Quantidade de outliers",
    caption = "Fonte: Banco Central do Brasil"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    axis.text = element_text(color = "black")
  )


# =========================================================
# 9. Mapa Temático - Coeficiente de Variação por Estado
# =========================================================

# Importando o shapefile dos estados brasileiros (ano de referência 2020)
estados_shape <- read_state(year = 2020)

# Criando o dataframe com CV
cv_estados <- estatisticas_long %>% 
  filter(estatistica == "coef_var") %>% 
  select(estados, valor) 

# Fazendo o join espacial
mapa_cv <- estados_shape %>% 
  left_join(
    cv_estados,
    by = c("abbrev_state" = "estados")
  )

# Plot do mapa com gradiente de cor
ggplot(data = mapa_cv) +
  geom_sf(aes(fill = valor), color = "white", size = 0.2) +
  scale_fill_gradient(low = "#FFEDA0", high = "#F03B20", 
                      name = "Coeficiente de\nVariação (%)", 
                      labels = percent_format(accuracy = 1)) +
  theme_minimal() +
  labs(
    caption = "Fonte: Banco Central do Brasil"
  ) +
  theme(
    legend.title = element_text(size = 10),
    legend.text = element_text(size = 8)
  )

# ======================================================================
# FIM DA ANÁLISE DESCRITIVA
# ======================================================================



library(ggdendro)
library(dendextend)
library(reshape2)
library(ggrepel)
library(tibble)
library(cluster)


view(BaseCompleta)


# Transpondo a base
BaseTransposta <- BaseCompleta %>% 
  pivot_longer(
    cols = -Date,
    names_to = "Estado",
    values_to = "Taxa"
  ) %>% 
  pivot_wider(
    names_from = Date,
    values_from = Taxa
  )

view(BaseTransposta)





# Gerando a matriz de distâncias euclidianas
matriz_distancias <- dist(BaseTransposta %>% 
                            select(-Estado),
                          method = "euclidean")


# Visualizando as primeiras distâncias calculadas
as.matrix(matriz_distancias)[1:5, 1:5]


cluster_single <- hclust(matriz_distancias, method = "single")
cluster_complete <- hclust(matriz_distancias, method = "complete")
cluster_average <- hclust(matriz_distancias, method = "average")
cluster_ward <- hclust(matriz_distancias, method = "ward.D2")


cor_single <- cor(cophenetic(cluster_single), matriz_distancias)
cor_complete <- cor(cophenetic(cluster_complete), matriz_distancias)
cor_average <- cor(cophenetic(cluster_average), matriz_distancias)
cor_ward <- cor(cophenetic(cluster_ward), matriz_distancias)


print(cor_single)
print(cor_complete)
print(cor_average)
print(cor_ward)

library(dendextend)
library(ggdendro)

dendo <- as.dendrogram(cluster_ward)
dend_colored <- dendo %>% color_branches(k = 2) %>% set("branches_lwd", 0.8)



plot(cluster_single, 
     labels = BaseTransposta$Estado, 
     main = paste("Dendrograma - Single Linkage (Cophenetic =", 
                  round(cor_single, 3),")"))


plot(cluster_complete, labels = BaseTransposta$Estado, 
     main = paste("Dendrograma - Complete Linkage (Cophenetic =", 
                  round(cor_complete, 3),")"))


plot(cluster_average, labels = BaseTransposta$Estado, 
     main = paste("Dendrograma - Average Linkage (Cophenetic =", 
                  round(cor_average, 3),")"))


plot(cluster_ward, labels = BaseTransposta$Estado, 
     main = paste("Dendrograma - Ward.D2 (Cophenetic =", 
                  round(cor_ward,3),")"))

