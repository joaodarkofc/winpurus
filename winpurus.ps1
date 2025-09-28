# WinPurus - Sistema de Instalação e Manutenção do Windows
# Versão: 1.0
# Autor: WinPurus Team
# Codificação: UTF-8
# Descrição: Script principal com menu interativo para instalação do Microsoft Office e outras ferramentas

#Requires -Version 5.1

# Configuração de codificação para suporte completo ao português
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Importar módulo de funções auxiliares
$ModulePath = Join-Path $PSScriptRoot "WinPurusHelpers.psm1"
if (Test-Path $ModulePath) {
    Import-Module $ModulePath -Force
} else {
    Write-Error "Módulo WinPurusHelpers.psm1 não encontrado. Certifique-se de que está no mesmo diretório do script."
    exit 1
}

# Verificar e solicitar elevação de privilégios se necessário
function Request-AdminElevation {
    if (-not (Test-IsAdmin)) {
        Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Red
        Write-Host "                    PRIVILÉGIOS INSUFICIENTES                   " -ForegroundColor Red
        Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Red
        Write-Host ""
        Write-Host "Este script requer privilégios de administrador para funcionar corretamente." -ForegroundColor Yellow
        Write-Host "Relançando o script com elevação UAC..." -ForegroundColor Yellow
        Write-Host ""
        
        try {
            # Relançar o script como administrador
            $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`""
            Start-Process PowerShell -Verb RunAs -ArgumentList $arguments
            exit 0
        } catch {
            Write-Error "Falha ao elevar privilégios. Execute o PowerShell como Administrador manualmente."
            Read-Host "Pressione Enter para sair"
            exit 1
        }
    }
}

# Definição das edições do Microsoft Office com links oficiais pt-BR
$Global:OfficeEditions = @{
    # Office 2013
    "2013" = @{
        "Office 2013 Home and Student" = "https://officeredir.microsoft.com/r/rlidO15C2RMediaDownload?p1=db&p2=pt-BR&p3=HomeStudentRetail"
        "Office 2013 Home and Business" = "https://officeredir.microsoft.com/r/rlidO15C2RMediaDownload?p1=db&p2=pt-BR&p3=HomeBusinessRetail"
        "Office 2013 Professional" = "https://officeredir.microsoft.com/r/rlidO15C2RMediaDownload?p1=db&p2=pt-BR&p3=ProfessionalRetail"
        "Office 2013 Professional Plus" = "https://officeredir.microsoft.com/r/rlidO15C2RMediaDownload?p1=db&p2=pt-BR&p3=ProPlusRetail"
        "Word 2013" = "https://officeredir.microsoft.com/r/rlidO15C2RMediaDownload?p1=db&p2=pt-BR&p3=WordRetail"
        "Excel 2013" = "https://officeredir.microsoft.com/r/rlidO15C2RMediaDownload?p1=db&p2=pt-BR&p3=ExcelRetail"
        "PowerPoint 2013" = "https://officeredir.microsoft.com/r/rlidO15C2RMediaDownload?p1=db&p2=pt-BR&p3=PowerPointRetail"
        "Outlook 2013" = "https://officeredir.microsoft.com/r/rlidO15C2RMediaDownload?p1=db&p2=pt-BR&p3=OutlookRetail"
        "Publisher 2013" = "https://officeredir.microsoft.com/r/rlidO15C2RMediaDownload?p1=db&p2=pt-BR&p3=PublisherRetail"
        "Access 2013" = "https://officeredir.microsoft.com/r/rlidO15C2RMediaDownload?p1=db&p2=pt-BR&p3=AccessRetail"
        "Project 2013 Standard" = "https://officeredir.microsoft.com/r/rlidO15C2RMediaDownload?p1=db&p2=pt-BR&p3=ProjectStdRetail"
        "Project 2013 Professional" = "https://officeredir.microsoft.com/r/rlidO15C2RMediaDownload?p1=db&p2=pt-BR&p3=ProjectProRetail"
        "Visio 2013 Standard" = "https://officeredir.microsoft.com/r/rlidO15C2RMediaDownload?p1=db&p2=pt-BR&p3=VisioStdRetail"
        "Visio 2013 Professional" = "https://officeredir.microsoft.com/r/rlidO15C2RMediaDownload?p1=db&p2=pt-BR&p3=VisioProRetail"
    }
    
    # Office 2016
    "2016" = @{
        "Office 2016 Home and Student" = "https://officecdn.microsoft.com/db/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/pt-BR/HomeStudentRetail.img"
        "Office 2016 Home and Business" = "https://officecdn.microsoft.com/db/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/pt-BR/HomeBusinessRetail.img"
        "Office 2016 Professional" = "https://officecdn.microsoft.com/db/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/pt-BR/ProfessionalRetail.img"
        "Office 2016 Professional Plus" = "https://officecdn.microsoft.com/db/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/pt-BR/ProPlusRetail.img"
        "Word 2016" = "https://officecdn.microsoft.com/db/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/pt-BR/WordRetail.img"
        "Excel 2016" = "https://officecdn.microsoft.com/db/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/pt-BR/ExcelRetail.img"
        "PowerPoint 2016" = "https://officecdn.microsoft.com/db/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/pt-BR/PowerPointRetail.img"
        "Outlook 2016" = "https://officecdn.microsoft.com/db/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/pt-BR/OutlookRetail.img"
        "Publisher 2016" = "https://officecdn.microsoft.com/db/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/pt-BR/PublisherRetail.img"
        "Access 2016" = "https://officecdn.microsoft.com/db/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/pt-BR/AccessRetail.img"
        "Project 2016 Standard" = "https://officecdn.microsoft.com/db/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/pt-BR/ProjectStdRetail.img"
        "Project 2016 Professional" = "https://officecdn.microsoft.com/db/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/pt-BR/ProjectProRetail.img"
        "Visio 2016 Standard" = "https://officecdn.microsoft.com/db/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/pt-BR/VisioStdRetail.img"
        "Visio 2016 Professional" = "https://officecdn.microsoft.com/db/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/pt-BR/VisioProRetail.img"
    }
    
    # Office 2019
    "2019" = @{
        "Office 2019 Home and Student" = "https://officecdn.microsoft.com/pr/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/pt-BR/HomeStudent2019Retail.img"
        "Office 2019 Home and Business" = "https://officecdn.microsoft.com/pr/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/pt-BR/HomeBusiness2019Retail.img"
        "Office 2019 Professional" = "https://officecdn.microsoft.com/pr/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/pt-BR/Professional2019Retail.img"
        "Office 2019 Professional Plus" = "https://officecdn.microsoft.com/pr/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/pt-BR/ProPlus2019Retail.img"
        "Word 2019" = "https://officecdn.microsoft.com/pr/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/pt-BR/Word2019Retail.img"
        "Excel 2019" = "https://officecdn.microsoft.com/pr/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/pt-BR/Excel2019Retail.img"
        "PowerPoint 2019" = "https://officecdn.microsoft.com/pr/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/pt-BR/PowerPoint2019Retail.img"
        "Outlook 2019" = "https://officecdn.microsoft.com/pr/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/pt-BR/Outlook2019Retail.img"
        "Publisher 2019" = "https://officecdn.microsoft.com/pr/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/pt-BR/Publisher2019Retail.img"
        "Access 2019" = "https://officecdn.microsoft.com/pr/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/pt-BR/Access2019Retail.img"
        "Project 2019 Standard" = "https://officecdn.microsoft.com/pr/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/pt-BR/ProjectStd2019Retail.img"
        "Project 2019 Professional" = "https://officecdn.microsoft.com/pr/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/pt-BR/ProjectPro2019Retail.img"
        "Visio 2019 Standard" = "https://officecdn.microsoft.com/pr/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/pt-BR/VisioStd2019Retail.img"
        "Visio 2019 Professional" = "https://officecdn.microsoft.com/pr/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/pt-BR/VisioPro2019Retail.img"
    }
    
    # Office 2021
    "2021" = @{
        "Office 2021 Home and Student" = "https://officecdn.microsoft.com/db/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/pt-BR/HomeStudent2021Retail.img"
        "Office 2021 Home and Business" = "https://officecdn.microsoft.com/db/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/pt-BR/HomeBusiness2021Retail.img"
        "Office 2021 Professional" = "https://officecdn.microsoft.com/db/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/pt-BR/Professional2021Retail.img"
        "Office 2021 Professional Plus" = "https://officecdn.microsoft.com/db/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/pt-BR/ProPlus2021Retail.img"
        "Word 2021" = "https://officecdn.microsoft.com/db/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/pt-BR/Word2021Retail.img"
        "Excel 2021" = "https://officecdn.microsoft.com/db/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/pt-BR/Excel2021Retail.img"
        "PowerPoint 2021" = "https://officecdn.microsoft.com/db/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/pt-BR/PowerPoint2021Retail.img"
        "Outlook 2021" = "https://officecdn.microsoft.com/db/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/pt-BR/Outlook2021Retail.img"
        "Publisher 2021" = "https://officecdn.microsoft.com/db/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/pt-BR/Publisher2021Retail.img"
        "Access 2021" = "https://officecdn.microsoft.com/db/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/pt-BR/Access2021Retail.img"
        "Project 2021 Standard" = "https://officecdn.microsoft.com/db/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/pt-BR/ProjectStd2021Retail.img"
        "Project 2021 Professional" = "https://officecdn.microsoft.com/db/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/pt-BR/ProjectPro2021Retail.img"
        "Visio 2021 Standard" = "https://officecdn.microsoft.com/db/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/pt-BR/VisioStd2021Retail.img"
        "Visio 2021 Professional" = "https://officecdn.microsoft.com/db/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/pt-BR/VisioPro2021Retail.img"
    }
    
    # Office 365
    "365" = @{
        "Office 365 Home Premium" = "https://officecdn.microsoft.com/db/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/pt-BR/O365HomePremRetail.img"
        "Office 365 Business" = "https://officecdn.microsoft.com/db/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/pt-BR/O365BusinessRetail.img"
        "Office 365 Professional Plus" = "https://officecdn.microsoft.com/db/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/pt-BR/O365ProPlusRetail.img"
    }
}

# Função para exibir o cabeçalho do programa
function Show-Header {
    Clear-Host
    $currentTime = Get-Date -Format "dd/MM/yyyy HH:mm:ss"
    
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "                            WinPurus v1.0                      " -ForegroundColor White
    Write-Host "        Sistema de Instalação e Manutenção do Windows          " -ForegroundColor Gray
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Data/Hora: $currentTime" -ForegroundColor Yellow
    Write-Host "Usuário: $env:USERNAME" -ForegroundColor Yellow
    Write-Host "Computador: $env:COMPUTERNAME" -ForegroundColor Yellow
    Write-Host ""
}

# Função para exibir o menu principal
function Show-MainMenu {
    Show-Header
    
    Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║                        MENU PRINCIPAL                        ║" -ForegroundColor Green
    Write-Host "╠═══════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    Write-Host "║                                                               ║" -ForegroundColor Green
    Write-Host "║  1) Instalar Microsoft Office                                 ║" -ForegroundColor White
    Write-Host "║  2) Reparos do Windows (SFC/DISM) [Em desenvolvimento]        ║" -ForegroundColor Gray
    Write-Host "║  3) Rede / Impressoras [Em desenvolvimento]                   ║" -ForegroundColor Gray
    Write-Host "║                                                               ║" -ForegroundColor Green
    Write-Host "║  0) Sair                                                      ║" -ForegroundColor Red
    Write-Host "║                                                               ║" -ForegroundColor Green
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
}

# Função para exibir o submenu do Microsoft Office
function Show-OfficeMenu {
    Show-Header
    
    Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Blue
    Write-Host "║                    INSTALAÇÃO MICROSOFT OFFICE               ║" -ForegroundColor Blue
    Write-Host "╠═══════════════════════════════════════════════════════════════╣" -ForegroundColor Blue
    Write-Host "║                                                               ║" -ForegroundColor Blue
    Write-Host "║  Selecione a versão e edição do Office que deseja instalar:  ║" -ForegroundColor White
    Write-Host "║                                                               ║" -ForegroundColor Blue
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Blue
    Write-Host ""
    
    $optionNumber = 1
    $optionMap = @{}
    
    # Exibir opções organizadas por versão
    foreach ($version in @("2013", "2016", "2019", "2021", "365")) {
        $versionName = if ($version -eq "365") { "Office 365" } else { "Office $version" }
        Write-Host "═══ $versionName ═══" -ForegroundColor Yellow
        
        foreach ($edition in $Global:OfficeEditions[$version].Keys | Sort-Object) {
            $optionMap[$optionNumber] = @{
                Version = $version
                Edition = $edition
                Url = $Global:OfficeEditions[$version][$edition]
            }
            
            Write-Host ("{0,2}) {1}" -f $optionNumber, $edition) -ForegroundColor White
            $optionNumber++
        }
        Write-Host ""
    }
    
    Write-Host "0) Voltar ao menu principal" -ForegroundColor Red
    Write-Host ""
    
    return $optionMap
}

# Função para instalar uma edição específica do Office
function Install-OfficeEdition {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Edition,
        
        [Parameter(Mandatory = $true)]
        [string]$Version,
        
        [Parameter(Mandatory = $true)]
        [string]$Url
    )
    
    try {
        Write-Log -Message "Iniciando instalação do $Edition" -Action "INSTALL_OFFICE" -Item $Edition -Url $Url
        
        # Verificar conectividade de rede
        Write-Host "Verificando conectividade de rede..." -ForegroundColor Yellow
        if (-not (Test-NetworkConnection)) {
            throw "Sem conexão com a internet. Verifique sua conexão e tente novamente."
        }
        Write-Host "✓ Conexão com a internet confirmada" -ForegroundColor Green
        
        # Determinar nome do arquivo e diretório de destino
        $fileName = if ($Url -like "*.img") {
            "$($Edition -replace '[^\w\s-]', '').img"
        } else {
            "$($Edition -replace '[^\w\s-]', '').exe"
        }
        
        $destDir = "$env:TEMP\WinPurus\Office\$Version\$($Edition -replace '[^\w\s-]', '')"
        $destPath = Join-Path $destDir $fileName
        
        # Exibir resumo antes do download
        Write-Host ""
        Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
        Write-Host "║                      RESUMO DA INSTALAÇÃO                    ║" -ForegroundColor Magenta
        Write-Host "╠═══════════════════════════════════════════════════════════════╣" -ForegroundColor Magenta
        Write-Host "║ Produto: $($Edition.PadRight(49)) ║" -ForegroundColor White
        Write-Host "║ Versão: Office $($Version.PadRight(45)) ║" -ForegroundColor White
        Write-Host "║ URL: $($Url.Substring(0, [Math]::Min(53, $Url.Length)).PadRight(53)) ║" -ForegroundColor White
        Write-Host "║ Destino: $($destPath.Substring(0, [Math]::Min(49, $destPath.Length)).PadRight(49)) ║" -ForegroundColor White
        Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
        Write-Host ""
        
        # Solicitar confirmação
        if (-not (Get-UserConfirmation "Deseja prosseguir com o download e instalação?")) {
            Write-Host "Instalação cancelada pelo usuário." -ForegroundColor Yellow
            Write-Log -Message "Instalação cancelada pelo usuário" -Result "FAILURE" -Details "Usuário cancelou"
            return
        }
        
        # Iniciar download
        Write-Host ""
        Write-Host "Iniciando download..." -ForegroundColor Green
        $downloadedFile = Start-FileDownload -Url $Url -Destination $destPath
        
        # Verificar se o download foi bem-sucedido
        if (-not (Test-Path $downloadedFile)) {
            throw "Falha no download. Arquivo não encontrado."
        }
        
        $fileSize = [math]::Round((Get-Item $downloadedFile).Length / 1MB, 2)
        Write-Host "✓ Download concluído! Tamanho: ${fileSize}MB" -ForegroundColor Green
        
        # Solicitar confirmação final antes da instalação
        Write-Host ""
        if (-not (Get-UserConfirmation "Deseja prosseguir com a instalação?")) {
            Write-Host "Instalação cancelada pelo usuário." -ForegroundColor Yellow
            Write-Log -Message "Instalação cancelada após download" -Result "FAILURE" -Details "Usuário cancelou após download"
            return
        }
        
        # Processar instalação baseado no tipo de arquivo
        if ($downloadedFile -like "*.img" -or $downloadedFile -like "*.iso") {
            # Arquivo de imagem - montar e instalar
            Write-Host ""
            Write-Host "Montando imagem de disco..." -ForegroundColor Yellow
            
            $mountInfo = Mount-OfficeImage -ImagePath $downloadedFile
            
            try {
                Write-Host "✓ Imagem montada em: $($mountInfo.MountPath)" -ForegroundColor Green
                Write-Host "✓ Setup encontrado em: $($mountInfo.SetupPath)" -ForegroundColor Green
                
                # Executar instalação
                Write-Host ""
                Write-Host "Iniciando instalação do Office..." -ForegroundColor Green
                Write-Host "ATENÇÃO: A instalação pode demorar vários minutos. Aguarde..." -ForegroundColor Yellow
                
                $startTime = Get-Date
                $process = Start-Process -FilePath $mountInfo.SetupPath -Wait -PassThru
                $endTime = Get-Date
                $duration = $endTime - $startTime
                
                if ($process.ExitCode -eq 0) {
                    Write-Host "✓ Instalação concluída com sucesso!" -ForegroundColor Green
                    Write-Host "Tempo de instalação: $($duration.ToString('mm\:ss'))" -ForegroundColor Cyan
                    Write-Log -Message "Instalação concluída com sucesso" -Result "SUCCESS" -Details "ExitCode: 0, Duração: $($duration.ToString('mm\:ss'))"
                } else {
                    Write-Host "⚠ Instalação finalizada com código de saída: $($process.ExitCode)" -ForegroundColor Yellow
                    Write-Log -Message "Instalação finalizada com aviso" -Level "WARNING" -Result "SUCCESS" -Details "ExitCode: $($process.ExitCode)"
                }
                
            } finally {
                # Desmontar imagem
                Write-Host ""
                Write-Host "Desmontando imagem..." -ForegroundColor Yellow
                Dismount-OfficeImage -ImagePath $downloadedFile
            }
            
        } else {
            # Arquivo executável - executar diretamente
            Write-Host ""
            Write-Host "Iniciando instalação..." -ForegroundColor Green
            Write-Host "ATENÇÃO: A instalação pode demorar vários minutos. Aguarde..." -ForegroundColor Yellow
            
            $startTime = Get-Date
            $process = Start-Process -FilePath $downloadedFile -Wait -PassThru
            $endTime = Get-Date
            $duration = $endTime - $startTime
            
            if ($process.ExitCode -eq 0) {
                Write-Host "✓ Instalação concluída com sucesso!" -ForegroundColor Green
                Write-Host "Tempo de instalação: $($duration.ToString('mm\:ss'))" -ForegroundColor Cyan
                Write-Log -Message "Instalação concluída com sucesso" -Result "SUCCESS" -Details "ExitCode: 0, Duração: $($duration.ToString('mm\:ss'))"
            } else {
                Write-Host "⚠ Instalação finalizada com código de saída: $($process.ExitCode)" -ForegroundColor Yellow
                Write-Log -Message "Instalação finalizada com aviso" -Level "WARNING" -Result "SUCCESS" -Details "ExitCode: $($process.ExitCode)"
            }
        }
        
        # Limpeza opcional do arquivo baixado
        Write-Host ""
        if (Get-UserConfirmation "Deseja remover o arquivo de instalação baixado para liberar espaço?") {
            Remove-Item $downloadedFile -Force
            Write-Host "✓ Arquivo de instalação removido." -ForegroundColor Green
        }
        
        Write-Host ""
        Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Green
        Write-Host "                    INSTALAÇÃO FINALIZADA                     " -ForegroundColor Green
        Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Green
        
    } catch {
        $errorMsg = $_.Exception.Message
        Write-Host ""
        Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Red
        Write-Host "                        ERRO NA INSTALAÇÃO                    " -ForegroundColor Red
        Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Red
        Write-Host "Erro: $errorMsg" -ForegroundColor Red
        Write-Host ""
        Write-Host "Sugestões para resolver o problema:" -ForegroundColor Yellow
        Write-Host "• Verifique sua conexão com a internet" -ForegroundColor White
        Write-Host "• Certifique-se de ter espaço suficiente em disco (mínimo 5GB)" -ForegroundColor White
        Write-Host "• Execute o script como Administrador" -ForegroundColor White
        Write-Host "• Tente baixar manualmente do link oficial da Microsoft" -ForegroundColor White
        
        Write-Log -Message "Erro na instalação: $errorMsg" -Level "ERROR" -Result "FAILURE" -Details $errorMsg
    }
    
    Write-Host ""
    Write-Host "Pressione qualquer tecla para voltar ao menu..." -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Função principal do programa
function Start-WinPurus {
    # Verificar e solicitar elevação se necessário
    Request-AdminElevation
    
    # Inicializar log
    Write-Log -Message "WinPurus iniciado" -Action "START_APPLICATION" -Details "Versão 1.0"
    
    # Loop principal do menu
    do {
        Show-MainMenu
        
        Write-Host "Selecione uma opção: " -ForegroundColor Cyan -NoNewline
        $choice = Read-Host
        
        switch ($choice) {
            "1" {
                # Submenu do Microsoft Office
                do {
                    $officeOptions = Show-OfficeMenu
                    
                    Write-Host "Selecione uma opção: " -ForegroundColor Cyan -NoNewline
                    $officeChoice = Read-Host
                    
                    if ($officeChoice -eq "0") {
                        break
                    }
                    
                    if ($officeOptions.ContainsKey([int]$officeChoice)) {
                        $selectedOption = $officeOptions[[int]$officeChoice]
                        Install-OfficeEdition -Edition $selectedOption.Edition -Version $selectedOption.Version -Url $selectedOption.Url
                    } else {
                        Write-Host "Opção inválida! Pressione qualquer tecla para continuar..." -ForegroundColor Red
                        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                    }
                } while ($true)
            }
            
            "2" {
                Write-Host ""
                Write-Host "Funcionalidade em desenvolvimento..." -ForegroundColor Yellow
                Write-Host "Pressione qualquer tecla para continuar..." -ForegroundColor Cyan
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            
            "3" {
                Write-Host ""
                Write-Host "Funcionalidade em desenvolvimento..." -ForegroundColor Yellow
                Write-Host "Pressione qualquer tecla para continuar..." -ForegroundColor Cyan
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            
            "0" {
                Write-Host ""
                Write-Host "Encerrando WinPurus..." -ForegroundColor Yellow
                Write-Log -Message "WinPurus encerrado pelo usuário" -Action "EXIT_APPLICATION"
                break
            }
            
            default {
                Write-Host ""
                Write-Host "Opção inválida! Pressione qualquer tecla para continuar..." -ForegroundColor Red
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
        }
    } while ($true)
}

# Iniciar o programa
try {
    Start-WinPurus
} catch {
    Write-Error "Erro crítico no WinPurus: $($_.Exception.Message)"
    Write-Log -Message "Erro crítico: $($_.Exception.Message)" -Level "ERROR" -Result "FAILURE"
    Read-Host "Pressione Enter para sair"
    exit 1
}