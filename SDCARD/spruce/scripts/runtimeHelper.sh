#!/bin/sh

. /mnt/SDCARD/spruce/scripts/helperFunctions.sh
. /mnt/SDCARD/spruce/scripts/firstbootLaneCommon.sh
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

emit_startup_av_trace_from_config() {
    "$SYSTEM_EMIT" av-startup-baselines-if-missing "runtimeHelper.sh" || true
}

initialize_system_emit_gate() {
    # Read the persistent ENABLE_TRACE flag once during boot, then mirror the decision into /tmp
    # so hot-path emit checks do not hit the SD card on every invocation.
    mkdir -p "$SYSTEM_EMIT_GATE_DIR" 2>/dev/null || return 1
    rm -f "$SYSTEM_EMIT_GATE_FILE"

    if flag_check "ENABLE_TRACE"; then
        touch "$SYSTEM_EMIT_GATE_FILE"
        rm -f "$SYSTEM_EMIT_GATE_DIR/trace.off"
        return 0
    fi

    touch "$SYSTEM_EMIT_GATE_DIR/trace.off"
    return 1
}

system_emit_gate_enabled() {
    [ -f "$SYSTEM_EMIT_GATE_FILE" ]
}

UNPACK_STATE_FILE="/mnt/SDCARD/Saves/spruce/unpacker_state"

read_unpack_state() {
    if [ -f "$UNPACK_STATE_FILE" ]; then
        sed -n 's/^state=//p' "$UNPACK_STATE_FILE" | head -n 1
    else
        echo "idle"
    fi
}

run_archive_unpacker_foreground() {
    force_foreground_precmd="$1"

    if [ "$force_foreground_precmd" = "1" ]; then
        SPRUCE_FIRSTBOOT_UI="$FIRSTBOOT_PROGRESS_CONTEXT_UI" \
        SPRUCE_FIRSTBOOT_ARCHIVE_TOTAL="${FIRSTBOOT_PROGRESS_CONTEXT_TOTAL:-0}" \
        SPRUCE_FIRSTBOOT_ARCHIVE_COMPLETED="${FIRSTBOOT_PROGRESS_CONTEXT_COMPLETED:-0}" \
        UNPACKER_FORCE_FOREGROUND_PRECMD=1 /mnt/SDCARD/spruce/scripts/archiveUnpacker.sh
    else
        SPRUCE_FIRSTBOOT_UI="$FIRSTBOOT_PROGRESS_CONTEXT_UI" \
        SPRUCE_FIRSTBOOT_ARCHIVE_TOTAL="${FIRSTBOOT_PROGRESS_CONTEXT_TOTAL:-0}" \
        SPRUCE_FIRSTBOOT_ARCHIVE_COMPLETED="${FIRSTBOOT_PROGRESS_CONTEXT_COMPLETED:-0}" \
        /mnt/SDCARD/spruce/scripts/archiveUnpacker.sh
    fi
}

run_unpacker_foreground() {
    launch_event="$1"
    launch_context="$2"
    result_event="$3"
    log_prefix="$4"
    allow_background_state="$5"
    force_foreground_precmd="$6"
    firstboot_ui="$7"

    "$SYSTEM_EMIT" process runtime "$launch_event" "runtimeHelper.sh" "$launch_context" || true
    firstboot_progress_prepare_unpacker_context "${firstboot_ui:-0}"
    run_archive_unpacker_foreground "$force_foreground_precmd"
    firstboot_progress_finalize_unpacker_context "${firstboot_ui:-0}"

    unpack_state="$(read_unpack_state)"
    if [ "$allow_background_state" = "1" ] && [ "$unpack_state" = "running" ]; then
        log_message "Unpacker: $log_prefix returned with background worker still active."
    else
        log_message "Unpacker: $log_prefix returned with state=$unpack_state."
    fi
    "$SYSTEM_EMIT" process runtime "$result_event" "runtimeHelper.sh" "state=$unpack_state" || true

    if [ "$allow_background_state" = "1" ] && [ "$unpack_state" = "running" ]; then
        return 0
    fi

    [ "$unpack_state" = "complete" ]
}

