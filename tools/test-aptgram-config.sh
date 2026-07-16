#!/usr/bin/env bash

# Mock functions are invoked indirectly by sourced production code.
# shellcheck disable=SC2317

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
TEST_ROOT="$(mktemp -d /tmp/aptgram-config-tests.XXXXXX)"

readonly OLD_TOKEN="123456789:ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghi"
readonly NEW_TOKEN="987654321:zyxwvutsrqponmlkjihgfedcbaZYXWVUT"

CASE_DIR=""
CASE_STATUS=0

cleanup() {
    rm -rf -- "${TEST_ROOT}"
}

trap cleanup EXIT

fail() {
    printf 'FEHLER: %s\n' "$1" >&2
    exit 1
}

assert_status() {
    local expected="$1"

    if [[ "${CASE_STATUS}" != "${expected}" ]]; then
        sed -n '1,240p' "${CASE_DIR}/output.log" >&2
        fail "Unerwarteter Exit-Code: ${CASE_STATUS}, erwartet: ${expected}"
    fi
}

assert_contains() {
    local file="$1"
    local pattern="$2"

    if ! grep -Fq -- "${pattern}" "${file}"; then
        fail "Text fehlt in ${file}: ${pattern}"
    fi
}

assert_not_contains() {
    local file="$1"
    local pattern="$2"

    if grep -Fq -- "${pattern}" "${file}"; then
        fail "Unerwarteter Text in ${file}: ${pattern}"
    fi
}

assert_same_file() {
    local first="$1"
    local second="$2"

    if ! cmp -s -- "${first}" "${second}"; then
        fail "Dateien unterscheiden sich: ${first}, ${second}"
    fi
}

assert_mode() {
    local file="$1"
    local expected="$2"
    local actual

    actual="$(stat -c '%a' "${file}")"

    if [[ "${actual}" != "${expected}" ]]; then
        fail "Falsche Dateirechte für ${file}: ${actual}, erwartet: ${expected}"
    fi
}

create_fixture() {
    local name="$1"
    local credential_mode="${2:-plain}"

    CASE_DIR="${TEST_ROOT}/${name}"

    mkdir -p \
        "${CASE_DIR}/bin" \
        "${CASE_DIR}/credentials" \
        "${CASE_DIR}/systemd"

    install -m 0755 /bin/true "${CASE_DIR}/bin/aptgram"

    printf '%s\n' \
        'APTGRAM_LANGUAGE=en' \
        'TELEGRAM_CHAT_ID=-100' \
        'CHECK_TIME=20:00' \
        'PRESERVED_SETTING=keep-me' \
        >"${CASE_DIR}/aptgram.conf"
    chmod 0644 "${CASE_DIR}/aptgram.conf"

    printf '%s\n' \
        '[Unit]' \
        'Description=APTGRAM test service' \
        >"${CASE_DIR}/systemd/aptgram.service"

    printf '%s\n' \
        '[Unit]' \
        'Description=Run APTGRAM daily' \
        '' \
        '[Timer]' \
        'OnCalendar=*-*-* 20:00:00' \
        'Persistent=true' \
        >"${CASE_DIR}/systemd/aptgram.timer"

    case "${credential_mode}" in
        plain)
            printf '%s' "${OLD_TOKEN}" \
                >"${CASE_DIR}/credentials/telegram-bot-token"
            chmod 0600 "${CASE_DIR}/credentials/telegram-bot-token"
            ;;
        encrypted)
            printf '%s' 'mock-encrypted-credential' \
                >"${CASE_DIR}/credentials/telegram-bot-token.cred"
            chmod 0600 "${CASE_DIR}/credentials/telegram-bot-token.cred"
            ;;
        *)
            fail "Unbekannter Test-Credential-Modus: ${credential_mode}"
            ;;
    esac
}

