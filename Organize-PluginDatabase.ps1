function Get-SafePath {
    param([string]$Path)
    $Clean = $Path.Trim('"').Trim()
    return [System.IO.Path]::GetFullPath($Clean)
}

$ValidDb = $false
while (-not $ValidDb) {
    $RawDbPath = Read-Host "`nEnter the path to your FL Studio 'Plugin database' folder"
    try {
        $PluginDbPath = Get-SafePath $RawDbPath
        if (Test-Path -Path (Join-Path $PluginDbPath "Installed")) {
            $InstalledPath = Join-Path $PluginDbPath "Installed"
            $ValidDb = $true
        } else {
            Write-Host "Invalid Path!" -ForegroundColor Red
        }
    } catch { Write-Host "Invalid path format." -ForegroundColor Red }
}


if ((Read-Host "`nEmpty 'Effects' and 'Generators' first? (Y/N)").Trim().ToLower() -eq 'y') {
    foreach ($Folder in "Effects", "Generators") {
        $Path = Join-Path $PluginDbPath $Folder
        if (Test-Path $Path) { Get-ChildItem $Path | Remove-Item -Recurse -Force }
    }
}

$RawCsvPath = Read-Host "`nEnter the full path to your mapping CSV"
$CsvPath = Get-SafePath $RawCsvPath

if (-not (Test-Path $CsvPath)) {
    Write-Error "CSV not found at $CsvPath"; exit
}

$Mapping = Import-Csv $CsvPath
$Extensions = ".fst", ".nfo", ".png"

foreach ($Row in $Mapping) {
    $PluginName = $Row.Name
    $BaseName = [System.IO.Path]::GetFileNameWithoutExtension($PluginName)
    $TargetPaths = $Row.TargetPaths -split ";"
    
    $SourceFile = Get-ChildItem -Path $InstalledPath -Filter "$BaseName.fst" -Recurse | Select-Object -First 1
    
    if ($SourceFile) {
        $SourceDir = $SourceFile.DirectoryName
        foreach ($Path in $TargetPaths) {
            if ([string]::IsNullOrWhiteSpace($Path)) { continue }
            $FullDestPath = Join-Path $PluginDbPath $Path.Trim()
            
            if (-not (Test-Path $FullDestPath)) { 
                New-Item -ItemType Directory -Path $FullDestPath -Force | Out-Null 
            }
            
            foreach ($Ext in $Extensions) {
                $SrcFile = Join-Path $SourceDir "$BaseName$Ext"
                if (Test-Path $SrcFile) { Copy-Item $SrcFile $FullDestPath -Force }
            }
        }
        Write-Host "Organized: $PluginName" -ForegroundColor Green
    }
}