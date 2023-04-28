#!/bin/bash
##############################################################################################################
# Script for installing Community Odoo on Ubuntu 22.04 64Bits and Brazillian Localization
#
# Script is based on https://github.com/Yenthe666/InstallScript 
# Author: Marcelo Costa from engeCloud (www.engecloud.com)
#-------------------------------------------------------------------------------------------------------------
# This script will install Odoo on your Ubuntu Server.
# It can install multiple Odoo instances in one Ubuntu on different "xmlrpc_ports" and different "users"
#-------------------------------------------------------------------------------------------------------------
# # Place this content in it and then make the file executable:
# sudo chmod +x installOdoo16Ubuntu.sh
# Execute the script to install Odoo: ./installOdoo16Ubuntu.sh
#
##############################################################################################################


echo -e "\n*** INFORME OS PARÂMETROS BÁSICOS DE INSTALAÇÃO DO ODOO ***\n"

read -p 'Informe o nome do seu usuário Odoo (ex: odoo): ' ODOO_USER
read -p 'Informe a versão do seu Odoo (ex: 16.0): ' ODOO_VERSION
read -p 'Informe a porta do seu Odoo (ex: 8069): ' ODOO_PORT
read -p 'Informe a sua Timezone (ex: America/Sao_Paulo): ' TIMEZONE
read -p 'Informe a senha administrativa do banco de dados Odoo (ex: Psql-123456): ' DB_ADMINPASS


# Global Variables
ODOO_USER=$ODOO_USER
ODOO_VERSION=$ODOO_VERSION
ODOO_PORT=$ODOO_PORT
TIMEZONE=$TIMEZONE
# Set the superadmin password to postgresql
DB_ADMINPASS=$DB_ADMINPASS

# Fixed variables
ODOO_DIR="/opt/$ODOO_USER"
ODOO_DIR_ADDONS="$ODOO_DIR/${ODOO_USER}-server/addons"
ODOO_DIR_CUSTOM="$ODOO_DIR/custom-addons"
ODOO_DIR_TRUSTCODE="$ODOO_DIR_CUSTOM/odoo-brasil"
ODOO_DIR_OCA="$ODOO_DIR_CUSTOM/oca"
ODOO_DIR_SOULINUX="$ODOO_DIR_CUSTOM/soulinux"
ODOO_DIR_CODE137="$ODOO_DIR_CUSTOM/code137"
ODOO_DIR_SERVER="$ODOO_DIR/${ODOO_USER}-server"
ODOO_CONFIG_FILE="${ODOO_USER}-server.conf"
ODOO_LOG_FILE="${ODOO_USER}-server.log"
ODOO_SERVICE="${ODOO_USER}.service"
ODOO_IP="$(hostname -I)"
LINUX_DISTRIBUTION=$(awk '{ print $1 }' /etc/issue)
INSTALL_WKHTMLTOPDF="True"

echo "
INFORMAÇÕES BÁSICAS DO SEU ODOO:
Usuário Odoo: $ODOO_USER
Versão Odoo: $ODOO_VERSION
Porta Odoo: $ODOO_PORT
Timezone: $TIMEZONE
Senha Banco de Dados: $DB_ADMINPASS
"
while true; do
        echo "Se alguma informação acima não estiver correta, reinicie o script e informe os valores corretos."
        read -p 'As informações estão corretas? Deseja continuar? (s/n)' sn
        case $sn in
        [Ss]*) break ;;
        [Nn]*) exit ;;
        *) echo "Por favor, responda Sim ou Não." ;;
        esac
done

echo "
INFORMAÇÕES DE PASTAS DO ODOO:
Pasta padrão de instalação do Odoo: $ODOO_DIR
Pasta padrão de instalação dos Módulos Personalizados: $ODOO_DIR_CUSTOM

Pasta padrão dos módulos TrustCODE: $ODOO_DIR_TRUSTCODE
Pasta padrão dos módulos OCA: $ODOO_DIR_OCA
Pasta padrão dos módulos Code137: $ODOO_DIR_CODE137
Pasta padrão dos módulos SOULinux: $ODOO_DIR_SOULINUX

