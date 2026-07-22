#!/bin/bash
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
log()  { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[x]${NC} $1"; }
info() { echo -e "${CYAN}[i]${NC} $1"; }

echo -e "${CYAN}"
echo "======================================"
echo "  estagiario_ia — Instalação VPS"
echo "  Ollama + LFM2.5 + nomic-embed-text"
echo "======================================"
echo -e "${NC}"

if [ "$(id -u)" -ne 0 ]; then
  warn "Alguns passos precisam de root. Tentando com sudo..."
  SUDO="sudo"
else
  SUDO=""
fi

# ------------------------------------------------------------------
# 1. Detectar gerenciador de pacotes
# ------------------------------------------------------------------
if command -v apt-get &>/dev/null; then PKG="apt-get"; INSTALL_CMD="$SUDO apt-get install -y"
elif command -v dnf &>/dev/null; then PKG="dnf"; INSTALL_CMD="$SUDO dnf install -y"
elif command -v yum &>/dev/null; then PKG="yum"; INSTALL_CMD="$SUDO yum install -y"
elif command -v zypper &>/dev/null; then PKG="zypper"; INSTALL_CMD="$SUDO zypper install -y"
elif command -v apk &>/dev/null; then PKG="apk"; INSTALL_CMD="$SUDO apk add"
else err "Gerenciador de pacotes não encontrado."; exit 1; fi

log "Gerenciador detectado: $PKG"

# ------------------------------------------------------------------
# 2. Instalar dependências do sistema
# ------------------------------------------------------------------
log "Instalando zstd + curl + python3..."
case $PKG in
  apt-get) $SUDO apt-get update -qq && $INSTALL_CMD zstd curl python3 python3-pip ;;
  *) $INSTALL_CMD zstd curl python3 python3-pip 2>/dev/null || $INSTALL_CMD zstd curl python3 ;;
esac

# ------------------------------------------------------------------
# 3. Instalar Ollama
# ------------------------------------------------------------------
if command -v ollama &>/dev/null; then
  warn "Ollama já instalado ($(ollama --version)). Pulando."
else
  log "Instalando Ollama..."
  curl -fsSL https://ollama.com/install.sh | sh
fi

# ------------------------------------------------------------------
# 4. Garantir que Ollama está rodando
# -----------------------------------------------------------------
log "Iniciando serviço Ollama..."
$SUDO systemctl enable ollama 2>/dev/null || true
$SUDO systemctl start ollama 2>/dev/null || true

if ! pgrep -x ollama > /dev/null; then
  warn "Service não iniciou. Iniciando manualmente..."
  ollama serve &
  sleep 3
fi

info "Aguardando Ollama ficar pronto..."
for i in $(seq 1 30); do
  if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    log "Ollama pronto!"
    break
  fi
  if [ "$i" -eq 30 ]; then
    err "Ollama não respondeu após 30s. Verifique logs."
    exit 1
  fi
  sleep 1
done

# ------------------------------------------------------------------
# 5. Fazer pull dos modelos
# ------------------------------------------------------------------
log "Puxando LFM2.5-1.2B (~730 MB)..."
ollama pull hf.co/LiquidAI/LFM2.5-1.2B-Instruct-GGUF

log "Puxando nomic-embed-text (~274 MB)..."
ollama pull nomic-embed-text

# ------------------------------------------------------------------
# 6. Criar modelo customizado extrator-leads
# ------------------------------------------------------------------
log "Criando Modelfile..."
cat > /tmp/Modelfile << 'EOF'
FROM hf.co/LiquidAI/LFM2.5-1.2B-Instruct-GGUF
PARAMETER temperature 0.1
SYSTEM """Você extrai leads de agência de automação. Devolva SOMENTE JSON:
{"nome":"","empresa":"","intencao":"orcamento|suporte|cancelamento","urgencia":"alta|media|baixa","assunto":""}
Campo ausente = "". Nunca invente. Nada fora do JSON."""
MESSAGE user Oi, aqui é a Ana da Clínica Sorriso, meu agente tá fora do ar!
MESSAGE assistant {"nome":"Ana","empresa":"Clínica Sorriso","intencao":"suporte","urgencia":"alta","assunto":"agente fora do ar!"}
EOF

log "Criando modelo extrator-leads..."
ollama create extrator-leads -f /tmp/Modelfile
rm /tmp/Modelfile

# ------------------------------------------------------------------
# 7. Instalar libs Python para RAG
# ------------------------------------------------------------------
log "Instalando numpy + requests para RAG..."
pip3 install --quiet --break-system-packages 2>/dev/null \
  numpy requests \
  || pip3 install --quiet numpy requests

# ------------------------------------------------------------------
# 8. Firewall
# ------------------------------------------------------------------
if command -v ufw &>/dev/null; then
  log "Liberando porta 11434 no UFW..."
  $SUDO ufw allow 11434/tcp 2>/dev/null || true
elif command -v firewall-cmd &>/dev/null; then
  log "Liberando porta 11434 no firewalld..."
  $SUDO firewall-cmd --add-port=11434/tcp --permanent 2>/dev/null || true
  $SUDO firewall-cmd --reload 2>/dev/null || true
fi

# ------------------------------------------------------------------
# 9. Bind para 0.0.0.0 (acesso externo)
# ------------------------------------------------------------------
OLLAMA_CONF="/etc/systemd/system/ollama.service.d"
if [ -d /etc/systemd/system/ollama.service.d ] || mkdir -p $OLLAMA_CONF 2>/dev/null; then
  cat > /tmp/override.conf << 'EOF'
[Service]
Environment=OLLAMA_HOST=0.0.0.0
EOF
  $SUDO mkdir -p $OLLAMA_CONF
  $SUDO cp /tmp/override.conf $OLLAMA_CONF/override.conf
  rm /tmp/override.conf
  $SUDO systemctl daemon-reload
  $SUDO systemctl restart ollama
  log "Ollama configurado para escutar em 0.0.0.0:11434"
fi

# ------------------------------------------------------------------
# Resumo final
# ------------------------------------------------------------------
echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}  Instalação concluída!${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo -e "  ${CYAN}Modelos instalados:${NC}"
ollama list 2>/dev/null | awk '{print "    " $0}'
echo ""
echo -e "  ${CYAN}Testar chat interativo:${NC}"
echo "    ollama run extrator-leads"
echo ""
echo -e "  ${CYAN}Testar via API:${NC}"
echo "    curl http://localhost:11434/api/chat -d '{\"model\":\"extrator-leads\",\"messages\":[{\"role\":\"user\",\"content\":\"Sou o Pedro da Auto Peças\"}],\"stream\":false}'"
echo ""
echo -e "  ${CYAN}RAG (busca semântica):${NC}"
echo "    ollama run nomic-embed-text"
echo ""
echo -e "  ${YELLOW}Acesso externo:${NC}"
echo "    A API está em http://SEU_IP:11434"
echo "    Proteja com firewall se necessário: ufw deny 11434"
echo ""
echo -e "  ${YELLOW}Quer uma tela visual tipo ChatGPT?${NC}"
echo "    curl -fsSL https://raw.githubusercontent.com/felipefernandesdev/estagiario_ia/main/scripts/install-open-webui.sh | bash"
echo "    Acessar: http://SEU_IP:8080"
echo ""
echo -e "  ${YELLOW}Quer um orquestrador low-code (n8n)?${NC}"
echo "    curl -fsSL https://raw.githubusercontent.com/felipefernandesdev/estagiario_ia/main/scripts/install-n8n.sh | bash"
echo "    Acessar: http://SEU_IP:5678"
echo ""
