#!/usr/bin/env bash

create_update_backup() {
    local backup_dir="$1"
    local install_bin_dir="$2"
    local install_lib_dir="$3"
    local systemd_unit_dir="$4"

    install -d \
        -m 0700 \
        "${backup_dir}" \
        "${backup_dir}/bin" \
        "${backup_dir}/systemd"

    sudo cp -a \
        "${install_bin_dir}/aptgram" \
        "${install_bin_dir}/aptgram-uninstall" \
        "${backup_dir}/bin/"

    if [[ -f "${install_bin_dir}/aptgram-update" ]]; then
        sudo cp -a \
            "${install_bin_dir}/aptgram-update" \
            "${backup_dir}/bin/"
    fi

    if [[ -f "${install_bin_dir}/aptgram-config" ]]; then
        sudo cp -a \
            "${install_bin_dir}/aptgram-config" \
            "${backup_dir}/bin/"
    fi

    sudo cp -a \
        "${install_lib_dir}" \
        "${backup_dir}/aptgram-lib"

    sudo cp -a \
        "${systemd_unit_dir}/aptgram.service" \
        "${systemd_unit_dir}/aptgram.timer" \
        "${backup_dir}/systemd/"
}

restore_timer_state() {
    local timer_was_enabled="$1"
    local timer_was_active="$2"

    if [[ "${timer_was_enabled}" == true ]]; then
        sudo systemctl enable aptgram.timer >/dev/null
    else
        sudo systemctl disable aptgram.timer >/dev/null 2>&1 ||
            true
    fi

    if [[ "${timer_was_active}" == true ]]; then
        sudo systemctl start aptgram.timer
    else
        sudo systemctl stop aptgram.timer >/dev/null 2>&1 ||
            true
    fi
}

restore_update_backup() (
    set -Eeuo pipefail

    local backup_dir="$1"
    local install_bin_dir="$2"
    local install_lib_dir="$3"
    local systemd_unit_dir="$4"
    local timer_was_enabled="$5"
    local timer_was_active="$6"

    sudo systemctl stop \
        aptgram.timer \
        aptgram.service \
        >/dev/null 2>&1 ||
        true

    sudo rm -f \
        "${install_bin_dir}/aptgram" \
        "${install_bin_dir}/aptgram-config" \
        "${install_bin_dir}/aptgram-uninstall" \
        "${install_bin_dir}/aptgram-update"

    sudo cp -a \
        "${backup_dir}/bin/." \
        "${install_bin_dir}/"

    sudo rm -rf "${install_lib_dir}"

    sudo cp -a \
        "${backup_dir}/aptgram-lib" \
        "${install_lib_dir}"

    sudo rm -f \
        "${systemd_unit_dir}/aptgram.service" \
        "${systemd_unit_dir}/aptgram.timer"

    sudo cp -a \
        "${backup_dir}/systemd/." \
        "${systemd_unit_dir}/"

    sudo systemctl daemon-reload

    restore_timer_state \
        "${timer_was_enabled}" \
        "${timer_was_active}"
)
