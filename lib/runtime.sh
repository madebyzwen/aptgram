initialize_runtime() {
    umask 077

    WORK_DIR="$(mktemp -d /tmp/aptgram.XXXXXX)"
    UPDATE_DATA_FILE="${WORK_DIR}/updates.tsv"
    REPORT_FILE="${WORK_DIR}/aptgram-updates-$(date '+%Y-%m-%d-%H%M').txt"
}

cleanup_runtime() {
    if [[ -n "${WORK_DIR}" && -d "${WORK_DIR}" ]]; then
        rm -rf -- "${WORK_DIR}"
    fi
}
