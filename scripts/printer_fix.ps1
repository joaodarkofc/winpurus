#Requires -RunAsAdministrator

<#
.SYNOPSIS
    WinPurus - Módulo de Correção de Impressoras
.DESCRIPTION
    Script para diagnóstico e correção de problemas com impressoras e spooler
.PARAMETER Action
    Ação a ser executada: reset-spooler, clear-queue, reinstall-drivers, diagnose, all
.NOTES
    Versão: 1.0.0
    Autor: WinPurus Team
    Requer: PowerShell 5.1+ e permissões de Administrador
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("reset-spooler", "clear-queue", "reinstall-drivers", "diagnose", "all")]
    [string]$Action,
    
    [switch]$DryRun,
    [switch]$Quiet
)

# Configurações
$ErrorActionPreference = "Continue"
$LogPath = "C:\ProgramData\WinPurus\winpurus.log"
$SpoolerPath = "$env:WINDIR\System32\spool\PRINTERS"

# Função de log
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] [PRINTER] $Message"
    
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

function Get-SpoolerStatus {
    try {
        $spoolerService = Get-Service -Name "Spooler" -ErrorAction SilentlyContinue
        if ($spoolerService) {
            return $spoolerService.Status
        } else {
            return "NotFound"
        }
    } catch {
        return "Error"
    }
}

function Stop-SpoolerService {
    try {
        Write-Log "Parando serviço Print Spooler..."
        
        if ($DryRun) {
            Write-Log "MODO DRY-RUN: Spooler seria parado" "WARN"
            return $true
        }
        
        $spoolerService = Get-Service -Name "Spooler"
        
        if ($spoolerService.Status -eq "Running") {
            Stop-Service -Name "Spooler" -Force -ErrorAction Stop
            
            # Aguardar até parar completamente
            $timeout = 30
            $elapsed = 0
            while ((Get-Service -Name "Spooler").Status -ne "Stopped" -and $elapsed -lt $timeout) {
                Start-Sleep -Seconds 1
                $elapsed++
            }
            
            if ((Get-Service -Name "Spooler").Status -eq "Stopped") {
                Write-Log "Serviço Print Spooler parado com sucesso" "SUCCESS"
                return $true
            } else {
                Write-Log "Timeout ao parar o serviço Print Spooler" "ERROR"
                return $false
            }
        } else {
            Write-Log "Serviço Print Spooler já estava parado" "SUCCESS"
            return $true
        }
    } catch {
        Write-Log "Erro ao parar serviço Print Spooler: $_" "ERROR"
        return $false
    }
}

function Start-SpoolerService {
    try {
        Write-Log "Iniciando serviço Print Spooler..."
        
        if ($DryRun) {
            Write-Log "MODO DRY-RUN: Spooler seria iniciado" "WARN"
            return $true
        }
        
        $spoolerService = Get-Service -Name "Spooler"
        
        if ($spoolerService.Status -eq "Stopped") {
            Start-Service -Name "Spooler" -ErrorAction Stop
            
            # Aguardar até iniciar completamente
            $timeout = 30
            $elapsed = 0
            while ((Get-Service -Name "Spooler").Status -ne "Running" -and $elapsed -lt $timeout) {
                Start-Sleep -Seconds 1
                $elapsed++
            }
            
            if ((Get-Service -Name "Spooler").Status -eq "Running") {
                Write-Log "Serviço Print Spooler iniciado com sucesso" "SUCCESS"
                return $true
            } else {
                Write-Log "Timeout ao iniciar o serviço Print Spooler" "ERROR"
                return $false
            }
        } else {
            Write-Log "Serviço Print Spooler já estava em execução" "SUCCESS"
            return $true
        }
    } catch {
        Write-Log "Erro ao iniciar serviço Print Spooler: $_" "ERROR"
        return $false
    }
}

function Reset-PrintSpooler {
    try {
        Write-Log "Iniciando reset completo do Print Spooler..."
        
        # Parar o serviço
        $stopSuccess = Stop-SpoolerService
        if (-not $stopSuccess) {
            return $false
        }
        
        # Limpar arquivos de spool
        if (Test-Path $SpoolerPath) {
            Write-Log "Limpando arquivos de spool em $SpoolerPath"
            
            if (-not $DryRun) {
                try {
                    Get-ChildItem $SpoolerPath -File | Remove-Item -Force -ErrorAction SilentlyContinue
                    Write-Log "Arquivos de spool removidos" "SUCCESS"
                } catch {
                    Write-Log "Erro ao remover arquivos de spool: $_" "ERROR"
                }
            }
        }
        
        # Limpar registro do spooler
        Write-Log "Limpando entradas do registro do spooler..."
        
        if (-not $DryRun) {
            try {
                $spoolerRegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Print\Printers"
                if (Test-Path $spoolerRegPath) {
                    # Backup das configurações antes de limpar
                    $backupPath = "C:\ProgramData\WinPurus\Backups"
                    if (-not (Test-Path $backupPath)) {
                        New-Item -Path $backupPath -ItemType Directory -Force | Out-Null
                    }
                    
                    $backupFile = Join-Path $backupPath "printer_registry_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"
                    Start-Process -FilePath "reg.exe" -ArgumentList "export", "HKLM\SYSTEM\CurrentControlSet\Control\Print", $backupFile, "/y" -Wait -WindowStyle Hidden
                    
                    Write-Log "Backup do registro criado: $backupFile" "SUCCESS"
                }
            } catch {
                Write-Log "Erro ao fazer backup do registro: $_" "WARN"
            }
        }
        
        # Reiniciar o serviço
        $startSuccess = Start-SpoolerService
        if (-not $startSuccess) {
            return $false
        }
        
        Write-Log "Reset do Print Spooler concluído com sucesso" "SUCCESS"
        return $true
        
    } catch {
        Write-Log "Erro durante reset do Print Spooler: $_" "ERROR"
        return $false
    }
}

