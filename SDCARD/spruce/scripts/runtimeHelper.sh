#!/bin/sh

. /mnt/SDCARD/spruce/scripts/helperFunctions.sh
. /mnt/SDCARD/spruce/scripts/network/sambaFunctions.sh
. /mnt/SDCARD/spruce/scripts/network/sshFunctions.sh

run_sd_card_fix_if_triggered() {
    needs_fix=false
    if [ -e /mnt/SDCARD/FIX_MY_SDCARD ]; then
        needs_fix=true
        log_message "/mnt/SDCARD/FIX_MY_SDCARD detected."
    elif read_only_check; then
        needs_fix=true
    fi

    if [ "$needs_fix" = "true" ]; then
        log_message "Running repairSD.sh..."
        mkdir -p /tmp/sdfix
        cp /mnt/SDCARD/spruce/scripts/tasks/repairSD.sh /tmp/sdfix/
        chmod 777 /tmp/sdfix/repairSD.sh
        /tmp/sdfix/repairSD.sh run
    fi
}

hide_fw_app() {
    jq 'if .label then ."#label" = .label | del(.label) else . end' /mnt/SDCARD/App/-FirmwareUpdate-/config.json > /mnt/SDCARD/App/-FirmwareUpdate-/config.json.tmp && mv /mnt/SDCARD/App/-FirmwareUpdate-/config.json.tmp /mnt/SDCARD/App/-FirmwareUpdate-/config.json
}

show_fw_app() {
    jq 'if ."#label" then .label = ."#label" | del(."#label") else . end' /mnt/SDCARD/App/-FirmwareUpdate-/config.json > /mnt/SDCARD/App/-FirmwareUpdate-/config.json.tmp && mv /mnt/SDCARD/App/-FirmwareUpdate-/config.json.tmp /mnt/SDCARD/App/-FirmwareUpdate-/config.json
}

# Define the function to check and hide the firmware update app
check_and_handle_firmware_app() {
    need_fw_update="$(check_if_fw_needs_update)"
    if [ "$need_fw_update" = "true" ]; then
        show_fw_app
    else
        hide_fw_app
    fi
}

check_for_update() {
    log_message "Device can't boot with wifi on, so don't check for updates at startup."
}

update_checker(){
    sleep 20
    check_for_update
}

check_for_update_file() {
    echo "Searching for update file"
    UPDATE_FILE=$(find /mnt/SDCARD/ -maxdepth 1 -name "twigUI_V*.7z" | awk -F'V' '{print $2, $0}' | sort -n | tail -n1 | cut -d' ' -f2-)
    echo "Found update file: $UPDATE_FILE"

    if [ -z "$UPDATE_FILE" ]; then
        echo "No update file found"
        return 1
    fi
    return 0
}

# Function to check and hide the Update App if necessary
check_and_hide_update_app() {
    if ! check_for_update_file; then
        jq 'if .label then ."#label" = .label | del(.label) else . end' "/mnt/SDCARD/App/-Updater/config.json" > "/mnt/SDCARD/App/-Updater/config.json.tmp" && mv "/mnt/SDCARD/App/-Updater/config.json.tmp" "/mnt/SDCARD/App/-Updater/config.json"
        log_message "No update file found; hiding Updater app"
    else
        jq 'if ."#label" then .label = ."#label" | del(."#label") else . end' "/mnt/SDCARD/App/-Updater/config.json" > "/mnt/SDCARD/App/-Updater/config.json.tmp" && mv "/mnt/SDCARD/App/-Updater/config.json.tmp" "/mnt/SDCARD/App/-Updater/config.json"
        log_message "Update file found; Updater app is visible"
    fi
}

developer_mode_task() {
    if flag_check "developer_mode"; then
        samba_enabled="$(get_config_value '.menuOptions."Network Settings".enableSamba.selected' "False")"
        ssh_enabled="$(get_config_value '.menuOptions."Network Settings".enableSSH.selected' "False")"
        ssh_service=$(get_ssh_service_name)

        if [ "$samba_enabled" = "True" ] || [ "$ssh_enabled" = "True" ]; then
            # Loop until WiFi is connected
            while ! ifconfig wlan0 | grep -qE "inet |inet6 "; do
                sleep 0.2
            done

            if [ "$samba_enabled" = "True" ] && ! pgrep "smbd" > /dev/null; then
                log_message "Dev Mode: Samba starting..."
                start_samba_process
            fi

            if [ "$ssh_enabled" = "True" ] && ! pgrep "$ssh_service" > /dev/null; then
                log_message "Dev Mode: $ssh_service starting..."
                start_ssh_process
            fi
        fi
    fi
}

rotate_logs_background() {
        # Rotate logs spruce5.log -> spruce4.log -> spruce3.log -> etc.
        i=$((max_log_files - 1))
        while [ $i -ge 1 ]; do
            if [ -f "$log_dir/spruce${i}.log" ]; then
                mv "$log_dir/spruce${i}.log" "$log_dir/spruce$((i+1)).log"
            fi
            i=$((i - 1))
        done

        # Move the temporary file to spruce1.log
        if [ -f "$log_target.tmp" ]; then
            mv "$log_target.tmp" "$log_dir/spruce1.log"
        fi
}

rotate_logs() {
    log_dir="/mnt/SDCARD/Saves/spruce"
    log_target="$log_dir/spruce.log"
    max_log_files=5

    # Create the log directory if it doesn't exist
    if [ ! -d "$log_dir" ]; then
        mkdir -p "$log_dir"
    fi

    # If spruce.log exists, move it to a temporary file
    if [ -f "$log_target" ]; then
        mv "$log_target" "$log_target.tmp"
    fi

    # Create a fresh spruce.log immediately
    touch "$log_target"

    # Perform log rotation in the background
    rotate_logs_background &
}

