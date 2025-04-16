# Análise de Cluster da Inadimplência por Estado no Brasil (2004–2023)

Este projeto aplica uma análise de cluster hierárquica para identificar padrões de inadimplência entre os estados brasileiros ao longo do tempo. Utilizando dados do Banco Central do Brasil, a proposta é agrupar Unidades Federativas com comportamentos similares em relação à taxa de inadimplência de crédito para pessoas físicas.

## 📊 Objetivo

Agrupar os 26 estados brasileiros e o Distrito Federal com base em seus perfis históricos de inadimplência, identificando padrões regionais e comportamentos semelhantes ao longo de um período de 20 anos (2004–2023).

## 📁 Estrutura do Projeto

- **/data/**: base de dados utilizada
- **/figures/**: gráficos gerados (dendrograma, boxplot, séries temporais)
- **/scripts/**: script em R com toda a análise reprodutível
- **README.md**: explicação do projeto, metodologia e resultados

## 🧪 Metodologia

- **Linguagem**: R
- **Pacotes principais**: `tidyverse`, `ggplot2`, `lubridate`, `dendextend`, `ggrepel`
- **Análise**:
  - Transformação e agregação da base
  - Cálculo de medidas descritivas
  - Análise de cluster hierárquico com linkage completo
  - Visualização com dendrogramas e boxplots
  - Comparação de grupos com eventos macroeconômicos

## 📈 Principais Resultados

- Foram identificados **dois grupos principais de estados**:
  - Grupo 1: estados com maior inadimplência, principalmente Norte/Nordeste
  - Grupo 2: estados com menores níveis, concentrados no Sul, Sudeste e Centro-Oeste
- O Grupo 1 apresentou maior média, desvio padrão e sensibilidade a choques macroeconômicos

## 📚 Fonte dos Dados

> Banco Central do Brasil (SGS – Sistema Gerenciador de Séries Temporais)  
> https://www.bcb.gov.br/estabilidadefinanceira/historicocreditopessoafisica

## ✍️ Autor

**Jeferson Delavusca Gonçalves**  
Pós-graduando em Estatística e Modelagem Quantitativa  
[LinkedIn](https://www.linkedin.com/in/jefersondelavusca/)
