# WaveScan 🌊🔍

Readme: [English](README.md)

<img src="https://github.com/sr00t3d/wavescan/blob/docs/322e87b1-3es2b-4791-b714-369e214e6c1.jpg?raw=true" width="700">

![License](https://img.shields.io/github/license/sr00t3d/bindfilter)
![Shell Script](https://img.shields.io/badge/shell-script-green)

**WaveScan** is a comprehensive web security scanner designed for administrators, developers, and security professionals to perform complete vulnerability assessments. It offers everything from basic port scans to advanced source code and vulnerability analysis, ensuring the integrity of web applications.

## ✨ Detailed Features
WaveScan consolidates a wide range of specialized modules:

### 🛡️ Intelligence and Reconnaissance

- **Multi-Language**: Native support for pt-BR, English, and Spanish.
- **Curl Impersonate**: Uses `curl-impersonate` to perform requests identical to real browsers, bypassing simple detections.
- **Technology Fingerprinting**: Custom wrapper of `WhatWeb` with modern User-Agents to detect CMS (WordPress), libraries, analytics, and servers, saving clean results without ANSI codes.
- **Firewall & WAF Detection**: Identifies web application `firewalls`, `DDoS protections`, and intrusion prevention systems through `traffic analysis`.

### 🔍 Surface and Content Auditing

- **Port Scanning**: `TCP/UDP` port scanning, `service banners`, and `software version` identification on the target host.
- **Iframe Checker**: Extracts `iframe sources` (including relative paths and `.php` files) using `realistic User-Agents`. Allows manual selection if multiple iframes are detected.
- **CSS and Path Analysis**: Scans CSS files for `url(...)` references, reconstructing paths to discover hidden directories (e.g., `/assets/`, `/uploads/`).
- **HTTP Method Check**: Simulates Googlebot to test HTTP methods via `OPTIONS` request, capturing permission headers (`Allow`).

### 🚀 Vulnerability Scanning (Active Scanning)
- **Directory Enumeration**: Uses `gobuster` with `SecLists` wordlists to locate directories and files, filtering status codes (`200`, `301`, `403`).
- **Sensitive File Search**: Focused scanning on exposed files such as `.zip`, `.sql`, `.env`, `.bak`, and `.log`, filtering false positives by response size.
- **PHP Parameter Fuzzing**: Collects URLs and uses `wfuzz` to test parameters for code exposure (e.g., `<?php`) and Path Traversal (`../`).
- **Vulnerability Probing**: Automated testing for `SQLi`, `XSS`, and `Open Redirects` by analyzing server responses.
- **FTP/SSH Checker**: Checks ports `21` and `22`, captures banners with `netcat`, tests anonymous authentication, and performs probes with `hydra` to validate server hardening.
- **Index Check**: Uses `FFUF` to identify `"Index of"` pages and leftover backup files.

📊 Reports and Output
- **Multi-format Summary**: Converts findings into organized reports in PDF, TXT, and PNG (image).
- **Wordlist Management**: Automatic configuration of SecLists, dirb, and creation of custom lists for debugging.

## Requirements

- **OS**: Linux/Unix-based systems (used on Ubuntu).
- **Dependencies**:
  - `curl`
  - `sed`
  - `grep`
  - `awk`
  - `bash`
  - Other standard Unix utilities.

## 🚀 Installation and Usage

1. **Clone the repository**:
    ```bash
    git clone https://github.com/percioandrade/wavescan.git
    cd wavescan && chmod +x wavescan
    ```
    
2. **Install dependencies**:
- Make sure the necessary tools (such as `curl`, `grep`, `sed`, etc.) are installed on your system. You can install them using the package manager.

*The -i parameter installs all dependencies and configures the Wordlists*

## Execution Examples

- **Full Scan**: ./wave.sh your-target.com]
- **Fast Mode (Smaller Wordlists)**: ./wave.sh your-target.com -f
- **Dev Mode (Debug Wordlist)**: ./wave.sh your-target.com -d

⚙️ Configuration

Adjust the active modules and language in the config.sh file:

- **__FUNC_ADVANCED_SCAN**(true/false): Enables advanced scan, slower.
- **__FUNC_NORMAL_SCAN**(true/false): Enables basic scan, faster.
- **__FUNC_NORMAL_SCAN=**(true/false): Disables scan. 
- **LANGUAGE=**"pt-BR": Changes the language; language codes can be viewed in the `lang` directory

## ⚠️ Disclaimer

> [!WARNING]
> This software is provided "as is". Always ensure you have explicit permission before scanning any target. The author is not responsible for any misuse, legal consequences, or data impact caused by this tool.

## 📚 Detailed Tutorial

For a complete, step-by-step guide on how to import generated files into Thunderbird and troubleshoot common migration issues, check out my full article:

👉 [**Make a full OSINT with WaveScan**](https://perciocastelo.com.br/blog/make-a-full-osint-with-wavescan.html)

## 🤝 Credits
Developed based on Pentest concepts from [DESEC Academy](https://academy.desecsecurity.com/introducao-pentest/)

## License 📄

This project is licensed under the **GNU General Public License v3.0**. See the [LICENSE](LICENSE) file for more details.
