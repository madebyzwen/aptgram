refresh_package_lists() {
    apt-get update -qq
}

sanitize_single_line() {
    LC_ALL=C tr -d '\000-\010\013\014\016-\037\177' |
        tr '\t\r\n' '   ' |
        sed \
            -e 's/[[:space:]][[:space:]]*/ /g' \
            -e 's/^ //' \
            -e 's/ $//'
}

reset_update_collection() {
    UPDATE_TOTAL=0
    UPDATE_SECURITY=0
    UPDATE_REGULAR=0
    UPDATE_BACKPORTS=0
    UPDATE_EXTERNAL=0
    UPDATE_KERNEL=0

    : >"${UPDATE_DATA_FILE}"
}

list_upgradable_packages() {
    LC_ALL=C apt list --upgradable 2>/dev/null |
        tail -n +2 |
        cut -d/ -f1
}

get_installed_version() {
    local package="$1"

    dpkg-query \
        -W \
        -f='${Version}' \
        "${package}" \
        2>/dev/null ||
        true
}

get_candidate_version() {
    local package_policy="$1"

    awk '/Candidate:/ { print $2; exit }' <<<"${package_policy}"
}

get_package_summary() {
    local package="$1"
    local summary

    summary="$(
        dpkg-query \
            -W \
            -f='${binary:Summary}' \
            "${package}" \
            2>/dev/null ||
            true
    )"

    printf '%s' "${summary}" |
        sanitize_single_line
}

analyze_package_sources() {
    local package_policy="$1"
    local installed="$2"
    local candidate="$3"
    local version
    local repository
    local pocket
    local key
    local origin
    local archive

    is_security=false
    is_backports=false
    candidate_has_official=false
    candidate_has_external=false
    candidate_source=""

    while IFS='|' read -r version repository pocket; do
        [[ -z "${version}" || -z "${repository}" ]] && continue

        key="${repository}|${pocket}"
        origin="${REPOSITORY_ORIGIN[${key}]-}"
        archive="${REPOSITORY_ARCHIVE[${key}]-}"

        if is_official_origin "${origin}"; then
            if [[ "${archive}" == *-security ]] &&
                dpkg --compare-versions \
                    "${version}" \
                    gt \
                    "${installed}"
            then
                is_security=true
            fi

            if [[ "${version}" == "${candidate}" ]]; then
                candidate_has_official=true

                if [[ -z "${candidate_source}" ]]; then
                    candidate_source="${origin}/${archive}"
                fi

                if [[ "${archive}" == *-backports ]]; then
                    is_backports=true
                fi
            fi
        elif [[ "${version}" == "${candidate}" ]]; then
            candidate_has_external=true

            if [[ -z "${candidate_source}" ]]; then
                candidate_source="${origin:-${repository}}"
            fi
        fi
    done < <(
        list_package_sources "${package_policy}"
    )
}

determine_update_category() {
    local is_security="$1"
    local is_backports="$2"
    local candidate_has_external="$3"
    local candidate_has_official="$4"

    if "${is_security}"; then
        printf '%s' "security"
    elif "${is_backports}"; then
        printf '%s' "backports"
    elif "${candidate_has_external}" && ! "${candidate_has_official}"; then
        printf '%s' "external"
    else
        printf '%s' "regular"
    fi
}

increment_update_category_count() {
    local category="$1"

    case "${category}" in
        security)
            ((UPDATE_SECURITY += 1))
            ;;
        backports)
            ((UPDATE_BACKPORTS += 1))
            ;;
        external)
            ((UPDATE_EXTERNAL += 1))
            ;;
        regular)
            ((UPDATE_REGULAR += 1))
            ;;
    esac
}

is_kernel_package() {
    local package_name="$1"

    case "${package_name}" in
        linux-image-* | linux-headers-* | linux-modules-* | linux-modules-extra-* | linux-generic* | linux-virtual*)
            return 0
            ;;
    esac

    return 1
}

write_update_record() {
    local package="$1"
    local installed="$2"
    local candidate="$3"
    local summary="$4"
    local category="$5"
    local candidate_source="$6"
    local is_kernel="$7"

    candidate_source="$(
        printf '%s' "${candidate_source}" |
            sanitize_single_line
    )"

    if [[ -z "${summary}" ]]; then
        summary="-"
    fi

    if [[ -z "${candidate_source}" ]]; then
        candidate_source="-"
    fi

    printf \
        '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "${package}" \
        "${installed}" \
        "${candidate}" \
        "${summary}" \
        "${category}" \
        "${candidate_source}" \
        "${is_kernel}" \
        >>"${UPDATE_DATA_FILE}"
}

process_available_update() {
    local package="$1"
    local package_name
    local installed
    local candidate
    local summary
    local package_policy
    local category
    local candidate_source
    local is_security
    local is_backports
    local candidate_has_official
    local candidate_has_external
    local is_kernel

    installed="$(get_installed_version "${package}")"

    package_policy="$(LC_ALL=C apt-cache policy "${package}")"

    candidate="$(get_candidate_version "${package_policy}")"

    summary="$(get_package_summary "${package}")"

    analyze_package_sources \
        "${package_policy}" \
        "${installed}" \
        "${candidate}"

    category="$(
        determine_update_category \
            "${is_security}" \
            "${is_backports}" \
            "${candidate_has_external}" \
            "${candidate_has_official}"
    )"

    increment_update_category_count "${category}"

    package_name="${package%%:*}"
    is_kernel=false

    if is_kernel_package "${package_name}"; then
        is_kernel=true
        ((UPDATE_KERNEL += 1))
    fi

    write_update_record \
        "${package}" \
        "${installed}" \
        "${candidate}" \
        "${summary}" \
        "${category}" \
        "${candidate_source}" \
        "${is_kernel}"

    ((UPDATE_TOTAL += 1))
}

collect_available_updates() {
    local package

    reset_update_collection
    build_repository_index

    while read -r package; do
        [[ -z "${package}" ]] && continue

        process_available_update "${package}"
    done < <(
        list_upgradable_packages
    )
}

log_update_classification() {
    printf \
        'APTGRAM update classification: total=%s security=%s regular=%s backports=%s external=%s kernel=%s\n' \
        "${UPDATE_TOTAL}" \
        "${UPDATE_SECURITY}" \
        "${UPDATE_REGULAR}" \
        "${UPDATE_BACKPORTS}" \
        "${UPDATE_EXTERNAL}" \
        "${UPDATE_KERNEL}"
}
