#!/bin/bash

# Instalar o SQLite
echo "Instalando o SQLite..."
pkg install -y sqlite &>/dev/null
echo "SQLite instalado com sucesso."

# Inserir dados no banco de dados
echo "Inserindo dados no banco de dados..."
sqlite3 dbdata/users.db "insert into users ('name','token') values ('7774','7774');"
sqlite3 dbdata/users.db "insert into users ('name','token') values ('7775','7775');"
echo "Dados inseridos com sucesso."

# Iniciar o script do wuzapi novamente
echo "Iniciando o wuzapi..."
cd ~/wuzapi
./wuzapi
