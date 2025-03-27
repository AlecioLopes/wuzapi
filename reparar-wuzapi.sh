#!/data/data/com.termux/files/usr/bin/bash

# ======================================
# CONFIGURAÇÕES
# ======================================
DB_FILE="$HOME/wuzapi/dbdata/users.db"
LOG_FILE="$HOME/wuzapi_logs/reparo.log"
SCRIPT_NAME="reparar-wuzapi.sh"

# ======================================
# FUNÇÕES
# ======================================

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

dar_permissao_script() {
    log "Concedendo permissão de execução ao script..."
    chmod +x "$HOME/$SCRIPT_NAME"
}

reparar_db() {
    # Criar diretório de logs se não existir
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
    
    log "Iniciando processo de reparo completo..."
    
    # 1. Verificar e instalar SQLite se necessário
    if ! command -v sqlite3 &>/dev/null; then
        log "Instalando SQLite..."
        pkg install -y sqlite >> "$LOG_FILE" 2>&1
    fi
    
    # 2. Parar WuzAPI se estiver rodando
    if pgrep -f "wuzapi" >/dev/null; then
        log "Parando WuzAPI..."
        pkill -f "wuzapi"
        sleep 2
    fi
    
    # 3. Criar estrutura do banco se não existir
    mkdir -p "$(dirname "$DB_FILE")"
    
    log "Verificando/Criando banco de dados..."
    sqlite3 "$DB_FILE" "CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE,
        token TEXT UNIQUE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );" >> "$LOG_FILE" 2>&1
    
    # 4. Inserir usuários padrão (se não existirem)
    log "Verificando usuários 7774 e 7775..."
    sqlite3 "$DB_FILE" "INSERT OR IGNORE INTO users (name, token) VALUES 
        ('7774', '7774'),
        ('7775', '7775');" >> "$LOG_FILE" 2>&1
    
    # 5. Ajustar permissões
    log "Ajustando permissões..."
    chmod 660 "$DB_FILE" >> "$LOG_FILE" 2>&1
    chmod 770 "$(dirname "$DB_FILE")" >> "$LOG_FILE" 2>&1
    
    # 6. Reiniciar WuzAPI
    if [ -f "$HOME/wuzapi/wuzapi" ]; then
        log "Reiniciando WuzAPI..."
        cd "$HOME/wuzapi" && ./wuzapi >> "$LOG_FILE" 2>&1 &
    fi
    
    log "Processo de reparo concluído!"
}

# ======================================
# EXECUÇÃO PRINCIPAL
# ======================================

clear
echo "=========================================="
echo "  REPARADOR AUTOMÁTICO WUZAPI - BOTZAP"
echo "  Este script vai:"
echo "  1. Verificar/criar banco de dados"
echo "  2. Adicionar usuários padrão"
echo "  3. Ajustar permissões automaticamente"
echo "=========================================="

# Dar permissão a si mesmo e executar
dar_permissao_script
reparar_db

# Mostrar resumo
echo -e "\n✔ Reparo concluído com sucesso!"
echo -e "\n📋 Log completo em: $LOG_FILE"
echo -e "\n🔍 Últimas entradas do log:"
tail -n 5 "$LOG_FILE"

# Verificar usuários
echo -e "\n👥 Usuários no banco de dados:"
sqlite3 "$DB_FILE" "SELECT name, token FROM users;" 2>/dev/null || echo "Banco de dados não encontrado"
