# =======================================================
# __FUNC_CHECK_CSS - CSS Files and Directory Analysis
# =======================================================
# - Downloads the main page and searches for CSS files (both inline and external).
# - Analyzes the linked CSS files to find additional directories referenced within.
# - Downloads and inspects each CSS file to identify directory references.
# - Logs all CSS files and directories found.
# - Saves the results to a text file for further inspection.
# =======================================================

__FUNC_CHECK_CSS() {

    CSS_RESULT_FILE="${TXT_DIR}/${DOMAIN}-css.txt"
    print_info "${CSS_ANALYSIS}"

    declare -a CSS_FILE_NAMES=( 
        "style.css" "style.min.css" "styles.css" "styles.min.css"
        "main.css" "main.min.css" "base.css" "base.min.css"
        "login.css" "login.min.css" "app.css" "app.min.css"
        "global.css" "global.min.css" "theme.css" "theme.min.css"
        "common.css" "common.min.css" "index.css" "index.min.css"
        "layout.css" "layout.min.css" "site.css" "site.min.css"
        "reset.css" "reset.min.css" "normalize.css" "normalize.min.css"
        "bootstrap.css" "bootstrap.min.css" "foundation.css" "foundation.min.css"
        "tailwind.css" "tailwind.min.css" "bulma.css" "bulma.min.css"
        "material.css" "material.min.css" "skeleton.css" "skeleton.min.css"
        "custom.css" "custom.min.css" "application.css" "application.min.css"
        "default.css" "default.min.css" "core.css" "core.min.css"
        "vendor.css" "vendor.min.css" "utils.css" "utils.min.css"
        "components.css" "components.min.css" "responsive.css" "responsive.min.css"
        "print.css" "print.min.css" "dark.css" "dark.min.css"
        "lightbox.css" "lightbox.min.css" "animate.css" "animate.min.css"
        "/assets/css/layout.css" "/assets/css/styles.css"
    )

    try_download() {
        ${CURL} -skL --compressed --max-time 10 \
        -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36" \
        -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" \
        -H "Accept-Encoding: gzip, deflate, en" \
        -H "Accept-Language: en-US,en;q=0.9" \
        -H "Connection: keep-alive" \
        -H "Cache-Control: no-cache" \
        -H "Upgrade-Insecure-Requests: 1" \
        -e "https://www.google.com" "$1"
    }

    print_info "${CSS_DOWNLOADING_MAIN_PAGE} ${DOMAIN}..."
    HTML_CONTENT=$(try_download "${TARGET_URL}")

    if [[ -z "${HTML_CONTENT}" ]]; then
        print_error "${CSS_HTML_FAIL}"
        return 1
    fi

    CSS_FILES=""
    print_info "${CSS_SEARCHING_IN} ${DOMAIN}..."
    ALL_CSS=$(echo "${HTML_CONTENT}" | grep -oP '<link[^>]+rel=["'\''"]?(stylesheet|preload)["'\''"]?[^>]+>' | grep -oP 'href=["'\''"]?\K[^"'\'' >]+' | sort -u)

    if [[ -n "${ALL_CSS}" ]]; then
        echo "${CSS_FOUND} $(echo "${ALL_CSS}" | wc -l) ${CSS_STYLESHEET_LINKS}"
        CSS_FILES="${ALL_CSS}"$'\n'
    fi

    for CSS_NAME in "${CSS_FILE_NAMES[@]}"; do
        CSS_NAME_ESCAPED=$(echo "${CSS_NAME}" | sed 's/\./\\./g')
        FOUND_FILES=$(echo "${HTML_CONTENT}" | grep -oE "[^\"' ]*/${CSS_NAME_ESCAPED}(\?[^\"']*)?(\"|'|$)" | sed 's/\?.*$//' | sed 's/["'\'']$//' | sort -u)
        [[ -n "${FOUND_FILES}" ]] && CSS_FILES="${CSS_FILES}${FOUND_FILES}"$'\n'
    done

    CSS_FILES=$(echo "${CSS_FILES}" | sort -u | grep -v '^$')

    {
        line
        echo "${CSS_ANALIZY_RESULT} ${DOMAIN}"
        line

        echo "${CSS_PATH_RESULT}:"
        if [[ -z "${CSS_FILES}" ]]; then
            echo "${CSS_NOT_FOUND}"
            return 1
        else
            echo "${CSS_FILES}"
        fi

        CSS_DIRECTORIES=""
        CSS_PROCESSED_COUNT=0
        CSS_TOTAL_COUNT=$(echo "${CSS_FILES}" | wc -l)
        print_info "${CSS_WAIT_PROCESSING} ${CSS_TOTAL_COUNT} ${CSS_FILES_FOUND}..."

        line
        echo "${CSS_DIRECTORY_REFER}:"
        line

        while IFS= read -r CSS_FILE; do
            CSS_FILE=$(echo "${CSS_FILE}" | sed 's/"$//')
            ((CSS_PROCESSED_COUNT++))

            if [[ "${CSS_FILE}" =~ ^https?:// ]]; then
                FULL_CSS_URL="${CSS_FILE}"
            elif [[ "${CSS_FILE}" =~ ^// ]]; then
                FULL_CSS_URL="https:${CSS_FILE}"
            elif [[ "${CSS_FILE}" =~ ^/ ]]; then
                FULL_CSS_URL="${TARGET_URL}${CSS_FILE}"
            else
                FULL_CSS_URL="${TARGET_URL}/${CSS_FILE}"
            fi

            echo "[${CSS_PROCESSED_COUNT}/${CSS_TOTAL_COUNT}] ${DOWNLOADING_FILES}: ${FULL_CSS_URL}"
            CSS_FILE_CONTENT=$(try_download "${FULL_CSS_URL}")

            if [[ -n "${CSS_FILE_CONTENT}" ]]; then
                DIRECTORIES=$(echo "${CSS_FILE_CONTENT}" | grep -oP 'url\(\K[^)]+' | grep -v '^data:' | grep -v '^https\?://' | grep -E '^(\.\./|\./|/)' | sed 's!/[^/]*$!!' | sort -u)
                line
                echo "${CSS_DIRECTORIES_FOUND} ${CSS_FILE}:"
                line
                if [[ -n "${DIRECTORIES}" ]]; then
                    echo "${DIRECTORIES}"
                    for DIR in ${DIRECTORIES}; do
                        [[ -z "${DIR}" ]] && continue
                        if [[ "${DIR}" =~ ^\.\./(.*)$ ]]; then
                            BASE_DIR=$(dirname "$(dirname "${CSS_FILE}")")
                            NORM_DIR="${BASE_DIR}/${BASH_REMATCH[1]}"
                        elif [[ "${DIR}" =~ ^\./(.*) ]]; then
                            BASE_DIR=$(dirname "${CSS_FILE}")
                            NORM_DIR="${BASE_DIR}/${BASH_REMATCH[1]}"
                        elif [[ "${DIR}" =~ ^/ ]]; then
                            NORM_DIR="${DIR}"
                        else
                            NORM_DIR="/${DIR}"
                        fi
                        CSS_DIRECTORIES="${CSS_DIRECTORIES}${NORM_DIR}"$'\n'
                    done
                else
                    echo "${CSS_NO_DIRECTORY_FOUND} ${CSS_FILE}"
                fi
            fi
        done <<< "${CSS_FILES}"

        CSS_DIRECTORIES=$(echo "${CSS_DIRECTORIES}" | sort -u)

        if [[ -n "${CSS_DIRECTORIES}" ]]; then
            echo "${CSS_DIRECTORIES}"
        else
            echo "${CSS_NONE_DIRECTORY_FOUND}."
        fi

    } | tee "${CSS_RESULT_FILE}"

    separator
    print_success "${CSS_ANALYSIS_DONE}: ${CSS_RESULT_FILE}"
    separator

    createFile "css" "${CSS_TITLE} - ${DOMAIN}"
}
