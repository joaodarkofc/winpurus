# WinPurus - Diagnóstico do Sistema
# Gera relatórios detalhados sobre hardware, software e estado do sistema

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("hardware", "software", "system", "all")]
    [string]$Type = "all",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "$env:USERPROFILE\Desktop\WinPurus_Report.json",
    
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
    $logEntry = "[$timestamp] [$Level] [DIAGNOSTICS] $Message"
    
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

# Função para obter informações de hardware
function Get-HardwareInfo {
    Write-Log "Coletando informações de hardware..."
    
    $hardware = @{}
    
    try {
        # CPU
        $cpu = Get-WmiObject -Class Win32_Processor | Select-Object -First 1
        $hardware.CPU = @{
            Name = $cpu.Name
            Cores = $cpu.NumberOfCores
            LogicalProcessors = $cpu.NumberOfLogicalProcessors
            MaxClockSpeed = $cpu.MaxClockSpeed
            Architecture = $cpu.Architecture
        }
        
        # Memória RAM
        $memory = Get-WmiObject -Class Win32_PhysicalMemory
        $totalRAM = ($memory | Measure-Object -Property Capacity -Sum).Sum / 1GB
        $hardware.Memory = @{
            TotalGB = [math]::Round($totalRAM, 2)
            Modules = $memory.Count
            Speed = ($memory | Select-Object -First 1).Speed
        }
        
        # Discos
        $disks = Get-WmiObject -Class Win32_DiskDrive
        $hardware.Storage = @()
        foreach ($disk in $disks) {
            $hardware.Storage += @{
                Model = $disk.Model
                SizeGB = [math]::Round($disk.Size / 1GB, 2)
                Interface = $disk.InterfaceType
            }
        }
        
        # Placa de vídeo
        $gpu = Get-WmiObject -Class Win32_VideoController | Where-Object { $_.Name -notlike "*Basic*" } | Select-Object -First 1
        if ($gpu) {
            $hardware.GPU = @{
                Name = $gpu.Name
                DriverVersion = $gpu.DriverVersion
                VideoMemoryMB = [math]::Round($gpu.AdapterRAM / 1MB, 0)
            }
        }
        
        # Placa-mãe
        $motherboard = Get-WmiObject -Class Win32_BaseBoard
        $hardware.Motherboard = @{
            Manufacturer = $motherboard.Manufacturer
            Product = $motherboard.Product
            SerialNumber = $motherboard.SerialNumber
        }
        
        Write-Log "Informações de hardware coletadas com sucesso" "SUCCESS"
        return $hardware
        
    } catch {
        Write-Log "Erro ao coletar informações de hardware: $_" "ERROR"
        return $null
    }
}

# Função para obter informações de software
function Get-SoftwareInfo {
    Write-Log "Coletando informações de software..."
    
    $software = @{}
    
    try {
        # Sistema operacional
        $os = Get-WmiObject -Class Win32_OperatingSystem
        $software.OperatingSystem = @{
            Name = $os.Caption
            Version = $os.Version
            BuildNumber = $os.BuildNumber
            Architecture = $os.OSArchitecture
            InstallDate = $os.InstallDate
            LastBootUpTime = $os.LastBootUpTime
        }
        
        # .NET Framework
        $dotnetVersions = @()
        $dotnetKeys = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP" -Recurse | Get-ItemProperty -Name Version -ErrorAction SilentlyContinue
        foreach ($key in $dotnetKeys) {
            if ($key.Version) {
                $dotnetVersions += $key.Version
            }
        }
        $software.DotNetFramework = $dotnetVersions | Sort-Object -Unique
        
        # PowerShell
        $software.PowerShell = @{
            Version = $PSVersionTable.PSVersion.ToString()
            Edition = $PSVersionTable.PSEdition
        }
        
        # Windows Features
        $features = Get-WindowsOptionalFeature -Online | Where-Object { $_.State -eq "Enabled" }
        $software.WindowsFeatures = $features | Select-Object -ExpandProperty FeatureName | Sort-Object
        
        # Programas instalados (principais)
        $programs = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -and $_.Version }
        $software.InstalledPrograms = $programs | Select-Object Name, Version, Vendor | Sort-Object Name
        
        Write-Log "Informações de software coletadas com sucesso" "SUCCESS"
        return $software
        
    } catch {
        Write-Log "Erro ao coletar informações de software: $_" "ERROR"
        return $null
    }
}

