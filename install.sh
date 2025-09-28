#!/usr/bin/env bash
set -euo pipefail
GREEN="\033[32m"; RED="\033[31m"; CYAN="\033[36m"; BOLD="\033[1m"; RESET="\033[0m"

APPDIR="$HOME/job-hunt-tool"
SRCDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${CYAN}${BOLD}==> Installing Job Hunt Tool${RESET}"
echo "Target directory: $APPDIR"
mkdir -p "$APPDIR"

echo -e "${CYAN}==> Copying project files (excluding Git metadata)...${RESET}"
if command -v rsync >/dev/null 2>&1; then
  # Prefer rsync if available
  if ! rsync -a --delete \
      --exclude=".git/" --exclude=".gitignore" --exclude=".gitattributes" --exclude=".gitmodules" \
      "$SRCDIR"/ "$APPDIR"/; then
    echo -e "${RED}${BOLD}ERROR:${RESET} Failed to copy files with rsync"
    echo "Press ENTER to close..."; read; exit 1
  fi
else
  # Portable fallback using tar to exclude .git*
  if ! ( tar -C "$SRCDIR" \
        --exclude=".git" --exclude=".git/*" \
        --exclude=".gitignore" --exclude=".gitattributes" --exclude=".gitmodules" \
        -cf - . | tar -C "$APPDIR" -xf - ); then
    echo -e "${RED}${BOLD}ERROR:${RESET} Failed to copy files (tar fallback)"
    echo "Press ENTER to close..."; read; exit 1
  fi
fi

chmod +x "$APPDIR"/src/*.sh || true
chmod +x "$APPDIR"/src/*.sh || true

# ✅ Replace the old apt install section with this:
echo -e "${CYAN}==> Checking dependencies...${RESET}"
deps=(printer-driver-cups-pdf inotify-tools zenity rsync gnome-terminal libnotify-bin)
missing=()
for p in "${deps[@]}"; do
  dpkg -s "$p" >/dev/null 2>&1 || missing+=("$p")
done

if ((${#missing[@]})); then
  echo -e "${CYAN}==> Installing missing deps: ${missing[*]}${RESET}"
  sudo dpkg --configure -a || true
  sudo apt update || { echo -e "${RED}${BOLD}ERROR:${RESET} apt update failed"; echo "Press ENTER to close..."; read; exit 1; }
  if ! sudo apt install -y "${missing[@]}"; then
    echo -e "${RED}${BOLD}ERROR:${RESET} Failed to install dependencies"; echo "Press ENTER to close..."; read; exit 1
  fi
else
  echo -e "${GREEN}All dependencies already installed. Skipping apt.${RESET}"
fi

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
