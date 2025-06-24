# ============================================
# __FUNC_NORMAL_SCAN - Perform a normal scan for open ports on the target domain
# ============================================
# - Runs Nmap with decoy hosts and stealth mode to scan the top 100 ports
# - Outputs the raw scan results to a file and checks for open ports
# - Saves the scan results, including the list of open ports, to a result file
# ============================================

# Waiting time for execution
TIMEOUT=5
TIMEOUT_NMAP=30

__FUNC_NORMAL_SCAN() {

    # Files
    NORMAL_SCAN_RAW_FILE="${TXT_DIR}/${DOMAIN}-ports-normal-raw.txt"
    NORMAL_SCAN_RESULT_FILE="${TXT_DIR}/${DOMAIN}-ports-normal.txt"
    
    print_info "${SCAN_START_TOP100}"
    print_info "${SCAN_STEALTH_MODE}"
    
    # Run Nmap with output and decoy
    nmap -D RND:20 --open -sS --top-ports=100 --osscan-guess \
    --scan-delay 500ms --max-rate 50 --data-length 50 \
    --randomize-hosts "${DOMAIN}" -oN "${NORMAL_SCAN_RAW_FILE}" > /dev/null 2>&1

    SCAN_TOP=$(grep -i ' open ' "${NORMAL_SCAN_RAW_FILE}")
    
    {
        line
        echo "${SCAN_RESULT_NORMAL}: ${DOMAIN}"
        line

        if [[ -n "${SCAN_TOP//[[:space:]]/}" ]]; then
            echo "${SCAN_TOP}"
        else
            echo "${SCAN_NO_OPEN_PORTS_TOP100}"
        fi

        separator
        echo "${DATE}"
        line

    } | tee "${NORMAL_SCAN_RESULT_FILE}"

    separator
    print_bg "###### ${FINISHED}: ${SCAN_TOP100_TITLE}"
    separator
    print_success "${SAVED_RESULT} ${NORMAL_SCAN_RESULT_FILE}"
    createFile "ports-normal" "${SCAN_TOP100_TITLE} - ${DOMAIN}"
}

# ============================================
# __FUNC_ADVANCED_SCAN - Perform an advanced scan for open ports on the target domain
# ============================================
# - Runs Nmap with optimized scanning parameters to scan the top 5000 ports
# - Uses decoy hosts and fast scanning options to minimize detection
# - Outputs the raw scan results to a file and checks for open ports
# - Saves the scan results, including the list of open ports, to a result file
# - Extracts and saves port numbers for later use
# ============================================

__FUNC_ADVANCED_SCAN() {

    # Files
    ADVANCE_SCAN_RAW_FILE="${TXT_DIR}/${DOMAIN}-ports-advanced-raw.txt"
    ADVANCE_SCAN_RESULT_FILE="${TXT_DIR}/${DOMAIN}-ports-advanced.txt"

    print_warning "${SCAN_WARNING_TRAFFIC_CPU}"
    print_warning "${SCAN_LOCAL_NETWORK_WARNING}"
    print_info "${SCAN_CLOUD_RECOMMENDATION}"

    # Running Nmap with fast and optimized scanning and decoy
    nmap -D RND:10 --open -sS \
    --top-ports 5000 \
    --min-rate 1000 \
    --max-retries 1 \
    --scan-delay 30ms \
    --data-length 50 \
    --mtu 144 "${DOMAIN}" -oN "${ADVANCE_SCAN_RAW_FILE}" > /dev/null 2>&1

    SCAN_PORTS=$(grep -i ' open ' "${ADVANCE_SCAN_RAW_FILE}")

    # Save the results
    {
        line
        echo "${SCAN_RESULT_ADVANCED}: ${DOMAIN}"
        line
        
        if [[ -n "${SCAN_PORTS//[[:space:]]/}" ]]; then
            echo "${SCAN_PORTS}"
        else
            echo "${SCAN_NO_OPEN_PORTS_ADVANCED}"
        fi

        separator
        echo "${DATE}"
        line

    } | tee "${ADVANCE_SCAN_RESULT_FILE}"

    separator
    print_bg "###### ${FINISHED}: ${SCAN_ALLPORTS_TITLE}"
    separator
    print_success "${SAVED_RESULT} ${ADVANCE_SCAN_RESULT_FILE}"
    createFile "ports-advanced" "${SCAN_ALLPORTS_TITLE} - ${DOMAIN}"

    # Extract and save only the port numbers for later use (used below)
    if [[ -n "${SCAN_PORTS//[[:space:]]/}" ]]; then
        grep -oE '[0-9]+/' "${ADVANCE_SCAN_RAW_FILE}" | cut -d'/' -f1 | sort -n | uniq > "${PORT_LIST_RESULT_FILE}"
    fi
}

