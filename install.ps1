param(
    [string]$Target = "",
    [switch]$NoStart,
    [switch]$Silent
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$RepoRaw = 'https://raw.githubusercontent.com/Graf-Git-Hub/Qwen_Image_2.1/main'
$Version = '8.2.0'

function Write-Step([string]$Text) {
    if (-not $Silent) { Write-Host $Text }
}

function Get-DefaultTarget {
    # Preserve the original installation location on this workstation when the parent exists.
    $paschyRoot = 'K:\Paschy_Tools_und_Projekte'
    if (Test-Path $paschyRoot) {
        return 'K:\Paschy_Tools_und_Projekte\Qwen_image2.1\Qwen-Image-2.1-Standalone'
    }
    return (Join-Path $env:LOCALAPPDATA 'Qwen-Image-2.1-Standalone')
}

function Download-File([string]$Relative, [string]$Destination, [int64]$MinBytes = 1) {
    $url = "$RepoRaw/$Relative?ts=$([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds())"
    $parent = Split-Path -Parent $Destination
    if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
    $last = $null
    for ($i = 1; $i -le 3; $i++) {
        try {
            Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $Destination -TimeoutSec 180
            if (-not (Test-Path $Destination)) { throw "Download wurde nicht gespeichert: $Relative" }
            if ((Get-Item $Destination).Length -lt $MinBytes) { throw "Download ist unvollstaendig: $Relative" }
            return
        } catch {
            $last = $_
            Start-Sleep -Seconds 2
        }
    }
    throw "Download fehlgeschlagen: $Relative`n$last"
}

function Find-Python311 {
    try {
        $p = (& py -3.11 -c "import sys;print(sys.executable)" 2>$null | Select-Object -First 1).Trim()
        if ($p -and (Test-Path $p)) { return $p }
    } catch {}

    $known = Join-Path $env:LOCALAPPDATA 'Programs\Python\Python311\python.exe'
    if (Test-Path $known) { return $known }

    try {
        $cmd = Get-Command python.exe -ErrorAction Stop
        $ver = (& $cmd.Source -c "import sys;print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>$null).Trim()
        if ($ver -eq '3.11') { return $cmd.Source }
    } catch {}

    return $null
}

if ([string]::IsNullOrWhiteSpace($Target)) { $Target = Get-DefaultTarget }
$Target = [IO.Path]::GetFullPath($Target)
$Temp = Join-Path $env:TEMP ("Qwen_Image_2_1_Install_" + [guid]::NewGuid().ToString('N'))
$Log = Join-Path $Target 'INSTALL_UPDATE.log'

New-Item -ItemType Directory -Force -Path $Target | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $Target 'outputs') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $Target 'hf_cache') | Out-Null
New-Item -ItemType Directory -Force -Path $Temp | Out-Null

Start-Transcript -Path $Log -Append | Out-Null

