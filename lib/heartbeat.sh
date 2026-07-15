is_heartbeat_day() {
    [[ "$(date +%u)" == "7" ]]
}

build_heartbeat_message() {
    local hostname

    hostname="$(hostname)"

    printf \
        '%s\n\n%s\n\n%s\n%s\n\n%s: %s' \
        "${MSG_HEARTBEAT_TITLE}" \
        "${MSG_HEARTBEAT_TEXT}" \
        "${MSG_HEARTBEAT_SUPPORT}" \
        "${APTGRAM_SUPPORT_URL}" \
        "${MSG_SERVER}" \
        "${hostname}"
}
