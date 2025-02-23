echo "what type of computer are you using?"

generate_echo() {
  local start_echo=$1
  local end_echo=$2
  local steps=$3
  local index=$4

  local start_r=$(((start_echo & 0xFF0000) >> 16))
  local start_g=$(((start_echo & 0x00FF00) >> 8))
  local start_b=$((start_echo & 0x0000FF))
  local end_r=$(((end_echo & 0xFF0000) >> 16))
  local end_g=$(((end_echo & 0x00FF00) >> 8))
  local end_b=$((end_echo & 0x0000FF))

  local r=$((start_r + (end_r - start_r) * index / steps))
  local g=$((start_g + (end_g - start_g) * index / steps))
  local b=$((start_b + (end_b - start_b) * index / steps))

  printf "\033[38;2;%d;%d;%dm" $r $g $b
}

gprint() {
  local input_string="$1"
  local start_echo=0xef09f7
  local end_echo=0x7809f7
  local delay1=0.02
  local delay=${2:-0.02}
  local newline="${3:-false}"
  local length=${#input_string}

  for ((i = 0; i < $length; i++)); do
    generate_echo $start_echo $end_echo $length $i
    printf "${input_string:$i:1}"
  done
  if [ "$newline" = "true" ]; then
    echo -n -e "\033[0m"
  else
    echo -e "\033[0m"
  fi
}

install_evtest() { #its likely Bill-Breaker doesnt even work on most of these distros, however better safe the sorry
  if command -v pacman &>/dev/null; then
    echo "Detected Arch-based system. Installing evtest..."
    sudo pacman -S --noconfirm evtest
  elif command -v apt &>/dev/null; then
    echo "Detected Debian/Ubuntu-based system. Installing evtest..."
    sudo apt update && sudo apt install -y evtest
  elif command -v dnf &>/dev/null; then
    echo "Detected Fedora-based system. Installing evtest..."
    sudo dnf install -y evtest
  elif command -v zypper &>/dev/null; then
    echo "Detected openSUSE-based system. Installing evtest..."
    sudo zypper install -y evtest
  else
    echo "Unsupported distribution. Please install evtest manually."
    exit 1
  fi
  echo "evtest installation completed."
}

echo "installing dependency (evtest) ..."
install_evtest

tput sc
echo -n " > [ "
gprint "Laptop" 0 "true"
echo " ]"
echo "   [ Desktop ]"

selected=1
while true; do
  read -s -n 1 ke
  case $ke in
  'A')
    if [ "$selected" -eq 1 ]; then
      let "selected=2"
    else
      let "selected=selected-1"
    fi
    ;;
  'B')
    if [ "$selected" -eq 2 ]; then
      let "selected=1"
    else
      let "selected=selected+1"
    fi
    ;;
  '')
    break
    ;;
  *)
    continue
    ;;
  esac
  tput rc

  if [ "$selected" -eq 1 ]; then
    echo -n " > [ "
    gprint "Laptop" 0 "true"
    echo " ]"
    echo "   [ Desktop ]"
    #echo "   [ ${options[2]} ]"
  fi
  if [ "$selected" -eq 2 ]; then
    echo "   [ Laptop ]"
    echo -n " > [ "
    gprint "Desktop" 0 "true"
    echo " ]"
    #echo "   [ ${options[2]} ]"
  fi
  #if [ "$selected2" -eq 3 ]; then
  #  echo "   [ ${options[0]} ]"
  #  echo "   [ ${options[1]} ]"
  #  echo -n " > [ "
  #  gprint "${options[2]}" 0 "true"
  #  echo " ]"
  #fi
done

tput rc
echo "                                                            "
echo "                                                            "
echo "                                                            "
tput rc

if [ "$selected" -eq 2 ]; then
  echo "Running exclude.sh to exclude your defualt keyboard, this requires admin permission"
  sudo ./exclude.sh
fi

echo "Are you using a external keyboard?"

tput sc
echo -n " > [ "
gprint "Yes" 0 "true"
echo " ]"
echo "   [ No ]"

