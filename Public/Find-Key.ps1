function Find-Key {
    <#
    .SYNOPSIS
        Detects the musical key of audio files and logs the results to a file.

    .DESCRIPTION
        Processes MP3 or FLAC audio files to detect their musical key using keyfinder-cli.exe.
        Outputs the results to a specified log file in comma-delimited format: "filepath,key"

    .PARAMETER Path
        Path to the input audio file(s) (MP3 or FLAC). Supports pipeline input.

    .PARAMETER Output
        Path to the output log file where results will be written.

    .EXAMPLE
        Find-Key -Path "song.mp3" -Output "keys.log"

    .EXAMPLE
        Get-ChildItem *.mp3 | Find-Key -Output "keys.log"

    .EXAMPLE
        Find-Key -Path @("song1.mp3", "song2.flac") -Output "keys.log"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('FullName')]
        [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
        [string[]]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Output
    )

    begin {
        Write-Verbose "Starting key detection process"

        # Verify keyfinder.exe exists
        if (-not (Test-Path $script:KeyChangerConfig.KeyFinderExe)) {
            throw "keyfinder-cli.exe not found at: $($script:KeyChangerConfig.KeyFinderExe)"
        }

        # Initialize output file
        if (Test-Path $Output) {
            Remove-Item $Output -Force
        }
        New-Item -Path $Output -ItemType File -Force | Out-Null
    }

    process {
        foreach ($filePath in $Path) {
            try {
                # Resolve full path
                $resolvedPath = (Resolve-Path -LiteralPath $filePath).Path

                # Get file info
                $fileInfo = Get-Item $resolvedPath
                $extension = $fileInfo.Extension.ToLower()

                # Validate file format
                if ($extension -notin @('.mp3', '.flac')) {
                    Write-Warning "Skipping unsupported file format '$extension': $resolvedPath"
                    continue
                }

                Write-Host "Processing: $($fileInfo.Name)" -ForegroundColor Cyan

                # Create temp WAV file
                $tempGuid = [Guid]::NewGuid().ToString()
                $tempWav = Join-Path $script:KeyChangerConfig.TempDirectory "${tempGuid}_temp.wav"

                try {
                    # Convert to WAV using ffmpeg
                    Write-Verbose "Converting to WAV for key detection..."
                    $ffmpegArgs = @(
                        '-i', $resolvedPath,
                        '-acodec', 'pcm_s16le',
                        '-ar', '44100',
                        '-ac', '2',
                        $tempWav,
                        '-y'
                    )

                    $result = & $script:KeyChangerConfig.FfmpegExe @ffmpegArgs 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        throw "FFmpeg conversion failed for $resolvedPath"
                    }

                    if (-not (Test-Path $tempWav)) {
                        throw "Failed to create temporary WAV file for $resolvedPath"
                    }

                    # Detect key using keyfinder-cli.exe
                    Write-Verbose "Detecting key..."
                    $keyFinderOutput = & $script:KeyChangerConfig.KeyFinderExe $tempWav 2>&1
                    $outputString = ($keyFinderOutput | Out-String).Trim()

                    # Parse detected key
                    $detectedKey = $null
                    if ($outputString -match '^([A-G][#b]?)$') {
                        $detectedKey = $matches[1]
                    }
                    elseif ($outputString -match 'Key:\s*([A-G][#b]?)') {
                        $detectedKey = $matches[1]
                    }
                    elseif ($outputString -match '([A-G][#b]?)\s*(?:major|minor|maj|min)') {
                        $detectedKey = $matches[1]
                    }
                    elseif ($outputString -match 'Samples loaded:\s*\d+\s*([A-G][#b]?)') {
                        $detectedKey = $matches[1]
                    }
                    elseif ($outputString -match '\b([A-G][#b]?)\b') {
                        $detectedKey = $matches[1]
                    }

                    if ($detectedKey) {
                        Write-Host "  Detected key: $detectedKey" -ForegroundColor Green
                        # Write to output file
                        "$resolvedPath,$detectedKey" | Out-File -FilePath $Output -Append -Encoding UTF8
                    }
                    else {
                        Write-Host "  Key detection failed for: $($fileInfo.Name)" -ForegroundColor Yellow
                        # Write with unknown key
                        "$resolvedPath,Unknown" | Out-File -FilePath $Output -Append -Encoding UTF8
                    }
                }
                finally {
                    # Cleanup temp file
                    if (Test-Path $tempWav) {
                        Remove-Item $tempWav -Force -ErrorAction SilentlyContinue
                    }
                }
            }
            catch {
                Write-Error "Failed to process $filePath`: $_"
                # Write error to output
                "$resolvedPath,Error" | Out-File -FilePath $Output -Append -Encoding UTF8
            }
        }
    }

    end {
        Write-Host "Key detection complete. Results saved to: $Output" -ForegroundColor Green
    }
}