#!/usr/bin/env python3

from __future__ import annotations

from datetime import datetime
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile


LOCALES_DIR = Path("locales")
REFERENCE_FILE = LOCALES_DIR / "de.sh"

LANGUAGES = {
    "de": "Deutsch",
    "en": "Englisch",
    "es": "Spanisch",
    "fr": "Französisch",
    "pt_BR": "Portugiesisch (Brasilien)",
    "it": "Italienisch",
}

VARIABLE_PATTERN = re.compile(r"^(LANGUAGE|TXT|MSG|REPORT)_[A-Z0-9_]+$")

ASSIGNMENT_PATTERN = re.compile(r"^([A-Z][A-Z0-9_]*)=")

SECTION_TITLES = {
    0: "Language",
    1: "Installer",
    2: "Telegram messages",
    3: "Update report",
    4: "Other",
}


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

        match = ASSIGNMENT_PATTERN.match(line)

        if match is None:
            raise ValueError(f"{path}:{line_index + 1}: Unerwarteter Inhalt: {line!r}")

        variable_name = match.group(1)
        block = [line]
        quote_count = count_unescaped_double_quotes(line)

        while quote_count % 2 != 0:
            line_index += 1

            if line_index >= len(lines):
                raise ValueError(
                    f"{path}: Nicht abgeschlossener Wert bei {variable_name}"
                )

            block.append(lines[line_index])
            quote_count += count_unescaped_double_quotes(lines[line_index])

        if variable_name in assignments:
            raise ValueError(f"{path}: Variable doppelt vorhanden: {variable_name}")

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


def escape_bash_double_quoted_value(value: str) -> str:
    return (
        value.replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace("$", "\\$")
        .replace("`", "\\`")
    )


def create_assignment(
    variable_name: str,
    value: str,
) -> str:
    escaped_value = escape_bash_double_quoted_value(value)

    return f'{variable_name}="{escaped_value}"'


def read_translation(
    language_code: str,
    language_name: str,
) -> str:
    print()
    print(f"=== {language_name} ({language_code}) ===")
    print()
    print("Text eingeben oder einfügen.")
    print("Leerzeilen sind erlaubt.")
    print("Mit einer einzelnen Zeile '.end' abschließen.")
    print()

    lines: list[str] = []

    while True:
        try:
            line = input()
        except EOFError as error:
            raise ValueError(
                f"Die Eingabe für {language_name} wurde unerwartet beendet."
            ) from error

        if line == ".end":
            break

        lines.append(line)

    value = "\n".join(lines)

    if not value.strip():
        raise ValueError(f"Für {language_name} wurde kein Wert eingegeben.")

    return value


def validate_locale_sets(
    parsed_files: dict[Path, dict[str, str]],
) -> None:
    reference_variables = set(parsed_files[REFERENCE_FILE])

    validation_failed = False

    for locale_file, assignments in parsed_files.items():
        variables = set(assignments)

        missing = sorted(reference_variables - variables)
        extra = sorted(variables - reference_variables)

        if missing:
            validation_failed = True
            print(
                f"{locale_file}: Fehlende Variablen:",
                file=sys.stderr,
            )

            for variable_name in missing:
                print(
                    f"  - {variable_name}",
                    file=sys.stderr,
                )

        if extra:
            validation_failed = True
            print(
                f"{locale_file}: Zusätzliche Variablen:",
                file=sys.stderr,
            )

            for variable_name in extra:
                print(
                    f"  - {variable_name}",
                    file=sys.stderr,
                )

    if validation_failed:
        raise ValueError("Die Locale-Dateien sind nicht einheitlich.")


def render_locale(
    assignments: dict[str, str],
) -> str:
    ordered_variables = sorted(
        assignments,
        key=variable_group,
    )

    output_lines: list[str] = []
    current_group: int | None = None

    for variable_name in ordered_variables:
        group_number, _ = variable_group(variable_name)

        if group_number != current_group:
            if output_lines:
                output_lines.append("")

            output_lines.append(f"# {SECTION_TITLES[group_number]}")

            current_group = group_number

        output_lines.append(assignments[variable_name])

    return "\n".join(output_lines) + "\n"