run_case() {
    local input="$1"
    local curl_mode="${2:-success}"
    local systemctl_mode="${3:-success}"

    : >"${CASE_DIR}/curl.log"
    : >"${CASE_DIR}/systemctl.log"

    set +e
    (
        export APTGRAM_BIN="${CASE_DIR}/bin/aptgram"
        export APTGRAM_CONFIG_FILE="${CASE_DIR}/aptgram.conf"
        export APTGRAM_CREDENTIAL_DIR="${CASE_DIR}/credentials"
        export APTGRAM_LOCALES_DIR="${PROJECT_DIR}/locales"
        export APTGRAM_SYSTEMD_UNIT_DIR="${CASE_DIR}/systemd"

        # shellcheck source=/dev/null
        source "${PROJECT_DIR}/aptgram-config"

        require_root() {
            return 0
        }

        set_root_ownership() {
            return 0
        }

        install() {
            local argument
            local skip_next=false
            local -a arguments=()

            for argument in "$@"; do
                if [[ "${skip_next}" == true ]]; then
                    skip_next=false
                    continue
                fi

                case "${argument}" in
                    -o|-g)
                        skip_next=true
                        ;;
                    *)
                        arguments+=("${argument}")
                        ;;
                esac
            done

            command install "${arguments[@]}"
        }

        systemd-creds() {
            local command_name="$1"

            shift

            case "${command_name}" in
                decrypt)
                    printf '%s' "${OLD_TOKEN}"
                    ;;
                encrypt)
                    local output_file="${*: -1}"

                    command cat >/dev/null
                    printf '%s' 'mock-encrypted-credential-updated' \
                        >"${output_file}"
                    ;;
                *)
                    return 1
                    ;;
            esac
        }

        systemctl() {
            printf '%s\n' "$*" >>"${CASE_DIR}/systemctl.log"

            case "$1" in
                is-enabled|is-active)
                    return 0
                    ;;
                restart)
                    if [[ "${systemctl_mode}" == "fail-restart" ]]; then
                        return 1
                    fi
                    ;;
                list-timers)
                    printf 'aptgram.timer mock-next-run\n'
                    ;;
            esac

            return 0
        }

        curl() {
            local argument
            local chat_id=""
            local message=""
            local method="unknown"
            local request_config
            local token_label="old"

            request_config="$(command cat)"

            case "${request_config}" in
                *"${NEW_TOKEN}"*) token_label="new" ;;
            esac

            case "${request_config}" in
                */getMe*) method="getMe" ;;
                */sendMessage*) method="sendMessage" ;;
            esac

            for argument in "$@"; do
                case "${argument}" in
                    chat_id=*) chat_id="${argument#chat_id=}" ;;
                    text=*) message="${argument#text=}" ;;
                esac
            done

            if [[ "${method}" == "getMe" ]]; then
                printf 'getMe:%s\n' "${token_label}" \
                    >>"${CASE_DIR}/curl.log"

                if [[ "${curl_mode}" == "reject-new-token" && \
                    "${token_label}" == "new" ]]
                then
                    return 22
                fi

                return 0
            fi

            if [[ "${message}" == *"APTGRAM configuration updated successfully."* ]]; then
                printf 'final:%s:%s:%s\n' \
                    "${token_label}" \
                    "${chat_id}" \
                    "${message}" \
                    >>"${CASE_DIR}/curl.log"

                if [[ "${curl_mode}" == "fail-final" ]]; then
                    return 22
                fi
            else
                printf 'chat-test:%s:%s\n' \
                    "${token_label}" \
                    "${chat_id}" \
                    >>"${CASE_DIR}/curl.log"

                if [[ "${curl_mode}" == "reject-chat" ]]; then
                    return 22
                fi
            fi

            return 0
        }

        main <<<"${input}"
    ) >"${CASE_DIR}/output.log" 2>&1
    CASE_STATUS="$?"
    set -e

    assert_not_contains "${CASE_DIR}/output.log" "${OLD_TOKEN}"
    assert_not_contains "${CASE_DIR}/output.log" "${NEW_TOKEN}"
    assert_not_contains "${CASE_DIR}/curl.log" "${OLD_TOKEN}"
    assert_not_contains "${CASE_DIR}/curl.log" "${NEW_TOKEN}"
}

create_fixture no_changes
cp -p "${CASE_DIR}/aptgram.conf" "${CASE_DIR}/aptgram.conf.before"
run_case $'n\nn\nn'
assert_status 0
assert_same_file "${CASE_DIR}/aptgram.conf.before" "${CASE_DIR}/aptgram.conf"
[[ ! -s "${CASE_DIR}/curl.log" ]] || fail "Ohne Änderungen wurde Telegram aufgerufen."