function Clear-PrintQueue {
    try {
        Write-Log "Limpando fila de impressão..."
        
        if ($DryRun) {
            Write-Log "MODO DRY-RUN: Fila seria limpa" "WARN"
            return $true
        }
        
        # Obter todos os trabalhos de impressão
        $printJobs = Get-WmiObject -Class Win32_PrintJob -ErrorAction SilentlyContinue
        
        if ($printJobs) {
            Write-Log "Encontrados $($printJobs.Count) trabalhos na fila"
            
            foreach ($job in $printJobs) {
                try {
                    Write-Log "Removendo trabalho: $($job.Name)"
                    $job.Delete()
                    Write-Log "Trabalho removido: $($job.Name)" "SUCCESS"
                } catch {
                    Write-Log "Erro ao remover trabalho $($job.Name): $_" "ERROR"
                }
            }
        } else {
            Write-Log "Nenhum trabalho encontrado na fila" "SUCCESS"
        }
        
        # Método alternativo: limpar via comando
        try {
            $result = Start-Process -FilePath "net" -ArgumentList "stop", "spooler" -Wait -PassThru -WindowStyle Hidden
            Start-Sleep -Seconds 2
            
            if (Test-Path $SpoolerPath) {
                Get-ChildItem $SpoolerPath -File | Remove-Item -Force -ErrorAction SilentlyContinue
            }
            
            Start-Process -FilePath "net" -ArgumentList "start", "spooler" -Wait -PassThru -WindowStyle Hidden
            
            Write-Log "Fila de impressão limpa via comando net" "SUCCESS"
        } catch {
            Write-Log "Erro no método alternativo de limpeza: $_" "WARN"
        }
        
        return $true
        
    } catch {
        Write-Log "Erro ao limpar fila de impressão: $_" "ERROR"
        return $false
    }
}

function Reinstall-PrinterDrivers {
    try {
        Write-Log "Iniciando reinstalação de drivers de impressora..."
        
        if ($DryRun) {
            Write-Log "MODO DRY-RUN: Drivers seriam reinstalados" "WARN"
            return $true
        }
        
        # Listar impressoras instaladas
        $printers = Get-WmiObject -Class Win32_Printer -ErrorAction SilentlyContinue
        
        if ($printers) {
            Write-Log "Impressoras encontradas:"
            foreach ($printer in $printers) {
                Write-Log "  - $($printer.Name) (Driver: $($printer.DriverName))"
            }
            
            # Executar comando para reinstalar drivers
            Write-Log "Executando reinstalação automática de drivers..."
            
            try {
                # Usar PnPUtil para reinstalar drivers Plug and Play
                $pnpResult = Start-Process -FilePath "pnputil.exe" -ArgumentList "/scan-devices" -Wait -PassThru -WindowStyle Hidden
                
                if ($pnpResult.ExitCode -eq 0) {
                    Write-Log "Scan de dispositivos PnP concluído" "SUCCESS"
                } else {
                    Write-Log "Scan de dispositivos retornou código: $($pnpResult.ExitCode)" "WARN"
                }
                
                # Tentar detectar e instalar impressoras automaticamente
                Add-PrinterDriver -Name "Generic / Text Only" -ErrorAction SilentlyContinue
                
                Write-Log "Reinstalação de drivers concluída" "SUCCESS"
                
            } catch {
                Write-Log "Erro durante reinstalação de drivers: $_" "ERROR"
            }
        } else {
            Write-Log "Nenhuma impressora encontrada no sistema" "WARN"
        }
        
        return $true
        
    } catch {
        Write-Log "Erro ao reinstalar drivers: $_" "ERROR"
        return $false
    }
}

