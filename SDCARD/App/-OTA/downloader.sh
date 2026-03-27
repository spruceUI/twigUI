#!/bin/sh

. /mnt/SDCARD/spruce/scripts/helperFunctions.sh

IMAGE_PATH="/mnt/SDCARD/spruce/imgs/update.png"
BAD_IMG="/mnt/SDCARD/spruce/imgs/notfound.png"

OTA_URL="https://api.github.com/repos/spruceUI/twigUI/releases/latest"
TMP_DIR="/mnt/SDCARD/App/-OTA/tmp"

##### FUNCTIONS #####

get_version() {
    twig_file="/mnt/SDCARD/spruce/twig"

    if [ ! -f "$twig_file" ]; then
        echo "0"
        return 1
    fi

    version=$(cat "$twig_file" | tr -d '[:space:]')

    if [ -z "$version" ]; then
        echo "0"
        return 1
    fi

    # Updated regex to handle both beta and nightly versions
    # e.g., 3.3.2-Beta or 3.3.1-20250123
    if echo "$version" | grep -qE '^[0-9]+\.[0-9]+(\.[0-9]+)*(-([A-Za-z]+|[0-9]{8}))?$'; then
        echo "$version"
        return 0
    else
        echo "0"
        return 1
    fi
}

is_wifi_connected() {
    if ping -c 3 -W 2 spruceui.github.io > /dev/null 2>&1; then
        log_message "GitHub ping successful; device is online."
        return 0
    else
        display_image_and_text "$BAD_IMG" 35 20 "GitHub ping failed; device is offline. Aborting." 75
        return 1
    fi
}

download_release_info() {
    # Try to download the file
    OTA_JSON=$(curl -s -S -f "$OTA_URL")
    if [ $? -ne 0 ]; then
        log_message "OTA: Failed to download from $OTA_URL - Error: $OTA_JSON"
        return 1
    fi

    # Verify we got valid content
    json_check=$(echo "$OTA_JSON" | jq 'has("assets")')
    if [ "$json_check" = "true" ]; then
        return 0
    else
        log_message "OTA: Invalid or empty release info file from $OTA_URL"
        return 1
    fi
}

verify_checksum() {
    local file="$1"
    local expected_checksum="$2"
    local downloaded_checksum

    downloaded_checksum=$(sha256sum "$file" | cut -d' ' -f1)

    if [ "$(printf '%s' "$downloaded_checksum")" = "$(printf '%s' "$expected_checksum")" ]; then
        return 0 # Success
    else
        log_message "OTA: Checksum verification failed, received: $downloaded_checksum, expected: $expected_checksum"
        rm -f "$file"
        return 1 # Failure
    fi
}

##### MAIN EXECUTION #####

start_pyui_message_writer
display_image_and_text "$IMAGE_PATH" 35 25 "Checking for updates..." 75

rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

# Check for Wi-Fi and active connection
if ! is_wifi_connected; then sleep 3; exit 1; fi

CURRENT_VERSION=$(get_version)  # this comes from helperFunctions.sh
read_only_check                 # this too is from helperFunctions.sh

# Try primary and backup URLs
if ! download_release_info; then
    log_message "OTA: Primary URL failed; trying backup URL"
    display_image_and_text "$IMAGE_PATH" 35 25 "Update check failed; could not get valid update info. Please try again later." 75
    sleep 5
    rm -rf "$TMP_DIR"
    exit 1
fi

# If we get here, we have valid content
UPDATE_ASSET=$(echo "$OTA_JSON" | jq '.assets[] | select(.name | contains("_update"))')
RELEASE_SIZE=$(echo "$UPDATE_ASSET" | jq '.size')

# Set target to release
TARGET_VERSION=$(echo "$OTA_JSON" | jq -r '.tag_name')
TARGET_CHECKSUM=$(echo "$UPDATE_ASSET" | jq -r '.digest' | cut -d":" -f2)
TARGET_LINK=$(echo "$UPDATE_ASSET" | jq -r '.browser_download_url')
TARGET_SIZE=$(bc <<< "scale=0; $RELEASE_SIZE/1024/1024")
TARGET_INFO=$(echo "$OTA_JSON" | jq -r '.html_url')

SKIP_VERSION_CHECK="$(get_config_value '.menuOptions."Network Settings".otaSkipVersionCheck.selected' "False")"
# Set SKIP_VERSION_CHECK to True if developer mode or tester mode is enabled
if flag_check "developer_mode" || flag_check "tester_mode" || flag_check "beta"; then
    SKIP_VERSION_CHECK="True"
fi

if [ -z "$TARGET_VERSION" ] || [ -z "$TARGET_CHECKSUM" ] || [ -z "$TARGET_LINK" ] || [ -z "$TARGET_SIZE" ] || [ -z "$TARGET_INFO" ]; then
    log_message "OTA: Invalid release info file format
    Target version: $TARGET_VERSION
    Target checksum: $TARGET_CHECKSUM
    Target link: $TARGET_LINK
    Target size: $TARGET_SIZE
    Target info: $TARGET_INFO"
    display_image_and_text "$BAD_IMG" 35 20 "Update check failed: Invalid release info." 75
    sleep 5
    rm -rf "$TMP_DIR"
    exit 1
fi

