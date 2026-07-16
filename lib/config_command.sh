#!/usr/bin/env bash

set -Eeuo pipefail

umask 077

COMMAND_SOURCE_DIR="$(
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &&
        pwd
)"

if [[ -f "${COMMAND_SOURCE_DIR}/config.sh" ]]; then
    LIB_DIR="${COMMAND_SOURCE_DIR}"

    if [[ -d "${COMMAND_SOURCE_DIR}/locales" ]]; then
        DEFAULT_LOCALES_DIR="${COMMAND_SOURCE_DIR}/locales"
    else
        DEFAULT_LOCALES_DIR="${COMMAND_SOURCE_DIR}/../locales"
    fi
elif [[ -d "${COMMAND_SOURCE_DIR}/lib" ]]; then
    LIB_DIR="${COMMAND_SOURCE_DIR}/lib"
    DEFAULT_LOCALES_DIR="${COMMAND_SOURCE_DIR}/locales"
else
    LIB_DIR="/usr/lib/aptgram"
    DEFAULT_LOCALES_DIR="${LIB_DIR}/locales"
fi

CONFIG_FILE="${APTGRAM_CONFIG_FILE:-/etc/aptgram/aptgram.conf}"
APTGRAM_CREDENTIAL_DIR="${APTGRAM_CREDENTIAL_DIR:-/etc/aptgram/credentials}"
LOCALES_DIR="${APTGRAM_LOCALES_DIR:-${DEFAULT_LOCALES_DIR}}"
APTGRAM_BIN="${APTGRAM_BIN:-/usr/bin/aptgram}"
SYSTEMD_UNIT_DIR="${APTGRAM_SYSTEMD_UNIT_DIR:-/etc/systemd/system}"
SERVICE_FILE="${SYSTEMD_UNIT_DIR}/aptgram.service"
TIMER_FILE="${SYSTEMD_UNIT_DIR}/aptgram.timer"

# shellcheck source=/dev/null
source "${LIB_DIR}/config.sh"
# shellcheck source=/dev/null
source "${LIB_DIR}/telegram.sh"
# shellcheck source=/dev/null
source "${LIB_DIR}/configuration.sh"

TXT_CONFIG_INCOMPLETE_INSTALLATION="The APTGRAM installation or configuration is incomplete."

BOT_TOKEN=""
PENDING_BOT_TOKEN=""
PENDING_CHAT_ID=""
PENDING_CHECK_TIME=""
CREDENTIAL_MODE=""

TOKEN_CHANGED=false
CHAT_ID_CHANGED=false
CHECK_TIME_CHANGED=false
TRANSACTION_ACTIVE=false
CHANGES_SAVED=false
TIMER_WAS_ENABLED=false
TIMER_WAS_ACTIVE=false

WORK_DIR=""
CONFIG_CANDIDATE=""
CREDENTIAL_STAGING_DIR=""
CREDENTIAL_CANDIDATE=""
TIMER_CANDIDATE=""
ACTIVE_CREDENTIAL_FILE=""

set_root_ownership() {
    chown root:root "$@"
}

load_configured_language() {
    local locale_file

    APTGRAM_LANGUAGE=""
    TELEGRAM_CHAT_ID=""
    CHECK_TIME=""

    if [[ ! -r "${CONFIG_FILE}" ]]; then
        locale_file="${LOCALES_DIR}/en.sh"

        if [[ -r "${locale_file}" ]]; then
            # shellcheck source=/dev/null
            source "${locale_file}"
        fi

        printf '%s\n' "${TXT_CONFIG_INCOMPLETE_INSTALLATION}" >&2
        return 1
    fi

    # shellcheck source=/dev/null
    source "${CONFIG_FILE}"

    locale_file="${LOCALES_DIR}/${APTGRAM_LANGUAGE:-en}.sh"

    if [[ ! -r "${locale_file}" ]]; then
        locale_file="${LOCALES_DIR}/en.sh"
    fi

    if [[ ! -r "${locale_file}" ]]; then
        printf '%s\n' "${TXT_CONFIG_INCOMPLETE_INSTALLATION}" >&2
        return 1
    fi

    # shellcheck source=/dev/null
    source "${locale_file}"
}

require_root() {
    if ((EUID != 0)); then
        printf '%s\n' "${TXT_CONFIG_REQUIRES_ROOT}" >&2
        return 1
    fi
}

