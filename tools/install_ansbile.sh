#!/bin/bash

#!/bin/bash
set -e

# 判斷系統發行版
OS=""
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "無法判斷系統版本 (/etc/os-release 不存在)"
    exit 1
fi

echo "檢測到系統: $OS"

if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
    echo "執行 Ubuntu/Debian 安裝流程..."
    sudo apt update -y
    # sudo apt upgrade -y
    sudo apt install -y ansible tree

elif [[ "$OS" == "rocky" || "$OS" == "rhel" || "$OS" == "centos" ]]; then
    echo "執行 Rocky/RHEL/CentOS 安裝流程..."
    sudo dnf makecache -y
    sudo dnf install -y epel-release
    sudo dnf install -y ansible tree

else
    echo "尚未支援的系統: $OS"
    exit 1
fi

# set -e

# # Update package list
#  sudo apt update -y
# # sudo apt update && sudo apt upgrade -y

# # Install additional tools
# # sudo apt-get dist-upgrade -y

# # Install ansible
# sudo apt install -y ansible

# # Install additional tools
# sudo apt install -y tree

# # Ensure Python venv module is installed
# sudo apt install -y python3.12-venv

# # # Create Python virtual environment if not exists
# if [ ! -d ".venv" ]; then
#   python3 -m venv .venv
# fi


# 以下自行輸入
# # Activate the virtual environment
# source .venv/bin/activate

# # Upgrade pip and install Ansible
# pip install --upgrade pip
# pip install ansible requests joblib tqdm

# echo "Virtual environment and Ansible are ready."