create_fixture root_required
cp -p "${CASE_DIR}/aptgram.conf" "${CASE_DIR}/aptgram.conf.before"
set +e
APTGRAM_BIN="${CASE_DIR}/bin/aptgram" \
APTGRAM_CONFIG_FILE="${CASE_DIR}/aptgram.conf" \
APTGRAM_CREDENTIAL_DIR="${CASE_DIR}/credentials" \
APTGRAM_LOCALES_DIR="${PROJECT_DIR}/locales" \
APTGRAM_SYSTEMD_UNIT_DIR="${CASE_DIR}/systemd" \
    "${PROJECT_DIR}/aptgram-config" \
    >"${CASE_DIR}/output.log" \
    2>&1 \
    <<<'n'
CASE_STATUS="$?"
set -e
assert_status 1
assert_contains "${CASE_DIR}/output.log" 'aptgram-config must be run as root.'
assert_same_file "${CASE_DIR}/aptgram.conf.before" "${CASE_DIR}/aptgram.conf"

create_fixture incomplete_installation
rm -f "${CASE_DIR}/systemd/aptgram.timer"
run_case $'n\nn\nn'
assert_status 1
assert_contains "${CASE_DIR}/output.log" \
    'The APTGRAM installation or configuration is incomplete.'

create_fixture token_only
cp -p "${CASE_DIR}/aptgram.conf" "${CASE_DIR}/aptgram.conf.before"
run_case $'y\n'"${NEW_TOKEN}"$'\nn\nn'
assert_status 0
assert_same_file "${CASE_DIR}/aptgram.conf.before" "${CASE_DIR}/aptgram.conf"
[[ "$(<"${CASE_DIR}/credentials/telegram-bot-token")" == "${NEW_TOKEN}" ]] ||
    fail "Der neue Bot Token wurde nicht gespeichert."
assert_mode "${CASE_DIR}/credentials/telegram-bot-token" 600
assert_contains "${CASE_DIR}/curl.log" 'getMe:new'
assert_contains "${CASE_DIR}/curl.log" 'final:new:-100:'

create_fixture aborted_after_token_validation
cp -p "${CASE_DIR}/credentials/telegram-bot-token" \
    "${CASE_DIR}/token.before"
run_case $'y\n'"${NEW_TOKEN}"
assert_status 1
assert_same_file "${CASE_DIR}/token.before" \
    "${CASE_DIR}/credentials/telegram-bot-token"

create_fixture chat_only
run_case $'n\ny\n-200\nn'
assert_status 0
assert_contains "${CASE_DIR}/aptgram.conf" 'TELEGRAM_CHAT_ID=-200'
assert_contains "${CASE_DIR}/aptgram.conf" 'PRESERVED_SETTING=keep-me'
assert_contains "${CASE_DIR}/curl.log" 'chat-test:old:-200'
assert_contains "${CASE_DIR}/curl.log" 'final:old:-200:'

create_fixture time_only
run_case $'n\nn\ny\n21:45'
assert_status 0
assert_contains "${CASE_DIR}/aptgram.conf" 'CHECK_TIME=21:45'
assert_mode "${CASE_DIR}/aptgram.conf" 644
assert_contains "${CASE_DIR}/systemd/aptgram.timer" 'OnCalendar=*-*-* 21:45:00'
assert_mode "${CASE_DIR}/systemd/aptgram.timer" 644
assert_contains "${CASE_DIR}/systemctl.log" 'enable --now aptgram.timer'
assert_contains "${CASE_DIR}/systemctl.log" 'is-active --quiet aptgram.timer'
assert_contains "${CASE_DIR}/systemctl.log" 'list-timers --all aptgram.timer --no-pager'
assert_contains "${CASE_DIR}/curl.log" 'Daily check: 21:45'

create_fixture all_changes
run_case $'y\n'"${NEW_TOKEN}"$'\ny\n-300\ny\n22:30'
assert_status 0
assert_contains "${CASE_DIR}/aptgram.conf" 'TELEGRAM_CHAT_ID=-300'
assert_contains "${CASE_DIR}/aptgram.conf" 'CHECK_TIME=22:30'
assert_contains "${CASE_DIR}/curl.log" 'chat-test:new:-300'
assert_contains "${CASE_DIR}/curl.log" 'final:new:-300:'
assert_contains "${CASE_DIR}/curl.log" 'Daily check: 22:30'