detect_existing_credential_mode() {
    local encrypted_file="${APTGRAM_CREDENTIAL_DIR}/telegram-bot-token.cred"
    local plain_file="${APTGRAM_CREDENTIAL_DIR}/telegram-bot-token"

    if [[ -f "${encrypted_file}" && ! -f "${plain_file}" ]]; then
        CREDENTIAL_MODE="encrypted"
        ACTIVE_CREDENTIAL_FILE="${encrypted_file}"
        return 0
    fi

    if [[ -f "${plain_file}" && ! -f "${encrypted_file}" ]]; then
        CREDENTIAL_MODE="plain"
        ACTIVE_CREDENTIAL_FILE="${plain_file}"
        return 0
    fi

    return 1
}

validate_existing_installation() {
    local command_name
    local required_file
    local -a required_commands=(
        awk
        basename
        chmod
        chown
        cp
        curl
        dirname
        install
        mktemp
        mv
        rm
        systemctl
    )
    local -a required_files=(
        "${APTGRAM_BIN}"
        "${CONFIG_FILE}"
        "${LIB_DIR}/config.sh"
        "${LIB_DIR}/configuration.sh"
        "${LIB_DIR}/telegram.sh"
        "${LOCALES_DIR}/${APTGRAM_LANGUAGE}.sh"
        "${SERVICE_FILE}"
        "${TIMER_FILE}"
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

    for required_file in "${required_files[@]}"; do
        if [[ ! -f "${required_file}" ]]; then
            printf '%s: %s\n' \
                "${TXT_CONFIG_INCOMPLETE_INSTALLATION}" \
                "${required_file}" \
                >&2
            return 1
        fi
    done

    if [[ ! -x "${APTGRAM_BIN}" ]] || \
        ! is_valid_telegram_chat_id "${TELEGRAM_CHAT_ID}" || \
        ! is_valid_check_time "${CHECK_TIME}" || \
        ! detect_existing_credential_mode
    then
        printf '%s\n' "${TXT_CONFIG_INCOMPLETE_INSTALLATION}" >&2
        return 1
    fi

    if [[ "${CREDENTIAL_MODE}" == "encrypted" ]] && \
        ! command -v systemd-creds >/dev/null 2>&1
    then
        printf '%s\n' "${TXT_CONFIG_INCOMPLETE_INSTALLATION}" >&2
        return 1
    fi

    if ! load_bot_token_for_manual_command; then
        return 1
    fi

    if [[ -z "${BOT_TOKEN}" ]]; then
        printf '%s\n' "${TXT_CONFIG_INCOMPLETE_INSTALLATION}" >&2
        return 1
    fi

    PENDING_BOT_TOKEN="${BOT_TOKEN}"
    PENDING_CHAT_ID="${TELEGRAM_CHAT_ID}"
    PENDING_CHECK_TIME="${CHECK_TIME}"
}

ask_to_change() {
    local prompt="$1"
    local answer

    read -r -p "${prompt} " answer || return 2
    is_affirmative_answer "${answer}"
}

prompt_bot_token_change() {
    local candidate
    local decision

    printf '%s: %s\n' \
        "${TXT_CONFIG_CURRENT_BOT_TOKEN}" \
        "${TXT_CONFIG_VALUE_PRESENT}"

    if ask_to_change "${TXT_CONFIG_CHANGE_BOT_TOKEN}"; then
        :
    else
        decision="$?"

        if ((decision == 2)); then
            return 1
        fi

        return 0
    fi

    printf '%s\n' "${TXT_CONFIG_EMPTY_KEEPS_VALUE}"

    while true; do
        candidate=""
        read -r -p "${TXT_CONFIG_NEW_BOT_TOKEN}: " candidate || return 1
        printf '\n'

        if [[ -z "${candidate}" ]]; then
            printf '%s\n' "${TXT_CONFIG_CHANGE_ABORTED}"
            return 0
        fi

        if ! is_valid_bot_token_format "${candidate}"; then
            printf '%s\n' "${TXT_BOT_TOKEN_INVALID}"
            continue
        fi

        printf '%s\n' "${TXT_TESTING_BOT_TOKEN}"

        if verify_telegram_bot_token "${candidate}"; then
            PENDING_BOT_TOKEN="${candidate}"
            TOKEN_CHANGED=true
            printf '%s\n' "${TXT_BOT_TOKEN_VALID}"
            return 0
        fi

        printf '%s\n' "${TXT_BOT_TOKEN_INVALID}"
    done
}

prompt_chat_id_change() {
    local candidate
    local decision

    printf '%s: %s\n' \
        "${TXT_CONFIG_CURRENT_CHAT_ID}" \
        "${TELEGRAM_CHAT_ID}"

    if ask_to_change "${TXT_CONFIG_CHANGE_CHAT_ID}"; then
        :
    else
        decision="$?"

        if ((decision == 2)); then
            return 1
        fi

        return 0
    fi

    printf '%s\n' "${TXT_CONFIG_EMPTY_KEEPS_VALUE}"

    while true; do
        candidate=""
        read -r -p "${TXT_CONFIG_NEW_CHAT_ID}: " candidate || return 1

        if [[ -z "${candidate}" ]]; then
            printf '%s\n' "${TXT_CONFIG_CHANGE_ABORTED}"
            return 0
        fi

        if ! is_valid_telegram_chat_id "${candidate}"; then
            printf '%s\n' "${TXT_CHAT_ID_INVALID}"
            continue
        fi

        printf '%s\n' "${TXT_TESTING_TELEGRAM}"

        if verify_telegram_chat_id \
            "${PENDING_BOT_TOKEN}" \
            "${candidate}" \
            "${TXT_CONFIG_CHAT_TEST_MESSAGE}"
        then
            PENDING_CHAT_ID="${candidate}"
            CHAT_ID_CHANGED=true
            printf '%s\n' "${TXT_TELEGRAM_SUCCESS}"
            return 0
        fi

        printf '%s\n' "${TXT_CONFIG_CHAT_ID_TEST_FAILED}"
    done
}

prompt_check_time_change() {
    local candidate
    local decision

    printf '%s: %s\n' \
        "${TXT_CONFIG_CURRENT_CHECK_TIME}" \
        "${CHECK_TIME}"

    if ask_to_change "${TXT_CONFIG_CHANGE_CHECK_TIME}"; then
        :
    else
        decision="$?"

        if ((decision == 2)); then
            return 1
        fi

        return 0
    fi

    printf '%s\n' "${TXT_CONFIG_EMPTY_KEEPS_VALUE}"

    while true; do
        candidate=""
        read -r -p "${TXT_CONFIG_NEW_CHECK_TIME}: " candidate || return 1

        if [[ -z "${candidate}" ]]; then
            printf '%s\n' "${TXT_CONFIG_CHANGE_ABORTED}"
            return 0
        fi

        if is_valid_check_time "${candidate}"; then
            PENDING_CHECK_TIME="${candidate}"
            CHECK_TIME_CHANGED=true
            return 0
        fi

        printf '%s\n' "${TXT_CHECK_TIME_INVALID}"
    done
}

prepare_runtime() {
    WORK_DIR="$(mktemp -d /tmp/aptgram-config.XXXXXX)" || return 1
    chmod 0700 "${WORK_DIR}" || return 1
}

prepare_configuration_candidate() {
    local chat_assignment
    local time_assignment
    local config_dir

    if [[ "${CHAT_ID_CHANGED}" != true && \
        "${CHECK_TIME_CHANGED}" != true ]]
    then
        return 0
    fi

    config_dir="$(dirname -- "${CONFIG_FILE}")"
    CONFIG_CANDIDATE="$(
        mktemp "${config_dir}/.aptgram.conf.XXXXXX"
    )" || return 1

    printf -v chat_assignment \
        'TELEGRAM_CHAT_ID=%q' \
        "${PENDING_CHAT_ID}"
    printf -v time_assignment \
        'CHECK_TIME=%q' \
        "${PENDING_CHECK_TIME}"

    if ! awk \
        -v chat_assignment="${chat_assignment}" \
        -v change_chat="${CHAT_ID_CHANGED}" \
        -v change_time="${CHECK_TIME_CHANGED}" \
        -v time_assignment="${time_assignment}" \
        '
            BEGIN { chat_count = 0; time_count = 0 }
            /^TELEGRAM_CHAT_ID=/ {
                chat_count++

                if (change_chat == "true") {
                    print chat_assignment
                } else {
                    print
                }

                next
            }
            /^CHECK_TIME=/ {
                time_count++

                if (change_time == "true") {
                    print time_assignment
                } else {
                    print
                }

                next
            }
            { print }
            END {
                if (chat_count != 1 || time_count != 1) {
                    exit 1
                }
            }
        ' \
        "${CONFIG_FILE}" \
        >"${CONFIG_CANDIDATE}"
    then
        return 1
    fi

    chmod 0644 "${CONFIG_CANDIDATE}" || return 1
    set_root_ownership "${CONFIG_CANDIDATE}" || return 1
}

