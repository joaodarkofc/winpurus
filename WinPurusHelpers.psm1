<#
WinPurusHelpers.psm1
Módulo com funções de suporte seguras para WinPurus
#>

# Logging helper
function Write-Log {
    param([hashtable]$Entry)
    $LogDir = "C:\ProgramData\WinPurus"
    if (-not (Test-Path $LogDir)) { New-Item -Path $LogDir -ItemType Directory | Out-Null }
    $LogFile = Join-Path $LogDir "winpurus.log"
    $Entry.Time = (Get-Date).ToString("o")
    Add-Content -Path $LogFile -Value ($Entry | ConvertTo-Json -Depth 6)
}

# Função segura para executar scripts remotos
function Invoke-RemoteScriptSecure {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Url,
        [string]$TrustedSHA256Url = $null,
        [switch]$RequireElevationForExecution
    )

    $tmp = Join-Path $env:TEMP "WinPurus_Remote"
    if (-not (Test-Path $tmp)) { New-Item -Path $tmp -ItemType Directory | Out-Null }

    $fileName = [IO.Path]::GetFileName([Uri]$Url)
    if ([string]::IsNullOrWhiteSpace($fileName)) { $fileName = "remote_$([Guid]::NewGuid()).ps1" }
    $dest = Join-Path $tmp $fileName

    Invoke-WebRequest -Uri $Url -OutFile $dest -UseBasicParsing -ErrorAction Stop

    Write-Host "Preview (200 linhas max) do script remoto:" -ForegroundColor Cyan
    Get-Content $dest -TotalCount 200 | ForEach-Object { Write-Host $_ }

    $fileHash = (Get-FileHash -Path $dest -Algorithm SHA256).Hash
    Write-Host "SHA256: $fileHash" -ForegroundColor Yellow

    if ($TrustedSHA256Url) {
        try {
            $trusted = (Invoke-WebRequest -Uri $TrustedSHA256Url -UseBasicParsing -ErrorAction Stop).Content.Trim()
            Write-Host "Hash confiável: $trusted" -ForegroundColor Yellow
        } catch {
            Write-Warning "Falha ao baixar hash confiável: $_"
        }
    }

    $open = Read-Host "Abrir no Notepad para inspeção completa? (S/N)"
    if ($open -match '^[sS]') { Start-Process notepad -ArgumentList $dest -Wait }

    $choice = Read-Host "Executar? [S]=contexto atual | [E]=elevado | [N]=cancelar"
    switch ($choice.ToUpper()) {
        'S' { & $dest; Write-Log @{Action='Executed-Current'; File=$dest; User=$env:USERNAME} }
        'E' {
            $args = "-NoProfile -ExecutionPolicy Bypass -File `"$dest`""
            Start-Process powershell -ArgumentList $args -Verb RunAs
            Write-Log @{Action='Started-Elevated'; File=$dest; User=$env:USERNAME}
        }
        default { Write-Host "Cancelado pelo usuário." -ForegroundColor Green; Write-Log @{Action='Cancelled'; File=$dest; User=$env:USERNAME} }
    }
}
