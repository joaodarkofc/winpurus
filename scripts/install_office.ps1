#Requires -RunAsAdministrator

<#
.SYNOPSIS
    WinPurus - Módulo de Instalação do Office
.DESCRIPTION
    Script para download e instalação do Microsoft Office usando links fornecidos pelo usuário
.PARAMETER DownloadUrl
    URL do instalador do Office
.PARAMETER HashSHA256
    Hash SHA256 opcional para verificação de integridade
.PARAMETER InstallArgs
    Argumentos de instalação personalizados
.NOTES
    Versão: 1.0.0
    Autor: WinPurus Team
    Requer: PowerShell 5.1+ e permissões de Administrador
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$DownloadUrl,
    
    [string]$HashSHA256,
    [string]$InstallArgs = "/quiet /norestart",
    [switch]$DryRun,
    [switch]$Quiet
)

# Configurações
$ErrorActionPreference = "Continue"
$LogPath = "C:\ProgramData\WinPurus\winpurus.log"
$TempPath = "$env:TEMP\WinPurus"
$MaxDownloadSize = 5GB # Limite de 5GB para downloads

# Função de log
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] [OFFICE] $Message"
    
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

function Test-InternetConnection {
    try {
        $response = Invoke-WebRequest -Uri "https://www.microsoft.com" -Method Head -TimeoutSec 10 -UseBasicParsing
        return $response.StatusCode -eq 200
    } catch {
        return $false
    }
}

function Test-ValidUrl {
    param([string]$Url)
    
    # Verificar se é uma URL válida
    try {
        $uri = [System.Uri]$Url
        if ($uri.Scheme -notin @("http", "https")) {
            return $false
        }
        return $true
    } catch {
        return $false
    }
}

function Get-FileNameFromUrl {
    param([string]$Url)
    
    try {
        $uri = [System.Uri]$Url
        $fileName = [System.IO.Path]::GetFileName($uri.LocalPath)
        
        if ([string]::IsNullOrEmpty($fileName) -or $fileName -eq "/") {
            $fileName = "office_installer.exe"
        }
        
        # Garantir que tem extensão
        if (-not [System.IO.Path]::HasExtension($fileName)) {
            $fileName += ".exe"
        }
        
        return $fileName
    } catch {
        return "office_installer.exe"
    }
}

function Get-FileSizeFromUrl {
    param([string]$Url)
    
    try {
        $response = Invoke-WebRequest -Uri $Url -Method Head -UseBasicParsing -TimeoutSec 30
        $contentLength = $response.Headers["Content-Length"]
        
        if ($contentLength) {
            return [long]$contentLength[0]
        }
        return 0
    } catch {
        Write-Log "Não foi possível obter o tamanho do arquivo: $_" "WARN"
        return 0
    }
}

function Download-File {
    param(
        [string]$Url,
        [string]$OutputPath
    )
    
    try {
        Write-Log "Iniciando download de: $Url"
        
        # Verificar tamanho do arquivo
        $fileSize = Get-FileSizeFromUrl $Url
        if ($fileSize -gt $MaxDownloadSize) {
            throw "Arquivo muito grande ($(($fileSize/1GB).ToString('F2'))GB). Limite: $(($MaxDownloadSize/1GB))GB"
        }
        
        if ($fileSize -gt 0) {
            Write-Log "Tamanho do arquivo: $(($fileSize/1MB).ToString('F2'))MB"
        }
        
        # Download com barra de progresso
        $webClient = New-Object System.Net.WebClient
        
        # Configurar User-Agent
        $webClient.Headers.Add("User-Agent", "WinPurus/1.0")
        
        # Event handler para progresso
        $progressHandler = {
            param($sender, $e)
            if ($e.TotalBytesToReceive -gt 0) {
                $percent = [math]::Round(($e.BytesReceived / $e.TotalBytesToReceive) * 100, 1)
                $mbReceived = [math]::Round($e.BytesReceived / 1MB, 1)
                $mbTotal = [math]::Round($e.TotalBytesToReceive / 1MB, 1)
                
                if (-not $Quiet) {
                    Write-Progress -Activity "Download do Office" -Status "$percent% - $mbReceived MB de $mbTotal MB" -PercentComplete $percent
                }
            }
        }
        
        $webClient.add_DownloadProgressChanged($progressHandler)
        
        # Realizar download
        $webClient.DownloadFile($Url, $OutputPath)
        $webClient.Dispose()
        
        if (-not $Quiet) {
            Write-Progress -Activity "Download do Office" -Completed
        }
        
        Write-Log "Download concluído: $OutputPath" "SUCCESS"
        return $true
        
    } catch {
        Write-Log "Erro no download: $_" "ERROR"
        return $false
    }
}

function Test-FileHash {
    param(
        [string]$FilePath,
        [string]$ExpectedHash
    )
    
    if ([string]::IsNullOrEmpty($ExpectedHash)) {
        Write-Log "Hash não fornecido, pulando verificação" "WARN"
        return $true
    }
    
    try {
        Write-Log "Verificando integridade do arquivo..."
        $actualHash = Get-FileHash -Path $FilePath -Algorithm SHA256
        
        if ($actualHash.Hash -eq $ExpectedHash.ToUpper()) {
            Write-Log "Verificação de hash bem-sucedida" "SUCCESS"
            return $true
        } else {
            Write-Log "Hash não confere! Esperado: $ExpectedHash, Atual: $($actualHash.Hash)" "ERROR"
            return $false
        }
    } catch {
        Write-Log "Erro ao verificar hash: $_" "ERROR"
        return $false
    }
}

