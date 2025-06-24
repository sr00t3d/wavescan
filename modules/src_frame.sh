# ================================================
# __FUNC_CHECK_FRAME - Check and Handle Iframes on a Webpage
# ================================================
# - Scans the target URL for embedded iframes
# - Extracts iframe `src` attributes and validates the URL structure
# - Handles cases of one or multiple iframe detections
# - Allows the user to choose an iframe if multiple are detected
# - Updates target URL based on iframe selection
# - Logs the iframe detection results and chosen URL
# ================================================

__FUNC_CHECK_FRAME() {

    # Files
    FRAME_RETURN_FILE="${TXT_DIR}/${DOMAIN}-frame.txt"

    print_info "${IFRAME_CHECKING} ${DOMAIN}"

    # The full URL using the defined protocol and domain
    HTML_RESPONSE=$(${CURL} -skL --compressed --max-time 10 \
        -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36" \
        -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" \
        -H "Accept-Encoding: gzip, deflate, br" \
        -H "Accept-Language: en-US,en;q=0.9" \
        -H "Connection: keep-alive" \
        -H "Cache-Control: no-cache" \
        -H "Upgrade-Insecure-Requests: 1" \
        -e "https://www.google.com" \
        "${TARGET_URL}")

    # Extract iframe src
    IFRAME_LIST=($(echo "${HTML_RESPONSE}" | grep -oiE '<iframe[^>]+src=.?["'\'']?([^"'\'' >]+)' | \
        sed -E 's/.*src=.?["'\'']?([^"'\'' >]+).*/\1/' | \
        grep -E "^/|^[^/]*\.php|^https?://${DOMAIN}/" | \
        sed -E "s|^https?://${DOMAIN}/||"))

    # Check how many iframes we detected
    IFRAME_COUNT=${#IFRAME_LIST[@]}

    {
        line
        echo "${IFRAME_RESULT} ${DOMAIN}"
        line

        if [[ ${IFRAME_COUNT} -eq 1 ]]; then
            # Only one iframe found, continue normally
            FRAME_NAME="${IFRAME_LIST[0]}"
            echo "${IFRAME_DETECTED}: ${FRAME_NAME}"

            # Build the new URL safely
            TARGET_FRAME_URL="${PROTOCOL}://${DOMAIN}/${FRAME_NAME}"

            echo "${IFRAME_APPEND} ${TARGET_FRAME_URL}"

            # Save new TARGET_URL only if you want to update flow
            TARGET_URL="${TARGET_FRAME_URL}"

        elif [[ ${IFRAME_COUNT} -gt 1 ]]; then
            # Multiple iframes detected, prompt the user for a choice
            echo "${IFRAME_MULTIPLE_FOUND}"
            echo "${IFRAME_CHOSE_IFRAME}"
            for i in "${!IFRAME_LIST[@]}"; do
                echo "$((i+1)) - ${IFRAME_LIST[$i]}"
            done

            # Get user input for iframe selection
            read -p "${IFRAME_CHOOSE_NUMBER}" FRAME_CHOICE


            if [[ ${FRAME_CHOICE} -ge 1 && ${FRAME_CHOICE} -le ${IFRAME_COUNT} ]]; then
                # Valid choice, continue with selected iframe
                FRAME_NAME="${IFRAME_LIST[$((FRAME_CHOICE-1))]}"
                TARGET_FRAME_URL="${PROTOCOL}://${DOMAIN}/${FRAME_NAME}"

                echo "${IFRAME_SELECTED} ${TARGET_FRAME_URL}"

                # Save new TARGET_URL
                TARGET_URL="${TARGET_FRAME_URL}"
                
            else
                echo "${IFRAME_INVALID_NUMBER}"
                exit 1
            fi
        else
            echo "${IFRAME_NOT_FOUND}"
        fi

        echo "${IFRAME_NEW_CHECK} ${TARGET_URL}"

        separator
        echo "${DATE}"
        line

    } | tee "${FRAME_RETURN_FILE}"

    separator
    print_bg "###### ${FINISHED}: ${IFRAME_TITLE}"
    separator

    createFile "iframe" "${IFRAME_TITLE} - ${DOMAIN}"
}