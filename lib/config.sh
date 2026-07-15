load_configuration() {
    if [[ ! -r "${CONFIG_FILE}" ]]; then
        echo "APTGRAM configuration not found: ${CONFIG_FILE}" >&2
        exit 1
    fi

    # shellcheck source=/dev/null
    source "${CONFIG_FILE}"
}

load_language() {
    local locale_file="${LOCALES_DIR}/${APTGRAM_LANGUAGE}.sh"

    if [[ ! -r "${locale_file}" ]]; then
        locale_file="${LOCALES_DIR}/en.sh"
    fi

    # shellcheck source=/dev/null
    source "${locale_file}"
}

load_distribution() {
    if [[ ! -r /etc/os-release ]]; then
        echo "APTGRAM cannot determine the Linux distribution." >&2
        exit 1
    fi

    # shellcheck source=/dev/null
    source /etc/os-release

    DISTRO_ID="${ID:-}"
}

load_bot_token() {
    local credential_file

    if [[ -z "${CREDENTIALS_DIRECTORY:-}" ]]; then
        echo "APTGRAM must be started by systemd." >&2
        exit 1
    fi

    credential_file="${CREDENTIALS_DIRECTORY}/telegram-bot-token"

    if [[ ! -r "${credential_file}" ]]; then
        echo "Telegram bot credential is unavailable." >&2
        exit 1
    fi

    BOT_TOKEN="$(<"${credential_file}")"
}
