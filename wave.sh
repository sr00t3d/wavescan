#!/usr/bin/env bash
# ==============================================================
# WaveScan - Main Script for Web Scanning and Analysis
# ==============================================================
# - Loads global settings and modules automatically.
# - Calls all the other functions
# ==============================================================

# Load global settings
source ./config.sh

# Load all modules automatically
for MOD in ./modules/*.sh; do
    source "${MOD}"
done

# Runs the first detection to ensure script work properly
checkinput
checkversion
detect_os

# Calls the installation if requested
if [[ "$2" = "-i" || "$2" = "--install" ]]; then
    separator
    line
    print_warning "${WAVE_INSTALL_WARNING} ${DOMAIN}."
    line

    read -p "${WAVE_CONTINUE_PROMPT} " CONTINUE
    
    if [[ "$CONTINUE" =~ ^[yY]$ ]]; then
        installpkg
    fi
fi

# Core main function
main() {

    # File
    SUMARY_RESULT_FILE="${WAVE_FINAL_SUMMARY_AT}: ${TXT_DIR}/${DOMAIN}-summary.txt"
    
    # Display banner and configure directories
    banner
    setup_directories
    
    # Check dependencies and wordlists
    print_info "${WAVE_CHECKING_TOOLS}"
    curl_impersonate & spinner
    seclist & spinner
    
    # Run modules
    print_info "${WAVE_CHECK_FOR_DOMAIN} ${DOMAIN}"
    
    if [[ "${__FUNC_NORMAL_SCAN}" == true ]]; then
        print_info "${WAVE_PORT_SCAN}"
        __FUNC_NORMAL_SCAN & spinner
    fi
    
    if [[ "${__FUNC_ADVANCED_SCAN}" == true ]]; then
        print_info "${WAVE_ADVANCED_SCAN}"
        __FUNC_ADVANCED_SCAN & spinner
    fi

    if [[ "${__FUNC_UDP_SCAN}" == true ]]; then
        print_info "${WAVE_UDP_SCAN}"
        __FUNC_UDP_SCAN & spinner
    fi

    if [[ "${__FUNC_ALL_PORTS}" == true ]]; then
        print_info "${WAVE_PORT_GET}"
        __FUNC_ALL_PORTS & spinner
    fi
    
    if [[ "${__FUNC_PORT_VERSION}" == true ]]; then
        print_info "${WAVE_SERVICE_SCAN}"
        __FUNC_PORT_VERSION & spinner
    fi
    
    if [[ "${__FUNC_PORT_CONNECT}" == true ]]; then
        print_info "${WAVE_CONNECT_SCAN}"
        __FUNC_PORT_CONNECT & spinner
    fi
    
    if [[ "${__FUNC_PORT_HEADER}" == true ]]; then
        print_info "${WAVE_HEADERS_SCAN}"
        __FUNC_PORT_HEADER & spinner
    fi

    if [[ "${__FUNC_WEB_SCAN}" == true ]]; then
        print_info "${WAVE_WEB_SCAN}"
        __FUNC_WEB_SCAN & spinner
    fi

    if [[ "${__FUNC_VULN_SCAN}" == true ]]; then
        print_info "${WAVE_VUL_SCAN}"
        __FUNC_VULN_SCAN & spinner
    fi

    if [[ "${__FUNC_CHECK_FRAME}" == true ]]; then
        print_info "${WAVE_FRAME_SCAN}"

        # here we don't use '& spinner' function to avoid 'read' error on stdin if have multiples iframe to choice
        __FUNC_CHECK_FRAME
    fi
    
    if [[ "${__FUNC_CHECK_WAF}" == true ]]; then
        print_info "${WAVE_WAF_SCAN}"
        __FUNC_CHECK_WAF & spinner
    fi
    
    if [[ "${__FUNC_CHECK_TECH}" == true ]]; then
        print_info "${WAVE_TECH_SCAN}"
        __FUNC_CHECK_TECH & spinner
    fi
    
    if [[ "${__FUNC_CHECK_HTTP}" == true ]]; then
        print_info "${WAVE_HTTP_SCAN}"
        __FUNC_CHECK_HTTP & spinner
    fi
    
    if [[ "${__FUNC_CHECK_SOURCE}" == true ]]; then
        print_info "${WAVE_SOURCE_SCAN}"
        __FUNC_CHECK_SOURCE & spinner
    fi

    if [[ "${__FUNC_CHECK_CSS}" == true ]]; then
        print_info "${WAVE_CSS_SCAN}"
        __FUNC_CHECK_CSS & spinner
    fi

    if [[ "${__FUNC_CHECK_PATH}" == true ]]; then
        print_info "${WAVE_PATH_SCAN}"
        __FUNC_CHECK_PATH & spinner
    fi

    if [[ "${__FUNC_CHECK_DIR}" == true ]]; then
        print_info "${WAVE_DIRECTORY_SCAN}"
        __FUNC_CHECK_DIR & spinner
    fi

    if [[ "${__FUNC_CHECK_FILES}" == true ]]; then
        print_info "${WAVE_FILE_SCAN}"
        __FUNC_CHECK_FILES & spinner
    fi

    if [[ "${__FUNC_CHECK_INDEX}" == true ]]; then
        print_info "${WAVE_INDEXOF_SCAN}"
        __FUNC_CHECK_INDEX
    fi

    if [[ "${__FUNC_CHECK_FUZZ}" == true ]]; then
        print_info "${WAVE_LFD_SCAN}"
        __FUNC_CHECK_FUZZ
    fi
    
    if [[ "${__FUNC_CHECK_FTP}" == true ]]; then
        print_info "${WAVE_FTP_SCAN}"
        __FUNC_CHECK_FTP & spinner
    fi

    if [[ "${__FUNC_CHECK_SQL}" == true ]]; then
        print_info "${WAVE_SQL_SCAN}"
        __FUNC_CHECK_SQL & spinner
    fi

    # Generate summary report

    separator    
    line
    print_info "${WAVE_FINAL_SUMMARY_REPORT}"
    summary & spinner 

    print_success "${WAVE_SCAN_COMPLETED_SUCCESS} ${DOMAIN} ${WAVE_SCAN_COMPLETED_FINISH}"
    print_info "${WAVE_RESULTS_AVAILABLE_AT}:"
    print_info "${WAVE_TEXT_REPORTS_AT}: ${TXT_DIR}/"
    print_info "${WAVE_IMAGES_AT}: ${IMG_DIR}/"
    print_info "${SUMARY_RESULT_FILE}"
}

# Script execution
main