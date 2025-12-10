# KeyChanger PowerShell Module
# Audio pitch/key changing tool

# Module variables
$ModuleRoot = $PSScriptRoot
$script:KeyChangerConfig = @{
    KeyFinderExe = Join-Path $ModuleRoot 'external programs\Release\keyfinder-cli.exe'
    SoundStretchExe = Join-Path $ModuleRoot 'external programs\soundstretch.exe'
    FfmpegExe = 'ffmpeg' # Assumes ffmpeg is in PATH
    TempDirectory = $env:TEMP
}

# Import private functions
$PrivateFunctions = Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" -ErrorAction SilentlyContinue
foreach ($Function in $PrivateFunctions) {
    . $Function.FullName
}

# Import public functions
$PublicFunctions = Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1" -ErrorAction SilentlyContinue
foreach ($Function in $PublicFunctions) {
    . $Function.FullName
}

# Export public functions
Export-ModuleMember -Function $PublicFunctions.BaseName
