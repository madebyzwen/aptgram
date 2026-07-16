#!/usr/bin/env bash

install_program_files() {
    local source_dir="$1"
    local install_bin_dir="$2"
    local install_lib_dir="$3"
    local install_locales_dir="$4"
    local install_state_dir="$5"

    sudo install -d \
        -o root \
        -g root \
        -m 0755 \
        "${install_lib_dir}" \
        "${install_locales_dir}" \
        "${install_state_dir}"

    sudo install \
        -o root \
        -g root \
        -m 0755 \
        "${source_dir}/aptgram" \
        "${install_bin_dir}/aptgram"

    sudo install \
        -o root \
        -g root \
        -m 0755 \
        "${source_dir}/aptgram-config" \
        "${install_bin_dir}/aptgram-config"

    sudo install \
        -o root \
        -g root \
        -m 0755 \
        "${source_dir}/uninstall.sh" \
        "${install_bin_dir}/aptgram-uninstall"

    sudo install \
        -o root \
        -g root \
        -m 0755 \
        "${source_dir}/update.sh" \
        "${install_bin_dir}/aptgram-update"

    sudo install \
        -o root \
        -g root \
        -m 0644 \
        "${source_dir}/lib/"*.sh \
        "${install_lib_dir}/"

    sudo install \
        -o root \
        -g root \
        -m 0644 \
        "${source_dir}/locales/"*.sh \
        "${install_locales_dir}/"
}

install_version_file() {
    local source_dir="$1"
    local install_lib_dir="$2"

    sudo install \
        -o root \
        -g root \
        -m 0644 \
        "${source_dir}/VERSION" \
        "${install_lib_dir}/VERSION"
}

detect_credential_mode() {
    local credential_dir="$1"
    local encrypted_file="${credential_dir}/telegram-bot-token.cred"
    local plain_file="${credential_dir}/telegram-bot-token"

    if sudo test -f "${encrypted_file}" &&
        ! sudo test -f "${plain_file}"
    then
        printf 'encrypted\n'
        return 0
    fi

    if sudo test -f "${plain_file}" &&
        ! sudo test -f "${encrypted_file}"
    then
        printf 'plain\n'
        return 0
    fi

    return 1
}

install_systemd_units() {
    local systemd_source_dir="$1"
    local systemd_unit_dir="$2"
    local check_time="$3"
    local credential_mode="$4"

    local credential_directive
    local service_content
    local timer_content

    case "${credential_mode}" in
        encrypted)
            credential_directive="LoadCredentialEncrypted=telegram-bot-token:/etc/aptgram/credentials/telegram-bot-token.cred"
            ;;
        plain)
            credential_directive="LoadCredential=telegram-bot-token:/etc/aptgram/credentials/telegram-bot-token"
            ;;
        *)
            return 1
            ;;
    esac

    service_content="$(
        sed \
            "s|@CREDENTIAL_DIRECTIVE@|${credential_directive}|" \
            "${systemd_source_dir}/aptgram.service.in"
    )"

    timer_content="$(
        sed \
            "s|@CHECK_TIME@|${check_time}|" \
            "${systemd_source_dir}/aptgram.timer.in"
    )"

    printf '%s\n' "${service_content}" |
        sudo tee "${systemd_unit_dir}/aptgram.service" >/dev/null

    printf '%s\n' "${timer_content}" |
        sudo tee "${systemd_unit_dir}/aptgram.timer" >/dev/null

    sudo chown \
        root:root \
        "${systemd_unit_dir}/aptgram.service" \
        "${systemd_unit_dir}/aptgram.timer"

    sudo chmod \
        0644 \
        "${systemd_unit_dir}/aptgram.service" \
        "${systemd_unit_dir}/aptgram.timer"
}