prepare_credential_candidate() {
    if [[ "${TOKEN_CHANGED}" != true ]]; then
        return 0
    fi

    CREDENTIAL_STAGING_DIR="$(
        mktemp -d \
            "${APTGRAM_CREDENTIAL_DIR}/.aptgram-config.XXXXXX"
    )" || return 1
    chmod 0700 "${CREDENTIAL_STAGING_DIR}" || return 1
    set_root_ownership "${CREDENTIAL_STAGING_DIR}" || return 1

    case "${CREDENTIAL_MODE}" in
        encrypted)
            CREDENTIAL_CANDIDATE="${CREDENTIAL_STAGING_DIR}/telegram-bot-token.cred"

            if ! printf '%s' "${PENDING_BOT_TOKEN}" |
                systemd-creds encrypt \
                    --name=telegram-bot-token \
                    - \
                    "${CREDENTIAL_CANDIDATE}" \
                    >/dev/null 2>&1
            then
                return 1
            fi
            ;;
        plain)
            CREDENTIAL_CANDIDATE="${CREDENTIAL_STAGING_DIR}/telegram-bot-token"
            printf '%s' "${PENDING_BOT_TOKEN}" \
                >"${CREDENTIAL_CANDIDATE}" || return 1
            ;;
        *)
            return 1
            ;;
    esac

    chmod 0600 "${CREDENTIAL_CANDIDATE}" || return 1
    set_root_ownership "${CREDENTIAL_CANDIDATE}" || return 1
}