auto_resume_game() {
    AUTORESUME_ID="$(date +%s)-$$"
    save_active_state="0"; flag_check "save_active" && save_active_state="1"
    in_menu_state="0"; flag_check "in_menu" && in_menu_state="1"
    log_message "Auto Resume[$AUTORESUME_ID] start: save_active=$save_active_state in_menu=$in_menu_state"

    # Ensure device is properly initialized (volume, wifi, etc) before launching auto-resume
    AUTORESUME_INIT_TIMEOUT_SEC=20
    log_message "Auto Resume[$AUTORESUME_ID] init start: launching PyUI startupInitOnly timeout=${AUTORESUME_INIT_TIMEOUT_SEC}s"
    /mnt/SDCARD/App/PyUI/launch.sh -startupInitOnly True &
    init_pid="$!"
    init_timed_out=0
    init_degraded=0
    init_start_ts="$(date +%s)"
    init_next_heartbeat=2
    log_message "Auto Resume[$AUTORESUME_ID] init pid=$init_pid"
    while kill -0 "$init_pid" 2>/dev/null; do
        now_ts="$(date +%s)"
        elapsed=$((now_ts - init_start_ts))
        if [ "$elapsed" -ge "$init_next_heartbeat" ]; then
            log_message "Auto Resume[$AUTORESUME_ID] init wait heartbeat: elapsed=${elapsed}s pid=$init_pid alive=1"
            init_next_heartbeat=$((init_next_heartbeat + 2))
        fi
        if [ "$elapsed" -ge "$AUTORESUME_INIT_TIMEOUT_SEC" ]; then
            init_timed_out=1
            listener_state="absent"
            [ -f /mnt/SDCARD/App/PyUI/realtime_message_network_listener.txt ] && listener_state="present"
            init_cmdline="unavailable"
            if [ -r "/proc/$init_pid/cmdline" ]; then
                init_cmdline="$(tr '\000' ' ' < "/proc/$init_pid/cmdline" 2>/dev/null)"
                [ -z "$init_cmdline" ] && init_cmdline="empty"
            fi
            init_ps="unavailable"
            if command -v ps >/dev/null 2>&1; then
                init_ps="$(ps 2>/dev/null | awk -v p="$init_pid" '$1==p{print; found=1} END{if(!found) print "not-found"}')"
            fi
            log_message "Auto Resume[$AUTORESUME_ID] init timeout: startupInitOnly exceeded ${AUTORESUME_INIT_TIMEOUT_SEC}s (pid=$init_pid); listener=$listener_state cmdline=$init_cmdline ps=$init_ps"
            kill "$init_pid" 2>/dev/null || true
            sleep 1
            kill -9 "$init_pid" 2>/dev/null || true
            if kill -0 "$init_pid" 2>/dev/null; then
                log_message "Auto Resume[$AUTORESUME_ID] init kill result: pid still alive after SIGTERM+SIGKILL"
            else
                log_message "Auto Resume[$AUTORESUME_ID] init kill result: pid exited after timeout"
            fi
            break
        fi
        sleep 0.2
    done
    wait "$init_pid" 2>/dev/null
    init_rc="$?"
    if [ "$init_timed_out" -eq 1 ]; then
        init_degraded=1
        log_message "Auto Resume[$AUTORESUME_ID] init degraded: continuing resume stage without startupInitOnly completion wait_rc=$init_rc"
    else
        log_message "Auto Resume[$AUTORESUME_ID] init complete: startupInitOnly exit_code=$init_rc"
    fi

    # moving rather than copying prevents you from repeatedly reloading into a corrupted NDS save state;
    # copying is necessary for repeated save+shutdown/autoresume chaining though and is preferred when safe.
    MOVE_OR_COPY=cp
    if grep -q "Roms/NDS" "${FLAGS_DIR}/lastgame.lock"; then MOVE_OR_COPY=mv; fi

    # runtimeHelper producer contract:
    # stage once and hand off; principal.sh owns execution and cleanup.
    AUTORESUME_STAGED_FLAG="autoresume_staged"
    AUTORESUME_CONSUMED_FLAG="autoresume_consumed"
    STAGED_PATH="/tmp/cmd_to_run.sh"
    STAGED_TMP="/tmp/cmd_to_run.sh.autoresume.tmp"

    if flag_check "$AUTORESUME_STAGED_FLAG"; then
        log_message "Auto Resume[$AUTORESUME_ID] stage skipped: existing staged marker already present."
        return 1
    fi

    rm -f "$STAGED_TMP" "$STAGED_PATH"
    log_message "Auto Resume[$AUTORESUME_ID] stage attempt: source=/mnt/SDCARD/spruce/flags/lastgame.lock target=$STAGED_PATH mode=$MOVE_OR_COPY degraded_init=$init_degraded"
    if $MOVE_OR_COPY "/mnt/SDCARD/spruce/flags/lastgame.lock" "$STAGED_TMP"; then
        mv -f "$STAGED_TMP" "$STAGED_PATH" || return 1
        chmod a+x "$STAGED_PATH"
        flag_add "$AUTORESUME_STAGED_FLAG" --tmp
        flag_remove "$AUTORESUME_CONSUMED_FLAG"
        sync
        if [ "$init_degraded" -eq 1 ]; then
            log_message "Auto Resume[$AUTORESUME_ID] staged for principal.sh execution (degraded_init=1 stage_once=1 path=$STAGED_PATH)"
        else
            log_message "Auto Resume[$AUTORESUME_ID] staged for principal.sh execution (stage_once=1 path=$STAGED_PATH)"
        fi
    else
        rm -f "$STAGED_TMP" "$STAGED_PATH"
        flag_remove "$AUTORESUME_STAGED_FLAG"
        log_message "Auto Resume[$AUTORESUME_ID] staging failed (lastgame.lock copy/move failed); fallback to normal menu boot path."
        return 1
    fi

    return 0
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
