#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
TEST_ROOT="$(mktemp -d /tmp/aptgram-update-compatibility.XXXXXX)"

cleanup() {
    rm -rf -- "${TEST_ROOT}"
}

fail() {
    printf 'FEHLER: %s\n' "$1" >&2
    exit 1
}

trap cleanup EXIT

mkdir -p \
    "${TEST_ROOT}/bin" \
    "${TEST_ROOT}/lib" \
    "${TEST_ROOT}/locales" \
    "${TEST_ROOT}/state"

# Load the deployment implementation that is already installed on v1.0.0
# systems. It deliberately does not know the aptgram-config executable.
# shellcheck source=/dev/null
source <(git -C "${PROJECT_DIR}" show v1.0.0:lib/deployment.sh)

install() {
    local argument
    local skip_next=false
    local -a arguments=()

    for argument in "$@"; do
        if [[ "${skip_next}" == true ]]; then
            skip_next=false
            continue
        fi

        case "${argument}" in
            -o|-g)
                skip_next=true
                ;;
            *)
                arguments+=("${argument}")
                ;;
        esac
    done

    command install "${arguments[@]}"
}

sudo() {
    "$@"
}

install_program_files \
    "${PROJECT_DIR}" \
    "${TEST_ROOT}/bin" \
    "${TEST_ROOT}/lib" \
    "${TEST_ROOT}/locales" \
    "${TEST_ROOT}/state"

[[ ! -e "${TEST_ROOT}/bin/aptgram-config" ]] ||
    fail "Der v1.0.0-Updater hat unerwartet aptgram-config installiert."

[[ -f "${TEST_ROOT}/lib/config_command.sh" ]] ||
    fail "Die Kompatibilitätsimplementierung wurde nicht übernommen."

# The new updater performs the one-time migration before validating the
# installation. Sourcing is safe because update.sh only runs main directly.
# shellcheck source=/dev/null
source "${PROJECT_DIR}/update.sh"

install_missing_config_command \
    "${TEST_ROOT}/bin" \
    "${TEST_ROOT}/lib"

[[ -x "${TEST_ROOT}/bin/aptgram-config" ]] ||
    fail "Der zweite Updater-Aufruf hat aptgram-config nicht installiert."

bash -n "${TEST_ROOT}/bin/aptgram-config"

first_checksum="$(sha256sum "${TEST_ROOT}/bin/aptgram-config")"

install_missing_config_command \
    "${TEST_ROOT}/bin" \
    "${TEST_ROOT}/lib"

second_checksum="$(sha256sum "${TEST_ROOT}/bin/aptgram-config")"

[[ "${first_checksum}" == "${second_checksum}" ]] ||
    fail "Die wiederholte Migration war nicht idempotent."

printf 'APTGRAM v1.0.0-Update-Kompatibilität erfolgreich geprüft.\n'
