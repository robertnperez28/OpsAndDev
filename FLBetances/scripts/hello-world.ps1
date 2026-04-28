#!/usr/bin/env pwsh
# Script: hello-world.ps1
# Purpose: Print "Hola Mundo" with iteration metadata (parallel pipeline job)

param(
    [string]$Iteration = "unknown"
)

$ErrorActionPreference = "Stop"

Write-Host "==================================================="
Write-Host "Hola Mundo - Iteration #$Iteration"
Write-Host "Executed at: $((Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ'))"
Write-Host "Hostname: $(hostname)"
Write-Host "==================================================="
