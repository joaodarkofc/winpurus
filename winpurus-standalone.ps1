# ============================================================================
# WINPURUS - SISTEMA DE INSTALACAO E CONFIGURACAO DO WINDOWS
# Versao Standalone - Todas as funcoes em um unico arquivo
# ============================================================================

# Configuracoes globais
$Global:WinPurusLogPath = "$env:TEMP\WinPurus\winpurus.log"

# ============================================================================
# FUNCOES AUXILIARES
# ============================================================================

function Test-IsAdmin {
    try {
        $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch {
        return $false
    }
}

function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    
    try {
        $logDir = Split-Path $Global:WinPurusLogPath -Parent
        if (-not (Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }
        
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry = "[$timestamp] [$Level] $Message"
        Add-Content -Path $Global:WinPurusLogPath -Value $logEntry -Encoding UTF8
        
        $colorMap = @{
            "INFO" = "White"
            "WARNING" = "Yellow"
            "ERROR" = "Red"
            "SUCCESS" = "Green"
        }
        
        Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $colorMap[$Level]
    }
    catch {
        Write-Host "Erro ao escrever log: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Test-NetworkConnection {
    param([string]$Url = "https://www.microsoft.com")
    
    try {
        $response = Invoke-WebRequest -Uri $Url -Method Head -TimeoutSec 10 -UseBasicParsing
        return $response.StatusCode -eq 200
    }
    catch {
        return $false
    }
}

function Show-ColorMessage {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Download-FileWithProgress {
    param(
        [string]$Url,
        [string]$OutputPath
    )
    
    try {
        Write-Log -Message "Iniciando download de $Url" -Level "INFO"
        
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "WinPurus/1.0")
        
        Register-ObjectEvent -InputObject $webClient -EventName DownloadProgressChanged -Action {
            $percent = $Event.SourceEventArgs.ProgressPercentage
            $received = [math]::Round($Event.SourceEventArgs.BytesReceived / 1MB, 2)
            $total = [math]::Round($Event.SourceEventArgs.TotalBytesToReceive / 1MB, 2)
            
            Write-Progress -Activity "Download em progresso" -Status "$percent% - $received MB de $total MB" -PercentComplete $percent
        } | Out-Null
        
        $webClient.DownloadFile($Url, $OutputPath)
        $webClient.Dispose()
        
        Write-Progress -Activity "Download em progresso" -Completed
        
        Show-ColorMessage -Message "[OK] Download concluido com sucesso!" -Color "Green"
        return $true
    }
    catch {
        Show-ColorMessage -Message "[ERRO] Erro no download: $($_.Exception.Message)" -Color "Red"
        if (Test-Path $OutputPath) {
            Remove-Item $OutputPath -Force
        }
        return $false
    }
}

function Mount-OfficeImage {
    param([string]$ImagePath)
    
    try {
        Write-Log -Message "Montando imagem ISO: $ImagePath" -Level "INFO"
        $mountResult = Mount-DiskImage -ImagePath $ImagePath -PassThru
        $driveLetter = ($mountResult | Get-Volume).DriveLetter
        
        if ($driveLetter) {
            Write-Log -Message "Imagem montada com sucesso na unidade $driveLetter" -Level "SUCCESS"
            return "$driveLetter`:"
        } else {
            throw "Nao foi possivel obter a letra da unidade"
        }
    }
    catch {
        Write-Log -Message "Erro ao montar imagem: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Dismount-OfficeImage {
    param([string]$ImagePath)
    
    try {
        Write-Log -Message "Desmontando imagem ISO: $ImagePath" -Level "INFO"
        Dismount-DiskImage -ImagePath $ImagePath
        Write-Log -Message "Imagem desmontada com sucesso" -Level "SUCCESS"
    }
    catch {
        Write-Log -Message "Erro ao desmontar imagem: $($_.Exception.Message)" -Level "WARNING"
    }
}

# ============================================================================
# DADOS DO MICROSOFT OFFICE
# ============================================================================

$Global:OfficeEditions = @(
    @{ Index = 1; Edition = "Office 2016 Professional Plus"; Url = "https://archive.org/download/office-2016-professional-plus-x-64-pt-br/Office%202016%20Professional%20Plus%20x64%20PT-BR.iso" },
    @{ Index = 2; Edition = "Office 2016 Standard"; Url = "https://archive.org/download/office-2016-standard-x-64-pt-br/Office%202016%20Standard%20x64%20PT-BR.iso" },
    @{ Index = 3; Edition = "Office 2019 Professional Plus"; Url = "https://archive.org/download/office-2019-professional-plus-x-64-pt-br/Office%202019%20Professional%20Plus%20x64%20PT-BR.iso" },
    @{ Index = 4; Edition = "Office 2019 Standard"; Url = "https://archive.org/download/office-2019-standard-x-64-pt-br/Office%202019%20Standard%20x64%20PT-BR.iso" },
    @{ Index = 5; Edition = "Office 2021 Professional Plus"; Url = "https://archive.org/download/office-2021-professional-plus-x-64-pt-br/Office%202021%20Professional%20Plus%20x64%20PT-BR.iso" },
    @{ Index = 6; Edition = "Office 2021 Standard"; Url = "https://archive.org/download/office-2021-standard-x-64-pt-br/Office%202021%20Standard%20x64%20PT-BR.iso" }
)

# ============================================================================
# INTERFACE DO USUARIO
# ============================================================================

function Show-Header {
    Clear-Host
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "           W I N P U R U S" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Sistema de Instalacao e Configuracao do Windows" -ForegroundColor Yellow
    Write-Host "Versao: 1.0.0 | Autor: Joao Dark | Licenca: MIT" -ForegroundColor Gray
    Write-Host "============================================" -ForegroundColor DarkGray
    Write-Host ""
}

function Show-MainMenu {
    Write-Host "MENU PRINCIPAL" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Microsoft Office" -ForegroundColor White
    Write-Host "2. Ferramentas do Sistema" -ForegroundColor DarkGray
    Write-Host "3. Configuracoes Avancadas" -ForegroundColor DarkGray
    Write-Host "4. Relatorios e Logs" -ForegroundColor DarkGray
    Write-Host "5. Ajuda e Suporte" -ForegroundColor DarkGray
    Write-Host "0. Sair" -ForegroundColor Red
    Write-Host ""
}

function Show-OfficeMenu {
    Write-Host "MICROSOFT OFFICE" -ForegroundColor Cyan
    Write-Host ""
    
    foreach ($edition in $Global:OfficeEditions) {
        Write-Host "$($edition.Index). $($edition.Edition)" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "0. Voltar ao Menu Principal" -ForegroundColor Yellow
    Write-Host ""
}

# ============================================================================
# FUNCOES PRINCIPAIS
# ============================================================================

function Install-OfficeEdition {
    param([int]$EditionIndex)
    
    $selectedEdition = $Global:OfficeEditions | Where-Object { $_.Index -eq $EditionIndex }
    
    if (-not $selectedEdition) {
        Show-ColorMessage -Message "[ERRO] Edicao invalida selecionada!" -Color "Red"
        return
    }
    
    Write-Log -Message "Iniciando instalacao do $($selectedEdition.Edition)" -Level "INFO"
    
    Show-ColorMessage -Message "[INFO] Iniciando instalacao do $($selectedEdition.Edition)..." -Color "Cyan"
    
    if (-not (Test-NetworkConnection)) {
        Show-ColorMessage -Message "[ERRO] Sem conexao com a internet. Verifique sua conexao e tente novamente." -Color "Red"
        return
    }
    
    $downloadPath = "$env:TEMP\WinPurus"
    if (-not (Test-Path $downloadPath)) {
        New-Item -ItemType Directory -Path $downloadPath -Force | Out-Null
    }
    
    $fileName = "Office_$($selectedEdition.Index).iso"
    $fullPath = Join-Path $downloadPath $fileName
    
    Show-ColorMessage -Message "[INFO] Baixando $($selectedEdition.Edition)..." -Color "Yellow"
    
    if (Download-FileWithProgress -Url $selectedEdition.Url -OutputPath $fullPath) {
        Show-ColorMessage -Message "[INFO] Preparando instalacao..." -Color "Yellow"
        
        try {
            $mountPath = Mount-OfficeImage -ImagePath $fullPath
            Show-ColorMessage -Message "[OK] Imagem montada em $mountPath" -Color "Green"
            
            $setupPath = Join-Path $mountPath "setup.exe"
            if (Test-Path $setupPath) {
                Show-ColorMessage -Message "[INFO] Executando instalador..." -Color "Cyan"
                Start-Process -FilePath $setupPath -Wait
                Show-ColorMessage -Message "[OK] Instalacao concluida!" -Color "Green"
                Write-Log -Message "Instalacao do $($selectedEdition.Edition) concluida com sucesso" -Level "SUCCESS"
            } else {
                Show-ColorMessage -Message "[ERRO] Arquivo setup.exe nao encontrado na imagem!" -Color "Red"
                Write-Log -Message "Setup.exe nao encontrado na imagem montada" -Level "ERROR"
            }
        }
        catch {
            Show-ColorMessage -Message "[ERRO] Erro durante a instalacao: $($_.Exception.Message)" -Color "Red"
            Write-Log -Message "Erro durante instalacao: $($_.Exception.Message)" -Level "ERROR"
        }
        finally {
            try {
                Dismount-OfficeImage -ImagePath $fullPath
            }
            catch {
                Write-Log -Message "Aviso: Nao foi possivel desmontar a imagem automaticamente" -Level "WARNING"
            }
        }
    } else {
        Show-ColorMessage -Message "[ERRO] Falha no download. Tente novamente." -Color "Red"
        Write-Log -Message "Falha no download do $($selectedEdition.Edition)" -Level "ERROR"
    }
    
    Write-Host ""
    Write-Host "Pressione qualquer tecla para continuar..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Start-WinPurus {
    if (-not (Test-IsAdmin)) {
        Write-Host "[ERRO] WinPurus requer privilegios de administrador." -ForegroundColor Red
        Write-Host "       Execute o PowerShell como Administrador e tente novamente." -ForegroundColor Yellow
        exit 1
    }
    
    Write-Log -Message "WinPurus iniciado pelo usuario $env:USERNAME" -Level "INFO"
    
    do {
        Show-Header
        Show-MainMenu
        
        $choice = Read-Host "Escolha uma opcao"
        
        switch ($choice) {
            "1" {
                do {
                    Show-Header
                    Show-OfficeMenu
                    
                    $officeChoice = Read-Host "Escolha uma edicao do Office"
                    
                    if ($officeChoice -eq "0") {
                        break
                    }
                    elseif ($officeChoice -match "^\d+$" -and [int]$officeChoice -ge 1 -and [int]$officeChoice -le $Global:OfficeEditions.Count) {
                        Install-OfficeEdition -EditionIndex ([int]$officeChoice)
                    }
                    else {
                        Show-ColorMessage -Message "[ERRO] Opcao invalida! Tente novamente." -Color "Red"
                        Start-Sleep -Seconds 2
                    }
                } while ($true)
            }
            "2" { Show-ColorMessage -Message "[INFO] Ferramentas do Sistema - Em desenvolvimento" -Color "Yellow"; Start-Sleep -Seconds 2 }
            "3" { Show-ColorMessage -Message "[INFO] Configuracoes Avancadas - Em desenvolvimento" -Color "Yellow"; Start-Sleep -Seconds 2 }
            "4" { Show-ColorMessage -Message "[INFO] Relatorios e Logs - Em desenvolvimento" -Color "Yellow"; Start-Sleep -Seconds 2 }
            "5" { Show-ColorMessage -Message "[INFO] Ajuda e Suporte - Em desenvolvimento" -Color "Yellow"; Start-Sleep -Seconds 2 }
            "0" {
                Show-ColorMessage -Message "[INFO] Obrigado por usar o WinPurus!" -Color "Cyan"
                Write-Log -Message "WinPurus finalizado pelo usuario" -Level "INFO"
                exit 0
            }
            default {
                Show-ColorMessage -Message "[ERRO] Opcao invalida! Tente novamente." -Color "Red"
                Start-Sleep -Seconds 2
            }
        }
    } while ($true)
}

# ============================================================================
# EXECUCAO PRINCIPAL
# ============================================================================

try {
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Write-Host "[ERRO] WinPurus requer PowerShell 5.1 ou superior." -ForegroundColor Red
        Write-Host "       Versao atual: $($PSVersionTable.PSVersion)" -ForegroundColor Yellow
        Write-Host "       Baixe a versao mais recente em: https://aka.ms/PSWindows" -ForegroundColor Cyan
        exit 1
    }
    
    Start-WinPurus
}
catch {
    Write-Host "[ERRO] Erro critico no WinPurus: $($_.Exception.Message)" -ForegroundColor Red
    Write-Log -Message "Erro critico: $($_.Exception.Message)" -Level "ERROR"
    exit 1
}