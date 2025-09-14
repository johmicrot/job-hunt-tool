# Job Hunt Tool

> Automate saving job postings and bundling resumes/cover letters into organized folders — so you can focus on applying, not file management.

---

## ✨ What is this?
While job hunting, I noticed I was doing a lot of **manual clicking, pasting, renaming, and moving files** every time I applied somewhere. Saving job postings as PDFs, renaming them, creating folders, copying the right resume + cover letter… it added up.

So I built **Job Hunt Tool** — an automation that listens for PDFs printed from Firefox/Brave/Chromium, renames and files them into a structured directory, and drops in your chosen resume set + cover letter.

---

## 🤔 Why?
Did I spend ~4 hours making an automation tool that saves ~40 seconds per application?  

**Yessir.**  

But sometimes it’s more about the **adventure of building tools** than the raw time saved. Along the way, it reinforced my skills with:  
- Linux automation (CUPS-PDF, inotify)  
- Bash scripting best practices  
- Packaging scripts as a portable, installable app  
- Creating desktop launchers and systemd user services  

---

## 📂 How it works
- You print a job posting via **CUPS-PDF** printer.  
- The watcher script sees the new PDF.  
- It files it into:
  ```
  ~/jobs/YYYY/MM/DD.urlname/job.pdf
  ```
- Copies your **cover letter** into the same folder.  
- Prompts you to select one of your **resume sets** from `RESUME_DIR`, and copies it into a subfolder.  

Example:
```
~/jobs/2025/09/13.coolstartup/
    job.pdf
    JohnRothmanCoverLetter.docx
    resumes/python/resume.pdf
```

---

## ⚙️ Setup
1. Clone and install:
   ```bash
   git clone https://github.com/johmicrot/job-hunt-tool.git
   cd job-hunt-tool
   bash install.sh
   ```

2. Create your `.env` (the tool won’t run without it):
   ```bash
   cp .env.example .env
   nano .env
   ```
   - `DEST_ROOT` = root folder where organized jobs are stored  
   - `COVER_LETTER` = path to your cover letter file  
   - `RESUME_DIR` = folder containing subfolders of resume variants  
   - `WATCH_DIR` = usually your CUPS-PDF output folder  

---

## 🖥️ Usage
- Click the **Job Hunt Tool Toggle** desktop icon to enable/disable the background watcher.  
- Print a job posting → it gets automatically filed.  
- A dialog lets you pick which resume set to copy.  

---

## 📜 License
This is a personal project shared publicly.  
If you’d like to reuse or adapt it, feel free — but please credit the original work.  
(If needed, an MIT license can be added later for clarity.)  

---

### 🧑‍💻 Final Thought
This project is less about shaving seconds and more about **reinforcing skills in Linux automation, system integration, and workflow design**. If it inspires you to automate even tiny annoyances in your own workflow, then it was worth every minute. 🚀
