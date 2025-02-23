#!/bin/bash

THRESHOLD=30
CHECK_INTERVAL=0.02
MAINTENANCE_INTERVAL=2
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
EXCLUDED_FILE="$SCRIPT_DIR/exclusions"

declare -a EXCLUDED_KEYBOARDS=()
declare -a MONITORED_KEYBOARDS=()
declare -a BLOCKED_KEYBOARDS=()

while IFS= read -r line; do
  [[ -n "$line" ]] && EXCLUDED_KEYBOARDS+=("$line")
done <"$EXCLUDED_FILE"

get_keyboard_inputs() {
  for input_dir in /sys/class/input/input*; do
    if [[ -d "$input_dir" && -f "$input_dir/device/uevent" ]]; then
      if grep -qi "keyboard" "$input_dir/device/uevent"; then
        echo "$input_dir"
      fi
    fi
  done
}

is_excluded() {
  local keyboard_name="$1"
  for excluded in "${EXCLUDED_KEYBOARDS[@]}"; do
    if [[ "$keyboard_name" == *"$excluded"* ]]; then
      return 0
    fi
  done
  return 1
}

derive_event_device() {
  local input_dir="$1"
  local input_name
  input_name=$(cat "$input_dir/name")

  for event in /sys/class/input/event*; do
    if [[ -f "$event/device/name" ]]; then
      local event_name
      event_name=$(cat "$event/device/name")
      if [[ "$input_name" == "$event_name" ]]; then
        echo "/dev/input/$(basename "$event")"
        return 0
      fi
    fi
  done
}

# Unbind the keyboard from the usbhid driver using the input directory.
#####################################################################################
# Unbind the keyboard from its driver.
# First, try to read the device’s driver symlink.
# If that fails or the unbind file isn’t writable, fall back to the HID driver path.
#####################################################################################
unbind_keyboard() {
  local input_dir="$1"
  local dev_sysfs
  dev_sysfs=$(readlink -f "$input_dir/device")

  local dev_id
  dev_id=$(basename "$dev_sysfs")

  local driver_path=""
  if [[ -L "$input_dir/device/driver" ]]; then
    driver_path=$(readlink -f "$input_dir/device/driver")
  fi

  if [[ -z "$driver_path" || ! -w "$driver_path/unbind" ]]; then
    if [[ -w "/sys/bus/hid/drivers/usbhid/unbind" ]]; then
      driver_path="/sys/bus/hid/drivers/usbhid"
    fi
  fi

  if [[ -w "$driver_path/unbind" ]]; then
    echo "Unbinding device $dev_id from $(basename "$driver_path")"
    echo -n "$dev_id" | sudo tee "$driver_path/unbind" >/dev/null
  else
    echo "Could not unbind $dev_id; no writable unbind file found."
  fi
}

#######################################
# Block the keyboard by unbinding it.
#######################################
block_keyboard() {
  local input_dir="$1"
  echo "Blocking keyboard detected at $input_dir"
  unbind_keyboard "$input_dir"

  if [[ ! " ${BLOCKED_KEYBOARDS[@]} " =~ " $input_dir " ]]; then
    BLOCKED_KEYBOARDS+=("$input_dir")
  fi
}
monitor_keyboard() {
  local input_dir="$1"
  local event_dev
  event_dev=$(derive_event_device "$input_dir")
  if [[ -z "$event_dev" ]]; then
    echo "Could not derive event device for $input_dir"
    return
  fi

  if is_excluded "$input_dir"; then
    echo "🛑 device $input_dir is excluded, skipping"
    return
  fi

  local count=0
  echo "Monitoring keyboard: $event_dev (detected via $input_dir)"

  local start_time
  start_time=$(date +%s)

  sudo stdbuf -oL evtest "$event_dev" 2>/dev/null | while read -r line; do
    if [[ "$line" =~ ^Event:\ time.*EV_KEY ]]; then
      ((count++))
      echo "Typing detected on $event_dev: $line"
    fi

    current_time=$(date +%s)
    elapsed=$((current_time - start_time))
    if ((elapsed >= 1)); then
      if ((count > THRESHOLD)); then
        echo "🚨 Rubber Ducky detected on $event_dev (keystrokes in last second: $count)! Blocking..."
        block_keyboard "$input_dir"
        MONITORED_KEYBOARDS=("${MONITORED_KEYBOARDS[@]/$input_dir/}")
        #sudo shutdown now #optinal, shutdown once a attack is detected to prevent it from rebinding
        if [ -f "$SCRIPT_DIR/ondetect.sh" ]; then
          echo "Found ondetect.sh, executing..."
          sudo bash "$SCRIPT_DIR/ondetect.sh"
        else
          echo "ondetect.sh not found."
        fi
        break
      fi
      count=0
      start_time=$(date +%s)
    fi
  done
}

################################################################################
# Continuously monitor the list of blocked keyboards and re-unbind them if they
# rebind themselves.
################################################################################
maintain_blocked_keyboards() {
  while true; do
    for input_dir in "${BLOCKED_KEYBOARDS[@]}"; do
      if [[ -e "$input_dir/device/driver" ]]; then
        echo "Blocked keyboard at $input_dir appears to be rebound. Re-blocking..."
        block_keyboard "$input_dir"
      fi
    done
    sleep "$MAINTENANCE_INTERVAL"
  done
}

#############################################################################
# Main loop: detect new keyboards, start monitoring them, and maintain blocks.
#############################################################################

maintain_blocked_keyboards & # pretty sure this doesnt work

while true; do
  mapfile -t keyboard_array < <(get_keyboard_inputs)

  for i in "${!MONITORED_KEYBOARDS[@]}"; do
    if [[ ! " ${keyboard_array[@]} " =~ " ${MONITORED_KEYBOARDS[i]} " ]]; then
      echo "Keyboard ${MONITORED_KEYBOARDS[i]} was unplugged. Removing from monitoring list."
      unset 'MONITORED_KEYBOARDS[i]'
    fi
  done

  for input_dir in "${keyboard_array[@]}"; do
    if [[ ! " ${MONITORED_KEYBOARDS[@]} " =~ " $input_dir " &&
      ! " ${BLOCKED_KEYBOARDS[@]} " =~ " $input_dir " ]]; then
      echo "New keyboard detected: $input_dir. Starting monitoring..."
      MONITORED_KEYBOARDS+=("$input_dir")
      monitor_keyboard "$input_dir" &
    fi
  done

  sleep "$CHECK_INTERVAL"
done