# Compare versions
log_message "Comparing versions: $TARGET_VERSION vs $CURRENT_VERSION"
if [ "$SKIP_VERSION_CHECK" = "True" ] || [ "$(echo "$TARGET_VERSION $CURRENT_VERSION" | awk '{split($1,a,"."); split($2,b,"."); for (i=1; i<=3; i++) {if (a[i]<b[i]) {print $2; exit} else if (a[i]>b[i]) {print $1; exit}} print $2}')" != "$CURRENT_VERSION" ]; then
    log_message "Proceeding with update"
else
    display_image_and_text "$IMAGE_PATH" 35 25 "System is up to date. Installed version: $CURRENT_VERSION" 75
    rm -rf "$TMP_DIR"
    sleep 5
    exit 0
fi

BATTERY_CAPACITY="$(cat $BATTERY/capacity)"
CHARGING="$(cat $BATTERY/online)"
if [ "$BATTERY_CAPACITY" -lt 20 ] && [ "$CHARGING" -eq 0 ]; then
    display_image_and_text "$IMAGE_PATH" 35 25 "Battery too low to complete update. You can still download it now, but you will need to charge your device to at least 20% or plug it in. Afterwards you may use the EZ Updater app to complete the update process." 75
    sleep 5
    log_message "OTA: Battery level: $BATTERY_CAPACITY%
    Charging: $CHARGING"
fi

update_qr_code="$(qr_code -t "$TARGET_INFO")"
display_image_and_text "$update_qr_code" 50 5 "New version available: $TARGET_VERSION. Scan QR code for release notes. Press A to download and install, or B to cancel." 75

if confirm 300; then
    log_message "OTA: User confirmed"
else
    log_message "OTA: User did not confirm"
    display_image_and_text "$BAD_IMG" 35 20 "Update cancelled." 75
    sleep 3
    rm -rf "$TMP_DIR"
    exit 0
fi

# Extract filename from TARGET_LINK
FILENAME=$(echo "$TARGET_LINK" | sed 's/.*\///')

# Check if update file already exists
if [ -f "/mnt/SDCARD/$FILENAME" ]; then
    display_image_and_text "$IMAGE_PATH" 35 25 "Update file already exists. Verifying..." 75
    log_message "OTA: Update file already exists"
    if verify_checksum "/mnt/SDCARD/$FILENAME" "$TARGET_CHECKSUM"; then
        display_image_and_text "$IMAGE_PATH" 35 25 "Valid update file already exists. Download again anyways? Press A to redownload, or B to use existing file for update."
        if ! confirm; then
            log_message "OTA: User chose to use existing file"
            rm -rf "$TMP_DIR"
            goto_install=true
        else
            rm -rf "/mnt/SDCARD/$FILENAME"
        fi
    else
        display_image_and_text "$IMAGE_PATH" 35 25 "Existing update file isn't valid. Will download fresh copy." 75
        sleep 3
    fi
fi

sync

if [ "$goto_install" != "true" ]; then  # do the downloadin'
    # Check free disk space
    sdcard_mountpoint="$(mount | grep -m 1 "$SD_MOUNTPOINT" | awk '{print $1}')"
    sdcard_freespace="$(df -m "$sdcard_mountpoint" | awk 'NR==2{print $4}')"
    min_install_space=$(((TARGET_SIZE * 2) + 128))
    if [ "$sdcard_freespace" -lt "$min_install_space" ]; then
        log_message "OTA: Not enough free space on SD card (at least ${min_install_space}MB should be free)"
        display_image_and_text "$IMAGE_PATH" 35 25 "Insufficient space on SD card. At least $min_install_space MB of space should be free." 75
        sleep 5
        rm -rf "$TMP_DIR"
        exit 1
    fi

    # Download update file
    display_image_and_text "$IMAGE_PATH" 35 25 "Downloading update..." 75
    if ! download_and_display_progress "$TARGET_LINK" "/mnt/SDCARD/$FILENAME" "twigUI v${TARGET_VERSION}" "$((TARGET_SIZE * 1024 * 1024))"; then
        exit 1
    fi

    # Verify checksum
    display_image_and_text "$IMAGE_PATH" 35 25 "Download complete! Verifying..." 75
    if ! verify_checksum "/mnt/SDCARD/$FILENAME" "$TARGET_CHECKSUM"; then
        display_image_and_text "$BAD_IMG" 35 25 "File downloaded but failed verification. Try again..." 75
        sleep 5
        rm -rf "$TMP_DIR"
        exit 1
    fi
    vibrate &
fi

rm -rf "$TMP_DIR"
# Show updater app
jq 'if ."#label" then .label = ."#label" | del(."#label") else . end' "/mnt/SDCARD/App/-Updater/config.json" > "/mnt/SDCARD/App/-Updater/config.json.tmp" && mv "/mnt/SDCARD/App/-Updater/config.json.tmp" "/mnt/SDCARD/App/-Updater/config.json"

# Check battery level before asking to update
BATTERY_CAPACITY="$(cat $BATTERY/capacity)"
CHARGING="$(cat $BATTERY/online)"
if [ $BATTERY_CAPACITY -lt 20 ] && [ $CHARGING -eq 0 ]; then
    display_image_and_text "$BAD_IMG" 35 25 "Battery too low to safely update. Please charge to at least 20% or plug in your device. You can run the EZ Updater app to install the already downloaded update." 75
    sleep 5
    exit 0
fi

# Update script call
display_image_and_text "$IMAGE_PATH" 35 25 "Download successful! Press A to install now, or B to exit and install later." 75
if confirm 30 0; then
    log_message "OTA: Update confirmed"
    "$(get_python_path)" /mnt/SDCARD/App/-Updater/updater.py
else
    log_message "OTA: Update declined"
    exit 0
fi
