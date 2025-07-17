#!/bin/bash

# Filename: check_junk.sh
# Description: Check and optionally clean junk files in Ubuntu
# Author: sripathi_bhat@yahoo.com
# Date: 2025-07-16

LOGFILE="$HOME/junk_report_$(date +%Y%m%d_%H%M%S).log"
echo "Junk Files Report - $(date)" > "$LOGFILE"
echo "==========================" >> "$LOGFILE"

# Function to check and log folder size
check_folder_size() {
    local name=$1
    local path=$2
    local size=$(du -sh "$path" 2>/dev/null | cut -f1)
    echo "$name: $size ($path)" | tee -a "$LOGFILE"
}

# Check APT cache
check_folder_size "APT Cache" "/var/cache/apt/archives"

# Check thumbnail cache
check_folder_size "Thumbnail Cache" "$HOME/.cache/thumbnails"

# Check user cache
check_folder_size "User Cache" "$HOME/.cache"

# Check systemd journal logs
JOURNAL_SIZE=$(journalctl --disk-usage 2>/dev/null | awk '{print $6, $7}')
echo "Journal Logs: $JOURNAL_SIZE" | tee -a "$LOGFILE"

# Optional cleaning
read -p "Do you want to clean these junk files now? [y/N]: " confirm
if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
    echo "Cleaning started..." | tee -a "$LOGFILE"

    echo "Cleaning APT cache..."
    sudo apt clean >> "$LOGFILE" 2>&1

    echo "Cleaning thumbnail cache..."
    rm -rf "$HOME/.cache/thumbnails"/* >> "$LOGFILE" 2>&1

    echo "Cleaning user cache..."
    rm -rf "$HOME/.cache"/* >> "$LOGFILE" 2>&1

    echo "Vacuuming journal logs to 100MB..."
    sudo journalctl --vacuum-size=100M >> "$LOGFILE" 2>&1

    echo "Cleaning done." | tee -a "$LOGFILE"
else
    echo "Cleanup skipped." | tee -a "$LOGFILE"
fi

echo -e "\n✅ Report saved to: $LOGFILE"

