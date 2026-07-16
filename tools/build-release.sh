#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

readonly DIST_DIR="${ROOT_DIR}/dist"
readonly VERSION_FILE="${ROOT_DIR}/VERSION"

RELEASE_VERSION=""
SOURCE_EPOCH="${SOURCE_DATE_EPOCH:-}"
WORK_DIR=""
RELEASE_DIR=""

if [[ -r "${VERSION_FILE}" ]]; then
    IFS= read -r RELEASE_VERSION <"${VERSION_FILE}" || true
fi

readonly RELEASE_VERSION
readonly ARCHIVE_BASENAME="aptgram-v${RELEASE_VERSION}.tar.gz"
readonly CHECKSUM_BASENAME="${ARCHIVE_BASENAME}.sha256"
readonly ARCHIVE_FILE="${DIST_DIR}/${ARCHIVE_BASENAME}"
readonly CHECKSUM_FILE="${DIST_DIR}/${CHECKSUM_BASENAME}"
readonly COMPAT_ARCHIVE_FILE="${DIST_DIR}/aptgram.tar.gz"
readonly COMPAT_CHECKSUM_FILE="${DIST_DIR}/aptgram.tar.gz.sha256"
readonly COMPAT_VERSION_FILE="${DIST_DIR}/aptgram.version"

readonly -a RELEASE_FILES=(
    "aptgram"
    "aptgram-config"
    "install.sh"
    "uninstall.sh"
    "update.sh"
    "VERSION"
    "README.md"
    "CHANGELOG.md"
    "LICENSE"
    "SECURITY.md"
    "lib/apt_updates.sh"
    "lib/config.sh"
    "lib/configuration.sh"
    "lib/config_command.sh"
    "lib/deployment.sh"
    "lib/heartbeat.sh"
    "lib/recovery.sh"
    "lib/release.sh"
    "lib/report.sh"
    "lib/repository.sh"
    "lib/runtime.sh"
    "lib/telegram.sh"
    "locales/de.sh"
    "locales/en.sh"
    "locales/es.sh"
    "locales/fr.sh"
    "locales/it.sh"
    "locales/pt_BR.sh"
    "systemd/aptgram.service.in"
    "systemd/aptgram.timer.in"
    "docs/INSTALLATION_DE.md"
    "docs/INSTALLATION_EN.md"
    "docs/INSTALLATION_ES.md"
    "docs/INSTALLATION_FR.md"
    "docs/INSTALLATION_IT.md"
    "docs/INSTALLATION_PT_BR.md"
    "docs/images/logo.png"
    "docs/images/telegram-botfather-token.png"
    "docs/images/telegram-channel-admin.png"
    "docs/images/telegram-chat-id.png"
    "docs/images/telegram-notification.png"
    "docs/images/telegram-test-message.png"
    "docs/images/update-report.png"
)

cleanup() {
    if [[ -n "${WORK_DIR}" && -d "${WORK_DIR}" ]]; then
        rm -rf -- "${WORK_DIR}"
    fi
}

