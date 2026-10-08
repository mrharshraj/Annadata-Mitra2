# Production APK build helper (Windows PowerShell).
# Reads PUBLIC values (SUPABASE_URL, SUPABASE_ANON_KEY) from the git-ignored
# project-root credentials.txt and passes them as --dart-define.
# No secrets are stored in this file. Service-role / JWT / Gemini keys are
# NEVER read here and must never be added.
# Usage from app/: powershell -ExecutionPolicy Bypass -File tool/build_prod_apk.ps1 [-Release]
param([switch]$Release)

$ErrorActionPreference = "Stop"
$root = Resolve-Path (Join-Path (Split-Path $PSScriptRoot -Parent) "..")
$lines = Get-Content (Join-Path $root "credentials.txt")
$url = @($lines | Where-Object { $_ -match "^https://" })[0].Trim()
$key = @($lines | Where-Object { $_ -match "^sb_publishable_" })[0].Trim()
if (-not $url -or -not $key) { throw "public Supabase config missing" }

$mode = "debug"
if ($Release) { $mode = "release" }
flutter build apk --$mode --no-pub `
  --dart-define=SUPABASE_URL=$url `
  --dart-define=SUPABASE_ANON_KEY=$key
