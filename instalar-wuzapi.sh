#!/bin/bash

# Cores para personalização
VERDE='\033[0;32m'
VERMELHO='\033[0;31m'
AMARELO='\033[0;33m'
RESET='\033[0m'

# Função para exibir títulos destacados
exibir_titulo() {
    echo -e "\n${VERDE}▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓"
    echo -e "    ${1}"
    echo -e "▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓${RESET}"
}

# Função para exibir mensagens de sucesso
mensagem_sucesso() {
    echo -e "${VERDE}✓ $1${RESET}"
}

# Função para exibir mensagens de erro
mensagem_erro() {
    echo -e "${VERMELHO}✗ ERRO: $1${RESET}"
    exit 1
}

# Função para exibir mensagens de aviso
mensagem_aviso() {
    echo -e "${AMARELO}⚠ $1${RESET}"
}

# Função para verificar se o comando foi executado com sucesso
verificar_erro() {
    if [ $? -ne 0 ]; then
        mensagem_erro "$1"
    fi
}

exibir_titulo "INICIANDO INSTALAÇÃO DO WUZAPI"
echo -e "${AMARELO}##### ESTE PROCESSO PODE DEMORAR ENTRE 15 A 20 MINUTOS #####${RESET}"

# Atualizar repositórios do Termux
exibir_titulo "ATUALIZANDO REPOSITÓRIOS DO TERMUX"
pkg update -y
verificar_erro "Falha ao atualizar os repositórios do Termux."
mensagem_sucesso "Repositórios atualizados com sucesso!"

# Verificar e instalar Git
exibir_titulo "VERIFICANDO INSTALAÇÃO DO GIT"
if ! command -v git &> /dev/null; then
    echo "Instalando Git..."
    pkg install -y git
    verificar_erro "Falha ao instalar o Git."
    mensagem_sucesso "Git instalado com sucesso!"
else
    mensagem_sucesso "Git já está instalado."
fi

# Verificar e instalar Go
exibir_titulo "VERIFICANDO INSTALAÇÃO DO GO"
if ! command -v go &> /dev/null; then
    echo "Instalando Go..."
    pkg install -y golang
    verificar_erro "Falha ao instalar o Go."
    mensagem_sucesso "Go instalado com sucesso!"
else
    mensagem_sucesso "Go já está instalado."
fi

# Verificar e instalar SQLite
exibir_titulo "VERIFICANDO INSTALAÇÃO DO SQLITE"
if ! command -v sqlite3 &> /dev/null; then
    echo "Instalando SQLite..."
    pkg install -y sqlite
    verificar_erro "Falha ao instalar o SQLite."
    mensagem_sucesso "SQLite instalado com sucesso!"
else
    mensagem_sucesso "SQLite já está instalado."
fi

# Verificar se o diretório wuzapi já existe
exibir_titulo "PREPARANDO DIRETÓRIO DO PROJETO"
if [ -d "wuzapi" ]; then
    mensagem_aviso "O diretório wuzapi já existe. Removendo para uma instalação limpa..."
    rm -rf wuzapi
fi

# Clonar o repositório do Botzão
exibir_titulo "CLONANDO O REPOSITÓRIO DO WUZAPI"
echo "Clonando de https://github.com/AlecioLopes/wuzapi.git ..."
git clone https://github.com/AlecioLopes/wuzapi.git
verificar_erro "Falha ao clonar o repositório."
mensagem_sucesso "Repositório clonado com sucesso!"

# Navegar para o diretório do projeto
cd wuzapi || mensagem_erro "Falha ao acessar o diretório do projeto."

# Verificar se o diretório dbdata existe, se não, criar
exibir_titulo "CONFIGURANDO DIRETÓRIOS DE DADOS"
if [ ! -d "dbdata" ]; then
    echo "Criando diretório dbdata..."
    mkdir -p dbdata
    verificar_erro "Falha ao criar o diretório dbdata."
    mensagem_sucesso "Diretório dbdata criado com sucesso!"
else
    mensagem_sucesso "Diretório dbdata já existe!"
fi

# Verificar se o banco de dados existe
exibir_titulo "PREPARANDO BANCO DE DADOS"
if [ ! -f "dbdata/users.db" ]; then
    echo "Criando banco de dados..."
    # Criar a tabela users caso não exista
    sqlite3 dbdata/users.db "CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, token TEXT);"
    verificar_erro "Falha ao criar o banco de dados."
    mensagem_sucesso "Banco de dados criado com sucesso!"
else
    mensagem_sucesso "Banco de dados já existe!"
fi

# Compilar o binário do Botzão
exibir_titulo "COMPILANDO O BINÁRIO DO WUZAPI"
echo "Este processo pode demorar alguns minutos..."
go build .
verificar_erro "Falha ao compilar o binário."
mensagem_sucesso "Compilação concluída com sucesso!"

