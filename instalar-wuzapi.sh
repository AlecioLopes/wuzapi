#!/bin/bash

# Função para verificar se o comando foi executado com sucesso
verificar_erro() {
    if [ $? -ne 0 ]; then
        echo "ERRO: $1"
        exit 1
    fi
}

echo "##### ESTE PROCESSO PODE DEMORAR ENTRE 15 A 20 MINUTOS #####"

# Atualizar repositórios do Termux
echo "Atualizando repositórios do Termux..."
pkg update -y
verificar_erro "Falha ao atualizar os repositórios do Termux."

# Verificar e instalar Git
if ! command -v git &> /dev/null; then
    echo "Instalando Git..."
    pkg install -y git
    verificar_erro "Falha ao instalar o Git."
else
    echo "Git já está instalado."
fi

# Verificar e instalar Go
if ! command -v go &> /dev/null; then
    echo "Instalando Go..."
    pkg install -y golang
    verificar_erro "Falha ao instalar o Go."
else
    echo "Go já está instalado."
fi

# Verificar e instalar SQLite
if ! command -v sqlite3 &> /dev/null; then
    echo "Instalando SQLite..."
    pkg install -y sqlite
    verificar_erro "Falha ao instalar o SQLite."
else
    echo "SQLite já está instalado."
fi

# Verificar se o diretório wuzapi já existe
if [ -d "wuzapi" ]; then
    echo "O diretório wuzapi já existe. Removendo para uma instalação limpa..."
    rm -rf wuzapi
fi

# Clonar o repositório do BotZap
echo "Clonando o repositório do BotZap..."
git clone https://github.com/AlecioLopes/wuzapi.git
verificar_erro "Falha ao clonar o repositório."
echo "Repositório clonado com sucesso."

# Navegar para o diretório do projeto
cd wuzapi || exit 1

# Verificar se o diretório dbdata existe, se não, criar
if [ ! -d "dbdata" ]; then
    echo "Criando diretório dbdata..."
    mkdir -p dbdata
    verificar_erro "Falha ao criar o diretório dbdata."
fi

# Verificar se o banco de dados existe
if [ ! -f "dbdata/users.db" ]; then
    echo "Criando banco de dados..."
    # Criar a tabela users caso não exista
    sqlite3 dbdata/users.db "CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, token TEXT);"
    verificar_erro "Falha ao criar o banco de dados."
fi

# Compilar o binário do BotZap
echo "Compilando o binário..."
go build .
verificar_erro "Falha ao compilar o binário."

# Verificar se o binário foi compilado corretamente
if [ -f "./wuzapi" ]; then
    echo "BotZap foi compilado corretamente no Termux."
    
    # Conceder permissões de execução ao binário
    chmod +x wuzapi
    verificar_erro "Falha ao conceder permissões ao binário wuzapi."
    
    # Verificar se o arquivo executar_wuzapi.sh existe
    if [ -f "executar_wuzapi.sh" ]; then
        chmod +x executar_wuzapi.sh
        verificar_erro "Falha ao conceder permissões ao script executar_wuzapi.sh."
        echo "Permissões de execução concedidas aos arquivos."
    else
        echo "Arquivo executar_wuzapi.sh não encontrado. Criando..."
        echo '#!/bin/bash' > executar_wuzapi.sh
        echo 'cd "$(dirname "$0")"' >> executar_wuzapi.sh
        echo './wuzapi' >> executar_wuzapi.sh
        chmod +x executar_wuzapi.sh
        verificar_erro "Falha ao criar o script executar_wuzapi.sh."
    fi
else
    echo "Erro ao compilar o Botzão."
    exit 1
fi

# Inserir dados no banco de dados SQLite (verificando se já existem)
echo "Configurando o banco de dados..."
# Verificar se o token 7774 já existe
TOKEN_7774=$(sqlite3 dbdata/users.db "SELECT COUNT(*) FROM users WHERE token='7774';")
if [ "$TOKEN_7774" -eq 0 ]; then
    sqlite3 dbdata/users.db "INSERT INTO users (name, token) VALUES ('7774', '7774');"
    verificar_erro "Falha ao inserir token 7774 no banco de dados."
    echo "Token 7774 inserido com sucesso."
else
    echo "Token 7774 já existe no banco de dados."
fi

# Verificar se o token 7775 já existe
TOKEN_7775=$(sqlite3 dbdata/users.db "SELECT COUNT(*) FROM users WHERE token='7775';")
if [ "$TOKEN_7775" -eq 0 ]; then
    sqlite3 dbdata/users.db "INSERT INTO users (name, token) VALUES ('7775', '7775');"
    verificar_erro "Falha ao inserir token 7775 no banco de dados."
    echo "Token 7775 inserido com sucesso."
else
    echo "Token 7775 já existe no banco de dados."
fi

echo "Banco de dados configurado com sucesso."

# Conceder permissões ao Tasker
echo "Configurando permissões para o Tasker..."
mkdir -p ~/.termux
if ! grep -q "allow-external-apps=true" ~/.termux/termux.properties; then
    echo "allow-external-apps=true" >> ~/.termux/termux.properties
    echo "Permissões do Tasker configuradas. Você precisará reiniciar o Termux para que as mudanças tenham efeito."
else
    echo "Permissões do Tasker já estão configuradas."
fi

# Verificar se há algum arquivo de configuração necessário
echo "Verificando arquivos de configuração..."
if [ ! -f "config.json" ] && [ -f "config.example.json" ]; then
    echo "Arquivo config.json não encontrado. Copiando do exemplo..."
    cp config.example.json config.json
    echo "Lembre-se de editar o arquivo config.json com suas configurações pessoais."
fi

echo "Instalação concluída com sucesso!"
echo "Para executar o Botzão, use: ./wuzapi"

# Perguntar se deseja executar o BotZap agora
read -p "Deseja executar o Botzão agora? (s/n): " resposta
if [ "$resposta" = "s" ] || [ "$resposta" = "S" ]; then
    echo "Executando o Botzão..."
    ./wuzapi
else
    echo "Para executar o Botzão mais tarde, use o comando: ./wuzapi"
fi