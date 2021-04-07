#!/bin/bash
##############################################################################################################
# Script for installing Odoo 14 on Ubuntu 20.04 64Bits
# Script is based on https://github.com/Yenthe666/InstallScript 
# Author: Marcelo Costa from SOULinux (www.soulinux.com)
#-------------------------------------------------------------------------------------------------------------
# This script will install Odoo on your Ubuntu 20.04 server.
# It can install multiple Odoo instances in one Ubuntu on different "xmlrpc_ports" and different "users"
#-------------------------------------------------------------------------------------------------------------
# # Place this content in it and then make the file executable:
# sudo chmod +x installOdoo14Ubuntu.sh
# Execute the script to install Odoo: ./installOdoo14Ubuntu.sh
#
##############################################################################################################

# Set the variables
ODOO_USER="odoo"
ODOO_VERSION="14.0"
ODOO_PORT="8069"
INSTALL_WKHTMLTOPDF="True"

# Fixed variables
ODOO_DIR="/opt/$ODOO_USER"
ODOO_DIR_SERVER="$ODOO_DIR/${ODOO_USER}-server"
ODOO_DIR_ADDONS="$ODOO_DIR/${ODOO_USER}-server/addons"
ODOO_DIR_CUSTOM="$ODOO_DIR/custom-addons"
ODOO_CONFIG="${ODOO_USER}-server"
ODOO_SERVICE="${ODOO_USER}.service"
ODOO_IP="`hostname -I`"

# Database config
# The variable DB_HOST is disable (False) because we have not a rule to our network at "pg_hba.conf" file.
# If you need access or edit database on other machine, is necessary add a rule in "IPv4 local connections:" field.
# The variable DB_PASSWORD is disable because we have use the password stored on variable DB_ADMINPASS to DB_USER user account.
# If postgres is installed on another machine, these variables must be defined and have an access rule in the field "local IPv4 connections:" at "pg_hba.conf" file.

# Set the superadmin password to postgresql
DB_ADMINPASS="Psql-123456"

# Fixed variables to postgresql
DB_USER=$ODOO_USER
DB_PORT="5432"
DB_HOST="False"
DB_PASSWORD="False"

###  WKHTMLTOPDF download link
## Check the correct version of wkhtmltopdf at https://wkhtmltopdf.org/downloads.html
WKHTMLTOX_X64=https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.focal_amd64.deb

#--------------------------------------------------
# Update Server
#--------------------------------------------------
echo -e "\n*** UPDATE SERVER ***"
sudo apt update
sudo apt upgrade -y

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


echo -e "\n*** CREATE SERVER CONFIG FILE ***"
sudo touch /etc/${ODOO_CONFIG}.conf

sudo su root -c "printf '[options]\n' >> /etc/${ODOO_CONFIG}.conf"
sudo su root -c "printf '; This is the password that allows database operations:\n' >> /etc/${ODOO_CONFIG}.conf"
sudo su root -c "printf 'admin_passwd = ${DB_ADMINPASS}\n' >> /etc/${ODOO_CONFIG}.conf"
sudo su root -c "printf 'db_host = ${DB_HOST}\n' >> /etc/${ODOO_CONFIG}.conf"
sudo su root -c "printf 'db_password = ${DB_PASSWORD}\n' >> /etc/${ODOO_CONFIG}.conf"
sudo su root -c "printf 'db_port = ${DB_PORT}\n' >> /etc/${ODOO_CONFIG}.conf"
sudo su root -c "printf 'db_user = ${DB_USER}\n' >> /etc/${ODOO_CONFIG}.conf"
sudo su root -c "printf 'xmlrpc_port = ${ODOO_PORT}\n' >> /etc/${ODOO_CONFIG}.conf"
sudo su root -c "printf 'logfile = /var/log/${ODOO_USER}/${ODOO_CONFIG}.log\n' >> /etc/${ODOO_CONFIG}.conf"
sudo su root -c "printf 'addons_path=${ODOO_DIR_ADDONS}\n' >> /etc/${ODOO_CONFIG}.conf"

sudo chown $ODOO_USER:$ODOO_USER /etc/${ODOO_CONFIG}.conf
sudo chmod 640 /etc/${ODOO_CONFIG}.conf


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
ExecStart=${ODOO_DIR_SERVER}/odoo-bin -c /etc/${ODOO_CONFIG}.conf
WorkingDirectory=${ODOO_DIR_SERVER}
StandardOutput=journal+console

[Install]
WantedBy=default.target
EOF


sudo chmod 755 /etc/systemd/system/$ODOO_SERVICE
sudo chown root: /etc/systemd/system/$ODOO_SERVICE

echo -e "*** START ODOO ON STARTUP ***"
sudo systemctl enable /etc/systemd/system/$ODOO_SERVICE

echo -e "*** START ODOO ***"
sudo systemctl restart $ODOO_SERVICE

echo -e "*** STATUS ODOO ***"
sudo systemctl status $ODOO_SERVICE

echo -e "*** OPEN ODOO INSTANCE ON YOUR BROWSER ***"
echo -e "*** IP ADDRESS: $ODOO_IP - PORT: $ODOO_PORT ***"
