#!/bin/bash

# 新的安装目录
NEW_INSTALL_DIR="/opt/realm"
# 旧的安装目录
OLD_INSTALL_DIR="/root/realm"

# 设置默认的 GitHub 地址
GITHUB_URL="https://github.com/zhboner/realm/releases/latest"

# 用户自定义的 GitHub 加速地址
ACCELERATE_URL=""

# 检查旧路径是否存在
if [ -d "$OLD_INSTALL_DIR" ]; then
    echo "检测到旧的安装路径 $OLD_INSTALL_DIR。"
    read -p "是否迁移到新的路径 $NEW_INSTALL_DIR? (Y/N): " migrate_choice
    if [[ $migrate_choice == "Y" || $migrate_choice == "y" ]]; then
        echo "正在迁移到新的路径 $NEW_INSTALL_DIR..."
        mkdir -p $NEW_INSTALL_DIR
        cp -r $OLD_INSTALL_DIR/* $NEW_INSTALL_DIR/
        echo "迁移完成。"
    else
        NEW_INSTALL_DIR="$OLD_INSTALL_DIR"
        echo "继续使用旧的安装路径 $OLD_INSTALL_DIR。"
    fi
else
    echo "没有检测到旧的安装路径。使用新的安装路径 $NEW_INSTALL_DIR。"
fi

# 检查 Realm 是否已安装
if [ -f "$NEW_INSTALL_DIR/realm" ]; then
    echo "检测到 Realm 已安装。"
    realm_status="已安装"
    realm_status_color="\033[0;32m" # 绿色
else
    echo "Realm 未安装。"
    realm_status="未安装"
    realm_status_color="\033[0;31m" # 红色
fi

# 检查 Realm 服务状态
check_realm_service_status() {
    if systemctl is-active --quiet realm; then
        echo -e "\033[0;32m启用\033[0m" # 绿色
    else
        echo -e "\033[0;31m未启用\033[0m" # 红色
    fi
}

# 获取本地 Realm 版本
get_local_realm_version() {
    if [ -f "$NEW_INSTALL_DIR/realm" ]; then
        local_version=$($NEW_INSTALL_DIR/realm -v)
        echo "本地 Realm 版本为: ${local_version}"
    else
        local_version="未安装"
        echo "Realm 未安装。"
    fi
}

# 获取最新版本号
get_latest_realm_version() {
    latest_version=$(curl -s $GITHUB_URL | grep 'tag_name' | cut -d\" -f4)
    echo "最新的 Realm 版本为: ${latest_version}"
}

# 检查 CPU 架构并下载相应的 Realm 包
download_realm() {
    arch=$(uname -m)
    case $arch in
        x86_64)
            package="realm-x86_64-unknown-linux-gnu.tar.gz"
            ;;
        aarch64)
            package="realm-aarch64-unknown-linux-gnu.tar.gz"
            ;;
        armv7l)
            package="realm-armv7-unknown-linux-gnueabihf.tar.gz"
            ;;
        arm*)
            package="realm-arm-unknown-linux-gnueabi.tar.gz"
            ;;
        *)
            echo "不支持的架构: $arch"
            return 1
            ;;
    esac

    # 使用加速地址下载
    if [ -n "$ACCELERATE_URL" ]; then
        # 处理加速地址的斜杠问题
        accelerate_url=$(echo "$ACCELERATE_URL" | sed 's:/*$::')
        download_url="$accelerate_url/https://github.com/zhboner/realm/releases/download/${latest_version}/${package}"
    else
        download_url="https://github.com/zhboner/realm/releases/download/${latest_version}/${package}"
    fi

    wget -O realm.tar.gz "$download_url" || {
        echo "下载出现网络异常，请检查网络连接。"
        read -p "按任意键返回菜单首页..." key
        return 1
    }
}

# 显示菜单的函数
show_menu() {
    clear
    echo "欢迎使用 Realm 一键转发脚本"
    echo "================="
    echo "1. 部署环境"
    echo "2. 添加转发"
    echo "3. 删除转发"
    echo "4. 启动服务"
    echo "5. 停止服务"
    echo "6. 一键卸载"
    echo "7. 更新 Realm"
    echo "8. 设置 GitHub 加速地址"
    echo "================="
    echo -e "Realm 状态：${realm_status_color}${realm_status}\033[0m"
    echo -n "Realm 转发状态："
    check_realm_service_status
    echo "当前 GitHub 加速地址：${ACCELERATE_URL:-无}"
}

# 部署环境的函数
deploy_realm() {
    if [ "$EUID" -ne 0 ]; then
        echo "请使用 root 用户或 sudo 运行脚本以创建服务文件。"
        return
    fi
    mkdir -p $NEW_INSTALL_DIR
    cd $NEW_INSTALL_DIR
    get_latest_realm_version
    download_realm || return 1
    tar -xvf realm.tar.gz
    rm realm.tar.gz
    chmod +x realm
    # 创建服务文件
    cat << EOF > /etc/systemd/system/realm.service
[Unit]
Description=realm
After=network-online.target
Wants=network-online.target systemd-networkd-wait-online.service

[Service]
Type=simple
User=root
Restart=on-failure
RestartSec=5s
DynamicUser=true
WorkingDirectory=$NEW_INSTALL_DIR
ExecStart=$NEW_INSTALL_DIR/realm -c $NEW_INSTALL_DIR/config.toml

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    # 更新 Realm 状态变量
    realm_status="已安装"
    realm_status_color="\033[0;32m" # 绿色
    echo "部署完成。"
}

# 更新 Realm
update_realm() {
    get_local_realm_version
    get_latest_realm_version
    if [ "$local_version" != "$latest_version" ]; then
        echo "更新 Realm 到最新版本..."
        deploy_realm
        echo "Realm 已更新到版本: ${latest_version}"
    else
        echo "当前已是最新版本: ${local_version}"
    fi
}

# 卸载 Realm
uninstall_realm() {
    if [ "$EUID" -ne 0 ]; then
        echo "请使用 root 用户或 sudo 运行脚本以卸载服务。"
        return
    fi
    systemctl stop realm
    systemctl disable realm
    rm -f /etc/systemd/system/realm.service
    systemctl daemon-reload
    rm -rf $NEW_INSTALL_DIR
    echo "Realm 已被卸载。"
    # 更新 Realm 状态变量
    realm_status="未安装"
    realm_status_color="\033[0;31m" # 红色
}

# 删除转发规则的函数
delete_forward() {
    echo "当前转发规则："
    local IFS=$'\n' # 设置 IFS 仅以换行符作为分隔符
    local lines=($(grep -n 'remote =' $NEW_INSTALL_DIR/config.toml)) # 搜索所有包含转发规则的行
    if [ ${#lines[@]} -eq 0 ]; then
        echo "没有发现任何转发规则。"
        return
    fi
    local index=1
    for line in "${lines[@]}"]; do
        echo "${index}. $(echo $line | cut -d '"' -f 2)" # 提取并显示端口信息
        let index+=1
    done

    echo "请输入要删除的转发规则序号，直接按回车返回主菜单。"
    read -p "选择: " choice
    if [ -z "$choice" ]; then
        echo "返回主菜单。"
        return
    fi

    if ! [[ $choice =~ ^[0-9]+$ ]]; then
        echo "无效输入，请输入数字。"
        return
    fi

    if [ $choice -lt 1 ] || [ $choice -gt ${#lines[@]} ]; then
        echo "选择超出范围，请输入有效序号。"
        return
    fi

    local chosen_line=${lines[$((choice-1))]} # 根据用户选择获取相应行
    local line_number=$(echo $chosen_line | cut -d ':' -f 1) # 获取行号

    # 计算要删除的范围，从 listen 开始到 remote 结束
    local start_line=$line_number
    local end_line=$(($line_number + 2))

    # 使用 sed 删除选中的转发规则
    sed -i "${start_line},${end_line}d" $NEW_INSTALL_DIR/config.toml

    echo "转发规则已删除。"
}

# 添加转发规则
add_forward() {
    while true; do
        read -p "请输入 IP: " ip
        read -p "请输入端口: " port
        # 追加到 config.toml 文件
        echo "[[endpoints]]
listen = \"0.0.0.0:$port\"
remote = \"$ip:$port\"" >> $NEW_INSTALL_DIR/config.toml
        
        read -p "是否继续添加(Y/N)? " answer
        if [[ $answer != "Y" && $answer != "y" ]]; then
            break
        fi
    done
}

# 启动服务
start_service() {
    if [ "$EUID" -ne 0 ]; then
        echo "请使用 root 用户或 sudo 运行脚本以启动服务。"
        return
    fi
    sudo systemctl unmask realm.service
    sudo systemctl daemon-reload
    sudo systemctl restart realm.service
    sudo systemctl enable realm.service
    echo "Realm 服务已启动并设置为开机自启。"
}

# 停止服务
stop_service() {
    if [ "$EUID" -ne 0 ]; then
        echo "请使用 root 用户或 sudo 运行脚本以停止服务。"
        return
    fi
    systemctl stop realm
    echo "Realm 服务已停止。"
}

# 设置 GitHub 加速地址
set_accelerate_url() {
    read -p "请输入 GitHub 加速地址: " accelerate_url
    ACCELERATE_URL=$accelerate_url
    echo "GitHub 加速地址已设置为: ${ACCELERATE_URL}"
}

# 主循环
while true; do
    show_menu
    read -p "请选择一个选项: " choice
    case $choice in
        1)
            deploy_realm
            ;;
        2)
            add_forward
            ;;
        3)
            delete_forward
            ;;
        4)
            start_service
            ;;
        5)
            stop_service
            ;;
        6)
            uninstall_realm
            ;;
        7)
            update_realm
            ;;
        8)
            set_accelerate_url
            ;;
        *)
            echo "无效选项: $choice"
            ;;
    esac
    read -p "按任意键继续..." key
done