validate_release_version() {
    if [[ ! "${RELEASE_VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
        ! dpkg --validate-version "${RELEASE_VERSION}" >/dev/null 2>&1
    then
        printf 'Invalid APTGRAM version: %s\n' \
            "${RELEASE_VERSION:-<empty>}" \
            >&2
        return 1
    fi
}

validate_release_source() {
    local relative_file
    local source_file

    for relative_file in "${RELEASE_FILES[@]}"; do
        source_file="${ROOT_DIR}/${relative_file}"

        if [[ ! -f "${source_file}" ]]; then
            printf 'Required release file missing: %s\n' \
                "${relative_file}" \
                >&2
            return 1
        fi
    done

    bash -n \
        "${ROOT_DIR}/aptgram" \
        "${ROOT_DIR}/aptgram-config" \
        "${ROOT_DIR}/install.sh" \
        "${ROOT_DIR}/uninstall.sh" \
        "${ROOT_DIR}/update.sh" \
        "${ROOT_DIR}/lib/"*.sh \
        "${ROOT_DIR}/locales/"*.sh

    "${ROOT_DIR}/tools/check-language-variables.sh"
}

refuse_existing_assets() {
    local asset
    local -a assets=(
        "${ARCHIVE_FILE}"
        "${CHECKSUM_FILE}"
        "${COMPAT_ARCHIVE_FILE}"
        "${COMPAT_CHECKSUM_FILE}"
        "${COMPAT_VERSION_FILE}"
    )

    for asset in "${assets[@]}"; do
        if [[ -e "${asset}" ]]; then
            printf 'Release asset already exists: %s\n' \
                "${asset}" \
                >&2
            return 1
        fi
    done
}

determine_source_epoch() {
    if [[ -z "${SOURCE_EPOCH}" ]]; then
        SOURCE_EPOCH="$(
            git -C "${ROOT_DIR}" log -1 --format=%ct
        )"
    fi

    if [[ ! "${SOURCE_EPOCH}" =~ ^[0-9]+$ ]]; then
        printf 'Invalid SOURCE_DATE_EPOCH: %s\n' \
            "${SOURCE_EPOCH:-<empty>}" \
            >&2
        return 1
    fi
}

prepare_release_tree() {
    local destination
    local mode
    local relative_file

    WORK_DIR="$(mktemp -d /tmp/aptgram-release.XXXXXX)"
    RELEASE_DIR="${WORK_DIR}/release"
    install -d -m 0755 "${RELEASE_DIR}"

    for relative_file in "${RELEASE_FILES[@]}"; do
        destination="${RELEASE_DIR}/${relative_file}"
        install -d -m 0755 "$(dirname -- "${destination}")"

        case "${relative_file}" in
            aptgram|aptgram-config|install.sh|uninstall.sh|update.sh)
                mode=0755
                ;;
            *)
                mode=0644
                ;;
        esac

        install \
            -m "${mode}" \
            "${ROOT_DIR}/${relative_file}" \
            "${destination}"
    done
}

build_release_archive() {
    install -d -m 0755 "${DIST_DIR}"

    tar \
        --sort=name \
        --mtime="@${SOURCE_EPOCH}" \
        --owner=0 \
        --group=0 \
        --numeric-owner \
        --format=gnu \
        -cf - \
        -C "${RELEASE_DIR}" \
        . |
        gzip -9 -n >"${ARCHIVE_FILE}"
}

write_release_assets() {
    (
        cd "${DIST_DIR}"
        sha256sum "${ARCHIVE_BASENAME}" >"${CHECKSUM_BASENAME}"
    )

    cp -p -- "${ARCHIVE_FILE}" "${COMPAT_ARCHIVE_FILE}"

    (
        cd "${DIST_DIR}"
        sha256sum aptgram.tar.gz >aptgram.tar.gz.sha256
    )

    printf '%s\n' "${RELEASE_VERSION}" >"${COMPAT_VERSION_FILE}"
}

show_release_result() {
    printf '\nAPTGRAM release assets created.\n'
    printf 'Version: %s\n' "${RELEASE_VERSION}"
    printf 'Archive: %s\n' "${ARCHIVE_FILE}"
    printf 'Checksum: %s\n' "${CHECKSUM_FILE}"
    printf 'Compatibility archive: %s\n' "${COMPAT_ARCHIVE_FILE}"
    printf 'Compatibility checksum: %s\n' "${COMPAT_CHECKSUM_FILE}"
    printf 'Compatibility version: %s\n' "${COMPAT_VERSION_FILE}"
    printf '\nArchive contents:\n'
    tar -tzf "${ARCHIVE_FILE}"
}

print_release_files() {
    printf '%s\n' "${RELEASE_FILES[@]}"
}

main() {
    trap cleanup EXIT

    validate_release_version
    validate_release_source
    refuse_existing_assets
    determine_source_epoch
    prepare_release_tree
    build_release_archive
    write_release_assets
    show_release_result
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    case "${1:-}" in
        --print-files)
            print_release_files
            ;;
        "")
            main
            ;;
        *)
            printf 'Usage: tools/build-release.sh [--print-files]\n' >&2
            exit 2
            ;;
    esac
fi
