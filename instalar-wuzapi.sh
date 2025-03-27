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

# ======================================
# FUNÇÕES UTILITÁRIAS
# ======================================

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_DIR/instalacao.log"
}

setup_database() {
    # Criar diretório do banco de dados se não existir
    mkdir -p "$DB_DIR"
    
    # Verificar se o SQLite está instalado
    if ! command -v sqlite3 &>/dev/null; then
        log "Instalando SQLite..."
        pkg install -y sqlite || {
            log "❌ Falha ao instalar SQLite"
            exit 1
        }
    fi

    # Criar banco de dados e tabela se não existirem
    if [ ! -f "$DB_FILE" ]; then
        log "Criando banco de dados..."
        sqlite3 "$DB_FILE" "CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE,
            token TEXT UNIQUE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );" || {
            log "❌ Erro ao criar banco de dados"
            exit 1
        }
        
        # Inserir dados iniciais (opcional)
        sqlite3 "$DB_FILE" "INSERT OR IGNORE INTO users (name, token) VALUES 
            ('7774', '7774'),
            ('7775', '7775');"
            
        log "✅ Banco de dados configurado com sucesso"
    else
        # Atualização segura do banco existente
        log "✔ Banco de dados já existe (atualização segura)"
        
        # Adicionar novas colunas se necessário (exemplo de migração segura)
        sqlite3 "$DB_FILE" "ALTER TABLE users ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;" 2>/dev/null
    fi
    
    # Garantir permissões corretas
    chmod 660 "$DB_FILE"
    chmod 770 "$DB_DIR"
}

# ======================================
# EXECUÇÃO PRINCIPAL
# ======================================

# Configuração inicial
mkdir -p "$LOG_DIR"
clear
echo "#############################################"
echo "  INSTALADOR DO $APP_NAME PARA TERMUX"
echo "  Este processo pode levar até 15 minutos"
echo "#############################################"
log "Iniciando instalação..."

# 1. Instalar dependências básicas
log "Instalando dependências principais..."
pkg update -y && pkg install -y git golang ffmpeg sqlite || {
    log "❌ Falha na instalação das dependências"
    exit 1
}

# 2. Configurar banco de dados
setup_database

# 3. Limpar instalações anteriores
if [ -d "$HOME/wuzapi" ]; then
    log "Removendo instalação anterior..."
    rm -rf "$HOME/wuzapi"
fi

# 4. Clonar repositório
log "Clonando repositório oficial..."
git clone "$REPO_URL" "$HOME/wuzapi" || {
    log "❌ Falha ao clonar repositório"
    exit 1
}

# 5. Compilar
log "Compilando $BINARY_NAME..."
cd "$HOME/wuzapi" && go build -o $BINARY_NAME . || {
    log "❌ Falha na compilação"
    exit 1
}

# 6. Permissões
chmod +x "$BINARY_NAME"
[ -f "executar_wuzapi.sh" ] && chmod +x "executar_wuzapi.sh"

# 7. Configurar Termux
log "Configurando permissões do Termux..."
mkdir -p "$HOME/.termux"
echo "allow-external-apps=true" > "$HOME/.termux/termux.properties"
termux-reload-settings

# Finalização
echo "✔️ Instalação concluída com sucesso!"
echo "──────────────────────────────────────"
echo "  Para iniciar o $APP_NAME:"
echo "  cd ~/wuzapi && ./$BINARY_NAME"
echo "──────────────────────────────────────"
log "Instalação concluída com sucesso!"

# Opção de iniciar automaticamente
read -p "Deseja iniciar o $APP_NAME agora? [s/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    cd ~/wuzapi && ./$BINARY_NAME
fi
