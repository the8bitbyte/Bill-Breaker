#!/bin/bash

EXCLUSIONS_FILE="exclusions"

get_keyboard_inputs() {
  for input_dir in /sys/class/input/input*; do
    if [[ -d "$input_dir" && -f "$input_dir/device/uevent" ]]; then
      if grep -qi "keyboard" "$input_dir/device/uevent"; then
        echo "$input_dir"
      fi
    fi
  done
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

monitor_keyboard() {
  local event_dev="$1"
  local input_dir="$2"

  echo "Please type on your primary keyboard. Detecting activity..."
  local count=0

  sudo stdbuf -oL evtest "$event_dev" 2>/dev/null | while read -r line; do
    if [[ "$line" =~ ^Event:\ time.*EV_KEY ]]; then
      ((count++))
      if ((count > 5)); then
        tput cr
        tput el
        echo "✅ Typing detected! Excluding this keyboard: $input_dir"
        echo "$input_dir" >>"$EXCLUSIONS_FILE"
        exit 0
      fi
    fi
  done
}

echo "Detecting keyboards..."

mapfile -t keyboard_array < <(get_keyboard_inputs)

if [[ ${#keyboard_array[@]} -eq 0 ]]; then
  echo "❌ No keyboards detected. Please note if you are using a laptop the internal keyboard will not be recognized and this Process is not required"
  exit 1
fi

echo "Detected keyboards:"
for ((i = 0; i < ${#keyboard_array[@]}; i++)); do
  echo "[$i] ${keyboard_array[i]}"
done
tput cr
tput el
#echo "Now, type on your keyboard for a few seconds..."
for input_dir in "${keyboard_array[@]}"; do
  event_dev=$(derive_event_device "$input_dir")
  if [[ -n "$event_dev" ]]; then
    monitor_keyboard "$event_dev" "$input_dir" &
  fi
done

wait
tput cr
tput el
echo "Process complete! You can run exclude.sh again to exclude more keyboards."
