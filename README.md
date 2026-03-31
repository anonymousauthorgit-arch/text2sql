# Text2SQL

Sistema de conversao de perguntas em linguagem natural para consultas SQL, voltado para gestao de estoque hospitalar e farmaceutico. Utiliza modelos de linguagem (LLMs) com suporte a RAG (Retrieval-Augmented Generation) para gerar, executar e avaliar consultas SQL automaticamente.

## Visao geral

O pipeline completo segue estas etapas:

1. **Geracao de ground truth** -- queries SQL de referencia com substituicao de parametros
2. **Execucao do ground truth** -- executa as queries de referencia no banco de dados
3. **Construcao do indice RAG** -- indexa o schema do banco para recuperacao semantica
4. **Geracao de queries** -- o LLM converte perguntas em SQL usando contexto do RAG
5. **Execucao das queries geradas** -- executa as queries do modelo no banco
6. **Comparacao** -- compara resultados do modelo com o ground truth
7. **Exportacao de relatorio** -- gera relatorio HTML com metricas e graficos

## Requisitos

- Python 3.12+
- PostgreSQL
- GPU com suporte CUDA (recomendado para inferencia com modelos grandes)

## Instalacao

O projeto usa [uv](https://docs.astral.sh/uv/) como gerenciador de pacotes.

```bash
uv sync
```

Para instalar dependencias de desenvolvimento (Jupyter, quantizacao):

```bash
uv sync --group dev
```

## Configuracao

### Banco de dados

Crie um arquivo `.env` na raiz do projeto com as credenciais de conexao:

```
DB_HOST=localhost
DB_PORT=10001
DB_NAME=text2sql
DB_USER=seu_usuario
DB_PASSWORD=sua_senha
```

Alternativamente, edite `config/execute_config.yaml`.

### Modelo LLM

O modelo e parametros de geracao sao definidos em `config/generate_config.yaml`:

```yaml
model:
  name: "Qwen/Qwen3-32B-AWQ"
  max_new_tokens: 32768
  temperature: 0.0001
  do_sample: false
  enable_thinking: true
```

## Uso

O CLI unificado `text2sql` expoe todos os comandos:

```
text2sql [COMANDO]

  generate      Gera queries SQL a partir de perguntas em linguagem natural
  execute       Executa queries SQL no banco de dados
  ground-truth  Gera queries de referencia com substituicao de parametros
  compare       Compara resultados do modelo com o ground truth
  rag           Gerencia o indice RAG (construcao e consulta)
  ui            Inicia o dashboard web (Shiny)
```

### Pipeline completo

Execute todas as etapas de uma vez:

```bash
bash run_pipeline.sh
```

Ou passo a passo:

```bash
# 1. Gerar e executar ground truth
text2sql ground-truth run --run "default"
text2sql execute run \
  --queries "data/queries/ground_truth/default" \
  --results "data/results/ground_truth/default"

# 2. Construir indice RAG
text2sql rag run

# 3. Gerar queries com o modelo
text2sql generate run --model "Qwen/Qwen3-32B-AWQ" --run "default"

# 4. Executar queries geradas
text2sql execute run \
  --queries "data/queries/Qwen3-32B-AWQ/default" \
  --results "data/results/Qwen3-32B-AWQ/default"

# 5. Comparar e exportar relatorio
text2sql compare run --gt "default" --model "Qwen3-32B-AWQ/default"
text2sql compare export "Qwen3-32B-AWQ/default"
```

### Dashboard web

```bash
text2sql ui --port 8000 --host 127.0.0.1
```

## Estrutura do projeto

```
text2sql_application/
├── app/
│   ├── cli/                  # Interface de linha de comando (Typer)
│   │   ├── main.py           # Ponto de entrada do CLI
│   │   ├── generate_queries/ # Pipeline de geracao de SQL
│   │   ├── execute_sql/      # Execucao de queries no banco
│   │   ├── ground_truth/     # Geracao de ground truth
│   │   ├── compare/          # Comparacao de resultados
│   │   └── rag_index/        # Gestao do indice RAG
│   ├── llm/
│   │   ├── model/            # Carregamento de modelos (Transformers)
│   │   ├── rag/              # Indexador e recuperador semantico
│   │   └── prompt/           # Templates de prompt
│   ├── metrics/              # Calculo de metricas (precisao, recall, F1)
│   ├── ui/                   # Dashboard Shiny
│   └── utils/                # Utilitarios (exportacao HTML, dataframes)
├── config/                   # Arquivos de configuracao YAML
├── data/
│   ├── questions.csv         # Perguntas de avaliacao (20 questoes)
│   ├── schema.yaml           # Schema do banco de dados
│   ├── queries/              # Queries SQL geradas
│   └── results/              # Resultados de execucao e metricas
├── notebooks/                # Notebooks Jupyter para analise
├── pyproject.toml            # Configuracao do projeto e dependencias
└── run_pipeline.sh           # Script de execucao do pipeline completo
```

## Dados e dominio

O sistema opera sobre um banco de dados hospitalar (Tasy) com foco em gestao de estoque farmaceutico. As principais tabelas sao:

| Tabela | Descricao |
|--------|-----------|
| `cadastro_mat_med` | Catalogo de materiais e medicamentos |
| `estoque_mat_med` | Estoque atual por local de armazenamento |
| `movimento_mat_med` | Movimentacoes (consumo, perdas, transferencias) |
| `compras_mat_med` | Registros de compras com lote e validade |

As 20 perguntas de avaliacao cobrem cenarios como: estoque critico, validade de medicamentos, historico de consumo, impacto financeiro de perdas, ponto de ressuprimento e tendencias de consumo.

## Metricas de avaliacao

Para **questoes de listagem** (retornam conjuntos de itens):
- Precisao, Recall, F1-Score e Acuracia baseados em comparacao multiset

Para **questoes de quantidade** (retornam valores numericos):
- Comparacao exata com tolerancia relativa de 1% para queries dependentes de data

## RAG

O sistema RAG usa o modelo `neuralmind/bert-large-portuguese-cased` para criar embeddings semanticos do schema do banco. Dado uma pergunta, recupera as tabelas e colunas mais relevantes (threshold de similaridade configuravel) e injeta o DDL correspondente no prompt do LLM.

## Arquivos de configuracao

| Arquivo | Finalidade |
|---------|-----------|
| `config/generate_config.yaml` | Modelo, RAG, templates e regras de negocio |
| `config/execute_config.yaml` | Conexao com o banco e timeout de queries |
| `config/ground_truth_config.yaml` | Substituicao de parametros no ground truth |
| `config/compare_config.yaml` | Pares de ground truth e modelo para comparacao |
| `config/rag_index_config.yaml` | Modelo de embedding e parametros do indice |
