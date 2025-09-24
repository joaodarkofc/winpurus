#Requires -RunAsAdministrator

<#
.SYNOPSIS
    WinPurus - Módulo de Ativação Legal
.DESCRIPTION
    Script para ativação legal do Windows e Office usando comandos oficiais da Microsoft
.PARAMETER Product
    Produto a ser ativado: Windows ou Office
.PARAMETER ProductKey
    Chave de produto legítima
.PARAMETER Action
    Ação: install-key, activate, check-status
.NOTES
    Versão: 1.0.0
    Autor: WinPurus Team
    Requer: PowerShell 5.1+ e permissões de Administrador
    IMPORTANTE: Use apenas chaves legítimas e licenças válidas
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("Windows", "Office")]
    [string]$Product,
    
    [Parameter(Mandatory=$false)]
    [string]$ProductKey,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet("install-key", "activate", "check-status")]
    [string]$Action,
    
    [switch]$DryRun,
    [switch]$Quiet
)

# Configurações
$ErrorActionPreference = "Continue"
$LogPath = "C:\ProgramData\WinPurus\winpurus.log"

# Função de log
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] [ACTIVATION] $Message"
    
    try {
        $logDir = Split-Path $LogPath -Parent
        if (-not (Test-Path $logDir)) {
            New-Item -Path $logDir -ItemType Directory -Force | Out-Null
        }
        Add-Content -Path $LogPath -Value $logEntry -Encoding UTF8
    } catch {
        Write-Warning "Não foi possível escrever no log: $_"
    }
    
    if (-not $Quiet) {
        switch ($Level) {
            "ERROR" { Write-Host $Message -ForegroundColor Red }
            "WARN"  { Write-Host $Message -ForegroundColor Yellow }
            "SUCCESS" { Write-Host $Message -ForegroundColor Green }
            default { Write-Host $Message -ForegroundColor White }
        }
    }
}

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-ProductKey {
    param([string]$Key)
    
    if ([string]::IsNullOrEmpty($Key)) {
        return $false
    }
    
    # Verificar formato básico da chave (XXXXX-XXXXX-XXXXX-XXXXX-XXXXX)
    $keyPattern = "^[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}$"
    
    if ($Key -match $keyPattern) {
        return $true
    } else {
        Write-Log "Formato de chave inválido. Use o formato: XXXXX-XXXXX-XXXXX-XXXXX-XXXXX" "ERROR"
        return $false
    }
}

function Get-WindowsActivationStatus {
    try {
        Write-Log "Verificando status de ativação do Windows..."
        
        # Usar slmgr para obter status
        $slmgrOutput = & cscript //nologo "$env:WINDIR\System32\slmgr.vbs" /dli
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Status do Windows:" "SUCCESS"
            $slmgrOutput | ForEach-Object { Write-Log "  $_" }
            
            # Verificar se está ativado
            $isActivated = $slmgrOutput | Where-Object { $_ -like "*License Status*" -and $_ -like "*Licensed*" }
            
            if ($isActivated) {
                Write-Log "Windows está ATIVADO" "SUCCESS"
                return $true
            } else {
                Write-Log "Windows NÃO está ativado" "WARN"
                return $false
            }
        } else {
            Write-Log "Erro ao verificar status do Windows" "ERROR"
            return $false
        }
    } catch {
        Write-Log "Erro ao verificar ativação do Windows: $_" "ERROR"
        return $false
    }
}

