# ================================================
# __FUNC_CHECK_WAF - Scan and detect Web Application Firewalls (WAF)
# ================================================
# - Uses `wafw00f` tool to scan the target URL for known WAFs
# - Sends a custom header with `User-Agent` and other HTTP headers for stealth detection
# - Checks the response for WAF signatures and attempts to identify the WAF type
# - If `wafw00f` fails, sends a `HEAD` request and manually inspects response headers for WAF signatures
# - Logs the detected WAF or indicates if no WAF was detected or if detection is undefined
# - Saves the results to a file and cleans up temporary files
# ================================================

__FUNC_CHECK_WAF() {

    # Files
    WAF_HEADER_FILE="${TXT_DIR}/${DOMAIN}-waf-header.txt"
    WAF_RESULT_FILE="${TXT_DIR}/${DOMAIN}-waf.txt"

    print_info "${WAF_SCAN}"

    # Create user-agent header for wafw00f and curl stealth
    printf "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36\nAccept-Language: en-US,en;q=0.9\nConnection: keep-alive\n" > "${WAF_HEADER_FILE}"

    # Try detecting WAF via wafw00f
    WAF_OUTPUT=$(timeout 30s wafw00f -H "${WAF_HEADER_FILE}" --timeout 10 "${TARGET_URL}" 2>/dev/null | grep -E 'is behind|appears to be|might be|No WAF detected')

    # Extract detected WAF
    CHECK_WAF=$(echo "${WAF_OUTPUT}" | grep -Eo '\(.*\)' | sed 's/[()]//g')

    if [[ -z "${CHECK_WAF}" ]]; then
        CHECK_WAF=$(echo "${WAF_OUTPUT}" | grep -o 'No WAF detected')
    fi

    # If wafw00f detection failed, try manual header inspection
    if [[ -z "${CHECK_WAF}" || "${CHECK_WAF}" == "Undefined" ]]; then

        print_warn "${WAF_CANT_CHECK}"

        # Send a HEAD request stealth with user-agent
        HEADERS=$(${CURL} -sI -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36" \
            -H "Accept-Language: en-US,en;q=0.9" \
            -H "Connection: keep-alive" \
            --connect-timeout 5 --max-time 10 "${TARGET_URL}")

        declare -A WAF_SIGNATURES=(
            ["cloudflare"]="Cloudflare"
            ["akamai"]="Akamai"
            ["sucuri"]="Sucuri"
            ["incapsula"]="Imperva Incapsula"
            ["f5"]="F5 BigIP"
            ["barracuda"]="Barracuda Networks"
            ["siteground"]="SiteGround"
            ["edgecast"]="EdgeCast"
            ["aws"]="AWS Shield"
            ["dome9"]="Dome9"
            ["yunjiasu"]="Yunjiasu (Baidu Cloud Firewall)"
            ["anquanbao"]="Anquanbao"
            ["wangsu"]="Wangsu Science and Technology"
            ["profense"]="Profense"
            ["denyall"]="DenyALL"
            ["radware"]="Radware AppWall"
            ["dts"]="Alibaba Cloud"
            ["safe3"]="Safe3 Web Firewall"
            ["sitelock"]="SiteLock"
            ["netscaler"]="Citrix NetScaler"
            ["ibm"]="IBM DataPower"
            ["fortiweb"]="Fortinet FortiWeb"
            ["securesphere"]="Imperva SecureSphere"
            ["trustwave"]="Trustwave"
            ["mod_security"]="ModSecurity"
            ["modsecurity"]="ModSecurity"
            ["wallarm"]="Wallarm"
            ["reblaze"]="Reblaze"
            ["bloxone"]="Infoblox BloxOne Threat Defense"
            ["sophos"]="Sophos"
            ["cloudfront"]="Amazon CloudFront"
            ["stackpath"]="StackPath"
            ["qualys"]="Qualys"
            ["fastly"]="Fastly"
            ["azion"]="Azion Edge Firewall"
            ["bunnycdn"]="Bunny CDN Shield"
        )

        CHECK_WAF="Undefined"
        for SIGNATURE in "${!WAF_SIGNATURES[@]}"; do
            if echo "${HEADERS}" | grep -iq "${SIGNATURE}"; then
                CHECK_WAF="${WAF_SIGNATURES[$SIGNATURE]}"
                break
            fi
        done

    fi

    # Final fallback if no detection
    if [[ -z "${CHECK_WAF}" ]]; then
        CHECK_WAF="Undefined"
    fi

    # Create output and write to file
    {
        line
        echo "${WAF_RESULT_FOR}: ${DOMAIN}"
        line

        if [[ "${CHECK_WAF}" == "No WAF detected" ]]; then
            echo "${WAF_NOT_DETECTED} ${DOMAIN}"
        elif [[ "${CHECK_WAF}" == "Undefined" ]]; then
            echo "${WAF_CANNOT_DETERMINE} ${DOMAIN}"
        else
            echo "${WAF_DETECTED} ${DOMAIN}: ${CHECK_WAF}"
        fi
    } | tee "${WAF_RESULT_FILE}"

    separator
    print_bg "###### ${FINISHED}: ${WAF_DETECTION}"
    separator

    print_success "${SAVED_RESULT} ${WAF_RESULT_FILE}"
    createFile "waf" "${WAF_DETECTION} - ${DOMAIN}"

    # Clean
    [[ -f "${WAF_HEADER_FILE}" ]] && rm "${WAF_HEADER_FILE}"
}