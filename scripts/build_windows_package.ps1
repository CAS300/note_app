<#
.SYNOPSIS
Builds the MSIX package for the Note App on Windows.

.DESCRIPTION
This script compiles the Flutter application for Windows desktop and
packages it into an MSIX file using the msix pub package. It provides
instructions on how to pass certificate paths and passwords if signing
is required.

.EXAMPLE
.\build_windows_package.ps1
#>

Write-Host "========================================="
Write-Host "    Note App Windows MSIX Build Script   "
Write-Host "========================================="
Write-Host ""
Write-Host "Step 1: Cleaning previous builds..."
flutter clean

Write-Host "Step 2: Getting dependencies..."
flutter pub get

Write-Host "Step 3: Building Flutter Windows release..."
flutter build windows

Write-Host "Step 4: Creating MSIX Package..."
# Note: For production releases, you should sign the MSIX package.
# Do NOT hardcode your certificate password in the code repository!
# Provide it via environment variables or uncommitted local files.
# Example with signing:
# dart run msix:create --certificate-path $env:CERT_PATH --certificate-password $env:CERT_PASSWORD

dart run msix:create

Write-Host "========================================="
Write-Host "Build Complete!"
Write-Host "Check the output directory: build\windows\x64\runner\Release\"
Write-Host "========================================="
