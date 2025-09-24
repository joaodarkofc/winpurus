# WinPurus - Instalação de Programas
# Instala programas usando winget e chocolatey

param(
    [Parameter(Mandatory=$false)]
    [string[]]$Programs = @(),
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("winget", "chocolatey", "auto")]
    [string]$PackageManager = "auto",
    
    [Parameter(Mandatory=$false)]
    [switch]$InstallEssentials,
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun,
    
    [Parameter(Mandatory=$false)]
    [switch]$Quiet
)

# Configuração de logs
$LogPath = "C:\ProgramData\WinPurus\winpurus.log"

# Função para logging
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] [INSTALL] $Message"
    
    if (-not $Quiet) {
        switch ($Level) {
            "ERROR" { Write-Host $logEntry -ForegroundColor Red }
            "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
            "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
            default { Write-Host $logEntry -ForegroundColor White }
        }
    }
    
    try {
        $logDir = Split-Path $LogPath -Parent
        if (-not (Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }
        Add-Content -Path $LogPath -Value $logEntry -Encoding UTF8
    } catch {
        Write-Warning "Não foi possível escrever no log: $_"
    }
}

# Verificar se está executando como administrador
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Verificar se winget está disponível
function Test-Winget {
    try {
        $null = Get-Command winget -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

# Verificar se chocolatey está disponível
function Test-Chocolatey {
    try {
        $null = Get-Command choco -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

# Instalar winget se não estiver disponível
function Install-Winget {
    Write-Log "Instalando winget..."
    
    if ($DryRun) {
        Write-Log "DRY RUN: winget seria instalado"
        return $true
    }
    
    try {
        # Baixar e instalar App Installer (que inclui winget)
        $progressPreference = 'SilentlyContinue'
        $url = "https://aka.ms/getwinget"
        $output = "$env:TEMP\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
        
        Invoke-WebRequest -Uri $url -OutFile $output
        Add-AppxPackage -Path $output
        
        Remove-Item $output -Force
        Write-Log "winget instalado com sucesso" "SUCCESS"
        return $true
        
    } catch {
        Write-Log "Erro ao instalar winget: $_" "ERROR"
        return $false
    }
}

# Instalar chocolatey se não estiver disponível
function Install-Chocolatey {
    Write-Log "Instalando chocolatey..."
    
    if ($DryRun) {
        Write-Log "DRY RUN: chocolatey seria instalado"
        return $true
    }
    
    try {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        
        Write-Log "chocolatey instalado com sucesso" "SUCCESS"
        return $true
        
    } catch {
        Write-Log "Erro ao instalar chocolatey: $_" "ERROR"
        return $false
    }
}

# Instalar programa usando winget
function Install-WithWinget {
    param([string]$ProgramId)
    
    Write-Log "Instalando $ProgramId usando winget..."
    
    if ($DryRun) {
        Write-Log "DRY RUN: winget install $ProgramId"
        return $true
    }
    
    try {
        $result = & winget install $ProgramId --accept-package-agreements --accept-source-agreements --silent
        if ($LASTEXITCODE -eq 0) {
            Write-Log "$ProgramId instalado com sucesso via winget" "SUCCESS"
            return $true
        } else {
            Write-Log "Erro ao instalar $ProgramId via winget (código: $LASTEXITCODE)" "ERROR"
            return $false
        }
    } catch {
        Write-Log "Erro ao instalar $ProgramId via winget: $_" "ERROR"
        return $false
    }
}

# Instalar programa usando chocolatey
function Install-WithChocolatey {
    param([string]$ProgramId)
    
    Write-Log "Instalando $ProgramId usando chocolatey..."
    
    if ($DryRun) {
        Write-Log "DRY RUN: choco install $ProgramId"
        return $true
    }
    
    try {
        $result = & choco install $ProgramId -y
        if ($LASTEXITCODE -eq 0) {
            Write-Log "$ProgramId instalado com sucesso via chocolatey" "SUCCESS"
            return $true
        } else {
            Write-Log "Erro ao instalar $ProgramId via chocolatey (código: $LASTEXITCODE)" "ERROR"
            return $false
        }
    } catch {
        Write-Log "Erro ao instalar $ProgramId via chocolatey: $_" "ERROR"
        return $false
    }
}

# Lista de programas essenciais
$EssentialPrograms = @{
    "winget" = @(
        "7zip.7zip",
        "Google.Chrome",
        "Mozilla.Firefox",
        "VideoLAN.VLC",
        "Adobe.Acrobat.Reader.64-bit",
        "Microsoft.VisualStudioCode",
        "Git.Git",
        "Microsoft.PowerToys",
        "WinRAR.WinRAR"
    )
    "chocolatey" = @(
        "7zip",
        "googlechrome",
        "firefox",
        "vlc",
        "adobereader",
        "vscode",
        "git",
        "powertoys",
        "winrar"
    )
}

# Função principal
function Start-ProgramInstallation {
    Write-Log "Iniciando instalação de programas"
    
    if (-not (Test-Administrator)) {
        Write-Log "Este script requer privilégios de administrador" "ERROR"
        return $false
    }
    
    if ($DryRun) {
        Write-Log "Modo DRY RUN ativado - nenhuma instalação será feita" "WARNING"
    }
    
    # Determinar gerenciador de pacotes
    $useWinget = $false
    $useChocolatey = $false
    
    if ($PackageManager -eq "winget" -or $PackageManager -eq "auto") {
        if (Test-Winget) {
            $useWinget = $true
            Write-Log "winget detectado e será usado"
        } elseif ($PackageManager -eq "winget") {
            Write-Log "winget não encontrado, tentando instalar..."
            $useWinget = Install-Winget
        }
    }
    
    if ((-not $useWinget) -and ($PackageManager -eq "chocolatey" -or $PackageManager -eq "auto")) {
        if (Test-Chocolatey) {
            $useChocolatey = $true
            Write-Log "chocolatey detectado e será usado"
        } elseif ($PackageManager -eq "chocolatey" -or $PackageManager -eq "auto") {
            Write-Log "chocolatey não encontrado, tentando instalar..."
            $useChocolatey = Install-Chocolatey
        }
    }
    
    if (-not $useWinget -and -not $useChocolatey) {
        Write-Log "Nenhum gerenciador de pacotes disponível" "ERROR"
        return $false
    }
    
    # Determinar lista de programas
    $programsToInstall = @()
    
    if ($InstallEssentials) {
        if ($useWinget) {
            $programsToInstall += $EssentialPrograms.winget
        } elseif ($useChocolatey) {
            $programsToInstall += $EssentialPrograms.chocolatey
        }
    }
    
    if ($Programs.Count -gt 0) {
        $programsToInstall += $Programs
    }
    
    if ($programsToInstall.Count -eq 0) {
        Write-Log "Nenhum programa especificado para instalação" "WARNING"
        return $true
    }
    
    # Instalar programas
    $successCount = 0
    $failCount = 0
    
    foreach ($program in $programsToInstall) {
        Write-Log "Processando: $program"
        
        $success = $false
        
        if ($useWinget) {
            $success = Install-WithWinget -ProgramId $program
        } elseif ($useChocolatey) {
            $success = Install-WithChocolatey -ProgramId $program
        }
        
        if ($success) {
            $successCount++
        } else {
            $failCount++
        }
    }
    
    # Relatório final
    Write-Log "Instalação concluída - Sucessos: $successCount, Falhas: $failCount" "SUCCESS"
    
    return $true
}

# Executar instalação
try {
    $result = Start-ProgramInstallation
    
    if (-not $Quiet) {
        Write-Host "`n=== RESUMO DA INSTALAÇÃO ===" -ForegroundColor Cyan
        Write-Host "Gerenciador usado: $PackageManager" -ForegroundColor White
        Write-Host "Programas processados: $($Programs.Count + $(if($InstallEssentials){$EssentialPrograms.winget.Count}else{0}))" -ForegroundColor White
        Write-Host "Status: $(if($result){'Concluído'}else{'Erro'})" -ForegroundColor $(if($result){'Green'}else{'Red'})
        Write-Host "==============================`n" -ForegroundColor Cyan
    }
    
} catch {
    Write-Log "Erro durante a instalação: $_" "ERROR"
    exit 1
}