Pasta padrão de instalação do servidor Odoo: $ODOO_DIR_SERVER
Arquivo de Configuração: /etc/$ODOO_CONFIG_FILE
Arquivo de Log: /var/log/${ODOO_USER}/${ODOO_LOG_FILE}
Distribuição Linux: $LINUX_DISTRIBUTION
Endereço IP: $ODOO_IP
"

while true; do
        echo "Se alguma informação acima não estiver correta, ajuste os dados no próprio script."
        read -p 'As informações estão corretas? Deseja continuar? (s/n)' sn
        case $sn in
        [Ss]*) break ;;
        [Nn]*) exit ;;
        *) echo "Por favor, responda Sim ou Não." ;;
        esac
done

# Database config
# The variable DB_HOST is disable (False) because we have not a rule to our network at "pg_hba.conf" file.
# If you need access or edit database on other machine, is necessary add a rule in "IPv4 local connections:" field.
# The variable DB_PASSWORD is disable because we have use the password stored on variable DB_ADMINPASS to DB_USER user account.
# If postgres is installed on another machine, these variables must be defined and have an access rule in the field "local IPv4 connections:" at "pg_hba.conf" file.


# Fixed variables to postgresql
DB_USER=$ODOO_USER
DB_PORT="5432"
DB_HOST="False"
DB_PASSWORD="False"

###  WKHTMLTOPDF download link
## Check the correct version of wkhtmltopdf at https://wkhtmltopdf.org/downloads.html

ubuntuVersion=$(lsb_release -c --short)
echo "$ubuntuVersion

if [ "$ubuntuVersion" = "jammy" ]; then
        WKHTMLTOX_X64=https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.jammy_amd64.deb
elif [ "$ubuntuVersion" = "focal" ]; then
        WKHTMLTOX_X64=https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.focal_amd64.deb
else
        echo "Sua versão do Ubuntu é diferente das versões '20.04' e '22.04'. Instale o WKHTMLTOPDF manualmente"
fi

#--------------------------------------------------
# Update Operational System
#--------------------------------------------------
if [ "$LINUX_DISTRIBUTION" = "Ubuntu" ]; then
        sudo apt update && sudo apt upgrade -y
else
        echo "A distribuição não é Ubuntu"
fi
echo -e "LIMPANDO O CACHE DO APT, AGUARDE... \n"
sudo apt autoclean
sudo apt clean

#--------------------------------------------------
# Server Timezone
#--------------------------------------------------
echo -e "\n*** Set Timezone ***"
sudo timedatectl set-timezone $TIMEZONE
echo -e "\n*** LOCAL TIME: ***"
sudo date

#--------------------------------------------------
# Install PostgreSQL Server
#--------------------------------------------------
echo -e "\n*** Install PostgreSQL Server ***"
sudo apt install postgresql postgresql-server-dev-all -y

echo -e "\n*** CREATING THE ODOO POSTGRESQL USER  ***"
sudo su - postgres -c "createuser -s $DB_USER" 2> /dev/null || true
sudo su psql -U postgres -c "ALTER USER $DB_USER WITH PASSWORD '$DB_ADMINPASS'"

#--------------------------------------------------
# Create Odoo System User and log directory
#--------------------------------------------------
echo -e "\n*** CREATE ODOO SYSTEM USER ***"
sudo adduser --system --quiet --shell=/bin/bash --home=$ODOO_DIR --gecos 'ODOO' --group $ODOO_USER
#The user should also be added to the sudo'ers group.
sudo adduser $ODOO_USER sudo

echo -e "\n*** CREATE LOG DIRECTORY ***"
sudo mkdir /var/log/$ODOO_USER
sudo chown $ODOO_USER:$ODOO_USER /var/log/$ODOO_USER

