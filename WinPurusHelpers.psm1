# WinPurusHelpers.psm1
# Módulo de funções auxiliares para o WinPurus
# Versão: 1.0
# Autor: WinPurus Team
# Codificação: UTF-8

# Configurações globais
$Global:WinPurusLogPath = "C:\ProgramData\WinPurus\winpurus.log"
$Global:WinPurusTempPath = "$env:TEMP\WinPurus"

<#
.SYNOPSIS
    Escreve mensagens de log em formato JSON estruturado
.DESCRIPTION
    Registra todas as ações do WinPurus em um arquivo de log centralizado
.PARAMETER Message
    Mensagem a ser registrada
.PARAMETER Level
    Nível do log (INFO, WARNING, ERROR)
.PARAMETER Action
    Ação sendo executada
.PARAMETER Item
    Item relacionado à ação
.PARAMETER Url
    URL relacionada (se aplicável)
.PARAMETER Result
    Resultado da operação (SUCCESS, FAILURE)
.PARAMETER Details
    Detalhes adicionais
#>
function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR")]
        [string]$Level = "INFO",
        
        [Parameter(Mandatory = $false)]
        [string]$Action = "",
        
        [Parameter(Mandatory = $false)]
        [string]$Item = "",
        
        [Parameter(Mandatory = $false)]
        [string]$Url = "",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("SUCCESS", "FAILURE", "PENDING")]
        [string]$Result = "PENDING",
        
        [Parameter(Mandatory = $false)]
        [string]$Details = ""
    )
    
    try {
        # Criar diretório de log se não existir
        $logDir = Split-Path $Global:WinPurusLogPath -Parent
        if (-not (Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }
        
        # Criar objeto de log estruturado
        $logEntry = @{
            timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            level = $Level
            user = $env:USERNAME
            message = $Message
            action = $Action
            item = $Item
            url = $Url
            result = $Result
            details = $Details
            computer = $env:COMPUTERNAME
        }
        
        # Converter para JSON e adicionar ao arquivo
        $jsonLog = $logEntry | ConvertTo-Json -Compress
        Add-Content -Path $Global:WinPurusLogPath -Value $jsonLog -Encoding UTF8
        
        # Exibir no console com cores
        $color = switch ($Level) {
            "INFO" { "Green" }
            "WARNING" { "Yellow" }
            "ERROR" { "Red" }
            default { "White" }
        }
        
        Write-Host "[$Level] $Message" -ForegroundColor $color
        
    } catch {
        Write-Warning "Erro ao escrever no log: $($_.Exception.Message)"
    }
}

<#
.SYNOPSIS
    Executa scripts remotos de forma segura com validação
.DESCRIPTION
    Baixa e executa scripts de URLs confiáveis com verificações de segurança
.PARAMETER Url
    URL do script a ser executado
.PARAMETER TrustedSHA256
    Hash SHA256 esperado para validação
.PARAMETER Arguments
    Argumentos para passar ao script
#>
function Invoke-RemoteScriptSecure {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url,
        
        [Parameter(Mandatory = $false)]
        [string]$TrustedSHA256 = "",
        
        [Parameter(Mandatory = $false)]
        [string[]]$Arguments = @()
    )
    
    try {
        Write-Log -Message "Iniciando download seguro de script" -Action "DOWNLOAD_SCRIPT" -Url $Url
        
        # Criar diretório temporário
        if (-not (Test-Path $Global:WinPurusTempPath)) {
            New-Item -ItemType Directory -Path $Global:WinPurusTempPath -Force | Out-Null
        }
        
        # Gerar nome de arquivo temporário
        $tempFile = Join-Path $Global:WinPurusTempPath "temp_script_$(Get-Random).ps1"
        
        # Download do script
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($Url, $tempFile)
        
        # Validar hash se fornecido
        if ($TrustedSHA256) {
            $fileHash = Get-FileHash -Path $tempFile -Algorithm SHA256
            if ($fileHash.Hash -ne $TrustedSHA256) {
                Remove-Item $tempFile -Force
                throw "Hash SHA256 não confere. Arquivo pode estar comprometido."
            }
            Write-Log -Message "Hash SHA256 validado com sucesso" -Level "INFO"
        }
        
        # Executar script
        Write-Log -Message "Executando script baixado" -Action "EXECUTE_SCRIPT"
        & $tempFile @Arguments
        
        # Limpar arquivo temporário
        Remove-Item $tempFile -Force
        
        Write-Log -Message "Script executado com sucesso" -Result "SUCCESS"
        
    } catch {
        Write-Log -Message "Erro ao executar script remoto: $($_.Exception.Message)" -Level "ERROR" -Result "FAILURE"
        throw
    }
}

