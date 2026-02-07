#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if installer path was provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: KSA installer path is required${NC}"
    echo
    echo "Usage: $0 <path-to-ksa-installer.exe>"
    echo
    echo "Example:"
    echo "  $0 ~/Downloads/setup_ksa_v2026.2.4.3423.exe"
    echo
    exit 1
fi

INSTALLER_PATH="$1"
# Expand ~ to home directory if used
INSTALLER_PATH="${INSTALLER_PATH/#\~/$HOME}"

if [ ! -f "$INSTALLER_PATH" ]; then
    echo -e "${RED}Error: Installer not found at: $INSTALLER_PATH${NC}"
    exit 1
fi

echo -e "${GREEN}=== Kitten Space Agency Installer ===${NC}"
echo
echo -e "${GREEN}Found installer: $INSTALLER_PATH${NC}"
echo

# Check for wine
echo -e "${YELLOW}Checking for wine...${NC}"
if ! command -v wine &> /dev/null; then
    echo -e "${RED}Wine is not installed!${NC}"
    echo
    echo "For Ubuntu/Pop!_OS 22.04, run:"
    echo "  sudo dpkg --add-architecture i386"
    echo "  sudo mkdir -pm755 /etc/apt/keyrings"
    echo "  sudo wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key"
    echo "  sudo wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/jammy/winehq-jammy.sources"
    echo "  sudo apt update"
    echo "  sudo apt install --install-recommends winehq-stable"
    echo
    echo "For other distributions, search: 'install wine [your distro name]'"
    echo
    exit 1
fi
echo -e "${GREEN}Wine found: $(wine --version)${NC}"
echo

# Check for winetricks
echo -e "${YELLOW}Checking for winetricks...${NC}"
if ! command -v winetricks &> /dev/null; then
    echo -e "${RED}Winetricks is not installed!${NC}"
    echo
    echo "For Ubuntu/Debian-based distros, run:"
    echo "  sudo apt install winetricks"
    echo "  sudo winetricks --self-update"
    echo
    echo "For other distributions, search: 'install winetricks [your distro name]'"
    echo
    exit 1
fi
echo -e "${GREEN}Winetricks found: $(winetricks --version | head -1)${NC}"
echo

# Prompt for wine prefix
echo -e "${YELLOW}Enter wine prefix directory (default: $HOME/ksa_prefix):${NC}"
read -r WINEPREFIX_INPUT
if [ -z "$WINEPREFIX_INPUT" ]; then
    WINEPREFIX="$HOME/ksa_prefix"
else
    WINEPREFIX="$WINEPREFIX_INPUT"
fi

# Expand ~ to home directory if used
WINEPREFIX="${WINEPREFIX/#\~/$HOME}"

echo -e "${GREEN}Using wine prefix: $WINEPREFIX${NC}"
echo

# Create and initialize wine prefix if it doesn't exist
if [ ! -d "$WINEPREFIX" ]; then
    echo -e "${YELLOW}Creating wine prefix...${NC}"
    mkdir -p "$WINEPREFIX"
    WINEPREFIX="$WINEPREFIX" wineboot -u
    echo -e "${GREEN}Wine prefix created${NC}"
    echo
else
    echo -e "${YELLOW}Wine prefix already exists, using existing prefix${NC}"
    echo
fi

# Install .NET 9
echo -e "${YELLOW}Installing .NET 9 runtime (this may take a few minutes)...${NC}"
WINEPREFIX="$WINEPREFIX" winetricks -q dotnet9
if [ $? -eq 0 ]; then
    echo -e "${GREEN}.NET 9 installed successfully${NC}"
else
    echo -e "${RED}Failed to install .NET 9${NC}"
    exit 1
fi
echo

# Install KSA
echo -e "${YELLOW}Installing Kitten Space Agency...${NC}"
echo -e "${YELLOW}Please choose 'Install for all users' and use the default install directory${NC}"
WINEPREFIX="$WINEPREFIX" wine "$INSTALLER_PATH"
echo -e "${GREEN}KSA installation complete${NC}"
echo

# Detect graphics cards
echo -e "${YELLOW}Detecting graphics cards...${NC}"
GPUS=$(lspci | grep -E "VGA|3D")
GPU_COUNT=$(echo "$GPUS" | wc -l)

if [ "$GPU_COUNT" -eq 0 ]; then
    echo -e "${RED}No graphics cards detected!${NC}"
    exit 1
