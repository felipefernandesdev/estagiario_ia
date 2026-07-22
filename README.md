# estagiario_ia — IA Local com Ollama + Podman

Container com [Ollama](https://ollama.com) para rodar modelos de IA localmente, preparado para extração de leads, classificação, RAG e automação com ferramentas (function calling).

Setup baseado em testes reais com o modelo **LFM2.5-1.2B** — ~730 MB, ~51 tok/s em CPU, 0.4s por extração.

---

## Stack

| Peça | O que faz |
|------|-----------|
| **Ollama** | Motor/runtime que roda o modelo e expõe API REST na porta 11434 |
| **Modelo principal** | LFM2.5-1.2B-Instruct (GGUF Q4) — extração, classificação, tool calling |
| **Embedder (RAG)** | `nomic-embed-text` — busca semântica na base privada |
| **Seu modelo** | `extrator-leads` — criado via Modelfile com system + few-shot |

---

## Comandos Rápidos

```bash
# Build + start
podman-compose up -d

# Logs
podman-compose logs -f

# Acessar terminal do container
podman exec -it estagiario-ollama bash

# Parar
podman-compose down

# Rebuild (se mudar Dockerfile)
podman-compose up -d --build
```

---

## Pull de Modelos

### Opção 1 — Automático no start (recomendado)

Crie o arquivo `models-to-pull.txt` na raiz do projeto:

```bash
echo "hf.co/LiquidAI/LFM2.5-1.2B-Instruct-GGUF" > models-to-pull.txt
echo "nomic-embed-text" >> models-to-pull.txt
```

Ou use env var:

```bash
PULL_MODELS="hf.co/LiquidAI/LFM2.5-1.2B-Instruct-GGUF,nomic-embed-text" podman-compose up -d
```

### Opção 2 — Manual (dentro do container)

```bash
podman exec -it estagiario-ollama bash
# Pull interativo com menu
bash scripts/pull-models.sh
```

### Opção 3 — Manual via API

```bash
curl -X POST http://localhost:11434/api/pull \
  -d '{"model":"hf.co/LiquidAI/LFM2.5-1.2B-Instruct-GGUF"}'
```

---

## Como Usar

### 1. Chat interativo

```bash
podman exec -it estagiario-ollama ollama run hf.co/LiquidAI/LFM2.5-1.2B-Instruct-GGUF
# /bye para sair
```

### 2. Via API (one-shot)

```bash
curl http://localhost:11434/api/chat -d '{
  "model":"hf.co/LiquidAI/LFM2.5-1.2B-Instruct-GGUF",
  "messages":[{"role":"user","content":"Extraia o lead: Oi, aqui é o Carlos da PetShop"}],
  "stream":false
}' | jq .
```

### 3. Criar modelo customizado (extrator-leads)

O `Modelfile` já vem configurado com system message + few-shot para extração de leads.

```bash
podman exec estagiario-ollama ollama create extrator-leads -f /Modelfile
```

Depois use direto pelo nome:

```bash
curl http://localhost:11434/api/chat -d '{
  "model":"extrator-leads",
  "messages":[{"role":"user","content":"Sou o Pedro da Auto Peças Silva, quero preço"}],
  "stream":false
}' | jq .
```

### 4. RAG — busca semântica na sua base

```python
import requests, numpy as np

def embed(t):
    r = requests.post("http://localhost:11434/api/embeddings",
        json={"model":"nomic-embed-text","prompt":t})
    return r.json()["embedding"]

base = [(doc, embed(doc)) for doc in meus_documentos]

def responder(pergunta):
    q = embed(pergunta)
    top = sorted(base, key=lambda c: -np.dot(q, c[1]))[:3]
    contexto = "\n".join(d for d,_ in top)
    r = requests.post("http://localhost:11434/api/chat", json={
        "model":"extrator-leads",
        "messages":[{"role":"system","content":f"Responda SÓ com base em:\n{contexto}"},
                    {"role":"user","content":pergunta}],
        "stream":False})
    return r.json()
```

---

## API Reference (Ollama)

| Endpoint | Exemplo |
|----------|---------|
| `POST /api/chat` | Chat completo com mensagens |
| `POST /api/generate` | Geração one-shot |
| `POST /api/embeddings` | Gerar embedding (para RAG) |
| `POST /api/pull` | Baixar modelo |
| `GET /api/tags` | Listar modelos instalados |
| `POST /api/create` | Criar modelo via Modelfile |

---

## Arquitetura (O Lego)

```
   [ CANAL ]            [ ORQUESTRADOR ]         [ MOTOR ]         [ CÉREBRO ]
 WhatsApp / CRM   →    n8n / código         →  Ollama (API)   →   LFM2 / extrator-leads
 formulário/site       (recebe, chama, decide)   porta :11434       730 MB
       ↑                        │
       └────── resposta ────────┤
                                ↓
                        [ MEMÓRIA / RAG ]
                     nomic-embed-text + sua base
                       (tudo no SEU servidor)
```

---

## Desempenho (testado em VPS 4 vCPU, 8 GB RAM, CPU-only)

| Métrica | Valor |
|---------|-------|
| Velocidade de geração | 44-65 tok/s (média ~51 tok/s) |
| Latência extração lead | 0.36-1.4 s |
| RAM ocupada | ~860 MB |
| Modelo em disco | 730 MB |

---

## Referência

- [Ollama](https://ollama.com)
- [LFM2.5-1.2B no HuggingFace](https://huggingface.co/LiquidAI/LFM2.5-1.2B-Instruct-GGUF)
- [nomic-embed-text](https://ollama.com/library/nomic-embed-text)
