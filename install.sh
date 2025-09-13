#!/usr/bin/env bash
set -euo pipefail
GREEN="\033[32m"; RED="\033[31m"; CYAN="\033[36m"; BOLD="\033[1m"; RESET="\033[0m"

APPDIR="$HOME/job-hunt-tool"
SRCDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${CYAN}${BOLD}==> Installing Job Hunt Tool${RESET}"
echo "Target directory: $APPDIR"
mkdir -p "$APPDIR"

echo -e "${CYAN}==> Copying project files...${RESET}"
if ! cp -a "$SRCDIR"/. "$APPDIR"/; then
  echo -e "${RED}${BOLD}ERROR:${RESET} Failed to copy files from $SRCDIR to $APPDIR"
  echo "Press ENTER to close..."; read; exit 1
fi

chmod +x "$APPDIR"/src/*.sh || true

echo -e "${CYAN}==> Installing dependencies (this may prompt for your password)...${RESET}"
sudo apt update || { echo -e "${RED}${BOLD}ERROR:${RESET} apt update failed"; echo "Press ENTER to close..."; read; exit 1; }
sudo apt install -y printer-driver-cups-pdf inotify-tools zenity rsync gnome-terminal libnotify-bin   || { echo -e "${RED}${BOLD}ERROR:${RESET} Failed to install dependencies"; echo "Press ENTER to close..."; read; exit 1; }

if snap list 2>/dev/null | grep -q '^firefox\b'; then
  echo -e "${CYAN}==> Connecting snap Firefox to cups-control${RESET}"
  sudo snap connect firefox:cups-control || true
fi

echo -e "${CYAN}==> Installing icon into user theme (hicolor)...${RESET}"
ICON_DIR="$HOME/.local/share/icons/hicolor/scalable/apps"
mkdir -p "$ICON_DIR"
cp "$APPDIR/share/icons/job-hunt-tool.svg" "$ICON_DIR/job-hunt-tool.svg"   || { echo -e "${RED}${BOLD}ERROR:${RESET} Failed to install icon"; echo "Press ENTER to close..."; read; exit 1; }
if [[ -f "$HOME/.local/share/icons/hicolor/index.theme" ]] && command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -f "$HOME/.local/share/icons/hicolor" || true
fi

echo -e "${CYAN}==> Installing systemd user unit...${RESET}"
mkdir -p "$HOME/.config/systemd/user"
cp "$APPDIR/systemd/job-hunt-tool.service" "$HOME/.config/systemd/user/"   || { echo -e "${RED}${BOLD}ERROR:${RESET} Failed to install systemd unit"; echo "Press ENTER to close..."; read; exit 1; }
systemctl --user daemon-reload
systemctl --user enable job-hunt-tool.service || true

# Strict .env requirement (fail hard)
if [[ ! -f "$APPDIR/.env" ]]; then
  echo -e "${RED}${BOLD}============================================================${RESET}"
  echo -e "${RED}${BOLD} ERROR: $APPDIR/.env not found!${RESET}"
  echo -e "${RED}${BOLD}============================================================${RESET}"
  echo
  echo -e "${CYAN}${BOLD}Create it manually before proceeding:${RESET}"
  echo "  cp $APPDIR/.env.example $APPDIR/.env"
  echo "  nano $APPDIR/.env   # or use your editor"
  echo
  echo "After creating it, start the service with:"
  echo "  systemctl --user start job-hunt-tool.service"
  echo
  echo -e "${RED}${BOLD}ABORTING INSTALLATION.${RESET}  ${RED}The tool cannot run without a valid .env file.${RESET}"
  echo
  echo "Press ENTER to close..."; read
  exit 1
fi

echo -e "${CYAN}==> Starting service...${RESET}"
if ! systemctl --user start job-hunt-tool.service; then
  echo -e "${RED}${BOLD}ERROR:${RESET} Failed to start job-hunt-tool.service"
  echo "Press ENTER to close..."; read; exit 1
fi

echo -e "${CYAN}==> Installing application launcher...${RESET}"
SRC="$APPDIR/share/applications/job-hunt-tool.desktop"
if [[ ! -f "$SRC" ]]; then
  echo -e "${RED}${BOLD}ERROR:${RESET} Launcher file missing at $SRC"
else
  mkdir -p "$HOME/.local/share/applications"
  cp "$SRC" "$HOME/.local/share/applications/"
  chmod +x "$HOME/.local/share/applications/job-hunt-tool.desktop"

  DESKTOP_DIR="$(xdg-user-dir DESKTOP 2>/dev/null || echo "$HOME/Desktop")"
  if [[ -d "$DESKTOP_DIR" ]]; then
    cp "$SRC" "$DESKTOP_DIR/"
    chmod +x "$DESKTOP_DIR/job-hunt-tool.desktop"
    gio set "$DESKTOP_DIR/job-hunt-tool.desktop" metadata::trusted true 2>/dev/null || true
    echo -e "${GREEN}${BOLD}==> Desktop launcher installed to $DESKTOP_DIR${RESET}"
  else
    echo -e "${RED}Note:${RESET} Desktop directory not found, skipping desktop icon."
  fi
fi

echo -e "${GREEN}${BOLD}Install complete!${RESET}"
echo "Press ENTER to close..."; read
