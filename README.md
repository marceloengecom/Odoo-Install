
## [installOdoo14Ubuntu.sh](https://github.com/marceloengecom/Odoo-Install/blob/14.0/installOdoo14Ubuntu.sh)
#### Este script instala a versão Comunity do Odoo 14.0 no Ubuntu 20.04

### PROCEDIMENTO DE INSTALAÇÃO

#### 1. Download the script:
```
sudo wget https://github.com/marceloengecom/Odoo-Install/blob/14.0/installOdoo14Ubuntu.sh
```

#### 2. Confira os parâmetros e, se necessário, modifique de acordo com o que você deseja:
```
ODOO_USER: Usário de sistema operacional com permissões para execução do Odoo. O padrão é "odoo".
ODOO_VERSION: Versão do Odoo. O padrão é "14.0".
ODOO_PORT: Porta do Odoo. O padrão é "8069".
INSTALL_WKHTMLTOPDF: Biblioteca que permite renderizar converter páginas HTML para PDF. O padrão é "True".
DB_ADMINPASS: Senha administrativa para o usuário postgresql (DB_USER). O padrão é "Psql-123456".
DB_USER: Usuário postgresql para o banco de dados do Odoo. O padrão é "ODOO_USER".
DB_PORT: Porta do Postgresql. O padrão é "5432".
DB_HOST: Endereço do servidor do Odoo. Padrão é "False".
DB_PASSWORD: Senha do usuário postgresql. O padrão é "False".
```

#### 3. Torne o script executável:
```
sudo chmod +x installOdoo14Ubuntu.sh
```

#### 4. Execute o script:
```
./installOdoo14Ubuntu.sh
```

### ACESSE AO SISTEMA E CRIAÇÃO DO BANCO DE DADOS

#### Acesse o Odoo a partir de um navegador web e crie o respectivo banco de dados:
```
http://<EndereçoIP>:<ODOO_PORT>
```

#### Informe os respectivos parâmetros do banco de dados:
```Master Password: <DB_ADMINPASS>
Database Name: <NomeBancoDados>
Email: <EmailUsuarioAdmin>
Password: <SenhaUsuarioAdmin>
Language: Portugues (BR)
Country: Brazil
```