# Verificar se o binário foi compilado corretamente
exibir_titulo "VERIFICANDO RESULTADO DA COMPILAÇÃO"
if [ -f "./wuzapi" ]; then
    mensagem_sucesso "Botzão foi compilado corretamente no Termux."
    
    # Conceder permissões de execução ao binário
    echo "Concedendo permissões de execução ao binário..."
    chmod +x wuzapi
    verificar_erro "Falha ao conceder permissões ao binário wuzapi."
    
    # Verificar se o arquivo executar_wuzapi.sh existe
    if [ -f "executar_wuzapi.sh" ]; then
        chmod +x executar_wuzapi.sh
        verificar_erro "Falha ao conceder permissões ao script executar_wuzapi.sh."
        mensagem_sucesso "Permissões de execução concedidas aos arquivos."
    else
        echo "Arquivo executar_wuzapi.sh não encontrado. Criando..."
        echo '#!/bin/bash' > executar_wuzapi.sh
        echo 'cd "$(dirname "$0")"' >> executar_wuzapi.sh
        echo './wuzapi' >> executar_wuzapi.sh
        chmod +x executar_wuzapi.sh
        verificar_erro "Falha ao criar o script executar_wuzapi.sh."
        mensagem_sucesso "Script de execução criado com sucesso!"
    fi
else
    mensagem_erro "Erro ao compilar o Botzão."
fi

# Inserir dados no banco de dados SQLite (verificando se já existem)
exibir_titulo "CONFIGURANDO USUÁRIOS NO BANCO DE DADOS"
# Verificar se o token 7774 já existe
TOKEN_7774=$(sqlite3 dbdata/users.db "SELECT COUNT(*) FROM users WHERE token='7774';")
if [ "$TOKEN_7774" -eq 0 ]; then
    echo "Inserindo token 7774..."
    sqlite3 dbdata/users.db "INSERT INTO users (name, token) VALUES ('7774', '7774');"
    verificar_erro "Falha ao inserir token 7774 no banco de dados."
    mensagem_sucesso "Token 7774 inserido com sucesso!"
else
    mensagem_aviso "Token 7774 já existe no banco de dados."
fi

# Verificar se o token 7775 já existe
TOKEN_7775=$(sqlite3 dbdata/users.db "SELECT COUNT(*) FROM users WHERE token='7775';")
if [ "$TOKEN_7775" -eq 0 ]; then
    echo "Inserindo token 7775..."
    sqlite3 dbdata/users.db "INSERT INTO users (name, token) VALUES ('7775', '7775');"
    verificar_erro "Falha ao inserir token 7775 no banco de dados."
    mensagem_sucesso "Token 7775 inserido com sucesso!"
else
    mensagem_aviso "Token 7775 já existe no banco de dados."
fi

mensagem_sucesso "Banco de dados configurado com sucesso!"

# Conceder permissões ao Tasker
exibir_titulo "CONFIGURANDO PERMISSÕES PARA O TASKER"
mkdir -p ~/.termux
if ! grep -q "allow-external-apps=true" ~/.termux/termux.properties; then
    echo "allow-external-apps=true" >> ~/.termux/termux.properties
    mensagem_sucesso "Permissões do Tasker configuradas. Você precisará reiniciar o Termux para que as mudanças tenham efeito."
else
    mensagem_sucesso "Permissões do Tasker já estão configuradas."
fi

# Verificar se há algum arquivo de configuração necessário
exibir_titulo "VERIFICANDO ARQUIVOS DE CONFIGURAÇÃO"
if [ ! -f "config.json" ] && [ -f "config.example.json" ]; then
    echo "Arquivo config.json não encontrado. Copiando do exemplo..."
    cp config.example.json config.json
    mensagem_aviso "Lembre-se de editar o arquivo config.json com suas configurações pessoais."
    mensagem_sucesso "Arquivo de configuração criado com sucesso!"
elif [ -f "config.json" ]; then
    mensagem_sucesso "Arquivo de configuração já existe!"
fi

exibir_titulo "INSTALAÇÃO CONCLUÍDA COM SUCESSO!"
echo -e "${VERDE}Para executar o Botzão, use: ./wuzapi${RESET}"

# Perguntar se deseja executar o Botzão agora
echo ""
echo -e "${AMARELO}Deseja executar o Botzão agora? (s/n):${RESET} \c"
read resposta
if [ "$resposta" = "s" ] || [ "$resposta" = "S" ]; then
    exibir_titulo "INICIANDO O WUZAPI"
    ./wuzapi
else
    mensagem_aviso "Para executar o Botzão mais tarde, use o comando: ./wuzapi"
fi