function Get-SafePath {
    param([string]$Path)
    $Clean = $Path.Trim('"').Trim()
    return [System.IO.Path]::GetFullPath($Clean)
}

$ValidPath = $false
while (-not $ValidPath) {
    $RawDbPath = Read-Host "`nEnter the path to your FL Studio 'Plugin database' folder"
    try {
        $PluginDbPath = Get-SafePath $RawDbPath
        if (Test-Path -Path (Join-Path $PluginDbPath "Installed")) {
            $InstalledPath = Join-Path $PluginDbPath "Installed"
            $ValidPath = $true
        } else {
            Write-Host "Invalid Path! Ensure 'Installed' exists inside." -ForegroundColor Red
        }
    } catch { Write-Host "Invalid path format." -ForegroundColor Red }
}

$RawCsvPath = Read-Host "`nWhere should the CSV be saved/updated?"
$OutputCsv = Get-SafePath $RawCsvPath
if (-not $OutputCsv.EndsWith(".csv")) { $OutputCsv += ".csv" }

$EnableGuessing = (Read-Host "`nAttempt to 'guess' categories for new plugins? (Y/N)").Trim().ToLower() -eq 'y'

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
    $name = $File.Name
    $paths = @()

    # Vendor Detection
    if ($File.FullName -match "Installed\\(Effects|Generators)\\VST3\\") {
        $vendor = $File.Directory.Name
        $paths += "Effects\Vendors\$vendor"
    }

    # --- Categorization Rules ---
    
    # Top-Level Exceptions
    if ($name -match "Airwindows") { $paths += "Airwindows" }

    # EQ & Filters
    if ($name -match "Pro-Q|Parametric EQ 2|7 Band|Fast LP|Filter|Free Filter|Equalizer|Match EQ|Stem EQ|Simplon|Slice EQ|Carve EQ") { $paths += "Effects\EQ\Surgical" }
    elseif ($name -match "Vintage EQ|Sky Blue|EQUO|Bass Boost|3-Band EQ|MBassador|SubBass Doctor") { $paths += "Effects\EQ\Character" }
    elseif ($name -match "Dynamic EQ|Shade|Morph EQ|Stabilizer|Clarity") { $paths += "Effects\EQ\Dynamic" }
    elseif ($name -match "Love Philter|Volcano|Rift Filter|Comb Filter|Formant Filter|Ladder Filter|Nonlinear Filter|Hybrid Filter|Filter Table") { $paths += "Effects\Filters\Creative" }

    # Dynamics
    if ($name -match "Clipper") { $paths += "Effects\Dynamics\Clippers" }
    elseif ($name -match "Multiband|Pro-MB|The King|MB") { $paths += "Effects\Dynamics\Compressors\Multi-Band" }
    elseif ($name -match "Compressor|Pro-C|Compactor|Dynamics|Soundgoodizer|Vocal Compressor") { $paths += "Effects\Dynamics\Compressors\Single-Band" }
    elseif ($name -match "Limiter|Maximizer|LoudMax") { $paths += "Effects\Dynamics\Limiters" }
    elseif ($name -match "Gate") { $paths += "Effects\Dynamics\Gates" }
    elseif ($name -match "Transient") { $paths += "Effects\Dynamics\Transient Shapers" }

    # Distortion
    if ($name -match "Saturn|TAIP|Tape|Exciter|Origin|Emphasis|Faturator") { $paths += "Effects\Distortion\Saturation" }
    elseif ($name -match "Bitcrush|Lofinity|VHS|Squeeze") { $paths += "Effects\Distortion\Lo-Fi" }
    elseif ($name -match "Distortion|Rift|Blood Overdrive|Fast Dist|WaveShaper|Sausage|Aggressor|Disperser|Shaper Table") { $paths += "Effects\Distortion\Aggressive" }

    # Mastering & Vocal
    if ($name -match "Ozone 12|KSHMR Essentials|Soundgoodizer") { $paths += "Effects\Mastering\Finishers" }
    if ($name -match "Newtone|Pitcher|Vocoder|Vocodex|TrapTune|Tune|Vocal|Cleaner") { $paths += "Effects\Vocal" }

    # Spatial
    if ($name -match "Reeverb|Reverb|Crystalline|Convolver|Supermassive") { $paths += "Effects\Spatial\Reverb" }
    elseif ($name -match "Delay|Echo|Comeback Kid") { $paths += "Effects\Spatial\Delay" }
    if ($name -match "Stereo|Imager|Width|Spreader|Phase Inverter") { $paths += "Effects\Spatial\Imaging and Stereo" }
    if ($name -match "PanOMatic|Panner|Rotary") { $paths += "Effects\Spatial\Panning" }

    # Utilities
    if ($name -match "Wave Candy|Meter|Spectroman|Clock|Tuner|Edison") { $paths += "Effects\Utilities\Analyzers" }
    elseif ($name -match "Patcher|Send|Mixer|Surface|Balance|Center|Multipass|Snap Heap") { $paths += "Effects\Utilities\Routing" }
    elseif ($name -match "Controller|Envelope|Mapper|Splitter|Scaler|Script|Sequencer") { $paths += "Effects\Utilities\Controllers" }

    # Generators
    if ($name -match "3x Osc|Sawer|JUPITER|Kepler|MiniSynth|SimSynth|Transistor Bass") { $paths += "Generators\Synths\Analog" }
    elseif ($name -match "Sytrus|Serum|DX10|Harmor|Harmless|Ogun|Toxic|Twin|Electra|Phase Plant|Babylon") { $paths += "Generators\Synths\Digital" }
    elseif ($name -match "FLEX|DirectWave|Sakura|MSoundFactory|UVIWorkstation") { $paths += "Generators\Synths\Sample-Based" }

    return ($paths | Select-Object -Unique) -join ";"
}

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

if ($NewEntries.Count -gt 0) {
    $NewEntries | Export-Csv -Path $OutputCsv -Append -NoTypeInformation -Encoding utf8
    Write-Host "`nComplete! $($NewEntries.Count) new entries added." -ForegroundColor Green
} else {
    Write-Host "`nNo new plugins found." -ForegroundColor Yellow
}