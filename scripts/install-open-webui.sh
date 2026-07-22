#!/bin/bash
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
log()  { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[x]${NC} $1"; }

if [ "$(id -u)" -ne 0 ]; then
  SUDO="sudo"
else
  SUDO=""
fi

echo -e "${CYAN}"
echo "======================================"
echo "  estagiario_ia — Open WebUI"
echo "  Tela visual tipo ChatGPT"
echo "======================================"
echo -e "${NC}"

# ------------------------------------------------------------------
# 1. Instalar Docker se não existir
# ------------------------------------------------------------------
if command -v docker &>/dev/null; then
  log "Docker já instalado."
else
  log "Instalando Docker..."
  curl -fsSL https://get.docker.com | $SUDO bash
  log "Docker instalado com sucesso."
fi

# ------------------------------------------------------------------
# 2. Garantir que o daemon está rodando
# ------------------------------------------------------------------
if ! docker info &>/dev/null; then
  log "Iniciando Docker daemon..."
  $SUDO systemctl enable docker 2>/dev/null || true
  $SUDO systemctl start docker 2>/dev/null || true
  sleep 2
fi

# ------------------------------------------------------------------
# 3. Subir Open WebUI
# ------------------------------------------------------------------
log "Baixando e iniciando Open WebUI..."
$SUDO docker rm -f open-webui 2>/dev/null || true

$SUDO docker run -d -p 8080:8080 \
  --network=host \
  -v open-webui:/app/backend/data \
  --name open-webui \
  --restart unless-stopped \
  ghcr.io/open-webui/open-webui:main

# ------------------------------------------------------------------
# 4. Firewall
# ------------------------------------------------------------------
if command -v ufw &>/dev/null; then
  log "Liberando porta 8080 no UFW..."
  $SUDO ufw allow 8080/tcp 2>/dev/null || true
elif command -v firewall-cmd &>/dev/null; then
  log "Liberando porta 8080 no firewalld..."
  $SUDO firewall-cmd --add-port=8080/tcp --permanent 2>/dev/null || true
  $SUDO firewall-cmd --reload 2>/dev/null || true
fi

# ------------------------------------------------------------------
# Resumo
# ------------------------------------------------------------------
IP=$(curl -s ifconfig.me || hostname -I | awk '{print $1}')
echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}  Open WebUI instalado!${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo -e "  Acessar: ${CYAN}http://$IP:8080${NC}"
echo ""
echo -e "  ${YELLOW}Ele já conecta no Ollama local automaticamente.${NC}"
echo -e "  ${YELLOW}Pare com: docker stop open-webui${NC}"
echo ""
