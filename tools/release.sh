#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &&
        pwd
)"

readonly ROOT_DIR
readonly BUILD_SCRIPT="${ROOT_DIR}/tools/build-release.sh"
readonly LANGUAGE_CHECK_SCRIPT="${ROOT_DIR}/tools/check-language-variables.sh"
readonly VERSION_FILE="${ROOT_DIR}/VERSION"
readonly DIST_DIR="${ROOT_DIR}/dist"

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
TEST_LOG=""

declare -a TEST_RESULTS=()

cleanup() {
    if [[ -n "${WORK_DIR}" && -d "${WORK_DIR}" ]]; then
        rm -rf -- "${WORK_DIR}"
    fi
}

fail_test() {
    local test_description="$1"

    echo
    echo "========================================"
    echo "APTGRAM Release Build"
    echo "========================================"
    echo
    printf '%s = FEHLER\n' "${test_description}"

    if [[ -s "${TEST_LOG}" ]]; then
        echo
        cat "${TEST_LOG}"
    fi

    echo
    echo "Release-Build abgebrochen."

    exit 1
}

run_test() {
    local test_description="$1"

    shift

    printf '%s ... ' "${test_description}"

    : >"${TEST_LOG}"

    if ! "$@" >"${TEST_LOG}" 2>&1; then
        printf 'FEHLER\n'
        fail_test "${test_description}"
    fi

    printf 'OK\n'

    TEST_RESULTS+=(
        "${test_description} = OK"
    )
}

check_git_clean() {
    local git_status

    git --no-pager \
        -C "${ROOT_DIR}" \
        diff \
        --check

    git_status="$(
        git \
            -C "${ROOT_DIR}" \
            status \
            --porcelain \
            --untracked-files=all
    )"

    if [[ -n "${git_status}" ]]; then
        printf '%s\n' "${git_status}"
        return 1
    fi
}

check_language_files() {
    bash "${LANGUAGE_CHECK_SCRIPT}"
}

check_bash_syntax() {
    bash -n \
        "${ROOT_DIR}/aptgram" \
        "${ROOT_DIR}/install.sh" \
        "${ROOT_DIR}/uninstall.sh" \
        "${ROOT_DIR}/update.sh" \
        "${ROOT_DIR}"/lib/*.sh \
        "${ROOT_DIR}"/locales/*.sh \
        "${ROOT_DIR}"/tools/*.sh
}

build_release() {
    bash "${BUILD_SCRIPT}"
}

verify_checksum() {
    (
        cd "${RELEASE_DIST_DIR}"

        sha256sum -c \
            "$(basename -- "${CHECKSUM_FILE}")"
    )
}

verify_versions() {
    local source_version
    local release_version
    local archive_version

    IFS= read -r source_version <"${VERSION_FILE}"
    IFS= read -r release_version <"${RELEASE_VERSION_FILE}"

    archive_version="$(
        tar \
            -xOf "${ARCHIVE_FILE}" \
            ./VERSION
    )"

    [[ -n "${source_version}" ]]
    [[ "${source_version}" == "${RELEASE_VERSION}" ]]
    [[ "${source_version}" == "${release_version}" ]]
    [[ "${source_version}" == "${archive_version}" ]]
}

verify_release_contents() {
    local archive_entries
    local required_file

    local -a required_files=(
        "./aptgram"
        "./install.sh"
        "./uninstall.sh"
        "./update.sh"
        "./VERSION"
        "./lib/config.sh"
        "./lib/deployment.sh"
        "./lib/heartbeat.sh"
        "./lib/recovery.sh"
        "./lib/release.sh"
        "./lib/report.sh"
        "./lib/repository.sh"
        "./lib/runtime.sh"
        "./lib/telegram.sh"
        "./lib/apt_updates.sh"
        "./locales/de.sh"
        "./locales/en.sh"
        "./locales/es.sh"
        "./locales/fr.sh"
        "./locales/it.sh"
        "./locales/pt_BR.sh"
        "./systemd/aptgram.service.in"
        "./systemd/aptgram.timer.in"
    )

    archive_entries="$(
        tar -tzf "${ARCHIVE_FILE}"
    )"

    for required_file in "${required_files[@]}"; do
        if ! grep \
            -Fxq \
            "${required_file}" \
            <<<"${archive_entries}"
        then
            printf 'Fehlende Release-Datei: %s\n' \
                "${required_file}"

            return 1
        fi
    done
}

show_release_report() {
    local test_result

    echo
    echo "========================================"
    echo "APTGRAM Release Build"
    echo "========================================"
    echo
    printf 'Version %s erstellt.\n' "${RELEASE_VERSION}"
    echo

    for test_result in "${TEST_RESULTS[@]}"; do
        printf '%s\n' "${test_result}"
    done

    echo
    printf 'Release-Verzeichnis: %s\n' "${RELEASE_DIST_DIR}"
    printf 'Archive: %s\n' "${ARCHIVE_FILE}"
    printf 'Checksum: %s\n' "${CHECKSUM_FILE}"
    printf 'Version asset: %s\n' "${RELEASE_VERSION_FILE}"
}

main() {
    WORK_DIR="$(mktemp -d)"
    TEST_LOG="${WORK_DIR}/test.log"

    trap cleanup EXIT

    run_test \
        "Git-Arbeitsbaum prüfen" \
        check_git_clean

    run_test \
        "Sprachdateien prüfen" \
        check_language_files

    run_test \
        "Bash-Syntax prüfen" \
        check_bash_syntax

    run_test \
        "Release bauen" \
        build_release

    run_test \
        "Prüfsumme prüfen" \
        verify_checksum

    run_test \
        "Versionen prüfen" \
        verify_versions

    run_test \
        "Release-Inhalt prüfen" \
        verify_release_contents

    show_release_report
}

main "$@"
