<#
install_and_register_module.ps1
Instala o módulo WinPurusHelpers e registra alias 'irmx' no profile AllUsers.
Execute este script como Administrador.
#>

Set-StrictMode -Version Latest

# Paths
$moduleSource = Join-Path $PSScriptRoot 'WinPurusHelpers.psm1'
$moduleDestRoot = 'C:\Program Files\WindowsPowerShell\Modules\WinPurus\1.0.0'
$moduleDest = Join-Path $moduleDestRoot 'WinPurusHelpers.psm1'
$allProfile = Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\profile.ps1'

# Verifica execução como administrador
$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $IsAdmin) {
    Write-Warning 'Este instalador precisa ser executado como Administrador. Relançando...'
    Start-Process -FilePath powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Verifica se o arquivo fonte existe
if (-not (Test-Path $moduleSource)) { Write-Error "Módulo de origem não encontrado: $moduleSource"; exit 1 }

# Cria destino
if (-not (Test-Path $moduleDestRoot)) { New-Item -Path $moduleDestRoot -ItemType Directory -Force | Out-Null }

# Copia módulo
Copy-Item -Path $moduleSource -Destination $moduleDest -Force
Write-Host "Módulo copiado para: $moduleDest" -ForegroundColor Green

# Importa módulo
try {
    Import-Module WinPurus -Force -ErrorAction Stop
    Write-Host "Módulo importado com sucesso." -ForegroundColor Green
} catch {
    Write-Warning "Falha ao importar módulo: $_"
}

# Registra Import-Module no profile AllUsers se não existir
$importLine = 'Import-Module WinPurus -ErrorAction SilentlyContinue'
if (-not (Test-Path $allProfile)) { New-Item -Path $allProfile -ItemType File -Force | Out-Null }
$profileContent = Get-Content $allProfile -ErrorAction SilentlyContinue -Raw
if ($profileContent -notmatch [regex]::Escape($importLine)) {
    Add-Content -Path $allProfile -Value "`n$importLine`n"
    Write-Host "Import-Module adicionado ao perfil AllUsers." -ForegroundColor Green
} else {
    Write-Host "Import-Module já presente no perfil AllUsers." -ForegroundColor Yellow
}

# Adiciona alias irmx se não existir
$aliasFunction = "function irmx { param([string]`$u,[string]`$h) Invoke-RemoteScriptSecure -Url `$u -TrustedSHA256Url `$h } ; Set-Alias -Name irmx -Value irmx"
if ($profileContent -notmatch 'irmx') {
    Add-Content -Path $allProfile -Value "`n$aliasFunction`n"
    Write-Host "Alias 'irmx' registrado no profile AllUsers." -ForegroundColor Green
} else {
    Write-Host "Alias 'irmx' já existe no profile AllUsers." -ForegroundColor Yellow
}

Write-Host "Instalação concluída. Reinicie os consoles do PowerShell para aplicar as mudanças." -ForegroundColor Cyan
