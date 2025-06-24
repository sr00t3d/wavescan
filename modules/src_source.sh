# ================================================
# __FUNC_CHECK_SOURCE - Analyze and gather source assets (JS, CSS, Images)
# ================================================
# - Fetches the HTML content from the target URL using `curl`
# - Extracts and lists all JavaScript (.js) files, CSS files (.css), and image files (e.g., .jpg, .png)
# - Collects the paths of the JS, CSS, and image files (relative paths without the domain)
# - Logs the results including any found JS, CSS, and image files or reports none found
# - Saves the results in a text file and prints the analysis summary
# ================================================

__FUNC_CHECK_SOURCE() {

    # Files
    SOURCE_RESULT_FILE="${TXT_DIR}/${DOMAIN}-src.txt"

    print_info "${SRC_ANALYSIS}"

    HTML=$(timeout 20s "${CURL}" \
    -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36" \
    -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
    -H "Accept-Language: en-US,en;q=0.5" -sLk "${TARGET_URL}")
    
    if [[ -z "${HTML}" ]]; then
        print_error "${SRC_FAIL}"
        return
    fi

    # Collect JS files
    JS_FILES=$(echo "${HTML}" | grep -oiE 'src=["'\''"][^"'\'' >]+\.js' | sed -E 's/src=["'\''"]//' | sort -u)
    JS_PATHS=$(echo "${JS_FILES}" | grep -Ev '^https?://' | sed -E 's|https?://[^/]+||' | grep -oE '^.*/|^[^/:]+/' | sort -u)

    # Collect CSS files
    CSS_FILES=$(echo "${HTML}" | grep -oiE 'href=["'\''"][^"'\'' >]+\.css' | sed -E 's/href=["'\''"]//' | sort -u)
    CSS_PATHS=$(echo "${CSS_FILES}" | grep -Ev '^https?://' | sed -E 's|https?://[^/]+||' | grep -oE '^.*/|^[^/:]+/' | sort -u)

    # Collect images
    IMG_FILES=$(echo "${HTML}" | grep -oiE 'src=["'\''"][^"'\'' >]+\.(jpg|jpeg|png|gif|svg|webp)' | sed -E 's/src=["'\''"]//' | sort -u)
    IMG_PATHS=$(echo "${IMG_FILES}" | grep -Ev '^https?://' | sed -E 's|https?://[^/]+||' | grep -oE '^.*/|^[^/:]+/' | sort -u)

    {
        line
        echo "${SRC_RESULT}: ${DOMAIN}"
        line

        echo "#### ${SRC_JS_FILES}:"
        if [[ -n "${JS_FILES}" ]]; then 
            echo "${JS_FILES}" | sed 's/^/  /'
        else 
            echo "${NONE_FOUND}"
        fi

        echo "#### ${SRC_JS_PATHS}:"
        if [[ -n "$JS_PATHS" ]]; then 
            echo "$JS_PATHS" | sed 's/^/  /'
        else 
            echo "${NONE_FOUND}"
        fi

        echo "#### ${SRC_CSS_FILES}:"
        if [[ -n "${CSS_FILES}" ]]; then 
            echo "${CSS_FILES}" | sed 's/^/  /'
        else 
            echo "${NONE_FOUND}"
        fi

        echo "#### ${SRC_CSS_PATHS}:"
        if [[ -n "${CSS_PATHS}" ]]; then 
            echo "${CSS_PATHS}" | sed 's/^/  /'
        else 
            echo "${NONE_FOUND}"
        fi

        echo "#### ${SRC_IMG_FILES}:"
        if [[ -n "${IMG_FILES}" ]]; then 
            echo "${IMG_FILES}" | sed 's/^/  /'
        else 
            echo "${NONE_FOUND}"
        fi

        echo "#### ${SRC_IMG_PATHS}:"
        if [[ -n "${IMG_PATHS}" ]]; then 
            echo "${IMG_PATHS}" | sed 's/^/  /'
        else 
            echo "${NONE_FOUND}"
        fi

        separator
        echo "${DATE}"
        line

    } | tee "${SOURCE_RESULT_FILE}"

    separator
    print_bg "###### ${FINISHED}: ${SRC_TITLE}"
    separator

    print_success "${SAVED_RESULT} ${SOURCE_RESULT_FILE}"
    createFile "src" "${SRC_TITLE} - ${DOMAIN}"
}