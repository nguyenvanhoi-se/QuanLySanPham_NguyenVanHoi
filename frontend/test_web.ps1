# Flutter 3.47 on Windows can return 404 for CanvasKit in its test server.
# Serve the SDK files through the test directory, without changing the SDK.
$ErrorActionPreference = 'Stop'
$flutterCommand = Get-Command flutter -ErrorAction Stop
$flutterRoot = Split-Path (Split-Path $flutterCommand.Source -Parent) -Parent
$assetDirectory = Join-Path $PSScriptRoot 'test\canvaskit'
if (Test-Path -LiteralPath $assetDirectory) {
    throw "Temporary test assets already exist: $assetDirectory"
}
$assetFiles = @('canvaskit.js', 'canvaskit.wasm')
Push-Location $PSScriptRoot
try {
    New-Item -ItemType Directory -Path (Join-Path $assetDirectory 'chromium') | Out-Null
    foreach ($assetFile in $assetFiles) {
        Copy-Item -LiteralPath (Join-Path $flutterRoot "bin\cache\flutter_web_sdk\canvaskit\chromium\$assetFile") -Destination (Join-Path $assetDirectory 'chromium')
    }
    & $flutterCommand.Source test --platform chrome @args
    $testExitCode = $LASTEXITCODE
} finally {
    foreach ($assetFile in $assetFiles) {
        $temporaryFile = Join-Path $assetDirectory "chromium\$assetFile"
        if (Test-Path -LiteralPath $temporaryFile) { Remove-Item -LiteralPath $temporaryFile }
    }
    # Remove only empty directories created by this script.
    if (Test-Path -LiteralPath (Join-Path $assetDirectory 'chromium')) {
        [IO.Directory]::Delete((Join-Path $assetDirectory 'chromium'))
    }
    if (Test-Path -LiteralPath $assetDirectory) { [IO.Directory]::Delete($assetDirectory) }
    Pop-Location
}
exit $testExitCode