# ============================================
# __FUNC_UDP_SCAN - Perform a UDP scan for open ports on the target domain
# ============================================
# - Runs Nmap with optimized parameters to scan the top 100 UDP ports
# - Uses decoy hosts and fast scanning options to minimize detection
# - Checks for open UDP ports and outputs the results to a raw file
# - Saves the scan results, including the list of open UDP ports, to a result file
# - Handles scan failure and prints an error if the scan doesn't complete successfully
# ============================================

__FUNC_UDP_SCAN() {

    # Files
    UDP_SCAN_RAW_FILE="${TXT_DIR}/${DOMAIN}-ports-udp-raw.txt"
    UDP_SCAN_RESULT_FILE="${TXT_DIR}/${DOMAIN}-ports-udp.txt"

    print_info "${SCAN_START_UDP}"
    
    # UDP scan of top 100 ports
    nmap -D RND:10 -sU --open \
    --top-ports=100 \
    --min-rate 800 \
    --max-retries 2 \
    --scan-delay 50ms \
    --mtu 144 "${DOMAIN}" -oN "${UDP_SCAN_RAW_FILE}" > /dev/null 2>&1

    if [ $? -ne 0 ]; then
        print_error "${SCAN_UDP_FAILED}"
        return 3
    fi
    
    UDP_SCAN=$(grep -i ' open ' "${UDP_SCAN_RAW_FILE}")
    
    {   
        line
        echo "${SCAN_RESULT_UDP}: ${DOMAIN}"
        line
        
        if [ -n "${UDP_SCAN}" ]; then
            echo "${UDP_SCAN}"
        else
            echo "${SCAN_NO_OPEN_UDP_PORTS}"
        fi

        separator
        echo "${DATE}"
        line

    } | tee "${UDP_SCAN_RESULT_FILE}"

    separator
    print_bg "###### ${FINISHED}: ${SCAN_UDP_TITLE}"
    separator
    print_success "${SAVED_RESULT} ${UDP_SCAN_RESULT_FILE}"
    createFile "ports-udp" "${SCAN_UDP_TITLE} - ${DOMAIN}"
}

# ============================================
# __FUNC_ALL_PORTS - Combine open ports from multiple scans and output the list
# ============================================
# - Combines open ports found in both normal and advanced scans
# - Extracts unique port numbers from the raw scan results
# - Saves the list of open ports to a result file for further use
# - Creates a formatted, comma-separated list of ports for Nmap usage
# - Handles scenarios where no open ports are found or extraction fails
# ============================================

