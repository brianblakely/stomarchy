#!/bin/bash
#
# Installation script for stomarchy
#

set -e

INSTALL_DIR="/usr/local/bin"
COMPLETION_DIR="/usr/local/share/bash-completion/completions"
MAN_DIR="/usr/local/share/man/man1"
SCRIPT_NAME="stomarchy"

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    INSTALL_DIR="/usr/bin"
    COMPLETION_DIR="/usr/share/bash-completion/completions"
    MAN_DIR="/usr/share/man/man1"
fi

echo "Installing stomarchy to ${INSTALL_DIR}..."

# Create install directory if it doesn't exist
mkdir -p "$INSTALL_DIR"

# Copy the script
cp stomarchy "${INSTALL_DIR}/${SCRIPT_NAME}"
chmod +x "${INSTALL_DIR}/${SCRIPT_NAME}"

if [ -f completions/stomarchy.bash ]; then
    mkdir -p "$COMPLETION_DIR"
    cp completions/stomarchy.bash "${COMPLETION_DIR}/stomarchy"
fi

if [ -f man/stomarchy.1 ]; then
    mkdir -p "$MAN_DIR"
    cp man/stomarchy.1 "${MAN_DIR}/stomarchy.1"
fi

echo "Installation complete!"
echo ""
echo "stomarchy has been installed to: ${INSTALL_DIR}/${SCRIPT_NAME}"
echo "bash completion has been installed to: ${COMPLETION_DIR}/stomarchy"
echo "man page has been installed to: ${MAN_DIR}/stomarchy.1"
echo ""
echo "Usage:"
echo "  stomarchy help     - Show help message"
echo "  stomarchy add      - Track changes and update local file"
echo "  stomarchy add -n   - Preview tweak generation"
echo "  stomarchy link     - Link checked-out tweaks"
echo "  stomarchy remove   - Restore default and stop tracking"
echo "  stomarchy sync     - Copy current Omarchy defaults"
echo "  stomarchy sync -n  - Preview sync changes"
echo "  stomarchy wipe     - Restore Omarchy baselines"
echo "  stomarchy status   - Show current status"
echo ""
echo "Get started by running: stomarchy help"
