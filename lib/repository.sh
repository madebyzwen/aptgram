is_official_origin() {
    local origin="$1"

    case "${DISTRO_ID}" in
        ubuntu)
            [[ "${origin}" == Ubuntu* ]]
            ;;
        debian)
            [[ "${origin}" == Debian* ]]
            ;;
        *)
            return 1
            ;;
    esac
}

build_repository_index() {
    local repository_index_file="${WORK_DIR}/repositories.tsv"
    local repository
    local pocket
    local origin
    local archive
    local key

    LC_ALL=C apt-cache policy |
        awk '
            $1 ~ /^[0-9]+$/ && $NF == "Packages" {
                repository = $2
                pocket = $3
                next
            }

            repository != "" && /^[[:space:]]*release / {
                release_line = $0
                sub(/^[[:space:]]*release[[:space:]]+/, "", release_line)

                origin = ""
                archive = ""

                field_count = split(release_line, fields, ",")

                for (i = 1; i <= field_count; i++) {
                    field = fields[i]
                    gsub(/^[[:space:]]+|[[:space:]]+$/, "", field)

                    if (field ~ /^o=/) {
                        origin = substr(field, 3)
                    } else if (field ~ /^a=/) {
                        archive = substr(field, 3)
                    }
                }

                print repository "|" pocket "|" origin "|" archive

                repository = ""
                pocket = ""
            }
        ' >"${repository_index_file}"

    while IFS='|' read -r repository pocket origin archive; do
        [[ -z "${repository}" ]] && continue

        key="${repository}|${pocket}"
        REPOSITORY_ORIGIN["${key}"]="${origin}"
        REPOSITORY_ARCHIVE["${key}"]="${archive}"
    done <"${repository_index_file}"
}

list_package_sources() {
    local package_policy="$1"

    awk '
        $1 == "***" {
            version = $2
            next
        }

        NF == 2 && $2 ~ /^[0-9]+$/ {
            version = $1
            next
        }

        $1 ~ /^[0-9]+$/ && $NF == "Packages" {
            print version "|" $2 "|" $3
        }
    ' <<<"${package_policy}"
}
