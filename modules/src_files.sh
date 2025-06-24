# ================================================
# __FUNC_CHECK_FILES - Scan for Files on a Web Server
# ================================================
# - Scans a target URL for accessible files with specific extensions
# - Uses `gobuster` to brute-force directories and find files
# - Excludes fake or error responses based on a random file path check
# - Logs the results and found files in a specific text file
# - Handles error situations, including connection failures and no files found
# ================================================

__FUNC_CHECK_FILES() {
    print_info "${FILES_START} ${DOMAIN}..."

    # Files
    FILES_RAW_FILE="${TXT_DIR}/${DOMAIN}-file-list-raw.txt"
    FILES_LIST_FILE="${TXT_DIR}/${DOMAIN}-file-list.txt"

    # File extensions
    EXTENSIONS="zip,rar,7z,tar,gz,bz2,txt,log,log.1,log.old,md,bkp,backup,old,new,1,xml,json,conf,yaml,ini,cfg,git,sql,database,db,cred,pass,key,secret,secrets,vault,settings,env,properties,connection,credentials,auth,account,token,bak,orig,sav,tmp,swp,~,pem,crt,cer,der,pfx,p12,csr,ssh,pub,private,lock,htpasswd,htaccess,inc,lib,phar,inc.php,xlsx,xls,csv,doc,docx,ppt,pptx,pdf,ps1,bat,cmd,vbs,sh,rc,pl,rb,npmrc,yarnrc,pip,pypirc,dockerfile,docker-compose.yml,docker-compose.override.yml,terraform,tfstate,tfvars,kubeconfig,kube.yml,kube.json"

    print_info "${FILES_USING_METHOD} ${TARGET_URL}..."

    # Detects the false size to check the error response
    RANDOM_PATH=$(date +%s%N)
    FAKE_LENGTH=$(curl -m 5 -sk "${TARGET_URL}/${RANDOM_PATH}" | wc -c 2>/dev/null | tr -d ' ')

    if [[ -z "${FAKE_LENGTH}" || "${FAKE_LENGTH}" -eq 0 ]]; then
        print_warning "${FILES_CONN_FAIL} ${TARGET_URL}. ${FILES_TRY_NEXT}."
        return 1
    fi

    print_info "${FILES_FAKE_SIZE}: ${FAKE_LENGTH} bytes"
    print_info "${FILES_LONG_PROCESS}"

    # Runs gobuster to find files
    if ! timeout 600s gobuster dir -k -u "${TARGET_URL}" \
            -w "${WORDLIST_WEBBIG}" \
            -t "${THREADS}" \
            -x "${EXTENSIONS}" \
            -s 200,204,302,307,403 \
            --exclude-length "${FAKE_LENGTH}" \
            --no-error \
            --status-codes-blacklist "" \
            -e | grep "Status: 200" | awk '{print $1}' > "${FILES_RAW_FILE}" 2>/dev/null; then
        print_warning "${FILES_GOBUSTER_ERROR} ${TARGET_URL}. ${FILES_TRYING_NEXT}..."
        return 1
    fi

    # Check if any files have been found
    FILE_COUNT=$(wc -l < "${FILES_RAW_FILE}" | tr -d ' ')
    FILES_NAMES=$(cat "${FILES_RAW_FILE}")

    {
        line
        echo "${FILES_RESULT} ${DOMAIN}"
        line

        if [[ "${FILE_COUNT}" -gt 0 ]]; then
            echo -e "${FILES_FOUND} ${FILE_COUNT} ${FILES_FOUND_NAMES}\n${FILES_NAMES}"
        else
            echo "${FILES_NOT_FOUND}"
            echo "${FILES_RESULT_EMPTY}"
        fi

        separator
        echo "${DATE}"
        line

    } | tee "${FILES_LIST_FILE}"

    separator
    print_bg "###### ${FINISHED}: ${FILES_TITLE}"
    separator

    createFile "file-list" "${FILES_TITLE} - ${DOMAIN}"

    # Clean
    [[ -f "${FILES_RAW_FILE}" ]] && rm "${FILES_RAW_FILE}"
}