__FUNC_ALL_PORTS() {
    
    # Files
    PORT_LIST_RESULT_FILE="${TXT_DIR}/${DOMAIN}-ports-list.txt"

    # Combine the ports from the two previous scans
    OPEN_PORTS=$(grep -i ' open ' "${NORMAL_SCAN_RAW_FILE}" 2>/dev/null || echo "")
    OPEN_PORTS_FULL=$(grep -i ' open ' "${ADVANCE_SCAN_RAW_FILE}" 2>/dev/null || echo "")
    
    # Displays the open ports found
    if [[ -n "${OPEN_PORTS//[[:space:]]/}" || -n "${OPEN_PORTS_FULL//[[:space:]]/}" ]]; then
        print_success "${SCAN_OPEN_PORTS_LIST}:"
        
        # Extract only ports from both scans
        ALL_PORTS=$(echo -e "${OPEN_PORTS}\n${OPEN_PORTS}_FULL" | grep -oE '[0-9]+/' | cut -d'/' -f1 | sort -n | uniq)
        
        if [[ -n "${ALL_PORTS}" ]]; then
            # Saves the list of ports for use by other functions
            
            echo "${ALL_PORTS}" > "${PORT_LIST_RESULT_FILE}"
            
            # Create a formatted list for Nmap (comma separated)
            DOMAIN_PORTS=$(echo "${ALL_PORTS}" | paste -sd,)

            {
                line
                echo "${SCAN_OPEN_PORTS_LIST}: ${DOMAIN}"
                line
                echo "${DOMAIN_PORTS}"
            } | tee "${PORT_LIST_RESULT_FILE}"

        else
            print_warning "${SCAN_PORT_EXTRACTION_FAIL}"
        fi
    else
        print_warning "${SCAN_NO_OPEN_PORTS_BOTH}"
    fi
    
    # Export the DOMAIN PORTS variable for global use
    export DOMAIN_PORTS
}

# ============================================
# __FUNC_PORT_VERSION - Check service versions for open ports
# ============================================
# - Loads the formatted list of open ports from the previous scan results
# - Runs Nmap with service version detection to identify services running on open ports
# - Outputs the detected service versions to a result file
# - Handles cases where no port list is found or no services are detected
# ============================================

__FUNC_PORT_VERSION() {

    # Files
    PORT_VERSION_RAW_FILE="${TXT_DIR}/${DOMAIN}-ports-version-raw.txt"
    PORT_VERSION_RESULT_FILE="${TXT_DIR}/${DOMAIN}-ports-version.txt"

    # Load the formatted list of ports if it exists
    if [[ -f "${PORT_LIST_RESULT_FILE}" ]]; then
        if [[ -z "${DOMAIN_PORTS}" ]]; then
            DOMAIN_PORTS=$(grep -E '^[0-9,]+$' "${PORT_LIST_RESULT_FILE}" | tr -d ' \n\r')
        fi
    else
        print_warning "${SCAN_NO_PORT_LIST_FILE}"
        return
    fi
    
    print_info "${SCAN_CHECKING_SERVICE_VERSIONS}:\n${DOMAIN_PORTS}"
    
    # Running Nmap for service detection
    nmap -D RND:10 --open -sV \
    --version-intensity 2 \
    --min-rate 800 \
    --max-retries 2 \
    --scan-delay 50ms \
    --data-length 50 \
    --mtu 144 -p "${DOMAIN_PORTS}" "${DOMAIN}" -oN "${PORT_VERSION_RAW_FILE}" > /dev/null 2>&1

    SERVICE_PORTS=$(grep -i ' open ' "${PORT_VERSION_RAW_FILE}")

    {
        line
        echo "${SCAN_SERVICE_RESULT_FOR}: ${DOMAIN}"
        line

        if [ -n "${SERVICE_PORTS}" ]; then
            echo "${SERVICE_PORTS}"
        else
            echo "${SCAN_NO_SERVICES_FOUND}"
        fi

        separator
        echo "${DATE}"
        line

    } | tee "${PORT_VERSION_RESULT_FILE}"

    separator
    print_bg "###### ${FINISHED}: ${SCAN_SERVICES_FILE_TITLE}"
    separator
    print_success "${SAVED_RESULT} ${PORT_VERSION_RESULT_FILE}"
    createFile "ports-version" "${SCAN_SERVICES_FILE_TITLE} - ${DOMAIN}"
}