unstage_archive() {
    ARC_DIR="/mnt/SDCARD/spruce/archives"
    STAGED_ARCHIVE="$1"
    TARGET="$2"
    if [ -z "$TARGET_FOLDER" ] || [ "$TARGET_FOLDER" != "preCmd" ]; then TARGET="preMenu"; fi

    if [ -f "$ARC_DIR/staging/$STAGED_ARCHIVE" ]; then
        log_message "$STAGED_ARCHIVE detected in spruce/archives/staging. Moving into place!"
        mv -f "$ARC_DIR/staging/$STAGED_ARCHIVE" "$ARC_DIR/$TARGET/$STAGED_ARCHIVE"
    fi
}

unstage_archives_wanted() {
    if [ "$DISPLAY_WIDTH" = "640" ] && [ "$DISPLAY_HEIGHT" = "480" ]; then
        unstage_archive "overlays_640x480.7z" "preCmd"
    elif [ "$DISPLAY_WIDTH" = "1024" ] && [ "$DISPLAY_HEIGHT" = "768" ]; then
        unstage_archive "overlays_1024x768.7z" "preCmd"
    fi
    if [ "$DEVICE_CAN_USE_EXTERNAL_CONTROLLER" = "true" ]; then
        unstage_archive "autoconfig.7z" "preCmd"
    fi
    if [ "$DEVICE_USES_64_BIT_RA" = "true" ]; then
        unstage_archive "cores64.7z" "preCmd"
    else
        unstage_archive "cores32.7z" "preCmd"
    fi
}

UPDATE_ICON="/mnt/SDCARD/Themes/SPRUCE/icons/app/firmwareupdate.png"

# This works with checker to display a notification if an update is available
# But only on next boot. So if they find the app by themselves it's fine.
update_notification(){
    if [ "$(jq -r '.wifi // 0' "$SYSTEM_JSON")" -eq 0 ]; then
        exit 1
    fi

    if flag_check "update_available"; then
        available_version=$(cat "$(flag_path update_available)")
        display --icon "$UPDATE_ICON" -t "Update available!
Version ${available_version} is ready to install
Go to Apps and look for 'Update Available'" --okay
        flag_remove "update_available"
    fi
}


set_volume_to_config() {
    vol=$(jq -r '.vol // empty' "$SYSTEM_JSON")
    [ -n "$vol" ] && set_volume "$vol"
}

auto_resume_game() {
    log_message "save_active flag detected. Autoresuming game."

    # Ensure device is properly initialized (volume, wifi, etc) before launching auto-resume
    /mnt/SDCARD/App/PyUI/launch.sh -startupInitOnly True

    # moving rather than copying prevents you from repeatedly reloading into a corrupted NDS save state;
    # copying is necessary for repeated save+shutdown/autoresume chaining though and is preferred when safe.
    MOVE_OR_COPY=cp
    if grep -q "Roms/NDS" "${FLAGS_DIR}/lastgame.lock"; then MOVE_OR_COPY=mv; fi

    # move command to cmd_to_run.sh so game switcher can work correctly
    $MOVE_OR_COPY "/mnt/SDCARD/spruce/flags/lastgame.lock" /tmp/cmd_to_run.sh && sync

    sleep 4
    nice -n -20 /tmp/cmd_to_run.sh &> /dev/null
    rm -f /tmp/cmd_to_run.sh # remove tmp command file after game exit; otherwise the game will load again in principal.sh later
    log_message "Auto Resume executed"
}

set_up_boot_action() {
    BOOT_ACTION="$(get_config_value '.menuOptions."System Settings".bootTo.selected' "spruceUI")"
    if ! flag_check "save_active"; then
        log_message "Selected boot action is $BOOT_ACTION."
        case "$BOOT_ACTION" in
            "Random Game")
                echo "\"/mnt/SDCARD/App/RandomGame/random.sh\"" > /tmp/cmd_to_run.sh
                ;;
            "Game Switcher")
                touch /mnt/SDCARD/App/PyUI/pyui_gs_trigger
                ;;
            "Splore")
                log_message "Attempting to boot into Pico-8. Checking for binaries"
                if [ "$PLATFORM_ARCHITECTURE" = "armhf" ]; then
                    PICO8_EXE="pico8_dyn"
                else
                    PICO8_EXE="pico8_64"
                fi
                if [ -f "/mnt/SDCARD/BIOS/pico8.dat" ] && [ -f "/mnt/SDCARD/BIOS/$PICO8_EXE" ]; then
                    echo "\"/mnt/SDCARD/Emu/PICO8/../../spruce/scripts/emu/standard_launch.sh\" \"/mnt/SDCARD/Roms/PICO8/-=☆ Launch Splore ☆=-.splore\"" > /tmp/cmd_to_run.sh
                else
                    log_message "Pico-8 binaries not found; booting to spruceUI instead."
                fi
                ;;
            "Apotris"*)
                log_message "Sun mode engaged."
                GAME_PATH=/mnt/SDCARD/Roms/GBA/Apotris.gba
                if [ -f "$GAME_PATH" ]; then
                    echo "\"/mnt/SDCARD/Emu/GBA/../../spruce/scripts/emu/standard_launch.sh\" \"$GAME_PATH\"" > /tmp/cmd_to_run.sh
                else
                    log_message "Sun's literal entire romset not found; booting to spruceUI instead."
                fi
                ;;
        esac
    fi
}