# Job Hunt Tool

Organizes printed job postings from Firefox (CUPS-PDF) into:
```
$HOME/jobs/YYYY/MM/DD.urlname/job.pdf
```
- `urlname` is derived from the print job title, sanitized (lowercase, non-alphanumerics -> '-', trimmed, max 80).

## Required .env
Create `$HOME/job-hunt-tool/.env` from the template:
```bash
cp $HOME/job-hunt-tool/.env.example $HOME/job-hunt-tool/.env
nano $HOME/job-hunt-tool/.env
```
Variables:
- `DEST_ROOT` – where organized jobs go
- `COVER_LETTER` – your cover letter file
- `RESUME_DIR` – parent dir containing subfolders for resume sets (e.g., `python/`, `data-science/`)
- `WATCH_DIR` – CUPS-PDF output dir (default `$HOME/PDF`)

## Install
```bash
unzip job-hunt-tool-colored.zip -d ~/
bash ~/job-hunt-tool/install.sh
```
If `.env` is missing, the installer aborts with a red error banner.

## Toggle
Run **Job Hunt Tool (Toggle)** from your app menu/desktop to start/stop the watcher (colored output).

## Uninstall
```bash
bash ~/job-hunt-tool/uninstall.sh
```
