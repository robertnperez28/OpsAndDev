#!/usr/bin/env pwsh
# Script: create-files.ps1
# Purpose: Create 10 files with the current date, then print their contents

param(
    [string]$OutputDir = "./generated-files"
)

$ErrorActionPreference = "Stop"

New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

Write-Host "==> Generating 10 files in $OutputDir"

1..10 | ForEach-Object {
    $i = $_
    $file = Join-Path $OutputDir "file_$i.txt"
    @(
        "File number: $i"
        "Generated at: $((Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ'))"
        "Local date:   $(Get-Date)"
        "Random ID:    $([guid]::NewGuid())"
    ) | Set-Content -Path $file -Encoding UTF8
    Write-Host "Created: $file"
}

Write-Host ""
Write-Host "==> Printing contents of all generated files:"
Write-Host "==================================================="

Get-ChildItem -Path $OutputDir -Filter "file_*.txt" | Sort-Object Name | ForEach-Object {
    Write-Host "----- $($_.FullName) -----"
    Get-Content $_.FullName | ForEach-Object { Write-Host $_ }
    Write-Host ""
}

$total = (Get-ChildItem -Path $OutputDir -Filter "file_*.txt").Count
Write-Host "==> Done. Total files: $total"
