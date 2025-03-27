#!/data/data/com.termux/files/usr/bin/bash

# ======================================
# CONFIGURAÇÕES PRINCIPAIS
# ======================================
REPO_URL="https://github.com/AlecioLopes/wuzapi.git"
APP_NAME="BotZAP"
LOG_DIR="$HOME/wuzapi_logs"
BINARY_NAME="wuzapi"
DB_DIR="$HOME/wuzapi/dbdata"
DB_FILE="$DB_DIR/users.db"
SERVICE_DIR="$HOME/.termux/boot"
SERVICE_FILE="$SERVICE_DIR/start-botzap"
UPDATE_LOCK="$HOME/wuzapi/.update.lock"

# Cores para o terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ======================================
# FUNÇÕES UTILITÁRIAS (ATUALIZADAS)
# ======================================

log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_DIR/instalacao.log"
}

show_step() {
    echo -e "${YELLOW}▶ $1${NC}"
    log "$1"
}

show_success() {
    echo -e "${GREEN}✔ $1${NC}"
    log "$1"
}

show_error() {
    echo -e "${RED}✖ $1${NC}"
    log "$1"
    [ -f "$UPDATE_LOCK" ] && rm "$UPDATE_LOCK"
    exit 1
}

# ======================================
# FUNÇÕES PRINCIPAIS (COM ATUALIZAÇÃO)
# ======================================

setup_database() {
    show_step "Configurando banco de dados SQLite..."
    
    mkdir -p "$DB_DIR" || show_error "Falha ao criar diretório do banco de dados"

    if ! command -v sqlite3 &>/dev/null; then
        show_step "Instalando SQLite..."
        pkg install -y sqlite || show_error "Falha ao instalar SQLite"
    fi

    sqlite3 "$DB_FILE" "CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE,
        token TEXT UNIQUE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );" || show_error "Erro na criação da tabela"

    # Inserção segura com verificação
    insert_user() {
        sqlite3 "$DB_FILE" "INSERT OR IGNORE INTO users (name, token) VALUES ('$1', '$2');"
        changes=$(sqlite3 "$DB_FILE" "SELECT changes();")
        [ "$changes" -eq 1 ] && show_success "Usuário $1 inserido" || show_step "Usuário $1 já existia"
    }

    insert_user "7774" "7774"
    insert_user "7775" "7775"

    chmod 660 "$DB_FILE" && chmod 770 "$DB_DIR" || show_step "Aviso: Permissões do banco não ajustadas"
}

update_self() {
    if [ -f "$UPDATE_LOCK" ]; then
        show_error "Atualização já em progresso. Aguarde..."
    fi
    
    touch "$UPDATE_LOCK"
    show_step "Iniciando auto-atualização..."
    
    # Backup crítico
    cp "$DB_FILE" "$DB_FILE.bak" || show_error "Falha no backup"
    
    # Atualizar código
    if [ -d "$HOME/wuzapi" ]; then
        show_step "Atualizando código-fonte..."
        cd "$HOME/wuzapi"
        git reset --hard || show_error "Falha ao resetar repositório"
        git pull origin main || show_error "Falha ao atualizar código"
    else
        clone_repository
    fi
    
    # Recompilar
    compile_binary
    
    rm "$UPDATE_LOCK"
    show_success "Auto-atualização concluída!"
}

install_dependencies() {
    show_step "Atualizando pacotes e instalando dependências..."
    pkg update -y && pkg install -y git golang ffmpeg sqlite || show_error "Falha na instalação"
}

clone_repository() {
    show_step "Clonando repositório..."
    [ -d "$HOME/wuzapi" ] && rm -rf "$HOME/wuzapi"
    git clone "$REPO_URL" "$HOME/wuzapi" || show_error "Falha ao clonar"
}

compile_binary() {
    show_step "Compilando binário..."
    cd "$HOME/wuzapi" && go build -o $BINARY_NAME . || show_error "Falha na compilação"
}

setup_permissions() {
    show_step "Configurando permissões..."
    chmod +x "$HOME/wuzapi/$BINARY_NAME"
    [ -f "$HOME/wuzapi/executar_wuzapi.sh" ] && chmod +x "$HOME/wuzapi/executar_wuzapi.sh"
}

configure_termux() {
    show_step "Configurando ambiente Termux..."
    mkdir -p "$HOME/.termux"
    echo "allow-external-apps=true" > "$HOME/.termux/termux.properties"
    termux-reload-settings
}

create_service() {
    show_step "Criando serviço de auto-reinício..."
    mkdir -p "$SERVICE_DIR"
    
    cat > "$SERVICE_FILE" <<EOF
#!/data/data/com.termux/files/usr/bin/bash

# Configurações avançadas
LOG_DIR="\$HOME/wuzapi_logs"
MAX_RETRIES=999
SLEEP_TIME=10
UPDATE_URL="https://raw.githubusercontent.com/AlecioLopes/wuzapi/main/instalar-wuzapi.sh"

while true; do
    echo "\$(date '+%Y-%m-%d %H:%M:%S') - Iniciando $APP_NAME (\$((999-MAX_RETRIES)))" >> "\$LOG_DIR/service.log"
    
    # Verificar atualizações a cada 24h
    if [ \$(( (\$(date +%s) - \$(stat -c %Y "\$HOME/wuzapi/$BINARY_NAME" 2>/dev/null || echo 0) )) -gt 86400 ]; then
        curl -sL "\$UPDATE_URL" | bash -s -- --update
    fi
    
    cd "\$HOME/wuzapi" && ./$BINARY_NAME
    
    if [ \$? -eq 130 ]; then  # Ctrl+C
        echo "\$(date '+%Y-%m-%d %H:%M:%S') - Encerrado pelo usuário" >> "\$LOG_DIR/service.log"
        break
    fi
    
    [ \$MAX_RETRIES -le 0 ] && break
    sleep \$SLEEP_TIME
    ((MAX_RETRIES--))
done
EOF

    chmod +x "$SERVICE_FILE"
}

start_service() {
    show_step "Iniciando serviço..."
    nohup "$SERVICE_FILE" >/dev/null 2>&1 &
}

# ======================================
# CONTROLE PRINCIPAL
# ======================================

main() {
    clear
    echo -e "${GREEN}"
    echo "#############################################"
    echo "#  SUPER INSTALADOR $APP_NAME"
    echo "#  com Auto-Atualização"
    echo "#############################################"
    echo -e "${NC}"
    
    mkdir -p "$LOG_DIR"
    touch "$LOG_DIR/instalacao.log"

    case "$1" in
        "--update")
            update_self
            ;;
        *)
            install_dependencies
            setup_database
            clone_repository
            compile_binary
            setup_permissions
            configure_termux
            create_service
            start_service
            ;;
    esac

    show_success "Processo concluído com sucesso!"
    echo -e "${YELLOW}"
    echo "═══════════════════════════════════════════"
    echo "  COMANDOS:"
    echo "  • Iniciar: cd ~/wuzapi && ./wuzapi"
    echo "  • Parar: pkill -f wuzapi"
    echo "  • Atualizar: curl -sL $REPO_URL/raw/main/instalar-wuzapi.sh | bash -s -- --update"
    echo "  • Logs: tail -f ~/wuzapi_logs/service.log"
    echo "═══════════════════════════════════════════"
    echo -e "${NC}"
}

main "$@"
