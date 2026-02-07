# KSA Linux Installer

Automated installation script for **Kitten Space Agency** on Linux using Wine.

![KSA Icon](ksa_icon.png)

## Features

- ✅ Automatically checks for Wine and Winetricks
- ✅ Creates and configures a Wine prefix
- ✅ Installs .NET 9 runtime dependency
- ✅ Detects multiple GPUs and lets you choose which to use
- ✅ Creates launch script in the installation directory
- ✅ Creates desktop launcher with custom icon
- ✅ Supports NVIDIA and AMD GPU configurations

## Requirements

- Ubuntu/Pop!_OS 22.04 or similar Linux distribution
- Wine 8.x or later (9.x+ recommended)
- Winetricks (latest version recommended)
- ~500MB free disk space for Wine prefix
- ~2GB for KSA installation
- KSA installer executable (`.exe` file)

## Installation

### 1. Download the installer script

```bash
wget https://raw.githubusercontent.com/sleepyeb/ksa_linux/main/install_ksa.sh
chmod +x install_ksa.sh
```

### 2. Run the installer

```bash
./install_ksa.sh /path/to/setup_ksa_*.exe
```

For example:
```bash
./install_ksa.sh ~/Downloads/setup_ksa_v2026.2.4.3423.exe
```

### 3. Follow the prompts

The script will:
1. Check if Wine and Winetricks are installed
2. Prompt you for a Wine prefix location (default: `~/ksa_prefix`)
3. Install .NET 9 runtime
4. Run the KSA installer (choose "Install for all users" and default directory)
5. Detect your GPUs and let you choose which one to use
6. Create a launch script and desktop launcher

### 4. Launch KSA

After installation, you can launch KSA by:
- Double-clicking the **Kitten Space Agency** icon on your desktop
- Running the launch script: `~/ksa_prefix/drive_c/Program Files/Kitten Space Agency/launch_ksa.sh`

## Installing Wine and Winetricks

If Wine is not installed, the script will provide instructions. Here's how to install on Ubuntu/Pop!_OS 22.04:

```bash
# Add 32-bit architecture support
sudo dpkg --add-architecture i386

# Add WineHQ repository
sudo mkdir -pm755 /etc/apt/keyrings
sudo wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key
sudo wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/jammy/winehq-jammy.sources

# Update and install Wine
sudo apt update
sudo apt install --install-recommends winehq-stable

# Install Winetricks and update it
sudo apt install winetricks
sudo winetricks --self-update
```

## Troubleshooting

### Game crashes while loading
- **Cause**: Insufficient VRAM or texture memory
- **Solution**: Lower texture settings in the graphics options

### Permission errors
Make sure the script is executable:
```bash
chmod +x install_ksa.sh
```

### Graphics performance issues
The script automatically detects and configures GPU offloading for:
- **NVIDIA**: Uses PRIME offloading
- **AMD**: Uses DRI_PRIME

Make sure you have the latest graphics drivers installed for your GPU.

### .NET installation fails
Make sure your Wine and Winetricks are up to date:
```bash
sudo apt update && sudo apt upgrade
sudo winetricks --self-update
```

## GPU Configuration

The script automatically detects your graphics cards. If you have multiple GPUs, it will:
1. List all detected GPUs with numbers
2. Let you choose which GPU to use
3. Configure the appropriate environment variables:
   - **NVIDIA**: `__NV_PRIME_RENDER_OFFLOAD=1`, `__GLX_VENDOR_LIBRARY_NAME=nvidia`, `VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json`
   - **AMD**: `DRI_PRIME=1`

## Manual Launch

If you prefer to launch KSA manually, use:

```bash
cd "$HOME/ksa_prefix/drive_c/Program Files/Kitten Space Agency/"
WINEPREFIX="$HOME/ksa_prefix" wine KSA.exe
```

For NVIDIA GPU:
```bash
cd "$HOME/ksa_prefix/drive_c/Program Files/Kitten Space Agency/"
__NV_PRIME_RENDER_OFFLOAD=1 \
__GLX_VENDOR_LIBRARY_NAME=nvidia \
VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json \
WINEPREFIX="$HOME/ksa_prefix" \
wine KSA.exe
```

## License

This installer script is provided as-is for the KSA community. Kitten Space Agency is developed by Kitten Interactive.

## Contributing

Issues and pull requests welcome! Feel free to improve the script or add support for more Linux distributions.
