
## [installOdoo16_interactive.sh](https://github.com/marceloengecom/Odoo-Install/blob/16.0/installOdoo16_interactive.sh)
#### Este script instala a versão Comunity do Odoo 16.0 no Ubuntu e pergunta se deseja instalar os módulos adicionais largamente usados no Brasil



### PROCEDIMENTO DE INSTALAÇÃO

#### 1. Faça o download do respectivo script:
```
sudo wget https://raw.githubusercontent.com/marceloengecom/Odoo-Install/16.0/installOdoo16_interactive.sh
```

#### 2. Torne o respectivo script executável:
```
sudo chmod +x installOdoo16_interactive.sh
```

#### 3. Execute o respectivo script:
```
sudo ./installOdoo16_interactive.sh
```

#### 4. Após executar o script, defina os parâmetros básicos para instalação do Odoo:
```
Nome do seu usuário Odoo (ex: odoo)
Versão do seu Odoo (ex: 16.0)
Porta do seu Odoo (ex: 8069)
Timezone (ex: America/Sao_Paulo)
Senha administrativa do banco de dados (ex: Psql-123456)
```

#### 5. Será perguntado se deseja instalar os seguintes módulos:
```
TrustCode (Módulos para Localização Brasileira)
OCA (módulos para relatórios, ano fiscal e faturas recorrentes)
```

### ACESSE AO SISTEMA E CRIAÇÃO DO BANCO DE DADOS

#### 1. Acesse o Odoo a partir de um navegador web e crie o respectivo banco de dados:
```
http://<EndereçoIP>:<ODOO_PORT>
```

#### 2. Informe os respectivos parâmetros do banco de dados:
```Master Password: <DB_ADMINPASS>
Database Name: <NomeBancoDados>
Email: <EmailUsuarioAdmin>
Password: <SenhaUsuarioAdmin>
Language: Portugues (BR)
Country: Brazil
```
