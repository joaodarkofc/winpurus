# install_and_register_module.ps1
# Script de instalação e registro do módulo WinPurus
# Versão: 1.0
# Autor: WinPurus Team
# Codificação: UTF-8

#Requires -Version 5.1
#Requires -RunAsAdministrator

# Configuração de codificação para suporte completo ao português
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Configurações do módulo
$ModuleName = "WinPurus"
$ModuleVersion = "1.0.0"
$ModuleDescription = "Sistema de Instalação e Manutenção do Windows"
$ModuleAuthor = "WinPurus Team"

# Caminhos importantes
$ScriptRoot = $PSScriptRoot
$ModuleSourcePath = Join-Path $ScriptRoot "WinPurusHelpers.psm1"
$MainScriptPath = Join-Path $ScriptRoot "winpurus.ps1"

# Diretório de módulos do usuário
$UserModulesPath = Join-Path $env:USERPROFILE "Documents\WindowsPowerShell\Modules\$ModuleName"
$ModuleManifestPath = Join-Path $UserModulesPath "$ModuleName.psd1"
$ModuleFilePath = Join-Path $UserModulesPath "$ModuleName.psm1"

# Função para exibir cabeçalho
function Show-InstallHeader {
    Clear-Host
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "                    INSTALADOR DO WINPURUS                    " -ForegroundColor White
    Write-Host "        Sistema de Instalação e Manutenção do Windows          " -ForegroundColor Gray
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
}

