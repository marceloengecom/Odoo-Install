#!/bin/bash
##############################################################################################################
# Script for installing Truscode Localization (https://github.com/Trust-Code/odoo-brasil)
# to Odoo 14 on Ubuntu 20.04 64Bits
# Author: Marcelo Costa from SOULinux (www.soulinux.com)
#-------------------------------------------------------------------------------------------------------------
# # Place this content in it and then make the file executable:
# sudo chmod +x installTrustCodeOdoo14.sh
# Execute the script to install Odoo: ./installTrustCodeOdoo14.sh
#
##############################################################################################################

# Set the variables
ODOO_USER="odoo"
ODOO_VERSION="14.0"
ODOO_PORT="8069"

# Fixed variables
ODOO_DIR="/opt/$ODOO_USER"
ODOO_DIR_ADDONS="$ODOO_DIR/addons"
ODOO_DIR_TRUSTCODE="$ODOO_DIR_ADDONS/odoo-brasil"
ODOO_CONFIG="${ODOO_USER}-server"
ODOO_SERVICE="${ODOO_USER}.service"
ODOO_IP="`hostname -I`"


#--------------------------------------------------
# Install TRUSTCODE LOCALIZATION (BR)
#--------------------------------------------------
echo -e "\n*** CLONE LOCALIZATION FROM GITHUB ***"
sudo git clone https://github.com/Trust-Code/odoo-brasil --depth 1 --branch $ODOO_VERSION $ODOO_DIR_TRUSTCODE/

echo -e "\n*** INSTALL TRUSTCODE ODOO $ODOO_VERSION REQUIREMENTS PYTHON PACKAGES ***"
sudo pip3 install -r $ODOO_DIR_TRUSTCODE/requirements.txt

echo -e "\n*** SETTING PERMISSIONS ON ENTIRE ODOO DIRECTORY ***"
sudo chown -R $ODOO_USER:$ODOO_USER $ODOO_DIR/*


echo -e "\n*** UPDATE SERVER CONFIG FILE ADDING ADDON PATH ***"
# The corret Trustcode folder must be added to the config file
sudo sed  -i -e "/addons_path=/s/$/,${ODOO_DIR_TRUSTCODE//\//\\/}/" /etc/${ODOO_CONFIG}.conf

sudo chown $ODOO_USER:$ODOO_USER /etc/${ODOO_CONFIG}.conf
sudo chmod 640 /etc/${ODOO_CONFIG}.conf


echo -e "*** RESTART ODOO SERVICE ***"
sudo systemctl restart $ODOO_SERVICE

echo -e "*** STATUS ODOO SERVICE ***"
sudo systemctl status $ODOO_SERVICE

echo -e "*** OPEN ODOO INSTANCE ON YOUR BROWSE ***"
echo -e "*** IP ADDRESS: $ODOO_IP - PORT: $ODOO_PORT ***"