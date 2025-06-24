# ================================================
# __FUNC_CHECK_TECH - Technology Identification with WhatWeb
# ================================================
# - Scans the target URL for detected technologies using `whatweb`
# - Extracts and formats the output, removing unnecessary characters
# - Logs the detected technologies for further analysis
# - Saves the scan results to a text file
# ================================================

__FUNC_CHECK_TECH() {

    # Files
    TECH_RESULT_FILE="${TXT_DIR}/${DOMAIN}-tech.txt"

    print_info "${TECH_SCAN}"

    # Set User-Agent
    USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

    # Runs WhatWeb with timeout, removes ANSI codes and extracts only technologies
    TECH_OUTPUT=$(timeout 30s whatweb \
        -U "$USER_AGENT" \
        --no-errors \
        --open-timeout=10 \
        --read-timeout=20 \
        "${TARGET_URL}" 2>/dev/null | \
        sed -E 's/^https?:\/\/[^ ]+ \[[0-9]{3} [^]]+\] //' | \
        sed -r "s/\x1B\[[0-9;]*[mGKH]//g")

    {
        line
        echo "${TECH_RESULT_FOR}: ${DOMAIN}"
        line

        if [[ -z "${TECH_OUTPUT}" ]]; then
            echo "${TECH_CANNOT_IDENTIFY}"
            return
        fi

        # Transform into line
        echo "${TECH_DETECTED}:"
        echo "${TECH_OUTPUT}" | tr ',' '\n' | sed 's/^[[:space:]]*//' | sort | uniq | sed 's/^/  /'

        separator
        echo "${DATE}"
        line
        
    } | tee "${TECH_RESULT_FILE}"

    separator
    print_bg "###### ${FINISHED}: ${TECH_DETECTED}"
    separator

    print_success "${SAVED_RESULT} ${TECH_RESULT_FILE}"
    createFile "tech" "${TECH_DETECTED} - ${DOMAIN}"

}
