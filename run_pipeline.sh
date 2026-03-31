#!/bin/bash
set -e

# CONFIGURAÇÃO
MODEL_NAME="Qwen/Qwen3-32B-AWQ"
RUN_NAME="default"

MODEL_SHORT="${MODEL_NAME##*/}"

# LIMPAR RESULTADOS ANTERIORES (descomente para usar)
rm -rf "data/queries/${MODEL_SHORT}/${RUN_NAME}"
rm -rf "data/results/${MODEL_SHORT}/${RUN_NAME}"

echo "Modelo: $MODEL_NAME | Run: $RUN_NAME"

echo "1/7 Ground Truth..."
text2sql ground-truth run --run "$RUN_NAME"

echo "2/7 Execute Ground Truth..."
text2sql execute run --queries "data/queries/ground_truth/${RUN_NAME}" --results "data/results/ground_truth/${RUN_NAME}"

echo "3/7 RAG..."
text2sql rag run

echo "4/7 Generate..."
text2sql generate run --model "$MODEL_NAME" --run "$RUN_NAME"

echo "5/7 Execute Model..."
text2sql execute run --queries "data/queries/${MODEL_SHORT}/${RUN_NAME}" --results "data/results/${MODEL_SHORT}/${RUN_NAME}"

echo "6/7 Compare..."
text2sql compare run --gt "$RUN_NAME" --model "${MODEL_SHORT}/${RUN_NAME}"

echo "7/7 Export..."
text2sql compare export "${MODEL_SHORT}/${RUN_NAME}"

echo "Concluído!"
