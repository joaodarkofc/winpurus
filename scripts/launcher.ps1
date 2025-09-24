#Requires -RunAsAdministrator

<#
.SYNOPSIS
    WinPurus Launcher - Script de instalação via IRM
.DESCRIPTION
    Este script baixa e instala o WinPurus no sistema.
    Uso: irm "https://winpurus.cc/irm" | iex
.NOTES
    Versão: 1.0.0
    Autor: WinPurus Team
    Requer: PowerShell 5.1+ e permissões de Administrador
#>

param(
    [switch]$Force,
    [switch]$Quiet,
    [string]$InstallPath = "$env:ProgramFiles\WinPurus"
)

# Configurações
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# URLs e configurações (ajustar para URLs reais)
$GitHubRepo = "winpurus/winpurus"
$DownloadUrl = "https://github.com/$GitHubRepo/archive/refs/heads/main.zip"
$TempPath = "$env:TEMP\WinPurus"
$LogPath = "C:\ProgramData\WinPurus"
$LogFile = "$LogPath\install.log"

# Cores para output
$Colors = @{
    Success = "Green"
    Warning = "Yellow"
    Error = "Red"
    Info = "Cyan"
    Header = "Magenta"
}

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White",
        [switch]$NoNewline
    )
    
    if (-not $Quiet) {
        if ($NoNewline) {
            Write-Host $Message -ForegroundColor $Color -NoNewline
        } else {
            Write-Host $Message -ForegroundColor $Color
        }
    }
}

function Write-Log {
    param([string]$Message)
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] $Message"
    
    try {
        if (-not (Test-Path $LogPath)) {
            New-Item -Path $LogPath -ItemType Directory -Force | Out-Null
        }
        Add-Content -Path $LogFile -Value $logEntry -Encoding UTF8
    } catch {
        Write-Warning "Não foi possível escrever no log: $_"
    }
}

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Show-Header {
    Clear-Host
    Write-ColorOutput @"
╔══════════════════════════════════════════════════════════════╗
║                         WinPurus                             ║
║              Manutenção e Otimização do Windows              ║
║                                                              ║
║  🚀 Instalador Automático via PowerShell                    ║
╚══════════════════════════════════════════════════════════════╝
"@ -Color $Colors.Header
    Write-ColorOutput ""
}

function Test-Prerequisites {
    Write-ColorOutput "🔍 Verificando pré-requisitos..." -Color $Colors.Info
    
    # Verificar se é administrador
    if (-not (Test-Administrator)) {
        Write-ColorOutput "❌ Este script requer permissões de Administrador!" -Color $Colors.Error
        Write-ColorOutput "   Execute o PowerShell como Administrador e tente novamente." -Color $Colors.Warning
        Write-Log "ERRO: Script executado sem permissões de administrador"
        exit 1
    }
    
    # Verificar versão do PowerShell
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Write-ColorOutput "❌ PowerShell 5.1 ou superior é necessário!" -Color $Colors.Error
        Write-ColorOutput "   Versão atual: $($PSVersionTable.PSVersion)" -Color $Colors.Warning
        Write-Log "ERRO: Versão do PowerShell incompatível: $($PSVersionTable.PSVersion)"
        exit 1
    }
    
    # Verificar conexão com internet
    try {
        $null = Invoke-WebRequest -Uri "https://www.google.com" -UseBasicParsing -TimeoutSec 10
    } catch {
        Write-ColorOutput "❌ Sem conexão com a internet!" -Color $Colors.Error
        Write-Log "ERRO: Sem conexão com internet"
        exit 1
    }
    
    Write-ColorOutput "✅ Pré-requisitos verificados com sucesso!" -Color $Colors.Success
    Write-Log "Pré-requisitos verificados com sucesso"
}

function Install-Dependencies {
    Write-ColorOutput "📦 Verificando dependências..." -Color $Colors.Info
    
    # Verificar se Node.js está instalado (para Electron)
    try {
        $nodeVersion = node --version 2>$null
        if ($nodeVersion) {
            Write-ColorOutput "✅ Node.js encontrado: $nodeVersion" -Color $Colors.Success
        }
    } catch {
        Write-ColorOutput "⚠️  Node.js não encontrado. Será necessário para executar a GUI." -Color $Colors.Warning
        Write-ColorOutput "   Você pode baixar em: https://nodejs.org" -Color $Colors.Info
    }
    
    # Verificar .NET Framework
    try {
        $dotnetVersion = Get-ItemProperty "HKLM:SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\" -Name Release -ErrorAction SilentlyContinue
        if ($dotnetVersion.Release -ge 461808) {
            Write-ColorOutput "✅ .NET Framework 4.7.2+ encontrado" -Color $Colors.Success
        } else {
            Write-ColorOutput "⚠️  .NET Framework 4.7.2+ recomendado" -Color $Colors.Warning
        }
    } catch {
        Write-ColorOutput "⚠️  Não foi possível verificar .NET Framework" -Color $Colors.Warning
    }
    
    Write-Log "Verificação de dependências concluída"
}

function Download-WinPurus {
    Write-ColorOutput "⬇️  Baixando WinPurus..." -Color $Colors.Info
    
    try {
        # Criar diretório temporário
        if (Test-Path $TempPath) {
            Remove-Item $TempPath -Recurse -Force
        }
        New-Item -Path $TempPath -ItemType Directory -Force | Out-Null
        
        # Baixar arquivo
        $zipFile = "$TempPath\winpurus.zip"
        Write-ColorOutput "   Baixando de: $DownloadUrl" -Color $Colors.Info
        
        Invoke-WebRequest -Uri $DownloadUrl -OutFile $zipFile -UseBasicParsing
        
        # Extrair arquivo
        Write-ColorOutput "📂 Extraindo arquivos..." -Color $Colors.Info
        Expand-Archive -Path $zipFile -DestinationPath $TempPath -Force
        
        Write-ColorOutput "✅ Download concluído!" -Color $Colors.Success
        Write-Log "Download e extração concluídos com sucesso"
        
    } catch {
        Write-ColorOutput "❌ Erro no download: $_" -Color $Colors.Error
        Write-Log "ERRO no download: $_"
        exit 1
    }
}

