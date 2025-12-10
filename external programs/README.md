# External Programs

Place the following executables in this folder:

## Required Tools

### 1. keyfinder-cli.exe
- **Purpose:** Detects the musical key of WAV audio files
- **Download:** [KeyFinder Project](https://www.ibrahimshaath.co.uk/keyfinder/)
- **Usage:** Takes a WAV file as input and outputs the detected key

### 2. soundstretch.exe
- **Purpose:** Pitch-shifts audio files
- **Download:** [SoundTouch Library](https://www.surina.net/soundtouch/)
- **Usage:** Command syntax: `soundstretch input.wav output.wav -pitch=+3`
  - Use `+` for raising pitch (e.g., `-pitch=+2`)
  - Use `-` for lowering pitch (e.g., `-pitch=-3`)

### 3. ffmpeg.exe (Optional)
- **Purpose:** Converts between audio formats (MP3/FLAC to WAV and back)
- **Download:** [FFmpeg Official](https://ffmpeg.org/download.html)
- **Note:** Can also be installed system-wide and added to PATH instead of placing here

## Installation

1. Download each tool from the links above
2. Extract/copy the executables to this folder
3. Verify the files are in place:
   - `keyfinder-cli.exe`
   - `soundstretch.exe`
   - `ffmpeg.exe` (optional if already in PATH)

## Configuration

If you place ffmpeg elsewhere or want to use different paths, configure the module:

```powershell
Set-KeyChangerConfig -FfmpegExe "C:\Path\To\ffmpeg.exe"
```
