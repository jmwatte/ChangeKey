# KeyChanger Project Instructions

## Project Overview
KeyChanger is an audio pitch/key changing tool that processes MP3 or FLAC files using external programs to transpose songs to different musical keys (e.g., Bb to C).

## Development Guidelines
- PowerShell module
- Support for MP3 and FLAC formats
- Integration with external audio processing tools
- Musical key detection and transposition
- Clean, modular code structure
- Follow PowerShell best practices and conventions
- **IMPORTANT**: Never use backticks to escape quotes around paths when building argument arrays for external programs. PowerShell's Start-Process and call operator handle path quoting automatically. Use unquoted variables in argument arrays (e.g., `@('-i', $path)` not `@('-i', "\`"$path\`"")`).

## Progress Checklist

- [x] Create .github/copilot-instructions.md file
- [ ] Scaffold KeyChanger Python project structure
- [ ] Customize project for audio key changing
- [ ] Install dependencies
- [ ] Create documentation
