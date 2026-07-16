#!/usr/bin/env bash

set -Eeuo pipefail

download_latest_release_assets() {
    local repository_url="$1"
    local work_dir="$2"
    local archive_file="${work_dir}/aptgram.tar.gz"
    local checksum_file="${work_dir}/aptgram.tar.gz.sha256"

    curl \
        --location \
        --fail \
        --silent \
        --show-error \
        --retry 3 \
        --output "${archive_file}" \
        "${repository_url}/releases/latest/download/aptgram.tar.gz"

    curl \
        --location \
        --fail \
        --silent \
        --show-error \
        --retry 3 \
        --output "${checksum_file}" \
        "${repository_url}/releases/latest/download/aptgram.tar.gz.sha256"
}

download_latest_release_version() {
    local repository_url="$1"
    local version_file="$2"

    curl \
        --location \
        --fail \
        --silent \
        --retry 3 \
        --output "${version_file}" \
        "${repository_url}/releases/latest/download/aptgram.version"
}

verify_release_checksum() {
    local work_dir="$1"
    local archive_file="${work_dir}/aptgram.tar.gz"
    local checksum_file="${work_dir}/aptgram.tar.gz.sha256"
    local expected_checksum
    local actual_checksum

    expected_checksum="$(awk 'NR == 1 {print $1}' "${checksum_file}")"

    if [[ ! "${expected_checksum}" =~ ^[[:xdigit:]]{64}$ ]]; then
        return 1
    fi

    actual_checksum="$(sha256sum "${archive_file}" | awk '{print $1}')"

    [[ "${actual_checksum,,}" == "${expected_checksum,,}" ]]
}

validate_release_archive() {
    local work_dir="$1"
    local archive_file="${work_dir}/aptgram.tar.gz"
    local archive_entries
    local archive_entry

    archive_entries="$(tar -tzf "${archive_file}")" ||
        return 1

    while IFS= read -r archive_entry; do
        case "${archive_entry}" in
            ..|../*|*/../*|*/..|/*)
                return 1
                ;;
        esac
    done <<<"${archive_entries}"
}

extract_release_archive() {
    local work_dir="$1"
    local extract_dir="$2"
    local archive_file="${work_dir}/aptgram.tar.gz"

    install -d \
        -m 0700 \
        "${extract_dir}"

    tar \
        -xzf "${archive_file}" \
        -C "${extract_dir}"
}

validate_release_tree() {
    local source_dir="$1"
    local source_file
    local -a required_files=(
        "${source_dir}/aptgram"
        "${source_dir}/aptgram-config"
        "${source_dir}/install.sh"
        "${source_dir}/uninstall.sh"
        "${source_dir}/update.sh"
        "${source_dir}/VERSION"
        "${source_dir}/lib/config.sh"
        "${source_dir}/lib/config_command.sh"
        "${source_dir}/lib/configuration.sh"
        "${source_dir}/lib/deployment.sh"
        "${source_dir}/lib/heartbeat.sh"
        "${source_dir}/lib/recovery.sh"
        "${source_dir}/lib/release.sh"
        "${source_dir}/lib/report.sh"
        "${source_dir}/lib/repository.sh"
        "${source_dir}/lib/runtime.sh"
        "${source_dir}/lib/telegram.sh"
        "${source_dir}/lib/apt_updates.sh"
        "${source_dir}/locales/de.sh"
        "${source_dir}/locales/en.sh"
        "${source_dir}/locales/es.sh"
        "${source_dir}/locales/fr.sh"
        "${source_dir}/locales/it.sh"
        "${source_dir}/locales/pt_BR.sh"
        "${source_dir}/systemd/aptgram.service.in"
        "${source_dir}/systemd/aptgram.timer.in"
    )

    for source_file in "${required_files[@]}"; do
        if [[ ! -f "${source_file}" ]]; then
            return 1
        fi
    done

    if [[ -n "$(find "${source_dir}" -type l -print -quit)" ]]; then
        return 1
    fi
}

read_aptgram_version() {
    local version_file="$1"
    local version

    if [[ ! -r "${version_file}" ]]; then
        return 1
    fi

    IFS= read -r version <"${version_file}" || true

    if [[ -z "${version}" ]]; then
        return 1
    fi

    if ! dpkg --validate-version "${version}" >/dev/null 2>&1; then
        return 1
    fi

    printf '%s\n' "${version}"
}

get_version_relation() {
    local installed_version="$1"
    local available_version="$2"

    if dpkg --compare-versions \
        "${installed_version}" \
        eq \
        "${available_version}"
    then
        printf 'current\n'
        return 0
    fi

    if dpkg --compare-versions \
        "${installed_version}" \
        gt \
        "${available_version}"
    then
        printf 'downgrade\n'
        return 0
    fi

    printf 'update\n'
}
