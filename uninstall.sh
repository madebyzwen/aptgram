#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &&
        pwd
)"

readonly CONFIG_FILE="/etc/aptgram/aptgram.conf"

if [[ -d "${SCRIPT_DIR}/locales" ]]; then
    readonly LOCALES_DIR="${SCRIPT_DIR}/locales"
else
    readonly LOCALES_DIR="/usr/lib/aptgram/locales"
fi

readonly APTGRAM_BIN="/usr/bin/aptgram"
readonly CONFIG_BIN="/usr/bin/aptgram-config"
readonly UPDATE_BIN="/usr/bin/aptgram-update"
readonly UNINSTALL_BIN="/usr/bin/aptgram-uninstall"

readonly APTGRAM_STATE_DIR="/var/lib/aptgram"
readonly APTGRAM_LIB_DIR="/usr/lib/aptgram"
readonly APTGRAM_CONFIG_DIR="/etc/aptgram"
readonly SYSTEMD_UNIT_DIR="/etc/systemd/system"

load_language() {
    local locale_file

    APTGRAM_LANGUAGE="en"

    if [[ -r "${CONFIG_FILE}" ]]; then
        # shellcheck source=/dev/null
        source "${CONFIG_FILE}"
    fi

    locale_file="${LOCALES_DIR}/${APTGRAM_LANGUAGE}.sh"

    if [[ ! -r "${locale_file}" ]]; then
        locale_file="${LOCALES_DIR}/en.sh"
    fi

    if [[ ! -r "${locale_file}" ]]; then
        printf 'APTGRAM locale files are unavailable.\n' >&2
        exit 1
    fi

    # shellcheck source=/dev/null
    source "${locale_file}"
}

require_root() {
    if (( EUID != 0 )); then
        printf '%s\n' "${TXT_UNINSTALL_REQUIRES_ROOT}" >&2
        exit 1
    fi
}

confirm_uninstallation() {
    local answer

    read -r -p "${TXT_UNINSTALL_CONFIRM} " answer

    case "${answer,,}" in
        y|yes|j|ja|s|si|sí|sì|sim|o|oui)
            return
            ;;
    esac

    printf '%s\n' "${TXT_UNINSTALL_CANCELLED}"
    exit 0
}

stop_services() {
    systemctl disable --now aptgram.timer >/dev/null 2>&1 || true
    systemctl stop aptgram.service >/dev/null 2>&1 || true
}

remove_aptgram_files() {
    rm -f \
        "${SYSTEMD_UNIT_DIR}/aptgram.service" \
        "${SYSTEMD_UNIT_DIR}/aptgram.timer" \
        "${APTGRAM_BIN}" \
        "${CONFIG_BIN}" \
        "${UPDATE_BIN}"

    rm -rf \
        "${APTGRAM_LIB_DIR}" \
        "${APTGRAM_CONFIG_DIR}" \
        "${APTGRAM_STATE_DIR}"

    systemctl daemon-reload

    systemctl reset-failed aptgram.service >/dev/null 2>&1 || true
    systemctl reset-failed aptgram.timer >/dev/null 2>&1 || true
}

remove_uninstaller() {
    rm -f "${UNINSTALL_BIN}"
}

main() {
    load_language
    require_root

    echo
    echo "${TXT_UNINSTALL_TITLE}"
    echo "=============================="
    echo

    confirm_uninstallation

    echo
    printf '%s\n' "${TXT_UNINSTALL_STOPPING_SERVICES}"
    stop_services

    echo
    printf '%s\n' "${TXT_UNINSTALL_REMOVING_FILES}"
    remove_aptgram_files

    remove_uninstaller

    echo
    printf '%s\n' "${TXT_UNINSTALL_COMPLETE}"
}

main "$@"