# Função para obter informações do sistema
function Get-SystemInfo {
    Write-Log "Coletando informações do sistema..."
    
    $system = @{}
    
    try {
        # Uso de disco
        $drives = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
        $system.DiskUsage = @()
        foreach ($drive in $drives) {
            $system.DiskUsage += @{
                Drive = $drive.DeviceID
                TotalGB = [math]::Round($drive.Size / 1GB, 2)
                FreeGB = [math]::Round($drive.FreeSpace / 1GB, 2)
                UsedPercent = [math]::Round((($drive.Size - $drive.FreeSpace) / $drive.Size) * 100, 1)
            }
        }
        
        # Uso de memória
        $totalRAM = (Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory / 1GB
        $availableRAM = (Get-WmiObject -Class Win32_OperatingSystem).FreePhysicalMemory / 1MB / 1024
        $system.MemoryUsage = @{
            TotalGB = [math]::Round($totalRAM, 2)
            AvailableGB = [math]::Round($availableRAM, 2)
            UsedGB = [math]::Round($totalRAM - $availableRAM, 2)
            UsedPercent = [math]::Round((($totalRAM - $availableRAM) / $totalRAM) * 100, 1)
        }
        
        # Processos principais
        $processes = Get-Process | Sort-Object CPU -Descending | Select-Object -First 10
        $system.TopProcesses = $processes | Select-Object Name, CPU, WorkingSet, Id
        
        # Serviços críticos
        $criticalServices = @("Spooler", "BITS", "Themes", "AudioSrv", "Dhcp", "Dnscache", "EventLog", "PlugPlay", "RpcSs", "Schedule", "Winmgmt")
        $system.CriticalServices = @()
        foreach ($serviceName in $criticalServices) {
            $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
            if ($service) {
                $system.CriticalServices += @{
                    Name = $service.Name
                    DisplayName = $service.DisplayName
                    Status = $service.Status.ToString()
                }
            }
        }
        
        # Ativação do Windows
        try {
            $activation = & slmgr.vbs /xpr
            $system.WindowsActivation = $activation
        } catch {
            $system.WindowsActivation = "Não foi possível verificar"
        }
        
        # Última atualização
        $lastUpdate = Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 1
        if ($lastUpdate) {
            $system.LastUpdate = @{
                HotFixID = $lastUpdate.HotFixID
                Description = $lastUpdate.Description
                InstalledOn = $lastUpdate.InstalledOn
            }
        }
        
        Write-Log "Informações do sistema coletadas com sucesso" "SUCCESS"
        return $system
        
    } catch {
        Write-Log "Erro ao coletar informações do sistema: $_" "ERROR"
        return $null
    }
}

# Função principal
function Start-Diagnostics {
    Write-Log "Iniciando diagnóstico do sistema - Tipo: $Type"
    
    if ($DryRun) {
        Write-Log "Modo DRY RUN ativado - nenhuma alteração será feita" "WARNING"
    }
    
    $report = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        ComputerName = $env:COMPUTERNAME
        UserName = $env:USERNAME
        ReportType = $Type
    }
    
    # Coletar informações baseado no tipo
    switch ($Type) {
        "hardware" {
            $report.Hardware = Get-HardwareInfo
        }
        "software" {
            $report.Software = Get-SoftwareInfo
        }
        "system" {
            $report.System = Get-SystemInfo
        }
        "all" {
            $report.Hardware = Get-HardwareInfo
            $report.Software = Get-SoftwareInfo
            $report.System = Get-SystemInfo
        }
    }
    
    # Salvar relatório
    if (-not $DryRun) {
        try {
            $reportJson = $report | ConvertTo-Json -Depth 10
            $reportJson | Out-File -FilePath $OutputPath -Encoding UTF8
            Write-Log "Relatório salvo em: $OutputPath" "SUCCESS"
        } catch {
            Write-Log "Erro ao salvar relatório: $_" "ERROR"
        }
    } else {
        Write-Log "DRY RUN: Relatório seria salvo em: $OutputPath"
    }
    
    # Salvar histórico
    $historyPath = "C:\ProgramData\WinPurus\history.json"
    try {
        $historyDir = Split-Path $historyPath -Parent
        if (-not (Test-Path $historyDir)) {
            New-Item -ItemType Directory -Path $historyDir -Force | Out-Null
        }
        
        $history = @()
        if (Test-Path $historyPath) {
            $history = Get-Content $historyPath | ConvertFrom-Json
        }
        
        $historyEntry = @{
            Timestamp = $report.Timestamp
            Type = $Type
            OutputPath = $OutputPath
            Success = $true
        }
        
        $history += $historyEntry
        
        if (-not $DryRun) {
            $history | ConvertTo-Json -Depth 5 | Out-File -FilePath $historyPath -Encoding UTF8
        }
        
    } catch {
        Write-Log "Erro ao salvar histórico: $_" "ERROR"
    }
    
    Write-Log "Diagnóstico concluído com sucesso" "SUCCESS"
    return $report
}

# Executar diagnóstico
try {
    $result = Start-Diagnostics
    
    if (-not $Quiet) {
        Write-Host "`n=== RESUMO DO DIAGNÓSTICO ===" -ForegroundColor Cyan
        Write-Host "Tipo: $Type" -ForegroundColor White
        Write-Host "Computador: $($result.ComputerName)" -ForegroundColor White
        Write-Host "Data/Hora: $($result.Timestamp)" -ForegroundColor White
        Write-Host "Relatório salvo em: $OutputPath" -ForegroundColor Green
        Write-Host "================================`n" -ForegroundColor Cyan
    }
    
} catch {
    Write-Log "Erro durante o diagnóstico: $_" "ERROR"
    exit 1
}