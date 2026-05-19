# 🗂️ Active Directory Manager — PowerShell Toolkit

Conjunto de scripts PowerShell para **gerenciamento e inventário do Active Directory**, cobrindo criação em massa de usuários e exportação completa do ambiente para arquivos CSV.

---

## 📋 Visão Geral

Este projeto foi desenvolvido para automatizar tarefas rotineiras de administração de domínio, eliminando a necessidade de criação manual de objetos no AD e facilitando auditorias e documentação do ambiente.

| Script | Função |
|---|---|
| `Importar_Usuarios_AD.ps1` | Importa usuários em massa a partir de um CSV |
| `Inventario_AD.ps1` | Gera inventário completo do AD e exporta para CSV |

---

## 🏗️ Estrutura do Domínio

O projeto foi desenvolvido sobre a seguinte estrutura de Active Directory:

```
workgroup.com
├── OU=Financeiro
│   ├── OU=Users
│   └── OU=Computers
├── OU=Contabilidade
├── OU=SQL SERVER Service
└── OU=Domain Controllers
```

---

## 📁 Arquivos do Projeto

```
📦 AD-Manager/
 ┣ 📜 Importar_Usuarios_AD.ps1      # Script de importação em massa
 ┣ 📜 Inventario_AD.ps1             # Script de inventário do AD
 ┣ 📄 Novos_Usuarios_AD.csv         # CSV com os 100 usuários gerados
 ┗ 📖 README.md
```

---

## ⚙️ Pré-requisitos

- Windows Server com **Active Directory Domain Services** configurado
- **RSAT** (Remote Server Administration Tools) instalado na máquina de execução
- PowerShell **5.1 ou superior**
- Conta com permissões de **Administrador de Domínio**

### Verificar se o módulo AD está disponível

```powershell
Get-Module -ListAvailable -Name ActiveDirectory
```

### Instalar RSAT (Windows 10/11)

```powershell
Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0
```

---

## 🚀 Como Usar

### 1. Importação de Usuários em Massa

Coloque o arquivo `Novos_Usuarios_AD.csv` na mesma pasta do script e execute:

```powershell
# Liberar execução na sessão atual
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# Executar o script
.\Importar_Usuarios_AD.ps1
```

**O script irá:**
- Ler cada linha do CSV
- Verificar se o usuário já existe (evita duplicatas)
- Criar o usuário na OU correta
- Adicionar ao grupo definido
- Forçar troca de senha no primeiro login
- Gerar um log `.txt` com o resultado de cada operação

**Colunas esperadas no CSV:**

| Coluna | Descrição |
|---|---|
| `Name` | Nome completo |
| `SamAccountName` | Login (ex: `joao.silva`) |
| `GivenName` | Primeiro nome |
| `Surname` | Sobrenome |
| `DisplayName` | Nome de exibição |
| `Department` | Departamento |
| `OU` | Distinguished Name da OU de destino |
| `Group` | Grupo ao qual o usuário será adicionado |
| `Password` | Senha inicial |
| `Email` | Endereço de e-mail |
| `Title` | Cargo |
| `Enabled` | `TRUE` ou `FALSE` |

---

### 2. Inventário do Active Directory

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

.\Inventario_AD.ps1
```

**O script gera automaticamente uma pasta** `Inventario_YYYYMMDD_HHMMSS` com os seguintes arquivos:

| Arquivo CSV | Conteúdo |
|---|---|
| `Inventario_Usuarios.csv` | Todos os usuários com OU e grupos vinculados |
| `Inventario_OUs.csv` | Todas as OUs com quantidade de usuários e sub-OUs |
| `Inventario_Grupos.csv` | Todos os grupos com escopo, categoria e membros |
| `Inventario_Computadores.csv` | Computadores ingressados com SO, IP e OU |

**Exemplo de saída no terminal:**

```
=================================================
   INVENTARIO DO ACTIVE DIRECTORY
=================================================
[1/4] Coletando usuarios...
  -> 109 usuarios exportados: Inventario_Usuarios.csv
[2/4] Coletando Unidades Organizacionais...
  -> 6 OUs exportadas: Inventario_OUs.csv
[3/4] Coletando Grupos...
  -> 28 grupos exportados: Inventario_Grupos.csv
[4/4] Coletando Computadores...
  -> 2 computadores exportados: Inventario_Computadores.csv
=================================================
   INVENTARIO CONCLUIDO
=================================================
```

---

## 🔒 Segurança

- A senha padrão no CSV de exemplo é `P@ssw0rd2024!` — **altere antes de usar em produção**
- O script de importação marca `ChangePasswordAtLogon = $true` para todos os usuários
- **Nunca versione CSVs com senhas reais** — adicione ao `.gitignore`:

```gitignore
# Ignorar CSVs com dados sensíveis
Novos_Usuarios_AD.csv
Inventario_*/
Log_*.txt
```

---

## 📌 Observações

- Os scripts foram testados em ambiente **Windows Server 2019/2022** com domínio `workgroup.com`
- Para outros domínios, nenhuma alteração é necessária — os scripts detectam o domínio automaticamente via `Get-ADDomain`
- Os arquivos de inventário podem ser abertos diretamente no **Excel** para análise e filtragem

---

## 👤 Autor

Projeto desenvolvido para automação de ambiente Active Directory em ambiente corporativo.

---

## 📄 Licença

Este projeto está sob a licença [MIT](LICENSE).