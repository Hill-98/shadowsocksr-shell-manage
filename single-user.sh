#!/bin/bash

# 命令式入口
main() {
    help() {
        echo \
"$SSRS 管理脚本 (单用户)

用法: `basename $0` <command>
例如: `basename $0` help

命令列表:
    help        查看帮助信息
    install     安装/更新 $SSR
    upgrade     安装/更新 $SSR
    uninstall   卸载 $SSR
    start       启动/重启 $SSR
    restart     启动/重启 $SSR
    stop        停止 $SSR
    viewlog     查看 $SSR 日志
    viewinfo    查看 $SSR 信息
    editconfig  编辑 $SSR 配置文件
    update      检查新版本并更新

未知命令将切换至交互式界面

Version:$ver
"
    exit
    }
    [ $1 = "help" ] && help
    local function_text=("install" "upgrade" "uninstall" "start" "restart" "stop" "viewlog" "viewinfo" "editconfig" "update")
    local function=("install_shadowsocksr" "install_shadowsocksr" "uninstall_shadowsocksr" "start_shadowsocksr" "start_shadowsocksr" "stop_shadowsocksr" "viewlog_shadowsocksr" "viewinfo_shadowsocksr" "set_config_shadowsocksr_customize" "update")
    for ((i=0;i<${#function_text[@]};i++)); do
        if [ "$1" = "${function_text[i]}" ]; then
            local _function=${function[i]}
            break
        fi
    done
    if [ -z "$_function" ]; then
        main_i
    else
        check_main_function $_function
        $_function
    fi
    
}

# 交互式入口
main_i() {
    clear
    local function_text=("安装/更新 $SSR" "卸载 $SSR" "启动/重启 $SSR" "停止 $SSR" "查看 $SSR 日志" "修改 $SSR 配置" "查看 $SSR 信息" "更新 libsodium" "检查更新")
    local function=("install_shadowsocksr" "uninstall_shadowsocksr" "start_shadowsocksr" "stop_shadowsocksr" "viewlog_shadowsocksr" "set_config_shadowsocksr_main" "viewinfo_shadowsocksr" "install_libsodium" "update")
    echo -e "    \033[32m $SSRS 管理脚本 (单用户) v$ver \033[0m"
    echo -e "       \033[32m            By: Hill \033[0m"
    echo -e "      \033[32m     Form: https://goo.gl/hLwm4B \033[0m"
    echo
    for ((i=0;i<${#function_text[@]};i++))
    do
      echo -e "   \033[34m $(($i+1)): ${function_text[$i]} \033[0m"
    done
    echo -e "   \033[34m 0: 退出 \033[0m"
    echo
    if [ $ssr_install_status -eq 0 ]; then
        if [ $ssr_run_status -eq 0 ]; then
            echo -e "   \033[31m 状态：未运行 \033[0m"
        else
            echo -e "   \033[31m 状态：运行中 \033[0m"
        fi
    else
        echo -e "   \033[31m 状态：未安装 \033[0m"
    fi
    echo
    read -p "请输入指定序号：" num
    is_num $num
    isnum=$?
    [ $isnum -ne 0 ] && {
        main_i
        return 1
    }
    clear
    [ $num -eq 0 ] && exit
    local _function=${function[($num - 1)]}
    [ -z "$_function" ] && {
        main_i
        return 1
    }
    check_main_function $_function
    ${function[($num - 1)]}
}

# 检测入口执行函数
 check_main_function() {
     local ignore_function=("install_shadowsocksr" "update")
     for((i=0;i<${#ignore_function[@]};i++))
     do
        [ "$1" = ${ignore_function[i]} ] && return
     done
     if_noinstall_shadowsocksr
 }

# 变量声明
variable() {
    ss="shadowsocks"
    ssr="shadowsocksr"
    SSR="ShadowsocksR"
    SSRS="ShadowsocksR Server"
    name="single-user"
    _name="single_user"
    ver=3
    update_info="shadowsocksr-shell-manage"
    update_url="https://raw.githubusercontent.com/Hill-98/shadowsocksr-shell-manage/master/update.json"
    cpu_number=`cat /proc/cpuinfo | grep -c processor`
    systemd_etc="/etc/systemd/system/multi-user.target.wants/"
    systemd_lib="/lib/systemd/system/"
    libsodium_git="https://github.com/jedisct1/libsodium.git"
    libsodium_branch="stable"
    libsodium_dir="`mktemp -u`"
    ssr_git="https://github.com/shadowsocksrr/shadowsocksr.git"
    ssr_branch="akkariiin/dev"
    ssr_dir="/usr/local/$ssr/"
    ssr_s_dir="/usr/local/$ssr/$ss/"
    ssr_config_file=$ssr_s_dir"config.json"
    ssr_log_file="/var/log/$ssr.log"
    ssr_pid_file="/var/run/$ssr.pid"
    ssr_exec="python ${ssr_s_dir}server.py"
    ssr_exec_start="$ssr_exec -c $ssr_config_file -d start --log-file $ssr_log_file --pid-file $ssr_pid_file"
    ssr_exec_stop="$ssr_exec -d stop"
    ssr_systemd="${ssr}-${name}.service"
    ssr_systemd_etc="${systemd_etc}${ssr_systemd}"
    ssr_systemd_lib="${systemd_lib}${ssr_systemd}"
    is_install_shadowsocksr
    ssr_install_status=$?
    is_run_shadowsocksr
    ssr_run_status=$?
    [ $ssr_install_status -eq 0 ] && {
        ssr_config="`jq . $ssr_config_file`"
        ssr_config_old_port=`jq .server_port $ssr_config_file`
    }
}

# 检查是否为数字
is_num() {
    local exp
    for i in `seq 1 ${#1}`; do
        exp=$exp"[[:digit:]]"
    done
    echo $1 | grep -w $exp >/dev/null 2>&1
    return $?
}

echo_back() {
    echo -e "   \033[34m 0. 返回上级 \033[0m"  
    echo
}

# 检查 ShadowsocksR 是否安装
is_install_shadowsocksr() {
    if [ -f "${ssr_dir}._ssr_" ]; then
        return 0 # 已安装
    else
        return 1 # 未安装
    fi
}

#如果 ShadowsocksR 没有安装
if_noinstall_shadowsocksr() {
    [ $ssr_install_status -ne 0 ] && {
        echo "请先安装 $SSR 再执行其他操作"
        exit 1
    }
}

# 安装和更新 ShadowsocksR
install_shadowsocksr() {
    if [ $ssr_install_status -ne 0 ]; then
        install_depend
        install_libsodium
        echo -e "\033[31m 开始安装 $SSR ... \033[0m"
        rm -rf $ssr_dir
        mkdir -p $ssr_dir
        cd $ssr_dir
        git clone $ssr_git --branch $ssr_branch .
        echo "$ssr" > ._ssr_
        echo -e "\033[31m $SSR 安装完成, 按任意键进行初始化配置. \033[0m" 
        cat ${ssr_dir}config.json | sed 's/\/\/.*//g' > $ssr_config_file
        variable
        read
        set_config_shadowsocksr_port 1
        set_config_shadowsocksr_passwd 1
        set_config_shadowsocksr_method 1
        set_config_shadowsocksr_protocol 1
        set_config_shadowsocksr_obfs 1
        start_shadowsocksr
    else
        cd $ssr_dir
        git pull
        [ $ssr_run_status -ne 0 ] && start_shadowsocksr
    fi
}

# 安装依赖
install_depend() {
    echo -e "\033[31m 开始安装所需依赖软件包... \033[0m"
    which apt-get >/dev/null 2>&1 # Debian/Ubuntu
    [ $? -eq 0 ] && {
        apt-get update
        apt-get install -y build-essential
        apt-get install -y curl git jq nano pwgen python
    }
    which yum >/dev/null 2>&1 # CentOS
    [ $? -eq 0 ] && {
        yum makecache
        yum groupinstall -y "Development Tools"
        yum install -y curl git jq nano pwgen python
    }
}

# 安装 libsodium
install_libsodium() {
    echo -e "\033[31m 开始安装 libsodium ... \033[0m"
    mkdir -p $libsodium_dir
    cd $libsodium_dir
    git clone $libsodium_git --branch $libsodium_branch .
    ./configure
    make -j$cpu_number && make check -j$cpu_number
    make install
    ldconfig
    rm -rf $libsodium_dir
}

# 卸载 ShadowsocksR
uninstall_shadowsocksr() {
    [ $ssr_run_status -ne 0 ] && stop_shadowsocksr
    boot_shadowsocksr
    rm -rf $ssr_dir
    rm -f $ssr_systemd_lib
    echo "$SSR 卸载完成"
}

# 检查 ShadowsocksR 是否运行
is_run_shadowsocksr() {
    [ -f "$ssr_pid_file" ] && local pid=`cat $ssr_pid_file` || return 0
    if [ -d "/proc/$pid" ]; then
        return 1 # 运行中
    else
        return 0 # 未运行
    fi
}

# 如果 ShadowsocksR 没有运行
if_norun_shadowsocksr() {
    [ $ssr_run_status -eq 0 ] && {
        echo "$SSR 未运行"
        exit 2
    }
}

# 启动 ShadowsocksR
start_shadowsocksr() {
    [ $ssr_run_status -ne 0 ] && stop_shadowsocksr
    ulimit -n 512000
    $ssr_exec_start
    iptables_shadowsocksr I
    if [ "$1" != "boot" ]; then
        viewinfo_shadowsocksr
    fi
}

# 停止 ShadowsocksR
stop_shadowsocksr() {
    if_norun_shadowsocksr
    $ssr_exec_stop
    iptables_shadowsocksr D
}

# 开机启动 ShadowsocksR
boot_shadowsocksr() {
    is_install_shadowsocksr
    [ $? -ne 0 ] && return
    set_shadowsockr_systemd
    is_run_shadowsocksr
    ssr_run_status=$?
    local action
    if [ $ssr_run_status -eq 0 ]; then
        [ -f "$ssr_systemd_etc" ] && action="disable"
    else
        [ ! -f "$ssr_systemd_etc" ] && action="enable"
    fi
    [ -n "$action" ] && systemctl $action $ssr_systemd >/dev/null 2>&1
}

# 设置 ShadowsocksR systemd
set_shadowsockr_systemd() {
    write_systemd() {
        cat <<-EOF >$ssr_systemd_lib
[Unit]
Description=ShadowsocksR Shell Manage
Wants=network-online.target
After=network.target

[Service]
Type=oneshot
ExecStart=$ExecStart
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
        systemctl daemon-reload
    }
    local ExecStart="${_pwd}/`basename $0` start systemd"
    local ws=0
    if [ -f "$ssr_systemd_lib" ]; then
        grep -w "ExecStart=$ExecStart" $ssr_systemd_lib >/dev/null 2>&1
        [ $? -ne 0 ] && ws=1
    else
        ws=1
    fi
    [ $ws -ne 0 ] && write_systemd
}

# 添加和删除 iptables 规则
iptables_shadowsocksr() {
    [ "$1" = "D" ] && {
        iptables -D INPUT -p tcp --dport $ssr_config_old_port -j ACCEPT
        iptables -D OUTPUT -p tcp --sport $ssr_config_old_port -j ACCEPT
        iptables -D INPUT -p udp --dport $ssr_config_old_port -j ACCEPT
        iptables -D OUTPUT -p udp --sport $ssr_config_old_port -j ACCEPT
    }
    [ "$1" = "I" ] && {
        local port=`jq .server_port $ssr_config_file`
        iptables -I INPUT -p tcp --dport $port -j ACCEPT
        iptables -I OUTPUT -p tcp --sport $port -j ACCEPT
        iptables -I INPUT -p udp --dport $port -j ACCEPT
        iptables -I OUTPUT -p udp --sport $port -j ACCEPT
    }
}

# 查看 ShadwosocksR 日志
viewlog_shadowsocksr() {
    if_norun_shadowsocksr
    tail -f $ssr_log_file
}

# 修改 ShadowsocksR 配置交互式入口
set_config_shadowsocksr_main() {
    clear
    echo -e "       \033[32m 修改 $SSR 配置 \033[0m"
    echo
    local function_text=("端口" "密码" "加密方法" "协议插件" "协议插件参数" "混淆插件" "混淆插件参数" "单线程限速" "单用户限速" "日志模式" "自定义修改")
    local function=("set_config_shadowsocksr_port" "set_config_shadowsocksr_passwd" "set_config_shadowsocksr_method" "set_config_shadowsocksr_protocol" "set_config_shadowsocksr_protocol_param" "set_config_shadowsocksr_obfs" "set_config_shadowsocksr_obfs_param" "set_config_shadowsocksr_speed_con" "set_config_shadowsocksr_speed_user" "set_config_shadowsocksr_log" "set_config_shadowsocksr_customize")
    for ((i=0;i<${#function_text[@]};i++))
    do
      echo -e "   \033[34m $(($i+1)): ${function_text[$i]} \033[0m"
    done
    echo_back
    read -p "请输入指定序号：" num
    is_num $num
    isnum=$?
    [ $isnum -ne 0 ] && {
        set_config_shadowsocksr_main
        return 1
    }
    [ -z "${function[($num - 1)]}" ] && {
        set_config_shadowsocksr_main
        return 1
    }
    [ $num -eq 0 ] && {
        main_i
        return 0
    }
    ${function[($num - 1)]}
}

# 更改 ShadowsocksR 配置文件
set_config_shadowsocksr() {
    local json_line=`echo "$ssr_config" | grep -w "\"$1\"" `
    local comma
    local key="\"$1\""
    local value=$2
    [ "${json_line:$((${#json_line}-1))}" = "," ] && comma=","
    if [ -n "`echo $json_line | grep '".*": ".*"'`" ]; then
        value="\"$value\""
    fi
    ssr_config="`echo "$ssr_config" | sed "s/$json_line/  $key: $value$comma/"`"
    echo "$ssr_config" > $ssr_config_file
    [ $ssr_run_status -ne 0 ] && start_shadowsocksr
}

# 获取 ShadowsocksR 当前配置
get_config_shadowsocksr_curr() {
    echo -e "\033[36m 当前配置: `jq .$1 $ssr_config_file`\033[0m"
    echo
}

# 设置 ShadowsocksR 端口
set_config_shadowsocksr_port() {
    clear
    local function_name="set_config_shadowsocksr_port"
    local json_key="server_port"
    local port=$RANDOM
    get_config_shadowsocksr_curr $json_key
    read -p "请设置端口 [1-65535] (默认: $port): " ssr_config_port
    [ -z "$ssr_config_port" ] && ssr_config_port=$port
    is_num $ssr_config_port
    isnum=$?
    [ $isnum -ne 0 ] && {
        $function_name
        return 1
    }
    [ $ssr_config_port -eq 0 ] && {
        if [ -z "$1" ]; then
            set_config_shadowsocksr_main
        else
            $function_name
        fi
        return 0
    }
    [ $ssr_config_port -gt 65535 ] && {
        $function_name
        return 1
    }
    set_config_shadowsocksr $json_key $ssr_config_port
}

# 设置 ShadowsocksR 密码
set_config_shadowsocksr_passwd() {
    clear
    local function_name="set_config_shadowsocksr_passwd"
    local json_key="password"
    local passwd="`pwgen 16 1`"
    get_config_shadowsocksr_curr $json_key
    read -p "请设置密码 (默认: $passwd): " ssr_config_passwd
    if [ -z "$ssr_config_passwd" ]; then
        ssr_config_passwd=$passwd
    fi
    [ "$ssr_config_passwd" = "0" ] && {
        if [ -z "$1" ]; then
            set_config_shadowsocksr_main
        else
            $function_name
        fi
    }
    set_config_shadowsocksr $json_key $ssr_config_passwd
}

# 设置 ShadowsocksR 加密方法
set_config_shadowsocksr_method() {
    clear
    local function_name="set_config_shadowsocksr_method"
    local json_key="method"
    local method=("none" "rc4" "rc4-md5" "rc4-md5-6" "aes-128-cfb" "aes-192-cfb" "aes-256-cfb" "aes-128-ctr" "aes-192-ctr" "aes-256-ctr" "chacha20" "chacha20-ietf" "salsa20")
    for ((i=0;i<${#method[@]};i++))
    do
        echo -e "   \033[34m $(($i+1)): ${method[$i]} \033[0m"
    done
    echo_back
    echo -e "   \033[31m 提示：如需使用 auth_chain_* 协议插件，推荐设置为 none .\033[0m"
    echo
    get_config_shadowsocksr_curr $json_key
    read -p "请选择加密方法 (默认: aes-128-ctr): " num
    [ -z "$num" ] && num=8
    is_num $num
    isnum=$?
    [ $isnum -ne 0 ] && {
        $function_name
        return 1
    }
    [ -z "${method[($num - 1)]}" ] && {
        $function_name
        return 1
    }
    [ $num -eq 0 ] && {
        if [ -z "$1" ]; then
            set_config_shadowsocksr_main
        else
            $function_name
        fi
        return 0
    }
    ssr_config_method=${method[($num - 1)]}
    set_config_shadowsocksr $json_key $ssr_config_method
}

# 设置 ShadowsocksR 协议插件
set_config_shadowsocksr_protocol() {
    clear
    local function_name="set_config_shadowsocksr_protocol"
    local json_key="protocol"
    local protocol=("origin" "verify_deflate" "auth_sha1_v4" "auth_aes128_md5" "auth_aes128_sha1" "auth_chain_a" "auth_chain_b" "auth_chain_c" "auth_chain_d" "auth_chain_e" "auth_chain_f")
    for ((i=0;i<${#protocol[@]};i++))
    do
        echo -e "   \033[34m $(($i+1)): ${protocol[$i]} \033[0m"
    done
    echo_back
    echo -e "   \033[31m 提示：推荐使用 auth_chain_* 协议插件 \033[0m"
    echo
    get_config_shadowsocksr_curr $json_key
    read -p "请选择协议插件 (默认: auth_aes128_md5): " num
    [ -z "$num" ] && num=4
    is_num $num
    isnum=$?
    [ $isnum -ne 0 ] && {
        $function_name
        return 1
    }
    [ -z "${protocol[($num - 1)]}" ] && {
        $function_name
        return 1
    }
    [ $num -eq 0 ] && {
        if [ -z "$1" ]; then
            set_config_shadowsocksr_main
        else
            $function_name
        fi
        return 0
    }
    ssr_config_protocol=${protocol[($num - 1)]}
    set_config_shadowsocksr $json_key $ssr_config_protocol
}

# 设置 ShadowsocksR 协议插件参数
set_config_shadowsocksr_protocol_param() {
    clear
    local function_name="set_config_shadowsocksr_protocol_param"
    local json_key="protocol_param"
    get_config_shadowsocksr_curr $json_key
    read -p "请设置协议插件参数 (默认: 无): " ssr_config_protocol_param
    [ -z "$ssr_config_protocol_param" ] && return 0
    [ "$ssr_config_protocol_param" = "0" ] && {
        if [ -z "$1" ]; then
            set_config_shadowsocksr_main
        else
            $function_name
        fi
        return 0
    }
    set_config_shadowsocksr $json_key $ssr_config_protocol_param
}

# 设置 ShadowsocksR 混淆插件
set_config_shadowsocksr_obfs() {
    clear
    local function_name="set_config_shadowsocksr_obfs"
    local json_key="obfs"
    local obfs=("plain" "http_simple" "http_post" "tls1.2_ticket_auth" "tls1.2_ticket_fastauth")
    for ((i=0;i<${#obfs[@]};i++))
    do
        echo -e "   \033[34m $(($i+1)): ${obfs[$i]} \033[0m"
    done
    echo_back
    echo -e "   \033[31m 提示：如果你当前地区 QoS 推荐使用 http_simple 或 tls1.2_ticket_auth 混淆插件, 否则推荐使用 plain . \033[0m"
    echo
    get_config_shadowsocksr_curr $json_key
    read -p "请选择混淆插件 (默认: tls1.2_ticket_auth): " num
    [ -z "$num" ] && num=4
    is_num $num
    isnum=$?
    [ $isnum -ne 0 ] && {
        $function_name
        return 1
    }
    [ -z "${obfs[($num - 1)]}" ] && {
        $function_name
        return 1
    }
    [ $num -eq 0 ] && {
        if [ -z "$1" ]; then
            set_config_shadowsocksr_main
        else
            $function_name
        fi
        return 0
    }
    ssr_config_obfs=${obfs[($num - 1)]}
    set_config_shadowsocksr $json_key $ssr_config_obfs
}

# 设置 ShadowsocksR 混淆插件参数
set_config_shadowsocksr_obfs_param() {
    clear
    local function_name="set_config_shadowsocksr_obfs_param"
    local json_key="obfs_param"
    get_config_shadowsocksr_curr $json_key
    read -p "请设置混淆插件参数 (推荐: cloudflare.com): " ssr_config_obfs_param
    [ -z "$ssr_config_obfs_param" ] && return 0
    [ "$ssr_config_obfs_param" = "0" ] && {
        if [ -z "$1" ]; then
            set_config_shadowsocksr_main
        else
            $function_name
        fi
        return 0
    }
    set_config_shadowsocksr $json_key $ssr_config_obfs_param
}

# 设置 ShadowsocksR 单线程限速
set_config_shadowsocksr_speed_con() {
    clear
    local function_name="set_config_shadowsocksr_speed_con"
    local json_key="speed_limit_per_con"
    get_config_shadowsocksr_curr $json_key
    read -p "请设置单线程限速 [KB/s] (默认: 0): " ssr_config_speed_con
    [ -z "$ssr_config_speed_con" ] && {
        ssr_config_speed_con=0
        return 0
    }
    is_num $ssr_config_speed_con
    isnum=$?
    [ $isnum -ne 0 ] && {
        $function_name
        return 1
    }
    [ $ssr_config_speed_con -eq 0 ] && {
        if [ -z "$1" ]; then
            set_config_shadowsocksr_main
        else
            $function_name
        fi
        return 0
    }
    set_config_shadowsocksr $json_key $ssr_config_speed_con
}

# 设置 ShadowsocksR 单用户限速
set_config_shadowsocksr_speed_user() {
    clear
    local function_name="set_config_shadowsocksr_speed_user"
    local json_key="speed_limit_per_user"
    get_config_shadowsocksr_curr $json_key
    read -p "请设置单用户限速 [KB/s] (默认: 0): " ssr_config_speed_user
    [ -z "$ssr_config_speed_user" ] && {
        ssr_config_speed_user=0
        return 0
    }
    is_num $ssr_config_speed_user
    isnum=$?
    [ $isnum -ne 0 ] && {
        $function_name
        return 1
    }
    [ $ssr_config_speed_user -eq 0 ] && {
        if [ -z "$1" ]; then
            set_config_shadowsocksr_main
        else
            $function_name
        fi
        return 0
    }
    set_config_shadowsocksr $json_key $ssr_config_speed_user
}

# 设置 ShadowsocksR 日志模式
set_config_shadowsocksr_log() {
    clear
    local function_name="set_config_shadowsocksr_log"
    local log_mode=("默认" "输出连接信息")
    for ((i=0;i<${#log_mode[@]};i++))
    do
        echo -e "   \033[34m $(($i+1)): ${log_mode[$i]} \033[0m"
    done
    echo_back
    read -p "请选择日志模式 (默认: 默认): " num
    [ -z "$num" ] && num=1
    is_num $num
    isnum=$?
    [ $isnum -ne 0 ] && {
        $function_name
        return 1
    }
    [ -z "${log_mode[($num - 1)]}" ] && {
        $function_name
        return 1
    }
    [ $num -eq 0 ] && {
        if [ -z "$1" ]; then
            set_config_shadowsocksr_main
        else
            $function_name
        fi
        return 0
    }
    ssr_config_log_connect=0
    case $num in
        2)
            ssr_config_log_connect=1
        ;;
    esac
    set_config_shadowsocksr connect_verbose_info $ssr_config_log_connect
}

# 自定义更改 ShadowsocksR 配置
set_config_shadowsocksr_customize() {
    clear
    nano $ssr_config_file
    [ $ssr_run_status -ne 0 ] && start_shadowsocksr
}

# 查看 ShadowsocksR 信息
viewinfo_shadowsocksr() {
    clear
    local key=("server_port" "password" "method" "protocol" "protocol_param" "obfs" "obfs_param" "speed_limit_per_con" "speed_limit_per_user")
    local key_name=("端口" "密码" "加密方法" "协议插件" "协议插件参数" "混淆插件" "混淆插件参数" "单线程限速 [KB/s]" "单用户限速 [KB/s]")
    echo -e "   \033[32m $SSRS \033[0m"
    echo
    for ((i=0;i<${#key[@]};i++)); do
        echo -e "\033[36m ${key_name[i]}:\033[0m \033[34m`jq -r .${key[i]} $ssr_config_file` \033[0m"
    done
    if [ `jq .connect_verbose_info $ssr_config_file` -eq 0 ]; then
        local connect_verbose_info="否"
    else
        local connect_verbose_info="是"
    fi
    echo -e "\033[36m 日志输出连接信息:\033[0m \033[34m$connect_verbose_info \033[0m"
    echo
}

# 检查新版本并更新
update() {
    clear
    echo "正在检查更新..."
    local data=`curl -s -L $update_url`
    clear
    if [ $? -eq 0 ]; then
        local info=`echo "$data" | jq -r .info`
        if [ "$info" = "$update_info" ]; then
            local version=`echo "$data" | jq .${_name}_ver`
            local local_md5="`md5sum $0 | awk '{print $1}'`"
            local update_md5="`echo "$data" | jq -r .${_name}_md5`"
            echo "本地版本: $local_md5"
            echo "最新版本: $update_md5"
            if [ $ver -lt $version -o "$local_md5" != "$update_md5" ]; then
                echo -e "检测到新版本: \033[31m$version\033[0m"
                echo -e "本地版本: \033[31m$ver\033[0m"
                echo
                echo "MD5:"
                echo "本地版本: $local_md5"
                echo "最新版本: $update_md5"
                echo
                echo "更新日志: "
                echo "$data" | jq -r .${_name}_log
                echo
                read -p "是否更新 [Y/n]: " yn
                [ "$yn" = "Y" -o "$yn" = "y" ] && {
                    echo
                    mkdir -p /tmp/$update_info
                    local save_file="/tmp/$update_info/${name}.sh"
                    curl -o $save_file  `echo "$data" | jq -r .${_name}_url`
                    if [ $? -eq 0 ]; then
                        local md5=`md5sum $save_file | awk '{print $1}'`
                        if [ "$md5" = "$update_md5" ]; then
                            mv $save_file $0
                            chmod +x $0
                            echo "更新完成"
                        else
                            echo "下载文件校验失败"
                        fi

                    else
                        echo "更新文件下载失败"
                    fi
                }
            else
                echo "当前已是最新版"
            fi
        else
            echo "获取版本信息失败"
        fi
    else
        echo "获取版本信息失败"
    fi
}

if [ `id -u` -eq 0 ]; then
    cd `dirname $0`
    _pwd="`pwd`"
    variable
    if [ $# -gt 0 ]; then
        main $1
    else
        main_i
    fi
    boot_shadowsocksr
    [ "$2" = "systemd" ] && exit 0
else
    echo "请以 Root 用户运行"
    exit 1
fi
