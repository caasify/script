#!/bin/bash

# Check if an argument is provided
if [ -z "$1" ]; then
  echo "Usage: bash launch.sh [trojan|mikrotik]"
  exit 1
fi

case "$1" in
  trojan)
    SCRIPT_URL="https://raw.githubusercontent.com/caasify/script/main/vpn/xui/trojan.sh"
    ;;
  mikrotik)
    SCRIPT_URL="https://raw.githubusercontent.com/caasify/script/main/mikrotik/mikrotik.sh"
    ;;
  *)
    echo "Invalid option: $1"
    echo "Usage: bash launch.sh [trojan|mikrotik]"
    exit 1
    ;;
esac

# Download and execute the script
TMP_SCRIPT=$(mktemp)
curl -fsSL "$SCRIPT_URL" -o "$TMP_SCRIPT"
if [ $? -ne 0 ]; then
  echo "Failed to download script from $SCRIPT_URL"
  exit 1
fi

chmod +x "$TMP_SCRIPT"
bash "$TMP_SCRIPT"

# Clean up
rm -f "$TMP_SCRIPT"