function Get-OfficeActivationStatus {
    try {
        Write-Log "Verificando status de ativação do Office..."
        
        # Procurar instalações do Office
        $officePaths = @(
            "${env:ProgramFiles}\Microsoft Office\Office16",
            "${env:ProgramFiles}\Microsoft Office\Office15",
            "${env:ProgramFiles(x86)}\Microsoft Office\Office16",
            "${env:ProgramFiles(x86)}\Microsoft Office\Office15",
            "${env:ProgramFiles}\Common Files\microsoft shared\ClickToRun",
            "${env:ProgramFiles(x86)}\Common Files\microsoft shared\ClickToRun"
        )
        
        $osppPath = $null
        foreach ($path in $officePaths) {
            $testPath = Join-Path $path "ospp.vbs"
            if (Test-Path $testPath) {
                $osppPath = $testPath
                break
            }
        }
        
        if (-not $osppPath) {
            Write-Log "Office não encontrado ou ospp.vbs não localizado" "WARN"
            return $false
        }
        
        Write-Log "Usando ospp.vbs em: $osppPath"
        
        # Verificar status do Office
        $osppOutput = & cscript //nologo $osppPath /dstatus
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Status do Office:" "SUCCESS"
            $osppOutput | ForEach-Object { Write-Log "  $_" }
            
            # Verificar se está ativado
            $isActivated = $osppOutput | Where-Object { $_ -like "*LICENSE STATUS*" -and $_ -like "*LICENSED*" }
            
            if ($isActivated) {
                Write-Log "Office está ATIVADO" "SUCCESS"
                return $true
            } else {
                Write-Log "Office NÃO está ativado" "WARN"
                return $false
            }
        } else {
            Write-Log "Erro ao verificar status do Office" "ERROR"
            return $false
        }
    } catch {
        Write-Log "Erro ao verificar ativação do Office: $_" "ERROR"
        return $false
    }
}

function Install-WindowsKey {
    param([string]$Key)
    
    try {
        Write-Log "Instalando chave do Windows: $($Key.Substring(0,5))-XXXXX-XXXXX-XXXXX-XXXXX"
        
        if ($DryRun) {
            Write-Log "MODO DRY-RUN: Chave seria instalada" "WARN"
            return $true
        }
        
        # Instalar chave usando slmgr
        $result = & cscript //nologo "$env:WINDIR\System32\slmgr.vbs" /ipk $Key
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Chave do Windows instalada com sucesso" "SUCCESS"
            $result | ForEach-Object { Write-Log "  $_" }
            return $true
        } else {
            Write-Log "Erro ao instalar chave do Windows" "ERROR"
            $result | ForEach-Object { Write-Log "  $_" "ERROR" }
            return $false
        }
    } catch {
        Write-Log "Erro ao instalar chave do Windows: $_" "ERROR"
        return $false
    }
}

function Install-OfficeKey {
    param([string]$Key)
    
    try {
        Write-Log "Instalando chave do Office: $($Key.Substring(0,5))-XXXXX-XXXXX-XXXXX-XXXXX"
        
        # Procurar ospp.vbs
        $officePaths = @(
            "${env:ProgramFiles}\Microsoft Office\Office16",
            "${env:ProgramFiles}\Microsoft Office\Office15",
            "${env:ProgramFiles(x86)}\Microsoft Office\Office16",
            "${env:ProgramFiles(x86)}\Microsoft Office\Office15",
            "${env:ProgramFiles}\Common Files\microsoft shared\ClickToRun",
            "${env:ProgramFiles(x86)}\Common Files\microsoft shared\ClickToRun"
        )
        
        $osppPath = $null
        foreach ($path in $officePaths) {
            $testPath = Join-Path $path "ospp.vbs"
            if (Test-Path $testPath) {
                $osppPath = $testPath
                break
            }
        }
        
        if (-not $osppPath) {
            Write-Log "Office não encontrado ou ospp.vbs não localizado" "ERROR"
            return $false
        }
        
        if ($DryRun) {
            Write-Log "MODO DRY-RUN: Chave seria instalada no Office" "WARN"
            return $true
        }
        
        # Instalar chave usando ospp.vbs
        $result = & cscript //nologo $osppPath /inpkey:$Key
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Chave do Office instalada com sucesso" "SUCCESS"
            $result | ForEach-Object { Write-Log "  $_" }
            return $true
        } else {
            Write-Log "Erro ao instalar chave do Office" "ERROR"
            $result | ForEach-Object { Write-Log "  $_" "ERROR" }
            return $false
        }
    } catch {
        Write-Log "Erro ao instalar chave do Office: $_" "ERROR"
        return $false
    }
}

