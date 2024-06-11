#!bin/bash

#Variáveis de acessoa ao banco de dados
readonly USERNAME=root
readonly PASSWORD=urubu100
readonly DATABASE=ideabd 

repositorio=https://github.com/Idea7-2ADSA/ScriptDocker.git

#atualizando ubuntu
sudo apt update
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo apt-get install wget

#criando novo usuario
yes | sudo adduser cliente_idea
echo "cliente_idea:cliente_password" | chpasswd

# Verificar se o Docker está instalado
if ! command -v docker &>/dev/null; then
    echo "Instalando Docker..."
    
    # Criação de diretório para armazenar chaves de repositório e download da chave GPG do Docker
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Adiciona o repositório do Docker às fontes do APT
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Atualiza novamente as listas de pacotes após adicionar o repositório do Docker
    sudo apt-get update

    # Instalação de ferramentas Docker
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Instalação de outras dependências
    sudo apt install -y nala git

    git clone $repositorio
    cd ScriptDocker

    # Instalação do Docker Compose diretamente do binário
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.10.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose

    # Inicia o serviço do Docker, caso não esteja em execução
    sudo chmod 666 /var/run/docker.sock
    sudo systemctl start docker
else
    echo "Docker já está instalado."
fi

touch .env
docker-compose down
docker-compose up -d db

# Aguarda o contêiner do banco de dados estar totalmente operacional
echo "Aguardando o banco de dados iniciar..."
until docker exec db_container mysqladmin ping -h "127.0.0.1" --silent; do
    printf "."
    sleep 2
done

nomamaquina=$(hostname)

query=$(sudo docker exec container_db bash -c "MYSQL_PWD="$PASSWORD" mysql --batch -u root -D"$DATABASE" -e 'SELECT codigoTotem, hostName FROM totem WHERE codigoTotem =\"$nomemaquina\";")

if [ -z "$query"]; then
    echo "Totem não encontrado"
    sleep 2
    echo "Digite o código do totem:"
    read CODIGOTOTEM
    echo "CODIGOTOTEM=$CODIGOTOTEM" >> .env
else
    echo "Totem encontrado"
fi

# Iniciar container com imagens mysql e java
echo "Iniciando compose com imagens..."
sudo docker compose up  app