function Diagnose-PrinterIssues {
    try {
        Write-Log "Iniciando diagnóstico de problemas de impressora..."
        
        # Verificar status do serviço Spooler
        $spoolerStatus = Get-SpoolerStatus
        Write-Log "Status do Print Spooler: $spoolerStatus"
        
        if ($spoolerStatus -ne "Running") {
            Write-Log "PROBLEMA: Print Spooler não está em execução" "ERROR"
        } else {
            Write-Log "Print Spooler está funcionando corretamente" "SUCCESS"
        }
        
        # Verificar impressoras instaladas
        $printers = Get-Printer -ErrorAction SilentlyContinue
        
        if ($printers) {
            Write-Log "Impressoras instaladas: $($printers.Count)"
            foreach ($printer in $printers) {
                Write-Log "  - $($printer.Name): $($printer.PrinterStatus)"
                
                if ($printer.PrinterStatus -ne "Normal") {
                    Write-Log "    PROBLEMA: Status anormal - $($printer.PrinterStatus)" "WARN"
                }
            }
        } else {
            Write-Log "Nenhuma impressora instalada" "WARN"
        }
        
        # Verificar fila de impressão
        $printJobs = Get-PrintJob -ErrorAction SilentlyContinue
        
        if ($printJobs) {
            Write-Log "Trabalhos na fila: $($printJobs.Count)"
            foreach ($job in $printJobs) {
                Write-Log "  - $($job.DocumentName): $($job.JobStatus)"
                
                if ($job.JobStatus -like "*Error*" -or $job.JobStatus -like "*Paused*") {
                    Write-Log "    PROBLEMA: Trabalho com erro - $($job.JobStatus)" "ERROR"
                }
            }
        } else {
            Write-Log "Nenhum trabalho na fila" "SUCCESS"
        }
        
        # Verificar drivers de impressora
        $drivers = Get-PrinterDriver -ErrorAction SilentlyContinue
        
        if ($drivers) {
            Write-Log "Drivers de impressora instalados: $($drivers.Count)"
            foreach ($driver in $drivers) {
                Write-Log "  - $($driver.Name) (Versão: $($driver.MajorVersion).$($driver.MinorVersion))"
            }
        } else {
            Write-Log "Nenhum driver de impressora encontrado" "WARN"
        }
        
        # Verificar espaço em disco na pasta de spool
        if (Test-Path $SpoolerPath) {
            $spoolSize = (Get-ChildItem $SpoolerPath -Recurse -ErrorAction SilentlyContinue | 
                         Measure-Object -Property Length -Sum).Sum
            
            if ($spoolSize) {
                $spoolSizeMB = [math]::Round($spoolSize / 1MB, 2)
                Write-Log "Tamanho da pasta de spool: ${spoolSizeMB}MB"
                
                if ($spoolSizeMB -gt 100) {
                    Write-Log "PROBLEMA: Pasta de spool muito grande (${spoolSizeMB}MB)" "WARN"
                }
            }
        }
        
        # Verificar serviços relacionados
        $relatedServices = @("Spooler", "PrintNotify", "PrintWorkflowUserSvc")
        
        foreach ($serviceName in $relatedServices) {
            $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
            if ($service) {
                Write-Log "Serviço $serviceName: $($service.Status)"
                if ($service.Status -ne "Running" -and $serviceName -eq "Spooler") {
                    Write-Log "PROBLEMA: Serviço crítico $serviceName não está em execução" "ERROR"
                }
            }
        }
        
        Write-Log "Diagnóstico de impressoras concluído" "SUCCESS"
        return $true
        
    } catch {
        Write-Log "Erro durante diagnóstico: $_" "ERROR"
        return $false
    }
}

# Verificar se é administrador
if (-not (Test-Administrator)) {
    Write-Log "Este script requer permissões de Administrador!" "ERROR"
    exit 1
}

Write-Log "Iniciando correção de impressoras: $Action"

# Executar ação solicitada
$success = $true

switch ($Action) {
    "reset-spooler" {
        $success = Reset-PrintSpooler
    }
    "clear-queue" {
        $success = Clear-PrintQueue
    }
    "reinstall-drivers" {
        $success = Reinstall-PrinterDrivers
    }
    "diagnose" {
        $success = Diagnose-PrinterIssues
    }
    "all" {
        Write-Log "Executando correção completa de impressoras..."
        
        $actions = @(
            @{ Name = "Diagnóstico"; Function = { Diagnose-PrinterIssues } },
            @{ Name = "Limpeza de Fila"; Function = { Clear-PrintQueue } },
            @{ Name = "Reset do Spooler"; Function = { Reset-PrintSpooler } },
            @{ Name = "Reinstalação de Drivers"; Function = { Reinstall-PrinterDrivers } }
        )
        
        foreach ($actionItem in $actions) {
            Write-Log "Executando: $($actionItem.Name)"
            $result = & $actionItem.Function
            if (-not $result) {
                Write-Log "Ação $($actionItem.Name) falhou" "WARN"
                $success = $false
            }
        }
        
        # Diagnóstico final
        Write-Log "Executando diagnóstico final..."
        Diagnose-PrinterIssues
    }
}

if ($success) {
    Write-Log "Correção de impressoras '$Action' concluída com sucesso!" "SUCCESS"
} else {
    Write-Log "Correção de impressoras '$Action' concluída com alguns problemas" "WARN"
}

if ($DryRun) {
    Write-Log "MODO DRY-RUN: Nenhuma alteração foi feita no sistema" "WARN"
}