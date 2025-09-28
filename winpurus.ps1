function Invoke-RemoteScriptSecure {
    param(
        [Parameter(Mandatory=$true)][string]$Url,
        [string]$TrustedSHA256Url = $null   # opcional: URL que contém o hash confiável em texto
    )

    $tmp = Join-Path $env:TEMP "WinPurus_Remote"
    if (-not (Test-Path $tmp)) { New-Item -Path $tmp -ItemType Directory | Out-Null }
    $file = [IO.Path]::GetFileName([Uri]$Url)
    if ([string]::IsNullOrWhiteSpace($file)) { $file = "remote_$(Get-Random).ps1" }
    $dst = Join-Path $tmp $file

    try {
        Write-Host "Baixando $Url ..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $Url -OutFile $dst -UseBasicParsing -ErrorAction Stop
        Write-Host "Salvo em: $dst" -ForegroundColor Green

        Write-Host "`n--- Pré-visualização (até 200 linhas) ---" -ForegroundColor Cyan
        Get-Content $dst -TotalCount 200 | ForEach-Object { Write-Host $_ }
        Write-Host "--- fim pré-visualização ---`n" -ForegroundColor Cyan

        $hash = (Get-FileHash -Path $dst -Algorithm SHA256).Hash
        Write-Host "SHA256: $hash" -ForegroundColor Yellow

        if ($TrustedSHA256Url) {
            try {
                $trusted = (Invoke-WebRequest -Uri $TrustedSHA256Url -UseBasicParsing -ErrorAction Stop).Content.Trim()
                Write-Host "Hash confiável obtido: $trusted" -ForegroundColor Yellow
                if ($trusted -ieq $hash) { Write-Host "Hash confere ✅" -ForegroundColor Green } else { Write-Warning "Hash NÃO confere ❌" }
            } catch { Write-Warning "Não foi possível baixar hash confiável: $_" }
        }

        $sig = Get-AuthenticodeSignature -FilePath $dst
        Write-Host "Signature status: $($sig.Status)" -ForegroundColor Yellow
        if ($sig.SignerCertificate) { Write-Host "Assinado por: $($sig.SignerCertificate.Subject)" -ForegroundColor Yellow }

        $open = Read-Host "Abrir no Notepad para inspeção completa? (S/N)"
        if ($open -match '^[sS]') { Start-Process notepad -ArgumentList $dst -Wait }

        $choice = Read-Host "Executar? [S]=aqui | [E]=elevado | [N]=cancelar"
        switch ($choice.ToUpper()) {
            'S' { & $dst; Write-Host "Executado no contexto atual." -ForegroundColor Green }
            'E' { Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$dst`"" -Verb RunAs; Write-Host "Iniciado em janela elevada." -ForegroundColor Green }
            default { Write-Host "Execução cancelada." -ForegroundColor Cyan }
        }

        # opcional: gravar log (pode adaptar para ProgramData)
        $logDir = Join-Path $env:TEMP "WinPurusLogs"
        if (-not (Test-Path $logDir)) { New-Item $logDir -ItemType Directory | Out-Null }
        $entry = @{ Time=(Get-Date).ToString("o"); Url=$Url; File=$dst; SHA256=$hash; Action=$choice }
        Add-Content -Path (Join-Path $logDir "winpurus_remote_log.txt") -Value (ConvertTo-Json $entry)
    } catch {
        Write-Error "Erro: $_"
    }
}
