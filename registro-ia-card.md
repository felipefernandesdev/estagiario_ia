# Registro de Uso de IA

## Nível

| Nível | Nome | Marcar |
|-------|------|--------|
| 0 | Humano — sem auxílio de IA | [ ] |
| 1 | Assistido — autocomplete, snippets | [ ] |
| 2 | Co-criado — IA gerou parte, humano revisou | [ ] |
| 3 | Gerado — IA gerou integral, humano só revisou | [x] |

## Detalhes

- **Agente:** opencode (deepseek-v4-flash-free)
- **Tarefa:** Preparar projeto estagiario_ia para rodar com Podman — Dockerfile com entrypoint, compose.yaml, scripts, Modelfile, README completo baseado em tutorial de IA local
- **Prompt usado:** "lê tudo isso e deixa o projeto pronto pra subir com o podman: [tutorial extenso sobre Ollama + LFM2 + n8n + RAG]"
- **Arquivos criados/modificados:**
  - `Dockerfile` — atualizado com entrypoint script, python3, pip
  - `compose.yaml` — healthcheck, env vars, volumes para Modelfile e models-to-pull
  - `README.md` — documentação completa do zero (modelos, API, RAG, desempenho, arquitetura Lego)
  - `Modelfile` — modelo customizado extrator-leads (system + few-shot)
  - `scripts/entrypoint.sh` — inicia Ollama + pull automático de modelos
  - `scripts/pull-models.sh` — menu interativo de pull
  - `models-to-pull.txt` — lista de modelos para baixar no start

## Revisão Humana

- **Revisor:** [pendente]
- **Data:** [pendente]
- **Alterações pós-revisão:** [pendente]

## Observações

Projeto configurado para pull automático de modelos LFM2.5-1.2B + nomic-embed-text no primeiro start. Modelfile de exemplo incluso. Entrypoint gerencia ciclo de vida do Ollama com healthcheck.

---

## Auto-gerado pelo agente

- **Comandos usados:** `read`, `write`, `mkdir`
- **Arquivos criados:**
  - `scripts/entrypoint.sh`
  - `scripts/pull-models.sh`
  - `Modelfile`
  - `models-to-pull.txt`
- **Arquivos modificados:**
  - `Dockerfile`
  - `compose.yaml`
  - `README.md`
  - `registro-ia-card.md`
- **Testes gerados:** 0
- **Decisões técnicas:** Sim — entrypoint script gerencia startup + pull automático
- **Data da sessão:** 2026-07-21
- **Sessão iniciada em:** container não encontrado após `podman-compose up -d`; necessário rebuild
