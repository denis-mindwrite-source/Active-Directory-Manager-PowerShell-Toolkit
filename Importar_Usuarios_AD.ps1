# =============================================================================
# Importar_Usuarios_AD.ps1
# Importa 100 usuários do CSV "Novos_Usuarios_AD.csv" para o Active Directory
# Domínio: workgroup.com
#
# Pré-requisito: executar como Administrador de Domínio em um DC ou máquina
#                com o módulo ActiveDirectory instalado (RSAT).
# =============================================================================

#Requires -Modules ActiveDirectory
#Requires -RunAsAdministrator

# ---------- Configurações ---------------------------------------------------
$CSVPath    = Join-Path $PSScriptRoot "Novos_Usuarios_AD.csv"
$LogPath    = Join-Path $PSScriptRoot "Log_Importacao_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$Dominio    = "workgroup.com"
$UPNSufixo  = "@$Dominio"

# ---------- Funções auxiliares -----------------------------------------------
function Write-Log {
    param([string]$Mensagem, [string]$Nivel = "INFO")
    $linha = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Nivel] $Mensagem"
    Write-Host $linha -ForegroundColor $(if ($Nivel -eq "ERRO") { "Red" } elseif ($Nivel -eq "AVISO") { "Yellow" } else { "Cyan" })
    $linha | Out-File -FilePath $LogPath -Append -Encoding UTF8
}

# ---------- Verificações iniciais --------------------------------------------
Write-Log "=== Início da importação de usuários AD ==="
Write-Log "CSV: $CSVPath"
Write-Log "Log: $LogPath"

if (-not (Test-Path $CSVPath)) {
    Write-Log "Arquivo CSV não encontrado: $CSVPath" "ERRO"
    exit 1
}

try {
    Import-Module ActiveDirectory -ErrorAction Stop
    Write-Log "Módulo ActiveDirectory carregado com sucesso."
} catch {
    Write-Log "Falha ao carregar o módulo ActiveDirectory: $_" "ERRO"
    exit 1
}

# ---------- Importação -------------------------------------------------------
$usuarios   = Import-Csv -Path $CSVPath -Encoding UTF8
$total      = $usuarios.Count
$sucesso    = 0
$falhas     = 0
$ignorados  = 0

Write-Log "Total de usuários no CSV: $total"
Write-Log "-------------------------------------------"

foreach ($u in $usuarios) {

    $sam  = $u.SamAccountName.Trim()
    $nome = $u.Name.Trim()

    # Verificar se o usuário já existe
    if (Get-ADUser -Filter { SamAccountName -eq $sam } -ErrorAction SilentlyContinue) {
        Write-Log "Usuário já existe, ignorado: $sam ($nome)" "AVISO"
        $ignorados++
        continue
    }

    # Converter senha em SecureString
    try {
        $senhaSegura = ConvertTo-SecureString $u.Password -AsPlainText -Force
    } catch {
        Write-Log "Erro ao converter senha para $sam : $_" "ERRO"
        $falhas++
        continue
    }

    # Parâmetros do New-ADUser
    $params = @{
        Name                  = $nome
        SamAccountName        = $sam
        GivenName             = $u.GivenName.Trim()
        Surname               = $u.Surname.Trim()
        DisplayName           = $u.DisplayName.Trim()
        UserPrincipalName     = "$sam$UPNSufixo"
        EmailAddress          = $u.Email.Trim()
        Department            = $u.Department.Trim()
        Title                 = $u.Title.Trim()
        AccountPassword       = $senhaSegura
        ChangePasswordAtLogon = $true
        Enabled               = ($u.Enabled -eq "TRUE")
        Path                  = $u.OU.Trim()
        ErrorAction           = "Stop"
    }

    try {
        New-ADUser @params
        Write-Log "Usuário criado: $sam | $nome | OU: $($u.OU)"

        # Adicionar ao grupo se especificado
        if ($u.Group -and $u.Group.Trim() -ne "") {
            try {
                Add-ADGroupMember -Identity $u.Group.Trim() -Members $sam -ErrorAction Stop
                Write-Log "  → Adicionado ao grupo: $($u.Group)"
            } catch {
                Write-Log "  → Falha ao adicionar ao grupo '$($u.Group)': $_" "AVISO"
            }
        }

        $sucesso++

    } catch {
        Write-Log "Falha ao criar $sam ($nome): $_" "ERRO"
        $falhas++
    }
}

# ---------- Resumo -----------------------------------------------------------
Write-Log "==========================================="
Write-Log "Importação concluída."
Write-Log "  Criados com sucesso : $sucesso"
Write-Log "  Já existiam (skip)  : $ignorados"
Write-Log "  Falhas              : $falhas"
Write-Log "  Total processados   : $total"
Write-Log "Log salvo em: $LogPath"
