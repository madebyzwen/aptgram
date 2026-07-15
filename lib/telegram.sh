telegram_request() {
    local method="$1"

    shift

    printf 'url = "https://api.telegram.org/bot%s/%s"\n' \
        "${BOT_TOKEN}" \
        "${method}" |
        curl \
            --disable \
            --silent \
            --show-error \
            --fail-with-body \
            --config - \
            "$@"
}

send_telegram_message() {
    local message="$1"

    telegram_request \
        "sendMessage" \
        --data-urlencode "chat_id=${TELEGRAM_CHAT_ID}" \
        --data-urlencode "text=${message}" \
        --data-urlencode 'link_preview_options={"is_disabled":true}' \
        >/dev/null
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
