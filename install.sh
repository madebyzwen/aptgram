#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
LOCALES_DIR="${SCRIPT_DIR}/locales"
LIB_DIR="${SCRIPT_DIR}/lib"
SYSTEMD_DIR="${SCRIPT_DIR}/systemd"

readonly APTGRAM_STATE_DIR="/var/lib/aptgram"
readonly INSTALL_BIN_DIR="/usr/bin"
readonly INSTALL_LIB_DIR="/usr/lib/aptgram"
readonly INSTALL_LOCALES_DIR="${INSTALL_LIB_DIR}/locales"
readonly SYSTEMD_UNIT_DIR="/etc/systemd/system"

show_banner() {
    local cyan=""
    local blue=""
    local dark_blue=""
    local bold=""
    local dim=""
    local reset=""

    if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
        cyan=$'\033[38;5;51m'
        blue=$'\033[38;5;39m'
        dark_blue=$'\033[38;5;27m'
        bold=$'\033[1m'
        dim=$'\033[2m'
        reset=$'\033[0m'
    fi

    printf '\n'
    printf '%s%s    █████╗ ██████╗ ████████╗ ██████╗ ██████╗  █████╗ ███╗   ███╗%s\n' "${bold}" "${cyan}" "${reset}"
    printf '%s%s   ██╔══██╗██╔══██╗╚══██╔══╝██╔════╝ ██╔══██╗██╔══██╗████╗ ████║%s\n' "${bold}" "${cyan}" "${reset}"
    printf '%s%s   ███████║██████╔╝   ██║   ██║  ███╗██████╔╝███████║██╔████╔██║%s\n' "${bold}" "${blue}" "${reset}"
    printf '%s%s   ██╔══██║██╔═══╝    ██║   ██║   ██║██╔══██╗██╔══██║██║╚██╔╝██║%s\n' "${bold}" "${blue}" "${reset}"
    printf '%s%s   ██║  ██║██║        ██║   ╚██████╔╝██║  ██║██║  ██║██║ ╚═╝ ██║%s\n' "${bold}" "${dark_blue}" "${reset}"
    printf '%s%s   ╚═╝  ╚═╝╚═╝        ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝%s\n' "${bold}" "${dark_blue}" "${reset}"
    printf '\n'
    printf '%s%s                         m a d e   b y   z w e n%s\n' "${dim}" "${dark_blue}" "${reset}"
    printf '\n'
}

ensure_curl() {
    local command_name

    if command -v curl >/dev/null 2>&1; then
        return 0
    fi

    for command_name in apt-get sudo; do
        if ! command -v "${command_name}" >/dev/null 2>&1; then
            printf '%s: %s\n' \
                "${TXT_MISSING_REQUIRED_COMMAND}" \
                "${command_name}" \
                >&2
            return 1
        fi
    done

    echo
    printf '%s\n' "${TXT_INSTALLING_CURL}"

    sudo apt-get update
    sudo apt-get install -y curl
}

check_requirements() {
    local command_name
    local -a required_commands=(
        apt
        apt-cache
        apt-get
        awk
        chmod
        chown
        curl
        cut
        date
        dpkg
        dpkg-query
        hostname
        install
        mktemp
        rm
        sed
        sudo
        systemctl
        tail
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

validate_source_tree() {
    local source_file
    local -a required_files=(
        "${SCRIPT_DIR}/aptgram"
        "${SCRIPT_DIR}/aptgram-config"
        "${SCRIPT_DIR}/uninstall.sh"
        "${SCRIPT_DIR}/VERSION"
        "${LIB_DIR}/config.sh"
        "${LIB_DIR}/config_command.sh"
        "${LIB_DIR}/configuration.sh"
        "${LIB_DIR}/heartbeat.sh"
        "${LIB_DIR}/report.sh"
        "${LIB_DIR}/repository.sh"
        "${LIB_DIR}/runtime.sh"
        "${LIB_DIR}/telegram.sh"
        "${LIB_DIR}/apt_updates.sh"
        "${LIB_DIR}/deployment.sh"
        "${LIB_DIR}/recovery.sh"
        "${LIB_DIR}/release.sh"
        "${LOCALES_DIR}/de.sh"
        "${LOCALES_DIR}/en.sh"
        "${LOCALES_DIR}/es.sh"
        "${LOCALES_DIR}/fr.sh"
        "${LOCALES_DIR}/it.sh"
        "${LOCALES_DIR}/pt_BR.sh"
        "${SYSTEMD_DIR}/aptgram.service.in"
        "${SYSTEMD_DIR}/aptgram.timer.in"
        "${SCRIPT_DIR}/update.sh"
    )

    for source_file in "${required_files[@]}"; do
        if [[ ! -f "${source_file}" ]]; then
            printf \
                '%s: %s\n' \
                "${TXT_REQUIRED_SOURCE_FILE_MISSING}" \
                "${source_file}" \
                >&2
            return 1
        fi
    done
}

load_installer_modules() {
    # shellcheck source=/dev/null
    source "${LIB_DIR}/deployment.sh"
    # shellcheck source=/dev/null
    source "${LIB_DIR}/telegram.sh"
    # shellcheck source=/dev/null
    source "${LIB_DIR}/configuration.sh"
}

detect_language() {
    local system_locale

    system_locale="${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}"

    case "${system_locale,,}" in
        de*) echo "de" ;;
        es*) echo "es" ;;
        fr*) echo "fr" ;;
        pt_br*) echo "pt_BR" ;;
        it*) echo "it" ;;
        en*) echo "en" ;;
        *) echo "en" ;;
    esac
}

