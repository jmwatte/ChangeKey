function Get-SemitoneDifference {
    <#
    .SYNOPSIS
        Calculates the semitone difference between two musical keys.

    .DESCRIPTION
        Internal helper function that calculates how many semitones apart two keys are.
        Handles enharmonic equivalents (e.g., C# and Db are the same).

    .PARAMETER SourceKey
        The starting musical key.

    .PARAMETER TargetKey
        The destination musical key.

    .EXAMPLE
        Get-SemitoneDifference -SourceKey "Bb" -TargetKey "C"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourceKey,

        [Parameter(Mandatory = $true)]
        [string]$TargetKey
    )

    # Map all keys to their chromatic scale position (0-11)
    $KeyMap = @{
        'C' = 0
        'C#' = 1; 'Db' = 1
        'D' = 2
        'D#' = 3; 'Eb' = 3
        'E' = 4
        'F' = 5
        'F#' = 6; 'Gb' = 6
        'G' = 7
        'G#' = 8; 'Ab' = 8
        'A' = 9
        'A#' = 10; 'Bb' = 10
        'B' = 11
    }

    $SourcePosition = $KeyMap[$SourceKey]
    $TargetPosition = $KeyMap[$TargetKey]

    # Calculate shortest distance (can go up or down)
    $Difference = $TargetPosition - $SourcePosition
    
    # Normalize to -6 to +6 range (shortest path on chromatic circle)
    if ($Difference -gt 6) {
        $Difference = $Difference - 12
    }
    elseif ($Difference -lt -6) {
        $Difference = $Difference + 12
    }

    return $Difference
}