prepare_timer_candidate() {
    local schedule

    if [[ "${CHECK_TIME_CHANGED}" != true ]]; then
        return 0
    fi

    TIMER_CANDIDATE="$(
        mktemp \
            "${SYSTEMD_UNIT_DIR}/.aptgram.timer.XXXXXX"
    )" || return 1
    schedule="OnCalendar=*-*-* ${PENDING_CHECK_TIME}:00"

    if ! awk \
        -v schedule="${schedule}" \
        '
            BEGIN { schedule_count = 0 }
            /^OnCalendar=/ {
                schedule_count++
                print schedule
                next
            }
            { print }
            END {
                if (schedule_count != 1) {
                    exit 1
                }
            }
        ' \
        "${TIMER_FILE}" \
        >"${TIMER_CANDIDATE}"
    then
        return 1
    fi

    chmod 0644 "${TIMER_CANDIDATE}" || return 1
    set_root_ownership "${TIMER_CANDIDATE}" || return 1
}

prepare_transaction() {
    prepare_runtime || return 1
    prepare_configuration_candidate || return 1
    prepare_credential_candidate || return 1
    prepare_timer_candidate || return 1

    if [[ -n "${CONFIG_CANDIDATE}" ]]; then
        cp -p \
            "${CONFIG_FILE}" \
            "${WORK_DIR}/aptgram.conf" || return 1
    fi

    if [[ -n "${CREDENTIAL_CANDIDATE}" ]]; then
        cp -p "${ACTIVE_CREDENTIAL_FILE}" \
            "${WORK_DIR}/$(basename -- "${ACTIVE_CREDENTIAL_FILE}")" ||
            return 1
    fi

    if [[ -n "${TIMER_CANDIDATE}" ]]; then
        cp -p \
            "${TIMER_FILE}" \
            "${WORK_DIR}/aptgram.timer" || return 1

        if systemctl is-enabled --quiet aptgram.timer; then
            TIMER_WAS_ENABLED=true
        fi

        if systemctl is-active --quiet aptgram.timer; then
            TIMER_WAS_ACTIVE=true
        fi
    fi
}

restore_timer_state() {
    systemctl daemon-reload >/dev/null 2>&1 || true

    if [[ "${TIMER_WAS_ENABLED}" == true ]]; then
        systemctl enable aptgram.timer >/dev/null 2>&1 || true
    else
        systemctl disable aptgram.timer >/dev/null 2>&1 || true
    fi

    if [[ "${TIMER_WAS_ACTIVE}" == true ]]; then
        systemctl restart aptgram.timer >/dev/null 2>&1 || true
    else
        systemctl stop aptgram.timer >/dev/null 2>&1 || true
    fi
}

