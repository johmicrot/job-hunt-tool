#!/usr/bin/env bash
set -euo pipefail
PROJ_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$PROJ_DIR/.env"

# Colors for logs (service logs will include ANSI; safe in journalctl)
GREEN="\033[32m"; RED="\033[31m"; CYAN="\033[36m"; BOLD="\033[1m"; RESET="\033[0m"

if [[ ! -f "$ENV_FILE" ]]; then
  echo -e "${RED}${BOLD}ERROR:${RESET} $ENV_FILE not found. Create it from .env.example." >&2
  exit 1
fi
# shellcheck disable=SC1090
source "$ENV_FILE"

mkdir -p "$WATCH_DIR" "$DEST_ROOT"

sanitize() {
  echo "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g' \
    | cut -c1-200
}
can_show_gui() {
  command -v zenity >/dev/null 2>&1 && [[ -n "${DISPLAY:-}" ]]
}

select_resume_set() {
  [[ -d "$RESUME_DIR" ]] || return 1
  mapfile -t sets < <(find "$RESUME_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)
  [[ ${#sets[@]} -gt 0 ]] || return 1
  if can_show_gui; then
    zenity --list --title="Select resume set" --text="Choose which resume set to copy:"            --column="Resume set" --hide-header --height=360 --width=480 "${sets[@]}" || true
  else
    echo -e "${CYAN}Note:${RESET} GUI not available (no DISPLAY); skipping resume set prompt." >&2
    return 1
  fi
}

prompt_edit_urlname() {
  local suggested="$1" edited
  if command -v zenity >/dev/null 2>&1 && [[ -n "${DISPLAY:-}" ]]; then
    edited="$(printf '%s' "$suggested" | zenity --text-info \
      --editable \
      --title="Confirm folder name" \
      --width=900 --height=420 \
      --filename=/dev/stdin \
      --ok-label="Use this name" --cancel-label="Keep suggestion" 2>/dev/null || true)"

    # If user typed something, sanitize it; otherwise keep suggested
    if [[ -n "$edited" ]]; then
      # collapse newlines/spaces before sanitizing
      edited="$(echo "$edited" | tr '\n' ' ' | sed -E 's/[[:space:]]+/ /g' | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')"
      edited="$(sanitize "$edited")"
      if [[ -n "$edited" ]]; then
        echo "$edited"
        return 0
      fi
    fi
  fi
  echo "$suggested"
}


echo -e "${CYAN}${BOLD}Job Hunt Tool watcher started.${RESET} Watching: $WATCH_DIR"
inotifywait -m -e close_write --format '%w%f' "$WATCH_DIR" | while read -r file; do
  [[ "${file,,}" == *.pdf ]] || continue
  name_noext="$(basename "$file" .pdf)"
  name_suggested="$(sanitize "$name_noext")"
  name_sanitized="$(prompt_edit_urlname "$name_suggested")"




  year="$(date +%Y)"; month="$(date +%m)"; day="$(date +%d)"
  folder="${DEST_ROOT}/${year}/${month}/${day}.${name_sanitized}"
  mkdir -p "$folder"
  [[ -f "$COVER_LETTER" ]] && cp -n "$COVER_LETTER" "$folder/" || true
  choice="$(select_resume_set || true)"
  if [[ -n "${choice:-}" && -d "$RESUME_DIR/$choice" ]]; then
    mkdir -p "$folder/$choice"
    rsync -a --ignore-existing "$RESUME_DIR/$choice"/ "$folder/$choice"/
  fi

  # Copy contents of $ADDITIONAL_DIR into "$folder/<basename(ADDITIONAL_DIR)>/"
  if [[ -n "${ADDITIONAL_DIR:-}" && -d "$ADDITIONAL_DIR" ]]; then
    shared_name="$(basename -- "${ADDITIONAL_DIR%/}")"
    dest_shared="$folder/$shared_name"
    mkdir -p "$dest_shared"
    # Trailing slash on source copies contents only
    rsync -a --ignore-existing -- "$ADDITIONAL_DIR"/ "$dest_shared"/
  fi
  
  outfile="${folder}/job.pdf"
  if [[ -e "$outfile" ]]; then
    n=2; while [[ -e "${folder}/job-${n}.pdf" ]]; do ((n++)); done
    outfile="${folder}/job-${n}.pdf"
  fi
  mv -f "$file" "$outfile"
  echo -e "${GREEN}Filed:${RESET} $outfile"
  command -v notify-send >/dev/null 2>&1 && notify-send "Job Hunt Tool" "Filed: $outfile" || true
done
