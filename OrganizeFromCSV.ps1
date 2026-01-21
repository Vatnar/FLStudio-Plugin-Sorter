$ValidDb = $false
while (-not $ValidDb) {
    $InputDbPath = (Read-Host "`nEnter the path to your FL Studio 'Plugin database' folder").Trim('"')
    if (Test-Path -Path (Join-Path $InputDbPath "Installed")) {
        $PluginDbPath = $InputDbPath
        $InstalledPath = Join-Path $PluginDbPath "Installed"
        $ValidDb = $true
    } else {
        Write-Host "Invalid Path! Ensure this folder contains the 'Installed' directory." -ForegroundColor Red
    }
}

# 2. Cleanup Prompt
$Cleanup = Read-Host "`nWould you like to empty 'Effects' and 'Generators' before starting? (Y/N)`n(This prevents duplicates. The 'Installed' folder will NOT be affected.)"
if ($Cleanup.Trim().ToLower() -eq 'y') {
    Write-Host "Cleaning Effects and Generators folders..." -ForegroundColor Yellow
    foreach ($Folder in "Effects", "Generators") {
        $TargetPath = Join-Path $PluginDbPath $Folder
        if (Test-Path $TargetPath) {
            Get-ChildItem -Path $TargetPath | Remove-Item -Recurse -Force
        }
    }
}

# 3. Locate the CSV
$ValidCsv = $false
while (-not $ValidCsv) {
    $InputCsvPath = (Read-Host "`nEnter the full path to your mapping CSV").Trim('"')
    if (Test-Path -Path $InputCsvPath -PathType Leaf) {
        $CsvPath = $InputCsvPath
        $ValidCsv = $true
    } else {
        Write-Host "CSV not found at that location. Please try again." -ForegroundColor Red
    }
}

$Mappings = Import-Csv -Path $CsvPath
$ProcessedCount = 0
$SkippedNoMapping = @()
$SkippedNoSource = @()

Write-Host "`nBeginning placement..." -ForegroundColor Cyan

foreach ($Row in $Mappings) {
    $PluginName = $Row.Name
    
    # Check for missing mapping
    if ([string]::IsNullOrWhiteSpace($Row.TargetPaths)) {
        $SkippedNoMapping += $PluginName
        continue
    }

    $TargetPaths = $Row.TargetPaths -split ";"
    
    
    $SourceFiles = Get-ChildItem -Path $InstalledPath -Filter $PluginName -Recurse
    
    if ($SourceFiles) {
        $SourceDir = $SourceFiles[0].DirectoryName
        $BaseName = [System.IO.Path]::GetFileNameWithoutExtension($PluginName)
        $Extensions = @(".fst", ".nfo", ".png")
        
        foreach ($Path in $TargetPaths) {
            $FullDestPath = Join-Path $PluginDbPath $Path.Trim()
            
            if (-not (Test-Path $FullDestPath)) {
                New-Item -ItemType Directory -Path $FullDestPath -Force | Out-Null
            }
            
            foreach ($Ext in $Extensions) {
                $FileName = "$BaseName$Ext"
                $SrcFile = Join-Path $SourceDir $FileName
                
                if (Test-Path $SrcFile) {
                    Copy-Item -Path $SrcFile -Destination $FullDestPath -Force
                }
            }
        }
        $ProcessedCount++
        Write-Host "Processed: $PluginName" -ForegroundColor Green
    } else {
        $SkippedNoSource += $PluginName
        Write-Warning " .fst .nfo .png not found in 'Installed' for: $PluginName"
    }
}


Write-Host "`n"("=" * 30) -ForegroundColor Cyan
Write-Host "      ORGANIZATION SUMMARY" -ForegroundColor Cyan
Write-Host ("=" * 30) -ForegroundColor Cyan
Write-Host "Successfully Processed: $ProcessedCount" -ForegroundColor Green

if ($SkippedNoSource.Count -gt 0) {
    Write-Host "Source Missing in 'Installed': $($SkippedNoSource.Count)" -ForegroundColor Red
}

if ($SkippedNoMapping.Count -gt 0) {
    Write-Host "Skipped (No Mapping Defined): $($SkippedNoMapping.Count)" -ForegroundColor Yellow
    foreach ($Name in $SkippedNoMapping) {
        Write-Host " - ${Name}" -ForegroundColor Gray
    }
}

Write-Host "`nOrganization complete. Restart FL Studio to refresh the browser." -ForegroundColor Cyan