create_fixture invalid_token
cp -p "${CASE_DIR}/credentials/telegram-bot-token" \
    "${CASE_DIR}/token.before"
run_case $'y\n'"${NEW_TOKEN}"$'\n\nn\nn' reject-new-token
assert_status 0
assert_same_file "${CASE_DIR}/token.before" \
    "${CASE_DIR}/credentials/telegram-bot-token"
assert_contains "${CASE_DIR}/curl.log" 'getMe:new'

create_fixture invalid_chat
cp -p "${CASE_DIR}/aptgram.conf" "${CASE_DIR}/aptgram.conf.before"
run_case $'n\ny\n-999\n\nn' reject-chat
assert_status 0
assert_same_file "${CASE_DIR}/aptgram.conf.before" "${CASE_DIR}/aptgram.conf"
assert_contains "${CASE_DIR}/curl.log" 'chat-test:old:-999'

create_fixture invalid_time
cp -p "${CASE_DIR}/aptgram.conf" "${CASE_DIR}/aptgram.conf.before"
run_case $'n\nn\ny\n25:99\n'
assert_status 0
assert_same_file "${CASE_DIR}/aptgram.conf.before" "${CASE_DIR}/aptgram.conf"

create_fixture timer_rollback
cp -p "${CASE_DIR}/aptgram.conf" "${CASE_DIR}/aptgram.conf.before"
cp -p "${CASE_DIR}/systemd/aptgram.timer" "${CASE_DIR}/aptgram.timer.before"
run_case $'n\nn\ny\n23:15' success fail-restart
assert_status 1
assert_same_file "${CASE_DIR}/aptgram.conf.before" "${CASE_DIR}/aptgram.conf"
assert_same_file "${CASE_DIR}/aptgram.timer.before" \
    "${CASE_DIR}/systemd/aptgram.timer"

create_fixture final_failure
run_case $'n\nn\ny\n19:10\nn' fail-final
assert_status 1
assert_contains "${CASE_DIR}/aptgram.conf" 'CHECK_TIME=19:10'
assert_contains "${CASE_DIR}/systemd/aptgram.timer" 'OnCalendar=*-*-* 19:10:00'
assert_contains "${CASE_DIR}/output.log" \
    'The saved settings remain active; Telegram confirmation failed.'

create_fixture encrypted_token encrypted
run_case $'y\n'"${NEW_TOKEN}"$'\nn\nn'
assert_status 0
[[ -f "${CASE_DIR}/credentials/telegram-bot-token.cred" ]] ||
    fail "Das verschlüsselte Credential fehlt."
[[ ! -e "${CASE_DIR}/credentials/telegram-bot-token" ]] ||
    fail "Das verschlüsselte Credential wurde auf Klartext zurückgestuft."

deployment_dir="${TEST_ROOT}/deployment"
mkdir -p \
    "${deployment_dir}/bin" \
    "${deployment_dir}/lib" \
    "${deployment_dir}/locales" \
    "${deployment_dir}/state"

(
    # shellcheck source=/dev/null
    source "${PROJECT_DIR}/lib/deployment.sh"

    install() {
        local argument
        local skip_next=false
        local -a arguments=()

        for argument in "$@"; do
            if [[ "${skip_next}" == true ]]; then
                skip_next=false
                continue
            fi

            case "${argument}" in
                -o|-g)
                    skip_next=true
                    ;;
                *)
                    arguments+=("${argument}")
                    ;;
            esac
        done

        command install "${arguments[@]}"
    }

    sudo() {
        "$@"
    }

    install_program_files \
        "${PROJECT_DIR}" \
        "${deployment_dir}/bin" \
        "${deployment_dir}/lib" \
        "${deployment_dir}/locales" \
        "${deployment_dir}/state"
)

[[ -x "${deployment_dir}/bin/aptgram-config" ]] ||
    fail "aptgram-config wurde vom Installer nicht ausführbar installiert."
[[ -f "${deployment_dir}/lib/configuration.sh" ]] ||
    fail "Die gemeinsame Konfigurationsbibliothek wurde nicht installiert."
[[ -f "${deployment_dir}/lib/config_command.sh" ]] ||
    fail "Die Implementierung von aptgram-config wurde nicht installiert."

printf 'aptgram-config: alle automatisierten Verhaltenstests erfolgreich.\n'
