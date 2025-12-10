function Set-KeyChangerConfig {
    <#
    .SYNOPSIS
        Configures the KeyChanger module settings.

    .DESCRIPTION
        Sets the paths to external audio processing tools and other configuration options
        for the KeyChanger module.

    .PARAMETER KeyFinderExe
        Path to the keyfinder.exe executable.

    .PARAMETER SoundStretchExe
        Path to the soundstretch.exe executable.

    .PARAMETER FfmpegExe
        Path to the ffmpeg executable (or just 'ffmpeg' if in PATH).

    .PARAMETER TempDirectory
        Directory to use for temporary files during processing.

    .EXAMPLE
        Set-KeyChangerConfig -FfmpegExe "C:\Tools\ffmpeg.exe"

    .EXAMPLE
        Set-KeyChangerConfig -TempDirectory "D:\Temp"
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string]$KeyFinderExe,

        [Parameter()]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string]$SoundStretchExe,

        [Parameter()]
        [string]$FfmpegExe,

        [Parameter()]
        [ValidateScript({ Test-Path $_ -PathType Container })]
        [string]$TempDirectory
    )

    if ($PSBoundParameters.ContainsKey('KeyFinderExe')) {
        $script:KeyChangerConfig.KeyFinderExe = $KeyFinderExe
        Write-Verbose "KeyFinder set to: $KeyFinderExe"
    }

    if ($PSBoundParameters.ContainsKey('SoundStretchExe')) {
        $script:KeyChangerConfig.SoundStretchExe = $SoundStretchExe
        Write-Verbose "SoundStretch set to: $SoundStretchExe"
    }

    if ($PSBoundParameters.ContainsKey('FfmpegExe')) {
        $script:KeyChangerConfig.FfmpegExe = $FfmpegExe
        Write-Verbose "FFmpeg set to: $FfmpegExe"
    }

    if ($PSBoundParameters.ContainsKey('TempDirectory')) {
        $script:KeyChangerConfig.TempDirectory = $TempDirectory
        Write-Verbose "Temp directory set to: $TempDirectory"
    }

    # Return current configuration
    [PSCustomObject]$script:KeyChangerConfig
}
