# ================================================
# __FUNC_CHECK_DIR - Directory Enumeration Using Gobuster
# ================================================
# - Scans a target URL for directories using `gobuster`
# - Enumerates directories with specific status codes (200, 301, 302, 403)
# - Logs the results, including valid directories found
# - Provides detailed output of URLs checked and their status codes
# - Saves the enumeration results to a text file
# ================================================

__FUNC_CHECK_DIR() {

    ENUM_RESULT_FILE="${TXT_DIR}/${DOMAIN}-enumdir.txt"

    print_info "${ENUM_STARTING_DIRECTORY_ENUMERATION}"
    print_info "${ENUM_PROCESS_MAY_TAKE_TIME}"

    print_info "${ENUM_ATTEMPTING_ENUMERATION_VIA_PROTOCOL} ${TARGET_URL}..."

    # Direct result in ENUM_RESULT_FILE
    timeout 600s gobuster dir -u "${TARGET_URL}" \
        -w "${WORDLIST_WEBBIG}" \
        --insecure --no-color \
        -t "${THREADS}" --no-error -e -r \
        -o "${ENUM_RESULT_FILE}" 2>/dev/null

    if [[ ! -s "${ENUM_RESULT_FILE}" ]]; then
        print_warning "${ENUM_FAILED_OR_NO_RESULTS}"
        return 1
    fi

    print_success "${ENUM_COMPLETED_FILE_SAVED}: ${ENUM_RESULT_FILE}"

    # Variable with all valid
    local RETURN_VALID_URLS
    RETURN_VALID_URLS=$(grep -E "\(Status: (200|301|302|403)\)" "${ENUM_RESULT_FILE}" | awk '{print $1}')

    {
        line
        echo "${ENUM_RESULTS_DIRECTORY_ENUMERATION} ${DOMAIN}"
        line

        local TOTAL_COUNT
        TOTAL_COUNT=$(wc -l < "${ENUM_RESULT_FILE}" | tr -d ' ')
        local CODE_VALID_COUNT
        CODE_VALID_COUNT=$(echo "$RETURN_VALID_URLS" | wc -l | tr -d ' ')

        echo "${ENUM_TOTAL_URLS_CHECKED}: ${TOTAL_COUNT}"
        echo "${ENUM_URLS_WITH_STATUS_200}: ${CODE_VALID_COUNT}"

        if [[ -n "${RETURN_VALID_URLS}" ]]; then
            echo "${ENUM_DIRECTORIES_FILES_FOUND_STATUS_200}:"
            echo -e "${RETURN_VALID_URLS}" | head -n 20

            if (( CODE_VALID_COUNT > 20 )); then
                echo "${ENUM_DISPLAYING_FIRST_20_RESULTS} ${CODE_VALID_COUNT} ${ENUM_DISPLAYING_FIRST_20_MORE}"
            fi
        else
            echo "${ENUM_NO_DIRECTORIES_FOUND_STATUS_200}"
        fi

        separator
        echo "${DATE}"
        line
    } | tee "${ENUM_RESULT_FILE}"

    separator
    print_bg "###### ${FINISHED}: ${ENUM_DIRECTORIES_FOUND}"
    separator

    print_success "${SAVED_RESULT} ${ENUM_RESULT_FILE}"
    print_info "${ENUM_COMPLETE_DIRECTORY_LIST_AVAILABLE} ${ENUM_RESULT_FILE}"

    createFile "enumdir" "${ENUM_DIRECTORIES_FOUND} - ${DOMAIN}"
}