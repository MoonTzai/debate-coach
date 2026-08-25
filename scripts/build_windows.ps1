[CmdletBinding()]
param(
    [string]$Python = "python"
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$venv = Join-Path $projectRoot ".build-venv"
$venvPython = Join-Path $venv "Scripts\python.exe"
$dist = Join-Path $projectRoot "dist"
$work = Join-Path $projectRoot "build"
$spec = Join-Path $projectRoot "spec"

Push-Location $projectRoot
try {
    if (-not (Test-Path -LiteralPath $venvPython -PathType Leaf)) {
        & $Python -m venv $venv
        if ($LASTEXITCODE -ne 0) { throw "venv creation failed: $LASTEXITCODE" }
    }

    & $venvPython -m pip install --disable-pip-version-check "pyinstaller==6.22.2" "pywebview==6.2.1" "pillow==11.3.0"
    if ($LASTEXITCODE -ne 0) { throw "build dependency install failed: $LASTEXITCODE" }

    $version = Get-Content -LiteralPath "version.json" -Raw | ConvertFrom-Json
    $tag = [string]$version.tag
    if (-not $tag) { throw "version.json has no tag" }
    $exe = "Debate-Coach-Windows-$tag.exe"
    $name = [IO.Path]::GetFileNameWithoutExtension($exe)

    & $venvPython "WindowsApp/extract-icon.py"
    if ($LASTEXITCODE -ne 0) { throw "icon extraction failed: $LASTEXITCODE" }
    $icon = "WindowsApp/generated/Debate-Coach.ico"
    if (-not (Test-Path -LiteralPath $icon -PathType Leaf)) { throw "generated icon missing" }

    & $venvPython -m PyInstaller `
        --noconfirm `
        --clean `
        --onefile `
        --windowed `
        --noupx `
        --name $name `
        --version-file (Join-Path $projectRoot "WindowsApp/windows_version_info.txt") `
        --manifest (Join-Path $projectRoot "WindowsApp/windows_dpi_manifest.xml") `
        --icon (Join-Path $projectRoot $icon) `
        --add-data ((Join-Path $projectRoot "Debate-Coach-web.html") + ";.") `
        --collect-all webview `
        --hidden-import clr `
        --hidden-import webview.platforms.winforms `
        --hidden-import webview.platforms.edgechromium `
        --distpath $dist `
        --workpath $work `
        --specpath $spec `
        (Join-Path $projectRoot "WindowsApp/host.py")
    if ($LASTEXITCODE -ne 0) { throw "PyInstaller failed: $LASTEXITCODE" }

    $exePath = Join-Path $dist $exe
    if (-not (Test-Path -LiteralPath $exePath -PathType Leaf)) { throw "built EXE missing: $exePath" }

    $p = Start-Process -FilePath $exePath -ArgumentList "--smoke" -PassThru -Wait
    $smoke = [IO.Path]::ChangeExtension($exePath, ".smoke.txt")
    if (-not (Test-Path -LiteralPath $smoke -PathType Leaf)) { throw "smoke report missing; exit=$($p.ExitCode)" }
    $report = Get-Content -LiteralPath $smoke -Raw
    $masterSha = (Get-FileHash -Algorithm SHA256 -LiteralPath "Debate-Coach-web.html").Hash.ToLowerInvariant()
    if ($report -notmatch [regex]::Escape("embedded_master_sha256=$masterSha")) { throw "embedded master SHA mismatch" }
    if ($p.ExitCode -ne 0 -and $report -notmatch "webview2_runtime=MISSING") { throw "EXE smoke failed unexpectedly: $($p.ExitCode)" }

    $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $exePath).Hash.ToLowerInvariant()
    Write-Host "Built: $exePath"
    Write-Host "SHA-256: $hash"
    Write-Host $report
}
finally {
    Pop-Location
}
