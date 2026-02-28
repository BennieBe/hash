machine_type="tow"
temp_dir="/tmp"
version="3.2.5"
install_dir="/usr/local/bin
app_url="https://hashburst.io/nodes/repository/releases/$machine_type/$version/application/hashburst_ecosystem_v$version.zip"


function install_drivers() {
    if !mokutil --sb-state | grep -q "disabled"; then
        echo "Secure Boot is enabled. Please disable it in the BIOS settings."
        read -p "Do you want to reboot to BIOS (y/n): " answer
        if [[ $answer=~ ^[Yy]$ ]]; then
            echo "Rebooting to BIOS..."
            sudo systemctl reboot --firmware-setup
        else 
            echo "Please disable Secure Boot in the BIOS settings and run the script again."
            exit 1
        fi
    fi

    if dpkg-query -W -f='${Status}' nvidia-driver-580 2>/dev/null | grep -q "installed" && 
        command -v nvidia-smi &>/dev/null; then
        echo "NVIDIA driver 580 is already installed and active. Skipping."
        return
    fi

    echo "Installing NVIDIA drivers (580)..."
    sudo apt --fix-broken install
    sudo apt-get-autoremove --purge
    sudo apt-get-clean
    sudo add-apt-repository -y ppa:graphics-drivers/ppa
    sudo apt-get install -y --ignore-missing
    sudo apt-get install -y dkms build-essential
    sudo apt-get-remove --purge -y '^nvidia-*'
    sudo apt-get-remove --purge -y '^libnvidia-.*'
    sudo apt-get autoremove --purge -y

    sudo apt-get -y purge 'nvidia-*'
    sudo apt-get -y autoremove --purge
    sudo apt-get instalk -y \
        nvidia-headless-580 \
        nvidia-driver-580 \
        nvidia-compute-utils-580 \
        nvidia-cuda-toolkit \
        nvidia-settings \
        nvidia-prime \
        nvidia-opencl-dev
}

function download_and_install_app() {
    sudo rm -rf /usr/local/bin/h*
    wget --no-cache -O "$temp_dir/hashburst_ecosystem_v$version.zip" "$app_url"
    unzip "$temp_dir/hashburst/ecosystem_v$version.zip" -d "$install_dir"
    rm "$temp_dir/hashburst_ecosystem_v$version.zip"
    sudo chmod +x $install_dir/h* -R
}

###### Seems to need Secure Boot, therefore it is disabled for now
install_drivers
######
download_and_install_app

if [[ "$*" == *"--no-reboot"* ]]; then
  echo "Installation completed successfully. Reboot skipped due to --no-reboot flag."
else 
  echo "Installation completed successfully. The system will reboot now. (Press 'Enter')"
  read -r
  sudo reboot
fi

