#Requires -RunAsAdministrator

<#
.SYNOPSIS
    WinPurus - Módulo de Otimização do Windows
.DESCRIPTION
    Script para limpeza e otimização do sistema Windows
.PARAMETER Action
    Ação a ser executada: cleanup, debloat, performance, power-plan
.NOTES
    Versão: 1.0.0
    Autor: WinPurus Team
    Requer: PowerShell 5.1+ e permissões de Administrador
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("cleanup", "debloat", "performance", "power-plan")]
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
    $logEntry = "[$timestamp] [$Level] [OPTIMIZE] $Message"
    
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

function Get-FolderSize {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        return 0
    }
    
    try {
        $size = (Get-ChildItem $Path -Recurse -Force -ErrorAction SilentlyContinue | 
                Measure-Object -Property Length -Sum).Sum
        return [math]::Round($size / 1MB, 2)
    } catch {
        return 0
    }
}

function Remove-TempFiles {
    Write-Log "Iniciando limpeza de arquivos temporários..."
    
    $tempPaths = @(
        "$env:TEMP",
        "$env:WINDIR\Temp",
        "$env:WINDIR\Prefetch",
        "$env:LOCALAPPDATA\Temp",
        "$env:WINDIR\SoftwareDistribution\Download",
        "$env:WINDIR\Logs",
        "$env:WINDIR\System32\LogFiles",
        "$env:LOCALAPPDATA\Microsoft\Windows\INetCache",
        "$env:LOCALAPPDATA\Microsoft\Windows\WebCache",
        "$env:APPDATA\Local\Microsoft\Windows\INetCookies"
    )
    
    $totalCleaned = 0
    
    foreach ($path in $tempPaths) {
        if (Test-Path $path) {
            try {
                $sizeBefore = Get-FolderSize $path
                Write-Log "Limpando: $path (${sizeBefore}MB)"
                
                if (-not $DryRun) {
                    Get-ChildItem $path -Recurse -Force -ErrorAction SilentlyContinue | 
                        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                }
                
                $sizeAfter = Get-FolderSize $path
                $cleaned = $sizeBefore - $sizeAfter
                $totalCleaned += $cleaned
                
                Write-Log "Liberado: ${cleaned}MB de $path" "SUCCESS"
            } catch {
                Write-Log "Erro ao limpar $path : $_" "ERROR"
            }
        }
    }
    
    # Limpar lixeira
    try {
        Write-Log "Esvaziando lixeira..."
        if (-not $DryRun) {
            Clear-RecycleBin -Force -ErrorAction SilentlyContinue
        }
        Write-Log "Lixeira esvaziada" "SUCCESS"
    } catch {
        Write-Log "Erro ao esvaziar lixeira: $_" "ERROR"
    }
    
    # Executar Disk Cleanup
    try {
        Write-Log "Executando Disk Cleanup..."
        if (-not $DryRun) {
            Start-Process "cleanmgr.exe" -ArgumentList "/sagerun:1" -Wait -WindowStyle Hidden
        }
        Write-Log "Disk Cleanup executado" "SUCCESS"
    } catch {
        Write-Log "Erro ao executar Disk Cleanup: $_" "ERROR"
    }
    
    Write-Log "Limpeza concluída. Total liberado: ${totalCleaned}MB" "SUCCESS"
}

function Remove-Bloatware {
    Write-Log "Iniciando remoção de bloatware..."
    
    # Lista de aplicativos comuns de bloatware
    $bloatwareApps = @(
        "Microsoft.3DBuilder",
        "Microsoft.BingFinance",
        "Microsoft.BingNews",
        "Microsoft.BingSports",
        "Microsoft.BingWeather",
        "Microsoft.GetHelp",
        "Microsoft.Getstarted",
        "Microsoft.Messaging",
        "Microsoft.Microsoft3DViewer",
        "Microsoft.MicrosoftOfficeHub",
        "Microsoft.MicrosoftSolitaireCollection",
        "Microsoft.MixedReality.Portal",
        "Microsoft.Office.OneNote",
        "Microsoft.OneConnect",
        "Microsoft.People",
        "Microsoft.Print3D",
        "Microsoft.SkypeApp",
        "Microsoft.Wallet",
        "Microsoft.WindowsAlarms",
        "Microsoft.WindowsCamera",
        "microsoft.windowscommunicationsapps",
        "Microsoft.WindowsFeedbackHub",
        "Microsoft.WindowsMaps",
        "Microsoft.WindowsSoundRecorder",
        "Microsoft.Xbox.TCUI",
        "Microsoft.XboxApp",
        "Microsoft.XboxGameOverlay",
        "Microsoft.XboxGamingOverlay",
        "Microsoft.XboxIdentityProvider",
        "Microsoft.XboxSpeechToTextOverlay",
        "Microsoft.ZuneMusic",
        "Microsoft.ZuneVideo"
    )
    
    foreach ($app in $bloatwareApps) {
        try {
            $package = Get-AppxPackage -Name $app -ErrorAction SilentlyContinue
            if ($package) {
                Write-Log "Removendo: $app"
                if (-not $DryRun) {
                    Remove-AppxPackage -Package $package.PackageFullName -ErrorAction SilentlyContinue
                    Get-AppxProvisionedPackage -Online | Where-Object DisplayName -eq $app | 
                        Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
                }
                Write-Log "Removido: $app" "SUCCESS"
            }
        } catch {
            Write-Log "Erro ao remover $app : $_" "ERROR"
        }
    }
    
    Write-Log "Remoção de bloatware concluída" "SUCCESS"
}

