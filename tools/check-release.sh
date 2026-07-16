#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
BUILD_SCRIPT="${SCRIPT_DIR}/build-release.sh"
VERSION_FILE="${ROOT_DIR}/VERSION"
CHANGELOG_FILE="${ROOT_DIR}/CHANGELOG.md"

EXPECTED_TAG=""
RELEASE_VERSION=""
WORK_DIR=""

usage() {
    printf 'Usage: tools/check-release.sh [--tag vX.Y.Z]\n'
}

parse_arguments() {
    while (($# > 0)); do
        case "$1" in
            --tag)
                if (($# < 2)); then
                    usage >&2
                    return 2
                fi

                EXPECTED_TAG="$2"
                shift 2
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                usage >&2
                return 2
                ;;
        esac
    done
}

cleanup() {
    if [[ -n "${WORK_DIR}" && -d "${WORK_DIR}" ]]; then
        rm -rf -- "${WORK_DIR}"
    fi
}

run_check() {
    local description="$1"

    shift
    printf '%s ... ' "${description}"

    if "$@"; then
        printf 'OK\n'
        return 0
    fi

    printf 'FEHLER\n' >&2
    return 1
}

load_and_validate_version() {
    if [[ ! -r "${VERSION_FILE}" ]]; then
        printf 'VERSION file is missing.\n' >&2
        return 1
    fi

    IFS= read -r RELEASE_VERSION <"${VERSION_FILE}" || true

    if [[ ! "${RELEASE_VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
        ! dpkg --validate-version "${RELEASE_VERSION}" >/dev/null 2>&1
    then
        printf 'Invalid release version: %s\n' \
            "${RELEASE_VERSION:-<empty>}" \
            >&2
        return 1
    fi

    if [[ -z "${EXPECTED_TAG}" ]]; then
        EXPECTED_TAG="v${RELEASE_VERSION}"
    fi
}

check_tag_and_version() {
    if [[ ! "${EXPECTED_TAG}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        printf 'Invalid release tag: %s\n' "${EXPECTED_TAG}" >&2
        return 1
    fi

    if [[ "${EXPECTED_TAG}" != "v${RELEASE_VERSION}" ]]; then
        printf 'Tag %s does not match VERSION %s.\n' \
            "${EXPECTED_TAG}" \
            "${RELEASE_VERSION}" \
            >&2
        return 1
    fi

    if git -C "${ROOT_DIR}" rev-parse --verify --quiet \
        "refs/tags/${EXPECTED_TAG}^{commit}" >/dev/null
    then
        [[ "$(git -C "${ROOT_DIR}" rev-parse "${EXPECTED_TAG}^{commit}")" == \
            "$(git -C "${ROOT_DIR}" rev-parse HEAD)" ]]
    elif [[ "${GITHUB_REF_TYPE:-}" == "tag" || \
        "${GITHUB_ACTIONS:-}" == "true" ]]
    then
        printf 'Expected tag is unavailable: %s\n' "${EXPECTED_TAG}" >&2
        return 1
    fi
}

check_diff_whitespace() {
    git --no-pager -C "${ROOT_DIR}" diff --check
    git --no-pager -C "${ROOT_DIR}" diff --cached --check
}

check_bash_syntax() {
    bash -n \
        "${ROOT_DIR}/aptgram" \
        "${ROOT_DIR}/aptgram-config" \
        "${ROOT_DIR}/install.sh" \
        "${ROOT_DIR}/uninstall.sh" \
        "${ROOT_DIR}/update.sh" \
        "${ROOT_DIR}"/lib/*.sh \
        "${ROOT_DIR}"/locales/*.sh \
        "${ROOT_DIR}"/tools/*.sh
}

check_locales() {
    "${ROOT_DIR}/tools/check-language-variables.sh" >/dev/null
}

check_behavior() {
    "${ROOT_DIR}/tools/test-aptgram-config.sh" >/dev/null
    "${ROOT_DIR}/tools/test-update-compatibility.sh" >/dev/null
}

check_changelog() {
    [[ -r "${CHANGELOG_FILE}" ]]
    grep -Fxq '## [Unreleased]' "${CHANGELOG_FILE}"
    grep -Eq \
        "^## \[${RELEASE_VERSION//./\\.}\] - [0-9]{4}-[0-9]{2}-[0-9]{2}$" \
        "${CHANGELOG_FILE}"
}

check_documentation() {
    local documentation_file
    local -a documentation_files=(
        "${ROOT_DIR}/README.md"
        "${ROOT_DIR}/docs/INSTALLATION_DE.md"
        "${ROOT_DIR}/docs/INSTALLATION_EN.md"
        "${ROOT_DIR}/docs/INSTALLATION_ES.md"
        "${ROOT_DIR}/docs/INSTALLATION_FR.md"
        "${ROOT_DIR}/docs/INSTALLATION_IT.md"
        "${ROOT_DIR}/docs/INSTALLATION_PT_BR.md"
    )

    for documentation_file in "${documentation_files[@]}"; do
        grep -Fq 'sudo aptgram-config' "${documentation_file}"
        grep -Fq 'sudo aptgram send-test-heartbeat' "${documentation_file}"
        grep -Fq 'sudo aptgram-update' "${documentation_file}"
    done
}

remove_current_release_assets() {
    rm -f -- \
        "${ROOT_DIR}/dist/aptgram-v${RELEASE_VERSION}.tar.gz" \
        "${ROOT_DIR}/dist/aptgram-v${RELEASE_VERSION}.tar.gz.sha256" \
        "${ROOT_DIR}/dist/aptgram.tar.gz" \
        "${ROOT_DIR}/dist/aptgram.tar.gz.sha256" \
        "${ROOT_DIR}/dist/aptgram.version"
}

build_release() {
    "${BUILD_SCRIPT}" >/dev/null
}

verify_checksum() {
    (
        cd "${ROOT_DIR}/dist"
        sha256sum -c "aptgram-v${RELEASE_VERSION}.tar.gz.sha256" >/dev/null
        sha256sum -c aptgram.tar.gz.sha256 >/dev/null
    )

    cmp -s \
        "${ROOT_DIR}/dist/aptgram-v${RELEASE_VERSION}.tar.gz" \
        "${ROOT_DIR}/dist/aptgram.tar.gz"

    [[ "$(<"${ROOT_DIR}/dist/aptgram.version")" == "${RELEASE_VERSION}" ]]
}

verify_archive_contents() {
    local actual_manifest="${WORK_DIR}/actual-files.txt"
    local expected_manifest="${WORK_DIR}/expected-files.txt"

    "${BUILD_SCRIPT}" --print-files | sort >"${expected_manifest}"

    tar -tzf "${ROOT_DIR}/dist/aptgram-v${RELEASE_VERSION}.tar.gz" |
        sed -e 's#^\./##' -e '/^$/d' -e '/\/$/d' |
        sort >"${actual_manifest}"

    diff -u "${expected_manifest}" "${actual_manifest}"
}

verify_archive_version() {
    local archive_version

    archive_version="$(
        tar -xOf \
            "${ROOT_DIR}/dist/aptgram-v${RELEASE_VERSION}.tar.gz" \
            ./VERSION
    )"

    [[ "${archive_version}" == "${RELEASE_VERSION}" ]]
    [[ "$(<"${ROOT_DIR}/dist/aptgram.version")" == "${RELEASE_VERSION}" ]]
}

verify_archive_secrets() {
    local archive="${ROOT_DIR}/dist/aptgram-v${RELEASE_VERSION}.tar.gz"
    local extract_dir="${WORK_DIR}/archive"
    local raw_matches="${WORK_DIR}/secret-matches.raw"
    local filtered_matches="${WORK_DIR}/secret-matches.filtered"

    mkdir -p "${extract_dir}"
    tar -xzf "${archive}" -C "${extract_dir}"

    if find "${extract_dir}" -type f \
        \( -name '.env' -o -name '.env.*' -o -name '*.key' -o \
        -name '*.pem' -o -name '*.p12' -o -name '*.pfx' -o \
        -name 'AGENTS.md' -o -path '*/tools/*' -o -path '*/.git/*' -o \
        -path '*/.github/*' -o -path '*/.vscode/*' \) |
        grep -q .
    then
        printf 'Forbidden file found in release archive.\n' >&2
        return 1
    fi

    grep -RInE \
        --exclude='*.png' \
        -- '-----BEGIN (RSA |EC |OPENSSH |DSA |PGP )?PRIVATE KEY-----|[0-9]{8,12}:[A-Za-z0-9_-]{30,}|gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,}|AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{30,}|xox[baprs]-[A-Za-z0-9-]{10,}|sk-[A-Za-z0-9_-]{20,}' \
        "${extract_dir}" \
        >"${raw_matches}" || true

    grep -Fv '1234567890:AAExampleTokenDoNotUseThisValue' \
        "${raw_matches}" \
        >"${filtered_matches}" || true

    if [[ -s "${filtered_matches}" ]]; then
        printf 'Possible secret found in release archive:\n' >&2
        cut -d: -f1 "${filtered_matches}" | sort -u >&2
        return 1
    fi
}

verify_reproducible_build() {
    local first_archive="${WORK_DIR}/first.tar.gz"
    local first_checksum="${WORK_DIR}/first.sha256"

    cp -p \
        "${ROOT_DIR}/dist/aptgram-v${RELEASE_VERSION}.tar.gz" \
        "${first_archive}"
    sha256sum "${first_archive}" | awk '{print $1}' >"${first_checksum}"

    printf 'Rebuilding release assets for reproducibility ...\n'
    remove_current_release_assets
    build_release

    [[ "$(<"${first_checksum}")" == "$(
        sha256sum "${ROOT_DIR}/dist/aptgram-v${RELEASE_VERSION}.tar.gz" |
            awk '{print $1}'
    )" ]]
}

main() {
    parse_arguments "$@"
    load_and_validate_version

    WORK_DIR="$(mktemp -d /tmp/aptgram-release-check.XXXXXX)"
    trap cleanup EXIT

    run_check "Tag und VERSION prüfen" check_tag_and_version
    run_check "Git-Diff auf Whitespace prüfen" check_diff_whitespace
    run_check "Bash-Syntax prüfen" check_bash_syntax
    run_check "Locale-Variablen prüfen" check_locales
    run_check "Verhaltenstests ausführen" check_behavior
    run_check "Changelog prüfen" check_changelog
    run_check "Benutzerdokumentation prüfen" check_documentation

    remove_current_release_assets
    run_check "Release-Paket bauen" build_release
    run_check "Prüfsummen und Kompatibilitäts-Assets prüfen" verify_checksum
    run_check "Archiv-Allowlist prüfen" verify_archive_contents
    run_check "Version im Archiv prüfen" verify_archive_version
    run_check "Archiv auf Secrets und Entwicklerdateien prüfen" verify_archive_secrets
    run_check "Reproduzierbaren Build prüfen" verify_reproducible_build
    run_check "Finale Prüfsummen prüfen" verify_checksum
    run_check "Finalen Archivinhalt prüfen" verify_archive_contents
    run_check "Finale Archivversion prüfen" verify_archive_version

    printf '\nAPTGRAM v%s ist technisch für den Release vorbereitet.\n' \
        "${RELEASE_VERSION}"
    printf 'Archiv: dist/aptgram-v%s.tar.gz\n' "${RELEASE_VERSION}"
    printf 'Prüfsumme: dist/aptgram-v%s.tar.gz.sha256\n' \
        "${RELEASE_VERSION}"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
