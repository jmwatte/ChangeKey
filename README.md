# KeyChanger

A PowerShell module for changing the musical key of audio files (MP3 and FLAC).

## Overview

KeyChanger processes audio files and automatically transposes them to different musical keys. The module detects the current key of a song and pitch-shifts it to your desired target key using industry-standard audio processing tools.

For example, convert a song from Bb to C, or from D to E - perfect for musicians, DJs, or anyone needing audio in specific keys.

## How It Works

KeyChanger uses a workflow combining three external tools:

1. **FFmpeg** - Converts audio files to/from WAV format
2. **KeyFinder** - Detects the musical key of the audio
3. **SoundStretch** - Performs the pitch shifting

The process:
1. Convert input file (MP3/FLAC) to WAV
2. Detect current key using keyfinder-cli.exe
3. Calculate semitone difference
4. Pitch-shift using soundstretch.exe
5. Convert back to original format
6. Save with "_in_[Key]" suffix
7. Clean up temporary files

## Installation

### 1. Install the Module

Copy the `KeyChanger` folder to one of your PowerShell module directories:
- Current user: `$HOME\Documents\PowerShell\Modules\`
- All users: `C:\Program Files\PowerShell\Modules\`

### 2. Install External Tools

Place the following executables in the `external programs` folder:

- **keyfinder-cli.exe** - [Download KeyFinder](https://www.ibrahimshaath.co.uk/keyfinder/)
- **soundstretch.exe** - [Download SoundTouch](https://www.surina.net/soundtouch/)
- **ffmpeg.exe** - [Download FFmpeg](https://ffmpeg.org/download.html) (or install system-wide)

See [external programs/README.md](external programs/README.md) for detailed installation instructions.

### 3. Import the Module

```powershell
Import-Module KeyChanger
```

### 4. Verify Installation

```powershell
Get-Module KeyChanger
Get-Command -Module KeyChanger
```

## Usage

### Basic Usage (Recommended)

For reliable results, specify both source and target keys manually:

```powershell
# Change from Bb major to C major
Invoke-ChangeKey -InputFile "C:\Music\Song.mp3" -OutputFolder "C:\Music\Converted" -SourceKey "Bb" -TargetKey "C"

# Change from A minor to D minor  
Invoke-ChangeKey -InputFile "C:\Music\Song.mp3" -OutputFolder "C:\Music\Converted" -SourceKey "Am" -TargetKey "Dm"
```

### Automatic Key Detection

The module can automatically detect the source key using KeyFinder:

```powershell
# Auto-detect source key and convert to C
Invoke-ChangeKey -InputFile "C:\Music\Song.mp3" -OutputFolder "C:\Music\Converted" -TargetKey "C"
```

**Note:** Automatic detection requires the KeyFinder executable to be properly installed in the `external programs\Release\` folder with all its dependencies.

### More Examples

```powershell
# Convert FLAC file to key of D
Invoke-ChangeKey -InputFile "song.flac" -OutputFolder ".\Output" -TargetKey "D"

# Overwrite if output file exists
Invoke-ChangeKey -InputFile "song.mp3" -OutputFolder ".\Output" -TargetKey "E" -Force

# Process multiple files
Get-ChildItem *.mp3 | ForEach-Object {
    Invoke-ChangeKey -InputFile $_.FullName -OutputFolder ".\Converted" -TargetKey "C"
}

# Convert all songs in a folder to the same key
$targetKey = "G"
Get-ChildItem "C:\Music\Original" -Filter *.mp3 | ForEach-Object {
    Invoke-ChangeKey -InputFile $_.FullName -OutputFolder "C:\Music\InKey_$targetKey" -TargetKey $targetKey
}
```

### Configuration

If ffmpeg is not in your PATH or you want to use custom locations:

```powershell
# View current configuration
Set-KeyChangerConfig

# Set ffmpeg path
Set-KeyChangerConfig -FfmpegExe "C:\Tools\ffmpeg.exe"

# Set custom temp directory
Set-KeyChangerConfig -TempDirectory "D:\Temp"

# Override default tool locations
Set-KeyChangerConfig -KeyFinderExe "C:\CustomPath\keyfinder.exe"
Set-KeyChangerConfig -SoundStretchExe "C:\CustomPath\soundstretch.exe"
```

## Supported Keys

All standard musical keys are supported:
- **Natural:** C, D, E, F, G, A, B
- **Sharps:** C#, D#, F#, G#, A#
- **Flats:** Db, Eb, Gb, Ab, Bb

Enharmonic equivalents (C# = Db, D# = Eb, etc.) are handled automatically.

## Supported Formats

- **Input:** MP3, FLAC
- **Output:** Same format as input
- **Processing:** WAV (temporary, auto-deleted)

## Output File Naming

Output files are automatically named with the pattern:
```
[OriginalName]_in_[TargetKey].[Extension]
```

Examples:
- `MySong.mp3` → `MySong_in_C.mp3`
- `Track01.flac` → `Track01_in_D.flac`

## Command Reference

### Invoke-ChangeKey

Main function for key conversion.

**Parameters:**
- `-InputFile` (Required) - Path to input MP3 or FLAC file
- `-OutputFolder` (Required) - Folder for output file
- `-TargetKey` (Required) - Desired musical key (C, D, E, F, G, A, B, with sharps/flats)
- `-Force` (Optional) - Overwrite existing output file

### Set-KeyChangerConfig

Configure module settings.

**Parameters:**
- `-KeyFinderExe` - Path to keyfinder.exe
- `-SoundStretchExe` - Path to soundstretch.exe
- `-FfmpegExe` - Path to ffmpeg executable
- `-TempDirectory` - Temporary file directory

## Troubleshooting

### "keyfinder-cli.exe not found"
Ensure keyfinder-cli.exe is in the `external programs` folder.

### "soundstretch.exe not found"
Ensure soundstretch.exe is in the `external programs` folder.

### "ffmpeg not found"
Either:
- Install ffmpeg system-wide and add to PATH
- Place ffmpeg.exe in the `external programs` folder
- Configure custom path: `Set-KeyChangerConfig -FfmpegExe "C:\path\to\ffmpeg.exe"`

### "Failed to detect key"
The audio file may not have clear tonal content. Try specifying the source key manually with the `-SourceKey` parameter.

### Poor audio quality
If the output has artifacts, the original file may have been heavily compressed or the pitch shift is too extreme (>6 semitones).

## Requirements

- PowerShell 5.1 or higher
- Windows operating system
- External tools: keyfinder.exe, soundstretch.exe, ffmpeg.exe

## License

[Specify your license here]

## Author

[Your name/contact]