def validate_bash_syntax(locale_files: list[Path]) -> None:
    for locale_file in locale_files:
        result = subprocess.run(
            ["bash", "-n", str(locale_file)],
            check=False,
            capture_output=True,
            text=True,
        )

        if result.returncode != 0:
            raise ValueError(f"Bash-Syntaxfehler in {locale_file}:\n{result.stderr}")


def main() -> int:
    locale_files = [LOCALES_DIR / f"{language_code}.sh" for language_code in LANGUAGES]

    missing_files = [path for path in locale_files if not path.is_file()]

    if missing_files:
        print(
            "Fehlende Locale-Dateien:",
            file=sys.stderr,
        )

        for missing_file in missing_files:
            print(
                f"  - {missing_file}",
                file=sys.stderr,
            )

        return 1

    parsed_files = {
        locale_file: parse_locale(locale_file) for locale_file in locale_files
    }

    validate_locale_sets(parsed_files)

    print("APTGRAM Locale-Variable hinzufügen")
    print("==================================")
    print()

    variable_name = input("Variablenname: ").strip()

    if not VARIABLE_PATTERN.fullmatch(variable_name):
        print(
            "Ungültiger Variablenname.",
            file=sys.stderr,
        )
        print(
            "Erlaubt sind LANGUAGE_, TXT_, MSG_ oder "
            "REPORT_ mit Großbuchstaben, Zahlen und "
            "Unterstrichen.",
            file=sys.stderr,
        )
        return 1

    existing_files = [
        locale_file
        for locale_file, assignments in parsed_files.items()
        if variable_name in assignments
    ]

    if existing_files:
        print(
            f"Variable bereits vorhanden: {variable_name}",
            file=sys.stderr,
        )

        for existing_file in existing_files:
            print(
                f"  - {existing_file}",
                file=sys.stderr,
            )

        return 1

    translations: dict[str, str] = {}

    for language_code, language_name in LANGUAGES.items():
        translations[language_code] = read_translation(
            language_code,
            language_name,
        )

    print()
    print("Zusammenfassung")
    print("===============")
    print(f"Variable: {variable_name}")

    for language_code, language_name in LANGUAGES.items():
        value = translations[language_code]
        preview = value.replace("\n", " / ")

        if len(preview) > 80:
            preview = preview[:77] + "..."

        print(f"{language_name:26} {preview}")

    print()

    confirmation = (
        input("Variable zu allen Locale-Dateien hinzufügen? [j/N] ").strip().lower()
    )

    if confirmation not in {"j", "ja", "y", "yes"}:
        print("Abgebrochen. Keine Dateien verändert.")
        return 0

    backup_directory = Path(tempfile.mkdtemp(prefix="aptgram-locales-backup-"))

    for locale_file in locale_files:
        shutil.copy2(
            locale_file,
            backup_directory / locale_file.name,
        )

    try:
        for language_code, locale_file in zip(
            LANGUAGES,
            locale_files,
            strict=True,
        ):
            assignments = parsed_files[locale_file]

            assignments[variable_name] = create_assignment(
                variable_name,
                translations[language_code],
            )

            locale_file.write_text(
                render_locale(assignments),
                encoding="utf-8",
                newline="\n",
            )

        validate_bash_syntax(locale_files)

        reparsed_files = {
            locale_file: parse_locale(locale_file) for locale_file in locale_files
        }

        validate_locale_sets(reparsed_files)

        reference_order = list(reparsed_files[REFERENCE_FILE])

        for locale_file, assignments in reparsed_files.items():
            if list(assignments) != reference_order:
                raise ValueError(f"Variablenreihenfolge weicht ab: {locale_file}")

    except Exception:
        for locale_file in locale_files:
            shutil.copy2(
                backup_directory / locale_file.name,
                locale_file,
            )

        print(
            "Fehler: Änderungen wurden zurückgesetzt.",
            file=sys.stderr,
        )
        raise

    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    print()
    print(f"OK: {variable_name} wurde in allen Locale-Dateien ergänzt.")
    print(f"Zeitpunkt: {timestamp}")
    print(f"Backup: {backup_directory}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
