# ================================================
# __FUNC_CHECK_HTTP - Check HTTP methods allowed by the server
# ================================================
# - Sends an OPTIONS request to the target URL simulating Googlebot
# - Captures the "Allow" headers in the response to determine the allowed HTTP methods
# - Extracts and logs the HTTP status and allowed methods (e.g., GET, POST, PUT, DELETE)
# - Outputs the results to a text file for further analysis
# - Saves the findings in a report for the specified domain
# ================================================

__FUNC_CHECK_HTTP() {
    
    print_info "${HTTP_CHECK}"
    
    # Files
    HTTP_RESULT_FILE="${TXT_DIR}/${DOMAIN}-httpmethods.txt"

    # OPTIONS request simulating Googlebot
    RESPONSE=$(${CURL} -s -L -X OPTIONS "${TARGET_URL}" \
        -H "User-Agent: Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)" \
        -H "Origin: https://www.google.com" \
        -H "Access-Control-Request-Method: GET" \
        -H "Access-Control-Request-Headers: X-Requested-With" \
        -i --connect-timeout 5 --max-time 10)

    # Capture all Allow headers from the final HTTP response
    METHODS=$(echo "${RESPONSE}" | awk 'BEGIN{IGNORECASE=1}/^Allow:/{sub(/^Allow: */, ""); gsub(/, */, ","); print}' | paste -sd ',' -)
    
    {
        line
        echo "${HTTP_RESULT} ${DOMAIN}"
        line

        # Extract and format the HTTP response and Allow headers

        # Retrieve the last HTTP response only
        HTTP_STATUS=$(echo "${RESPONSE}" | grep -iE "^HTTP/" | tail -n1)
        ALLOW_HEADERS=$(echo "${RESPONSE}" | grep -i "^Allow:")
        
        if [[ -n "${HTTP_STATUS}" ]]; then
            echo "Status HTTP: ${HTTP_STATUS}"
        else
            echo "${HTTP_STATUS_FAIL}"
        fi
        
        if [[ -n "${ALLOW_HEADERS}" ]]; then
            echo "${HTTP_ALLOW_HEADER}: ${ALLOW_HEADERS}"
        fi
        
        if [[ -z "${METHODS}" ]]; then
            echo "${HTTP_NO_METHODS}"
        else
            echo "${HTTP_ALLOWED_METHODS}: ${METHODS}"
        fi

        separator
        echo "${DATE}"
        line

    } | tee "${HTTP_RESULT_FILE}"

    separator
    print_bg "###### ${FINISHED}: ${HTTP_METHODS}"
    separator

    print_success "${SAVED_RESULT} ${HTTP_RESULT_FILE}"
    createFile "httpmethods" "${HTTP_METHODS} - ${DOMAIN}"
}