#--------------------------------------------------
# Install Basic Dependencies
#--------------------------------------------------
echo -e "\n*** INSTALLING PYTHON 3 + PIP3 ***"
sudo apt install git gcc wget pkg-config gdebi-core python3 python3-pip python3-venv python3-pil python3-lxml python3-ldap3 python3-wheel python3-suds libxslt1-dev libzip-dev libsasl2-dev python3-setuptools python3-pypdf2 python3-dev libxml2-dev zlib1g-dev libsasl2-dev libldap2-dev build-essential libssl-dev libffi-dev libmysqlclient-dev libjpeg-dev libpq-dev libjpeg8-dev liblcms2-dev libblas-dev libatlas-base-dev libxmlsec1-dev node-less -y

echo -e "\n*** UPGRADE PIP ***"
sudo pip3 install --upgrade pip

echo -e "\n*** INSTALLING GDATA (Google data Python client) ***" 
sudo pip3 install gdata

echo -e "\n*** INSTALANDO NODE JS NPM AND RTLCSS FOR LTR SUPPORT ***"
sudo apt install nodejs node-less npm -y
sudo npm install -g rtlcss less-plugin-clean-css


#--------------------------------------------------
# Install Wkhtmltopdf to PDF reports, if needed
#--------------------------------------------------
if [ $INSTALL_WKHTMLTOPDF = "True" ]; then
  echo -e "\n*** INSTALL WKHTML AND PLACE SHORTCUTS ON CORRECT PLACE FOR ODOO ***"
  sudo apt install fontconfig xfonts-base -y
  cd /tmp
  #pick up correct one from x64 versions:  
  if [ "`getconf LONG_BIT`" == "64" ];then
      _url=$WKHTMLTOX_X64
  else
    echo -e "\n*** YOUR OPERATION SYSTEM IS NOT 64-BIT. WE RECOMMEND CHANGING YOUR OPERATION SYSTEM ***"
  fi
  sudo wget $_url
  sudo gdebi --n `basename $_url`
  sudo ln -s /usr/local/bin/wkhtmltopdf /usr/bin
  sudo ln -s /usr/local/bin/wkhtmltoimage /usr/bin
else
  echo "\n*** WKHTMLTOPDF ISN'T INSATLLED DUE TO THE CHOICE OF THE USER! ***"
fi
cd

#--------------------------------------------------
# Install ODOO
#--------------------------------------------------
echo -e "\n*** INSTALLING ODOO SERVER ***"
sudo git clone https://www.github.com/odoo/odoo --depth 1 --branch $ODOO_VERSION $ODOO_DIR_SERVER/

echo -e "\n*** CREATE CUSTOM ADDONS MODULE DIRECTORY ***"
sudo su $ODOO_USER -c "mkdir $ODOO_DIR_ADDONS"

