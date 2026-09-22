param(
    [string]$Root = $PSScriptRoot,
    [switch]$SkipUpdate
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$RepoRaw = 'https://raw.githubusercontent.com/Graf-Git-Hub/Qwen_Image_2.1/main'
$Root = [IO.Path]::GetFullPath($Root)

function Start-Qwen {
    $python = Join-Path $Root 'venv\Scripts\python.exe'
    $app = Join-Path $Root 'qwen_app.py'
    if (-not (Test-Path $python) -or -not (Test-Path $app)) {
        throw 'Installation ist unvollstaendig. Bitte INSTALL_QWEN_IMAGE_2_1.cmd erneut starten.'
    }
    Start-Process -FilePath $python -ArgumentList @($app) -WorkingDirectory $Root
}

try {
    if (-not $SkipUpdate) {
        $localVersion = '0'
        $versionFile = Join-Path $Root 'VERSION.txt'
        if (Test-Path $versionFile) { $localVersion = (Get-Content $versionFile -Raw).Trim() }

        try {
            $remoteVersion = (Invoke-WebRequest -UseBasicParsing -Uri "$RepoRaw/VERSION.txt?ts=$([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds())" -TimeoutSec 15).Content.Trim()
            Write-Host "Qwen Image 2.1 - installiert: $localVersion | GitHub: $remoteVersion"

            if ($remoteVersion -and $remoteVersion -ne $localVersion) {
                Write-Host "Update gefunden: $localVersion -> $remoteVersion"
                $tempInstaller = Join-Path $env:TEMP ("Qwen_Image_2_1_update_" + [guid]::NewGuid().ToString('N') + '.ps1')
                Invoke-WebRequest -UseBasicParsing -Uri "$RepoRaw/install.ps1?ts=$([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds())" -OutFile $tempInstaller -TimeoutSec 60
                & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $tempInstaller -Target $Root -NoStart -Silent
                $code = $LASTEXITCODE
                Remove-Item -Force $tempInstaller -ErrorAction SilentlyContinue
                if ($code -ne 0) { Write-Warning 'Update fehlgeschlagen. Die vorhandene Version wird gestartet.' }
            }
        } catch {
            Write-Warning 'GitHub ist gerade nicht erreichbar. Die vorhandene Version wird gestartet.'
        }
    }

    Start-Qwen
}
catch {
    Write-Host ''
    Write-Host 'Qwen Image 2.1 konnte nicht gestartet werden:' -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Read-Host 'Enter zum Schliessen'
    exit 1
}
