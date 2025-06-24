# ============================================
# __FUNC_CHECK_PATH - Check for directory indexing on the target domain
# ============================================
# - Sends requests to detect directory indexing by fuzzing common file extensions
# - Retrieves possible directories and checks if they contain "Index of" in the response
# - Outputs results, including the count of found directories, to a result file
# ============================================

__FUNC_CHECK_PATH() {
    
    # Files
    PATH_RAW_FILE="${TXT_DIR}/${DOMAIN}-html-raw.txt"
    PATH_VECTOR_RESULT_FILE="${TXT_DIR}/${DOMAIN}-attack-vectors.txt"
    PATH_ENDPOINTS_RESULT_FILE="${TXT_DIR}/${DOMAIN}-high-risk-endpoints.txt"

    print_info "${PATH_ANALYSIS}"

    # Download the HTML of the page with timeout
    HTML=$(timeout 20s "${CURL}" \
    -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36" \
    -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
    -H "Accept-Language: en-US,en;q=0.5" -sLk "${TARGET_URL}")

    [[ -n "${HTML}" ]] && print_warning "${FILES_NOT_FOUND}"
    [[ -z "${HTML}" ]] && { print_error "${PATH_FAIL}"; return; }
    
    # Saves HTML for analysis
    echo "${HTML}" > "${PATH_RAW_FILE}"
    
    # 1. Detect URLs with GET parameters (potential SQL injection)
    URL_PARAMS=$(echo "${HTML}" | grep -oiE 'href=["'\'' ]*[^"'\'']*\?[^"'\'']*["'\'']' | sed -E 's/href=["'\'' ]*//; s/["'\'']$//' | grep -vE '\.(css|js|jpe?g|png|gif|svg|pdf)' | sort -u)

    # 2. Detects forms (potential SQL injection via POST)
    FORMS=$(echo "${HTML}" | grep -oiE '<form[^>]*action=["'\'' ]*[^"'\'']*["'\'']' | grep -viE 'action=["'\'' ]*["'\'']' | sed -E 's/.*action=["'\'' ]*//; s/["'\'']$//' | sort -u)

    # 3. Detect PHP files and URLs with GET parameters
    PHP_FILES=$(echo "${HTML}" | grep -oiE 'href=["'\'' ]*[^"'\'']*\.php(\?[^"'\'']*)?["'\'']' | sed -E 's/href=["'\'' ]*//; s/["'\'']$//' | sort -u)

    # 4. Detect JS files that may contain endpoints or AJAX calls
    JS_FILES=$(echo "${HTML}" | grep -oiE 'src=["'\'' ]*[^"'\'']*\.js[^"'\'']*["'\'']' | sed -E 's/src=["'\'' ]*//; s/["'\'']$//' | sort -u)

    #5. Download and parse JS files to find endpoints
    mkdir -p "${TXT_DIR}/js_analysis"
    JS_ENDPOINTS=""

    for JS_FILE in ${JS_FILES}; do
        [[ ${JS_FILE} == /* ]] && JS_URL="${PROTOCOL}://${DOMAIN}${JS_FILE}" ||
        [[ ${JS_FILE} != http* ]] && JS_URL="${PROTOCOL}://${DOMAIN}/${JS_FILE}" ||
        JS_URL="${JS_FILE}"

        JS_CONTENT=$(timeout 10s "${CURL}" -A "Mozilla/5.0" -sL "${JS_URL}")
        [[ -z "${JS_CONTENT}" ]] && continue

        JS_NAME=$(basename "${JS_FILE}")
        echo "${JS_CONTENT}" > "${TXT_DIR}/js_analysis/${JS_NAME}"

        FILE_ENDPOINTS=$(
            {
                echo "${JS_CONTENT}" |
                    grep -oE '(["'\''](GET|POST|PUT|DELETE|PATCH)["'\''].*?["'\''][^"'\'']+["'\''])' |
                    grep -oE '["'\''][^"'\'']+/[^"'\'']+["'\'']'
                echo "${JS_CONTENT}" |
                    grep -oE '["'\''][^"'\'']*(/api/|/rest/|/ajax/|/json/|/xml/|/service/|/v[0-9]/)[^"'\'']*["'\'']'
                echo "${JS_CONTENT}" |
                    grep -oE '(ajax|fetch|axios)\s*\(\s*[\{]?\s*[\"'\'']*url[\"'\'']?\s*:\s*[\"'\''][^\"'\'']+[\"'\'']' |
                    grep -oE '[\"'\''][^\"'\'']+[\"'\'']'
                echo "${JS_CONTENT}" |
                    grep -oE '\.(get|post|put|delete|patch)\s*\(\s*[\"'\''][^\"'\'']+[\"'\'']' |
                    grep -oE '[\"'\''][^\"'\'']+[\"'\'']'
                echo "${JS_CONTENT}" |
                    grep -oE '["'\''][^"'\'']*\.(php|asp|aspx|jsp|json|xml)[^"'\'']*["'\'']'
                echo "${JS_CONTENT}" |
                    grep -oE 'new\s+WebSocket\s*\(\s*[\"'\''][^\"'\'']+[\"'\'']'
            } |
            sed -E 's/^["'\'']|["'\'']$//g' | grep -v '^{' | sort -u
        )

        [[ -n "${FILE_ENDPOINTS}" ]] && JS_ENDPOINTS+=$'\n'"# ${IN} ${JS_NAME}:"$'\n'"${FILE_ENDPOINTS}"$'\n'
    done

    # Remove duplicate blank lines
    JS_ENDPOINTS=$(echo "${JS_ENDPOINTS}" | sed '/^$/N;/^\n$/D')

    # 11. Potential APIs - Broader Search
    API_ENDPOINTS=$(echo "${HTML}" | grep -oE 'href=["'\''"][^"'\'']*(/api/|/rest/|/v[0-9]/|/service/|/ws/|/rpc/|/graphql|/query|/data)[^"'\'']*["'\'']|href=["'\''"][^"'\'']*\.(json|xml|jsonp|soap)[^"'\'']*["'\'']' | sed -E 's/href=["'\'' ]*//; s/["'\'' ]*$//' | sort -u)

    # 12. GraphQL Detection
    GRAPHQL_ENDPOINTS=$(echo "${HTML}" | grep -oE 'href=["'\''"][^"'\'']*graphql[^"'\'']*["'\'']' | sed -E 's/href=["'\'' ]*//; s/["'\'' ]*$//' | sort -u)

    # 13. File Upload Standards (potential for RCE)
    FILE_UPLOADS=$(echo "${HTML}" | grep -oEi '<form[^>]*enctype=["\047]multipart/form-data["\047][^>]*>|<input[^>]*type=["\047]file["\047][^>]*>' | sort -u)

    # 14. Websockets Standards
    WEBSOCKET_ENDPOINTS=$(echo "${HTML}" | grep -oE 'wss?://[^"'\'']+' | sort -u)

    # 15. Identifying JWT or other tokens
    TOKEN_PATTERNS=$(echo "${HTML}" | grep -oE 'token=|jwt=|authorization=|auth=|apikey=|api_key=|key=' | sort -u)

    # 16. Content Management Systems (CMS) Detection via meta name=
    CMS_PATTERNS=$(echo "${HTML}" | grep -iE '<meta[^>]+name=["'\''](generator|powered-by|application-name|framework)["'\''][^>]+>' | sed -n 's/.*content=["'\'']\([^"'\''>]*\)["'\''].*/\1/p' | grep -iE 'wordpress|joomla|drupal|magento|woocommerce|prestashop|shopify|typo3|contentful|strapi|laravel' | sort -u)

    # Fallback if it does not find any CMS in the specified pattern
    if [[ -z "$CMS_PATTERNS" ]]; then
        CMS_PATTERNS=$(echo "${HTML}" | grep -iE '<meta[^>]+name=["'\''](generator|powered-by|application-name|framework)["'\''][^>]+>' | sed -n 's/.*content=["'\'']\([^"\'']*\)["'\''].*/\1/p' | sort -u)
    fi

    # If it still doesn't find CMS, it returns a default message
    if [[ -z "$CMS_PATTERNS" ]]; then
        CMS_PATTERNS="${PATH_NO_CMS}"
    fi

    # 17. Detects URLs with sensitive extensions (asp, aspx, jsp, cgi)
    SENSITIVE_URLS=$(echo "${HTML}" | grep -oE 'href=["'\''"][^"'\'']*\.(asp|aspx|jsp|cgi|pl|do|action)[^"'\'']*["'\'']' | sed -E 's/href=["'\'']//' | sed -E 's/["'\'']$//' | sort -u)
    
    # 18. Extracts specific parameters from URLs for analysis of potential injection points
    URL_PARAMS_ANALYSIS=$(echo "${URL_PARAMS}" | grep -o '?[^"'\'']*' | sed 's/?//' | tr '&' '\n' | cut -d'=' -f1 | grep -vE '\.(css|js|jpg|jpeg|png|gif|svg|pdf)' | sort -u)
    
    # 19. Detects comments that may contain sensitive information
    COMMENTS=$(echo "${HTML}" | grep -oE '<!--.*?-->' | sort -u)
    
    # 20. Analyzes potentially vulnerable redirects
    REDIRECTS=$(echo "${HTML}" | grep -oE 'href=["'\''"][^"'\'']*redirect[^"'\'']*["'\'']|href=["'\''"][^"'\'']*goto[^"'\'']*["'\'']|href=["'\''"][^"'\'']*url[^"'\'']*["'\'']' | sed -E 's/href=["'\'']//' | sed -E 's/["'\'']$//' | sort -u)
    
    # 21. Analyzes file inclusions that may be vulnerable to LFI/RFI
    FILE_INCLUSIONS=$(echo "${HTML}" | grep -oE 'href=["'\''"][^"'\'']*file[^"'\'']*["'\'']|href=["'\''"][^"'\'']*include[^"'\'']*["'\'']|href=["'\''"][^"'\'']*path[^"'\'']*["'\'']|href=["'\''"][^"'\'']*require[^"'\'']*["'\'']' | sed -E 's/href=["'\'']//' | sed -E 's/["'\'']$//' | sort -u)

    # Consolidates and removes duplicates from all endpoints found
    ALL_ENDPOINTS=$(echo -e "${URL_PARAMS}\n${FORMS}\n${PHP_FILES}\n${JS_ENDPOINTS}\n${SENSITIVE_URLS}\n${REDIRECTS}\n${FILE_INCLUSIONS}\n${API_ENDPOINTS}" | grep -v '^$' | sort -u)
    
    # Risk analysis - identifies high-risk patterns
    HIGH_RISK_PATTERNS=$(echo "${ALL_ENDPOINTS}" | grep -iE '\?(id|user|pass|key|token|auth|admin|file|path|load|page|include|dir|search|query)=')
    
    {
        line
        echo "${PATH_RESULT} ${DOMAIN}"
        line

        line
        echo "${PATH_GET_URLS}:"
        line
        if [[ -n "${URL_PARAMS}" ]]; then
            echo "${URL_PARAMS}" | sed 's/^/  /'
        else
            echo "${NONE_FOUND}"
        fi

        line
        echo "${PATH_PHP_FORM}:"
        line
        if [[ -n "${FORMS}" ]]; then
            echo "${FORMS}" | sed 's/^/  /'
        else
            echo "${NONE_FOUND}"
        fi

        line
        echo "${PATH_PHP_FILES}:"
        line
        if [[ -n "${PHP_FILES}" ]]; then
            echo "${PHP_FILES}" | sed 's/^/  /'
        else
            echo "${NONE_FOUND}"
        fi

        line
        echo "${PATH_JS_ENDPOINTS}:"
        line
        if [[ -n "${JS_ENDPOINTS}" ]]; then
            echo "${JS_ENDPOINTS}" | grep -v '^$' | sed 's/^/  /'
        else
            echo "${NONE_FOUND}"
        fi
        
        line
        echo "${PATH_API_ENDPOINTS}:"
        line
        if [[ -n "${API_ENDPOINTS}" ]]; then
            echo "${API_ENDPOINTS}" | sed 's/^/  /'
        else
            echo "${NONE_FOUND}"
        fi

        line
        echo "${PATH_GRAPHQL}:"
        line
        if [[ -n "${GRAPHQL_ENDPOINTS}" ]]; then
            echo "${GRAPHQL_ENDPOINTS}" | sed 's/^/  /'
        else
            echo "${NONE_FOUND}"
        fi

        line
        echo "${PATH_FILE_UPLOADS}:"
        line
        if [[ -n "${FILE_UPLOADS}" ]]; then
            echo "${FILE_UPLOADS}" | sed 's/^/  /'
        else
            echo "${NONE_FOUND}"
        fi
        
        line
        echo "${PATH_WEBSOCKETS}:"
        line
        if [[ -n "${WEBSOCKET_ENDPOINTS}" ]]; then
            echo "${WEBSOCKET_ENDPOINTS}" | sed 's/^/  /'
        else
            echo "${NONE_FOUND}"
        fi
        
        line
        echo "${PATH_AUTH_TOKENS}:"
        line
        if [[ -n "${TOKEN_PATTERNS}" ]]; then
            echo "${TOKEN_PATTERNS}" | sed 's/^/  /'
        else
            echo "${NONE_FOUND}"
        fi
        
        line
        echo "${PATH_CMS_DETECTED}:"
        line
        if [[ -n "${CMS_PATTERNS}" ]]; then
            echo "${CMS_PATTERNS}" | sed 's/^/  /'
        else
            echo "${NONE_FOUND}"
        fi

        line
        echo "${PATH_SENSITIVE_EXT}:"
        line
        if [[ -n "${SENSITIVE_URLS}" ]]; then
            echo "${SENSITIVE_URLS}" | sed 's/^/  /'
        else
            echo "${NONE_FOUND}"
        fi

        line
        echo "${PATH_COMMON_PARAMS}:"
        line
        if [[ -n "${URL_PARAMS_ANALYSIS}" ]]; then
            echo "${URL_PARAMS_ANALYSIS}" | sed 's/^/  /'
        else
            echo "${NONE_FOUND}"
        fi

        line
        echo "${PATH_OPEN_REDIRECT}:"
        line
        if [[ -n "${REDIRECTS}" ]]; then
            echo "${REDIRECTS}" | sed 's/^/  /'
        else
            echo "${NONE_FOUND}"
        fi

        line
        echo "${PATH_FILE_INCLUSION}:"
        line
        if [[ -n "${FILE_INCLUSIONS}" ]]; then
            echo "${FILE_INCLUSIONS}" | sed 's/^/  /'
        else
            echo "${NONE_FOUND}"
        fi

        line
        echo "${PATH_API_REPEAT}:"
        line
        if [[ -n "${API_ENDPOINTS}" ]]; then
            echo "${API_ENDPOINTS}" | sed 's/^/  /'
        else
            echo "${NONE_FOUND}"
        fi

        line
        echo "${PATH_HIGH_RISK}:"
        line
        if [[ -n "${HIGH_RISK_PATTERNS}" ]]; then
            echo "${HIGH_RISK_PATTERNS}" | sed 's/^/  /'
        else
            echo "${PATH_NO_RISK_FOUND}"
        fi

        separator
        echo "${DATE}"
        line
        
    } | tee "${PATH_VECTOR_RESULT_FILE}"

    separator
    print_bg "###### ${FINISHED}: ${PATH_TITLE}"
    separator

    print_success "${SAVED_RESULT} ${PATH_VECTOR_RESULT_FILE}"
    createFile "attack-vectors" "${PATH_TITLE} - ${DOMAIN}"
    
    # Saves high-risk points separately for easier testing
    if [[ -n "${HIGH_RISK_PATTERNS}" ]]; then
        echo "${HIGH_RISK_PATTERNS}" > "${PATH_ENDPOINTS_RESULT_FILE}"
        print_success "${SAVED_RESULT} ${PATH_ENDPOINTS_RESULT_FILE}"
    fi

    # Clean
    [[ -f "${PATH_RAW_FILE}" ]] && rm "${PATH_RAW_FILE}"

}