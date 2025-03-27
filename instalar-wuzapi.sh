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

# Cores para o terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ======================================
# FUNÇÕES UTILITÁRIAS
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
    exit 1
}

setup_database() {
    show_step "Configurando banco de dados SQLite..."
    
    # Criar diretório se não existir
    mkdir -p "$DB_DIR" || show_error "Falha ao criar diretório do banco de dados"

    # Verificar/instalar SQLite
    if ! command -v sqlite3 &>/dev/null; then
        show_step "Instalando SQLite..."
        pkg install -y sqlite || show_error "Falha ao instalar SQLite"
    fi

    # Criar tabela com tratamento de erros
    sqlite3 "$DB_FILE" "CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE,
        token TEXT UNIQUE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );" || show_error "Erro na criação da tabela"

    # Função para inserção segura de usuários
    insert_user() {
        local name="$1"
        local token="$2"
        
        if sqlite3 "$DB_FILE" "INSERT OR IGNORE INTO users (name, token) VALUES ('$name', '$token');"; then
            changes=$(sqlite3 "$DB_FILE" "SELECT changes();")
            if [ "$changes" -eq 1 ]; then
                show_success "Usuário $name inserido com sucesso"
            else
                show_step "Usuário $name já existia (não duplicado)"
            fi
        else
            show_error "Falha crítica ao inserir usuário $name"
        fi
    }

    # Inserir tokens essenciais
    insert_user "7774" "7774"
    insert_user "7775" "7775"

    # Ajustar permissões
    chmod 660 "$DB_FILE" && chmod 770 "$DB_DIR" || show_step "Aviso: Permissões do banco não ajustadas (continuando)"
}

install_dependencies() {
    show_step "Atualizando pacotes e instalando dependências..."
    pkg update -y && pkg install -y git golang ffmpeg sqlite || show_error "Falha na instalação das dependências"
}

clone_repository() {
    show_step "Clonando repositório do $APP_NAME..."
    if [ -d "$HOME/wuzapi" ]; then
        show_step "Removendo instalação anterior..."
        rm -rf "$HOME/wuzapi"
    fi
    
    git clone "$REPO_URL" "$HOME/wuzapi" || show_error "Falha ao clonar repositório"
}

compile_binary() {
    show_step "Compilando $BINARY_NAME..."
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
    show_step "Criando serviço de inicialização automática..."
    mkdir -p "$SERVICE_DIR"
    
    cat > "$SERVICE_FILE" <<EOF
#!/data/data/com.termux/files/usr/bin/bash

# Configurações do serviço
LOG_DIR="\$HOME/wuzapi_logs"
MAX_RETRIES=15
SLEEP_TIME=5

while true; do
    echo "\$(date '+%Y-%m-%d %H:%M:%S') - Iniciando $APP_NAME" >> "\$LOG_DIR/service.log"
    cd "\$HOME/wuzapi" && ./$BINARY_NAME
    
    # Código 130 = Ctrl+C (encerramento solicitado)
    if [ \$? -eq 130 ]; then
        echo "\$(date '+%Y-%m-%d %H:%M:%S') - Encerrado pelo usuário" >> "\$LOG_DIR/service.log"
        break
    fi
    
    if [ \$MAX_RETRIES -le 0 ]; then
        echo "\$(date '+%Y-%m-%d %H:%M:%S') - Máximo de reinícios atingido" >> "\$LOG_DIR/service.log"
        break
    fi
    
    echo "\$(date '+%Y-%m-%d %H:%M:%S') - Reiniciando em \$SLEEP_TIME segundos..." >> "\$LOG_DIR/service.log"
    sleep \$SLEEP_TIME
    ((MAX_RETRIES--))
done
EOF

    chmod +x "$SERVICE_FILE"
}

# ======================================
# EXECUÇÃO PRINCIPAL
# ======================================

clear
echo -e "${GREEN}"
echo "#############################################"
echo "#  INSTALADOR AUTOMÁTICO DO $APP_NAME"
echo "#  para Termux"
echo "#"
echo "#  Este processo pode levar alguns minutos"
echo "#############################################"
echo -e "${NC}"

# Configurar ambiente
mkdir -p "$LOG_DIR"
touch "$LOG_DIR/instalacao.log"

# Etapas de instalação
install_dependencies
setup_database
clone_repository
compile_binary
setup_permissions
configure_termux
create_service

# Finalização
show_success "Instalação concluída com sucesso!"
echo -e "${YELLOW}"
echo "═══════════════════════════════════════════"
echo "  COMANDOS ÚTEIS:"
echo "  • Iniciar manualmente:"
echo "    cd ~/wuzapi && ./wuzapi"
echo "  "
echo "  • Parar o serviço:"
echo "    pkill -f wuzapi"
echo "  "
echo "  • Ver logs:"
echo "    tail -f ~/wuzapi_logs/service.log"
echo "═══════════════════════════════════════════"
echo -e "${NC}"

# Opção de iniciar automaticamente
read -p "Deseja iniciar o $APP_NAME agora? [s/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    cd ~/wuzapi && ./wuzapi
fi