<#
.SYNOPSIS
    Baixa arquivos com barra de progresso e validação
.DESCRIPTION
    Função para download de arquivos grandes com monitoramento de progresso
.PARAMETER Url
    URL do arquivo a ser baixado
.PARAMETER Destination
    Caminho de destino para salvar o arquivo
.PARAMETER TrustedSHA256
    Hash SHA256 esperado para validação
#>
function Start-FileDownload {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url,
        
        [Parameter(Mandatory = $true)]
        [string]$Destination,
        
        [Parameter(Mandatory = $false)]
        [string]$TrustedSHA256 = ""
    )
    
    try {
        Write-Log -Message "Iniciando download de arquivo" -Action "DOWNLOAD_FILE" -Url $Url
        
        # Criar diretório de destino se não existir
        $destDir = Split-Path $Destination -Parent
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        
        # Verificar espaço em disco (mínimo 5GB)
        $drive = (Get-Item $destDir).PSDrive
        $freeSpace = (Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='$($drive.Name):'").FreeSpace
        $freeSpaceGB = [math]::Round($freeSpace / 1GB, 2)
        
        if ($freeSpaceGB -lt 5) {
            throw "Espaço insuficiente em disco. Disponível: ${freeSpaceGB}GB. Mínimo necessário: 5GB"
        }
        
        Write-Host "Espaço disponível: ${freeSpaceGB}GB" -ForegroundColor Green
        
        # Configurar WebClient com barra de progresso
        $webClient = New-Object System.Net.WebClient
        
        # Evento para mostrar progresso
        Register-ObjectEvent -InputObject $webClient -EventName DownloadProgressChanged -Action {
            $percent = $Event.SourceEventArgs.ProgressPercentage
            $received = [math]::Round($Event.SourceEventArgs.BytesReceived / 1MB, 2)
            $total = [math]::Round($Event.SourceEventArgs.TotalBytesToReceive / 1MB, 2)
            
            Write-Progress -Activity "Baixando arquivo" -Status "$percent% - $received MB de $total MB" -PercentComplete $percent
        } | Out-Null
        
        # Iniciar download
        $webClient.DownloadFileAsync($Url, $Destination)
        
        # Aguardar conclusão
        while ($webClient.IsBusy) {
            Start-Sleep -Milliseconds 100
        }
        
        Write-Progress -Activity "Baixando arquivo" -Completed
        
        # Verificar se o arquivo foi baixado
        if (-not (Test-Path $Destination)) {
            throw "Falha no download. Arquivo não encontrado no destino."
        }
        
        $fileSize = [math]::Round((Get-Item $Destination).Length / 1MB, 2)
        Write-Host "Download concluído! Tamanho: ${fileSize}MB" -ForegroundColor Green
        
        # Validar hash se fornecido
        if ($TrustedSHA256) {
            Write-Host "Validando integridade do arquivo..." -ForegroundColor Yellow
            $fileHash = Get-FileHash -Path $Destination -Algorithm SHA256
            if ($fileHash.Hash -ne $TrustedSHA256) {
                Remove-Item $Destination -Force
                throw "Hash SHA256 não confere. Arquivo pode estar corrompido ou comprometido."
            }
            Write-Host "Integridade do arquivo validada com sucesso!" -ForegroundColor Green
        }
        
        Write-Log -Message "Download concluído com sucesso" -Result "SUCCESS" -Details "Tamanho: ${fileSize}MB"
        return $Destination
        
    } catch {
        Write-Log -Message "Erro no download: $($_.Exception.Message)" -Level "ERROR" -Result "FAILURE"
        throw
    } finally {
        if ($webClient) {
            $webClient.Dispose()
        }
    }
}

<#
.SYNOPSIS
    Monta imagens de disco (.img, .iso) e retorna a letra da unidade
.DESCRIPTION
    Monta arquivos de imagem e localiza o setup.exe para instalação
.PARAMETER ImagePath
    Caminho para o arquivo de imagem