function Activate-Windows {
    try {
        Write-Log "Ativando Windows..."
        
        if ($DryRun) {
            Write-Log "MODO DRY-RUN: Windows seria ativado" "WARN"
            return $true
        }
        
        # Ativar usando slmgr
        $result = & cscript //nologo "$env:WINDIR\System32\slmgr.vbs" /ato
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Windows ativado com sucesso!" "SUCCESS"
            $result | ForEach-Object { Write-Log "  $_" }
            
            # Verificar status após ativação
            Start-Sleep -Seconds 3
            Get-WindowsActivationStatus
            return $true
        } else {
            Write-Log "Erro ao ativar Windows" "ERROR"
            $result | ForEach-Object { Write-Log "  $_" "ERROR" }
            return $false
        }
    } catch {
        Write-Log "Erro ao ativar Windows: $_" "ERROR"
        return $false
    }
}

function Activate-Office {
    try {
        Write-Log "Ativando Office..."
        
        # Procurar ospp.vbs
        $officePaths = @(
            "${env:ProgramFiles}\Microsoft Office\Office16",
            "${env:ProgramFiles}\Microsoft Office\Office15",
            "${env:ProgramFiles(x86)}\Microsoft Office\Office16",
            "${env:ProgramFiles(x86)}\Microsoft Office\Office15",
            "${env:ProgramFiles}\Common Files\microsoft shared\ClickToRun",
            "${env:ProgramFiles(x86)}\Common Files\microsoft shared\ClickToRun"
        )
        
        $osppPath = $null
        foreach ($path in $officePaths) {
            $testPath = Join-Path $path "ospp.vbs"
            if (Test-Path $testPath) {
                $osppPath = $testPath
                break
            }
        }
        
        if (-not $osppPath) {
            Write-Log "Office não encontrado ou ospp.vbs não localizado" "ERROR"
            return $false
        }
        
        if ($DryRun) {
            Write-Log "MODO DRY-RUN: Office seria ativado" "WARN"
            return $true
        }
        
        # Ativar usando ospp.vbs
        $result = & cscript //nologo $osppPath /act
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Office ativado com sucesso!" "SUCCESS"
            $result | ForEach-Object { Write-Log "  $_" }
            
            # Verificar status após ativação
            Start-Sleep -Seconds 3
            Get-OfficeActivationStatus
            return $true
        } else {
            Write-Log "Erro ao ativar Office" "ERROR"
            $result | ForEach-Object { Write-Log "  $_" "ERROR" }
            return $false
        }
    } catch {
        Write-Log "Erro ao ativar Office: $_" "ERROR"
        return $false
    }
}

# Verificar se é administrador
if (-not (Test-Administrator)) {
    Write-Log "Este script requer permissões de Administrador!" "ERROR"
    exit 1
}

# Validar chave se necessário
if ($Action -eq "install-key" -and -not (Test-ProductKey $ProductKey)) {
    Write-Log "Chave de produto inválida!" "ERROR"
    exit 1
}

Write-Log "Iniciando processo de ativação legal"
Write-Log "Produto: $Product"
Write-Log "Ação: $Action"

# Aviso legal
Write-Log "AVISO LEGAL: Use apenas chaves legítimas e licenças válidas!" "WARN"
Write-Log "Este script não suporta ativadores ilegais ou bypass de licenças" "WARN"

try {
    switch ($Product) {
        "Windows" {
            switch ($Action) {
                "install-key" {
                    $success = Install-WindowsKey $ProductKey
                    if (-not $success) { exit 1 }
                }
                "activate" {
                    $success = Activate-Windows
                    if (-not $success) { exit 1 }
                }
                "check-status" {
                    Get-WindowsActivationStatus
                }
            }
        }
        "Office" {
            switch ($Action) {
                "install-key" {
                    $success = Install-OfficeKey $ProductKey
                    if (-not $success) { exit 1 }
                }
                "activate" {
                    $success = Activate-Office
                    if (-not $success) { exit 1 }
                }
                "check-status" {
                    Get-OfficeActivationStatus
                }
            }
        }
    }
    
    Write-Log "Processo de ativação concluído" "SUCCESS"
    
} catch {
    Write-Log "Erro durante o processo de ativação: $_" "ERROR"
    exit 1
}

if ($DryRun) {
    Write-Log "MODO DRY-RUN: Nenhuma alteração foi feita no sistema" "WARN"
}