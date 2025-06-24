# ==============================================================
# WaveScan - Core file
# ==============================================================
# - Loads global settings and modules automatically.
# - Executes initial checks and detects OS.
# - Optionally installs packages if requested via command-line argument.
# - Runs a series of scans for port, vulnerability, HTTP headers, web application, and other potential threats.
# - Summarizes and generates a final report with results and scans.
# ==============================================================

INPUT="$1"

# Argument checking
if [ -z "$1" ]; then
    print_error "${CORE_SPECIFY_DOMAIN}"
    print_warning "${CORE_USAGE}: $0 ${CORE_DOMAIN_OR_IP}"
    exit
fi

# Functions for printing colored messages
print_success() { echo -e "${GREEN}[+]${RESET} $1"; }
print_warning() { echo -e "${YELLOW}[!]${RESET} $1"; }
print_error() { echo -e "${RED}[>]${RESET} $1"; }
print_info() { echo -e "${BLUE}[*]${RESET} $1"; }
print_finish() { echo -e "${BLUE}[*]${RESET} $1"; }
print_normal() { echo -e "$1"; }
print_bg() { echo -e "${BG}[*]${RESET} $1"; }

# Checks for the existence of a command
check_command() {
    command -v "$1" >/dev/null 2>&1 || { print_error "${COMMAND_NOT_FOUND_INSTALLING}"; return 1; }
    return 0
}