function Install-OfficeFile {
    param(
        [string]$FilePath,
        [string]$Arguments
    )
    
    try {
        Write-Log "Iniciando instalação do Office..."
        Write-Log "Arquivo: $FilePath"
        Write-Log "Argumentos: $Arguments"
        
        if (-not (Test-Path $FilePath)) {
            throw "Arquivo de instalação não encontrado: $FilePath"
        }
        
        # Detectar tipo de instalador
        $extension = [System.IO.Path]::GetExtension($FilePath).ToLower()
        
        switch ($extension) {
            ".exe" {
                Write-Log "Executando instalador EXE..."
                $process = Start-Process -FilePath $FilePath -ArgumentList $Arguments -Wait -PassThru -NoNewWindow
            }
            ".msi" {
                Write-Log "Executando instalador MSI..."
                $msiArgs = "/i `"$FilePath`" $Arguments"
                $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $msiArgs -Wait -PassThru -NoNewWindow
            }
            ".iso" {
                Write-Log "Montando arquivo ISO..."
                $mountResult = Mount-DiskImage -ImagePath $FilePath -PassThru
                $driveLetter = ($mountResult | Get-Volume).DriveLetter
                
                # Procurar setup.exe na ISO
                $setupPath = "${driveLetter}:\setup.exe"
                if (Test-Path $setupPath) {
                    Write-Log "Executando setup da ISO..."
                    $process = Start-Process -FilePath $setupPath -ArgumentList $Arguments -Wait -PassThru -NoNewWindow
                } else {
                    throw "Setup.exe não encontrado na ISO"
                }
                
                # Desmontar ISO
                Dismount-DiskImage -ImagePath $FilePath
            }
            default {
                throw "Tipo de arquivo não suportado: $extension"
            }
        }
        
        if ($process.ExitCode -eq 0) {
            Write-Log "Instalação do Office concluída com sucesso!" "SUCCESS"
            return $true
        } else {
            Write-Log "Instalação falhou com código de saída: $($process.ExitCode)" "ERROR"
            return $false
        }
        
    } catch {
        Write-Log "Erro durante a instalação: $_" "ERROR"
        return $false
    }
}

function Test-OfficeInstallation {
    Write-Log "Verificando instalação do Office..."
    
    # Verificar se o Office está instalado
    $officeApps = @(
        "Microsoft Office",
        "Microsoft 365",
        "Office 16",
        "Office 19",
        "Office 21"
    )
    
    $installedOffice = Get-WmiObject -Class Win32_Product | Where-Object { 
        $app = $_
        $officeApps | Where-Object { $app.Name -like "*$_*" }
    }
    
    if ($installedOffice) {
        Write-Log "Office detectado:" "SUCCESS"
        foreach ($app in $installedOffice) {
            Write-Log "  - $($app.Name) (Versão: $($app.Version))" "SUCCESS"
        }
        return $true
    } else {
        Write-Log "Office não detectado no sistema" "WARN"
        return $false
    }
}

function Cleanup-TempFiles {
    param([string]$TempDir)
    
    try {
        if (Test-Path $TempDir) {
            Write-Log "Limpando arquivos temporários..."
            Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
            Write-Log "Arquivos temporários removidos" "SUCCESS"
        }
    } catch {
        Write-Log "Erro ao limpar arquivos temporários: $_" "WARN"
    }
}

# Verificações iniciais
if (-not (Test-Administrator)) {
    Write-Log "Este script requer permissões de Administrador!" "ERROR"
    exit 1
}

if (-not (Test-InternetConnection)) {
    Write-Log "Sem conexão com a internet!" "ERROR"
    exit 1
}

if (-not (Test-ValidUrl $DownloadUrl)) {
    Write-Log "URL inválida: $DownloadUrl" "ERROR"
    exit 1
}

# Criar diretório temporário
if (-not (Test-Path $TempPath)) {
    New-Item -Path $TempPath -ItemType Directory -Force | Out-Null
}

Write-Log "Iniciando instalação do Office via URL fornecida"
Write-Log "URL: $DownloadUrl"

try {
    # Obter nome do arquivo
    $fileName = Get-FileNameFromUrl $DownloadUrl
    $downloadPath = Join-Path $TempPath $fileName
    
    Write-Log "Arquivo de destino: $downloadPath"
    
    if ($DryRun) {
        Write-Log "MODO DRY-RUN: Simulando download e instalação" "WARN"
        Write-Log "Arquivo seria baixado para: $downloadPath"
        Write-Log "Hash seria verificado: $HashSHA256"
        Write-Log "Argumentos de instalação: $InstallArgs"
        exit 0
    }
    
    # Download do arquivo
    $downloadSuccess = Download-File -Url $DownloadUrl -OutputPath $downloadPath
    
    if (-not $downloadSuccess) {
        throw "Falha no download do arquivo"
    }
    
    # Verificar hash se fornecido
    if (-not [string]::IsNullOrEmpty($HashSHA256)) {
        $hashValid = Test-FileHash -FilePath $downloadPath -ExpectedHash $HashSHA256
        if (-not $hashValid) {
            throw "Verificação de integridade falhou"
        }
    }
    
    # Instalar Office
    $installSuccess = Install-OfficeFile -FilePath $downloadPath -Arguments $InstallArgs
    
    if ($installSuccess) {
        # Verificar se a instalação foi bem-sucedida
        Start-Sleep -Seconds 5
        Test-OfficeInstallation
        
        Write-Log "Processo de instalação do Office concluído!" "SUCCESS"
    } else {
        throw "Falha na instalação do Office"
    }
    
} catch {
    Write-Log "Erro durante o processo: $_" "ERROR"
    exit 1
} finally {
    # Limpar arquivos temporários
    Cleanup-TempFiles $TempPath
}

Write-Log "Script de instalação do Office finalizado" "SUCCESS"