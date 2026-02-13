# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Single-purpose bash installer script for Kitten Space Agency (KSA) on Linux via Wine. The project consists of one main script (`install_ksa.sh`) that automates Wine prefix creation, dependency installation, GPU configuration, and desktop integration.

## Architecture

### Script Flow
The installer follows a linear workflow:
1. **Validation**: Check for installer path, Wine, and Winetricks
2. **Wine Prefix Setup**: Create/initialize WINEPREFIX directory
3. **Dependencies**: Install .NET 9 runtime via winetricks
4. **KSA Installation**: Run the Windows installer executable
5. **GPU Detection**: Detect graphics cards using `lspci` and set environment variables
6. **Launch Script**: Generate `launch_ksa.sh` with GPU-specific environment variables
7. **Desktop Integration**: Create `.desktop` launcher file and download icon

### GPU Configuration Logic
- **Detection**: Uses `lspci | grep -E "VGA|3D"` to enumerate GPUs
- **NVIDIA**: Sets `__NV_PRIME_RENDER_OFFLOAD=1`, `__GLX_VENDOR_LIBRARY_NAME=nvidia`, `VK_ICD_FILENAMES`
- **AMD**: Sets `DRI_PRIME=1`
- Multi-GPU systems: User selects which GPU to use (1-N)

### Generated Files
The script creates:
- `$WINEPREFIX/drive_c/Program Files/Kitten Space Agency/launch_ksa.sh` - Launch script with GPU environment variables
- `~/Desktop/KSA.desktop` - Desktop launcher
- `~/.local/share/icons/ksa.png` - Downloaded from GitHub repository

## Development

### Testing
No automated tests exist. Manual testing approach:
- Test on Ubuntu/Pop!_OS 22.04 (primary target)
- Verify with different Wine versions (8.x, 9.x)
- Test single-GPU and multi-GPU configurations
- Test NVIDIA and AMD GPU paths
- Verify .NET 9 installation with different winetricks versions

### Making Changes
- The script uses `set -e` - any command failure will exit immediately
- Color output uses ANSI codes: `$RED`, `$GREEN`, `$YELLOW`, `$NC`
- All paths must handle `~` expansion using `${VAR/#\~/$HOME}`
- When modifying GPU detection, test with `lspci` output variations across different systems

### Distribution
The script is distributed as a single file via:
```bash
wget https://raw.githubusercontent.com/sleepyeb/ksa_linux/main/install_ksa.sh
```

When modifying, ensure the script remains self-contained and doesn't introduce external dependencies beyond Wine, Winetricks, and standard Linux utilities (wget, lspci).

## Key Technical Details

### Wine Prefix Structure
- Default location: `~/ksa_prefix`
- KSA installs to: `$WINEPREFIX/drive_c/Program Files/Kitten Space Agency`
- Main executable: `KSA.exe`

### .NET 9 Installation
- Installed via `winetricks -q dotnet9`
- Requires Wine 8.x or newer
- Common failure points: outdated winetricks, network issues, Wine version too old

### Crash Recovery Mechanism
The launch script includes automatic crash detection and recovery:
- Uses flag file `~/.ksa_running` to detect unclean shutdowns
- On crash detection: kills lingering Wine processes with `wineserver -k`
- Clears corrupted Mesa shader cache at `~/.cache/mesa_shader_cache/*`
- **Root cause**: KSA crashes corrupt Mesa shader cache, causing freeze-on-relaunch during shader compilation
- This prevents the need for full Wine prefix reinstallation after crashes

### Error Handling
Critical validation points:
- Installer path exists (line 28)
- Wine and Winetricks are installed (lines 40, 60)
- .NET 9 installation succeeds (line 104)
- KSA installation directory exists after install (line 174)
