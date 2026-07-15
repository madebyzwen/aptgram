#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

readonly DIST_DIR="${ROOT_DIR}/dist"
readonly VERSION_FILE="${ROOT_DIR}/VERSION"

RELEASE_VERSION=""

if [[ -r "${VERSION_FILE}" ]]; then
    IFS= read -r RELEASE_VERSION <"${VERSION_FILE}" || true
fi

readonly RELEASE_VERSION
readonly RELEASE_DIST_DIR="${DIST_DIR}/${RELEASE_VERSION}"
readonly ARCHIVE_FILE="${RELEASE_DIST_DIR}/aptgram.tar.gz"
readonly CHECKSUM_FILE="${RELEASE_DIST_DIR}/aptgram.tar.gz.sha256"
readonly RELEASE_VERSION_FILE="${RELEASE_DIST_DIR}/aptgram.version"

WORK_DIR=""
RELEASE_DIR=""

cleanup() {
    if [[ -n "${WORK_DIR}" && -d "${WORK_DIR}" ]]; then
        rm -rf "${WORK_DIR}"
    fi
}

validate_release_source() {
    local source_file
    local -a required_files=(
        "${ROOT_DIR}/aptgram"
        "${ROOT_DIR}/install.sh"
        "${ROOT_DIR}/uninstall.sh"
        "${ROOT_DIR}/update.sh"
        "${ROOT_DIR}/VERSION"
        "${ROOT_DIR}/lib/apt_updates.sh"
        "${ROOT_DIR}/lib/config.sh"
        "${ROOT_DIR}/lib/deployment.sh"
        "${ROOT_DIR}/lib/heartbeat.sh"
        "${ROOT_DIR}/lib/recovery.sh"
        "${ROOT_DIR}/lib/release.sh"
        "${ROOT_DIR}/lib/report.sh"
        "${ROOT_DIR}/lib/repository.sh"
        "${ROOT_DIR}/lib/runtime.sh"
        "${ROOT_DIR}/lib/telegram.sh"
        "${ROOT_DIR}/locales/de.sh"
        "${ROOT_DIR}/locales/en.sh"
        "${ROOT_DIR}/locales/es.sh"
        "${ROOT_DIR}/locales/fr.sh"
        "${ROOT_DIR}/locales/it.sh"
        "${ROOT_DIR}/locales/pt_BR.sh"
        "${ROOT_DIR}/systemd/aptgram.service.in"
        "${ROOT_DIR}/systemd/aptgram.timer.in"
    )

    for source_file in "${required_files[@]}"; do
        if [[ ! -f "${source_file}" ]]; then
            printf 'Required release file missing: %s\n' \
                "${source_file}" \
                >&2
            return 1
        fi
    done

    if [[ -z "${RELEASE_VERSION}" ]]; then
        printf 'APTGRAM version information is invalid.\n' >&2
        return 1
    fi

    if ! dpkg --validate-version \
        "${RELEASE_VERSION}" \
        >/dev/null 2>&1
    then
        printf 'Invalid APTGRAM version: %s\n' \
            "${RELEASE_VERSION}" \
            >&2
        return 1
    fi

    bash -n \
        "${ROOT_DIR}/aptgram" \
        "${ROOT_DIR}/install.sh" \
        "${ROOT_DIR}/uninstall.sh" \
        "${ROOT_DIR}/update.sh" \
        "${ROOT_DIR}/lib/"*.sh \
        "${ROOT_DIR}/locales/"*.sh

    "${ROOT_DIR}/tools/check-language-variables.sh"
}

prepare_release_tree() {
    WORK_DIR="$(mktemp -d)"
    RELEASE_DIR="${WORK_DIR}/release"

    install -d \
        -m 0755 \
        "${RELEASE_DIR}" \
        "${RELEASE_DIR}/lib" \
        "${RELEASE_DIR}/locales" \
        "${RELEASE_DIR}/systemd"

    install \
        -m 0755 \
        "${ROOT_DIR}/aptgram" \
        "${ROOT_DIR}/install.sh" \
        "${ROOT_DIR}/uninstall.sh" \
        "${ROOT_DIR}/update.sh" \
        "${RELEASE_DIR}/"

    install \
        -m 0644 \
        "${ROOT_DIR}/VERSION" \
        "${RELEASE_DIR}/VERSION"

    install \
        -m 0644 \
        "${ROOT_DIR}/lib/"*.sh \
        "${RELEASE_DIR}/lib/"

    install \
        -m 0644 \
        "${ROOT_DIR}/locales/"*.sh \
        "${RELEASE_DIR}/locales/"

    install \
        -m 0644 \
        "${ROOT_DIR}/systemd/"*.in \
        "${RELEASE_DIR}/systemd/"
}

build_release_archive() {
    rm -rf "${RELEASE_DIST_DIR}"

    install -d \
        -m 0755 \
        "${RELEASE_DIST_DIR}"

    tar \
        -czf "${ARCHIVE_FILE}" \
        -C "${RELEASE_DIR}" \
        .
}

write_release_checksum() {
    (
        cd "${RELEASE_DIST_DIR}"
        sha256sum aptgram.tar.gz >aptgram.tar.gz.sha256
    )
}

write_release_version() {
    install \
        -m 0644 \
        "${VERSION_FILE}" \
        "${RELEASE_VERSION_FILE}"
}

show_release_result() {
    echo
    printf 'APTGRAM release assets created.\n'
    printf 'Version: %s\n' "${RELEASE_VERSION}"
    printf 'Release directory: %s\n' "${RELEASE_DIST_DIR}"
    printf 'Archive: %s\n' "${ARCHIVE_FILE}"
    printf 'Checksum: %s\n' "${CHECKSUM_FILE}"
    printf 'Version asset: %s\n' "${RELEASE_VERSION_FILE}"
}

main() {
    trap cleanup EXIT

    validate_release_source
    prepare_release_tree
    build_release_archive
    write_release_checksum
    write_release_version
    show_release_result
}

main "$@"
