<img src="https://github.com/sr00t3d/wavescan/blob/docs/322e87b1-3es2b-4791-b714-369e214e6c1.jpg?raw=true" width="700">

WaveScan is a comprehensive web security scanner designed to help administrators, developers, and security.
professionals perform vulnerability assessments and security scans on websites. It offers a wide range of scan types, from basic port scanning to advanced vulnerability and source code analysis, ensuring the safety and integrity of web applications.

## Features

- **Multi Language**
  - Change language if you need, pt-BR, Spanish and English.

- **Curl impersonate**
  - Ensures `curl-impersonate` is available for the script to make discreet, browser-like requests.

- **WordLists**
  - Manages the setup of `SecLists` also `dirb wordlist` (a collection of security testing wordlists) and creates a **devlist** for debugging.

- **Sumary in pdf, txt and image**
  - Converts a text file into text, PDF, and PNG formats, saving them to specific directories after cleaning and processing.

- **Port Scanning**  
  - Scans for open TCP/UDP ports, services, connection behavior, response headers, and vulnerabilities, identifying software versions on the target host.

- **Iframe Checker**  
  Detects and inspects `<iframe>` elements:  
  - Fetches HTML with a realistic User-Agent.  
  - Extracts iframe sources (relative paths, `.php`, same-domain URLs).  
  - Auto-updates to a single iframe or prompts selection if multiple found.  
  - Logs absence of iframes if none detected.

- **Firewall & WAF Detection**  
  Identifies WAFs, DDoS protection, and intrusion prevention via traffic and response analysis.

- **Technology Fingerprinting**  
  Custom `WhatWeb` wrapper to detect technologies:  
  - Uses modern User-Agent to avoid blocks.  
  - Handles timeouts, removes ANSI codes, deduplicates results.  
  - Lists CMSs, libraries, analytics, servers (e.g., WordPress, Apache, jQuery).  
  - Saves formatted results to a file.

- **HTTP Check Function**  
  Tests HTTP methods with an `OPTIONS` request:  
  - Simulates Googlebot with custom headers.  
  - Captures `Allow` headers and status (e.g., `200 OK`).  
  - Logs to `httpmethods.txt` and console with timestamps.

- **CSS & Path Analysis**  
  Extracts and inspects CSS files (e.g., `style.css`, `bootstrap.min.css`):  
  - Parses `url(...)` references.  
  - Reconstructs paths to uncover hidden directories (e.g., `/assets/`).  
  - Reports CSS files and exposed folders.

- **Directory Enumeration**  
  Uses `gobuster` for directory/file enumeration:  
  - Scans `${TARGET_URL}` with wordlists (e.g., `common.txt`).  
  - Ignores SSL warnings, filters valid codes (200, 301, 403).  
  - Logs first 20 accessible hits and total URLs tested.

- **Sensitive Files Finder**  
  Scans for exposed files (e.g., `.zip`, `.sql`, `.env`) with `gobuster`:  
  - Targets sensitive extensions.  
  - Filters false positives by response size.  
  - Saves and displays detected paths.

- **Vulnerability Scanning**  
  Probes for SQLi, XSS, and open redirects by sending payloads and analyzing responses.

- **Fuzz Check Function**  
  Tests `.php` URLs for vulnerabilities:  
  - Collects URLs with `curl`, fuzzes parameters with `wfuzz`.  
  - Checks code exposure (e.g., `<?php`) and path traversal (e.g., `file=../`).  
  - Logs findings.

- **FTP Checker**  
  Verifies FTP/SFTP/SSH services:  
  - Scans ports 21, 22 with `netcat`, 1-1024 with `nmap`.  
  - Grabs banners, tests FTP (`220`), probes with `hydra`.  
  - Assesses server hardening.

- **Index Check Function**  
  Detects accessible directories/files:  
  - Fuzzes with `FFUF` using wordlists and extensions (e.g., `.bak`, `.log`).  
  - Identifies "Index of" pages, logs to `indexof.txt`.  
  - Cleans temporary files.

- **Comprehensive Reporting**  
  Generates organized, categorized reports for all scan results.

  And more

## Requirements

Before running WaveScan, make sure your system meets the following requirements:

- **Operating System**: Linux/Unix-based systems (tested on Ubuntu).
- **Dependencies**:
  - `curl`
  - `sed`
  - `grep`
  - `awk`
  - `bash`
  - Other standard Unix utilities.

## Installation

1. **Clone the Repository**:
    ```bash
    git clone https://github.com/percioandrade/wavescan.git
    cd wavescan && chmod +x wavescan
    ```