# Função para verificar privilégios de administrador
function Test-AdminPrivileges {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Função para criar o manifesto do módulo
function New-ModuleManifest {
    param(
        [string]$Path
    )
    
    $manifestContent = @"
@{
    # Informações básicas do módulo
    ModuleVersion = '$ModuleVersion'
    GUID = '$(New-Guid)'
    Author = '$ModuleAuthor'
    CompanyName = 'WinPurus Team'
    Copyright = '(c) $(Get-Date -Format yyyy) WinPurus Team. Todos os direitos reservados.'
    Description = '$ModuleDescription'
    
    # Versão mínima do PowerShell
    PowerShellVersion = '5.1'
    
    # Arquivos do módulo
    RootModule = '$ModuleName.psm1'
    
    # Funções exportadas
    FunctionsToExport = @(
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
    
    # Aliases exportados
    AliasesToExport = @('irmx')
    
    # Variáveis exportadas
    VariablesToExport = @()
    
    # Cmdlets exportados
    CmdletsToExport = @()
    
    # Informações adicionais
    PrivateData = @{
        PSData = @{
            Tags = @('Windows', 'Office', 'Installation', 'Maintenance', 'Portuguese')
            LicenseUri = ''
            ProjectUri = ''
            ReleaseNotes = 'Versão inicial do WinPurus com suporte completo à instalação do Microsoft Office'
        }
    }
}
"@
    
    Set-Content -Path $Path -Value $manifestContent -Encoding UTF8
}

# Função principal de instalação
function Install-WinPurusModule {
    try {
        Show-InstallHeader
        
        Write-Host "Iniciando instalação do módulo WinPurus..." -ForegroundColor Green
        Write-Host ""
        
        # Verificar privilégios de administrador
        if (-not (Test-AdminPrivileges)) {
            Write-Host "ERRO: Este script requer privilégios de administrador." -ForegroundColor Red
            Write-Host "Execute o PowerShell como Administrador e tente novamente." -ForegroundColor Yellow
            exit 1
        }
        
        # Verificar se os arquivos fonte existem
        if (-not (Test-Path $ModuleSourcePath)) {
            throw "Arquivo WinPurusHelpers.psm1 não encontrado em: $ModuleSourcePath"
        }
        
        if (-not (Test-Path $MainScriptPath)) {
            throw "Arquivo winpurus.ps1 não encontrado em: $MainScriptPath"
        }
        
        Write-Host "✓ Arquivos fonte verificados" -ForegroundColor Green
        
        # Criar diretório do módulo
        if (Test-Path $UserModulesPath) {
            Write-Host "Removendo instalação anterior..." -ForegroundColor Yellow
            Remove-Item $UserModulesPath -Recurse -Force
        }
        
        New-Item -ItemType Directory -Path $UserModulesPath -Force | Out-Null
        Write-Host "✓ Diretório do módulo criado: $UserModulesPath" -ForegroundColor Green
        
        # Copiar arquivo do módulo
        Copy-Item $ModuleSourcePath $ModuleFilePath -Force
        Write-Host "✓ Módulo copiado para: $ModuleFilePath" -ForegroundColor Green
        
        # Criar manifesto do módulo
        New-ModuleManifest -Path $ModuleManifestPath
        Write-Host "✓ Manifesto do módulo criado: $ModuleManifestPath" -ForegroundColor Green
        
        # Importar o módulo para teste
        try {
            Import-Module $UserModulesPath -Force
            Write-Host "✓ Módulo importado e testado com sucesso" -ForegroundColor Green
        } catch {
            throw "Erro ao importar o módulo: $($_.Exception.Message)"
        }
        
        # Criar alias global 'irmx' para o script principal
        $aliasCommand = "Set-Alias -Name 'irmx' -Value '$MainScriptPath' -Scope Global"
        
        # Adicionar alias ao perfil do PowerShell
        $profilePath = $PROFILE.CurrentUserAllHosts
        $profileDir = Split-Path $profilePath -Parent
        
        if (-not (Test-Path $profileDir)) {
            New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
        }
        
        # Verificar se o alias já existe no perfil
        $profileContent = if (Test-Path $profilePath) { Get-Content $profilePath -Raw } else { "" }
        
        if ($profileContent -notlike "*irmx*") {
            # Adicionar comentário e alias ao perfil
            $aliasBlock = @"

# WinPurus - Sistema de Instalação e Manutenção do Windows
# Alias 'irmx' para execução rápida do WinPurus
Set-Alias -Name 'irmx' -Value '$MainScriptPath' -Force

"@
            Add-Content -Path $profilePath -Value $aliasBlock -Encoding UTF8
            Write-Host "✓ Alias 'irmx' adicionado ao perfil do PowerShell" -ForegroundColor Green
        } else {
            Write-Host "✓ Alias 'irmx' já existe no perfil" -ForegroundColor Yellow
        }
        
        # Definir alias na sessão atual
        Set-Alias -Name 'irmx' -Value $MainScriptPath -Scope Global -Force
        Write-Host "✓ Alias 'irmx' definido na sessão atual" -ForegroundColor Green
        
        # Criar entrada no registro para execução global (opcional)
        try {
            $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\App Paths\irmx.exe"
            if (-not (Test-Path $regPath)) {
                New-Item -Path $regPath -Force | Out-Null
            }
            Set-ItemProperty -Path $regPath -Name "(Default)" -Value "powershell.exe -ExecutionPolicy Bypass -File `"$MainScriptPath`""
            Write-Host "✓ Entrada no registro criada para execução global" -ForegroundColor Green
        } catch {
            Write-Host "⚠ Aviso: Não foi possível criar entrada no registro" -ForegroundColor Yellow
        }
        
        # Verificar instalação
        Write-Host ""
        Write-Host "Verificando instalação..." -ForegroundColor Yellow
        
        # Testar módulo
        $moduleTest = Get-Module -ListAvailable -Name $ModuleName
        if ($moduleTest) {
            Write-Host "✓ Módulo WinPurus instalado: v$($moduleTest.Version)" -ForegroundColor Green
        } else {
            Write-Host "⚠ Módulo não encontrado na lista de módulos disponíveis" -ForegroundColor Yellow
        }
        
        # Testar alias
        $aliasTest = Get-Alias -Name 'irmx' -ErrorAction SilentlyContinue
        if ($aliasTest) {
            Write-Host "✓ Alias 'irmx' configurado: $($aliasTest.Definition)" -ForegroundColor Green
        } else {
            Write-Host "⚠ Alias 'irmx' não encontrado" -ForegroundColor Yellow
        }
        
        # Exibir resumo da instalação
        Write-Host ""
        Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Green
        Write-Host "                    INSTALAÇÃO CONCLUÍDA                      " -ForegroundColor Green
        Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Green
        Write-Host ""
        Write-Host "O WinPurus foi instalado com sucesso!" -ForegroundColor White
        Write-Host ""
        Write-Host "Como usar:" -ForegroundColor Yellow
        Write-Host "• Digite 'irmx' em qualquer prompt do PowerShell" -ForegroundColor White
        Write-Host "• Ou execute diretamente: $MainScriptPath" -ForegroundColor White
        Write-Host ""
        Write-Host "Funcionalidades instaladas:" -ForegroundColor Yellow
        Write-Host "• Instalação completa do Microsoft Office (2013, 2016, 2019, 2021, 365)" -ForegroundColor White
        Write-Host "• Download automático de links oficiais da Microsoft (pt-BR)" -ForegroundColor White
        Write-Host "• Montagem automática de imagens ISO/IMG" -ForegroundColor White
        Write-Host "• Log detalhado de todas as operações" -ForegroundColor White
        Write-Host "• Interface em português com menus coloridos" -ForegroundColor White
        Write-Host ""
        Write-Host "Arquivos instalados:" -ForegroundColor Yellow
        Write-Host "• Módulo: $ModuleFilePath" -ForegroundColor White
        Write-Host "• Manifesto: $ModuleManifestPath" -ForegroundColor White
        Write-Host "• Script principal: $MainScriptPath" -ForegroundColor White
        Write-Host "• Perfil atualizado: $profilePath" -ForegroundColor White
        Write-Host ""
        Write-Host "Para começar a usar, digite: irmx" -ForegroundColor Cyan
        Write-Host ""
        
    } catch {
        Write-Host ""
        Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Red
        Write-Host "                      ERRO NA INSTALAÇÃO                      " -ForegroundColor Red
        Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Red
        Write-Host "Erro: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        Write-Host "Verifique se:" -ForegroundColor Yellow
        Write-Host "• O PowerShell está sendo executado como Administrador" -ForegroundColor White
        Write-Host "• Os arquivos WinPurusHelpers.psm1 e winpurus.ps1 estão no mesmo diretório" -ForegroundColor White
        Write-Host "• Não há antivírus bloqueando a execução" -ForegroundColor White
        Write-Host ""
        exit 1
    }
}

# Função para desinstalar o módulo
function Uninstall-WinPurusModule {
    try {
        Write-Host "Desinstalando WinPurus..." -ForegroundColor Yellow
        
        # Remover módulo
        if (Test-Path $UserModulesPath) {
            Remove-Item $UserModulesPath -Recurse -Force
            Write-Host "✓ Módulo removido" -ForegroundColor Green
        }
        
        # Remover alias do perfil
        $profilePath = $PROFILE.CurrentUserAllHosts
        if (Test-Path $profilePath) {
            $content = Get-Content $profilePath -Raw
            $newContent = $content -replace "(?s)# WinPurus.*?Set-Alias -Name 'irmx'.*?\r?\n", ""
            Set-Content -Path $profilePath -Value $newContent -Encoding UTF8
            Write-Host "✓ Alias removido do perfil" -ForegroundColor Green
        }
        
        # Remover entrada do registro
        $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\App Paths\irmx.exe"
        if (Test-Path $regPath) {
            Remove-Item $regPath -Force
            Write-Host "✓ Entrada do registro removida" -ForegroundColor Green
        }
        
        Write-Host "WinPurus desinstalado com sucesso!" -ForegroundColor Green
        
    } catch {
        Write-Host "Erro na desinstalação: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Menu principal do instalador
function Show-InstallerMenu {
    Show-InstallHeader
    
    Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Blue
    Write-Host "║                    INSTALADOR WINPURUS                       ║" -ForegroundColor Blue
    Write-Host "╠═══════════════════════════════════════════════════════════════╣" -ForegroundColor Blue
    Write-Host "║                                                               ║" -ForegroundColor Blue
    Write-Host "║  1) Instalar WinPurus                                         ║" -ForegroundColor White
    Write-Host "║  2) Desinstalar WinPurus                                      ║" -ForegroundColor White
    Write-Host "║  3) Verificar instalação                                      ║" -ForegroundColor White
    Write-Host "║                                                               ║" -ForegroundColor Blue
    Write-Host "║  0) Sair                                                      ║" -ForegroundColor Red
    Write-Host "║                                                               ║" -ForegroundColor Blue
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Blue
    Write-Host ""
}

# Função para verificar instalação
function Test-WinPurusInstallation {
    Write-Host "Verificando instalação do WinPurus..." -ForegroundColor Yellow
    Write-Host ""
    
    # Verificar módulo
    $module = Get-Module -ListAvailable -Name $ModuleName
    if ($module) {
        Write-Host "✓ Módulo WinPurus encontrado: v$($module.Version)" -ForegroundColor Green
    } else {
        Write-Host "✗ Módulo WinPurus não encontrado" -ForegroundColor Red
    }
    
    # Verificar alias
    $alias = Get-Alias -Name 'irmx' -ErrorAction SilentlyContinue
    if ($alias) {
        Write-Host "✓ Alias 'irmx' configurado: $($alias.Definition)" -ForegroundColor Green
    } else {
        Write-Host "✗ Alias 'irmx' não encontrado" -ForegroundColor Red
    }
    
    # Verificar arquivos
    if (Test-Path $MainScriptPath) {
        Write-Host "✓ Script principal encontrado: $MainScriptPath" -ForegroundColor Green
    } else {
        Write-Host "✗ Script principal não encontrado" -ForegroundColor Red
    }
    
    if (Test-Path $ModuleFilePath) {
        Write-Host "✓ Arquivo do módulo encontrado: $ModuleFilePath" -ForegroundColor Green
    } else {
        Write-Host "✗ Arquivo do módulo não encontrado" -ForegroundColor Red
    }
    
    Write-Host ""
}

# Loop principal do instalador
do {
    Show-InstallerMenu
    
    Write-Host "Selecione uma opção: " -ForegroundColor Cyan -NoNewline
    $choice = Read-Host
    
    switch ($choice) {
        "1" {
            Install-WinPurusModule
            Write-Host "Pressione qualquer tecla para continuar..." -ForegroundColor Cyan
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "2" {
            Uninstall-WinPurusModule
            Write-Host "Pressione qualquer tecla para continuar..." -ForegroundColor Cyan
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "3" {
            Test-WinPurusInstallation
            Write-Host "Pressione qualquer tecla para continuar..." -ForegroundColor Cyan
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "0" {
            Write-Host "Saindo do instalador..." -ForegroundColor Yellow
            break
        }
        
        default {
            Write-Host "Opção inválida! Pressione qualquer tecla para continuar..." -ForegroundColor Red
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
    }
} while ($true)