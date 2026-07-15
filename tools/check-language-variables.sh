#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
LOCALES_DIR="${PROJECT_DIR}/locales"

if [[ ! -d "${LOCALES_DIR}" ]]; then
    echo "Fehler: Sprachverzeichnis nicht gefunden: ${LOCALES_DIR}" >&2
    exit 2
fi

PROJECT_DIR="${PROJECT_DIR}" python3 <<'PY'
from pathlib import Path
import os
import re
import sys

PROJECT_DIR = Path(os.environ["PROJECT_DIR"])
LOCALES_DIR = PROJECT_DIR / "locales"

ASSIGNMENT_RE = re.compile(r"^([A-Z][A-Z0-9_]*)=")


def read_variable_names(path: Path) -> set[str]:
    content = path.read_text(encoding="utf-8-sig")
    content = content.replace("\r\n", "\n").replace("\r", "\n")

    variables: set[str] = set()
    duplicates: list[str] = []

    for line_number, line in enumerate(content.splitlines(), start=1):
        match = ASSIGNMENT_RE.match(line)

        if match is None:
            continue

        variable_name = match.group(1)

        if variable_name in variables:
            duplicates.append(f"{variable_name} (Zeile {line_number})")
        else:
            variables.add(variable_name)

    if duplicates:
        raise ValueError(
            f"{path.relative_to(PROJECT_DIR)}: "
            f"Doppelte Variablen: {', '.join(duplicates)}"
        )

    return variables


locale_files = sorted(LOCALES_DIR.glob("*.sh"))

if not locale_files:
    print(
        f"Fehler: Keine Sprachdateien in {LOCALES_DIR} gefunden.",
        file=sys.stderr,
    )
    sys.exit(2)

try:
    variables_by_file = {
        locale_file: read_variable_names(locale_file)
        for locale_file in locale_files
    }
except (OSError, UnicodeError, ValueError) as error:
    print(f"Fehler: {error}", file=sys.stderr)
    sys.exit(2)

all_variables: set[str] = set().union(*variables_by_file.values())

files_with_missing_variables = 0

print(
    f"Geprüft: {len(locale_files)} Sprachdatei(en), "
    f"{len(all_variables)} unterschiedliche Variablen.\n"
)

for locale_file, variables in variables_by_file.items():
    missing = sorted(all_variables - variables)
    relative_path = locale_file.relative_to(PROJECT_DIR)

    if missing:
        files_with_missing_variables += 1
        print(f"{relative_path}:")
        for variable_name in missing:
            print(f"  - {variable_name}")
        print()
    else:
        print(f"{relative_path}: vollständig")

if files_with_missing_variables:
    print(
        f"\nErgebnis: In {files_with_missing_variables} "
        "Sprachdatei(en) fehlen Variablen.",
        file=sys.stderr,
    )
    sys.exit(1)

print("\nErgebnis: Alle Sprachdateien enthalten dieselben Variablennamen.")
PY