try {
    if (-not $Silent) {
        Write-Host '============================================================'
        Write-Host '  Qwen Image 2.1 - INSTALLATION / UPDATE'
        Write-Host '============================================================'
        Write-Host "Ziel: $Target"
        Write-Host ''
    }

    Write-Step '[1/8] Lade aktuelle Programmdateien von GitHub ...'
    $downloads = @(
        @{ Rel='payload/qwen_app.py.gz.b64.001'; Name='qwen_app.py.gz.b64.001'; Min=5000 },
        @{ Rel='payload/qwen_app.py.gz.b64.002'; Name='qwen_app.py.gz.b64.002'; Min=5000 },
        @{ Rel='payload/qwen_app.py.gz.b64.003'; Name='qwen_app.py.gz.b64.003'; Min=5000 },
        @{ Rel='payload/qwen_app.py.gz.b64.004'; Name='qwen_app.py.gz.b64.004'; Min=5000 },
        @{ Rel='START_QWEN_IMAGE_2_1.cmd'; Name='START_QWEN_IMAGE_2_1.cmd'; Min=100 },
        @{ Rel='update_and_start.ps1';      Name='update_and_start.ps1';      Min=500 },
        @{ Rel='loading_matrix.mp4';        Name='loading_matrix.mp4';        Min=5000 },
        @{ Rel='queue_wait.webp';           Name='queue_wait.webp';           Min=5000 },
        @{ Rel='VERSION.txt';               Name='VERSION.txt';               Min=3 }
    )

    foreach ($item in $downloads) {
        Download-File $item.Rel (Join-Path $Temp $item.Name) $item.Min
    }

    # Reconstruct the compressed application payload from small text chunks.
    # This avoids fragile binary transfers through the public installer path.
    $gzPath = Join-Path $Temp 'qwen_app.py.gz'
    $appTemp = Join-Path $Temp 'qwen_app.py'
    $chunkNames = @(
        'qwen_app.py.gz.b64.001',
        'qwen_app.py.gz.b64.002',
        'qwen_app.py.gz.b64.003',
        'qwen_app.py.gz.b64.004'
    )
    $b64 = ''
    foreach ($chunkName in $chunkNames) {
        $b64 += (Get-Content (Join-Path $Temp $chunkName) -Raw).Trim()
    }
    try {
        [IO.File]::WriteAllBytes($gzPath, [Convert]::FromBase64String($b64))
    } catch {
        throw 'Qwen-App-Payload konnte nicht rekonstruiert werden.'
    }

    $inStream = [IO.File]::OpenRead($gzPath)
    try {
        $gzip = New-Object IO.Compression.GzipStream($inStream, [IO.Compression.CompressionMode]::Decompress)
        try {
            $outStream = [IO.File]::Create($appTemp)
            try { $gzip.CopyTo($outStream) } finally { $outStream.Dispose() }
        } finally { $gzip.Dispose() }
    } finally { $inStream.Dispose() }

    $appText = Get-Content $appTemp -Raw
    if ($appText -notmatch 'QwenImage21Pipeline' -or $appText -notmatch 'FastAPI') {
        throw 'qwen_app.py ist unvollstaendig oder beschaedigt.'
    }

    # Copy program assets only after all downloads have passed validation.
    Copy-Item -Force $appTemp (Join-Path $Target 'qwen_app.py')
    foreach ($item in $downloads) {
        if ($item.Name -eq 'VERSION.txt' -or $item.Name -like 'qwen_app.py.gz.b64.*') { continue }
        Copy-Item -Force (Join-Path $Temp $item.Name) (Join-Path $Target $item.Name)
    }

    if (-not (Test-Path (Join-Path $Target 'OLLAMA_URL.txt'))) {
        'http://127.0.0.1:11434' | Set-Content -Encoding UTF8 (Join-Path $Target 'OLLAMA_URL.txt')
    }
    if (-not (Test-Path (Join-Path $Target 'PROMPT_AI_MODEL.txt'))) {
        '' | Set-Content -Encoding UTF8 (Join-Path $Target 'PROMPT_AI_MODEL.txt')
    }

    Write-Step '[2/8] Pruefe NVIDIA ...'
    if (Get-Command nvidia-smi.exe -ErrorAction SilentlyContinue) {
        & nvidia-smi.exe --query-gpu=name,memory.total,driver_version --format=csv,noheader
    } else {
        Write-Warning 'nvidia-smi wurde nicht gefunden. Bitte einen aktuellen NVIDIA-Treiber installieren.'
    }

    Write-Step '[3/8] Pruefe Python 3.11 ...'
    $venvPython = Join-Path $Target 'venv\Scripts\python.exe'
    if (-not (Test-Path $venvPython)) {
        $python = Find-Python311
        if (-not $python) {
            if (Get-Command winget.exe -ErrorAction SilentlyContinue) {
                Write-Step 'Python 3.11 fehlt. Installiere es automatisch mit winget ...'
                & winget.exe install --id Python.Python.3.11 -e --scope user --silent --accept-package-agreements --accept-source-agreements
                if ($LASTEXITCODE -ne 0) { Write-Warning "winget meldete Fehlercode $LASTEXITCODE. Versuche Fallback." }
                $python = Find-Python311
            }
        }
        if (-not $python) {
            Write-Step 'Winget war nicht verfuegbar oder schlug fehl. Lade Python 3.11.9 direkt ...'
            $pyInstaller = Join-Path $Temp 'python-3.11.9-amd64.exe'
            Invoke-WebRequest -UseBasicParsing -Uri 'https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe' -OutFile $pyInstaller -TimeoutSec 300
            $proc = Start-Process -FilePath $pyInstaller -ArgumentList '/quiet','InstallAllUsers=0','PrependPath=1','Include_launcher=1','Include_pip=1' -Wait -PassThru
            if ($proc.ExitCode -ne 0) { throw "Python-Installation fehlgeschlagen: $($proc.ExitCode)" }
            $python = Find-Python311
        }
        if (-not $python) { throw 'Python 3.11 konnte nicht gefunden oder installiert werden.' }

        Write-Step '[4/8] Erstelle virtuelle Python-Umgebung ...'
        & $python -m venv (Join-Path $Target 'venv')
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path $venvPython)) { throw 'venv konnte nicht erstellt werden.' }
    } else {
        Write-Step '[4/8] Vorhandene virtuelle Python-Umgebung gefunden.'
    }

    Write-Step '[5/8] Pruefe / installiere Python-Pakete ...'
    $packageCheck = @'
