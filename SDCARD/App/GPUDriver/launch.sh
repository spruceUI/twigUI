#!/bin/sh

. /mnt/SDCARD/spruce/scripts/helperFunctions.sh
. /mnt/SDCARD/spruce/scripts/runtimeHelper.sh

CURR_DRIVER=$(gpudriver)

case "$CURR_DRIVER" in
    "panfrost")
        OTHER_DRIVER="libmali"
        ;;
    "libmali")
        OTHER_DRIVER="panfrost"
        ;;
    *)
        ;;
esac

DISP_MSG="Switch from ${CURR_DRIVER} to ${OTHER_DRIVER}?\nThe device needs to restart to switch GPU drivers.\n\nPress A to confirm, or B to cancel."

if [ $OTHER_DRIVER = "panfrost" ]; then
    DISP_MSG="Panfrost can cause visual glitches in the main menu, only use if it's required by any port.\n\n${DISP_MSG}"
fi

start_pyui_message_writer "1" # Wait for listener

display_message "$(printf '{"cmd":"MESSAGE","args":["%s"]}' "$DISP_MSG")"
log_message "Waiting for GPU driver switch confirmation..."

if confirm; then
    log_message "Switching GPU driver to $OTHER_DRIVER"
    gpudriver $OTHER_DRIVER
    sync

    log_message "Restarting..."
    reboot
else
    log_and_display_message "Cancelled by user."
    sleep 1
    exit 0
fi
