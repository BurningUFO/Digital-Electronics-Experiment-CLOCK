<#
Build a local Windows release package for ClockLink Studio.

The generated EXE and ZIP are build artifacts. They are intentionally ignored
by Git and should be uploaded to a GitHub Release instead of committed.
#>

[CmdletBinding()]
param(
    [string]$Version = "dev",
    [switch]$SkipTests
)

$ErrorActionPreference = "Stop"

$RepoRoot = Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")
$AppDir = Join-Path $RepoRoot "software\clocklink_studio"
$ReleaseRoot = Join-Path $RepoRoot "artifacts\releases"
$PackageName = "ClockLinkStudio-$Version-win64"
$PackageDir = Join-Path $ReleaseRoot $PackageName
$ZipPath = Join-Path $ReleaseRoot "$PackageName.zip"

function Invoke-Native {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )

    & $FilePath @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed with exit code ${LASTEXITCODE}: $FilePath $($Arguments -join ' ')"
    }
}

New-Item -ItemType Directory -Force -Path $ReleaseRoot | Out-Null

Push-Location $AppDir
try {
    Invoke-Native python -m pip install --upgrade pip
    Invoke-Native python -m pip install -r requirements-build.txt

    if (-not $SkipTests) {
        Invoke-Native python -m pytest
    }

    Invoke-Native python -m PyInstaller --noconfirm ClockLinkStudio.spec

    $ExePath = Join-Path $AppDir "dist\ClockLinkStudio.exe"
    if (-not (Test-Path -LiteralPath $ExePath)) {
        throw "Build finished but EXE was not found: $ExePath"
    }

    if (Test-Path -LiteralPath $PackageDir) {
        Remove-Item -LiteralPath $PackageDir -Recurse -Force
    }
    if (Test-Path -LiteralPath $ZipPath) {
        Remove-Item -LiteralPath $ZipPath -Force
    }

    New-Item -ItemType Directory -Force -Path $PackageDir | Out-Null
    Copy-Item -LiteralPath $ExePath -Destination (Join-Path $PackageDir "ClockLinkStudio.exe")
    Copy-Item -LiteralPath (Join-Path $AppDir "README.md") -Destination (Join-Path $PackageDir "README.md")
    Copy-Item -LiteralPath (Join-Path $RepoRoot "docs\UART_PROTOCOL.md") -Destination (Join-Path $PackageDir "UART_PROTOCOL.md")

    $NotesPath = Join-Path $PackageDir "RELEASE_NOTES.txt"
    @"
ClockLink Studio $Version

Run:
  ClockLinkStudio.exe

Serial defaults:
  115200 baud, 8 data bits, no parity, 1 stop bit

Notes:
  - Mock mode works without FPGA hardware.
  - Serial mode requires the Nexys A7 firmware that implements the ClockLink UART protocol.
  - The UART protocol document is included as UART_PROTOCOL.md.
"@ | Set-Content -LiteralPath $NotesPath -Encoding UTF8

    Compress-Archive -Path (Join-Path $PackageDir "*") -DestinationPath $ZipPath
    Write-Host "Built release package: $ZipPath"
}
finally {
    Pop-Location
}
