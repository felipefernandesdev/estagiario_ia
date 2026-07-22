#!/bin/bash
set -e

echo "=== Pull de Modelos Ollama ==="
echo ""

echo "Modelos recomendados:"
echo "  1) LFM2.5-1.2B (extração, classificação) ~730MB"
echo "  2) nomic-embed-text (embedding p/ RAG) ~274MB"
echo "  3) llama3.2 (3B - conversação geral) ~2GB"
echo "  4) llama3.2 (1B - leve, conversação) ~666MB"
echo "  5) Todos acima"
echo "  6) Modelo personalizado"
echo ""

read -p "Escolha (1-6): " choice

case $choice in
  1) models="hf.co/LiquidAI/LFM2.5-1.2B-Instruct-GGUF" ;;
  2) models="nomic-embed-text" ;;
  3) models="llama3.2:3b" ;;
  4) models="llama3.2:1b" ;;
  5) models="hf.co/LiquidAI/LFM2.5-1.2B-Instruct-GGUF,nomic-embed-text" ;;
  6)
    read -p "Nome do modelo no Ollama: " custom
    models="$custom"
    ;;
  *) echo "Opção inválida"; exit 1 ;;
esac

IFS=',' read -ra MODEL_LIST <<< "$models"
for model in "${MODEL_LIST[@]}"; do
  echo "Puxando $model..."
  ollama pull "$(echo "$model" | xargs)"
done

echo ""
echo "Pronto! Modelos instalados:"
ollama list
