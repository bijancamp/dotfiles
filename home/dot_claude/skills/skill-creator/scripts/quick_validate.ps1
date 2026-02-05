#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Quick validation script for skills - minimal version

.DESCRIPTION
    Validates a skill directory by checking SKILL.md existence, frontmatter format,
    required fields, naming conventions, and description constraints.

.PARAMETER SkillPath
    Path to the skill directory to validate.

.EXAMPLE
    .\quick_validate.ps1 path\to\skill

.NOTES
    Can be dot-sourced by other scripts to import the Validate-Skill function:
        . "$PSScriptRoot\quick_validate.ps1"
#>

$ErrorActionPreference = "Stop"

function Validate-Skill {
    <#
    .SYNOPSIS
        Validates a skill directory and returns a result object.
    .OUTPUTS
        PSCustomObject with Valid (bool) and Message (string) properties.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$SkillPath
    )

    if (-not (Test-Path $SkillPath)) {
        return [PSCustomObject]@{ Valid = $false; Message = "Skill directory not found: $SkillPath" }
    }
    $skillDir = (Get-Item $SkillPath).FullName

    # Check SKILL.md exists
    $skillMdPath = Join-Path $skillDir "SKILL.md"
    if (-not (Test-Path $skillMdPath)) {
        return [PSCustomObject]@{ Valid = $false; Message = "SKILL.md not found" }
    }

    # Read and validate frontmatter
    $content = Get-Content -Path $skillMdPath -Raw
    if (-not $content.StartsWith("---")) {
        return [PSCustomObject]@{ Valid = $false; Message = "No YAML frontmatter found" }
    }

    # Extract frontmatter
    if ($content -notmatch '(?s)^---\r?\n(.*?)\r?\n---') {
        return [PSCustomObject]@{ Valid = $false; Message = "Invalid frontmatter format" }
    }
    $frontmatterText = $Matches[1]

    # Parse YAML frontmatter using regex for top-level keys
    $frontmatter = @{}
    foreach ($line in ($frontmatterText -split '\r?\n')) {
        if ($line -match '^([^\s:]+):\s*(.*)$') {
            $frontmatter[$Matches[1]] = $Matches[2].Trim()
        }
    }

    if ($frontmatter.Count -eq 0) {
        return [PSCustomObject]@{ Valid = $false; Message = "Frontmatter must be a YAML dictionary" }
    }

    # Define allowed properties
    $allowedProperties = @('name', 'description', 'license', 'allowed-tools', 'metadata')

    # Check for unexpected properties
    $unexpectedKeys = @($frontmatter.Keys | Where-Object { $_ -notin $allowedProperties }) | Sort-Object
    if ($unexpectedKeys.Count -gt 0) {
        $unexpectedList = $unexpectedKeys -join ', '
        $allowedList = ($allowedProperties | Sort-Object) -join ', '
        return [PSCustomObject]@{
            Valid   = $false
            Message = "Unexpected key(s) in SKILL.md frontmatter: $unexpectedList. Allowed properties are: $allowedList"
        }
    }

    # Check required fields
    if (-not $frontmatter.ContainsKey('name')) {
        return [PSCustomObject]@{ Valid = $false; Message = "Missing 'name' in frontmatter" }
    }
    if (-not $frontmatter.ContainsKey('description')) {
        return [PSCustomObject]@{ Valid = $false; Message = "Missing 'description' in frontmatter" }
    }

    # Validate name
    $name = $frontmatter['name'].Trim()
    if ($name) {
        if ($name -notmatch '^[a-z0-9-]+$') {
            return [PSCustomObject]@{
                Valid   = $false
                Message = "Name '$name' should be hyphen-case (lowercase letters, digits, and hyphens only)"
            }
        }
        if ($name.StartsWith('-') -or $name.EndsWith('-') -or $name.Contains('--')) {
            return [PSCustomObject]@{
                Valid   = $false
                Message = "Name '$name' cannot start/end with hyphen or contain consecutive hyphens"
            }
        }
        if ($name.Length -gt 64) {
            return [PSCustomObject]@{
                Valid   = $false
                Message = "Name is too long ($($name.Length) characters). Maximum is 64 characters."
            }
        }
    }

    # Validate description
    $description = $frontmatter['description'].Trim()
    if ($description) {
        if ($description.Contains('<') -or $description.Contains('>')) {
            return [PSCustomObject]@{
                Valid   = $false
                Message = "Description cannot contain angle brackets (< or >)"
            }
        }
        if ($description.Length -gt 1024) {
            return [PSCustomObject]@{
                Valid   = $false
                Message = "Description is too long ($($description.Length) characters). Maximum is 1024 characters."
            }
        }
    }

    return [PSCustomObject]@{ Valid = $true; Message = "Skill is valid!" }
}

# Standalone execution guard: only run main block when invoked directly (not dot-sourced)
if ($MyInvocation.InvocationName -ne '.') {
    if ($args.Count -ne 1) {
        Write-Host "Usage: quick_validate.ps1 <skill_directory>"
        exit 1
    }

    $result = Validate-Skill -SkillPath $args[0]
    Write-Host $result.Message
    if ($result.Valid) { exit 0 } else { exit 1 }
}
