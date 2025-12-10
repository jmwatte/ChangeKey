function Invoke-ChangeKey {
    <#
    .SYNOPSIS
        Converts an audio file to a different musical key.

    .DESCRIPTION
        Processes an MP3 or FLAC audio file and transposes it to the desired musical key.
        The function:
        1. Converts the input file to WAV using ffmpeg
        2. Detects the current key using keyfinder.exe
        3. Calculates the semitone difference
        4. Pitch-shifts the audio using soundstretch.exe
        5. Converts back to the original format using ffmpeg
        6. Saves to the output folder with "_in_[Key]" suffix

    .PARAMETER SourceKey
        The original key of the audio file (optional - if not provided, will attempt auto-detection).

    .PARAMETER InputFile
        Path to the input audio file (MP3 or FLAC).

    .PARAMETER OutputFolder
        Folder where the converted file will be saved.

    .PARAMETER TargetKey
        The desired key for the output file (e.g., 'C', 'D', 'E').

    .PARAMETER Force
        Overwrite the output file if it already exists.

    .EXAMPLE
        Invoke-ChangeKey -InputFile "song.mp3" -OutputFolder "C:\Music\Converted" -TargetKey "C"

    .EXAMPLE
        Invoke-ChangeKey -InputFile "song.flac" -OutputFolder ".\Output" -TargetKey "D"

    .EXAMPLE
        # Specify source key manually (skips auto-detection)
        Invoke-ChangeKey -InputFile "song.mp3" -OutputFolder ".\Output" -SourceKey "Bb" -TargetKey "C"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Path')]
        [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
        [string]$InputFile,

        [Parameter(Mandatory = $true)]
        [string]$OutputFolder,

        [Parameter(Mandatory = $false)]
        [ValidateSet('C', 'C#', 'Db', 'D', 'D#', 'Eb', 'E', 'F', 'F#', 'Gb', 'G', 'G#', 'Ab', 'A', 'A#', 'Bb', 'B')]
        [string]$SourceKey,

        [Parameter(Mandatory = $true)]
        [ValidateSet('C', 'C#', 'Db', 'D', 'D#', 'Eb', 'E', 'F', 'F#', 'Gb', 'G', 'G#', 'Ab', 'A', 'A#', 'Bb', 'B')]
        [string]$TargetKey,

        [Parameter()]
        [switch]$Force
    )

    begin {
        Write-Verbose "Starting key conversion process"
        
        # Verify external tools exist
        if (-not (Test-Path $script:KeyChangerConfig.KeyFinderExe)) {
            throw "keyfinder-cli.exe not found at: $($script:KeyChangerConfig.KeyFinderExe)"
        }
        if (-not (Test-Path $script:KeyChangerConfig.SoundStretchExe)) {
            throw "soundstretch.exe not found at: $($script:KeyChangerConfig.SoundStretchExe)"
        }
        
        # Check if ffmpeg is available
        try {
            $null = & $script:KeyChangerConfig.FfmpegExe -version 2>&1
        }
        catch {
            throw "ffmpeg not found. Please ensure ffmpeg is installed and in your PATH, or configure it with Set-KeyChangerConfig."
        }

        # Ensure output folder exists
        if (-not (Test-Path $OutputFolder)) {
            New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
            Write-Verbose "Created output folder: $OutputFolder"
        }
    }

    process {
        try {
            # Resolve full paths
            $InputFilePath = (Resolve-Path -LiteralPath $InputFile).Path
            $OutputFolder = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputFolder)
            
            # Get file info
            $FileInfo = Get-Item $InputFilePath
            $FileName = $FileInfo.BaseName
            $Extension = $FileInfo.Extension.ToLower()
            
            # Validate file format
            if ($Extension -notin @('.mp3', '.flac')) {
                throw "Unsupported file format '$Extension'. Only MP3 and FLAC files are supported."
            }

            Write-Host "Processing: $($FileInfo.Name)" -ForegroundColor Cyan

            # Create temp files
            $TempGuid = [Guid]::NewGuid().ToString()
            $TempWavInput = Join-Path $script:KeyChangerConfig.TempDirectory "${TempGuid}_input.wav"
            $TempWavOutput = Join-Path $script:KeyChangerConfig.TempDirectory "${TempGuid}_output.wav"

            try {
                # Step 1: Convert to WAV
                Write-Host "  [1/5] Converting to WAV..." -ForegroundColor Gray
                Write-Verbose "Running ffmpeg to convert input file to WAV format..."
                Write-Verbose "Input: $InputFilePath"
                Write-Verbose "Output: $TempWavInput"
                
                $ffmpegArgs = @(
                    '-i', $InputFilePath,
                    '-acodec', 'pcm_s16le',
                    '-ar', '44100',
                    '-ac', '2',
                    $TempWavInput,
                    '-y'
                )
                
                Write-Verbose "FFmpeg arguments: $($ffmpegArgs -join ' ')"
                
                $result = & $script:KeyChangerConfig.FfmpegExe @ffmpegArgs 2>&1
                
                if ($LASTEXITCODE -ne 0) {
                    Write-Host "FFmpeg output: $result" -ForegroundColor Yellow
                    throw "FFmpeg failed with exit code $LASTEXITCODE"
                }
                
                Write-Verbose "FFmpeg conversion completed"
                Write-Verbose "WAV file created: $(Test-Path $TempWavInput)"
                
                $wavFileInfo = Get-Item $TempWavInput -ErrorAction SilentlyContinue
                if ($wavFileInfo) {
                    Write-Verbose "WAV file size: $($wavFileInfo.Length) bytes"
                }
                
                if (-not (Test-Path $TempWavInput) -or $wavFileInfo.Length -eq 0) {
                    throw "Failed to convert to WAV. WAV file was not created or is empty."
                }

                # Step 2: Detect key
                Write-Host "  [2/5] Detecting current key..." -ForegroundColor Gray
                
                $detectedKey = $null
                
                if ($PSBoundParameters.ContainsKey('SourceKey')) {
                    # Use manually provided key
                    $detectedKey = $SourceKey
                    Write-Host "    Using provided key: $detectedKey" -ForegroundColor Green
                }
                else {
                    # Try auto-detection
                    Write-Verbose "Running keyfinder-cli.exe to analyze audio..."
                    Write-Verbose "KeyFinder executable: $($script:KeyChangerConfig.KeyFinderExe)"
                    Write-Verbose "WAV file path: $TempWavInput"
                    Write-Verbose "WAV file exists: $(Test-Path $TempWavInput)"
                    
                    $keyFinderOutput = & $script:KeyChangerConfig.KeyFinderExe $TempWavInput 2>&1
                    Write-Verbose "Key detection completed"
                    Write-Verbose "Raw KeyFinder output: '$keyFinderOutput'"
                    
                    # Parse keyfinder output - try multiple patterns
                    $outputString = ($keyFinderOutput | Out-String).Trim()
                    Write-Verbose "Parsed output string: '$outputString'"
                    
                    # Try different parsing patterns
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
                        Write-Host "    Detected key: $detectedKey" -ForegroundColor Green
                    }
                    else {
                        Write-Host "    KeyFinder could not detect the key automatically." -ForegroundColor Yellow
                        Write-Host "    Raw KeyFinder output: '$outputString'" -ForegroundColor Yellow
                        Write-Host "    Please specify the source key manually using the -SourceKey parameter." -ForegroundColor Yellow
                        Write-Host "    Example: Invoke-ChangeKey -InputFile '$InputFilePath' -OutputFolder '$OutputFolder' -SourceKey 'Bb' -TargetKey 'C'" -ForegroundColor Cyan
                        
                        # Skip this file and continue
                        Write-Host "    Skipping file: $($FileInfo.Name)" -ForegroundColor Gray
                        return [PSCustomObject]@{
                            InputFile = $InputFilePath
                            OutputFile = $null
                            SourceKey = 'Unknown'
                            TargetKey = $TargetKey
                            SemitoneShift = 0
                            Status = 'Skipped - Key detection failed'
                        }
                    }
                }

                # Step 3: Calculate semitone difference
                Write-Host "  [3/5] Calculating semitone shift..." -ForegroundColor Gray
                Write-Verbose "Calculating semitone difference from $detectedKey to $TargetKey..."
                $semitones = Get-SemitoneDifference -SourceKey $detectedKey -TargetKey $TargetKey
                Write-Verbose "Calculated shift: $semitones semitones"
                
                if ($semitones -eq 0) {
                    Write-Host "    File is already in key $TargetKey. Copying original file..." -ForegroundColor Yellow
                    $outputFileName = "${FileName}_in_${TargetKey}${Extension}"
                    $outputPath = Join-Path $OutputFolder $outputFileName
                    
                    if ((Test-Path $outputPath) -and -not $Force) {
                        throw "Output file already exists: $outputPath. Use -Force to overwrite."
                    }
                    
                    Copy-Item -Path $InputFile -Destination $outputPath -Force
                    Write-Host "  [5/5] Complete!" -ForegroundColor Green
                    
                    return [PSCustomObject]@{
                        InputFile = $InputFilePath.Path
                        OutputFile = $outputPath
                        SourceKey = $detectedKey
                        TargetKey = $TargetKey
                        SemitoneShift = 0
                        Status = 'Copied (already in target key)'
                    }
                }
                
                Write-Host "    Shift: $semitones semitones" -ForegroundColor Green

                # Step 4: Pitch shift with soundstretch
                Write-Host "  [4/5] Pitch shifting audio..." -ForegroundColor Gray
                $pitchParam = if ($semitones -gt 0) { "+$semitones" } else { "$semitones" }
                Write-Verbose "Running soundstretch with pitch parameter: $pitchParam"
                Write-Verbose "Input WAV: $TempWavInput"
                Write-Verbose "Output WAV: $TempWavOutput"
                
                # Verify input file exists
                if (-not (Test-Path $TempWavInput)) {
                    throw "Input WAV file not found: $TempWavInput"
                }
                Write-Verbose "Input WAV file exists, size: $((Get-Item $TempWavInput).Length) bytes"
                
                Write-Host "    Processing audio (this may take a while)..." -ForegroundColor DarkGray
                
                $ssArgs = @($TempWavInput, $TempWavOutput, "-pitch=$pitchParam")
                Write-Verbose "SoundStretch arguments: $($ssArgs -join ' ')"
                
                $ssResult = & $script:KeyChangerConfig.SoundStretchExe @ssArgs 2>&1
                Write-Verbose "SoundStretch processing completed"
                Write-Verbose "SoundStretch exit code: $LASTEXITCODE"
                Write-Verbose "SoundStretch output: $ssResult"
                
                if ($LASTEXITCODE -ne 0) {
                    throw "SoundStretch failed with exit code $LASTEXITCODE. Output: $ssResult"
                }
                
                # Verify output file was created
                if (-not (Test-Path $TempWavOutput)) {
                    Write-Verbose "SoundStretch output file not found. Checking for alternative output..."
                    # SoundStretch might create files with different naming
                    $altOutput = $TempWavOutput -replace '_output\.wav$', '_output.wav'
                    if (Test-Path $altOutput) {
                        Write-Verbose "Found alternative output file: $altOutput"
                        $TempWavOutput = $altOutput
                    } else {
                        throw "SoundStretch failed to create output file: $TempWavOutput"
                    }
                } else {
                    Write-Verbose "SoundStretch output file exists, size: $((Get-Item $TempWavOutput).Length) bytes"
                }
                
                if (-not (Test-Path $TempWavOutput)) {
                    throw "SoundStretch failed to create output. Output: $ssResult"
                }

                $wavFileInfo = Get-Item $TempWavOutput -ErrorAction SilentlyContinue
                if (-not $wavFileInfo -or $wavFileInfo.Length -eq 0) {
                    throw "SoundStretch created an empty or invalid output file. Output: $ssResult"
                }

                # Step 5: Convert back to original format
                Write-Host "  [5/5] Converting to $($Extension.ToUpper().TrimStart('.'))..." -ForegroundColor Gray
                $outputFileName = "${FileName}_in_${TargetKey}${Extension}"
                $outputPath = Join-Path $OutputFolder $outputFileName
                
                if ((Test-Path $outputPath) -and -not $Force) {
                    throw "Output file already exists: $outputPath. Use -Force to overwrite."
                }
                
                Write-Verbose "Converting WAV back to $Extension format..."
                Write-Verbose "Input: $TempWavOutput"
                Write-Verbose "Output: $outputPath"
                
                # Extract existing title tag from original file
                $titleOutput = & $script:KeyChangerConfig.FfmpegExe -i $InputFilePath -f ffmetadata - 2>&1 | Where-Object { $_ -match '^title=' }
                $existingTitle = if ($titleOutput -match '^title=(.*)$') { $matches[1] } else { $FileInfo.BaseName }
                $newTitle = "${existingTitle}_in_$TargetKey"
                Write-Verbose "Original title: $existingTitle"
                Write-Verbose "New title: $newTitle"
                
                # Include original file to preserve metadata tags and append key to title
                $finalArgs = @('-i', $TempWavOutput, '-i', $InputFilePath, '-map', '0:a', '-map_metadata', '1', '-metadata', "title=$newTitle", $outputPath, '-y')
                Write-Verbose "Final FFmpeg arguments: $($finalArgs -join ' ')"
                
                $result = & $script:KeyChangerConfig.FfmpegExe @finalArgs 2>&1
                Write-Verbose "Final conversion completed"
                
                if ($LASTEXITCODE -ne 0) {
                    Write-Host "FFmpeg output: $result" -ForegroundColor Yellow
                    throw "FFmpeg failed with exit code $LASTEXITCODE"
                }
                
                if (-not (Test-Path $outputPath)) {
                    throw "Failed to convert back to $Extension. FFmpeg output: $result"
                }

                Write-Host "  Complete! Saved to: $outputFileName" -ForegroundColor Green

                # Return result object
                [PSCustomObject]@{
                    InputFile = $InputFilePath.Path
                    OutputFile = $outputPath
                    SourceKey = $detectedKey
                    TargetKey = $TargetKey
                    SemitoneShift = $semitones
                    Status = 'Success'
                }
            }
            finally {
                # Cleanup temp files
                if (Test-Path $TempWavInput) {
                    Remove-Item $TempWavInput -Force -ErrorAction SilentlyContinue
                }
                if (Test-Path $TempWavOutput) {
                    Remove-Item $TempWavOutput -Force -ErrorAction SilentlyContinue
                }
            }
        }
        catch {
            Write-Error "Failed to convert audio key: $_"
            throw
        }
    }
}
