$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$engine = Join-Path $root 'engine'
$venvPython = Join-Path $root 'venv\Scripts\python.exe'
$tag = 'master-956-1b0ba10'
$release = "https://github.com/leejet/stable-diffusion.cpp/releases/download/$tag"

function Download-Extract([string]$Name) {
    $archive = Join-Path $root $Name
    if (-not (Test-Path $archive)) {
        Write-Host "Lade $Name ..."
        Invoke-WebRequest -Uri "$release/$Name" -OutFile $archive -UseBasicParsing
    }
    Expand-Archive -LiteralPath $archive -DestinationPath $engine -Force
}

try {
    if (-not (Test-Path $venvPython)) {
        $python = $null
        try { $python = (& py -3.11 -c 'import sys;print(sys.executable)' 2>$null | Select-Object -First 1) } catch {}
        if (-not $python -or -not (Test-Path $python)) {
            throw 'Python 3.11 fehlt. Installiere Python 3.11 oder benutze deine bestehende Qwen-Installation.'
        }
        & $python -m venv (Join-Path $root 'venv')
        if ($LASTEXITCODE -ne 0) { throw 'Python-Umgebung konnte nicht erstellt werden.' }
    }

    $cli = Get-ChildItem -Path $engine -Filter sd-cli.exe -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $cli) {
        New-Item -ItemType Directory -Force -Path $engine | Out-Null
        Download-Extract 'sd-master-1b0ba10-bin-win-cuda12-x64.zip'
        Download-Extract 'cudart-sd-bin-win-cu12-x64.zip'
        $cli = Get-ChildItem -Path $engine -Filter sd-cli.exe -Recurse | Select-Object -First 1
        if (-not $cli) { throw 'Das CUDA-Archiv enthaelt kein sd-cli.exe.' }
        Get-ChildItem -Path $engine -Filter '*.dll' -File -Recurse | Where-Object { $_.DirectoryName -ne $cli.DirectoryName } | ForEach-Object {
            Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $cli.DirectoryName $_.Name) -Force
        }
    }

    Write-Host 'Pruefe Python-Pakete ...'
    & $venvPython -c 'import gradio, huggingface_hub, PIL'
    if ($LASTEXITCODE -ne 0) {
        & $venvPython -m pip install 'gradio>=6,<7' 'huggingface_hub>=1,<2' 'pillow>=10,<13'
        if ($LASTEXITCODE -ne 0) { throw 'Python-Pakete konnten nicht installiert werden.' }
    }

    Write-Host 'Starte lokale GPU-Oberflaeche ...'
    & $venvPython (Join-Path $root 'local_gpu.py')
    if ($LASTEXITCODE -ne 0) { throw "App wurde mit Code $LASTEXITCODE beendet." }
} catch {
    Write-Host "Fehler: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