load_language() {
    local language="$1"
    local locale_file="${LOCALES_DIR}/${language}.sh"

    if [[ ! -r "${locale_file}" ]]; then
        language="en"
        locale_file="${LOCALES_DIR}/en.sh"
    fi

    if [[ ! -r "${locale_file}" ]]; then
        printf 'APTGRAM locale files are unavailable.\n' >&2
        exit 1
    fi

    # shellcheck source=/dev/null
    source "${locale_file}"

    APTGRAM_LANGUAGE="${language}"
}

select_language() {
    echo
    echo "${TXT_LANGUAGE_SELECTION}"
    echo "=============================="
    echo
    echo "1) Deutsch"
    echo "2) English"
    echo "3) Español"
    echo "4) Français"
    echo "5) Português (Brasil)"
    echo "6) Italiano"
    echo

    while true; do
        read -r -p "${TXT_LANGUAGE_CHOICE}: " choice

        case "${choice}" in
            1) load_language "de"; break ;;
            2) load_language "en"; break ;;
            3) load_language "es"; break ;;
            4) load_language "fr"; break ;;
            5) load_language "pt_BR"; break ;;
            6) load_language "it"; break ;;
            *)
                echo "${TXT_INVALID_SELECTION}"
                ;;
        esac
    done
}

credential_encryption_available() {
    command -v systemd-creds >/dev/null 2>&1
}

store_bot_token() {
    local bot_token="$1"
    local credential_dir="/etc/aptgram/credentials"
    local encrypted_file="${credential_dir}/telegram-bot-token.cred"
    local plain_file="${credential_dir}/telegram-bot-token"

    sudo install -d \
        -o root \
        -g root \
        -m 0700 \
        "${credential_dir}"

    sudo rm -f "${encrypted_file}" "${plain_file}"

    if credential_encryption_available &&
        printf '%s' "${bot_token}" |
            sudo systemd-creds encrypt \
                --name=telegram-bot-token \
                - \
                "${encrypted_file}"
    then
        sudo chown root:root "${encrypted_file}"
        sudo chmod 0600 "${encrypted_file}"

        APTGRAM_CREDENTIAL_MODE="encrypted"
        return
    fi

    printf '%s' "${bot_token}" |
        sudo tee "${plain_file}" >/dev/null

    sudo chown root:root "${plain_file}"
    sudo chmod 0600 "${plain_file}"

    APTGRAM_CREDENTIAL_MODE="plain"
}

prompt_bot_token() {
    local bot_token

    while true; do
        echo
        read -r -p "${TXT_BOT_TOKEN}: " bot_token
        printf '\n\n'

        if [[ -z "${bot_token}" ]]; then
            echo "${TXT_VALUE_REQUIRED}"
            continue
        fi

        if ! is_valid_bot_token_format "${bot_token}"; then
            echo "${TXT_BOT_TOKEN_INVALID}"
            continue
        fi

        echo "${TXT_TESTING_BOT_TOKEN}"

        if verify_telegram_bot_token "${bot_token}"; then
            echo "${TXT_BOT_TOKEN_VALID}"
            BOT_TOKEN="${bot_token}"
            return
        fi

        echo "${TXT_BOT_TOKEN_INVALID}"
    done
}