rollback_transaction() {
    if [[ -n "${CONFIG_CANDIDATE}" && \
        -f "${WORK_DIR}/aptgram.conf" ]]
    then
        install \
            -o root \
            -g root \
            -m 0644 \
            "${WORK_DIR}/aptgram.conf" \
            "${CONFIG_FILE}" \
            >/dev/null 2>&1 || true
    fi

    if [[ -n "${CREDENTIAL_CANDIDATE}" ]]; then
        install \
            -o root \
            -g root \
            -m 0600 \
            "${WORK_DIR}/$(basename -- "${ACTIVE_CREDENTIAL_FILE}")" \
            "${ACTIVE_CREDENTIAL_FILE}" \
            >/dev/null 2>&1 || true
    fi

    if [[ -n "${TIMER_CANDIDATE}" && \
        -f "${WORK_DIR}/aptgram.timer" ]]
    then
        install \
            -o root \
            -g root \
            -m 0644 \
            "${WORK_DIR}/aptgram.timer" \
            "${TIMER_FILE}" \
            >/dev/null 2>&1 || true
        restore_timer_state
    fi
}

cleanup() {
    local exit_code="$?"

    trap - EXIT

    if [[ "${TRANSACTION_ACTIVE}" == true ]]; then
        rollback_transaction
    fi

    if [[ -n "${CONFIG_CANDIDATE}" ]]; then
        rm -f -- "${CONFIG_CANDIDATE}" >/dev/null 2>&1 || true
    fi

    if [[ -n "${TIMER_CANDIDATE}" ]]; then
        rm -f -- "${TIMER_CANDIDATE}" >/dev/null 2>&1 || true
    fi

    if [[ -n "${CREDENTIAL_STAGING_DIR}" ]]; then
        rm -rf -- "${CREDENTIAL_STAGING_DIR}" >/dev/null 2>&1 || true
    fi

    if [[ -n "${WORK_DIR}" ]]; then
        rm -rf -- "${WORK_DIR}" >/dev/null 2>&1 || true
    fi

    exit "${exit_code}"
}

handle_signal() {
    local exit_code="$1"

    if [[ "${CHANGES_SAVED}" == true ]]; then
        printf '%s\n' \
            "${TXT_CONFIG_SAVED_NOT_CONFIRMED}" \
            >&2
    fi

    exit "${exit_code}"
}

apply_transaction() {
    TRANSACTION_ACTIVE=true

    if [[ -n "${CREDENTIAL_CANDIDATE}" ]]; then
        mv -f -- \
            "${CREDENTIAL_CANDIDATE}" \
            "${ACTIVE_CREDENTIAL_FILE}" || return 1
    fi

    if [[ -n "${CONFIG_CANDIDATE}" ]]; then
        mv -f -- \
            "${CONFIG_CANDIDATE}" \
            "${CONFIG_FILE}" || return 1
    fi

    if [[ -n "${TIMER_CANDIDATE}" ]]; then
        mv -f -- \
            "${TIMER_CANDIDATE}" \
            "${TIMER_FILE}" || return 1

        systemctl daemon-reload || return 1
        systemctl enable --now aptgram.timer || return 1
        systemctl restart aptgram.timer || return 1
        systemctl is-enabled --quiet aptgram.timer || return 1
        systemctl is-active --quiet aptgram.timer || return 1
    fi

    TRANSACTION_ACTIVE=false
}

join_changed_items() {
    local item
    local result=""
    local -a items=()

    if [[ "${TOKEN_CHANGED}" == true ]]; then
        items+=("${TXT_CONFIG_ITEM_BOT_TOKEN}")
    fi

    if [[ "${CHAT_ID_CHANGED}" == true ]]; then
        items+=("${TXT_CONFIG_ITEM_CHAT_ID}")
    fi

    if [[ "${CHECK_TIME_CHANGED}" == true ]]; then
        items+=("${TXT_CONFIG_ITEM_CHECK_TIME}")
    fi

    for item in "${items[@]}"; do
        if [[ -n "${result}" ]]; then
            result+="${TXT_CONFIG_ITEM_SEPARATOR}"
        fi

        result+="${item}"
    done

    printf '%s\n' "${result}"
}

