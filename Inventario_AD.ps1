# =============================================================================
# Inventario_AD.ps1
# Realiza o inventário completo do Active Directory e exporta para CSV
#
# Arquivos gerados:
#   Inventario_Usuarios.csv      - Usuários, OU e Grupos
#   Inventario_OUs.csv           - Unidades Organizacionais
#   Inventario_Grupos.csv        - Grupos e membros
#   Inventario_Computadores.csv  - Computadores do domínio
#
# Pré-requisito: PowerShell com módulo ActiveDirectory (RSAT) instalado.
#                Executar como Administrador de Domínio.
# =============================================================================

#Requires -Modules ActiveDirectory

# ---------- Pasta de saída ---------------------------------------------------
$DataHora  = Get-Date -Format "yyyyMMdd_HHmmss"
$OutputDir = Join-Path $PSScriptRoot "Inventario_$DataHora"
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

Write-Host ""
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "   INVENTARIO DO ACTIVE DIRECTORY" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "Pasta de saida: $OutputDir" -ForegroundColor Gray
Write-Host ""

# =============================================================================
# 1. USUARIOS
# =============================================================================
Write-Host "[1/4] Coletando usuarios..." -ForegroundColor Yellow

$Usuarios = Get-ADUser -Filter * -Properties `
    DisplayName, GivenName, Surname, SamAccountName,
    EmailAddress, Department, Title,
    Enabled, LockedOut, PasswordNeverExpires,
    PasswordLastSet, LastLogonDate, WhenCreated,
    DistinguishedName, MemberOf |
ForEach-Object {

    # OU: remove o CN do inicio do DN para obter o caminho da OU
    $OU = $_.DistinguishedName -replace '^CN=[^,]+,', ''

    # Grupos: extrai apenas o nome (CN) de cada grupo
    $Grupos = if ($_.MemberOf) {
        ($_.MemberOf | ForEach-Object {
            $_ -replace '^CN=([^,]+),.+$', '$1'
        }) -join '; '
    } else {
        'Nenhum'
    }

    [PSCustomObject]@{
        'Nome Completo'        = $_.DisplayName
        'Nome'                 = $_.GivenName
        'Sobrenome'            = $_.Surname
        'Login (SAM)'          = $_.SamAccountName
        'Email'                = $_.EmailAddress
        'Departamento'         = $_.Department
        'Cargo'                = $_.Title
        'Habilitado'           = $_.Enabled
        'Bloqueado'            = $_.LockedOut
        'Senha Nunca Expira'   = $_.PasswordNeverExpires
        'Ultima Troca de Senha'= $_.PasswordLastSet
        'Ultimo Logon'         = $_.LastLogonDate
        'Data de Criacao'      = $_.WhenCreated
        'Unidade Organizacional' = $OU
        'Grupos'               = $Grupos
    }
}

$ArquivoUsuarios = "$OutputDir\Inventario_Usuarios.csv"
$Usuarios | Export-Csv -Path $ArquivoUsuarios -NoTypeInformation -Encoding UTF8
Write-Host "  -> $($Usuarios.Count) usuarios exportados: Inventario_Usuarios.csv" -ForegroundColor Green

# =============================================================================
# 2. UNIDADES ORGANIZACIONAIS
# =============================================================================
Write-Host "[2/4] Coletando Unidades Organizacionais..." -ForegroundColor Yellow

$OUs = Get-ADOrganizationalUnit -Filter * -Properties Description, WhenCreated, ManagedBy |
ForEach-Object {

    # Conta usuarios diretamente dentro da OU (sem sub-OUs)
    $QtdUsuarios = (Get-ADUser -Filter * -SearchBase $_.DistinguishedName -SearchScope OneLevel).Count

    # Conta sub-OUs
    $QtdSubOUs = (Get-ADOrganizationalUnit -Filter * -SearchBase $_.DistinguishedName -SearchScope OneLevel).Count

    [PSCustomObject]@{
        'Nome'              = $_.Name
        'Descricao'         = $_.Description
        'Gerenciado Por'    = $_.ManagedBy
        'Qtd Usuarios'      = $QtdUsuarios
        'Qtd Sub-OUs'       = $QtdSubOUs
        'Data de Criacao'   = $_.WhenCreated
        'Distinguished Name'= $_.DistinguishedName
    }
}

$ArquivoOUs = "$OutputDir\Inventario_OUs.csv"
$OUs | Export-Csv -Path $ArquivoOUs -NoTypeInformation -Encoding UTF8
Write-Host "  -> $($OUs.Count) OUs exportadas: Inventario_OUs.csv" -ForegroundColor Green

# =============================================================================
# 3. GRUPOS
# =============================================================================
Write-Host "[3/4] Coletando Grupos..." -ForegroundColor Yellow

$Grupos = Get-ADGroup -Filter * -Properties Description, GroupScope, GroupCategory, Members, WhenCreated |
ForEach-Object {

    $Membros = if ($_.Members) {
        ($_.Members | ForEach-Object {
            $_ -replace '^CN=([^,]+),.+$', '$1'
        }) -join '; '
    } else {
        'Nenhum'
    }

    [PSCustomObject]@{
        'Nome'              = $_.Name
        'Categoria'         = $_.GroupCategory
        'Escopo'            = $_.GroupScope
        'Descricao'         = $_.Description
        'Qtd Membros'       = $_.Members.Count
        'Membros'           = $Membros
        'Data de Criacao'   = $_.WhenCreated
        'Distinguished Name'= $_.DistinguishedName
    }
}

$ArquivoGrupos = "$OutputDir\Inventario_Grupos.csv"
$Grupos | Export-Csv -Path $ArquivoGrupos -NoTypeInformation -Encoding UTF8
Write-Host "  -> $($Grupos.Count) grupos exportados: Inventario_Grupos.csv" -ForegroundColor Green

# =============================================================================
# 4. COMPUTADORES
# =============================================================================
Write-Host "[4/4] Coletando Computadores..." -ForegroundColor Yellow

$Computadores = Get-ADComputer -Filter * -Properties `
    OperatingSystem, OperatingSystemVersion,
    LastLogonDate, WhenCreated, Enabled,
    IPv4Address, Description, DistinguishedName |
