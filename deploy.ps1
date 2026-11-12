# Al Bukhari: build for Android, and optionally install on a phone.
#
#   .\deploy.ps1            build the APK (for testing and sideloading)
#   .\deploy.ps1 -Install   build, then install on the connected phone/emulator
#   .\deploy.ps1 -Store     build the App Bundle (.aab) for Google Play
#
# Needs Flutter, Rust and Android Studio (see README.md).
param([switch]$Install, [switch]$Store)
# Exit codes are checked after each tool; harmless warnings on stderr are not errors.
Set-Location $PSScriptRoot

# Use the tools from their standard places when they are not on PATH.
if (-not $env:JAVA_HOME) { $env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr' }
$sdk = "$env:LOCALAPPDATA\Android\Sdk"
$env:Path = "$env:JAVA_HOME\bin;$env:USERPROFILE\dev\flutter\bin;$env:USERPROFILE\.cargo\bin;$sdk\platform-tools;$env:Path"

if ($Store) {
  flutter build appbundle --release
  if ($LASTEXITCODE) { exit $LASTEXITCODE }
  Write-Host "`nReady for Google Play: build\app\outputs\bundle\release\app-release.aab"
  exit 0
}

flutter build apk --release
if ($LASTEXITCODE) { exit $LASTEXITCODE }
$apk = 'build\app\outputs\flutter-apk\app-release.apk'
Write-Host "`nBuilt: $apk"

if ($Install) {
  adb install -r $apk
  if ($LASTEXITCODE) { exit $LASTEXITCODE }
  adb shell monkey -p com.albukhari.app -c android.intent.category.LAUNCHER 1 | Out-Null
  Write-Host 'Installed and opened on the device.'
}
