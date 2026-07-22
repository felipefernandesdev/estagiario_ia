#!/bin/bash
set -e

OLLAMA_HOST=${OLLAMA_HOST:-0.0.0.0}
OLLAMA_PORT=${OLLAMA_PORT:-11434}
MODELS=${PULL_MODELS:-""}

ollama serve &
SERVE_PID=$!

until curl -s http://$OLLAMA_HOST:$OLLAMA_PORT/api/tags > /dev/null 2>&1; do
  sleep 1
done

if [ -n "$MODELS" ]; then
  IFS=',' read -ra MODEL_LIST <<< "$MODELS"
  for model in "${MODEL_LIST[@]}"; do
    model_trimmed=$(echo "$model" | xargs)
    if ! ollama list | grep -q "$model_trimmed"; then
      echo "Puxando modelo: $model_trimmed"
      ollama pull "$model_trimmed"
    else
      echo "Modelo já existe: $model_trimmed"
    fi
  done
fi

if [ -f /models-to-pull.txt ] && [ -s /models-to-pull.txt ]; then
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    line_trimmed=$(echo "$line" | xargs)
    if ! ollama list | grep -q "$line_trimmed"; then
      echo "Puxando modelo (from file): $line_trimmed"
      ollama pull "$line_trimmed"
    fi
  done < /models-to-pull.txt
fi

wait $SERVE_PID