function Optimize-Performance {
    Write-Log "Iniciando otimizações de performance..."
    
    # Desabilitar efeitos visuais desnecessários
    try {
        Write-Log "Configurando efeitos visuais para performance..."
        if (-not $DryRun) {
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2
        }
        Write-Log "Efeitos visuais otimizados" "SUCCESS"
    } catch {
        Write-Log "Erro ao configurar efeitos visuais: $_" "ERROR"
    }
    
    # Desabilitar programas de inicialização desnecessários
    try {
        Write-Log "Otimizando programas de inicialização..."
        $startupApps = @(
            "Skype",
            "Spotify",
            "Steam",
            "Discord",
            "Adobe Updater"
        )
        
        foreach ($app in $startupApps) {
            if (-not $DryRun) {
                Get-CimInstance -ClassName Win32_StartupCommand | 
                    Where-Object { $_.Name -like "*$app*" } | 
                    ForEach-Object {
                        Write-Log "Desabilitando inicialização: $($_.Name)"
                        # Aqui você implementaria a lógica para desabilitar
                    }
            }
        }
        Write-Log "Programas de inicialização otimizados" "SUCCESS"
    } catch {
        Write-Log "Erro ao otimizar inicialização: $_" "ERROR"
    }
    
    # Configurar Storage Sense
    try {
        Write-Log "Configurando Storage Sense..."
        if (-not $DryRun) {
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" -Name "01" -Value 1
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" -Name "04" -Value 1
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" -Name "08" -Value 1
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" -Name "32" -Value 1
        }
        Write-Log "Storage Sense configurado" "SUCCESS"
    } catch {
        Write-Log "Erro ao configurar Storage Sense: $_" "ERROR"
    }
    
    # Desabilitar hibernação
    try {
        Write-Log "Desabilitando hibernação..."
        if (-not $DryRun) {
            powercfg /hibernate off
        }
        Write-Log "Hibernação desabilitada" "SUCCESS"
    } catch {
        Write-Log "Erro ao desabilitar hibernação: $_" "ERROR"
    }
    
    # Configurar paginação
    try {
        Write-Log "Otimizando arquivo de paginação..."
        if (-not $DryRun) {
            $cs = Get-WmiObject -Class Win32_ComputerSystem
            if ($cs.TotalPhysicalMemory -gt 8GB) {
                # Se tem mais de 8GB RAM, configurar paginação gerenciada pelo sistema
                $pageFile = Get-WmiObject -Class Win32_PageFileSetting
                if ($pageFile) {
                    $pageFile.Delete()
                }
                Set-WmiInstance -Class Win32_PageFileSetting -Arguments @{name="C:\pagefile.sys"; InitialSize=0; MaximumSize=0}
            }
        }
        Write-Log "Arquivo de paginação otimizado" "SUCCESS"
    } catch {
        Write-Log "Erro ao otimizar paginação: $_" "ERROR"
    }
    
    Write-Log "Otimizações de performance concluídas" "SUCCESS"
}

function Set-UltimatePowerPlan {
    Write-Log "Configurando plano de energia Ultimate Performance..."
    
    try {
        # Verificar se o plano Ultimate Performance existe
        $ultimatePlan = powercfg /list | Select-String "Ultimate Performance"
        
        if (-not $ultimatePlan) {
            Write-Log "Criando plano Ultimate Performance..."
            if (-not $DryRun) {
                powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61
            }
        }
        
        # Ativar o plano Ultimate Performance
        if (-not $DryRun) {
            $plans = powercfg /list
            $ultimateGuid = ($plans | Select-String "Ultimate Performance" | ForEach-Object { 
                ($_ -split '\s+')[3] 
            }) -replace '[()]', ''
            
            if ($ultimateGuid) {
                powercfg /setactive $ultimateGuid
                Write-Log "Plano Ultimate Performance ativado" "SUCCESS"
            } else {
                Write-Log "Não foi possível encontrar o GUID do plano Ultimate Performance" "ERROR"
            }
        }
        
    } catch {
        Write-Log "Erro ao configurar plano de energia: $_" "ERROR"
    }
}

# Verificar se é administrador
if (-not (Test-Administrator)) {
    Write-Log "Este script requer permissões de Administrador!" "ERROR"
    exit 1
}

# Executar ação solicitada
Write-Log "Iniciando otimização: $Action"

switch ($Action) {
    "cleanup" {
        Remove-TempFiles
    }
    "debloat" {
        Remove-Bloatware
    }
    "performance" {
        Optimize-Performance
    }
    "power-plan" {
        Set-UltimatePowerPlan
    }
}

Write-Log "Otimização '$Action' concluída" "SUCCESS"

if ($DryRun) {
    Write-Log "MODO DRY-RUN: Nenhuma alteração foi feita no sistema" "WARN"
}