echo -e "\n*** SETTING PERMISSIONS ON ENTIRE ODOO DIRECTORY ***"
sudo chown -R $ODOO_USER:$ODOO_USER $ODOO_DIR/*

echo -e "\n*** INSTALL ODOO $ODOO_VERSION REQUIREMENTS PYTHON PACKAGES ***"
sudo pip3 install -r $ODOO_DIR_SERVER/requirements.txt

echo -e "\n*** ODOO INSTALL COMPLETED ***"
    
while true; do
        read -p 'Iniciar a instalação dos módulos adicionais? (s/n)' sn
        case $sn in
        [Ss]*) break ;;
        [Nn]*) exit ;;
        *) echo "Por favor, responda Sim(s) ou Não(n)." ;;
        esac
done

#--------------------------------------------------
# Install TRUSTCODE LOCALIZATION (BRAZIL)
#--------------------------------------------------
read -p 'Instalar a Localização Brasileira TrustCODE? (ex: sim ou s): ' TRUSTCODE_INSTALL

if [ "$TRUSTCODE_INSTALL" = "sim" ] || [ "$TRUSTCODE_INSTALL" = "s" ] || [ "$TRUSTCODE_INSTALL" = "S" ] ; then
  echo -e "\n*** CLONE LOCALIZATION FROM GITHUB ***"
  sudo git clone https://github.com/Trust-Code/odoo-brasil --depth 1 --branch $ODOO_VERSION $ODOO_DIR_TRUSTCODE/

  echo -e "\n*** INSTALL TRUSTCODE ODOO $ODOO_VERSION REQUIREMENTS PYTHON PACKAGES ***"
  sudo pip3 install -r $ODOO_DIR_TRUSTCODE/requirements.txt

  echo -e "\n*** INSTALL OTHERS TRUSTCODE PYTHON PACKAGES ***"
  sudo pip3 install python3-cnab python3-boleto pycnab240 python-sped pytrustnfe3

  echo -e "\n*** INSTALL IUGU PYTHON REST API  ***"
  sudo pip3 install iugu

  echo -e "\n*** SETTING PERMISSIONS ON ENTIRE ODOO DIRECTORY ***"
  sudo chown -R $ODOO_USER:$ODOO_USER $ODOO_DIR/*

else
  echo "Os módulos TrustCode não serão instalados"
    while true; do
            read -p 'Continuar a instalação dos demais módulos? (s/n)' sn
            case $sn in
            [Ss]*) break ;;
            [Nn]*) exit ;;
            *) echo "Por favor, responda Sim(s) ou Não(n)." ;;
            esac
    done
fi

#----------------------------------------------------------
# Install OCA MODULES TO REPORTS, FISCAL YEAR and CONTRACT
#---------------------------------------------------------
read -p 'Instalar os módulos OCA para relatórios, ano fiscal e faturas recorrentes? (ex: sim ou s): ' OCA_INSTALL

if [ "$OCA_INSTALL" = "sim" ] || [ "$OCA_INSTALL" = "s" ] || [ "$OCA_INSTALL" = "S" ] ; then
  echo -e "\n*** CLONE 'Server-UX' FROM GITHUB ***"
  sudo git clone https://github.com/OCA/server-ux --depth 1 --branch $ODOO_VERSION $ODOO_DIR_OCA/server-ux

  echo -e "\n*** CLONE 'MIS Builder' FROM GITHUB ***"
  sudo git clone https://github.com/OCA/mis-builder --depth 1 --branch $ODOO_VERSION $ODOO_DIR_OCA/mis-builder

  echo -e "\n*** CLONE 'Reporting Engine' FROM GITHUB ***"
  sudo git clone https://github.com/OCA/reporting-engine --depth 1 --branch $ODOO_VERSION $ODOO_DIR_OCA/reporting-engine

  echo -e "\n*** CLONE 'Financial Tools' FROM GITHUB ***"
  sudo git clone  https://github.com/OCA/account-financial-tools --depth 1 --branch $ODOO_VERSION $ODOO_DIR_OCA/account-financial-tools

  echo -e "\n*** CLONE 'Contract' FROM GITHUB ***"
  sudo git clone  https://github.com/OCA/contract --depth 1 --branch $ODOO_VERSION $ODOO_DIR_OCA/contract


  echo -e "\n*** INSTALL OCA ODOO $ODOO_VERSION REQUIREMENTS PYTHON PACKAGES ***"
  sudo pip3 install -r $ODOO_DIR_OCA/server-ux/requirements.txt
  sudo pip3 install -r $ODOO_DIR_OCA/reporting-engine/requirements.txt
  sudo pip3 install -r $ODOO_DIR_OCA/account-financial-tools/requirements.txt
  sudo pip3 install -r $ODOO_DIR_OCA/contract/requirements.txt

  echo -e "\n*** SETTING PERMISSIONS ON ENTIRE ODOO DIRECTORY ***"
  sudo chown -R $ODOO_USER:$ODOO_USER $ODOO_DIR/*

else
  echo "Os módulos OCA não serão instalados"
    while true; do
            read -p 'Continuar a instalação dos demais módulos? (s/n)' sn
            case $sn in
            [Ss]*) break ;;
            [Nn]*) exit ;;
            *) echo "Por favor, responda Sim(s) ou Não(n)." ;;
            esac
    done
fi

#--------------------------------------------------
# CREATE SERVER CONFIG FILE
#--------------------------------------------------

echo -e "\n*** CREATE SERVER CONFIG FILE ***"
sudo touch /etc/${ODOO_CONFIG_FILE}

sudo su root -c "printf '[options]\n' >> /etc/${ODOO_CONFIG_FILE}"
sudo su root -c "printf '; This is the password that allows database operations:\n' >> /etc/${ODOO_CONFIG_FILE}"
sudo su root -c "printf 'admin_passwd = ${DB_ADMINPASS}\n' >> /etc/${ODOO_CONFIG_FILE}"
sudo su root -c "printf 'db_host = ${DB_HOST}\n' >> /etc/${ODOO_CONFIG_FILE}"
sudo su root -c "printf 'db_password = ${DB_PASSWORD}\n' >> /etc/${ODOO_CONFIG_FILE}"
sudo su root -c "printf 'db_port = ${DB_PORT}\n' >> /etc/${ODOO_CONFIG_FILE}"
sudo su root -c "printf 'db_user = ${DB_USER}\n' >> /etc/${ODOO_CONFIG_FILE}"
sudo su root -c "printf 'xmlrpc_port = ${ODOO_PORT}\n' >> /etc/${ODOO_CONFIG_FILE}"
sudo su root -c "printf 'logfile = /var/log/${ODOO_USER}/${ODOO_LOG_FILE}\n' >> /etc/${ODOO_CONFIG_FILE}"
sudo su root -c "printf 'addons_path=${ODOO_DIR_ADDONS},${ODOO_DIR_TRUSTCODE},${ODOO_DIR_OCA}/mis-builder,${ODOO_DIR_OCA}/reporting-engine,${ODOO_DIR_OCA}/server-ux,${ODOO_DIR_OCA}/account-financial-tools,${ODOO_DIR_OCA}/contract\n' >> /etc/${ODOO_CONFIG_FILE}"

sudo chown $ODOO_USER:$ODOO_USER /etc/${ODOO_CONFIG_FILE}
sudo chmod 640 /etc/${ODOO_CONFIG_FILE}


#--------------------------------------------------
# ODOO AS A DEAMON (INIT SCRIPT)
#--------------------------------------------------

echo -e "*** CREATE SYSTEMD INIT FILE ***"
cat <<EOF > /etc/systemd/system/$ODOO_SERVICE
[Unit]
Description=Odoo Open Source ERP
Requires=postgresql.service
After=network.target postgresql.service
 
[Service]
Type=simple
SyslogIdentifier=odoo-server
PermissionsStartOnly=true
User=${ODOO_USER}
Group=${ODOO_USER}
ExecStart=${ODOO_DIR_SERVER}/odoo-bin -c /etc/${ODOO_CONFIG_FILE}
WorkingDirectory=${ODOO_DIR_SERVER}
StandardOutput=journal+console

[Install]
WantedBy=default.target
EOF


sudo chmod 755 /etc/systemd/system/$ODOO_SERVICE
sudo chown root: /etc/systemd/system/$ODOO_SERVICE

#---------------------------------------------
# ODOO LOGS LOGROTATE
#---------------------------------------------

echo -e "*** CREATE LOGROTATE FILE ***"
cat <<EOF > /etc/logrotate.d/$ODOO_USER
#Generate 1 logfile per day and retain 30 logs

/var/log/${ODOO_USER}/${ODOO_LOG_FILE} {
    daily
    missingok
    rotate 30
    compress
    notifempty
}
EOF


echo -e "*** ODOO ON STARTUP ***"
sudo systemctl enable /etc/systemd/system/$ODOO_SERVICE

echo -e "*** START ODOO ***"
sudo systemctl restart $ODOO_SERVICE

echo -e "*** STATUS ODOO ***"
sudo systemctl status $ODOO_SERVICE


echo -e "*** COMMANDS TO CHECK ODOO LOGS:  ***"
echo -e "*** 'sudo journalctl -u $ODOO_USER' OR 'sudo tail -f /var/log/${ODOO_USER}/${ODOO_LOG_FILE}' ***"


echo -e "*** OPEN ODOO INSTANCE ON YOUR BROWSER ***"
echo -e "*** ************************************************* ***"
echo -e "*** IP ADDRESS: $ODOO_IP - PORT: $ODOO_PORT ***"
echo -e "*** ************************************************* ***"
