<#
.SYNOPSIS
  Sao lưu / khôi phục dữ liệu cục bộ của Flutter Lab qua adb (thẻ SM-2 + lịch sử).

.DESCRIPTION
  Dữ liệu nằm trong SharedPreferences của app (một tệp XML). Script dùng `run-as`
  nên CHỈ chạy được với bản debug/profile (bản release không debuggable).
  Dùng trước khi gỡ app để đổi chữ ký, hoặc để chuyển dữ liệu giữa hai máy.

.EXAMPLE
  ./tool/backup_app_data.ps1 -Action export
  ./tool/backup_app_data.ps1 -Action import -File backup/FlutterSharedPreferences-20261128-001500.xml

.NOTES
  - Bản release (ký bằng keystore nhóm) KHÔNG đọc/ghi được bằng run-as.
  - Tệp xuất chứa toàn bộ thẻ và lịch sử; giữ riêng, không commit (đã gitignore).
#>
param(
  [ValidateSet('export', 'import')]
  [string]$Action = 'export',
  [string]$File,
  [string]$Package = 'vn.flutterlab.flutter_quiz_app',
  [string]$Serial
)

$ErrorActionPreference = 'Stop'

$adb = Join-Path $env:LOCALAPPDATA 'Android\sdk\platform-tools\adb.exe'
if (-not (Test-Path $adb)) { throw "Không tìm thấy adb tại $adb" }

$adbArgs = @()
if ($Serial) { $adbArgs += @('-s', $Serial) }

$prefs = "/data/data/$Package/shared_prefs/FlutterSharedPreferences.xml"

switch ($Action) {
  'export' {
    $outDir = Join-Path (Get-Location) 'backup'
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
    if (-not $File) {
      $File = Join-Path $outDir ("FlutterSharedPreferences-{0}.xml" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
    }

    $lines = & $adb @adbArgs shell "run-as $Package cat $prefs" 2>&1
    if ($LASTEXITCODE -ne 0) { throw "run-as thất bại. App chưa cài, hoặc là bản release không debuggable." }

    $xml = ($lines -join "`n") -replace "`r`n", "`n"
    if ($xml.Length -lt 40 -or $xml -notmatch '<map>') {
      throw "Không đọc được dữ liệu (app chưa có dữ liệu, hoặc không phải bản debug)."
    }

    [System.IO.File]::WriteAllText($File, $xml, (New-Object System.Text.UTF8Encoding($false)))
    "Đã xuất: $File ($((Get-Item $File).Length) bytes)"

    if ($xml -match 'flutter_quiz_cards_sm2') { '  - có bộ thẻ SM-2' } else { '  - KHÔNG thấy bộ thẻ' }
    if ($xml -match 'flutter_lab_quiz_history_v1') { '  - có lịch sử làm bài' } else { '  - KHÔNG thấy lịch sử' }
  }

  'import' {
    if (-not $File) { throw "Cần -File trỏ tới tệp XML đã xuất." }
    if (-not (Test-Path $File)) { throw "Không thấy tệp: $File" }

    & $adb @adbArgs shell "am force-stop $Package" | Out-Null
    & $adb @adbArgs push $File '/data/local/tmp/restore-prefs.xml' | Out-Null
    & $adb @adbArgs shell "run-as $Package sh -c 'mkdir -p shared_prefs && cat /data/local/tmp/restore-prefs.xml > shared_prefs/FlutterSharedPreferences.xml'"
    if ($LASTEXITCODE -ne 0) { throw "Khôi phục thất bại. Cần bản debug/profile đã cài và USB debugging." }
    & $adb @adbArgs shell 'rm -f /data/local/tmp/restore-prefs.xml' | Out-Null

    "Đã khôi phục vào $Package. Mở app để kiểm tra số thẻ và lịch sử."
  }
}
