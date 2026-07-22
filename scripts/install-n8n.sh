#!/bin/bash
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
log()  { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[x]${NC} $1"; }

if [ "$(id -u)" -ne 0 ]; then SUDO="sudo"; else SUDO=""; fi

echo -e "${CYAN}"
echo "======================================"
echo "  estagiario_ia — n8n"
echo "  Orquestrador low-code"
echo "======================================"
echo -e "${NC}"

# ------------------------------------------------------------------
# 1. Docker
# ------------------------------------------------------------------
if ! command -v docker &>/dev/null; then
  log "Instalando Docker..."
  curl -fsSL https://get.docker.com | $SUDO bash
fi

# ------------------------------------------------------------------
# 2. Subir n8n
# ------------------------------------------------------------------
log "Iniciando n8n..."
$SUDO docker rm -f n8n 2>/dev/null || true
$SUDO docker run -d --name n8n \
  -p 5678:5678 \
  -v n8n_data:/home/node/.n8n \
  --restart unless-stopped \
  n8nio/n8n

# ------------------------------------------------------------------
# 3. Firewall
# ------------------------------------------------------------------
if command -v ufw &>/dev/null; then
  log "Liberando porta 5678 no UFW..."
  $SUDO ufw allow 5678/tcp 2>/dev/null || true
fi

# ------------------------------------------------------------------
# Resumo
# ------------------------------------------------------------------
IP=$(curl -s ifconfig.me || hostname -I | awk '{print $1}')
echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}  n8n instalado!${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo -e "  Acessar: ${CYAN}http://$IP:5678${NC}"
echo ""
echo -e "  ${YELLOW}No n8n, use HTTP Request node:${NC}"
echo "    URL: http://localhost:11434/api/chat"
echo "    Method: POST"
echo "    Body: { \"model\":\"extrator-leads\", \"messages\":[{\"role\":\"user\",\"content\":\"{{mensagem}}\"}], \"stream\":false }"
echo ""
