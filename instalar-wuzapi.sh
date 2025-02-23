bash
#!/bin/bash
echo "##### ESTE PROCESSO PODE DEMORAR ENTRE 15 A 20 MINUTOS #####"

# Instalar Git e Go
echo "Instalando Git e Go..."
pkg install -y git golang &>/dev/null
echo "Git e Go foram instalados corretamente."

# Clonar o repositório do Botzão
echo "Clonando o repositório do Botzão..."
git clone https://github.com/AlecioLopes/wuzapi.git &>/dev/null
echo "Repositório clonado com sucesso."

# Navegar para o diretório do projeto
cd wuzapi

# Compilar o binário do Botzão com o nome padrão
echo "Compilando o binário..."
go build . &>/dev/null

# Verificar se o binário foi compilado corretamente
if [ -f "./wuzapi" ]; then
    echo "Botzão foi compilado corretamente no Termux."
    
    # Conceder permissões de execução ao binário
    chmod +x wuzapi
    chmod +x executar_wuzapi.sh

    echo "Permissões de execução concedidas ao Botzão."
else
    echo "Erro ao compilar o Botzão."
    exit 1
fi

# Instalar SQLite e configurar o banco de dados
echo "Instalando SQLite e configurando o banco de dados..."
pkg install -y sqlite &>/dev/null

# Criar e inserir dados no banco de dados SQLite
echo "Inserindo dados no banco de dados..."
sqlite3 dbdata/users.db "insert into users ('name','token') values ('7774','7774');"
sqlite3 dbdata/users.db "insert into users ('name','token') values ('7775','7775');"
echo "Banco de dados configurado com sucesso."

# Conceder permissões ao Tasker
mkdir -p ~/.termux && echo "allow-external-apps=true" >> ~/.termux/termux.properties

# Executar o Botzão
echo "Executando o Botzão..."
./wuzapi