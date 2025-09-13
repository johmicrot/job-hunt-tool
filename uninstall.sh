#!/usr/bin/env bash
set -euo pipefail
GREEN="\033[32m"; RED="\033[31m"; CYAN="\033[36m"; BOLD="\033[1m"; RESET="\033[0m"

echo -e "${CYAN}${BOLD}==> Uninstalling Job Hunt Tool${RESET}"

if systemctl --user is-enabled --quiet job-hunt-tool.service 2>/dev/null; then
  echo -e "${CYAN}Stopping and disabling service...${RESET}"
  systemctl --user disable --now job-hunt-tool.service || echo -e "${RED}Note:${RESET} service may not have been running."
else
  echo -e "${CYAN}Service not enabled; skipping stop/disable.${RESET}"
fi

echo -e "${CYAN}Removing files...${RESET}"
rm -f "$HOME/.config/systemd/user/job-hunt-tool.service" || true
systemctl --user daemon-reload || true
rm -rf "$HOME/job-hunt-tool" || true
rm -f "$HOME/.local/share/applications/job-hunt-tool.desktop" || true
DESKTOP_DIR="$(xdg-user-dir DESKTOP 2>/dev/null || echo "$HOME/Desktop")"
rm -f "$DESKTOP_DIR/job-hunt-tool.desktop" || true
rm -f "$HOME/.local/share/icons/hicolor/scalable/apps/job-hunt-tool.svg" || true

echo -e "${GREEN}${BOLD}Uninstall complete.${RESET}"
echo "Press ENTER to close..."; read
