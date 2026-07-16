# Changelog

All notable changes to APTGRAM are documented in this file.

## [Unreleased]

## [1.1.0] - 2026-07-16

### Added

- Added `sudo aptgram-config` for interactively changing the Telegram Bot Token, Telegram chat or channel ID, and daily check time after installation.
- Added independent selection of configuration values, Telegram validation, transactional saving, systemd timer updates, and a final Telegram confirmation message.
- Added `sudo aptgram send-test-heartbeat` for immediately sending the configured weekly heartbeat message without refreshing APT package lists or checking for updates.
- Added localized command help, configuration prompts, validation messages, and Telegram confirmations for all supported languages.
- Added automated behavior tests for configuration changes, validation failures, rollback behavior, credential preservation, timer updates, and upgrades from APTGRAM 1.0.0.

### Changed

- Shared Telegram and configuration validation is now reused by the installer and configuration command.
- Installation, updating, rollback, and uninstallation now include the interactive configuration command.
- Existing APTGRAM configuration, Telegram credentials, credential mode, daily schedule, and timer state remain unchanged during an update.
- Direct upgrades from APTGRAM 1.0.0 require one additional `sudo aptgram-update` invocation to install the new configuration command; no configuration values need to be entered again.