function Install-WinPurus {
    Write-ColorOutput "🔧 Instalando WinPurus..." -Color $Colors.Info
    
    try {
        # Criar diretório de instalação
        if (Test-Path $InstallPath) {
            if ($Force) {
                Write-ColorOutput "   Removendo instalação anterior..." -Color $Colors.Warning
                Remove-Item $InstallPath -Recurse -Force
            } else {
                Write-ColorOutput "❌ WinPurus já está instalado em: $InstallPath" -Color $Colors.Error
                Write-ColorOutput "   Use -Force para sobrescrever" -Color $Colors.Warning
                Write-Log "ERRO: Instalação já existe e -Force não foi especificado"
                exit 1
            }
        }
        
        New-Item -Path $InstallPath -ItemType Directory -Force | Out-Null
        
        # Copiar arquivos
        $sourceFolder = Get-ChildItem $TempPath -Directory | Select-Object -First 1
        Copy-Item "$($sourceFolder.FullName)\*" -Destination $InstallPath -Recurse -Force
        
        # Criar atalho na área de trabalho
        $desktopPath = [Environment]::GetFolderPath("Desktop")
        $shortcutPath = "$desktopPath\WinPurus.lnk"
        
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = "powershell.exe"
        $shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$InstallPath\scripts\launcher.ps1`""
        $shortcut.WorkingDirectory = $InstallPath
        $shortcut.IconLocation = "$InstallPath\gui\assets\icon.ico"
        $shortcut.Description = "WinPurus - Manutenção e Otimização do Windows"
        $shortcut.Save()
        
        # Criar entrada no menu iniciar
        $startMenuPath = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs"
        $startMenuShortcut = "$startMenuPath\WinPurus.lnk"
        Copy-Item $shortcutPath $startMenuShortcut -Force
        
        Write-ColorOutput "✅ Instalação concluída!" -Color $Colors.Success
        Write-ColorOutput "   Localização: $InstallPath" -Color $Colors.Info
        Write-Log "Instalação concluída em: $InstallPath"
        
    } catch {
        Write-ColorOutput "❌ Erro na instalação: $_" -Color $Colors.Error
        Write-Log "ERRO na instalação: $_"
        exit 1
    }
}

function Set-ExecutionPolicyIfNeeded {
    Write-ColorOutput "🔒 Verificando política de execução..." -Color $Colors.Info
    
    $currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
    if ($currentPolicy -eq "Restricted") {
        try {
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
            Write-ColorOutput "✅ Política de execução configurada" -Color $Colors.Success
            Write-Log "Política de execução alterada para RemoteSigned"
        } catch {
            Write-ColorOutput "⚠️  Não foi possível alterar a política de execução" -Color $Colors.Warning
            Write-Log "AVISO: Não foi possível alterar política de execução"
        }
    } else {
        Write-ColorOutput "✅ Política de execução adequada: $currentPolicy" -Color $Colors.Success
    }
}

function Show-CompletionMessage {
    Write-ColorOutput ""
    Write-ColorOutput "🎉 WinPurus instalado com sucesso!" -Color $Colors.Success
    Write-ColorOutput ""
    Write-ColorOutput "📍 Localização: $InstallPath" -Color $Colors.Info
    Write-ColorOutput "🖥️  Atalho criado na área de trabalho" -Color $Colors.Info
    Write-ColorOutput "📋 Atalho criado no menu iniciar" -Color $Colors.Info
    Write-ColorOutput ""
    Write-ColorOutput "🚀 Para executar:" -Color $Colors.Header
    Write-ColorOutput "   • Clique no atalho da área de trabalho" -Color $Colors.Info
    Write-ColorOutput "   • Ou execute: cd '$InstallPath' && npm start" -Color $Colors.Info
    Write-ColorOutput ""
    Write-ColorOutput "⚠️  IMPORTANTE: Use apenas com licenças legítimas!" -Color $Colors.Warning
    Write-ColorOutput ""
    
    Write-Log "Instalação concluída com sucesso"
}

function Cleanup {
    Write-ColorOutput "🧹 Limpando arquivos temporários..." -Color $Colors.Info
    
    try {
        if (Test-Path $TempPath) {
            Remove-Item $TempPath -Recurse -Force
        }
        Write-ColorOutput "✅ Limpeza concluída!" -Color $Colors.Success
    } catch {
        Write-ColorOutput "⚠️  Erro na limpeza: $_" -Color $Colors.Warning
    }
}

# Função principal
function Main {
    try {
        Show-Header
        Test-Prerequisites
        Install-Dependencies
        Set-ExecutionPolicyIfNeeded
        Download-WinPurus
        Install-WinPurus
        Cleanup
        Show-CompletionMessage
        
        if (-not $Quiet) {
            Write-ColorOutput "Pressione qualquer tecla para continuar..." -Color $Colors.Info
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
    } catch {
        Write-ColorOutput "❌ Erro fatal: $_" -Color $Colors.Error
        Write-Log "ERRO FATAL: $_"
        exit 1
    }
}

# Executar instalação
Main