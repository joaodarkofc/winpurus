#Requires -RunAsAdministrator

<#
.SYNOPSIS
    WinPurus - Módulo de Reparo do Sistema
.DESCRIPTION
    Script para reparo do sistema Windows usando ferramentas oficiais
.PARAMETER RepairType
    Tipo de reparo: sfc, dism, registry, dotnet, vcredist, all
.NOTES
    Versão: 1.0.0
    Autor: WinPurus Team
    Requer: PowerShell 5.1+ e permissões de Administrador
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("sfc", "dism", "registry", "dotnet", "vcredist", "all")]
    [string]$RepairType,
    
    [switch]$DryRun,
    [switch]$Quiet
)

# Configurações
$ErrorActionPreference = "Continue"
$LogPath = "C:\ProgramData\WinPurus\winpurus.log"
$BackupPath = "C:\ProgramData\WinPurus\Backups"

# Função de log
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] [REPAIR] $Message"
    
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

function Backup-Registry {
    try {
        Write-Log "Criando backup do registro..."
        
        if (-not (Test-Path $BackupPath)) {
            New-Item -Path $BackupPath -ItemType Directory -Force | Out-Null
        }
        
        $backupFile = Join-Path $BackupPath "registry_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"
        
        if ($DryRun) {
            Write-Log "MODO DRY-RUN: Backup seria criado em $backupFile" "WARN"
            return $true
        }
        
        # Exportar registro completo
        $result = Start-Process -FilePath "reg.exe" -ArgumentList "export", "HKLM", $backupFile, "/y" -Wait -PassThru -WindowStyle Hidden
        
        if ($result.ExitCode -eq 0) {
            Write-Log "Backup do registro criado: $backupFile" "SUCCESS"
            return $true
        } else {
            Write-Log "Erro ao criar backup do registro" "ERROR"
            return $false
        }
    } catch {
        Write-Log "Erro ao fazer backup do registro: $_" "ERROR"
        return $false
    }
}

function Repair-SFC {
    try {
        Write-Log "Iniciando verificação SFC (System File Checker)..."
        Write-Log "Esta operação pode demorar vários minutos..."
        
        if ($DryRun) {
            Write-Log "MODO DRY-RUN: SFC seria executado" "WARN"
            return $true
        }
        
        # Executar SFC /scannow
        $sfcProcess = Start-Process -FilePath "sfc.exe" -ArgumentList "/scannow" -Wait -PassThru -WindowStyle Hidden -RedirectStandardOutput "$env:TEMP\sfc_output.txt"
        
        # Ler resultado
        if (Test-Path "$env:TEMP\sfc_output.txt") {
            $sfcOutput = Get-Content "$env:TEMP\sfc_output.txt"
            $sfcOutput | ForEach-Object { Write-Log "SFC: $_" }
            Remove-Item "$env:TEMP\sfc_output.txt" -ErrorAction SilentlyContinue
        }
        
        if ($sfcProcess.ExitCode -eq 0) {
            Write-Log "SFC concluído com sucesso" "SUCCESS"
            return $true
        } else {
            Write-Log "SFC encontrou problemas ou falhou" "WARN"
            return $false
        }
    } catch {
        Write-Log "Erro ao executar SFC: $_" "ERROR"
        return $false
    }
}

function Repair-DISM {
    try {
        Write-Log "Iniciando reparo DISM (Deployment Image Servicing and Management)..."
        
        if (-not (Test-InternetConnection)) {
            Write-Log "Sem conexão com internet. DISM pode falhar ao baixar arquivos" "WARN"
        }
        
        if ($DryRun) {
            Write-Log "MODO DRY-RUN: DISM seria executado" "WARN"
            return $true
        }
        
        # DISM - Verificar integridade
        Write-Log "Executando DISM /CheckHealth..."
        $dismCheck = Start-Process -FilePath "DISM.exe" -ArgumentList "/Online", "/Cleanup-Image", "/CheckHealth" -Wait -PassThru -WindowStyle Hidden
        
        if ($dismCheck.ExitCode -eq 0) {
            Write-Log "DISM CheckHealth: OK" "SUCCESS"
        } else {
            Write-Log "DISM CheckHealth detectou problemas" "WARN"
        }
        
        # DISM - Escanear integridade
        Write-Log "Executando DISM /ScanHealth..."
        $dismScan = Start-Process -FilePath "DISM.exe" -ArgumentList "/Online", "/Cleanup-Image", "/ScanHealth" -Wait -PassThru -WindowStyle Hidden
        
        if ($dismScan.ExitCode -eq 0) {
            Write-Log "DISM ScanHealth: OK" "SUCCESS"
        } else {
            Write-Log "DISM ScanHealth detectou corrupção" "WARN"
        }
        
        # DISM - Restaurar integridade
        Write-Log "Executando DISM /RestoreHealth..."
        Write-Log "Esta operação pode demorar muito tempo..."
        $dismRestore = Start-Process -FilePath "DISM.exe" -ArgumentList "/Online", "/Cleanup-Image", "/RestoreHealth" -Wait -PassThru -WindowStyle Hidden
        
        if ($dismRestore.ExitCode -eq 0) {
            Write-Log "DISM RestoreHealth concluído com sucesso" "SUCCESS"
            return $true
        } else {
            Write-Log "DISM RestoreHealth falhou ou encontrou problemas" "ERROR"
            return $false
        }
    } catch {
        Write-Log "Erro ao executar DISM: $_" "ERROR"
        return $false
    }
}

