<#
WinPurus - PowerShell Edition (versão segura, sem ativadores)
Coloque como C:\Program Files\WinPurus\winpurus.ps1

Funcionalidades:
- Relaunch elevado (se necessário)
- Menu: instalar/desinstalar (winget), links, teste/reparo de impressora, rede, reparos do sistema
- Execução remota segura (download -> inspeção -> hash/signature -> confirmação -> execução)
- Logs em C:\ProgramData\WinPurus\winpurus.log
#>

# ---------------------------
# Configurações iniciais
# ---------------------------
$ErrorActionPreference = 'Stop'
$LogDir = "C:\ProgramData\WinPurus"
if (-not (Test-Path $LogDir)) { New-Item -Path $LogDir -ItemType Directory -Force | Out-Null }
$LogFile = Join-Path $LogDir "winpurus.log"

function Write-Log {
    param(
        [Parameter(Mandatory=$true)][hashtable]$Entry
    )
    $Entry.Time = (Get-Date).ToString("o")
    $json = $Entry | ConvertTo-Json -Depth 6
    Add-Content -Path $LogFile -Value $json
}

# ---------------------------
# Elevação (UAC)
# ---------------------------
function Test-IsAdmin {
    return ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Relaunch-Elevated {
    param($ScriptPath, $Args)
    Write-Host "Solicitando elevação (UAC)..." -ForegroundColor Yellow
    $argList = "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`" $Args"
    Start-Process -FilePath powershell -ArgumentList $argList -Verb RunAs
    exit
}

# Se não for admin, relança elevado
if (-not (Test-IsAdmin)) {
    $self = $MyInvocation.MyCommand.Path
    $args = $MyInvocation.UnboundArguments -join ' '
    Relaunch-Elevated -ScriptPath $self -Args $args
}

# ---------------------------
# Helpers e função segura para execução remota
# ---------------------------
function Pause-Ui { Read-Host "Pressione Enter para continuar..." }

function Invoke-RemoteScriptSecure {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)][string]$Url,
        [string]$TrustedSHA256Url = $null,
        [switch]$RequireElevationForExecution
    )

    $tmp = Join-Path $env:TEMP "WinPurus_Remote"
    if (-not (Test-Path $tmp)) { New-Item -Path $tmp -ItemType Directory | Out-Null }

    try {
        $fileName = [IO.Path]::GetFileName([Uri]$Url)
        if ([string]::IsNullOrWhiteSpace($fileName)) { $fileName = "remote_$([Guid]::NewGuid()).ps1" }
        $dest = Join-Path $tmp $fileName

        Write-Host "1/5 - Baixando $Url ..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $Url -OutFile $dest -UseBasicParsing -ErrorAction Stop

        Write-Host "2/5 - Pré-visualização (até 200 linhas):" -ForegroundColor Cyan
        Get-Content $dest -TotalCount 200 | ForEach-Object { Write-Host $_ }

        Write-Host "3/5 - Calculando SHA256..." -ForegroundColor Cyan
        $fileHash = (Get-FileHash -Path $dest -Algorithm SHA256).Hash
        Write-Host "SHA256: $fileHash" -ForegroundColor Yellow

        if ($TrustedSHA256Url) {
            try {
                Write-Host "4/5 - Baixando hash confiável de $TrustedSHA256Url ..." -ForegroundColor Cyan
                $trusted = (Invoke-WebRequest -Uri $TrustedSHA256Url -UseBasicParsing -ErrorAction Stop).Content.Trim()
                Write-Host "Hash confiável obtido: $trusted" -ForegroundColor Yellow
                if ($trusted -ieq $fileHash) {
                    Write-Host "Hash confere ✅" -ForegroundColor Green
                    $hashMatch = $true
                } else {
                    Write-Warning "Hash NÃO confere ❌"
                    $hashMatch = $false
                }
            } catch {
                Write-Warning "Falha ao baixar hash confiável: $_"
                $hashMatch = $null
            }
        } else {
            $hashMatch = $null
            Write-Host "Nenhum hash confiável informado; sem comparação automática." -ForegroundColor Yellow
        }

        Write-Host "5/5 - Verificando assinatura Authenticode (se houver)..." -ForegroundColor Cyan
        try {
            $sig = Get-AuthenticodeSignature -FilePath $dest
            Write-Host "Signature status: $($sig.Status)" -ForegroundColor Yellow
            if ($sig.SignerCertificate) { Write-Host "Assinado por: $($sig.SignerCertificate.Subject)" -ForegroundColor Yellow }
        } catch {
            Write-Warning "Erro ao verificar assinatura: $_"
            $sig = $null
        }

        # Abrir no editor (opcional)
        $open = Read-Host "Abrir o arquivo no Notepad para inspeção completa? (S/N)"
        if ($open -match '^[sS]') { Start-Process -FilePath notepad -ArgumentList $dest -Wait }

        # Confirmação de execução
        $choice = Read-Host "Executar? [S]=aqui | [E]=elevado | [N]=cancelar"
        $action = "Cancelled"
        switch ($choice.ToUpper()) {
            'S' {
                Write-Host "Executando no contexto atual..." -ForegroundColor Yellow
                try { & $dest; $action = "Executed-Current" } catch { $action = "Error: $($_.Exception.Message)"; Write-Warning $action }
            }
            'E' {
                $args = "-NoProfile -ExecutionPolicy Bypass -File `"$dest`""
                Start-Process -FilePath powershell -ArgumentList $args -Verb RunAs
                $action = "Started-Elevated"
            }
            default {
                Write-Host "Execução cancelada pelo usuário." -ForegroundColor Green
                $action = "Cancelled"
            }
        }

        # grava log
        $entry = @{
            Time = (Get-Date).ToString("o")
            User = $env:USERNAME
            Url = $Url
            File = $dest
            SHA256 = $fileHash
            TrustedSHA256Url = $TrustedSHA256Url
            HashMatch = $hashMatch
            SignatureStatus = if ($sig) { $sig.Status } else { $null }
            Action = $action
        }
        Write-Log -Entry $entry

        Write-Host "Ação registrada em: $LogFile" -ForegroundColor Cyan
    } catch {
        Write-Log -Entry @{ Time=(Get-Date).ToString("o"); User=$env:USERNAME; Url=$Url; Error=$_.ToString() }
        Write-Error "Falha ao processar URL: $_"
    }
}

# ---------------------------
# Funções do menu
# ---------------------------
function Show-Title {
    Clear-Host
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host "             WinPurus - Ferramentas           " -ForegroundColor Cyan
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host "Data/Hora: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Yellow
    Write-Host ""
}

function Option-InstallApp {
    Write-Host "Instalar aplicativo (winget)" -ForegroundColor Green
    $app = Read-Host "Digite o ID do pacote (winget) ou URL do instalador local"
    if ([string]::IsNullOrWhiteSpace($app)) { Write-Host "Cancelado."; return }
    if ($app -match '^https?://') {
        Write-Host "Baixando instalador..." -ForegroundColor Yellow
        $installer = Join-Path $env:TEMP ([IO.Path]::GetFileName($app))
        Invoke-WebRequest -Uri $app -OutFile $installer -UseBasicParsing -ErrorAction Stop
        Write-Host "Executando instalador (pode abrir janela)..." -ForegroundColor Yellow
        Start-Process -FilePath $installer -Wait
        Write-Log -Entry @{ Action="Install-Installer"; Package=$app; User=$env:USERNAME; Path=$installer }
    } else {
        Write-Host "Tentando instalar via winget: $app" -ForegroundColor Yellow
        try {
            Start-Process -FilePath winget -ArgumentList "install --accept-source-agreements --accept-package-agreements $app" -NoNewWindow -Wait -ErrorAction Stop
            Write-Log -Entry @{ Action="Install-Winget"; Package=$app; User=$env:USERNAME }
        } catch {
            Write-Warning "Falha ao instalar via winget: $_"
            Write-Log -Entry @{ Action="Install-Winget-Failed"; Package=$app; Error=$_.ToString(); User=$env:USERNAME }
        }
    }
    Pause-Ui
}

function Option-UninstallApp {
    Write-Host "Desinstalar aplicativo (winget / Get-AppxPackage)" -ForegroundColor Green
    $choice = Read-Host "Digite 'winget' para usar winget ou 'appx' para apps UWP (Enter para cancelar)"
    if ($choice -eq 'winget') {
        $pkg = Read-Host "Digite o ID ou nome do pacote para desinstalar"
        if ($pkg) {
            Start-Process -FilePath winget -ArgumentList "uninstall $pkg" -NoNewWindow -Wait
            Write-Log -Entry @{ Action="Uninstall-Winget"; Package=$pkg; User=$env:USERNAME }
        }
    } elseif ($choice -eq 'appx') {
        $list = Get-AppxPackage | Select-Object Name, PackageFullName
        $list | Format-Table Name, PackageFullName -AutoSize
        $pkg = Read-Host "Digite o PackageFullName para remover"
        if ($pkg) {
            Remove-AppxPackage -Package $pkg -ErrorAction SilentlyContinue
            Write-Log -Entry @{ Action="Uninstall-Appx"; Package=$pkg; User=$env:USERNAME }
        }
    } else {
        Write-Host "Cancelado."
    }
    Pause-Ui
}

function Option-Links {
    Write-Host "Links rápidos" -ForegroundColor Green
    $links = @{
        "Intranet" = "https://intranet.example.local"
        "Portal TI" = "https://portal.example.local"
        "Suporte Microsoft" = "https://support.microsoft.com"
    }
    $i = 1; $map = @{}
    foreach ($k in $links.Keys) {
        Write-Host "[$i] $k - $($links[$k])"
        $map[$i] = $links[$k]
        $i++
    }
    $sel = Read-Host "Escolha (número) ou Enter para voltar"
    if ($sel -match '^[0-9]+$' -and $map.ContainsKey([int]$sel)) {
        Start-Process $map[[int]$sel]
        Write-Log -Entry @{ Action="Open-Link"; Link=$map[[int]$sel]; User=$env:USERNAME }
    }
    Pause-Ui
}

function Option-PrinterTest {
    Write-Host "Teste de impressora" -ForegroundColor Green
    try {
        $printers = Get-Printer | Select-Object -ExpandProperty Name
    } catch {
        Write-Warning "Get-Printer não disponível neste sistema." 
        $printers = @()
    }
    if (-not $printers) { Write-Warning "Nenhuma impressora encontrada."; Pause-Ui; return }
    $i=1; $map=@{}
    foreach ($p in $printers) { Write-Host "[$i] $p"; $map[$i]=$p; $i++ }
    $sel = Read-Host "Escolha impressora (número) ou Enter para voltar"
    if ($sel -match '^[0-9]+$' -and $map.ContainsKey([int]$sel)) {
        $printerName = $map[[int]$sel]
        $tmpFile = Join-Path $env:TEMP "winpurus_test_page.txt"
        "WinPurus Test Page - $(Get-Date)" | Out-File -FilePath $tmpFile -Encoding ascii
        Get-Content $tmpFile | Out-Printer -Name $printerName
        Write-Log -Entry @{ Action="Printer-Test"; Printer=$printerName; User=$env:USERNAME }
        Write-Host "Página de teste enviada para $printerName" -ForegroundColor Green
    }
    Pause-Ui
}

function Option-PrinterRepair {
    Write-Host "Reparo de impressora (spooler)" -ForegroundColor Green
    $confirm = Read-Host "Confirma executar reparo no spooler? (S/N)"
    if ($confirm -notmatch '^[sS]') { Write-Host "Cancelado."; Pause-Ui; return }
    try {
        Stop-Service -Name "Spooler" -Force -ErrorAction Stop
        $spool = "$env:SystemRoot\System32\spool\PRINTERS"
        if (Test-Path $spool) { Get-ChildItem $spool -Recurse -Force | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue }
        Start-Service -Name "Spooler"
        Write-Log -Entry @{ Action="Printer-Repair"; User=$env:USERNAME }
        Write-Host "Spooler reiniciado e fila limpa." -ForegroundColor Green
    } catch {
        Write-Warning "Falha durante reparo: $_"
        Write-Log -Entry @{ Action="Printer-Repair-Failed"; Error=$_.ToString(); User=$env:USERNAME }
    }
    Pause-Ui
}

function Option-NetworkTools {
    Write-Host "Ferramentas de Rede" -ForegroundColor Green
    Write-Host "1) Mostrar IP (ipconfig)"; Write-Host "2) Ping"; Write-Host "3) Renovar DHCP"; Write-Host "Enter para voltar"
    $c = Read-Host "Escolha"
    switch ($c) {
        '1' { ipconfig /all; Write-Log -Entry @{ Action="Network-ShowIP"; User=$env:USERNAME }; Pause-Ui }
        '2' { $host = Read-Host "Host para ping (ex: 8.8.8.8)"; if ($host) { Test-Connection -ComputerName $host -Count 4; Write-Log -Entry @{ Action="Network-Ping"; Host=$host; User=$env:USERNAME }; Pause-Ui } }
        '3' { ipconfig /renew; Write-Log -Entry @{ Action="Network-RenewIP"; User=$env:USERNAME }; Pause-Ui }
        default { }
    }
}

function Option-SystemRepair {
    Write-Host "Reparos do Sistema" -ForegroundColor Green
    Write-Host "1) Verificar arquivos do sistema (sfc /scannow)"; Write-Host "2) DISM (RestoreHealth)"; Write-Host "Enter para voltar"
    $choice = Read-Host "Escolha"
    if ($choice -eq '1') {
        Write-Host "Executando sfc /scannow (pode demorar)..." -ForegroundColor Yellow
        sfc /scannow
        Write-Log -Entry @{ Action="System-SFC"; User=$env:USERNAME }
        Pause-Ui
    } elseif ($choice -eq '2') {
        Write-Host "Executando DISM /RestoreHealth (pode demorar)..." -ForegroundColor Yellow
        DISM /Online /Cleanup-Image /RestoreHealth
        Write-Log -Entry @{ Action="System-DISM"; User=$env:USERNAME }
        Pause-Ui
    }
}

# ---------------------------
# Menu principal
# ---------------------------
function Main-Menu {
    while ($true) {
        Show-Title
        Write-Host "1) Instalar aplicativo (winget / instalador)" -ForegroundColor Green
        Write-Host "2) Desinstalar aplicativo (winget / appx)" -ForegroundColor Green
        Write-Host "3) Links rápidos" -ForegroundColor Green
        Write-Host "4) Teste de impressora" -ForegroundColor Green
        Write-Host "5) Reparo de impressora (spooler)" -ForegroundColor Green
        Write-Host "6) Rede e conectividade" -ForegroundColor Green
        Write-Host "7) Reparos do sistema (SFC/DISM)" -ForegroundColor Green
        Write-Host "8) Executar script remoto (seguro)" -ForegroundColor Green
        Write-Host "0) Sair" -ForegroundColor Cyan

        $opt = Read-Host "Escolha uma opção"
        switch ($opt) {
            '1' { Option-InstallApp }
            '2' { Option-UninstallApp }
            '3' { Option-Links }
            '4' { Option-PrinterTest }
            '5' { Option-PrinterRepair }
            '6' { Option-NetworkTools }
            '7' { Option-SystemRepair }
            '8' {
                $url = Read-Host "Digite a URL do script remoto (ou Enter para voltar)"
                if ($url) {
                    $trusted = Read-Host "Se houver URL com SHA256 confiável, cole aqui (opcional) ou Enter"
                    Invoke-RemoteScriptSecure -Url $url -TrustedSHA256Url $trusted
                }
                Pause-Ui
            }
            '0' { break }
            default { Write-Host "Opção inválida." -ForegroundColor Red; Pause-Ui }
        }
    }
}

# ---------------------------
# Iniciar
# ---------------------------
Main-Menu
