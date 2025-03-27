#!/bin/bash

# Função para verificar e instalar o SQLite
install_sqlite() {
    echo "Verificando a instalação do SQLite..."
    if ! command -v sqlite3 &>/dev/null; then
        echo "SQLite não encontrado. Instalando..."
        pkg install -y sqlite &>/dev/null
        if [ $? -eq 0 ]; then
            echo "SQLite instalado com sucesso."
        else
            echo "Erro ao instalar o SQLite." >&2
            exit 1
        fi
    else
        echo "SQLite já está instalado."
    fi
}

# Função para verificar e criar o banco de dados se não existir
setup_database() {
    local db_file="dbdata/users.db"
    
    # Criar diretório se não existir
    mkdir -p dbdata &>/dev/null
    
    # Verificar se o banco de dados existe, se não, criar
    if [ ! -f "$db_file" ]; then
        echo "Criando banco de dados..."
        sqlite3 "$db_file" "CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, token TEXT);"
    fi
}

# Função para inserir dados de forma segura
insert_data() {
    local db_file="dbdata/users.db"
    
    # Verificar se os dados já existem para evitar duplicação
    if ! sqlite3 "$db_file" "SELECT 1 FROM users WHERE name='7774' AND token='7774';" | grep -q "1"; then
        echo "Inserindo usuário 7774..."
        sqlite3 "$db_file" "INSERT INTO users (name, token) VALUES ('7774', '7774');"
    else
        echo "Usuário 7774 já existe no banco de dados."
    fi
    
    if ! sqlite3 "$db_file" "SELECT 1 FROM users WHERE name='7775' AND token='7775';" | grep -q "1"; then
        echo "Inserindo usuário 7775..."
        sqlite3 "$db_file" "INSERT INTO users (name, token) VALUES ('7775', '7775');"
    else
        echo "Usuário 7775 já existe no banco de dados."
    fi
}

# Função principal
main() {
    # Instalar SQLite se necessário
    install_sqlite
    
    # Configurar banco de dados
    setup_database
    
    # Inserir dados
    insert_data
    
    # Iniciar o wuzapi
    echo "Iniciando o wuzapi..."
    cd ~/wuzapi || { echo "Diretório wuzapi não encontrado!" >&2; exit 1; }
    ./wuzapi
}

# Executar função principal
main
