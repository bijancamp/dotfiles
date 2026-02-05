#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Skill Packager - Creates a distributable .skill file of a skill folder

.DESCRIPTION
    Validates and packages a skill directory into a .skill zip file for distribution.
    Automatically runs validation before packaging.

.PARAMETER SkillFolder
    Path to the skill folder to package.

.PARAMETER OutputDirectory
    Optional output directory for the .skill file. Defaults to current directory.

.EXAMPLE
    .\package_skill.ps1 path\to\my-skill

.EXAMPLE
    .\package_skill.ps1 path\to\my-skill .\dist
#>

param(
    [Parameter(Mandatory, Position = 0)]
    [string]$SkillFolder,

    [Parameter(Position = 1)]
    [string]$OutputDirectory
)

$ErrorActionPreference = "Stop"

# Import validation function
. "$PSScriptRoot\quick_validate.ps1"

# Load the compression assembly (required for PS 5.1; already loaded in PS 7)
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

function New-SkillPackage {
    param(
        [string]$SkillPath,
        [string]$OutDir
    )

    if (-not (Test-Path $SkillPath)) {
        Write-Host "❌ Error: Skill folder not found: $SkillPath"
        return $null
    }

    # Use Get-Item to resolve to canonical long path (avoids 8.3 short name mismatches)
    $skillPath = (Get-Item $SkillPath).FullName

    if (-not (Test-Path $skillPath -PathType Container)) {
        Write-Host "❌ Error: Path is not a directory: $skillPath"
        return $null
    }

    # Validate SKILL.md exists
    $skillMdPath = Join-Path $skillPath "SKILL.md"
    if (-not (Test-Path $skillMdPath)) {
        Write-Host "❌ Error: SKILL.md not found in $skillPath"
        return $null
    }

    # Run validation before packaging
    Write-Host "🔍 Validating skill..."
    $validation = Validate-Skill -SkillPath $skillPath
    if (-not $validation.Valid) {
        Write-Host "❌ Validation failed: $($validation.Message)"
        Write-Host "   Please fix the validation errors before packaging."
        return $null
    }
    Write-Host "✅ $($validation.Message)"
    Write-Host ""

    # Determine output location
    $skillName = Split-Path $skillPath -Leaf
    if ($OutDir) {
        $outputPath = $OutDir
        if (-not (Test-Path $outputPath)) {
            New-Item -ItemType Directory -Path $outputPath -Force | Out-Null
        }
        $outputPath = Resolve-Path $outputPath
    }
    else {
        $outputPath = Get-Location
    }

    $skillFilename = Join-Path $outputPath "$skillName.skill"

    # Remove existing file if present
    if (Test-Path $skillFilename) {
        Remove-Item $skillFilename -Force
    }

    # Create the .skill file (zip format) using System.IO.Compression
    try {
        $zip = [System.IO.Compression.ZipFile]::Open($skillFilename, [System.IO.Compression.ZipArchiveMode]::Create)

        # Get the parent directory (entries are relative to parent, including skill folder name)
        $parentDir = (Split-Path $skillPath -Parent).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)

        # Walk through all files in the skill directory
        $files = Get-ChildItem -Path $skillPath -Recurse -File
        foreach ($file in $files) {
            # Calculate relative path from parent and normalize to forward slashes
            $relativePath = $file.FullName.Substring($parentDir.Length + 1) -replace '\\', '/'
            $entry = $zip.CreateEntry($relativePath, [System.IO.Compression.CompressionLevel]::Optimal)

            # Write file contents into zip entry
            $entryStream = $entry.Open()
            try {
                $fileStream = [System.IO.File]::OpenRead($file.FullName)
                try {
                    $fileStream.CopyTo($entryStream)
                }
                finally {
                    $fileStream.Close()
                }
            }
            finally {
                $entryStream.Close()
            }

            Write-Host "  Added: $relativePath"
        }

        $zip.Dispose()

        Write-Host ""
        Write-Host "✅ Successfully packaged skill to: $skillFilename"
        return $skillFilename
    }
    catch {
        if ($zip) { $zip.Dispose() }
        Write-Host "❌ Error creating .skill file: $_"
        return $null
    }
}

# Main execution
Write-Host "📦 Packaging skill: $SkillFolder"
if ($OutputDirectory) {
    Write-Host "   Output directory: $OutputDirectory"
}
Write-Host ""

$result = New-SkillPackage -SkillPath $SkillFolder -OutDir $OutputDirectory

if ($result) {
    exit 0
}
else {
    exit 1
}
