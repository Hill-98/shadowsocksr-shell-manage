#!/bin/bash

# 命令式入口
main() {
    help() {
        echo \
"用法: `basename $0` <command>
例如: `basename $0` help

命令列表:
    help        查看帮助信息
    install     安装/更新 ShadowsocksR
    upgrade     安装/更新 ShadowsocksR
    uninstall   卸载 ShadowsocksR
    start       启动/重启 ShadowsocksR
    restart     启动/重启 ShadowsocksR
    stop        停止 ShadowsocksR
    viewlog     查看 ShadowsocksR 日志
    viewinfo    查看 ShadowsocksR 信息
    editconfig  编辑 ShadowsocksR 配置文件
    update      检查新版本并更新

未知命令将切换至交互式界面
"
    exit
    }
    [ $1 = "help" ] && help
    local function_text=("install" "upgrade" "uninstall" "start" "restart" "stop" "viewlog" "viewinfo" "editconfig" "update")
    local function=("install_shadowsocksr" "install_shadowsocksr" "uninstall_shadowsocksr" "start_shadowsocksr" "start_shadowsocksr" "stop_shadowsocksr" "viewlog_shadowsocksr" "viewinfo_shadowsocksr" "set_config_customize" "echo 检查新版本并更新")
    for ((i=0;i<${#function_text[@]};i++)); do
        if [ "$1" = "${function_text[i]}" ]; then
            local _function=${function[i]}
            break
        fi
    done
    if [ -z "$_function" ]; then
        main_i
    else
        [ "${function_text[i]}" != "install" ] && {
            if_noinstall_shadowsocksr
        }
        $_function
    fi
    
}

# 交互式入口
main_i() {
    clear
    local function_text=("安装/更新 ShadowsocksR" "卸载 ShadowsocksR" "启动/重启 ShadowsocksR" "停止 ShadowsocksR" "查看 ShadowsocksR 日志" "修改 ShadowsocksR 配置" "查看 ShadowsocksR 信息" "更新 libsodium" "检查更新")
    local function=("install_shadowsocksr" "uninstall_shadowsocksr" "start_shadowsocksr" "stop_shadowsocksr" "viewlog_shadowsocksr" "set_config_shadowsocksr_main" "viewinfo_shadowsocksr" "install_libsodium" "echo 检查更新")
    echo -e "    \033[32m ShadowsocksR Server 管理脚本 (单用户) v1 \033[0m"
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
    [ -z "${function[($num - 1)]}" ] && {
        main_i
        return 1
    }
    [ $num -ne 1 ] && {
        if_noinstall_shadowsocksr
    }
    ${function[($num - 1)]}
}

# 变量声明
variable() {
    cpu_number=`cat /proc/cpuinfo | grep -c processor`
    libsodium_git="https://github.com/jedisct1/libsodium.git"
    libsodium_branch="stable"
    libsodium_dir="`mktemp -u`"
    ssr_git="https://github.com/shadowsocksrr/shadowsocksr.git"
    ssr_branch="akkariiin/dev"
    ssr_dir="/usr/local/shadowsocksr/"
    ssr_s_dir="/usr/local/shadowsocksr/shadowsocks/"
    ssr_config_file=$ssr_s_dir"config.json"
    ssr_log_file="/var/log/shadowsocksr.log"
    ssr_pid_file="/var/run/shadowsocksr.pid"
    ssr_exec="python ${ssr_s_dir}server.py"
    ssr_exec_start="$ssr_exec -c $ssr_config_file -d start --log-file $ssr_log_file --pid-file $ssr_pid_file"
    ssr_exec_stop="$ssr_exec -d stop"
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
    echo -e "   \033[34m 0. 返回 \033[0m"  
    echo
}

# 检查 ShadowsocksR 是否安装
is_install_shadowsocksr() {
    if [ -f "${ssr_dir}._ssr_" ]; then
        return 0
    else
        return 1
    fi
}

#如果 ShadowsocksR 没有安装
if_noinstall_shadowsocksr() {
    [ $ssr_install_status -ne 0 ] && {
        echo "请先安装再执行其他操作"
        exit 1
    }
}

# 安装和更新 ShadowsocksR
install_shadowsocksr() {
    if [ $ssr_install_status -ne 0 ]; then
        install_depend
        install_libsodium
        echo -e "\033[31m 开始安装 ShadowsocksR ... \033[0m"
        rm -rf $ssr_dir
        mkdir -p $ssr_dir
        cd $ssr_dir
        git clone $ssr_git --branch $ssr_branch .
        echo "shadowsocksr" > ._ssr_
        echo -e "\033[31m ShadowsocksR 安装完成, 按任意键进行初始化配置. \033[0m" 
        cat ${ssr}config.json | sed 's/\/\/.*//g' > $ssr_config_file
        variable
        read
        set_config_shadowsocksr_port 1
        set_config_shadowsocksr_passwd 1
        set_config_shadowsocksr_method 1
        set_config_shadowsocksr_protocol 1
        set_config_shadowsocksr_obfs 1
    else
        cd $ssr_dir
        git pull
    fi
    start_shadowsocksr
}

# 安装依赖
install_depend() {
    echo -e "\033[31m 开始安装所需依赖软件包... \033[0m"
    which apt-get >/dev/null 2>&1
    [ $? -eq 0 ] && {
        apt-get update
        apt-get install -y build-essential
        apt-get install -y curl git jq nano pwgen python
    }
    which yum >/dev/null 2>&1
    [ $? -eq 0 ] && {
        yum makecache
        yum install -y curl git jq nano pwgen python
        yum groupinstall -y "Development Tools"
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
    stop_shadowsocksr
    rm -rf $ssr_dir
    iptables_shadowsocksr D
    echo "ShadowsocksR 卸载完成"
}

# 检查 ShadowsocksR 是否运行
is_run_shadowsocksr() {
    if [ -f $ssr_pid_file ]; then
        return 1
    else
        return 0
    fi
}

# 如果 ShadowsocksR 没有运行
if_norun_shadowsocksr() {
    [ $ssr_run_status -eq 0 ] && {
        echo "ShadowsocksR 未运行"
        exit 2
    }
}

# 启动 ShadowsocksR
start_shadowsocksr() {
    [ $ssr_run_status -ne 0 ] && stop_shadowsocksr
    ulimit -n 512000
    $ssr_exec_start
    iptables_shadowsocksr
    viewinfo_shadowsocksr
}

# 停止 ShadowsocksR
stop_shadowsocksr() {
    if_norun_shadowsocksr
    $ssr_exec_stop
}

iptables_shadowsocksr() {
    iptables -D INPUT -p tcp --dport $ssr_config_old_port -j ACCEPT
    iptables -D OUTPUT -p tcp --sport $ssr_config_old_port -j ACCEPT
    iptables -D INPUT -p udp --dport $ssr_config_old_port -j ACCEPT
    iptables -D OUTPUT -p udp --sport $ssr_config_old_port -j ACCEPT
    [ "$1" = "D" ] && return
    local port=`jq .server_port $ssr_config_file`
    iptables -A INPUT -p tcp --dport $port -j ACCEPT
    iptables -A OUTPUT -p tcp --sport $port -j ACCEPT
    iptables -A INPUT -p udp --dport $port -j ACCEPT
    iptables -A OUTPUT -p udp --sport $port -j ACCEPT
}

# 查看 ShadwosocksR 日志
viewlog_shadowsocksr() {
    if_norun_shadowsocksr
    tail -f $ssr_log_file
}

# 修改 ShadowsocksR 配置交互式入口
set_config_shadowsocksr_main() {
    clear
    echo -e "       \033[32m 修改 ShadowsocksR 配置 \033[0m"
    echo
    local function_text=("端口" "密码" "加密方法" "协议插件" "协议插件参数" "混淆插件" "混淆插件参数" "单线程限速" "单用户限速" "日志模式" "自定义修改")
    local function=("set_config_shadowsocksr_port" "set_config_shadowsocksr_passwd" "set_config_shadowsocksr_method" "set_config_shadowsocksr_protocol" "set_config_shadowsocksr_protocol_param" "set_config_shadowsocksr_obfs" "set_config_shadowsocksr_obfs_param" "set_config_shadowsocksr_speed_con" "set_config_shadowsocksr_speed_user" "set_config_shadowsocksr_log" "set_config_customize")
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

set_config_customize() {
    clear
    nano $ssr_config_file
    [ $ssr_run_status -ne 0 ] && start_shadowsocksr
}

# 查看 ShadowsocksR 信息
viewinfo_shadowsocksr() {
    clear
    local key=("server_port" "password" "method" "protocol" "protocol_param" "obfs" "obfs_param" "speed_limit_per_con" "speed_limit_per_user")
    local key_name=("端口" "密码" "加密方法" "协议插件" "协议插件参数" "混淆插件" "混淆插件参数" "单线程限速 [KB/s]" "单用户限速 [KB/s]")
    # local value_unit=("")
    echo -e "   \033[32m ShadowsocksR Server \033[0m"
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


if [ `id -u` -eq 0 ]; then
    variable
    if [ $# -eq 1 ]; then
        main $1
    else
        main_i
    fi
else
    echo "请以 Root 用户运行"
fi
