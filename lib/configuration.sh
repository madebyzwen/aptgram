#!/usr/bin/env bash

is_affirmative_answer() {
    local answer="${1,,}"

    case "${answer}" in
        y|yes|j|ja|s|si|sí|sì|sim|o|oui)
            return 0
            ;;
    esac

    return 1
}

is_valid_bot_token_format() {
    local bot_token="$1"

    [[ "${bot_token}" =~ ^[0-9]{6,}:[A-Za-z0-9_-]{20,}$ ]]
}

is_valid_telegram_chat_id() {
    local chat_id="$1"

    [[ "${chat_id}" =~ ^-?[0-9]+$ ]]
}

is_valid_check_time() {
    local check_time="$1"

    [[ "${check_time}" =~ ^([01][0-9]|2[0-3]):[0-5][0-9]$ ]]
}

verify_telegram_bot_token() {
    local bot_token="$1"

    if ! is_valid_bot_token_format "${bot_token}"; then
        return 1
    fi

    telegram_request_with_token \
        "${bot_token}" \
        "getMe" \
        >/dev/null 2>&1
}

verify_telegram_chat_id() {
    local bot_token="$1"
    local chat_id="$2"
    local test_message="$3"

    if ! is_valid_telegram_chat_id "${chat_id}"; then
        return 1
    fi

    send_telegram_message_with_credentials \
        "${bot_token}" \
        "${chat_id}" \
        "${test_message}" \
        >/dev/null 2>&1
}
