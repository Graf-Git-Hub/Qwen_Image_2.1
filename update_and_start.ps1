param(
    [string]$Root = $PSScriptRoot,
    [switch]$SkipUpdate,
    [switch]$ValidateRootOnly
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$RepoRaw = 'https://raw.githubusercontent.com/Graf-Git-Hub/Qwen_Image_2.1/main'

function Normalize-Root([string]$Value) {
    if ([string]::IsNullOrWhiteSpace($Value)) { $Value = $PSScriptRoot }

    # Defensive cleanup for arguments arriving from CMD. In particular,
    # old launchers could pass a trailing backslash directly before the
    # closing quote, leaving a literal quote in the received path.
    $Value = $Value.Trim()
    $Value = $Value.Trim('"')
    while ($Value.EndsWith('\') -or $Value.EndsWith('/')) {
        $Value = $Value.Substring(0, $Value.Length - 1)
    }
    $Value = $Value.Trim('"')

    if ([string]::IsNullOrWhiteSpace($Value)) { $Value = $PSScriptRoot }
    return [IO.Path]::GetFullPath($Value)
}

$Root = Normalize-Root $Root

if ($ValidateRootOnly) {
    Write-Host "ROOT_OK=$Root"
    exit 0
}

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

            $needsRepair = $false
            $appFile = Join-Path $Root 'qwen_app.py'
            if (-not (Test-Path $appFile)) {
                $needsRepair = $true
            } else {
                try {
                    $appCheck = [IO.File]::ReadAllText($appFile, [Text.Encoding]::UTF8)
                    if ($appCheck -notmatch ('APP_VERSION = "' + [regex]::Escape($remoteVersion) + '"')) { $needsRepair = $true }
                    if ($appCheck.Contains('Ã') -or $appCheck.Contains('Â')) { $needsRepair = $true }
                    if ($appCheck -notmatch '_autoload_model_on_startup') { $needsRepair = $true }
                    if ($appCheck -notmatch 'function makeQueueVideo' -or $appCheck -notmatch 'function makeQueueStill') { $needsRepair = $true }
                } catch {
                    $needsRepair = $true
                }
            }

            if (($remoteVersion -and $remoteVersion -ne $localVersion) -or $needsRepair) {
                if ($needsRepair -and $remoteVersion -eq $localVersion) {
                    Write-Host "Installation unvollstaendig oder beschaedigt - repariere Version $remoteVersion ..."
                } else {
                    Write-Host "Update gefunden: $localVersion -> $remoteVersion"
                }
                $tempInstaller = Join-Path $env:TEMP ("Qwen_Image_2_1_update_" + [guid]::NewGuid().ToString('N') + '.ps1')
                Invoke-WebRequest -UseBasicParsing -Uri "$RepoRaw/install.ps1?ts=$([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds())" -OutFile $tempInstaller -TimeoutSec 60
                & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $tempInstaller -Target $Root -NoStart -Silent
                $code = $LASTEXITCODE
                Remove-Item -Force $tempInstaller -ErrorAction SilentlyContinue
                if ($code -ne 0) { Write-Warning 'Update/Reparatur fehlgeschlagen. Die vorhandene Version wird gestartet.' }
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
