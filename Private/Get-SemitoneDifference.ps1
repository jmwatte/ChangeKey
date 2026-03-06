function Get-SemitoneDifference {
    <#
    .SYNOPSIS
        Calculates the semitone difference between two musical keys.

    .DESCRIPTION
        Internal helper function that calculates how many semitones apart two keys are.
        Handles enharmonic equivalents (e.g., C# and Db are the same).
        Supports Low- register keys (e.g., Low-C, Low-Bb) which are one octave (12 semitones) below normal.
        When both keys are in the same register, returns the shortest path (-6 to +6).
        When keys are in different registers, returns the full distance (octave jump is intentional).

    .PARAMETER SourceKey
        The starting musical key. Supports normal keys (C, Bb) and low register keys (Low-C, Low-Bb).

    .PARAMETER TargetKey
        The destination musical key. Supports normal keys (C, Bb) and low register keys (Low-C, Low-Bb).

    .EXAMPLE
        Get-SemitoneDifference -SourceKey "Bb" -TargetKey "C"
        # Returns 2

    .EXAMPLE
        Get-SemitoneDifference -SourceKey "Low-C" -TargetKey "C"
        # Returns 12 (one octave up)

    .EXAMPLE
        Get-SemitoneDifference -SourceKey "C" -TargetKey "Low-C"
        # Returns -12 (one octave down)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourceKey,

        [Parameter(Mandatory = $true)]
        [string]$TargetKey
    )

    # Parse Low- register prefix
    $sourceIsLow = $SourceKey.StartsWith('Low-')
    $targetIsLow = $TargetKey.StartsWith('Low-')
    $sourceBase = if ($sourceIsLow) { $SourceKey.Substring(4) } else { $SourceKey }
    $targetBase = if ($targetIsLow) { $TargetKey.Substring(4) } else { $TargetKey }

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

    # Calculate absolute positions (Low register = base position - 12)
    $SourcePosition = $KeyMap[$sourceBase]
    if ($sourceIsLow) { $SourcePosition -= 12 }

    $TargetPosition = $KeyMap[$targetBase]
    if ($targetIsLow) { $TargetPosition -= 12 }

    $Difference = $TargetPosition - $SourcePosition

    # Only normalize to shortest path when both keys are in the same register
    # Cross-register shifts are intentional octave jumps — don't normalize
    if ($sourceIsLow -eq $targetIsLow) {
        if ($Difference -gt 6) {
            $Difference = $Difference - 12
        }
        elseif ($Difference -lt -6) {
            $Difference = $Difference + 12
        }
    }

    return $Difference
}
