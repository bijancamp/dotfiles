#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Skill Initializer - Creates a new skill from template

.DESCRIPTION
    Creates a new skill directory with a SKILL.md template and example resource
    directories (scripts/, references/, assets/).

.PARAMETER SkillName
    Name of the skill (hyphen-case, e.g. 'my-new-skill').

.PARAMETER Path
    Directory where the skill folder will be created.

.EXAMPLE
    .\init_skill.ps1 my-new-skill -Path skills/public

.EXAMPLE
    .\init_skill.ps1 my-api-helper -Path skills/private
#>

param(
    [Parameter(Mandatory, Position = 0)]
    [string]$SkillName,

    [Parameter(Mandatory)]
    [string]$Path
)

$ErrorActionPreference = "Stop"

function ConvertTo-TitleCase {
    param([string]$Name)
    ($Name -split '-' | ForEach-Object {
        if ($_.Length -gt 0) { $_.Substring(0, 1).ToUpper() + $_.Substring(1) } else { $_ }
    }) -join ' '
}

function Initialize-Skill {
    param(
        [string]$SkillName,
        [string]$OutputPath
    )

    $skillDir = Join-Path (Resolve-Path $OutputPath) $SkillName

    # Check if directory already exists
    if (Test-Path $skillDir) {
        Write-Host "❌ Error: Skill directory already exists: $skillDir"
        return $null
    }

    # Create skill directory
    try {
        New-Item -ItemType Directory -Path $skillDir -Force | Out-Null
        Write-Host "✅ Created skill directory: $skillDir"
    }
    catch {
        Write-Host "❌ Error creating directory: $_"
        return $null
    }

    # Create SKILL.md from template
    $skillTitle = ConvertTo-TitleCase $SkillName

    $skillContent = @"
---
name: $SkillName
description: [TODO: Complete and informative explanation of what the skill does and when to use it. Include WHEN to use this skill - specific scenarios, file types, or tasks that trigger it.]
---

# $skillTitle

## Overview

[TODO: 1-2 sentences explaining what this skill enables]

## Structuring This Skill

[TODO: Choose the structure that best fits this skill's purpose. Common patterns:

**1. Workflow-Based** (best for sequential processes)
- Works well when there are clear step-by-step procedures
- Example: DOCX skill with "Workflow Decision Tree" → "Reading" → "Creating" → "Editing"
- Structure: ## Overview → ## Workflow Decision Tree → ## Step 1 → ## Step 2...

**2. Task-Based** (best for tool collections)
- Works well when the skill offers different operations/capabilities
- Example: PDF skill with "Quick Start" → "Merge PDFs" → "Split PDFs" → "Extract Text"
- Structure: ## Overview → ## Quick Start → ## Task Category 1 → ## Task Category 2...

**3. Reference/Guidelines** (best for standards or specifications)
- Works well for brand guidelines, coding standards, or requirements
- Example: Brand styling with "Brand Guidelines" → "Colors" → "Typography" → "Features"
- Structure: ## Overview → ## Guidelines → ## Specifications → ## Usage...

**4. Capabilities-Based** (best for integrated systems)
- Works well when the skill provides multiple interrelated features
- Example: Product Management with "Core Capabilities" → numbered capability list
- Structure: ## Overview → ## Core Capabilities → ### 1. Feature → ### 2. Feature...

Patterns can be mixed and matched as needed. Most skills combine patterns (e.g., start with task-based, add workflow for complex operations).

Delete this entire "Structuring This Skill" section when done - it's just guidance.]

## [TODO: Replace with the first main section based on chosen structure]

[TODO: Add content here. See examples in existing skills:
- Code samples for technical skills
- Decision trees for complex workflows
- Concrete examples with realistic user requests
- References to scripts/templates/references as needed]

## Resources

This skill includes example resource directories that demonstrate how to organize different types of bundled resources:

### scripts/
Executable code (Python/Bash/etc.) that can be run directly to perform specific operations.

**Examples from other skills:**
- PDF skill: ``fill_fillable_fields.py``, ``extract_form_field_info.py`` - utilities for PDF manipulation
- DOCX skill: ``document.py``, ``utilities.py`` - Python modules for document processing

**Appropriate for:** Python scripts, shell scripts, or any executable code that performs automation, data processing, or specific operations.

**Note:** Scripts may be executed without loading into context, but can still be read by Claude for patching or environment adjustments.

### references/
Documentation and reference material intended to be loaded into context to inform Claude's process and thinking.

**Examples from other skills:**
- Product management: ``communication.md``, ``context_building.md`` - detailed workflow guides
- BigQuery: API reference documentation and query examples
- Finance: Schema documentation, company policies

**Appropriate for:** In-depth documentation, API references, database schemas, comprehensive guides, or any detailed information that Claude should reference while working.

### assets/
Files not intended to be loaded into context, but rather used within the output Claude produces.

**Examples from other skills:**
- Brand styling: PowerPoint template files (.pptx), logo files
- Frontend builder: HTML/React boilerplate project directories
- Typography: Font files (.ttf, .woff2)

**Appropriate for:** Templates, boilerplate code, document templates, images, icons, fonts, or any files meant to be copied or used in the final output.

---

**Any unneeded directories can be deleted.** Not every skill requires all three types of resources.
"@

    $skillMdPath = Join-Path $skillDir "SKILL.md"
    try {
        Set-Content -Path $skillMdPath -Value $skillContent -NoNewline
        Write-Host "✅ Created SKILL.md"
    }
    catch {
        Write-Host "❌ Error creating SKILL.md: $_"
        return $null
    }

    # Create resource directories with example files
    try {
        # Create scripts/ directory with example script
        $scriptsDir = Join-Path $skillDir "scripts"
        New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null

        $exampleScriptContent = @"
#!/usr/bin/env python3
"""
Example helper script for $SkillName

This is a placeholder script that can be executed directly.
Replace with actual implementation or delete if not needed.

Example real scripts from other skills:
- pdf/scripts/fill_fillable_fields.py - Fills PDF form fields
- pdf/scripts/convert_pdf_to_images.py - Converts PDF pages to images
"""

def main():
    print("This is an example script for $SkillName")
    # TODO: Add actual script logic here
    # This could be data processing, file conversion, API calls, etc.

if __name__ == "__main__":
    main()
"@
        $exampleScriptPath = Join-Path $scriptsDir "example.py"
        Set-Content -Path $exampleScriptPath -Value $exampleScriptContent -NoNewline
        Write-Host "✅ Created scripts/example.py"

        # Create references/ directory with example reference doc
        $referencesDir = Join-Path $skillDir "references"
        New-Item -ItemType Directory -Path $referencesDir -Force | Out-Null

        $exampleReferenceContent = @"
# Reference Documentation for $skillTitle

This is a placeholder for detailed reference documentation.
Replace with actual reference content or delete if not needed.

Example real reference docs from other skills:
- product-management/references/communication.md - Comprehensive guide for status updates
- product-management/references/context_building.md - Deep-dive on gathering context
- bigquery/references/ - API references and query examples

## When Reference Docs Are Useful

Reference docs are ideal for:
- Comprehensive API documentation
- Detailed workflow guides
- Complex multi-step processes
- Information too lengthy for main SKILL.md
- Content that's only needed for specific use cases

## Structure Suggestions

### API Reference Example
- Overview
- Authentication
- Endpoints with examples
- Error codes
- Rate limits

### Workflow Guide Example
- Prerequisites
- Step-by-step instructions
- Common patterns
- Troubleshooting
- Best practices
"@
        $exampleReferencePath = Join-Path $referencesDir "api_reference.md"
        Set-Content -Path $exampleReferencePath -Value $exampleReferenceContent -NoNewline
        Write-Host "✅ Created references/api_reference.md"

        # Create assets/ directory with example asset placeholder
        $assetsDir = Join-Path $skillDir "assets"
        New-Item -ItemType Directory -Path $assetsDir -Force | Out-Null

        $exampleAssetContent = @"
# Example Asset File

This placeholder represents where asset files would be stored.
Replace with actual asset files (templates, images, fonts, etc.) or delete if not needed.

Asset files are NOT intended to be loaded into context, but rather used within
the output Claude produces.

Example asset files from other skills:
- Brand guidelines: logo.png, slides_template.pptx
- Frontend builder: hello-world/ directory with HTML/React boilerplate
- Typography: custom-font.ttf, font-family.woff2
- Data: sample_data.csv, test_dataset.json

## Common Asset Types

- Templates: .pptx, .docx, boilerplate directories
- Images: .png, .jpg, .svg, .gif
- Fonts: .ttf, .otf, .woff, .woff2
- Boilerplate code: Project directories, starter files
- Icons: .ico, .svg
- Data files: .csv, .json, .xml, .yaml

Note: This is a text placeholder. Actual assets can be any file type.
"@
        $exampleAssetPath = Join-Path $assetsDir "example_asset.txt"
        Set-Content -Path $exampleAssetPath -Value $exampleAssetContent -NoNewline
        Write-Host "✅ Created assets/example_asset.txt"
    }
    catch {
        Write-Host "❌ Error creating resource directories: $_"
        return $null
    }

    # Print next steps
    Write-Host ""
    Write-Host "✅ Skill '$SkillName' initialized successfully at $skillDir"
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "1. Edit SKILL.md to complete the TODO items and update the description"
    Write-Host "2. Customize or delete the example files in scripts/, references/, and assets/"
    Write-Host "3. Run the validator when ready to check the skill structure"

    return $skillDir
}

# Main execution
Write-Host "🚀 Initializing skill: $SkillName"
Write-Host "   Location: $Path"
Write-Host ""

$result = Initialize-Skill -SkillName $SkillName -OutputPath $Path

if ($result) {
    exit 0
}
else {
    exit 1
}
