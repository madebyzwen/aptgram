#!/usr/bin/env bash

set -Eeuo pipefail

readonly DEFAULT_REPOSITORY_URL="https://github.com/madebyzwen/aptgram"
readonly INSTALL_BIN_DIR="/usr/bin"
readonly INSTALL_LIB_DIR="/usr/lib/aptgram"
readonly INSTALL_LOCALES_DIR="${INSTALL_LIB_DIR}/locales"
readonly VERSION_FILE="${INSTALL_LIB_DIR}/VERSION"
readonly CONFIG_FILE="/etc/aptgram/aptgram.conf"
readonly CREDENTIAL_DIR="/etc/aptgram/credentials"
readonly SYSTEMD_UNIT_DIR="/etc/systemd/system"
readonly APTGRAM_STATE_DIR="/var/lib/aptgram"

REPOSITORY_URL="${APTGRAM_UPDATE_REPOSITORY_URL:-${DEFAULT_REPOSITORY_URL}}"
WORK_DIR=""
EXTRACT_DIR=""
BACKUP_DIR=""
INSTALLED_VERSION=""
AVAILABLE_VERSION=""
VERSION_RELATION=""
APTGRAM_CREDENTIAL_MODE=""
TIMER_WAS_ENABLED=false
TIMER_WAS_ACTIVE=false
BACKUP_CREATED=false

prepare_update_runtime() {
    local self_dir
    local self_script

    if [[ "${APTGRAM_UPDATE_REEXECUTED:-}" == "1" ]]; then
        return 0
    fi

    self_dir="$(mktemp -d)"
    self_script="${self_dir}/aptgram-update"

    install \
        -m 0600 \
        "${BASH_SOURCE[0]}" \
        "${self_script}"

    APTGRAM_UPDATE_REEXECUTED=1 \
    APTGRAM_UPDATE_SELF_DIR="${self_dir}" \
        exec bash "${self_script}" "$@"
}

cleanup_update_runtime() {
    local exit_code="$?"

    trap - EXIT

    if [[ -n "${WORK_DIR}" && -d "${WORK_DIR}" ]]; then
        rm -rf "${WORK_DIR}" >/dev/null 2>&1 ||
            sudo rm -rf "${WORK_DIR}" >/dev/null 2>&1 ||
            true
    fi

    if [[ -n "${APTGRAM_UPDATE_SELF_DIR:-}" &&
        -d "${APTGRAM_UPDATE_SELF_DIR}" ]]
    then
        rm -rf "${APTGRAM_UPDATE_SELF_DIR}" >/dev/null 2>&1 ||
            true
    fi

    exit "${exit_code}"
}

load_update_modules() {
    local module_file
    local -a module_files=(
        "${INSTALL_LIB_DIR}/deployment.sh"
        "${INSTALL_LIB_DIR}/recovery.sh"
        "${INSTALL_LIB_DIR}/release.sh"
    )

    for module_file in "${module_files[@]}"; do
        if [[ ! -r "${module_file}" ]]; then
            printf 'APTGRAM update module is unavailable: %s\n' \
                "${module_file}" \
                >&2
            return 1
        fi
    done

    # shellcheck source=/dev/null
    source "${INSTALL_LIB_DIR}/deployment.sh"
    # shellcheck source=/dev/null
    source "${INSTALL_LIB_DIR}/recovery.sh"
    # shellcheck source=/dev/null
    source "${INSTALL_LIB_DIR}/release.sh"
}

load_update_language() {
    local language="en"
    local locale_file

    if [[ -r "${CONFIG_FILE}" ]]; then
        # shellcheck source=/dev/null
        source "${CONFIG_FILE}"
        language="${APTGRAM_LANGUAGE:-en}"
    fi

    locale_file="${INSTALL_LOCALES_DIR}/${language}.sh"

    if [[ ! -r "${locale_file}" ]]; then
        locale_file="${INSTALL_LOCALES_DIR}/en.sh"
    fi

    if [[ ! -r "${locale_file}" ]]; then
        printf 'APTGRAM locale files are unavailable.\n' >&2
        return 1
    fi

    # shellcheck source=/dev/null
    source "${locale_file}"
}

check_update_requirements() {
    local command_name
    local -a required_commands=(
        awk
        bash
        curl
        dpkg
        find
        install
        mktemp
        rm
        sed
        sha256sum
        sudo
        systemctl
        tar
        tee
    )

    for command_name in "${required_commands[@]}"; do
        if ! command -v "${command_name}" >/dev/null 2>&1; then
            printf '%s: %s\n' \
                "${TXT_MISSING_REQUIRED_COMMAND}" \
                "${command_name}" \
                >&2
            return 1
        fi
    done

    if [[ ! -d /run/systemd/system ]]; then
        printf '%s\n' "${TXT_SYSTEMD_REQUIRED}" >&2
        return 1
    fi
}

