#!/bin/bash

# CS35L56 Firmware Installer for Asus Zenbook S16
# Fixes missing left speaker (AMP3 and AMP4) firmware

set -e

echo "=== CS35L56 Firmware Installer for Asus Zenbook S16 ==="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Error: This script must be run as root (use sudo)"
    exit 1
fi

# Firmware details
FIRMWARE_DIR="/lib/firmware/cirrus"
BASE_URL="https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/plain/cirrus"
MODEL_ID="10431264"
TARGET_ID="10431df3"
AMP3_FILE="cs35l56-b0-dsp1-misc-${MODEL_ID}-amp3.bin"
AMP4_FILE="cs35l56-b0-dsp1-misc-${MODEL_ID}-amp4.bin"
AMP3_TARGET="cs35l56-b0-dsp1-misc-${TARGET_ID}-amp3.bin"
AMP4_TARGET="cs35l56-b0-dsp1-misc-${TARGET_ID}-amp4.bin"

# Create firmware directory if it doesn't exist
echo "[1/5] Checking firmware directory..."
if [ ! -d "$FIRMWARE_DIR" ]; then
    echo "Creating $FIRMWARE_DIR..."
    mkdir -p "$FIRMWARE_DIR"
fi

# Backup existing files if they exist
echo "[2/5] Backing up existing firmware (if any)..."
if [ -f "$FIRMWARE_DIR/$AMP3_FILE" ]; then
    cp "$FIRMWARE_DIR/$AMP3_FILE" "$FIRMWARE_DIR/${AMP3_FILE}.backup.$(date +%s)"
    echo "Backed up existing amp3.bin"
fi
if [ -f "$FIRMWARE_DIR/$AMP4_FILE" ]; then
    cp "$FIRMWARE_DIR/$AMP4_FILE" "$FIRMWARE_DIR/${AMP4_FILE}.backup.$(date +%s)"
    echo "Backed up existing amp4.bin"
fi

# Download the actual firmware files (targets of the symlinks)
echo "[3/5] Downloading amp3.bin target (Left Tweeter firmware)..."
if wget -q --show-progress -O "$FIRMWARE_DIR/$AMP3_TARGET" "$BASE_URL/$AMP3_TARGET"; then
    echo "✓ Successfully downloaded $AMP3_TARGET"
else
    echo "✗ Failed to download $AMP3_TARGET"
    exit 1
fi

echo "[4/5] Downloading amp4.bin target (Left Woofer firmware)..."
if wget -q --show-progress -O "$FIRMWARE_DIR/$AMP4_TARGET" "$BASE_URL/$AMP4_TARGET"; then
    echo "✓ Successfully downloaded $AMP4_TARGET"
else
    echo "✗ Failed to download $AMP4_TARGET"
    exit 1
fi

# Create symlinks
echo "Creating symlinks..."
ln -sf "$AMP3_TARGET" "$FIRMWARE_DIR/$AMP3_FILE"
ln -sf "$AMP4_TARGET" "$FIRMWARE_DIR/$AMP4_FILE"
echo "✓ Created symlinks for amp3 and amp4"

# Verify files
echo "[5/5] Verifying installation..."
echo ""
echo "Installed firmware files:"
ls -lh "$FIRMWARE_DIR"/cs35l56-b0-dsp1-misc-${MODEL_ID}-amp*.bin
ls -lh "$FIRMWARE_DIR"/cs35l56-b0-dsp1-misc-${TARGET_ID}-amp*.bin 2>/dev/null || true

# Set proper permissions
chmod 644 "$FIRMWARE_DIR/$AMP3_TARGET" 2>/dev/null || true
chmod 644 "$FIRMWARE_DIR/$AMP4_TARGET" 2>/dev/null || true

echo ""
echo "=== Installation Complete ==="
echo ""
echo "Next steps:"
echo "1. Reload audio modules:"
echo "   sudo modprobe -r snd_hda_codec_realtek"
echo "   sudo modprobe -r snd_hda_scodec_cs35l56"
echo "   sudo modprobe snd_hda_scodec_cs35l56"
echo "   sudo modprobe snd_hda_codec_realtek"
echo ""
echo "   OR simply reboot: sudo reboot"
echo ""
echo "2. After reboot, verify all 4 amplifiers loaded:"
echo "   sudo dmesg | grep 'cs35l56.*amp[1-4].*bin'"
echo ""
echo "You should see amp1.bin, amp2.bin, amp3.bin, and amp4.bin all loaded."
echo "Both left and right speakers should now work!"
echo ""

read -p "Would you like to reload the audio modules now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Reloading audio modules..."
    modprobe -r snd_hda_codec_realtek 2>/dev/null || true
    modprobe -r snd_hda_scodec_cs35l56 2>/dev/null || true
    sleep 1
    modprobe snd_hda_scodec_cs35l56
    modprobe snd_hda_codec_realtek
    sleep 2
    echo ""
    echo "Checking if firmware loaded..."
    dmesg | tail -20 | grep -i cs35l56 || echo "Check dmesg for cs35l56 messages"
    echo ""
    echo "Done! Test your left speaker now."
else
    echo "Skipped module reload. Please reboot when convenient."
fi