import sys
ok = True
try:
 import torch, fastapi, uvicorn, transformers, accelerate, huggingface_hub
 from PIL import Image
 from diffusers import QwenImage21Pipeline
 from packaging.version import Version
 ok = Version(transformers.__version__) >= Version("5.17")
except Exception:
 ok = False
sys.exit(0 if ok else 1)
'@
    & $venvPython -c $packageCheck
    if ($LASTEXITCODE -ne 0) {
        & $venvPython -m pip install --upgrade pip setuptools wheel packaging
        if ($LASTEXITCODE -ne 0) { throw 'pip konnte nicht aktualisiert werden.' }

        & $venvPython -m pip install --upgrade torch torchvision --index-url https://download.pytorch.org/whl/cu126
        if ($LASTEXITCODE -ne 0) { throw 'PyTorch konnte nicht installiert werden.' }

        & $venvPython -m pip install --upgrade 'transformers>=5.17' accelerate pillow fastapi uvicorn python-multipart huggingface_hub hf_xet safetensors sentencepiece packaging
        if ($LASTEXITCODE -ne 0) { throw 'Python-Abhaengigkeiten konnten nicht installiert werden.' }

        & $venvPython -m pip install --upgrade 'https://github.com/huggingface/diffusers/archive/refs/heads/main.zip'
        if ($LASTEXITCODE -ne 0) { throw 'Diffusers konnte nicht installiert werden.' }
    }

    Write-Step '[6/8] Pruefe Anwendung ...'
    & $venvPython -m py_compile (Join-Path $Target 'qwen_app.py')
    if ($LASTEXITCODE -ne 0) { throw 'qwen_app.py hat einen Python-Syntaxfehler.' }

    Write-Step '[7/8] Pruefe Qwen-Image-2.1 Modell ...'
    $modelIndex = Join-Path $Target 'model\model_index.json'
    if (-not (Test-Path $modelIndex)) {
        Write-Host ''
        Write-Host 'Das grosse Qwen-Image-2.1-Modell wird jetzt heruntergeladen.'
        Write-Host 'Das kann lange dauern. Ein abgebrochener Download kann beim naechsten Start fortgesetzt werden.'
        Write-Host ''
        $modelCode = "from huggingface_hub import snapshot_download; snapshot_download(repo_id='Qwen/Qwen-Image-2.1', local_dir=r'''$($Target)\model''')"
        & $venvPython -c $modelCode
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path $modelIndex)) { throw 'Qwen-Image-2.1 Modell konnte nicht vollstaendig heruntergeladen werden.' }
    } else {
        Write-Step 'Modell ist bereits vorhanden.'
    }

    Write-Step '[8/8] Erstelle Desktop-Verknuepfung ...'
    # VERSION is written last. An interrupted install therefore never looks falsely current.
    Copy-Item -Force (Join-Path $Temp 'VERSION.txt') (Join-Path $Target 'VERSION.txt')
    Copy-Item -Force $PSCommandPath (Join-Path $Target 'install.ps1')

    $desktop = [Environment]::GetFolderPath('Desktop')
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut((Join-Path $desktop 'Qwen Image 2.1.lnk'))
    $shortcut.TargetPath = Join-Path $Target 'START_QWEN_IMAGE_2_1.cmd'
    $shortcut.WorkingDirectory = $Target
    $shortcut.IconLocation = "$env:SystemRoot\System32\shell32.dll,167"
    $shortcut.Description = 'Qwen Image 2.1 - automatische Update-Pruefung beim Start'
    $shortcut.Save()

    Write-Host ''
    Write-Host '============================================================'
    Write-Host "  FERTIG - Qwen Image 2.1 $Version"
    Write-Host '============================================================'
    Write-Host "Installiert in: $Target"
    Write-Host 'Desktop-Verknuepfung: Qwen Image 2.1'
    Write-Host ''

    if (-not $NoStart) {
        Start-Process -FilePath (Join-Path $Target 'START_QWEN_IMAGE_2_1.cmd') -WorkingDirectory $Target -ArgumentList '/skipupdate'
    }
}
catch {
    Write-Host ''
    Write-Host '============================================================' -ForegroundColor Red
    Write-Host '  INSTALLATION / UPDATE FEHLGESCHLAGEN' -ForegroundColor Red
    Write-Host '============================================================' -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host "Logdatei: $Log"
    exit 1
}
finally {
    try { Stop-Transcript | Out-Null } catch {}
    Remove-Item -Recurse -Force $Temp -ErrorAction SilentlyContinue
}

exit 0