validate_installed_aptgram() {
    local installed_file
    local -a required_files=(
        "${INSTALL_BIN_DIR}/aptgram"
        "${INSTALL_BIN_DIR}/aptgram-uninstall"
        "${INSTALL_BIN_DIR}/aptgram-update"
        "${VERSION_FILE}"
        "${CONFIG_FILE}"
        "${INSTALL_LIB_DIR}/deployment.sh"
        "${INSTALL_LIB_DIR}/recovery.sh"
        "${INSTALL_LIB_DIR}/release.sh"
        "${SYSTEMD_UNIT_DIR}/aptgram.service"
        "${SYSTEMD_UNIT_DIR}/aptgram.timer"
    )

    for installed_file in "${required_files[@]}"; do
        if [[ ! -f "${installed_file}" ]]; then
            printf '%s: %s\n' \
                "${TXT_UPDATE_INCOMPLETE_INSTALLATION}" \
                "${installed_file}" \
                >&2
            return 1
        fi
    done

    if [[ ! "${CHECK_TIME:-}" =~ ^([01][0-9]|2[0-3]):[0-5][0-9]$ ]]; then
        printf '%s\n' "${TXT_UPDATE_INCOMPLETE_INSTALLATION}" >&2
        return 1
    fi

    APTGRAM_CREDENTIAL_MODE="$(
        detect_credential_mode "${CREDENTIAL_DIR}"
    )" || {
        printf '%s\n' "${TXT_UPDATE_INCOMPLETE_INSTALLATION}" >&2
        return 1
    }

    INSTALLED_VERSION="$(
        read_aptgram_version "${VERSION_FILE}"
    )" || {
        printf '%s\n' "${TXT_UPDATE_VERSION_INVALID}" >&2
        return 1
    }

    if systemctl is-enabled --quiet aptgram.timer; then
        TIMER_WAS_ENABLED=true
    fi

    if systemctl is-active --quiet aptgram.timer; then
        TIMER_WAS_ACTIVE=true
    fi
}

prepare_release() {
    WORK_DIR="$(mktemp -d)"
    EXTRACT_DIR="${WORK_DIR}/release"
    BACKUP_DIR="${WORK_DIR}/backup"

    echo
    printf '%s\n' "${TXT_UPDATE_CHECKING_RELEASE}"
    printf '%s\n' "${TXT_UPDATE_DOWNLOADING}"

    if ! download_latest_release_assets \
        "${REPOSITORY_URL}" \
        "${WORK_DIR}"
    then
        printf '%s\n' "${TXT_UPDATE_DOWNLOAD_FAILED}" >&2
        return 1
    fi

    printf '%s\n' "${TXT_UPDATE_VERIFYING_CHECKSUM}"

    if ! verify_release_checksum "${WORK_DIR}"; then
        printf '%s\n' "${TXT_UPDATE_CHECKSUM_FAILED}" >&2
        return 1
    fi

    if ! validate_release_archive "${WORK_DIR}"; then
        printf '%s\n' "${TXT_UPDATE_INVALID_RELEASE}" >&2
        return 1
    fi

    printf '%s\n' "${TXT_UPDATE_EXTRACTING}"

    if ! extract_release_archive \
        "${WORK_DIR}" \
        "${EXTRACT_DIR}"
    then
        printf '%s\n' "${TXT_UPDATE_INVALID_RELEASE}" >&2
        return 1
    fi

    if ! validate_release_tree "${EXTRACT_DIR}"; then
        printf '%s\n' "${TXT_UPDATE_INVALID_RELEASE}" >&2
        return 1
    fi

    if ! bash -n \
        "${EXTRACT_DIR}/aptgram" \
        "${EXTRACT_DIR}/install.sh" \
        "${EXTRACT_DIR}/uninstall.sh" \
        "${EXTRACT_DIR}/update.sh" \
        "${EXTRACT_DIR}/lib/"*.sh \
        "${EXTRACT_DIR}/locales/"*.sh
    then
        printf '%s\n' "${TXT_UPDATE_INVALID_RELEASE}" >&2
        return 1
    fi

    AVAILABLE_VERSION="$(
        read_aptgram_version "${EXTRACT_DIR}/VERSION"
    )" || {
        printf '%s\n' "${TXT_UPDATE_VERSION_INVALID}" >&2
        return 1
    }

    VERSION_RELATION="$(
        get_version_relation \
            "${INSTALLED_VERSION}" \
            "${AVAILABLE_VERSION}"
    )"
}