prompt_chat_id() {
    local chat_id

    while true; do
        echo
        read -r -p "${TXT_CHAT_ID}: " chat_id

        if ! is_valid_telegram_chat_id "${chat_id}"; then
            echo "${TXT_CHAT_ID_INVALID}"
            continue
        fi

        echo "${TXT_TESTING_TELEGRAM}"

        if verify_telegram_chat_id \
            "${BOT_TOKEN}" \
            "${chat_id}" \
            "${TXT_TEST_MESSAGE}"
        then
            echo "${TXT_TELEGRAM_SUCCESS}"
            CHAT_ID="${chat_id}"
            return
        fi

        echo "${TXT_TELEGRAM_FAILED}"
    done
}


prompt_check_time() {
    local check_time

    while true; do
        echo
        read -r -p "${TXT_CHECK_TIME} [20:00]: " check_time

        check_time="${check_time:-20:00}"

        if is_valid_check_time "${check_time}"; then
            CHECK_TIME="${check_time}"
            return
        fi

        echo "${TXT_CHECK_TIME_INVALID}"
    done
}

enable_aptgram_timer() {
    sudo systemctl daemon-reload
    sudo systemctl enable --now aptgram.timer
}

run_initial_check() {
    sudo systemctl start aptgram.service
}

write_configuration() {
    local config_dir="/etc/aptgram"
    local config_file="${config_dir}/aptgram.conf"

    sudo install -d \
        -o root \
        -g root \
        -m 0755 \
        "${config_dir}"

    printf \
        'APTGRAM_LANGUAGE=%q\nTELEGRAM_CHAT_ID=%q\nCHECK_TIME=%q\n' \
        "${APTGRAM_LANGUAGE}" \
        "${CHAT_ID}" \
        "${CHECK_TIME}" |
        sudo tee "${config_file}" >/dev/null

    sudo chown root:root "${config_file}"
    sudo chmod 0644 "${config_file}"
}

main() {
    local detected_language

    show_banner

    detected_language="$(detect_language)"
    load_language "${detected_language}"

    ensure_curl
    check_requirements
    validate_source_tree
    load_installer_modules

    echo
    echo "${TXT_INSTALLATION_TITLE}"
    echo "=============================="
    echo
    printf "%s: %s\n" "${TXT_DETECTED_LANGUAGE}" "${LANGUAGE_NAME}"
    echo

    read -r -p "${TXT_CHANGE_LANGUAGE} " change_language

    if is_affirmative_answer "${change_language}"; then
        select_language
    fi

    echo
    printf "%s: %s\n" "${TXT_SELECTED_LANGUAGE}" "${LANGUAGE_NAME}"

    prompt_bot_token
    prompt_chat_id
    prompt_check_time

    echo
    echo "${TXT_CONFIGURATION_TITLE}"
    echo "=============================="
    echo
    printf "%s: %s\n" "${TXT_CONFIGURATION_LANGUAGE}" "${LANGUAGE_NAME}"
    printf "%s: %s\n" "${TXT_CONFIGURATION_CHAT_ID}" "${CHAT_ID}"
    printf "%s: %s\n" "${TXT_CONFIGURATION_CHECK_TIME}" "${CHECK_TIME}"
    printf "%s\n" "${TXT_CONFIGURATION_BOT_TOKEN}"

    store_bot_token "${BOT_TOKEN}"
    write_configuration

    echo
    printf "%s: %s\n" \
        "${TXT_CREDENTIAL_MODE}" \
        "${APTGRAM_CREDENTIAL_MODE}"
    printf "%s\n" "${TXT_CONFIGURATION_SAVED}"

    echo
    printf "%s\n" "${TXT_INSTALLING_FILES}"

    install_program_files \
    "${SCRIPT_DIR}" \
    "${INSTALL_BIN_DIR}" \
    "${INSTALL_LIB_DIR}" \
    "${INSTALL_LOCALES_DIR}" \
    "${APTGRAM_STATE_DIR}"

    install_version_file \
    "${SCRIPT_DIR}" \
    "${INSTALL_LIB_DIR}"

    echo
    printf "%s\n" "${TXT_INSTALLING_SYSTEMD}"
    install_systemd_units \
    "${SYSTEMD_DIR}" \
    "${SYSTEMD_UNIT_DIR}" \
    "${CHECK_TIME}" \
    "${APTGRAM_CREDENTIAL_MODE}"

    echo
    printf "%s\n" "${TXT_ENABLING_TIMER}"
    enable_aptgram_timer

    echo
    printf "%s\n" "${TXT_RUNNING_INITIAL_CHECK}"
    run_initial_check

    echo
    printf "%s\n" "${TXT_INSTALLATION_COMPLETE}"
}

main "$@"