function Repair-Registry {
    try {
        Write-Log "Iniciando reparo do registro..."
        
        # Fazer backup primeiro
        $backupSuccess = Backup-Registry
        if (-not $backupSuccess) {
            Write-Log "Falha no backup. Cancelando reparo do registro" "ERROR"
            return $false
        }
        
        if ($DryRun) {
            Write-Log "MODO DRY-RUN: Reparo do registro seria executado" "WARN"
            return $true
        }
        
        # Reparos básicos do registro
        $registryFixes = @(
            @{
                Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
                Name = "EnableLUA"
                Value = 1
                Type = "DWORD"
                Description = "Habilitar UAC"
            },
            @{
                Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
                Name = "ClearPageFileAtShutdown"
                Value = 0
                Type = "DWORD"
                Description = "Otimizar desligamento"
            },
            @{
                Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
                Name = "AutoRestartShell"
                Value = 1
                Type = "DWORD"
                Description = "Auto-restart do Explorer"
            }
        )
        
        foreach ($fix in $registryFixes) {
            try {
                Write-Log "Aplicando: $($fix.Description)"
                
                # Criar chave se não existir
                if (-not (Test-Path $fix.Path)) {
                    New-Item -Path $fix.Path -Force | Out-Null
                }
                
                # Definir valor
                Set-ItemProperty -Path $fix.Path -Name $fix.Name -Value $fix.Value -Type $fix.Type -Force
                Write-Log "Aplicado: $($fix.Description)" "SUCCESS"
            } catch {
                Write-Log "Erro ao aplicar $($fix.Description): $_" "ERROR"
            }
        }
        
        # Executar verificação de registro
        Write-Log "Executando verificação de registro..."
        $regProcess = Start-Process -FilePath "sfc.exe" -ArgumentList "/verifyonly" -Wait -PassThru -WindowStyle Hidden
        
        Write-Log "Reparo do registro concluído" "SUCCESS"
        return $true
        
    } catch {
        Write-Log "Erro ao reparar registro: $_" "ERROR"
        return $false
    }
}

function Repair-DotNet {
    try {
        Write-Log "Iniciando reparo do .NET Framework..."
        
        if ($DryRun) {
            Write-Log "MODO DRY-RUN: Reparo do .NET seria executado" "WARN"
            return $true
        }
        
        # Verificar versões instaladas do .NET
        $dotnetVersions = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP" -Recurse |
            Get-ItemProperty -Name Version -ErrorAction SilentlyContinue |
            Where-Object { $_.PSChildName -match '^(?!S)\p{L}' } |
            Select-Object PSChildName, Version
        
        Write-Log "Versões do .NET encontradas:"
        foreach ($version in $dotnetVersions) {
            Write-Log "  - $($version.PSChildName): $($version.Version)"
        }
        
        # Executar ferramenta de reparo do .NET (se disponível)
        $netfxRepairTool = "${env:ProgramFiles(x86)}\Microsoft\NetFxRepairTool\NetFxRepairTool.exe"
        
        if (Test-Path $netfxRepairTool) {
            Write-Log "Executando NetFx Repair Tool..."
            $repairProcess = Start-Process -FilePath $netfxRepairTool -ArgumentList "/q" -Wait -PassThru -WindowStyle Hidden
            
            if ($repairProcess.ExitCode -eq 0) {
                Write-Log "NetFx Repair Tool executado com sucesso" "SUCCESS"
            } else {
                Write-Log "NetFx Repair Tool retornou código: $($repairProcess.ExitCode)" "WARN"
            }
        } else {
            Write-Log "NetFx Repair Tool não encontrado. Executando limpeza manual..." "WARN"
            
            # Limpeza manual do cache .NET
            $tempAspNet = "${env:WINDIR}\Microsoft.NET\Framework\v*\Temporary ASP.NET Files"
            $tempAspNet64 = "${env:WINDIR}\Microsoft.NET\Framework64\v*\Temporary ASP.NET Files"
            
            Get-ChildItem $tempAspNet -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            Get-ChildItem $tempAspNet64 -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            
            Write-Log "Cache .NET limpo" "SUCCESS"
        }
        
        return $true
        
    } catch {
        Write-Log "Erro ao reparar .NET: $_" "ERROR"
        return $false
    }
}

