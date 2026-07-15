build_update_message() {
    local hostname

    hostname="$(hostname)"

    printf \
        '%s\n\n%s\n\n%s: %s\n%s: %s\n%s: %s\n%s: %s\n\n%s: %s\n\n%s: %s\n\n%s' \
        "${MSG_UPDATE_TITLE}" \
        "$(printf "${MSG_UPDATES_AVAILABLE}" "${UPDATE_TOTAL}")" \
        "${MSG_UPDATE_SECURITY}" \
        "${UPDATE_SECURITY}" \
        "${MSG_UPDATE_REGULAR}" \
        "${UPDATE_REGULAR}" \
        "${MSG_UPDATE_BACKPORTS}" \
        "${UPDATE_BACKPORTS}" \
        "${MSG_UPDATE_EXTERNAL}" \
        "${UPDATE_EXTERNAL}" \
        "${MSG_UPDATE_KERNEL}" \
        "${UPDATE_KERNEL}" \
        "${MSG_SERVER}" \
        "${hostname}" \
        "${MSG_UPDATE_REPORT_ATTACHED}"
}

append_report_section() {
    local wanted_category="$1"
    local section_title="$2"

    local package
    local installed
    local candidate
    local summary
    local category
    local source
    local is_kernel
    local display_summary
    local section_written=0

    while IFS=$'\t' read -r \
        package \
        installed \
        candidate \
        summary \
        category \
        source \
        is_kernel
    do
        if [[ "${category}" != "${wanted_category}" ]]; then
            continue
        fi

        if ((section_written == 0)); then
            {
                printf '\n%s\n' "${section_title}"
                printf '%s\n\n' "========================================"
            } >>"${REPORT_FILE}"

            section_written=1
        fi

        display_summary="${summary}"

        if [[ "${display_summary}" == "-" ]]; then
            display_summary="${REPORT_NO_DESCRIPTION}"
        fi

        {
            printf '%s\n' "${package}"
            printf '%s\n' "${display_summary}"
            printf '%s: %s\n' "${REPORT_INSTALLED}" "${installed}"
            printf '%s: %s\n' "${REPORT_AVAILABLE}" "${candidate}"

            if [[ "${source}" != "-" ]]; then
                printf '%s: %s\n' "${REPORT_SOURCE}" "${source}"
            fi

            if [[ "${is_kernel}" == "true" ]]; then
                printf '%s: %s\n' \
                    "${REPORT_KERNEL_PACKAGE}" \
                    "${REPORT_YES}"
            fi

            printf '\n'
        } >>"${REPORT_FILE}"
    done <"${UPDATE_DATA_FILE}"
}

build_update_report() {
    local hostname
    local created_at

    hostname="$(hostname)"
    created_at="$(date '+%Y-%m-%d %H:%M:%S %Z')"

    {
        printf '%s\n' "${REPORT_TITLE}"
        printf '%s\n\n' "========================================"

        printf '%s: %s\n' "${REPORT_SERVER}" "${hostname}"
        printf '%s: %s\n' "${REPORT_CREATED}" "${created_at}"
        printf '%s: %s\n' "${REPORT_TOTAL}" "${UPDATE_TOTAL}"

        printf '\n%s: %s\n' \
            "${REPORT_SECURITY}" \
            "${UPDATE_SECURITY}"

        printf '%s: %s\n' \
            "${REPORT_REGULAR}" \
            "${UPDATE_REGULAR}"

        printf '%s: %s\n' \
            "${REPORT_BACKPORTS}" \
            "${UPDATE_BACKPORTS}"

        printf '%s: %s\n' \
            "${REPORT_EXTERNAL}" \
            "${UPDATE_EXTERNAL}"

        printf '%s: %s\n' \
            "${REPORT_KERNEL}" \
            "${UPDATE_KERNEL}"

        printf '\n%s\n' \
            "${REPORT_CLASSIFICATION_NOTE}"
    } >"${REPORT_FILE}"

    append_report_section \
        "security" \
        "${REPORT_SECTION_SECURITY}"

    append_report_section \
        "regular" \
        "${REPORT_SECTION_REGULAR}"

    append_report_section \
        "backports" \
        "${REPORT_SECTION_BACKPORTS}"

    append_report_section \
        "external" \
        "${REPORT_SECTION_EXTERNAL}"
}
