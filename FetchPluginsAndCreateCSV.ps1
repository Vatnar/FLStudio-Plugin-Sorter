$ValidPath = $false
while (-not $ValidPath) {
    $InputDbPath = Read-Host "`nEnter the path to your FL Studio 'Plugin database' folder"
    if (Test-Path -Path (Join-Path $InputDbPath "Installed")) {
        $PluginDbPath = $InputDbPath
        $InstalledPath = Join-Path $PluginDbPath "Installed"
        $ValidPath = $true
    } else {
        Write-Host "Invalid Path! Could not find 'Installed' folder inside that directory." -ForegroundColor Red
    }
}

$OutputCsv = Read-Host "`nWhere should the CSV be saved/updated? (e.g., C:\Users\Me\Desktop\Plugins.csv)"
if (-not $OutputCsv.EndsWith(".csv")) { $OutputCsv += ".csv" }

$GuessResponse = Read-Host "`nShould it be attempted to 'guess' categories for new plugins? (Y/N)"
$EnableGuessing = $GuessResponse.Trim().ToLower() -eq 'y'

# Load existing data
$ExistingNames = @{}
if (Test-Path $OutputCsv) {
    Import-Csv $OutputCsv | ForEach-Object { $ExistingNames[$_.Name] = $true }
} else {
    "Name,TargetPaths" | Out-File $OutputCsv -Encoding utf8
}

function Get-GuessedPath {
    param([System.IO.FileInfo]$File)
    if (-not $EnableGuessing) { return "" }

    $name = $File.Name.ToLower()
    $dir = $File.DirectoryName
    $paths = @()
    $branch = if ($dir -like "*\Effects\*") { "Effects" } else { "Generators" }

    # Vendor Regex Map
    $vendors = @{
        "khs|kilohearts" = "Kilohearts"
        "pro-|saturn|volcano|timeless|twin|simplon|micro|fabfilter" = "FabFilter"
        "valhalla" = "Valhalla"
        "serum|ott" = "Xfer Records"
        "arturia|v-collection|jupiter" = "Arturia"
        "izotope|ozone|neutron|rx" = "iZotope"
        "waves" = "Waves"
        "soundtoys" = "Soundtoys"
        "native instruments|kontakt|reaktor|massive" = "Native Instruments"
        "baby audio" = "Baby Audio"
    }

    foreach ($pattern in $vendors.Keys) {
        if ($name -match $pattern) { 
            $paths += "$branch\Vendors\$($vendors[$pattern])" 
            break 
        }
    }

 	# some guessing, please add a pullrequest if anyone want to make some better guessing
    if ($branch -eq "Effects") {
        if ($name -match "comp|limit|maximus|gate|clipper|pressor") { $paths += "Effects\Dynamics" }
        elseif ($name -match "reverb|delay|space|echo|convolver|ir-") { $paths += "Effects\Spatial" }
        elseif ($name -match "eq|filter|volcano|simplon|cut") { $paths += "Effects\EQ and Filters" }
        elseif ($name -match "dist|shaper|overdrive|saturn|crush|fuzz|amp|drive") { $paths += "Effects\Distortion and Character" }
        elseif ($name -match "chorus|phase|flang|mod|ensemble|tremolo|vibrato") { $paths += "Effects\Modulation" }
        elseif ($name -match "meter|candy|tuner|span|analyzer|visual|scope|loudness") { $paths += "Effects\Utilities and Tools" }
    } else {
        if ($name -match "synth|osc|twin|serum|jupiter|kepler|massive|diva|3x") { $paths += "Generators\Synths" }
        elseif ($name -match "drum|kick|fpc|beat|machine") { $paths += "Generators\Drums" }
        elseif ($name -match "sampler|slice|labs|directwave|kontakt") { $paths += "Generators\Samplers" }
        elseif ($name -match "piano|guitar|bass|strings|brass|keys") { $paths += "Generators\Instruments" }
    }

    return ($paths -join ";")
}

# Scan
Write-Host "`nScanning..." -ForegroundColor Cyan
$AllFstFiles = Get-ChildItem -Path $InstalledPath -Filter *.fst -Recurse
$NewEntries = @()

foreach ($File in $AllFstFiles) {
    if (-not $ExistingNames.ContainsKey($File.Name)) {
        $NewEntries += [PSCustomObject]@{
            Name        = $File.Name
            TargetPaths = Get-GuessedPath -File $File
        }
        $ExistingNames[$File.Name] = $true 
    }
}

# Save and Report
if ($NewEntries.Count -gt 0) {
    $NewEntries | Export-Csv -Path $OutputCsv -Append -NoTypeInformation -Encoding utf8
    Write-Host "`nComplete!" -ForegroundColor Green
    Write-Host "$($NewEntries.Count) new plugins found and appended to: $OutputCsv" -ForegroundColor Yellow

# summary
$GuessedCount = ($NewEntries | Where-Object { $_.TargetPaths -ne "" }).Count
$BlankCount = ($NewEntries | Where-Object { $_.TargetPaths -eq "" }).Count

Write-Host "`nGeneration Summary:" -ForegroundColor Cyan
Write-Host "- Total New Plugins: $($NewEntries.Count)"
Write-Host "- Automatically Categorized: $GuessedCount" -ForegroundColor Green
Write-Host "- Requires Manual Mapping: $BlankCount" -ForegroundColor Yellow

} else {
    Write-Host "`nNo new plugins discovered." -ForegroundColor Green
}