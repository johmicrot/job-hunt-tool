#!/usr/bin/env bash
set -euo pipefail
SERVICE=job-hunt-tool.service

GREEN="\033[32m"; RED="\033[31m"; CYAN="\033[36m"; BOLD="\033[1m"; RESET="\033[0m"

USER_HOME="$HOME"

echo -e "${CYAN}${BOLD}============================================================${RESET}"
echo -e "${CYAN}${BOLD}                   Job Hunt Tool Toggle                     ${RESET}"
echo -e "${CYAN}${BOLD}============================================================${RESET}"
echo -e "${CYAN}${BOLD}Purpose:${RESET} Enable/disable the background service that watches your CUPS-PDF folder"
echo -e "and files printed job postings into /home/<user>/jobs/YYYY/MM/DD.urlname/"
echo -e "while copying your cover letter and an optionally selected resume set."
echo -e "(${CYAN}On this system:${RESET} ${USER_HOME}/jobs/YYYY/MM/DD.urlname/)"
echo

if systemctl --user is-active --quiet "$SERVICE"; then
    systemctl --user stop "$SERVICE"
    echo -e "Action: ${RED}${BOLD}Stopped${RESET} $SERVICE"
else
    systemctl --user start "$SERVICE"
    echo -e "Action: ${GREEN}${BOLD}Started${RESET} $SERVICE"
fi

if systemctl --user is-active --quiet "$SERVICE"; then
    echo -e "Current state: ${GREEN}${BOLD}active (running)${RESET}"
else
    echo -e "Current state: ${RED}${BOLD}inactive (stopped)${RESET}"
fi

echo
echo -e "Manage manually: ${BOLD}systemctl --user start|stop|status job-hunt-tool.service${RESET}"
echo
echo "Press ENTER to close..."; read
