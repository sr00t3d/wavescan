# ============================================
# WaveScan - Config file
# ============================================

# Author and Version
# Feel free to modify if you have a fork or your own version of this script.
# Otherwise, all contributors can be found here: http://github.com/percioandrade/wavescan/contributors
AUTHOR="Percio Andrade"
GIT="https://github.com/percioandrade/wavescan/"
CONFIG_FILE="https://raw.githubusercontent.com/percioandrade/wavescan/refs/heads/main/config.sh"
SRC_VERSION="2.0"

# Sets the locale for text output formatting
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

# Set the script language
# Other language codes are available in /lang/
LANGUAGE="pt-BR"

if [ -n "${LANGUAGE}" ]; then
    source ./lang/${LANGUAGE}.sh
fi

# SCAN
# This is a series of scripts to run tools like nmap, gobuster, dirb, and others.
# All of them are related to each other.
# When running the scan, make sure to set TRUE for "__FUNC_NORMAL_SCAN" and "__FUNC_ADVANCED_SCAN".
# Files from this scan are used in other types of scans.

# src_scan.sh
__FUNC_NORMAL_SCAN=true
__FUNC_ADVANCED_SCAN=true
__FUNC_UDP_SCAN=true
__FUNC_ALL_PORTS=true
__FUNC_PORT_VERSION=true
__FUNC_PORT_CONNECT=true   
__FUNC_PORT_HEADER=true
__FUNC_WEB_SCAN=true
__FUNC_VULN_SCAN=true
## 

# Domain/IP
# All functions here are independent. You can enable or disable each one individually
# by setting them to true or false.

# src_frame.sh
__FUNC_CHECK_FRAME=true

# src_waf.sh
__FUNC_CHECK_WAF=true

# scr_tech.sh
__FUNC_CHECK_TECH=true

# src_http.sh
__FUNC_CHECK_HTTP=true

# src_source.sh
__FUNC_CHECK_SOURCE=true

# scr_css
__FUNC_CHECK_CSS=true

# src_path
__FUNC_CHECK_PATH=true

# src_dir
__FUNC_CHECK_DIR=true

# src_files
__FUNC_CHECK_FILES=true

# src_index.sh
__FUNC_CHECK_INDEX=true

# src_fuzz.sh
__FUNC_CHECK_FUZZ=true

# src_ftp.sh
__FUNC_CHECK_FTP=true

# src_sql.sh
__FUNC_CHECK_SQL=true
SQLMAP_DELAY=3
SQLMAP_TIMEOUT=15
SQLMAP_RETRIES=2
SQLMAP_THREADS=10
SQLMAP_LEVEL=2
SQLMAP_RISK=1

# Number of threads to use during the process
THREADS=30

# Date
DATE=$(echo "${SCAN_MADE_ON_DATE}: $(date '+%d-%m-%Y %H:%M:%S')")

# Set the version of curl-impersonate to use
CURL="/usr/local/bin/curl_ff100"

# Set the default string value for MODE
MODE="${CONFIG_NORMAL_MODE}"

# Set the initial warning delay time
WAIT_BANNER_TIME="5"

# Colors
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
BOLD="\033[1m"
BG="\e[43;30m"
RESET="\033[0m"

YOURIP=$(curl -s ifconfig.me/ip)

# Function to apply wordlist to all types
apply_wordlist() {
    local VALUE="$1"
    WORDLIST="${VALUE}"
    WORDLIST_AZUL="${VALUE}"
    WORDLIST_WEBBIG="${VALUE}"
    WORDLIST_FUZZ="${VALUE}"
    WORDLIST_LFD="${VALUE}"
    WORDLIST_TRANSVERSAL="${VALUE}"
}

# SECList Wordlist Directory
WORDLIST_DIR="/usr/share/wordlists/seclists"
SECLISTS_DIR="/opt/SecLists"
DEV_LIST="/usr/share/devlist/dev.txt"
WORDLIST="/usr/share/wordlists/dirb/big.txt"
WORDLIST_AZUL="${WORDLIST_DIR}/Passwords/unkown-azul.txt"
WORDLIST_WEBBIG="${WORDLIST_DIR}/Discovery/Web-Content/big.txt"
WORDLIST_FUZZ="/usr/share/wordlists/seclists/Fuzzing/environment-identifiers.txt"
WORDLIST_LFD="/usr/share/wordlists/seclists/Discovery/Web-Content/burp-parameter-names.txt"
WORDLIST_TRANSVERSAL="/usr/share/wordlists/seclists/Fuzzing/LFI/LFI-Jhaddix.txt"

# Check quick mode
if [ "$2" = "--fast" ] || [ "$2" = "-f" ]; then
    MODE="${CONFIG_FAST_MODE}"
    apply_wordlist "/usr/share/wordlists/dirb/small.txt"
fi

# Check dev mode
if [ "$2" = "--dev" ] || [ "$2" = "-d" ]; then
    MODE="${CONFIG_DEV_MODE}"
    # Specify the path to your custom list
    # By default, the development list is created at /usr/share/custom/seclists/dev.txt
    # It contains only one value for debugging (assets)
    apply_wordlist "${DEV_LIST}"
fi

# Debug mode
if [ "$2" = "--debug" ] || [ "$2" = "-db" ]; then
    echo "${CONFIG_DEBUG_MODE}"

    echo "WordLists"
    cat <<EOF

  WordList Directory  : ${WORDLIST_DIR}
  Standard WordList   : ${WORDLIST}
  WordList Blue       : ${WORDLIST_AZUL}
  Wordlist Web        : ${WORDLIST_WEBBIG}
  Wordlist Fuzz       : ${WORDLIST_FUZZ}
  Wordlist LFD        : ${WORDLIST_LFD}
  Wordlist Trasversal : ${WORDLIST_TRANSVERSAL}
  Wordlist Dev        : ${DEV_LIST}

EOF
    exit
fi