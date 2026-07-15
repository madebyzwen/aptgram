#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
LOCALES_DIR="${PROJECT_DIR}/locales"
CHECK_SCRIPT="${SCRIPT_DIR}/check-language-variables.sh"
BACKUP_DIR="/tmp/aptgram-locales-backup-$(date '+%Y%m%d-%H%M%S')"

if [[ ! -d "${LOCALES_DIR}" ]]; then
    echo "Fehler: Sprachverzeichnis nicht gefunden: ${LOCALES_DIR}" >&2
    exit 1
fi

if [[ ! -x "${CHECK_SCRIPT}" ]]; then
    echo "Fehler: Prüfscript nicht gefunden oder nicht ausführbar: ${CHECK_SCRIPT}" >&2
    exit 1
fi

"${CHECK_SCRIPT}"

cp -a "${LOCALES_DIR}" "${BACKUP_DIR}"

echo "Backup erstellt: ${BACKUP_DIR}"

PROJECT_DIR="${PROJECT_DIR}" python3 <<'PY'

from pathlib import Path
import os
import re
import sys

PROJECT_DIR = Path(os.environ["PROJECT_DIR"])
LOCALES_DIR = PROJECT_DIR / "locales"
REFERENCE_FILE = LOCALES_DIR / "de.sh"

ASSIGNMENT_RE = re.compile(r"^([A-Z][A-Z0-9_]*)=")


def count_unescaped_double_quotes(text: str) -> int:
    count = 0
    escaped = False

    for character in text:
        if escaped:
            escaped = False
            continue

        if character == "\\":
            escaped = True
        elif character == '"':
            count += 1

    return count


def parse_locale(path: Path) -> dict[str, str]:
    content = path.read_text(encoding="utf-8-sig")
    content = content.replace("\r\n", "\n").replace("\r", "\n")
    lines = content.splitlines()

    assignments: dict[str, str] = {}
    line_index = 0

    while line_index < len(lines):
        line = lines[line_index]

        if not line.strip() or line.lstrip().startswith("#"):
            line_index += 1
            continue

        match = ASSIGNMENT_RE.match(line)

        if match is None:
            raise ValueError(
                f"{path}:{line_index + 1}: "
                f"Unerwarteter Inhalt: {line!r}"
            )

        variable_name = match.group(1)
        block = [line]
        quote_count = count_unescaped_double_quotes(line)

        while quote_count % 2 != 0:
            line_index += 1

            if line_index >= len(lines):
                raise ValueError(
                    f"{path}: Nicht abgeschlossener Text bei "
                    f"{variable_name}"
                )

            block.append(lines[line_index])
            quote_count += count_unescaped_double_quotes(
                lines[line_index]
            )

        if variable_name in assignments:
            raise ValueError(
                f"{path}: Variable doppelt vorhanden: {variable_name}"
            )

        assignments[variable_name] = "\n".join(block)
        line_index += 1

    return assignments


def variable_group(variable_name: str) -> tuple[int, str]:
    if variable_name.startswith("LANGUAGE_"):
        return 0, variable_name

    if variable_name.startswith("TXT_"):
        return 1, variable_name

    if variable_name.startswith("MSG_"):
        return 2, variable_name

    if variable_name.startswith("REPORT_"):
        return 3, variable_name

    return 4, variable_name


section_titles = {
    0: "Language",
    1: "Interface texts",
    2: "Telegram messages",
    3: "Update report",
    4: "Other",
}

locale_files = sorted(LOCALES_DIR.glob("*.sh"))

if not locale_files:
    print(
        f"Keine Sprachdateien gefunden: {LOCALES_DIR}",
        file=sys.stderr,
    )
    sys.exit(1)

if REFERENCE_FILE not in locale_files:
    print(f"Referenzdatei fehlt: {REFERENCE_FILE}", file=sys.stderr)
    sys.exit(1)

try:
    parsed_files = {
        locale_file: parse_locale(locale_file)
        for locale_file in locale_files
    }
except (OSError, UnicodeError, ValueError) as error:
    print(f"Fehler beim Einlesen: {error}", file=sys.stderr)
    sys.exit(1)

ordered_variables = sorted(
    parsed_files[REFERENCE_FILE],
    key=variable_group,
)

for locale_file, assignments in parsed_files.items():
    output_lines: list[str] = []
    current_group: int | None = None

    for variable_name in ordered_variables:
        group_number, _ = variable_group(variable_name)

        if group_number != current_group:
            if output_lines:
                output_lines.append("")

            output_lines.append(
                f"# {section_titles[group_number]}"
            )
            current_group = group_number

        output_lines.append(assignments[variable_name])

    locale_file.write_text(
        "\n".join(output_lines) + "\n",
        encoding="utf-8",
        newline="\n",
    )

    print(f"Sortiert: {locale_file.relative_to(PROJECT_DIR)}")

print("Alle Sprachdateien wurden erfolgreich sortiert.")
PY
