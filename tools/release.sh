#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
CHECK_SCRIPT="${SCRIPT_DIR}/check-release.sh"

check_git_clean() {
    local git_status

    git --no-pager -C "${ROOT_DIR}" diff --check
    git --no-pager -C "${ROOT_DIR}" diff --cached --check

    git_status="$(
        git -C "${ROOT_DIR}" status --porcelain --untracked-files=all
    )"

    if [[ -n "${git_status}" ]]; then
        printf '%s\n' "${git_status}" >&2
        printf 'Release refused: the Git worktree is not clean.\n' >&2
        return 1
    fi
}

main() {
    check_git_clean
    exec "${CHECK_SCRIPT}" "$@"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