#>
function Mount-OfficeImage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ImagePath
    )
    
    try {
        Write-Log -Message "Montando imagem de disco" -Action "MOUNT_IMAGE" -Item $ImagePath
        
        # Verificar se o arquivo existe
        if (-not (Test-Path $ImagePath)) {
            throw "Arquivo de imagem não encontrado: $ImagePath"
        }
        
        # Montar a imagem
        $mountResult = Mount-DiskImage -ImagePath $ImagePath -PassThru
        
        # Obter a letra da unidade montada
        $driveLetter = ($mountResult | Get-Volume).DriveLetter
        if (-not $driveLetter) {
            # Método alternativo para obter a letra da unidade
            Start-Sleep -Seconds 2
            $diskImage = Get-DiskImage -ImagePath $ImagePath
            $driveLetter = ($diskImage | Get-Volume).DriveLetter
        }
        
        if (-not $driveLetter) {
            throw "Não foi possível obter a letra da unidade montada"
        }
        
        $mountPath = "${driveLetter}:"
        Write-Host "Imagem montada em: $mountPath" -ForegroundColor Green
        
        # Procurar pelo setup.exe
        $setupPaths = @(
            "$mountPath\setup.exe",
            "$mountPath\setup64.exe",
            "$mountPath\Office\setup.exe",
            "$mountPath\Office\setup64.exe"
        )
        
        $setupPath = $null
        foreach ($path in $setupPaths) {
            if (Test-Path $path) {
                $setupPath = $path
                break
            }
        }
        
        if (-not $setupPath) {
            throw "Arquivo setup.exe não encontrado na imagem montada"
        }
        
        Write-Log -Message "Imagem montada com sucesso" -Result "SUCCESS" -Details "Unidade: $mountPath, Setup: $setupPath"
        
        return @{
            DriveLetter = $driveLetter
            MountPath = $mountPath
            SetupPath = $setupPath
            ImagePath = $ImagePath
        }
        
    } catch {
        Write-Log -Message "Erro ao montar imagem: $($_.Exception.Message)" -Level "ERROR" -Result "FAILURE"
        throw
    }
}

<#
.SYNOPSIS
    Desmonta imagens de disco montadas anteriormente
.DESCRIPTION
    Remove a montagem de arquivos de imagem do sistema
.PARAMETER ImagePath
    Caminho para o arquivo de imagem a ser desmontado
#>
function Dismount-OfficeImage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ImagePath
    )
    
    try {
        Write-Log -Message "Desmontando imagem de disco" -Action "DISMOUNT_IMAGE" -Item $ImagePath
        
        Dismount-DiskImage -ImagePath $ImagePath
        Write-Host "Imagem desmontada com sucesso" -ForegroundColor Green
        
        Write-Log -Message "Imagem desmontada com sucesso" -Result "SUCCESS"
        
    } catch {
        Write-Log -Message "Erro ao desmontar imagem: $($_.Exception.Message)" -Level "ERROR" -Result "FAILURE"
        Write-Warning "Erro ao desmontar imagem. Pode ser necessário desmontar manualmente."
    }
}

<#
.SYNOPSIS
    Verifica se o usuário atual tem privilégios de administrador
.DESCRIPTION
    Retorna true se o script está sendo executado como administrador
#>
function Test-IsAdmin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

<#
.SYNOPSIS
    Testa a conectividade de rede
.DESCRIPTION
    Verifica se há conexão com a internet antes de iniciar downloads
#>
function Test-NetworkConnection {
    try {
        $testUrl = "https://www.microsoft.com"
        $request = [System.Net.WebRequest]::Create($testUrl)
        $request.Timeout = 5000
        $response = $request.GetResponse()
        $response.Close()
        return $true
    } catch {
        return $false
    }
}

<#
.SYNOPSIS
    Exibe mensagem colorida e aguarda entrada do usuário
.DESCRIPTION
    Função auxiliar para pausas e confirmações no menu
.PARAMETER Message
    Mensagem a ser exibida
.PARAMETER Color
    Cor da mensagem
#>
function Show-ColorMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [string]$Color = "White"
    )
    
    Write-Host $Message -ForegroundColor $Color
}

<#
.SYNOPSIS
    Solicita confirmação do usuário
.DESCRIPTION
    Exibe uma pergunta e aguarda confirmação (S/N)
.PARAMETER Message
    Mensagem de confirmação
#>
function Get-UserConfirmation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    
    do {
        Write-Host "$Message (S/N): " -ForegroundColor Yellow -NoNewline
        $response = Read-Host
    } while ($response -notmatch '^[SsNn]$')
    
    return $response -match '^[Ss]$'
}

# Exportar todas as funções públicas
Export-ModuleMember -Function @(
    'Write-Log',
    'Invoke-RemoteScriptSecure',
    'Start-FileDownload',
    'Mount-OfficeImage',
    'Dismount-OfficeImage',
    'Test-IsAdmin',
    'Test-NetworkConnection',
    'Show-ColorMessage',
    'Get-UserConfirmation'
)