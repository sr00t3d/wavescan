# ================================================
# __FUNC_CHECK_INDEX - Scan for directory listings (index of) on the target website
# ================================================
# - Fetches the URL using `ffuf` to test potential directory listings
# - Checks for common extensions such as .zip, .rar, .txt, .log, .sql, etc.
# - Filters results to identify valid directory listings by searching for "Index of" in the response
# - Logs the found directory listings and outputs the results
# - Saves the results in a text file and prints the summary of findings
# ================================================

__FUNC_CHECK_INDEX() {

    print_info "${INDEX_START} ${DOMAIN}..."
    print_info "${INDEX_LONG_PROCESS}"

    # Files
    INDEX_VALUE_JSON="${TXT_DIR}/${DOMAIN}-indexof.json"
    INDEX_RETURN_FILE="${TXT_DIR}/${DOMAIN}-indexof.txt"

    # Uses more comprehensive list of extensions
    EXTENSIONS="zip,rar,7z,tar,gz,bz2,tar.gz,tar.bz2,tar.xz,bak,bkp,backup,old,new,orig,sav,tmp,swp,~,txt,log,log.1,log.old,md,csv,xlsx,xls,doc,docx,pdf,xml,json,yaml,yml,conf,ini,cfg,env,properties,pem,crt,cer,der,pfx,p12,csr,key,ssh,pub,sql,db,database,dmp,dmp1,dump,credentials,pass,passwd,password,secret,secrets,token,vault,htaccess,htpasswd,lock,git,svn,gitignore,dockerignore,npmrc,yarnrc,pypirc,dockerfile,docker-compose.yml,docker-compose.override.yml,terraform,tfstate,tfvars,kubeconfig,kube.yml,kube.json,inc,lib,phar,inc.php,ps1,bat,cmd,vbs,sh,rc,pl,rb,config,settings,connection,auth,account"

    print_info "${INDEX_USING_METHOD} ${TARGET_URL}..."

    # Detects false response size
    RANDOM_PATH=$(date +%s%N)
    FAKE_SIZE=$(${CURL} -m 5 -sk "${TARGET_URL}/${RANDOM_PATH}" | wc -c 2>/dev/null | tr -d ' ')
    if [[ -z "${FAKE_SIZE}" || "${FAKE_SIZE}" -eq 0 ]]; then
        print_warning "${INDEX_CONN_FAIL} ${TARGET_URL}. ${INDEX_TRY_NEXT}..."
        return
    fi

    print_info "${INDEX_FAKE_SIZE}: ${FAKE_SIZE} bytes"

    if stdbuf -oL ffuf -u "${TARGET_URL}/FUZZ" \
        -w "${WORDLIST_FUZZ}" \
        -t "${THREADS}" \
        -e "${EXTENSIONS}" \
        -mc 200,301 \
        -fc 302,403 \
        -recursion \
        -v \
        -o "${INDEX_VALUE_JSON}" \
        -of json \
        -ac; then

        if [[ -f "${INDEX_VALUE_JSON}" && -s "${INDEX_VALUE_JSON}" ]]; then
            INDEX_COUNT_EXTRACT=$(jq -r '.results[].input.FUZZ' "${INDEX_VALUE_JSON}" | grep -c '.')
            INDEX_DIR=$(jq -r '.results[].url' "${INDEX_VALUE_JSON}")

            {
                line
                echo "${INDEX_RESULT} ${DOMAIN}"
                line
                echo -e "${AMOUNT}: ${INDEX_COUNT_EXTRACT}\n${DIRECTORY}(s) ${INDEX_POSSIBLE_OPEN}:\n"

                FOUND_COUNT=0
                while IFS= read -r url; do
                    if ${CURL} -sk --max-time 5 "$url" | grep -qi "Index of"; then
                        echo "${INDEX_FOUND}: $url"
                        ((FOUND_COUNT++))
                    else
                        echo "${INDEX_DIRECTORY_NOT_INDEX}: $url"
                    fi
                done <<< "${INDEX_DIR}"

                separator
                echo "${INDEX_AMOUNT_DIRECTORY}: $FOUND_COUNT"
                echo "${DATE}"
                line
            } | tee "${INDEX_RETURN_FILE}"

        else
            echo "${INDEX_NONE_FOUND} ${PROTOCOL}."
        fi
    else
        echo "${INDEX_JSON_MISSING} ${PROTOCOL}: ${INDEX_VALUE_JSON}"
    fi

    separator
    print_bg "###### ${FINISHED}: ${INDEX_TITLE}"
    separator

    createFile "indexof" "${INDEX_TITLE} - ${DOMAIN}"

    [[ -f "${INDEX_VALUE_JSON}" ]] && rm "${INDEX_VALUE_JSON}"
}