# ============================================
# __FUNC_PORT_CONNECT - Check the connectivity of open ports
# ============================================
# - Loads the formatted list of open ports from the previous scan results
# - Tests the connectivity of each open port using a simple TCP connection
# - Outputs the connection results (whether the port is accessible or not) to a result file
# - Handles cases where no port list is found
# ============================================

__FUNC_PORT_CONNECT() {

    # Files
    PORT_CONNECT_RESULT_FILE="${TXT_DIR}/${DOMAIN}-ports-connection.txt"

    if [[ -f "${PORT_LIST_RESULT_FILE}" ]]; then
        PORT_LIST=$(grep -E '^[0-9,]+$' "${PORT_LIST_RESULT_FILE}" | tr -d ' \r' | tr ',' '\n')
    else
        print_warning "${SCAN_NO_PORT_LIST_FILE}"
        return
    fi
    
    print_info "${SCAN_TESTING_CONN}"
    {  
        line
        echo "${SCAN_CONN_RESULT_FOR}: ${DOMAIN}"
        line

        for PORT_CONNECT in ${PORT_LIST//,/ }; do
            if timeout "${TIMEOUT}"s bash -c "echo > /dev/tcp/${DOMAIN}/${PORT_CONNECT}" 2>/dev/null; then
                echo -e "${SCAN_PORT} ${PORT_CONNECT} - ${SCAN_YES_CONN}"
            else
                echo -e "${SCAN_PORT} ${PORT_CONNECT} - ${SCAN_NO_CONN}"
            fi
        done

        separator
        echo "${DATE}"
        line

    } | tee "${PORT_CONNECT_RESULT_FILE}"

    separator
    print_bg "###### ${FINISHED}: ${SCAN_CONN_TITLE}"
    separator
    print_success "${SAVED_RESULT} ${PORT_CONNECT_RESULT_FILE}"
    createFile "ports-connection" "${SCAN_CONN_TITLE} - ${DOMAIN}"
}

# ============================================
# __FUNC_PORT_HEADER - Check HTTP headers for open ports
# ============================================
# - Loads the formatted list of open ports from the previous scan results
# - For each port, sends a request to check for common HTTP headers (Location, Server, X-Powered-By, Content-Type)
# - Outputs the headers found for each port, or indicates if no headers were found
# - Handles cases where no port list is found or no ports are available to check
# ============================================

__FUNC_PORT_HEADER() {

    # Files
    PORT_HEADER_RESULT_FILE="${TXT_DIR}/${DOMAIN}-ports-header.txt"
    
    if [[ -f "${PORT_LIST_RESULT_FILE}" ]]; then
        PORT_LIST=$(grep -E '^[0-9,]+$' "${PORT_LIST_RESULT_FILE}" | tr -d ' \r' | tr ',' '\n')
    else
        print_warning "${SCAN_NO_PORT_LIST_FILE}"
        return
    fi

    if [[ -z "${PORT_LIST}" ]]; then
        print_warning "${SCAN_NO_PORTS_TO_CHECK_HEADERS}"
        return
    fi

    print_info "${SCAN_CHECKING_HEADERS} ${DOMAIN}"

    {
        line
        echo "${SCAN_HEADER_RESULT}: ${DOMAIN}"
        line

        for PORT in ${PORT_LIST}; do
            HEADERS=$(timeout "${TIMEOUT}"s ${CURL} -ILks \
            -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36" \
            -H "Accept: */*" \
            -H "Accept-Language: en-US,en;q=0.9" \
            -H "Connection: keep-alive" \
            --compressed \
            "${DOMAIN}:${PORT}" 2>/dev/null | grep -Ei 'Location|Server|x-powered-by|Content-Type')

            if [[ -n "${HEADERS}" ]]; then
                echo -e "${SCAN_HEADER_FOR_PORT} ${PORT}\n${HEADERS}\n"
            else
                echo -e "${SCAN_NO_HEADER} ${PORT}\n"
            fi
        done

        separator
        echo "${DATE}"
        line

    } | tee "${PORT_HEADER_RESULT_FILE}"

    separator
    print_bg "###### ${FINISHED}: ${SCAN_SAVED_TITLE}"
    separator
    print_success "${SAVED_RESULT} ${PORT_HEADER_RESULT_FILE}"
    createFile "ports-header" "${SCAN_SAVED_TITLE} - ${DOMAIN}"
}

# ================================================
# __FUNC_WEB_SCAN - Scan common web ports and gather HTTP service information
# ================================================
# - Scans common web service ports: 80, 443, 8080, 8443 for the specified domain
# - Uses Nmap with specific scripts to gather information about HTTP services:
#     - http-enum: HTTP service enumeration
#     - http-headers: HTTP headers
#     - http-title: HTTP title of the web pages
# - If any HTTP services are detected, it captures and displays the port, title, headers, and enumeration data
# - If no web services are found, it indicates that no HTTP services are available
# ================================================

__FUNC_WEB_SCAN() {

    # Files
    PORT_WEB_RAW_FILE="${TXT_DIR}/${DOMAIN}-ports-web-raw.txt"
    PORT_WEB_RESULT_FILE="${TXT_DIR}/${DOMAIN}-ports-web.txt"

    # Check common web ports (80, 443, 8080, 8443)
    print_info "${SCAN_WEB_START}: 80, 443, 8080, 8443"
    
    # Specific scanning for web services
    nmap -D RND:20 -Pn -T2 -p 80,443,8080,8443 \
    --min-rate 300 \
    --max-retries 1 \
    --scan-delay 200ms \
    --data-length 48 \
    --mtu 144 \
    --source-port 53 \
    --script http-enum,http-headers,http-title \
    "${DOMAIN}" -oN "${PORT_WEB_RAW_FILE}" > /dev/null 2>&1
    
    if [ $? -ne 0 ]; then
        print_warning "${SCAN_WEB_FAILED}"
        return 3
    fi
    
    # Enum
    WEB_BLOCK=$(awk '/^80\/tcp.*open/ {p=1} p {print} p && /^$/ {exit}' "${PORT_WEB_RAW_FILE}")
    
    # Capture the port line
    HTTP_PORT_WEB=$(echo "${WEB_BLOCK}" | grep '^80/tcp')

    # Capture the title
    HTTP_TITLE_WEB=$(echo "${WEB_BLOCK}" | grep '_http-title:' | sed 's/^|_http-title: //')

    # Capture headers
    HTTP_HEAD_WEB=$(echo "${WEB_BLOCK}" | sed -n '/http-headers:/,/^ *$/p' | grep '^|   ' | sed 's/^|   //')

    # Capture enumeration (http-enum block)
    HTTP_ENUM_WEB=$(awk '/http-enum:/,/^ *\|_/' "${PORT_WEB_RAW_FILE}" | grep '^|   ' | sed "s/^|   /https:\/\/${DOMAIN}/")

    {
        line
        echo "${SCAN_WEB_RESULT}: ${DOMAIN}"
        line
        
        if [ -n "${WEB_BLOCK}" ]; then
            echo -e "${SCAN_WEB_SERVICES_FOUND}:\n${HTTP_PORT_WEB}\n${HTTP_TITLE_WEB}\n${HTTP_HEAD_WEB}\n${HTTP_ENUM_WEB}"
        else
            echo "${SCAN_NO_WEB_SERVICES}"
        fi

        separator
        echo "${DATE}"
        line

    } | tee "${PORT_WEB_RESULT_FILE}"

    separator
    print_bg "###### ${FINISHED}: ${SCAN_WEB_TITLE}"
    separator
    print_success "${SAVED_RESULT} ${PORT_WEB_RESULT_FILE}"
    createFile "ports-web" "${SCAN_WEB_TITLE} - ${DOMAIN}"
}

# ================================================
# __FUNC_VULN_SCAN - Scan ports for known vulnerabilities using Nmap
# ================================================
# - Scans specified ports for vulnerabilities using Nmap's 'vuln' NSE (Nmap Scripting Engine) scripts
# - It uses the domain's ports, which are loaded from the previously saved port list
# - Nmap runs with custom parameters, such as random decoys, scan delay, and reduced retries
# - The function looks for vulnerabilities in services running on the scanned ports and outputs any findings
# - If vulnerabilities are found, they are saved in a raw file and reported with details
# - If no vulnerabilities are found, the function indicates that as well
# ================================================

__FUNC_VULN_SCAN() {

    # Files
    PORT_VUL_RAW_FILE="${TXT_DIR}/${DOMAIN}-ports-vulnerabilities-raw.txt"
    PORT_VUL_RESULT_FILE="${TXT_DIR}/${DOMAIN}-ports-vulnerabilities.txt"

    # Load the formatted list of ports if it exists
    if [[ -f "${PORT_LIST_RESULT_FILE}" ]]; then
        if [[ -z "${DOMAIN_PORTS}" ]]; then
            DOMAIN_PORTS=$(grep -E '^[0-9,]+$' "${PORT_LIST_RESULT_FILE}" | tr -d ' \n\r')
        fi
    else
        print_warning "${SCAN_NO_PORT_LIST_FILE}"
        return
    fi
    
    print_info "${SCAN_VULN_START} ${DOMAIN_PORTS}"
    
    # Vulnerability scanning with NSE scripts
    nmap -D RND:20 -T3 --open -p "${DOMAIN_PORTS}" --script vuln --script-timeout ${TIMEOUT_NMAP}s --max-retries 1 --min-rate 300 --scan-delay 100ms --data-length 50 --mtu 144 "${DOMAIN}" -oN "${PORT_VUL_RAW_FILE}" > /dev/null 2>&1
    
    if [[ ! -f "${PORT_VUL_RAW_FILE}" ]]; then
        print_warning "${SCAN_NO_PORT_LIST_FILE}"
        return
    fi

    VULN_SCAN=$(grep -A 10 "VULNERABLE" "${PORT_VUL_RAW_FILE}" || echo "")
    
    {   
        line
        echo "${SCAN_VULN_RESULT}: ${DOMAIN}"
        line
        
        if [ -n "${VULN_SCAN}" ]; then
            echo -e "${SCAN_VULNERABILITIES_FOUND}:\n${VULN_SCAN}"
        else
            echo "${SCAN_NO_VULNERABILITIES_FOUND}"
        fi

        separator
        echo "${DATE}"
        line

    } | tee "${PORT_VUL_RESULT_FILE}"

    separator
    print_bg "###### ${FINISHED}: ${SCAN_VULN_TITLE}"
    separator
    print_success "${SAVED_RESULT} ${PORT_VUL_RESULT_FILE}"
    createFile "ports-vulnerabilities" "${SCAN_VULN_TITLE} - ${DOMAIN}"
}

# Clean
[[ -f "${NORMAL_SCAN_RAW_FILE}" ]] && rm "${NORMAL_SCAN_RAW_FILE}"
[[ -f "${ADVANCE_SCAN_RAW_FILE}" ]] && rm "${ADVANCE_SCAN_RAW_FILE}"
[[ -f "${UDP_SCAN_RAW_FILE}" ]] && rm "${UDP_SCAN_RAW_FILE}"
[[ -f "${PORT_VERSION_RAW_FILE}" ]] && rm "${PORT_VERSION_RAW_FILE}"
[[ -f "${PORT_WEB_RAW_FILE}" ]] && rm "${PORT_WEB_RAW_FILE}"
[[ -f "${PORT_VUL_RAW_FILE}" ]] && rm "${PORT_VUL_RAW_FILE}"