# Set the domain or IP
checkinput() {
    print_success "-.--.--.--.--.- ${CORE_STARTING_WAIT} -.--.--.--.--.-"

    # Check if input is empty
    if [[ -z "${INPUT}" ]]; then
        print_error "${CORE_NO_DOMAIN_OR_IP_PROVIDED}"
        exit 1
    fi

    # Check if it is IP
    if [[ "${INPUT}" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        DOMAIN="${INPUT}"
        print_success "${CORE_VALID_IP_DETECTED}: ${DOMAIN}"
        exit 0
    fi

    # Check the domain format
    if ! [[ "${INPUT}" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        print_error "${CORE_INVALID_DOMAIN_IP}: ${INPUT}"
        exit 1
    fi

    BASE_DOMAIN="${INPUT#www.}"

    TEST_PLAIN="http://${BASE_DOMAIN}"
    TEST_WWW="http://www.${BASE_DOMAIN}"

    PLAIN_OK=false
    WWW_OK=false

    # Function to validate response without redirect
    test_domain() {
        local URL="$1"
        local RESPONSE
        RESPONSE=$(curl -ks --head --max-time 3 --location-trusted "${URL}")
        
        local HTTP_CODE
        HTTP_CODE=$(echo "${RESPONSE}" | grep -i '^HTTP/' | tail -n1 | awk '{print $2}')
        
        # Get the HTTP code from 200 to 599
        if [[ "${HTTP_CODE}" =~ ^[2-5] ]]; then
            return 0
        else
            return 1
        fi
    }

    print_info "${CORE_TESTING_DOMAIN_NO_WWW}: ${TEST_PLAIN}"
    if test_domain "${TEST_PLAIN}"; then
        PLAIN_OK=true
    fi

    print_info "${CORE_TESTING_DOMAIN_WITH_WWW}: ${TEST_WWW}"
    if test_domain "${TEST_WWW}"; then
        WWW_OK=true
    fi

    if [[ "${PLAIN_OK}" == true ]]; then
        DOMAIN="${BASE_DOMAIN}"
        print_success "${CORE_USING_VERSION_NO_WWW}: ${DOMAIN}"
    elif [[ "${WWW_OK}" == true ]]; then
        DOMAIN="www.${BASE_DOMAIN}"
        print_success "${CORE_USING_VERSION_WITH_WWW}: ${DOMAIN}"
    else
        print_error "${CORE_DOMAIN_OR_IP_INACCESSIBLE}: ${INPUT}"
        exit 1
    fi

    # Now correctly detects HTTPS/HTTP
    TEST_HTTPS="https://${DOMAIN}"
    TEST_HTTP="http://${DOMAIN}"
    HTTPS_OK=false
    HTTP_OK=false

    print_info "${CORE_TESTING_DOMAIN_WITH_SSL}: ${TEST_HTTPS}"
    if test_domain "${TEST_HTTPS}"; then
        HTTPS_OK=true
    fi

    if [[ "${HTTPS_OK}" == true ]]; then
        PROTOCOL="https"
        print_success "${CORE_USING_DOMAIN_WITH_SSL}: ${PROTOCOL}://${DOMAIN}"
    else
        print_info "${CORE_TESTING_DOMAIN_NO_SSL}: ${TEST_HTTP}"
        if test_domain "${TEST_HTTP}"; then
            HTTP_OK=true
        fi

        if [[ "${HTTP_OK}" == true ]]; then
            PROTOCOL="http"
            print_success "${CORE_USING_DOMAIN_NO_SSL}: ${PROTOCOL}://${DOMAIN}"
        else
            print_error "${CORE_DOMAIN_OR_IP_INACCESSIBLE}: ${INPUT}"
            exit 1
        fi
    fi

    DIR=$(pwd)

    IMG="img"
    TXT="txt"
    PDF="pdf"

    # Mount full default URL
    TARGET_URL="${PROTOCOL}://${DOMAIN}"
    
    # Like: http(s)://domain.tld < only
    #: Info frame.sh get the other part of url if site uses iframe to server content

    TXT_DIR="${DIR}/${DOMAIN}/${TXT}"
    IMG_DIR="${DIR}/${DOMAIN}/${IMG}"
    PDF_DIR="${DIR}/${DOMAIN}/${PDF}"

    if [[ -e "${DIR}/${DOMAIN}" ]]; then
        print_warning "${CORE_DIRECTORY_EXIST} ${DIR}/${DOMAIN} ${CORE_DIRECTORY_CONTINUE} (y/n)"
        read -p "${CONTINUE_SCAN} " CONTINUE
    
        if [[ "${CONTINUE}" =~ ^[nN]$ ]]; then
            print_error "${CORE_SCAN_ABORT} ${DOMAIN}"
            exit
        fi 
    fi 
}

# Check update
checkversion(){

    # Remote version
    WAVE_REMOTE_VERSION=$(curl -s "${CONFIG_FILE}" | grep SRC_VERSION  | awk -F= '{print $2}' | sed 's/"//g')
    
    # Local version
    WAVE_LOCAL_VERSION=$(grep "SRC_VERSION" config.sh | awk -F= '{print $2}' | sed 's/"//g')

    if [[ -z "${WAVE_REMOTE_VERSION}" ]]; then
        print_error "${CORE_VERSION_NOT_FOUND}"
    else
        if [[ "${WAVE_REMOTE_VERSION}" > "${WAVE_LOCAL_VERSION}" ]]; then
            print_info "${CORE_UPDATE_FOUND}: ${CORE_NEW_VERSION_IS} ${WAVE_REMOTE_VERSION}"
            print_warning "${CORE_GET_UPDATE}..."

            # Try with git first
            if [[ -d "${DIR}/.git" ]]; then
                print_info "${CORE_GITDIR_FOUND}..."
                git pull
            else
            # else try with curl
                print_info "${CORE_DOWNLOADING_FILES}..."
                # Here we use normal curl
                curl -L "${GIT}/archive/refs/heads/main.zip" -o repo.zip
                unzip -o repo.zip
                rm repo.zip
                mv wavescan-main/* .
                rmdir wavescan-main
            fi

            if [[ "${WAVE_LOCAL_VERSION}" == "${WAVE_REMOTE_VERSION}" ]]; then
                print_success "${CORE_FILES_UPDATED}"
            else
                print_error "${CORE_UPDATE_FAIL} ${GIT}"  
            fi
        fi
    fi
}

# Function to detect operating system and architecture
detect_os() {
    # Initialize with default values
    OS_NAME="unknown"
    OS_VERSION=""
    OS_FAMILY=""
    SERVER_TYPE=""

    # Detect CPU architecture
    ARCH=$(uname -m)
    case "${ARCH}" in
        x86_64|amd64)
            SERVER_TYPE="x86_64"
            ;;
        aarch64|arm64)
            SERVER_TYPE="arm64"
            ;;
        armv7l|armhf)
            SERVER_TYPE="armhf"
            ;;
        i*86)
            SERVER_TYPE="i386"
            ;;
        *)
            SERVER_TYPE="${ARCH}"
            ;;
    esac

    # Primary detection via /etc/os-release (modern Linux distros)
    if [ -f /etc/os-release ]; then
        # Source the file to get variables
        . /etc/os-release
        OS_NAME="${ID,,}" # Convert to lowercase
        OS_VERSION="${VERSION_ID}"
        
        # Determine OS family
        case "${OS_NAME}" in
            "ubuntu"|"debian"|"pop"|"kali"|"mint"|"elementary")
                OS_FAMILY="debian"
                ;;
            "fedora"|"rhel"|"centos"|"rocky"|"almalinux"|"ol")
                OS_FAMILY="redhat"
                ;;
            "arch"|"manjaro"|"endeavouros")
                OS_FAMILY="arch"
                ;;
            "opensuse-leap"|"opensuse-tumbleweed"|"sles")
                OS_FAMILY="suse"
                ;;
            "alpine")
                OS_FAMILY="alpine"
                ;;
            *)
                OS_FAMILY="${OS_NAME}"
                ;;
        esac
    # Fallback detection methods
    elif [ -f /etc/redhat-release ]; then
        OS_FAMILY="redhat"
        if grep -q "CentOS" /etc/redhat-release; then
            OS_NAME="centos"
        elif grep -q "Red Hat" /etc/redhat-release; then
            OS_NAME="rhel"
        elif grep -q "Fedora" /etc/redhat-release; then
            OS_NAME="fedora"
        fi
        OS_VERSION=$(grep -oE '[0-9]+\.[0-9]+' /etc/redhat-release | cut -d . -f1)
    elif [ -f /etc/debian_version ]; then
        OS_FAMILY="debian"
        if [ -f /etc/lsb-release ]; then
            . /etc/lsb-release
            OS_NAME="${DISTRIB_ID,,}"
            OS_VERSION="${DISTRIB_RELEASE}"
        else
            OS_NAME="debian"
            OS_VERSION=$(cat /etc/debian_version)
        fi
    # Add detection for additional systems
    elif [ -f /etc/arch-release ]; then
        OS_NAME="arch"
        OS_FAMILY="arch"
        OS_VERSION="rolling"
    elif [ "$(uname -s)" = "Darwin" ]; then
        OS_NAME="darwin"
        OS_FAMILY="darwin"
        OS_VERSION=$(sw_vers -productVersion)
        
        # For macOS, refine architecture detection
        if [ "${SERVER_TYPE}" = "arm64" ]; then
            # Check if running under Rosetta 2
            if sysctl -n sysctl.proc_translated &>/dev/null && [ "$(sysctl -n sysctl.proc_translated)" -eq 1 ]; then
                SERVER_TYPE="arm64_rosetta"
            fi
        fi
    fi
    
    # Export variables for use in other functions
    export OS_NAME OS_VERSION OS_FAMILY SERVER_TYPE VIRT_TYPE
}

# Function for package installation
installpkg() {
    print_info "${CORE_INSTALLING_PKG}"

    # Define packages based on operating system family
    case "${OS_FAMILY}" in
        "debian")
                SYSTEM_PACKAGES=(
                    "dirb" "ffuf" "fonts-dejavu" "gobuster" "hydra" "libnss3" "mailutils" "nss-plugin-pem" "wafw00f"
                    "wfuzz" "whatweb" "build-essential"
                )
            ;;
        "redhat")
                print_info "Enabling epel-repo"
                yum install epel-release && yum update
                SYSTEM_PACKAGES=(
                    "dejavu-fonts" "gcc-c++" "libcurl-devel" "libffi-devel" "yaml-cpp-devel" "nss" "nss-pem"
                    "openssl-devel" "python3-devel" "readline" "readline-devel" "sqlite-devel" "zlib" "zlib-devel"
                )
            ;;
        "arch")
                SYSTEM_PACKAGES=(
                    "base-devel" "go" "libffi" "nss" "python" "python-pip"  "zlib" 	"gnupg" "mailutils" "poppler"
                    "inetutils" "gnu-netcat"         
                )
            ;;
        "darwin")
                    SYSTEM_PACKAGES=(
                        "nss" "gnupg" "msmtp" "poppler" "inetutils" "gnu-netcat" "python" "python-pip" "gnupg" "fontconfig"
                    )
            ;;
        *)
            print_warning "${CORE_UNKNOW_OS}: ${OS_FAMILY}"
            SYSTEM_PACKAGES=()
            ;;
    esac

    # Common packages for all systems
    COMMON_PACKAGES=(
        "make" "cmake" "autoconf" "automake" "ca-certificates" "bison" "bzip2" "gcc" "golang" "gpg" "libtool"
        "mailx" "coreutils" "curl" "enscript" "findutils" "ghostscript" "git" "grep" "jq" "netpbm" "nmap"
        "poppler-utils" "sed" "wget" "ftp" "netcat" "openssl" "patch" "python3" "python3-pip" "gnupg2"
    )

    # Combine all package lists
    ALL_PACKAGES=("${SYSTEM_PACKAGES[@]}" "${COMMON_PACKAGES[@]}")

    # Display packages to be installed
    print_info "${CORE_PKG_BE_INSTALLED}: ${ALL_PACKAGES[*]}"

    # Install packages using the appropriate package manager
    install_packages "${ALL_PACKAGES[@]}"

    # Install custom security tools based on OS family
    case "${OS_FAMILY}" in
        "redhat"|"arch")
            install_custom_security_tools
            ;;
        "darwin")
            install_macos_security_tools
            ;;
    esac

    print_success "${CORE_PKG_INSTALLED}"
}

# Helper function to install custom security tools
install_custom_security_tools() {
    local TEMP_DIR="/tmp/security_tools"
    mkdir -p "${TEMP_DIR}"
    cd "${TEMP_DIR}" || { print_error "${CORE_FAILED_TEMP_DIR}"; return 1; }

    # Install Ruby v3
    RUBY_BIN="/usr/bin/ruby3.3"
    RUBY_VERSION=$(ruby -v | cut -d. -f2)

    if [[ ! -f "${RUBY_BIN}" || "${RUBY_VERSION}" -lt 3 ]]; then
        print_info "${CORE_INSTALL_RUBY}..."
        curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -
        curl -sSL https://get.rvm.io | bash -s stable
        source /etc/profile.d/rvm.sh
        rvm install 3.3
        rvm use 3.3 --default
        print_success "${CORE_INSTALLED_RUBY}..."
    fi

    # Install Python tools
    if ! command -v wafw00f &>/dev/null; then
        print_info "${CORE_INSTALL_WAFW00F}..."
        pip3 install dataclasses wafw00f wfuzz
        print_success "${CORE_INSTALLED_WAFW00F}"
    fi

    # Install Hydra
    if ! command -v hydra &>/dev/null; then
        print_info "${CORE_INSTALL_HYDRA}..."
        git clone https://github.com/vanhauser-thc/thc-hydra.git
        (cd thc-hydra && ./configure && make && make install)
        print_success "${CORE_INSTALLED_HYDRA}"
    fi

    # Install GoBuster
    if ! command -v gobuster &>/dev/null; then
        print_info "${CORE_INSTALL_GOBUSTER}..."
        git clone https://github.com/OJ/gobuster.git
        (cd gobuster && go build && install -m 755 gobuster /usr/local/bin/)
        print_success "${CORE_INSTALLED_GOBUSTER}"
    fi
    
    # FFUF
    if ! command -v ffuf &>/dev/null; then
        print_info "${CORE_INSTALL_FFUF}"
        git clone https://github.com/ffuf/ffuf.git
        (cd ffuf && go get && go build && install -m 755 ffuf /usr/local/bin/)
        print_success "${CORE_INSTALLED_FFUF}"
    fi

    # Install Dirb if not already present
    if ! command -v dirb &>/dev/null; then
        print_info "${CORE_INSTALL_DIRB}..."
        git clone https://github.com/v0re/dirb.git
        (cd dirb && ./configure && make && make install)
        print_success "${CORE_INSTALLED_DIRB}"
    fi

    # Install WhatWeb if not already present
    if ! command -v dirb &>/dev/null; then
        print_info "${CORE_INSTALL_WHATWEB}..."
        git clone https://github.com/urbanadventurer/WhatWeb.git
        (cd WhatWeb && gem install bundler && bundle install)
        print_success "${CORE_INSTALLED_WHATWEB}"
    fi

    # Install sqlmap if not already present
    if ! command -v sqlmap &>/dev/null; then
        print_info "${CORE_INSTALL_SQLMAP}..."
        git clone --depth 1 https://github.com/sqlmapproject/sqlmap.git /opt/sqlmap
        sudo ln -s /opt/sqlmap/sqlmap.py /usr/local/bin/sqlmap
        sudo chmod +x /opt/sqlmap/sqlmap.py
        echo "${CORE_INFO_SQLMAP}"
        print_info "${CORE_INSTALL_SQLMAP}..."
    fi

    # Clean up
    cd - >/dev/null
    print_info "${CORE_CLEANUP_TEMP}..."
    rm -rf "${TEMP_DIR}"
    print_success "${CORE_TOOLS_INSTALLED}"
}

# Helper function to install macOS security tools
install_macos_security_tools() {
    print_info "${CORE_INSTALL_FOR_MACOS}..."
    
    # Check if Homebrew is installed
    if ! command -v brew &>/dev/null; then
        print_error "${CORE_INSTALL_HOMEBREW}"
        print_info "${CORE_VISIT_HOMEBREW}"
        return 1
    fi
    
    # Install security tools via Homebrew
    brew install hydra gobuster dirb nmap
    
    # Install Python-based tools
    pip3 install wafw00f wfuzz
    
    # Install Go-based tools if not available via Homebrew
    if ! command -v ffuf &>/dev/null; then
        TEMP_DIR="/tmp/security_tools"
        mkdir -p "${TEMP_DIR}"
        cd "${TEMP_DIR}" || return 1
        
        git clone https://github.com/ffuf/ffuf.git
        (cd ffuf && go get && go build && install -m 755 ffuf /usr/local/bin/)
        
        cd - >/dev/null
        rm -rf "${TEMP_DIR}"
    fi
}

# Generic package installation function
install_packages() {
    local packages=("$@")
    local failed_packages=()
    
    case "${OS_FAMILY}" in
        "debian")
            apt-get update
            for pkg in "${packages[@]}"; do
                if ! apt-get install -y "${pkg}"; then
                    failed_packages+=("${pkg}")
                fi
            done
            ;;
        "redhat")
            if command -v dnf &>/dev/null; then
                for pkg in "${packages[@]}"; do
                    if ! dnf install -y "${pkg}"; then
                        failed_packages+=("${pkg}")
                    fi
                done
            else
                for pkg in "${packages[@]}"; do
                    if ! yum install -y "${pkg}"; then
                        failed_packages+=("${pkg}")
                    fi
                done
            fi
            ;;
        "arch")
            pacman -Syu --needed --noconfirm
            for pkg in "${packages[@]}"; do
                if ! pacman -S --needed --noconfirm "${pkg}"; then
                    # Try AUR if package not in official repos
                    if command -v yay &>/dev/null; then
                        if ! yay -S --needed --noconfirm "${pkg}"; then
                            failed_packages+=("${pkg}")
                        fi
                    elif command -v paru &>/dev/null; then
                        if ! paru -S --needed --noconfirm "${pkg}"; then
                            failed_packages+=("${pkg}")
                        fi
                    else
                        failed_packages+=("${pkg}")
                    fi
                fi
            done
            ;;
        "darwin")
            # Ensure Homebrew is installed
            if ! command -v brew &>/dev/null; then
                print_error "${CORE_HOMEBREW_NOT_INSTALLED}."
                return 1
            fi
            
            brew update
            for pkg in "${packages[@]}"; do
                if ! brew install "${pkg}"; then
                    failed_packages+=("${pkg}")
                fi
            done
            ;;
        *)
            print_error "${CORE_PKG_INSTALL_NOT_SUPPORTED} ${OS_FAMILY}"
            return 1
            ;;
    esac
    
    # Report any failed packages
    if [ ${#failed_packages[@]} -gt 0 ]; then
        print_warning "${CORE_FAILED_PKGS}: ${failed_packages[*]}"
        print_info "${CORE_CONTINUE_INSTALL_PKG}..."
        return 1
    fi
    
    return 0
}

# Get curl impersonate
curl_impersonate() {
    # Check if a version of curl-impersonate is already installed
    if [ ! -f "/usr/local/bin/curl_ff100" ]; then

        print_info "${CORE_CLONE_IMPERSONATE}..."

        # Detect the architecture and choose the file version to download
        if [[ "${SERVER_TYPE}" == "x86_64" ]]; then
            DOWNLOAD_URL="https://github.com/lwthiker/curl-impersonate/releases/download/v0.6.1/curl-impersonate-v0.6.1.x86_64-linux-gnu.tar.gz"
        elif [[ "${SERVER_TYPE}" == "aarch64" ]]; then
            DOWNLOAD_URL="https://github.com/lwthiker/curl-impersonate/releases/download/v0.6.1/curl-impersonate-v0.6.1.aarch64-linux-gnu.tar.gz"
        else
            print_error "${CORE_UNKNOW_OS}: ${SERVER_TYPE}"
            return 1
        fi
        
        # Download the correct file for the architecture
        TMP_DIR="/tmp/curimp"
        mkdir -p "$TMP_DIR"
        wget -q --show-progress "${DOWNLOAD_URL}" -O "${TMP_DIR}/curl-impersonate.tar.gz"
        tar -xzf "${TMP_DIR}/curl-impersonate.tar.gz" -C "$TMP_DIR"
        sudo cp "$TMP_DIR"/* /usr/local/bin/
        sudo chmod +x /usr/local/bin/curl*

        print_success "${CORE_CURL_IMPERSONATE_INSTALLED}"

    fi
}

# Seclist function
seclist() {
    
    # Clone SecLists if not already present
    if [ ! -d "${SECLISTS_DIR}" ]; then

        print_info "${CORE_DOWNLOADING_SECLIST}"
        print_warning "${CORE_DOWNLOADING_SECLIST_INFO}"

        git clone https://github.com/danielmiessler/SecLists.git "${SECLISTS_DIR}"

        # Create wordlists directory and symlinks
        mkdir -p "${WORDLIST_DIR}"
        ln -sf "${SECLISTS_DIR} ${WORDLIST_DIR}"
        print_success "${CORE_INSTALLED_SECLIST}"

    fi
    
    # Create the devlist for debug
    if [ ! -f "${DEV_LIST}" ]; then
        print_info "${CORE_CREATING_DEV_LIST}"
        mkdir /usr/share/devlist/
        touch ${DEV_LIST}
        echo "assets" > ${DEV_LIST} \
        && print_success "${CORE_DEV_LIST_CREATED}" \
        || print_error "${CORE_FAILED_CREATE_DEV_LIST}"
    fi
}

# Creating required directories
setup_directories() {
    for DIRS in "${DIR}/${DOMAIN}" "${TXT_DIR}" "${IMG_DIR}" "${PDF_DIR}"; do
        if [ ! -d "${DIRS}" ]; then
            mkdir -p "${DIRS}" && print_success "${CORE_DIRECTORY_CREATED}: ${DIRS}" || print_error "${CORE_FAILED_TO_CREATE} ${DIRS}"
        fi
    done
    cd "${DIR}/${DOMAIN}" || exit 1
}

# Improved function to create archives
createFile() {
    local TYPE="$1"
    local TITLE="$2"

    local FILE_TXT="${TXT_DIR}/${DOMAIN}-${TYPE}.txt"
    local FILE_PDF="${PDF_DIR}/${DOMAIN}-${TYPE}.pdf"
    local FILE_IMG="${IMG_DIR}/${DOMAIN}-${TYPE}.png"

    if [[ -s "${FILE_TXT}" ]]; then
        print_info "${CORE_GENERATING_VISUAL_REPORT}: ${TYPE}"

        local CLEAN_TXT="${FILE_TXT}.clean"
        sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,3})*)?[mGK]//g" "${FILE_TXT}" > "${CLEAN_TXT}"

        local LATIN_TXT="${FILE_TXT}.latin1"
        if ! iconv -f UTF-8 -t LATIN1//TRANSLIT "${CLEAN_TXT}" -o "${LATIN_TXT}" 2>/dev/null; then
            print_warning "${CORE_UNKNOWN_CHARACTER}..."
            iconv -f UTF-8 -t LATIN1//IGNORE "${CLEAN_TXT}" -o "${LATIN_TXT}"
        fi

        if enscript -B -q --lines-per-page=9999 --output=- -f "Courier10" -b "${TITLE}" "${LATIN_TXT}" \
        | ps2pdf - "${FILE_PDF}"; then

            # Convert pages to PNGs and merge them into a single image
            local TMP_IMG_PREFIX="${IMG_DIR}/${DOMAIN}-${TYPE}"
            
            # Adjust density to improve quality
            pdftoppm -r 300 "${FILE_PDF}" "${TMP_IMG_PREFIX}" -png

            # Trimming extra space from images and stacking without unwanted space
            for PAGE in ${TMP_IMG_PREFIX}-*.png; do
                convert "${PAGE}" -fuzz 10% -trim +repage "${PAGE}"
            done

            # Now join the cropped images without the spaces
            convert "${TMP_IMG_PREFIX}"-*.png -append -quality 92 "${FILE_IMG}"

            # Remove temporary images
            rm -f "${TMP_IMG_PREFIX}"-*.png

            print_success "${CORE_IMAGE_SUCCESSFULLY_GENERATED}: ${FILE_IMG}"
        else
            print_error "${CORE_FAILED_TO_GENERATE_IMAGE}"
        fi

        rm -f "${CLEAN_TXT}" "${LATIN_TXT}" 2>/dev/null
    else
        print_warning "${CORE_EMPTY_OR_MISSING_FILE}: ${FILE_TXT}"
    fi
}

# Function to clear ASCII colors to write in txt
cleancolor(){
    sed -E 's/^https?:\/\/[^ ]+ \[[0-9]{3} [^]]+\] //' | sed -r "s/\x1B\[[0-9;]*[mGKH]//g"
}

# Separation for summary
line(){
    print_normal "- - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
}

# Add lines separator
separator(){
    echo ""
}

# Add a spinner
spinner() {
    local PID=$!
    local DELAY=0.2
    local DOTS=('˦' '˨' '˨')

    tput civis  # Hide cursor
    local i=0

    # Prints the initial message and starts the spinner
    printf "%s" "${MSG:-}"
    while kill -0 ${PID} 2>/dev/null; do
        local dot_index=$(( i % 3 ))
        printf "\r%s%s" "${MSG:-}" "${DOTS[dot_index]}"
        i=$(( i + 1 ))
        sleep ${DELAY}
    done

    # Clears the entire line when the process ends
    printf "\r\033[K"
    tput cnorm
}

# Create a nice and stylish banner, we're talking about the ASCII 'cat' =)
banner() {
    echo -e "${CORE_DISCLAIMER}" | fold -s -w 100
    echo -e "${CORE_DISCLAIMER_IP} [${YOURIP}] ${CORE_DISCLAIMER_IP_FINAL}" | fold -s -w 100
    echo -e "${CORE_DISCLAIMER_FINAL}"
    sleep -e  "${WAIT_BANNER_TIME}"
    clear
    echo -e "${BOLD}

    /^--^\     _ _ _             _____              
    \____/    | | | |___ _ _ ___|   __|___ ___ ___  
    /     \   | | | | .'| | | -_|__   |  _| .'|   | ${CORE_VERSION_TITLE}
   |       |  |_____|__,|\_/|___|_____|___|__,|_|_| ${CORE_TITLE_REMOTE}: ${WAVE_REMOTE_VERSION} | ${CORE_TITLE_LOCAL}: ${WAVE_LOCAL_VERSION}
    \__  _/    ${GIT}                    
       \ \    
        \/    ${CORE_SCRIPT_DIRECTORY}: ${DIR}/${DOMAIN}
        ${RESET}"
print_error "${CORE_INFO_INSTALL}"
sleep 2
print_info "${CORE_SCAN_START_MESSAGE} ${DOMAIN}"
}