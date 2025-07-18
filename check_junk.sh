#!/bin/bash

# ───── Configuration ──────────────────────────────────────────────────────────
REAL_USER="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo "~$REAL_USER")
LOG_DIR="$USER_HOME"
LOG_FILE="$LOG_DIR/junk_report_$(date '+%Y%m%d_%H%M%S').log"
APT_CACHE="/var/cache/apt/archives"
USER_CACHE="$USER_HOME/.cache"
THUMB_CACHE="$USER_CACHE/thumbnails"

# ───── Color Codes ────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

# ───── Permissions Check ──────────────────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}❌ Please run this script using: sudo $0${NC}"
  exit 1
fi

# ───── Disk Usage Calculations ────────────────────────────────────────────────
APT_SIZE=$(du -sh "$APT_CACHE" 2>/dev/null | cut -f1)
USER_CACHE_SIZE=$(du -sh "$USER_CACHE" 2>/dev/null | cut -f1)
THUMB_CACHE_SIZE=$(du -sh "$THUMB_CACHE" 2>/dev/null | cut -f1)
JOURNAL_SIZE=$(journalctl --disk-usage 2>/dev/null | awk '{print $6 " " $7}')

# ───── Display Report ─────────────────────────────────────────────────────────
echo -e "${BLUE}APT Cache:${NC} $APT_SIZE ($APT_CACHE)"
echo -e "${BLUE}Thumbnail Cache:${NC} $THUMB_CACHE_SIZE ($THUMB_CACHE)"
echo -e "${BLUE}User Cache:${NC} $USER_CACHE_SIZE ($USER_CACHE)"
echo -e "${BLUE}Journal Logs:${NC} $JOURNAL_SIZE"

# ───── Prompt User ────────────────────────────────────────────────────────────
read -rp "$(echo -e "${YELLOW}Do you want to clean these junk files now? [y/N]: ${NC}")" CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo -e "${RED}❌ Cleanup aborted by user.${NC}"
  exit 0
fi

# ───── Cleanup Starts ─────────────────────────────────────────────────────────
echo -e "${GREEN}Cleaning started...${NC}" | tee "$LOG_FILE"

# 1. APT Cache
echo -e "${YELLOW}Cleaning APT cache...${NC}" | tee -a "$LOG_FILE"
apt clean >> "$LOG_FILE" 2>&1

# 2. Thumbnail Cache
echo -e "${YELLOW}Cleaning thumbnail cache...${NC}" | tee -a "$LOG_FILE"
rm -rf "$THUMB_CACHE"/* >> "$LOG_FILE" 2>&1

# 3. User Cache
echo -e "${YELLOW}Cleaning user cache...${NC}" | tee -a "$LOG_FILE"
rm -rf "$USER_CACHE"/* >> "$LOG_FILE" 2>&1

# 4. Journal Logs
echo -e "${YELLOW}Vacuuming journal logs to 100MB...${NC}" | tee -a "$LOG_FILE"
journalctl --vacuum-size=100M >> "$LOG_FILE" 2>&1

# ───── Done ───────────────────────────────────────────────────────────────────
echo -e "${GREEN}Cleaning done.${NC}" | tee -a "$LOG_FILE"
echo -e "${BLUE}✅ Report saved to:${NC} $LOG_FILE"