2. **Set up the Configuration**:
   - Edit the `config.sh` and modify the settings according to your requirements:

3. **Install Dependencies**:
   - Make sure that required tools (like `curl`, `grep`, `sed`, etc.) are installed on your system. You can install them using your package manager:
    ```bash
    sudo apt-get install curl sed grep
    ```
   ```bash
    ./wavescan.sh DOMAIN -i
    ```
    or ou can usage -i to install all

## Usage

## Print
<p>
  <img src="https://github.com/sr00t3d/wavescan/blob/docs/1746011437976.jpeg?raw=true" width="500">
  <img src="https://github.com/sr00t3d/wavescan/blob/docs/1746011454351.jpeg?raw=true" width="500">
  <img src="https://github.com/sr00t3d/wavescan/blob/docs/1746011461758.jpeg?raw=true" width="500">
  <img src="https://github.com/sr00t3d/wavescan/blob/docs/1746011470235.jpeg?raw=true" width="500">
  <img src="https://github.com/sr00t3d/wavescan/blob/docs/1746011476711.jpeg?raw=true" width="500">
  <img src="https://github.com/sr00t3d/wavescan/blob/docs/1746011485824.jpeg?raw=true" width="500">
  <img src="https://github.com/sr00t3d/wavescan/blob/docs/1746011493943.jpeg?raw=true" width="500">
  <img src="https://github.com/sr00t3d/wavescan/blob/docs/1746011500954.jpeg?raw=true" width="500">
    
  and more

</p>

### Run the Script

1. **Basic Usage**:
   - To run the script with all modules activated, simply execute:
    ```bash
    ./wavescan.sh DOMAIN
    ```
  **Fast Mode**
  - To run the script with fast modules (small wordlist), simply execute:
      ```bash
    ./wavescan.sh DOMAIN -f
    ```

  **Dev Mode**
   - To run the script with only dev modules (dev wordlist), simply execute:
    ```bash
    ./wavescan.sh DOMAIN -d
    ```

2. **Run with Installation Option**:
   - If you want to install the necessary packages before scanning, use the `-i` or `--install` flag:
    ```bash
    ./wavescan.sh DOMAIN --i
    ```

3. **Run Specific Scans**:
   - The script automatically runs multiple scans depending on your configuration. You can toggle individual scan types in the `config.sh` file (e.g., `__FUNC_NORMAL_SCAN`, `__FUNC_ADVANCED_SCAN`, etc.).

4. **Generate Report**:
   - The script generates a detailed summary report after completion. You can find the summary in the `TXT_DIR`:
    ```bash
    /path/to/output/folder/${DOMAIN}-summary.txt
    ```

5. **Change language**
   If you want change language, alter in config.sh `LANGUAGE` to language name avaible in `lang`

### Example Output

After a scan completes, the following directories will be populated:

- **Text Reports**: Located in `${TXT_DIR}/`
- **Images**: Located in `${IMG_DIR}/`

The `summary.txt` will include an overview of the findings and recommendations.

## Script Functions

- **`checkinput`**: Verifies user input and checks the domain.
- **`checkversion`**: Ensures the script is using the latest version.
- **`detect_os`**: Detects the operating system to optimize scans.
- **`installpkg`**: Installs required dependencies.
- **`main()`**: Executes the core scanning process, calling each module and generating reports.

## Customizing the Script

You can enable or disable specific scan types by modifying the `config.sh` file:

- **Enable Scan**: Set the respective function variable (e.g., `__FUNC_NORMAL_SCAN=true`).
- **Disable Scan**: Set it to `false` (e.g., `__FUNC_NORMAL_SCAN=false`).

This provides flexibility to run only the scans that are relevant to your needs.

## Contributing

We welcome contributions to improve WaveScan! To contribute:

1. Fork the repository.
2. Create a new branch (`git checkout -b feature-name`).
3. Make your changes and commit them (`git commit -am 'Add new feature'`).
4. Push to the branch (`git push origin feature-name`).
5. Open a Pull Request.

## License

WaveScan is open-source and distributed under the MIT License.

## Based on

WaveScan was developed based on the course offered for free by DESEC, available at [DESEC Academy](https://academy.desecsecurity.com/introducao-pentest/). thank you DESEC.

## Contact

For questions, feedback, or support, please open an issue on GitHub or contact us at [percio@zendev.com.br].

---

**Note**: This is a security scanning tool. Ensure that you have permission from the website owner before running any scan. Unauthorized scanning may violate terms of service or applicable laws.
