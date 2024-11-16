#!/bin/bash

clear
rm -rf /mnt/main_install.sh
# 检查是否为root用户执行
[[ $EUID -ne 0 ]] && echo -e "错误：必须使用root用户运行此脚本！\n" && exit 1
#颜色
red(){
    echo -e "\e[31m$1\e[0m"
}
green(){
    echo -e "\n\e[1m\e[37m\e[42m$1\e[0m\n"
}
yellow='\e[1m\e[33m'
reset='\e[0m'
white(){
    echo -e "$1"
}
################################ IP 选择 ################################
ip_choose() {
    clear
    rm -rf /mnt/main_install.sh
    echo "=================================================================="
    echo -e "\t\tIP 选择脚本 by 忧郁滴飞叶"
    echo -e "\t\n"
    echo "请选择要设置的网络模式，设置完成后脚本将自动重启系统："
    echo "=================================================================="
    echo "1. 静态IP"
    echo "2. DHCP"
    echo -e "\t"
    echo "-. 返回上级菜单"    
    echo "0. 退出脚本"
    read -p "请选择服务: " choice
    case $choice in
        1)
            ip_checking
            static_ip_setting
            ;;
        2)
            ip_checking
            dhcp_setting
            ;;
        0)
            red "退出脚本，感谢使用."
            rm -rf /mnt/ip.sh    #delete         
            ;;
        -)
            white "脚本切换中，请等待..."
            rm -rf /mnt/ip.sh    #delete
            wget -q -O /mnt/main_install.sh https://raw.githubusercontent.com/Jimmyzxk/LinuxScripts/main/AIO/Scripts/main_install.sh && chmod +x /mnt/main_install.sh && /mnt/main_install.sh
            ;;
        *)
            white "无效的选项，1秒后返回当前菜单，请重新选择有效的选项."
            sleep 1
            /mnt/ip.sh
            ;;
    esac 
}
################################ 网卡及网络设置文件检测 ################################
ip_checking() {
    NETPLAN_DIR="/etc/netplan"
    NETPLAN_FILES=($NETPLAN_DIR/*.yaml)
    INTERFACES=($(ls /sys/class/net | grep -v lo))
    if [[ ${#INTERFACES[@]} -gt 1 ]]; then
        white "检测到多个网卡，请选择要修改的网卡："
        select INTERFACE in "${INTERFACES[@]}"; do
            if [[ -n "$INTERFACE" ]]; then
                NET_INTERFACE="$INTERFACE"
                break
            fi
        done
    elif [[ ${#INTERFACES[@]} -eq 1 ]]; then
        NET_INTERFACE="${INTERFACES[0]}"
    else
        red "未找到网络接口，脚本退出。"
        rm -rf /mnt/ip.sh    #delete
        exit 1
    fi
    if [[ ${#NETPLAN_FILES[@]} -gt 1 ]]; then
        white "检测到多个Netplan文件，请选择要修改的文件："
        select FILE in "${NETPLAN_FILES[@]}"; do
            if [[ -n "$FILE" ]]; then
                NETPLAN_FILE="$FILE"
                break
            fi
        done
    elif [[ ${#NETPLAN_FILES[@]} -eq 1 ]]; then
        NETPLAN_FILE="${NETPLAN_FILES[0]}"
    else
        red "未找到Netplan网络配置文件，脚本退出。"
        rm -rf /mnt/ip.sh    #delete
        exit 1
    fi
}
################################ 设置静态IP ################################
static_ip_setting() {
    read -p "请输入静态IP地址（例如10.10.10.2）： " static_ip
    echo -e "您输入的静态IP地址为：${yellow}$static_ip${reset}"
    read -p "请输入子网掩码（例如24，回车默认为24）： " netmask
    netmask="${netmask:-24}"
    echo -e "您输入的子网掩码为：${yellow}$netmask${reset}"
    read -p "请输入网关地址（例如10.10.10.1）： " gateway
    echo -e "您输入的网关地址为：${yellow}$gateway${reset}"
    read -p "请输入DNS服务器地址（例如10.10.10.3）： " dns
    echo -e "您输入的DNS服务器地址为：${yellow}$dns${reset}"
    sudo cp "$NETPLAN_FILE" "$NETPLAN_FILE.bak"
    sudo bash -c "cat > $NETPLAN_FILE" <<EOL
network:
    version: 2
    ethernets:
        $NET_INTERFACE:
            addresses:
                - $static_ip/$netmask
            nameservers:
                addresses:
                    - $dns
            routes:
                - to: default
                  via: $gateway
EOL
    sudo netplan apply
    if [[ $? -eq 0 ]]; then
        echo -e "静态IP已设置为：${yellow}$static_ip${reset}，系统即将重启"
        sleep 1
        rm -rf /mnt/ip.sh    #delete 
        sudo reboot
    else
        white "设置静态IP失败，请检查配置"
        rm -rf /mnt/ip.sh    #delete 
        exit 1
    fi
}
################################ 设置DHCP ################################
dhcp_setting() {
    if grep -q "dhcp4: true" "$NETPLAN_FILE"; then
        echo "当前已经是DHCP配置，无需修改。"
        rm -rf /mnt/ip.sh    #delete 
    else
        cp "$NETPLAN_FILE" "$NETPLAN_FILE.bak"
        bash -c "cat > $NETPLAN_FILE" <<EOL
network:
    version: 2
    ethernets:
        $NET_INTERFACE:
            dhcp4: true
EOL
        netplan apply
        if [[ $? -eq 0 ]]; then
            echo -e "已设置为${yellow}DHCP模式${reset}，系统即将重启。"
            sleep 1
            rm -rf /mnt/ip.sh    #delete 
            sudo reboot
        else
            white "设置DHCP模式失败，请检查配置。"
            rm -rf /mnt/ip.sh    #delete 
            exit 1
        fi
    fi
}
################################ 主程序 ################################
ip_choose
