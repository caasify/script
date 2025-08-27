#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage:"
  echo "  bash launch.sh trojan <secret> <hostname>"
  echo "  bash launch.sh mikrotik <secret>"
  exit 1
fi

action=$(echo "$1" | awk '{print tolower($0)}')

case "$action" in
  "vpn trojan")
    if [ $# -ne 3 ]; then
      echo "Error: trojan requires <secret> <hostname>"
      echo "Usage: bash launch.sh trojan <secret> <hostname>"
      exit 1
    fi
    SCRIPT_URL="https://raw.githubusercontent.com/caasify/script/refs/heads/main/vpn/xui/trojan.sh"
    EXTRA_ARGS="${@:2}" # secret + hostname
    ;;
  mikrotik)
    if [ $# -ne 2 ]; then
      echo "Error: mikrotik requires <secret>"
      echo "Usage: bash launch.sh mikrotik <secret>"
      exit 1
    fi
    SCRIPT_URL="https://raw.githubusercontent.com/caasify/script/refs/heads/main/mikrotik/mikrotik.sh"
    EXTRA_ARGS="${@:2}" # secret
    ;;
  *)
    echo "Invalid option: $1"
    echo "Usage:"
    echo "  bash launch.sh trojan <secret> <hostname>"
    echo "  bash launch.sh mikrotik <secret>"
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
bash "$TMP_SCRIPT" $EXTRA_ARGS

# Clean up
rm -f "$TMP_SCRIPT"