ForEach-Object {

    $OU = $_.DistinguishedName -replace '^CN=[^,]+,', ''

    [PSCustomObject]@{
        'Nome'                   = $_.Name
        'Sistema Operacional'    = $_.OperatingSystem
        'Versao SO'              = $_.OperatingSystemVersion
        'Endereco IPv4'          = $_.IPv4Address
        'Habilitado'             = $_.Enabled
        'Descricao'              = $_.Description
        'Ultimo Logon'           = $_.LastLogonDate
        'Data de Criacao'        = $_.WhenCreated
        'Unidade Organizacional' = $OU
    }
}

$ArquivoComputadores = "$OutputDir\Inventario_Computadores.csv"
$Computadores | Export-Csv -Path $ArquivoComputadores -NoTypeInformation -Encoding UTF8
Write-Host "  -> $($Computadores.Count) computadores exportados: Inventario_Computadores.csv" -ForegroundColor Green

# =============================================================================
# RESUMO FINAL
# =============================================================================
Write-Host ""
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "   INVENTARIO CONCLUIDO" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "  Usuarios    : $($Usuarios.Count)"    -ForegroundColor White
Write-Host "  OUs         : $($OUs.Count)"         -ForegroundColor White
Write-Host "  Grupos      : $($Grupos.Count)"      -ForegroundColor White
Write-Host "  Computadores: $($Computadores.Count)" -ForegroundColor White
Write-Host ""
Write-Host "Arquivos salvos em: $OutputDir" -ForegroundColor Gray
Write-Host ""