selected3=1
while true; do
  read -s -n 1 ke
  case $ke in
  'A')
    if [ "$selected3" -eq 1 ]; then
      let "selected3=2"
    else
      let "selected3=selected3-1"
    fi
    ;;
  'B')
    if [ "$selected2" -eq 2 ]; then
      let "selected3=1"
    else
      let "selected3=selected3+1"
    fi
    ;;
  '')
    break
    ;;
  *)
    continue
    ;;
  esac
  tput rc

  if [ "$selected3" -eq 1 ]; then
    echo -n " > [ "
    gprint "Yes" 0 "true"
    echo " ]"
    echo "   [ No ]"
    #echo "   [ ${options[2]} ]"
  fi
  if [ "$selected3" -eq 2 ]; then
    echo "   [ Yes ]"
    echo -n " > [ "
    gprint "No" 0 "true"
    echo " ]"
    #echo "   [ ${options[2]} ]"
  fi
  #if [ "$selected2" -eq 3 ]; then
  #  echo "   [ ${options[0]} ]"
  #  echo "   [ ${options[1]} ]"
  #  echo -n " > [ "
  #  gprint "${options[2]}" 0 "true"
  #  echo " ]"
  #fi
done

tput rc
echo "                                                               "
echo "                                                               "
echo "                                                               "
tput rc

if [ "$selected3" -eq 1 ]; then
  echo "Running exclude.sh to exclude your external keyboard, this process requires admin permission"
  sudo ./exclude.sh
fi
tput cr
tput el
echo "Create service? (Recommended so Bill-Breaker runs on boot, also requires root permission)"

tput sc
echo -n " > [ "
gprint "Yes" 0 "true"
echo " ]"
echo "   [ No ]"

selected2=1
while true; do
  read -s -n 1 ke
  case $ke in
  'A')
    if [ "$selected2" -eq 1 ]; then
      let "selected2=2"
    else
      let "selected2=selected2-1"
    fi
    ;;
  'B')
    if [ "$selected2" -eq 2 ]; then
      let "selected2=1"
    else
      let "selected2=selected2+1"
    fi
    ;;
  '')
    break
    ;;
  *)
    continue
    ;;
  esac
  tput rc

  if [ "$selected2" -eq 1 ]; then
    echo -n " > [ "
    gprint "Yes" 0 "true"
    echo " ]"
    echo "   [ No ]"
    #echo "   [ ${options[2]} ]"
  fi
  if [ "$selected2" -eq 2 ]; then
    echo "   [ Yes ]"
    echo -n " > [ "
    gprint "No" 0 "true"
    echo " ]"
    #echo "   [ ${options[2]} ]"
  fi
  #if [ "$selected2" -eq 3 ]; then
  #  echo "   [ ${options[0]} ]"
  #  echo "   [ ${options[1]} ]"
  #  echo -n " > [ "
  #  gprint "${options[2]}" 0 "true"
  #  echo " ]"
  #fi
done

tput rc
echo "                                                           "
echo "                                                            "
echo "                                                            "
tput rc

if [ "$selected2" -eq 2 ]; then
  echo "Everythings all set! Thank you for using Bill-Breaker. You can edit 'ondetect.sh' to customize what happens on detection further"
  exit 1
fi

SCRIPT_PATH="./main.sh"
SERVICE_NAME="Bill-Breaker"
INSTALL_PATH="/usr/local/bin/$SERVICE_NAME"

if [[ ! -f "$SCRIPT_PATH" ]]; then
  echo "Error: Script '$SCRIPT_PATH' not found!"
  exit 1
fi

sudo cp "$SCRIPT_PATH" "$INSTALL_PATH"
chmod +x "$INSTALL_PATH"

SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"
sudo cat <<EOF >"$SERVICE_FILE"
[Unit]
Description=$SERVICE_NAME Service
After=network.target

[Service]
ExecStart=$INSTALL_PATH
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable "$SERVICE_NAME"
sudo systemctl start "$SERVICE_NAME"

echo "Service '$SERVICE_NAME' installed and started successfully!"
echo "Everythings all set! Thank you for using Bill-Breaker. You can edit 'ondetect.sh' to customize what happens on detection further"
