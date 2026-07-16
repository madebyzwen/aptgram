telegram_request_with_token() {
    local bot_token="$1"
    local method="$2"

    shift 2

    printf 'url = "https://api.telegram.org/bot%s/%s"\n' \
        "${bot_token}" \
        "${method}" |
        curl \
            --disable \
            --silent \
            --show-error \
            --fail-with-body \
            --config - \
            "$@"
}

telegram_request() {
    local method="$1"

    shift

    telegram_request_with_token \
        "${BOT_TOKEN}" \
        "${method}" \
        "$@"
}

send_telegram_message_with_credentials() {
    local bot_token="$1"
    local chat_id="$2"
    local message="$3"

    telegram_request_with_token \
        "${bot_token}" \
        "sendMessage" \
        --data-urlencode "chat_id=${chat_id}" \
        --data-urlencode "text=${message}" \
        --data-urlencode 'link_preview_options={"is_disabled":true}' \
        >/dev/null
}

send_telegram_message() {
    local message="$1"

    send_telegram_message_with_credentials \
        "${BOT_TOKEN}" \
        "${TELEGRAM_CHAT_ID}" \
        "${message}"
}

send_telegram_document() {
    local document_file="$1"
    local caption="$2"
    local document_name

    document_name="$(basename -- "${document_file}")"

    telegram_request \
        "sendDocument" \
        --form-string "chat_id=${TELEGRAM_CHAT_ID}" \
        --form-string "caption=${caption}" \
        --form "document=@${document_file};type=text/plain;filename=${document_name}" \
        >/dev/null
}
