# ============================================
# WaveScan - Summary file
# ============================================

summary() {
    print_info "${SUM_GENERATING}..."
    
    {
        line
        echo -e "========== ${SUM_TITLE} ${DOMAIN} =========="
        print_info "${SUM_DATE}: $(date)"
        line

        separator
        
        # Results from __FUNC_NORMAL_SCAN
        if [[ "${__FUNC_NORMAL_SCAN}" == true ]]; then
            if [[ -f "${TXT_DIR}/${DOMAIN}-ports-normal.txt" ]]; then
                cat "${TXT_DIR}/${DOMAIN}-ports-normal.txt"
            fi
        fi

        separator

        # Results from __FUNC_ADVANCED_SCAN
        if [[ "${__FUNC_ADVANCED_SCAN}" == true ]]; then
            if [[ -f "${TXT_DIR}/${DOMAIN}-ports-advanced.txt" ]]; then
                cat "${TXT_DIR}/${DOMAIN}-ports-advanced.txt"
            fi
        fi

        # Results from __FUNC_UDP_SCAN
        if [[ "${__FUNC_UDP_SCAN}" == true ]]; then
            if [[ -f "${TXT_DIR}/${DOMAIN}-ports-udp.txt" ]]; then
                cat "${TXT_DIR}/${DOMAIN}-ports-udp.txt"
            fi
        fi

        separator

        # Results from __FUNC_ALL_PORTS
        if [[ "${__FUNC_ALL_PORTS}" == true ]]; then
            if [[ -f "${TXT_DIR}/${DOMAIN}-ports-list.txt" ]]; then
                cat "${TXT_DIR}/${DOMAIN}-ports-list.txt"
            fi
        fi

        separator

        # Results from __FUNC_PORT_VERSION
        if [[ "${__FUNC_PORT_VERSION}" == true ]]; then
            if [[ -f "${TXT_DIR}/${DOMAIN}-ports-version.txt" ]]; then
                cat "${TXT_DIR}/${DOMAIN}-ports-version.txt"
            fi
        fi

        separator

        # Results from __FUNC_PORT_CONNECT
        if [[ "${__FUNC_PORT_CONNECT}" == true ]]; then
            if [[ -f "${TXT_DIR}/${DOMAIN}-ports-connection.txt" ]]; then
                cat "${TXT_DIR}/${DOMAIN}-ports-connection.txt"
            fi
        fi

        separator

        # Results from __FUNC_PORT_HEADER
        if [[ "${__FUNC_PORT_HEADER}" == true ]]; then
            if [[ -f "${TXT_DIR}/${DOMAIN}-ports-header.txt" ]]; then
                cat "${TXT_DIR}/${DOMAIN}-ports-header.txt"
            fi
        fi

        # Results from __FUNC_WEB_SCAN
        if [[ "${__FUNC_WEB_SCAN}" == true ]]; then
            if [[ -f "${TXT_DIR}/${DOMAIN}-ports-web.txt" ]]; then
                cat "${TXT_DIR}/${DOMAIN}-ports-web.txt"
            fi
        fi

        # Results from __FUNC_CHECK_FRAME
        if [[ "${__FUNC_CHECK_FRAME}" == true ]]; then
            if [[ -f "${TXT_DIR}/${DOMAIN}-ports-frame.txt" ]]; then
                cat "${TXT_DIR}/${DOMAIN}-ports-frame.txt"
            fi
        fi

        # Results from __FUNC_VULN_SCAN
        if [[ "${__FUNC_VULN_SCAN}" == true ]]; then
            if [[ -f "${TXT_DIR}/${DOMAIN}-ports-vulnerabilities.txt" ]]; then
                cat "${TXT_DIR}/${DOMAIN}-ports-vulnerabilities.txt"
            fi
        fi

        separator

        # Results from __FUNC_CHECK_WAF
        if [[ "${__FUNC_CHECK_WAF}" == true ]]; then
            if [[ -f "${TXT_DIR}/${DOMAIN}-waf.txt" ]]; then
                cat "${TXT_DIR}/${DOMAIN}-waf.txt"
            fi
        fi

        separator

        # Results from __FUNC_CHECK_TECH
        if [[ "${__FUNC_CHECK_TECH}" == true ]]; then
            if [[ -f "${TXT_DIR}/${DOMAIN}-tech.txt" ]]; then
                cat "${TXT_DIR}/${DOMAIN}-tech.txt"
            fi
        fi

        separator

        # Results from __FUNC_CHECK_HTTP
        if [[ "${__FUNC_CHECK_HTTP}" == true ]]; then
            if [[ -f "${TXT_DIR}/${DOMAIN}-httpmethods.txt" ]]; then
                cat "${TXT_DIR}/${DOMAIN}-httpmethods.txt"
            fi
        fi

        separator

        # Results from __FUNC_CHECK_SOURCE
        if [[ "${__FUNC_CHECK_SOURCE}" == true ]]; then
            if [[ -f "${TXT_DIR}/${DOMAIN}-src.txt" ]]; then
                cat "${TXT_DIR}/${DOMAIN}-src.txt"
            fi
        fi

        separator

        # Results from __FUNC_CHECK_CSS
        if [[ "${__FUNC_CHECK_CSS}" == true ]]; then
            if [[ -f "${TXT_DIR}/${DOMAIN}-css.txt" ]]; then
                cat "${TXT_DIR}/${DOMAIN}-css.txt"
            fi
        fi

        # Results from __FUNC_CHECK_PATH
        if [[ "${__FUNC_CHECK_PATH}" == true ]]; then
            if [[ -f "${TXT_DIR}/${DOMAIN}-high-risk-endpoints.txt" ]]; then
                cat "${TXT_DIR}/${DOMAIN}-high-risk-endpoints.txt"
            fi

            if [[ -f "${TXT_DIR}/${DOMAIN}-attack-vectors.txt" ]]; then
                cat "${TXT_DIR}/${DOMAIN}-attack-vectors.txt"
            fi

        fi

        separator
        
        # Results from __FUNC_CHECK_DIR
        if [[ "${__FUNC_CHECK_DIR}" == true ]]; then
            if [[ -f "${TXT_DIR}/${DOMAIN}-enumdir.txt" ]]; then
                cat "${TXT_DIR}/${DOMAIN}-enumdir.txt"
            fi
        fi

        separator

        # Results from __FUNC_CHECK_FILES
        if [[ "${__FUNC_CHECK_FILES}" == true ]]; then
            if [[ -f "${TXT_DIR}/${DOMAIN}-file-list.txt" ]]; then
                cat "${TXT_DIR}/${DOMAIN}-file-list.txt"
            fi
        fi

        separator

        # Results from __FUNC_CHECK_INDEX
        if [[ "${__FUNC_CHECK_INDEX}" == true ]]; then
            if [[ -f "${TXT_DIR}/${DOMAIN}-indexof.txt" ]]; then
                cat "${TXT_DIR}/${DOMAIN}-indexof.txt"
            fi
        fi

        separator

        # Results from __FUNC_CHECK_FUZZ
        if [[ "${__FUNC_CHECK_FUZZ}" == true ]]; then
            if [[ -f "${TXT_DIR}/${DOMAIN}-lfd-hits.txt" ]]; then
                cat "${TXT_DIR}/${DOMAIN}-lfd-hits.txt"
            fi
        fi

        separator

        # Results from __FUNC_CHECK_FTP
        if [[ "${__FUNC_CHECK_FTP}" == true ]]; then
            if [[ -f "${TXT_DIR}/${DOMAIN}-ftp-brute.txt" ]]; then
                cat "${TXT_DIR}/${DOMAIN}-ftp-brute.txt"
            fi
        fi

        # Results from __FUNC_CHECK_SQL
        if [[ "${__FUNC_CHECK_SQL}" == true ]]; then
            if [[ -f "${TXT_DIR}/${DOMAIN}-sqlmap.txt" ]]; then
                cat "${TXT_DIR}/${DOMAIN}-sqlmap.txt"
            fi

            if [[ -f "${TXT_DIR}/${DOMAIN}-sqlmap-db.txt" ]]; then
                cat "${TXT_DIR}/${DOMAIN}-sqlmap-db.txt"
            fi

            if [[ -f "${TXT_DIR}/${DOMAIN}-sqlmap-dump.txt" ]]; then
                cat "${TXT_DIR}/${DOMAIN}-sqlmap-dump.txt"
            fi
        fi

        echo "=== ${SUM_END} ==="
        print_info "${SAVED_RESULT} ${TXT_DIR}/"
    } | cleancolor | tee "${TXT_DIR}/${DOMAIN}-summary.txt"
    
    print_success "${SUM_SAVED} ${TXT_DIR}/${DOMAIN}-summary.txt"
    createFile "summary" "${SUM_ANALYSIS_SUMMARY} - ${DOMAIN}"

    print_success "${SUM_REPORT_LOCATION} $DIR/${DOMAIN}/\n"
}