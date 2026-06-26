# ============================================================
# Basic Store POS — Windows setup.exe yasash (yagona buyruq)
# Ishlatish:  powershell -ExecutionPolicy Bypass -File installer\build_installer.ps1
# Talab: Visual Studio (C++ workload) + Inno Setup 6 o'rnatilgan bo'lishi
# Natija: admin_app2\installer\dist\BasicStorePOS-Setup.exe
# ============================================================
$ErrorActionPreference = 'Stop'
$app = Split-Path -Parent $PSScriptRoot      # admin_app2
$installer = $PSScriptRoot

Write-Host "==> Flutter Windows release build..." -ForegroundColor Cyan
Push-Location $app
flutter build windows --release
if ($LASTEXITCODE -ne 0) { Pop-Location; throw "flutter build windows FAILED (exit $LASTEXITCODE)" }
Pop-Location

$exe = Join-Path $app "build\windows\x64\runner\Release\admin_app.exe"
if (-not (Test-Path $exe)) { throw "Build natijasi topilmadi: $exe" }
Write-Host "==> Build tayyor: $exe" -ForegroundColor Green

# VC++ redist (bo'lmasa yuklab olamiz)
$redist = Join-Path $installer "redist\vc_redist.x64.exe"
if (-not (Test-Path $redist)) {
  Write-Host "==> vc_redist.x64.exe yuklab olinmoqda..." -ForegroundColor Cyan
  New-Item -ItemType Directory -Force -Path (Split-Path $redist) | Out-Null
  Invoke-WebRequest -Uri "https://aka.ms/vs/17/release/vc_redist.x64.exe" -OutFile $redist -UseBasicParsing
}

# Inno Setup ISCC.exe topish
$iscc = @(
  "C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
  "C:\Program Files\Inno Setup 6\ISCC.exe",
  "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $iscc) {
  $cmd = Get-Command ISCC.exe -ErrorAction SilentlyContinue
  if ($cmd) { $iscc = $cmd.Source }
}
if (-not $iscc) { throw "ISCC.exe topilmadi. Inno Setup 6 o'rnatilganini tekshiring." }

Write-Host "==> Inno Setup qadoqlash ($iscc)..." -ForegroundColor Cyan
& $iscc (Join-Path $installer "basic_store_pos.iss")
if ($LASTEXITCODE -ne 0) { throw "ISCC FAILED (exit $LASTEXITCODE)" }

$setup = Join-Path $installer "dist\BasicStorePOS-Setup.exe"
if (Test-Path $setup) {
  $mb = ((Get-Item $setup).Length/1MB).ToString('0.0')
  Write-Host "`n✅ TAYYOR: $setup ($mb MB)" -ForegroundColor Green
} else {
  throw "setup.exe yaratilmadi"
}
