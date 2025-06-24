# ================================================
# __FUNC_CHECK_FTP - Check FTP and SFTP Services and Security
# ================================================
# - Scans for open FTP/SFTP ports (21, 22, or custom ports)
# - Performs connection test using FTP commands and checks for FTP banner
# - Simulates brute-force attacks using Hydra to check for vulnerabilities
# - Logs results into multiple files for detailed analysis
# - Outputs FTP connection status, vulnerabilities, and brute-force test results
# ================================================

__FUNC_CHECK_FTP() {
    
    print_info "${FTP_CHECK} ${DOMAIN}"

    # Files
    FTP_STATUS_FILE="${TXT_DIR}/${DOMAIN}-ftp-status.txt"
    FTP_CONNECTION_FILE="${TXT_DIR}/${DOMAIN}-ftp-connection.txt"
    FTP_BRUTE_FILE="${TXT_DIR}/${DOMAIN}-ftp-brute.txt"
    FTP_GREP_FILE="${TXT_DIR}/${DOMAIN}-ftp-scan.grep"

    # List of standard ports to check (FTP: 21, SFTP/SSH: 22)
    DEFAULT_PORTS=("21" "22")
    DETECTED_FTP_PORT=""

    # Direct check of standard ports with netcat
    # Here we use netcat for being faster at single port checking
    for port in "${DEFAULT_PORTS[@]}"; do
        if nc -z -v -w 1 "${DOMAIN}" "${port}" 2>/dev/null; then
            DETECTED_FTP_PORT="${port}"
            print_info "${FTP_PORT_OPEN} ${DOMAIN} ${FTP_ON_PORT} ${port}"
            break
        fi
    done

    # If no default ports are open, scan with nmap for custom ports
    if [ -z "${DETECTED_FTP_PORT}" ]; then
        print_info "${FTP_NO_PORT_FOUND}..."
        nmap -sS -Pn --scan-delay 200ms --max-retries 2 -p 1-1024 --open "${DOMAIN}" -oG "${FTP_GREP_FILE}" > /dev/null 2>&1
        DETECTED_FTP_PORT=$(grep -iE "ftp|sftp|ssh" "${FTP_GREP_FILE}" | grep -oE "[0-9]+/open" | cut -d'/' -f1 | head -n 1)

        if [ -z "${DETECTED_FTP_PORT}" ]; then
            {
                line
                echo "${FTP_RESULT} ${DOMAIN}"
                line
                echo "${FTP_PORT_CLOSED} ${FTP_SCAN_FINISHED}"
                separator
                echo "${DATE}"
                line
            } | tee "${FTP_STATUS_FILE}"

            separator
            print_bg "###### ${FINISHED}: ${FTP_TITLE}"
            separator

            createFile "ftp-status" "${FTP_TITLE} - ${DOMAIN}"
            return
        else
            print_info "${FTP_SERVICE_FOUND} ${DETECTED_FTP_PORT} ${ON} ${DOMAIN}"
        fi
    fi

    # If a port has been detected (21, 22, or customized), proceed with checks
    # Czech FTP/SFTP connection with nmap to grab banner
    nmap -sS -Pn --scan-delay 200ms --max-retries 2 -p "${DETECTED_FTP_PORT}" --script banner "${DOMAIN}" -oN "${FTP_CONNECTION_FILE}" > /dev/null 2>&1

    # Try a simple FTP connection with timeout (if FTP on the detected port)
    echo "exit" | timeout 5s ftp "${DOMAIN}" "${DETECTED_FTP_PORT}" >> "${FTP_CONNECTION_FILE}" 2>&1
    CHECK_FTP_CONNECTION=$(grep -i "220" "${FTP_CONNECTION_FILE}" | head -n 1 | grep -o "220")

    {
        line
        echo "${FTP_RESULT} ${DOMAIN} (porta ${DETECTED_FTP_PORT})"
        line

        if [ "${CHECK_FTP_CONNECTION}" == "220" ]; then
            echo "${FTP_CONNECTION_OK} ${DOMAIN} ${FTP_CONNECTION_SUCCESS} ${FTP_ON_PORT} ${DETECTED_FTP_PORT}."

            # Simulated brute-force test with hydra at the detected port
            echo "${FTP_BRUTE_FORCE_TEST} ${FTP_ON_PORT} ${DETECTED_FTP_PORT}"
            HYDRA_OUTPUT=$(timeout 30s /usr/bin/hydra -L /dev/null -P /dev/null -s "${DETECTED_FTP_PORT}" -t 1 -w 5 -f "${DOMAIN}" ftp 2>&1)

            CHECK_FTP_BRUTE=$(echo "${HYDRA_OUTPUT}" | grep -Ei "too many connection|connection errors|waiting" || echo "")

            if [[ -n "${CHECK_FTP_BRUTE}" ]]; then
                echo "${FTP_HARDENED} ${DOMAIN} ${FTP_HARDENED_STATUS}"
            else
                echo "${FTP_HARDENED} ${DOMAIN} ${FTP_VULNERABLE_STATUS}"
                echo "${FTP_BRUTE_STATUS}"
            fi
        else
            echo "${FTP_CONNECTION_FAIL} ${DOMAIN} ${FTP_ON_PORT} ${DETECTED_FTP_PORT}"
        fi

        separator
        echo "${DATE}"
        line
    } | tee "${FTP_BRUTE_FILE}"

    separator
    print_bg "###### ${FINISHED}: ${FTP_CONNECTION}"
    print_bg "###### ${FINISHED}: ${FTP_PROTECTION_STATUS}"
    separator

    print_success "${SAVED_RESULT} ${FTP_BRUTE_FILE}"
    createFile "ftp-brute" "${FTP_PROTECTION_STATUS} - ${DOMAIN}"

    # Clean
    [[ -f "${FTP_CONNECTION_FILE}" ]] && rm "${FTP_CONNECTION_FILE}"
    [[ -f "${FTP_GREP_FILE}" ]] && rm "${FTP_GREP_FILE}"
}