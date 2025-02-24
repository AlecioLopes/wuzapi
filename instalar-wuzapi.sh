#!/bin/bash

Cores para personalização

VERDE='\033[0;32m' VERMELHO='\033[0;31m' AMARELO='\033[0;33m' RESET='\033[0m'

Função para exibir títulos destacados

exibir_titulo() { echo -e "\n${VERDE}▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓" echo -e "    ${1}" echo -e "▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓${RESET}" }

Função para exibir mensagens de sucesso

mensagem_sucesso() { echo -e "${VERDE}✓ $1${RESET}" }

Função para exibir mensagens de erro

mensagem_erro() { echo -e "${VERMELHO}✗ ERRO: $1${RESET}" exit 1 }

Função para verificar se o comando foi executado com sucesso

verificar_erro() { if [ $? -ne 0 ]; then mensagem_erro "$1" fi }

exibir_titulo "INICIANDO INSTALAÇÃO DO BOTZAP" echo -e "${AMARELO}##### ESTE PROCESSO PODE DEMORAR ENTRE 15 A 20 MINUTOS #####${RESET}"

Atualizar repositórios do Termux

exibir_titulo "ATUALIZANDO REPOSITÓRIOS DO TERMUX" pkg update -y verificar_erro "Falha ao atualizar os repositórios do Termux." mensagem_sucesso "Repositórios atualizados com sucesso!"

Instalar dependências necessárias

exibir_titulo "INSTALANDO DEPENDÊNCIAS" pkg install -y git golang sqlite verificar_erro "Falha ao instalar dependências." mensagem_sucesso "Dependências instaladas com sucesso!"

Clonar o repositório do BotZap

exibir_titulo "CLONANDO O REPOSITÓRIO DO BOTZAP" if [ -d "wuzapi" ]; then rm -rf wuzapi fi git clone https://github.com/AlecioLopes/wuzapi.git verificar_erro "Falha ao clonar o repositório." mensagem_sucesso "Repositório clonado com sucesso!"

cd wuzapi || mensagem_erro "Falha ao acessar o diretório do projeto."

Criar banco de dados e configurar estrutura

exibir_titulo "CONFIGURANDO BANCO DE DADOS" mkdir -p dbdata sqlite3 dbdata/users.db "CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, token TEXT);" verificar_erro "Falha ao configurar o banco de dados." mensagem_sucesso "Banco de dados configurado com sucesso!"

Inserir tokens no banco de dados

for token in 7774 7775; do EXISTE=$(sqlite3 dbdata/users.db "SELECT COUNT(*) FROM users WHERE token='$token';") if [ "$EXISTE" -eq 0 ]; then sqlite3 dbdata/users.db "INSERT INTO users (name, token) VALUES ('$token', '$token');" mensagem_sucesso "Token $token inserido com sucesso!" fi done

Compilar o BotZap

go build . verificar_erro "Falha ao compilar o BotZap." mensagem_sucesso "Compilação concluída com sucesso!"

Conceder permissões ao binário

chmod +x wuzapi mensagem_sucesso "Permissões concedidas ao BotZap."

Criar script de execução

cat <<EOL > executar_wuzapi.sh #!/bin/bash cd "$(dirname "$0")" ./wuzapi EOL chmod +x executar_wuzapi.sh mensagem_sucesso "Script de execução criado com sucesso!"

Finalização

echo -e "${VERDE}Para executar o BotZap, use: ./wuzapi${RESET}"