fi

echo -e "${GREEN}Found $GPU_COUNT graphics card(s):${NC}"
echo "$GPUS" | nl -v 1
echo

# GPU selection and environment variables
GPU_ENV_VARS=""
if [ "$GPU_COUNT" -gt 1 ]; then
    echo -e "${YELLOW}Which GPU would you like to use? (1-$GPU_COUNT):${NC}"
    read -r GPU_CHOICE

    # Check if choice is valid
    if ! [[ "$GPU_CHOICE" =~ ^[0-9]+$ ]] || [ "$GPU_CHOICE" -lt 1 ] || [ "$GPU_CHOICE" -gt "$GPU_COUNT" ]; then
        echo -e "${RED}Invalid choice, defaulting to GPU 1${NC}"
        GPU_CHOICE=1
    fi

    SELECTED_GPU=$(echo "$GPUS" | sed -n "${GPU_CHOICE}p")
    echo -e "${GREEN}Selected: $SELECTED_GPU${NC}"

    # Set environment variables based on GPU type
    if echo "$SELECTED_GPU" | grep -iq "nvidia"; then
        GPU_ENV_VARS="__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json"
        echo -e "${GREEN}Using NVIDIA GPU with Prime offloading${NC}"
    elif echo "$SELECTED_GPU" | grep -iq "amd"; then
        GPU_ENV_VARS="DRI_PRIME=1"
        echo -e "${GREEN}Using AMD GPU with DRI_PRIME${NC}"
    fi
else
    echo -e "${GREEN}Single GPU detected, using default configuration${NC}"
fi
echo

# Determine KSA installation path
KSA_INSTALL_DIR="$WINEPREFIX/drive_c/Program Files/Kitten Space Agency"
if [ ! -d "$KSA_INSTALL_DIR" ]; then
    echo -e "${RED}Error: KSA installation directory not found at: $KSA_INSTALL_DIR${NC}"
    exit 1
fi

# Create launch script in installation directory
LAUNCH_SCRIPT="$KSA_INSTALL_DIR/launch_ksa.sh"
echo -e "${YELLOW}Creating launch script at: $LAUNCH_SCRIPT${NC}"

cat > "$LAUNCH_SCRIPT" << EOF
#!/bin/bash
cd "$KSA_INSTALL_DIR"
$GPU_ENV_VARS \\
WINEPREFIX="$WINEPREFIX" \\
wine KSA.exe
EOF

chmod +x "$LAUNCH_SCRIPT"
echo -e "${GREEN}Launch script created${NC}"
echo

# Download icon from GitHub
ICON_URL="https://raw.githubusercontent.com/sleepyeb/ksa_linux/main/tux_icon.png"
ICON_DEST="$HOME/.local/share/icons/ksa.png"
echo -e "${YELLOW}Downloading KSA icon...${NC}"
mkdir -p "$HOME/.local/share/icons"
if wget -q "$ICON_URL" -O "$ICON_DEST"; then
    echo -e "${GREEN}Icon downloaded successfully${NC}"
else
    echo -e "${YELLOW}Warning: Could not download icon, using default${NC}"
    ICON_DEST="applications-games"
fi

# Create desktop launcher
DESKTOP_FILE="$HOME/Desktop/KSA.desktop"
echo -e "${YELLOW}Creating desktop launcher at: $DESKTOP_FILE${NC}"

cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Kitten Space Agency
Comment=Launch KSA (Wine)
Exec="$LAUNCH_SCRIPT"
Icon=$ICON_DEST
Terminal=false
Categories=Game;
EOF

chmod +x "$DESKTOP_FILE"
echo -e "${GREEN}Desktop launcher created${NC}"
echo

# Final summary
echo -e "${GREEN}=== Installation Complete ===${NC}"
echo
echo "Wine prefix: $WINEPREFIX"
echo "Install directory: $KSA_INSTALL_DIR"
echo "Launch script: $LAUNCH_SCRIPT"
echo "Desktop launcher: $DESKTOP_FILE"
echo
echo -e "${GREEN}You can now launch KSA by:${NC}"
echo "  1. Double-clicking the KSA icon on your desktop"
echo "  2. Running: $LAUNCH_SCRIPT"
echo
echo -e "${YELLOW}Note: If the game crashes on loading, try lowering texture settings in graphics options.${NC}"
echo
