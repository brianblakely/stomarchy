#!/bin/bash
#
# Installation script for stomarchy
#

set -e

INSTALL_DIR="/usr/local/bin"
SCRIPT_NAME="stomarchy"

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    INSTALL_DIR="/usr/bin"
fi

echo "Installing stomarchy to ${INSTALL_DIR}..."

# Create install directory if it doesn't exist
mkdir -p "$INSTALL_DIR"

# Copy the script
cp stomarchy "${INSTALL_DIR}/${SCRIPT_NAME}"
chmod +x "${INSTALL_DIR}/${SCRIPT_NAME}"

echo "Installation complete!"
echo ""
echo "stomarchy has been installed to: ${INSTALL_DIR}/${SCRIPT_NAME}"
echo ""
echo "Usage:"
echo "  stomarchy help     - Show help message"
echo "  stomarchy add      - Track changes and update config"
echo "  stomarchy link     - Link checked-out snippets"
echo "  stomarchy remove   - Restore default and stop tracking"
echo "  stomarchy sync     - Copy current Omarchy defaults"
echo "  stomarchy status   - Show current status"
echo ""
echo "Get started by running: stomarchy help"