build_final_telegram_message() {
    local changed_items

    changed_items="$(join_changed_items)"

    printf \
        '%s\n%s: %s\n%s: %s' \
        "${MSG_CONFIG_SUCCESS}" \
        "${MSG_CONFIG_CHANGED}" \
        "${changed_items}" \
        "${MSG_CONFIG_DAILY_CHECK}" \
        "${PENDING_CHECK_TIME}"
}

send_final_confirmation() {
    local answer
    local message

    message="$(build_final_telegram_message)"

    while true; do
        printf '%s\n' "${TXT_CONFIG_FINAL_TEST_SENDING}"

        if send_telegram_message_with_credentials \
            "${PENDING_BOT_TOKEN}" \
            "${PENDING_CHAT_ID}" \
            "${message}" \
            2>/dev/null
        then
            return 0
        fi

        printf '%s\n' "${TXT_CONFIG_FINAL_TEST_FAILED}" >&2
        read -r -p "${TXT_CONFIG_FINAL_TEST_RETRY} " answer || answer=""

        if ! is_affirmative_answer "${answer}"; then
            printf '%s\n' \
                "${TXT_CONFIG_FINAL_TEST_NOT_CONFIRMED}" \
                >&2
            return 1
        fi
    done
}

print_status_line() {
    local label="$1"
    local changed="$2"

    if [[ "${changed}" == true ]]; then
        printf '%s: %s\n' "${label}" "${TXT_CONFIG_CHANGED}"
    else
        printf '%s: %s\n' "${label}" "${TXT_CONFIG_UNCHANGED}"
    fi
}

show_summary() {
    printf '\n%s\n' "${TXT_CONFIG_SUMMARY}"
    printf '%s\n' "=============================="
    print_status_line "${TXT_CONFIG_ITEM_BOT_TOKEN}" "${TOKEN_CHANGED}"
    print_status_line "${TXT_CONFIG_ITEM_CHAT_ID}" "${CHAT_ID_CHANGED}"
    print_status_line "${TXT_CONFIG_ITEM_CHECK_TIME}" "${CHECK_TIME_CHANGED}"

    if [[ "${CHECK_TIME_CHANGED}" == true ]]; then
        printf '%s: %s\n' \
            "${TXT_CONFIG_ITEM_TIMER}" \
            "${TXT_CONFIG_TIMER_UPDATED}"
    else
        printf '%s: %s\n' \
            "${TXT_CONFIG_ITEM_TIMER}" \
            "${TXT_CONFIG_UNCHANGED}"
    fi
}

show_next_timer_run() {
    if [[ "${CHECK_TIME_CHANGED}" != true ]]; then
        return 0
    fi

    printf '\n%s\n' "${TXT_CONFIG_NEXT_RUN}"
    systemctl list-timers --all aptgram.timer --no-pager || true
}

aptgram_config_main() {
    trap cleanup EXIT
    trap 'handle_signal 130' INT
    trap 'handle_signal 143' TERM

    load_configured_language
    require_root
    validate_existing_installation

    printf '\n%s\n' "${TXT_CONFIG_TITLE}"
    printf '%s\n\n' "=============================="

    prompt_bot_token_change
    printf '\n'
    prompt_chat_id_change
    printf '\n'
    prompt_check_time_change

    if [[ "${TOKEN_CHANGED}" != true && \
        "${CHAT_ID_CHANGED}" != true && \
        "${CHECK_TIME_CHANGED}" != true ]]
    then
        show_summary
        printf '\n%s\n' "${TXT_CONFIG_NO_CHANGES}"
        return 0
    fi

    if ! prepare_transaction || ! apply_transaction; then
        printf '%s\n' "${TXT_CONFIG_SAVE_FAILED}" >&2
        return 1
    fi

    BOT_TOKEN="${PENDING_BOT_TOKEN}"
    TELEGRAM_CHAT_ID="${PENDING_CHAT_ID}"
    CHECK_TIME="${PENDING_CHECK_TIME}"
    CHANGES_SAVED=true

    show_next_timer_run

    if ! send_final_confirmation; then
        show_summary
        printf '%s\n' "${TXT_CONFIG_SAVED_NOT_CONFIRMED}" >&2
        return 1
    fi

    show_summary
    printf '\n%s\n' "${TXT_CONFIG_COMPLETE}"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    aptgram_config_main "$@"
fi