show_version_status() {
    echo
    printf '%s: %s\n' \
        "${TXT_UPDATE_INSTALLED_VERSION}" \
        "${INSTALLED_VERSION}"
    printf '%s: %s\n' \
        "${TXT_UPDATE_AVAILABLE_VERSION}" \
        "${AVAILABLE_VERSION}"

    case "${VERSION_RELATION}" in
        current)
            echo
            printf '%s\n' "${TXT_UPDATE_ALREADY_CURRENT}"
            return 1
            ;;
        downgrade)
            echo
            printf '%s\n' "${TXT_UPDATE_DOWNGRADE_REFUSED}" >&2
            return 2
            ;;
        update)
            echo
            printf '%s\n' "${TXT_UPDATE_NEW_VERSION_AVAILABLE}"
            return 0
            ;;
        *)
            printf '%s\n' "${TXT_UPDATE_VERSION_INVALID}" >&2
            return 2
            ;;
    esac
}

validate_installed_files() {
    sudo bash -n \
        "${INSTALL_BIN_DIR}/aptgram" \
        "${INSTALL_BIN_DIR}/aptgram-uninstall" \
        "${INSTALL_BIN_DIR}/aptgram-update" \
        "${INSTALL_LIB_DIR}/"*.sh \
        "${INSTALL_LOCALES_DIR}/"*.sh
}

rollback_update() {
    local exit_code="$1"

    trap - ERR INT TERM
    set +e

    echo
    printf '%s\n' "${TXT_UPDATE_FAILED}" >&2

    if [[ "${BACKUP_CREATED}" == true ]]; then
        printf '%s\n' "${TXT_UPDATE_ROLLBACK}" >&2

        if restore_update_backup \
            "${BACKUP_DIR}" \
            "${INSTALL_BIN_DIR}" \
            "${INSTALL_LIB_DIR}" \
            "${SYSTEMD_UNIT_DIR}" \
            "${TIMER_WAS_ENABLED}" \
            "${TIMER_WAS_ACTIVE}"
        then
            printf '%s\n' "${TXT_UPDATE_ROLLBACK_SUCCESS}" >&2
        else
            printf '%s\n' "${TXT_UPDATE_FAILED}" >&2
        fi
    fi

    exit "${exit_code}"
}

perform_update() {
    printf '%s\n' "${TXT_UPDATE_CREATING_BACKUP}"


    create_update_backup \
        "${BACKUP_DIR}" \
        "${INSTALL_BIN_DIR}" \
        "${INSTALL_LIB_DIR}" \
        "${SYSTEMD_UNIT_DIR}"

    BACKUP_CREATED=true

    trap 'rollback_update $?' ERR
    trap 'rollback_update 130' INT
    trap 'rollback_update 143' TERM

    printf '%s\n' "${TXT_UPDATE_STOPPING_SERVICE}"

    sudo systemctl stop \
        aptgram.timer \
        aptgram.service

    printf '%s\n' "${TXT_UPDATE_INSTALLING_FILES}"

    install_program_files \
        "${EXTRACT_DIR}" \
        "${INSTALL_BIN_DIR}" \
        "${INSTALL_LIB_DIR}" \
        "${INSTALL_LOCALES_DIR}" \
        "${APTGRAM_STATE_DIR}"

    printf '%s\n' "${TXT_UPDATE_INSTALLING_SYSTEMD}"

    install_systemd_units \
        "${EXTRACT_DIR}/systemd" \
        "${SYSTEMD_UNIT_DIR}" \
        "${CHECK_TIME}" \
        "${APTGRAM_CREDENTIAL_MODE}"

    validate_installed_files

    sudo systemctl daemon-reload

    printf '%s\n' "${TXT_UPDATE_RESTORING_TIMER}"

    restore_timer_state \
        "${TIMER_WAS_ENABLED}" \
        "${TIMER_WAS_ACTIVE}"

    install_version_file \
        "${EXTRACT_DIR}" \
        "${INSTALL_LIB_DIR}"

    trap - ERR INT TERM
    BACKUP_CREATED=false

    echo
    printf '%s\n' "${TXT_UPDATE_SUCCESS}"
    printf '%s: %s\n' \
        "${TXT_UPDATE_INSTALLED_VERSION}" \
        "${AVAILABLE_VERSION}"
}

main() {
    local version_status

    prepare_update_runtime "$@"
    trap cleanup_update_runtime EXIT

    load_update_modules
    load_update_language
    check_update_requirements

    sudo -v

    validate_installed_aptgram

    echo
    echo "${TXT_UPDATE_TITLE}"
    echo "=============================="

    prepare_release

    set +e
    show_version_status
    version_status="$?"
    set -e

    case "${version_status}" in
        0)
            perform_update
            ;;
        1)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

main "$@"