function Repair-VCRedist {
    try {
        Write-Log "Iniciando reparo do Visual C++ Redistributable..."
        
        if ($DryRun) {
            Write-Log "MODO DRY-RUN: Reparo do VC++ seria executado" "WARN"
            return $true
        }
        
        # Verificar versões instaladas do VC++
        $vcVersions = Get-WmiObject -Class Win32_Product | Where-Object { 
            $_.Name -like "*Visual C++*Redistributable*" 
        } | Select-Object Name, Version
        
        Write-Log "Versões do VC++ Redistributable encontradas:"
        foreach ($version in $vcVersions) {
            Write-Log "  - $($version.Name): $($version.Version)"
        }
        
        # URLs dos redistributables mais comuns (Microsoft oficial)
        $vcRedistUrls = @{
            "2015-2022_x64" = "https://aka.ms/vs/17/release/vc_redist.x64.exe"
            "2015-2022_x86" = "https://aka.ms/vs/17/release/vc_redist.x86.exe"
        }
        
        if (Test-InternetConnection) {
            Write-Log "Baixando e instalando VC++ Redistributables mais recentes..."
            
            foreach ($redist in $vcRedistUrls.GetEnumerator()) {
                try {
                    $tempFile = Join-Path $env:TEMP "vcredist_$($redist.Key).exe"
                    
                    Write-Log "Baixando $($redist.Key)..."
                    Invoke-WebRequest -Uri $redist.Value -OutFile $tempFile -UseBasicParsing
                    
                    Write-Log "Instalando $($redist.Key)..."
                    $installProcess = Start-Process -FilePath $tempFile -ArgumentList "/quiet", "/norestart" -Wait -PassThru -WindowStyle Hidden
                    
                    if ($installProcess.ExitCode -eq 0) {
                        Write-Log "VC++ $($redist.Key) instalado com sucesso" "SUCCESS"
                    } else {
                        Write-Log "VC++ $($redist.Key) retornou código: $($installProcess.ExitCode)" "WARN"
                    }
                    
                    Remove-Item $tempFile -ErrorAction SilentlyContinue
                    
                } catch {
                    Write-Log "Erro ao instalar VC++ $($redist.Key): $_" "ERROR"
                }
            }
        } else {
            Write-Log "Sem conexão com internet. Pulando download do VC++" "WARN"
        }
        
        return $true
        
    } catch {
        Write-Log "Erro ao reparar VC++: $_" "ERROR"
        return $false
    }
}

# Verificar se é administrador
if (-not (Test-Administrator)) {
    Write-Log "Este script requer permissões de Administrador!" "ERROR"
    exit 1
}

Write-Log "Iniciando reparo do sistema: $RepairType"

# Executar reparo solicitado
$success = $true

switch ($RepairType) {
    "sfc" {
        $success = Repair-SFC
    }
    "dism" {
        $success = Repair-DISM
    }
    "registry" {
        $success = Repair-Registry
    }
    "dotnet" {
        $success = Repair-DotNet
    }
    "vcredist" {
        $success = Repair-VCRedist
    }
    "all" {
        Write-Log "Executando reparo completo do sistema..."
        
        $repairs = @(
            @{ Name = "Registry"; Function = { Repair-Registry } },
            @{ Name = "SFC"; Function = { Repair-SFC } },
            @{ Name = "DISM"; Function = { Repair-DISM } },
            @{ Name = ".NET"; Function = { Repair-DotNet } },
            @{ Name = "VC++"; Function = { Repair-VCRedist } }
        )
        
        foreach ($repair in $repairs) {
            Write-Log "Executando reparo: $($repair.Name)"
            $result = & $repair.Function
            if (-not $result) {
                Write-Log "Reparo $($repair.Name) falhou" "WARN"
                $success = $false
            }
        }
    }
}

if ($success) {
    Write-Log "Reparo '$RepairType' concluído com sucesso!" "SUCCESS"
    Write-Log "Recomenda-se reiniciar o sistema para aplicar todas as correções" "WARN"
} else {
    Write-Log "Reparo '$RepairType' concluído com alguns problemas" "WARN"
}

if ($DryRun) {
    Write-Log "MODO DRY-RUN: Nenhuma alteração foi feita no sistema" "WARN"
}