#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS 6/7,Debian 8/9,Ubuntu 16+
#	Description: 好快FRP内网穿透
#	Version: 0.51.3
#	Author: hkfrp
#	Blog: https://www.hkfrp.cn/
#=================================================

# fonts color
Green="\033[32m"
Red="\033[31m"
Yellow="\033[33m"
GreenBG="\033[42;37m"
RedBG="\033[41;37m"
Font="\033[0m"
# fonts color

# variable
WORK_PATH=$(dirname $(readlink -f $0))
FRP_TITLE=好快FRP内网穿透
FRP_NAME=frpc
FRPV_VERSION=0.51.3
FRP_PATH=/usr/local/frp
PROXY_URL="https://mirror.ghproxy.com/"
if [ -f ${FRP_PATH}/${FRP_NAME} ]; then
FRP_VERSION=$(cd ${FRP_PATH} && ./${FRP_NAME} -v)
fi
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"

colorEcho() {
    echo -e "${1}${@:2}${Font_color_suffix}"
}
# check pkg
if type apt-get >/dev/null 2>&1 ; then
    if ! type wget >/dev/null 2>&1 ; then
        apt-get install wget -y
    fi
    if ! type curl >/dev/null 2>&1 ; then
        apt-get install curl -y
    fi
fi

if type yum >/dev/null 2>&1 ; then
    if ! type wget >/dev/null 2>&1 ; then
        yum install wget -y
    fi
    if ! type curl >/dev/null 2>&1 ; then
        yum install curl -y
    fi
fi

#安装frpc
install(){
echo -e "${Info} ${Red_font_prefix}正在连接服务器...${Font_color_suffix}"
check_frpc
# check network
GOOGLE_HTTP_CODE=$(curl -o /dev/null --connect-timeout 5 --max-time 8 -s --head -w "%{http_code}" "https://www.google.com")
PROXY_HTTP_CODE=$(curl -o /dev/null --connect-timeout 5 --max-time 8 -s --head -w "%{http_code}" "${PROXY_URL}")
FILE_NAME=frp_${FRP_VERSION}_linux_${PLATFORM}
# download
if [ $GOOGLE_HTTP_CODE == "200" ]; then
echo -e "${Info} ${Red_font_prefix}开始下载 FRPC客服端...${Font_color_suffix}"
    wget -q --show-progress ${WORK_PATH} https://github.com/fatedier/frp/releases/download/v${FRP_VERSION}/${FILE_NAME}.tar.gz -O ${FILE_NAME}.tar.gz
else
    if [ $PROXY_HTTP_CODE == "200" ]; then
	echo -e "${Info} ${Red_font_prefix}正在使用代理下载 FRPC客服端${Font_color_suffix}"
        wget -q --show-progress ${WORK_PATH} ${PROXY_URL}https://github.com/fatedier/frp/releases/download/v${FRP_VERSION}/${FILE_NAME}.tar.gz -O ${FILE_NAME}.tar.gz
    else
        echo -e "${Red}检测 GitHub Proxy 代理失效 开始使用官方地址下载${Font}"
        wget -q --show-progress ${WORK_PATH} https://github.com/fatedier/frp/releases/download/v${FRP_VERSION}/${FILE_NAME}.tar.gz -O ${FILE_NAME}.tar.gz
    fi
fi
# 显示解压过程 xzvf 不显示解压过程 xzf
echo -e "${Info} ${Red_font_prefix}正在安装 FRPC客服端...${Font_color_suffix}"
tar -xzf ${FILE_NAME}.tar.gz

mkdir -p ${FRP_PATH}
mv ${FILE_NAME}/${FRP_NAME} ${FRP_PATH}
chmod -R 755 ${FRP_PATH}
#chmod -R 755 ${FRP_PATH}/${FRP_NAME}
# 删除没用文件
rm -rf ${WORK_PATH}/${FILE_NAME}.tar.gz ${WORK_PATH}/${FILE_NAME}
	echo -e "${Tip} ${Red_font_prefix}安装成功，需要配置文件才能正常启动${Font_color_suffix}"
	read -p "$(echo -e ${Info}${Green_font_prefix}) 是否进行文件配置？[y/n]：$(echo -e ${Font_color_suffix})" answer
    if [[ "${answer,,}" = "y" ]]; then
		set_token
	elif [[ "${answer,,}" = "n" ]]; then
	    start_menu
	else
    	set_token
    fi
}

#检查frpc
check_frpc(){
if [ -f "/usr/local/frp/${FRP_NAME}" ] || [ -f "/usr/local/frp/${FRP_NAME}.ini" ] || [ -f "/etc/systemd/system/${FRP_NAME}.service" ];then
    echo -e "${Green}=========================================================================${Font}"
    echo -e "${RedBG}${FRP_TITLE}已安装.${Font}"
    echo -e "${Green}检查到服务器已安装${Font} ${Red}${FRP_NAME}${Font}"
    echo -e "${Green}请手动确认和删除${Font} ${Red}/usr/local/frp/${Font} ${Green}目录下的${Font} ${Red}${FRP_NAME}${Font} ${Green}和${Font} ${Red}/${FRP_NAME}.ini${Font} ${Green}文件以及${Font} ${Red}/etc/systemd/system/${FRP_NAME}.service${Font} ${Green}文件,再次执行本脚本.${Font}"
    echo -e "${Green}参考命令如下:${Font}"
    echo -e "${Red}rm -rf /usr/local/frp/${FRP_NAME}${Font}"
    echo -e "${Red}rm -rf /usr/local/frp/${FRP_NAME}.ini${Font}"
    echo -e "${Red}rm -rf /etc/systemd/system/${FRP_NAME}.service${Font}"
    echo -e "${Green}=========================================================================${Font}"
	is_fail=1
    #exit 0
fi
    [[ $is_fail ]] && {
        exit_and_del_tmpdir
    }
}

#卸载判断
exit_and_del_tmpdir(){
echo -e "${Tip} ${Red_font_prefix}${FRP_TITLE}已安装${Font_color_suffix}"
	stty erase '^H' && read -p "$(echo -e ${Info}${Green_font_prefix}) 卸载按【y】|进入菜单按【n】 ? [Y/n] :$(echo -e ${Font_color_suffix})" yn
	[ -z "${yn}" ] && yn="y"
	if [[ $yn == [Yy] ]]; then
	   while ! test -z "$(ps -A | grep -w ${FRP_NAME})"; do
		  FRPCPID=$(ps -A | grep -w ${FRP_NAME} | awk 'NR==1 {print $1}')
		  [[ $FRPCPID ]] && {
            kill -9 $FRPCPID
		  }
	   done
		echo -e "${Info} ${Red_font_prefix}正在卸载${FRP_NAME}...${Font_color_suffix}"
		uninstall
	else
    	start_menu
	fi
}

#卸载
uninstall(){
	# 停止frpc
sudo systemctl stop ${FRP_NAME} >/dev/null 2>&1
sudo systemctl disable ${FRP_NAME} >/dev/null 2>&1
# 删除frpc
rm -rf ${FRP_PATH}
# 删除frpc.service
rm -rf /etc/systemd/system/${FRP_NAME}.service
sudo systemctl daemon-reload >/dev/null 2>&1
frpc_status="noinstall"
is_fail=""
# 删除本文件
#rm -rf ${FRP_NAME}_linux_uninstall.sh

echo -e "${Green}============================${Font}"
echo -e "${Green}卸载成功,相关文件已清理完毕!${Font}"
echo -e "${Green}============================${Font}"
sleep 2s
start_menu
}

#检查架构
check_framework(){
	if [ $(uname -m) = "x86_64" ]; then
		PLATFORM=amd64
	elif [ $(uname -m) = "aarch64" ]; then
		PLATFORM=arm64
	elif [ $(uname -m) = "armv7" ]; then
		PLATFORM=arm
	elif [ $(uname -m) = "armv7l" ]; then
		PLATFORM=arm
	elif [ $(uname -m) = "armhf" ]; then
		PLATFORM=arm
	fi
}

#检查系统
check_sys(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi
}

#开始菜单
start_menu(){
clear
if [[ ${FRP_VERSION} ]]; then
		FRPC_VERSION="版本:v${FRP_VERSION}"
	else
		FRPC_VERSION="未安装"
		FRP_VERSION=${FRPV_VERSION}
	fi
echo && echo -e " 
 ${Green_font_prefix}${FRP_TITLE}${Font_color_suffix} ${Red_font_prefix} ${FRPC_VERSION}${Font_color_suffix}
 ${Green_font_prefix}网址${Font_color_suffix}: https://www.hkfrp.cn
 ${Green_font_prefix}Q  Q${Font_color_suffix}: 88790363
 ${Green_font_prefix}W  X${Font_color_suffix}: fz88790363
${Red_font_prefix}————安装配置客服端————${Font_color_suffix}
 ${Green_font_prefix}1.${Font_color_suffix} 安装 FRPC客服端
 ${Green_font_prefix}2.${Font_color_suffix} 安装 配置 文件 
 ${Green_font_prefix}3.${Font_color_suffix} 编辑 配置 文件
${Red_font_prefix}——————FRPC客服端——————${Font_color_suffix}
 ${Green_font_prefix}4.${Font_color_suffix} 启动 FRPC客服端
 ${Green_font_prefix}5.${Font_color_suffix} 重启 FRPC客服端
 ${Green_font_prefix}6.${Font_color_suffix} 停止 FRPC客服端
———————————————————————
 ${Green_font_prefix}7.${Font_color_suffix} ${Red_font_prefix}卸载FRPC${Font_color_suffix}
 ${Green_font_prefix}8.${Font_color_suffix} ${Red_font_prefix}检测更新${Font_color_suffix}
 ${Green_font_prefix}0.${Font_color_suffix} ${Red_font_prefix}退出脚本${Font_color_suffix}
———————————————————————" && echo
	check_status
	if [[ ${frpc_status} == "yesinstall" ]]; then
		echo -e " 当前状态: ${Green_font_prefix}已安装${Font_color_suffix} ${frpcini_status} 客服端状态: ${is_fail_status}"
	else
		echo -e " 当前状态: ${Red_font_prefix}未安装FRPC客服端，请输入[${Green_font_prefix}1${Font_color_suffix}${Red_font_prefix}]安装${Font_color_suffix}${Font_color_suffix}"
	fi
echo
read -p "$(echo -e ${Info}${Green_font_prefix}) 请输入数字 [0-8]:$(echo -e ${Font_color_suffix})" num
case "$num" in
	0)
	exit 1
	;;
	1)
	install
	;;
	2)
	set_token
	;;
	3)
	frpc_edit
	;;
	4)
	frpc_start
	;;
	5)
	frpc_nohup
	;;
	6)
	frpc_stop
	;;
	7)
	read -p "$(echo -e ${Info}${Green_font_prefix}) 确定是否卸载？[y/n]：$(echo -e ${Font_color_suffix})" answer
    if [[ "${answer,,}" = "y" ]]; then
	echo -e "${Info} ${Red_font_prefix}正在卸载${FRP_NAME}...${Font_color_suffix}"
	uninstall
	fi
	start_menu
	;;
	8)
	frpc_upgrade
	;;
	*)
	clear
	echo -e "${Error}:请输入正确数字 [0-8]"
	sleep 5s
	start_menu
	;;
esac
}

#检测
check_status(){
	if [ -f "/usr/local/frp/${FRP_NAME}" ] || [ -f "/etc/systemd/system/${FRP_NAME}.service" ];then
		frpc_status="yesinstall"
	fi
	if [ ! -f "/usr/local/frp/${FRP_NAME}.ini" ];then
	    while ! test -z "$(ps -A | grep -w ${FRP_NAME})"; do
        FRPCPID=$(ps -A | grep -w ${FRP_NAME} | awk 'NR==1 {print $1}')
		[[ $FRPCPID ]] && {
            kill -9 $FRPCPID
			sudo systemctl stop ${FRP_NAME} >/dev/null 2>&1
		}
	done
		frpcini_status="${Red_font_prefix}未配置文件${Font_color_suffix}"
	else
		frpcini_status=""
	fi
	# 判断检测frp客户端进程是否存在，小于或者等于1就有问题
	checkfrpc=`ps -aux | grep -w ${FRP_NAME} | wc -l`
	if [ $checkfrpc == 2 ] || [ $checkfrpc == 4 ];then
		is_fail_status="${Green_font_prefix}已启动${Font_color_suffix}"
	else	
		is_fail_status="${Red_font_prefix}未启动${Font_color_suffix}"
	fi
}

#安装 配置 文件
set_token(){
    check_status
    if [[ ${frpc_status} == "yesinstall" ]]; then
	get_value=""
	echo -e "${Info} 输入[${Red_font_prefix}no${Font_color_suffix}]返回菜单"
	echo -e "${Info} 格式为：用户token 隧道名称，例：e3U8yXwzDraEWRuK eIIPVfYL"
	read -e -p "$(echo -e ${Info}${Green_font_prefix}) 请输入：$(echo -e ${Font_color_suffix})" get_value
	[[ -z ${get_value} ]] && get_value="none"
	if [ "${get_value}" = "none" ];then
	set_token
	elif [[ ${get_value} == "no" ]]; then
	start_menu
	else
	check_Configuration ${get_value}
	fi
	else
		echo -e " ${Error} ${Red_font_prefix}未安装FRPC客服端，请先安装FRPC客服端${Font_color_suffix}"
		sleep 4s
	start_menu
	fi
}

#检查Configuration
check_Configuration(){
url="https://www.hkfrp.cn/api/ajax?id=$2&user=$1"
if [ -n "$(curl ${url})" ]; then 
touch ${FRP_PATH}/${FRP_NAME}.ini
chmod -R 755 ${FRP_PATH}/${FRP_NAME}.ini
curl ${url} > ${FRP_PATH}/${FRP_NAME}.ini
# configure systemd
cat >/etc/systemd/system/${FRP_NAME}.service <<EOF
[Unit]
Description=Frp Server Service
After=network.target syslog.target
Wants=network.target

[Service]
Type=simple
User=root
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/frp/${FRP_NAME} -c /usr/local/frp/${FRP_NAME}.ini

[Install]
WantedBy=multi-user.target
EOF
chown root:root /etc/systemd/system/${FRP_NAME}.service
chmod -R 755 /etc/systemd/system/${FRP_NAME}.service
#sudo systemctl daemon-reload >/dev/null 2>&1
sudo systemctl start ${FRP_NAME} >/dev/null 2>&1
sudo systemctl enable ${FRP_NAME} >/dev/null 2>&1
#sudo systemctl restart ${FRP_NAME} >/dev/null 2>&1
colorEcho ${Info} "${Green_font_prefix} FRPC已启动"
sleep 4s
start_menu
else 
echo -e "${Error} ${Red_font_prefix}用户token 或者隧道名称错误，请检查是否正确！${Font_color_suffix}"; 
fi
set_token
}

#启动 FRPC客服端
frpc_start(){
check_status
    if [[ ${frpc_status} != "yesinstall" ]]; then
	echo -e " ${Error} ${Red_font_prefix}未安装FRPC客服端，请先安装FRPC客服端${Font_color_suffix}"
	sleep 4s
	start_menu
	fi
	# 判断检测frp客户端进程是否存在，小于或者等于1就有问题
	checkfrpc=`ps -aux | grep -w ${FRP_NAME} | wc -l`
	if [ $checkfrpc == 2 ] || [ $checkfrpc == 4 ];then
		echo -e "${Info} ${Red_font_prefix}已启动${Font_color_suffix}"
		sleep 3s
		start_menu
	else	
		sudo systemctl start ${FRP_NAME} >/dev/null 2>&1
		echo -e "${Info} FEPC启动中...."
		sleep 3s
		start_menu
	fi
}

#停止 FRPC客服端
frpc_stop(){
    # 判断检测frp客户端进程是否存在，小于或者等于1就有问题
	checkfrpc=`ps -aux | grep -w ${FRP_NAME} | wc -l`
	if [ $checkfrpc == 1 ] || [ $checkfrpc == 3 ];then
	echo -e "${Info} ${Red_font_prefix}未启动，无法停止${Font_color_suffix}"
	sleep 3s
	start_menu
	else	
	while ! test -z "$(ps -A | grep -w ${FRP_NAME})"; do
        FRPCPID=$(ps -A | grep -w ${FRP_NAME} | awk 'NR==1 {print $1}')
        [[ $FRPCPID ]] && {
            kill -9 $FRPCPID
			sudo systemctl stop ${FRP_NAME} >/dev/null 2>&1
		}
	done
	echo -e "${Info} FEPC停止中...."
	sleep 3s
	start_menu
	fi
}

Edit_2() {
    read -p "$(echo -e ${Info}${Green_font_prefix}) 请选择编辑器 1 (vim) 或 2 (nano)：$(echo -e ${Font_color_suffix})" answer
    if   [[ "${answer,,}" = "1" ]]; then
        vim /usr/local/frp/${FRP_NAME}.ini
    elif [[ "${answer,,}" = "2" ]]; then
        nano /usr/local/frp/${FRP_NAME}.ini
    fi
}

#编辑 配置 文件
frpc_edit(){
check_status
if [[ ${frpc_status} == "yesinstall" ]]; then
    if [ ! -f "/usr/local/frp/${FRP_NAME}.ini" ];then
	    colorEcho ${Error} "${Red_font_prefix}未发现配置文件，请先安装 配置文件${Font_color_suffix}"
		exit 1
	fi
	echo -e "${Tip} ${Red_font_prefix}进入编辑配置文件后，先按[i]进入编辑模式修改，然后按[Esc]键，在输入[:wq]进行保存,最后重启FRPC客服端${Font_color_suffix}"
	stty erase '^H' && read -p "$(echo -e ${Info}${Green_font_prefix}) 是否进入编辑配置文件? [Y/n] :$(echo -e ${Font_color_suffix})" yn
	[ -z "${yn}" ] && yn="y"
	if [[ $yn == [Yy] ]]; then
		sudo vim /usr/local/frp/${FRP_NAME}.ini
		colorEcho ${Green_font_prefix}  "编辑成功"
		read -p "$(echo -e ${Info}${Green_font_prefix}) 是否重启FRPC客服端？[y/n]：$(echo -e ${Font_color_suffix})" answer
    if [[ "${answer,,}" = "y" ]]; then
        sudo systemctl restart ${FRP_NAME} >/dev/null 2>&1
		colorEcho ${Green_font_prefix}  "已重启FRPC"
		start_menu
	else
    	start_menu
    fi
	else
    	start_menu
	fi
else
	echo -e " ${Error} ${Red_font_prefix}未安装FRPC客服端，请先安装FRPC客服端${Font_color_suffix}"
	sleep 4s
	start_menu
	fi	
}

#重启 FRPC客服端
frpc_nohup(){
check_status
    if [[ ${frpc_status} == "yesinstall" ]]; then
	sudo systemctl restart ${FRP_NAME} >/dev/null 2>&1
	echo -e "${Info} FEPC重启中...."
	sleep 3s
	start_menu
	else
		echo -e " ${Error} ${Red_font_prefix}未安装FRPC客服端，请先安装FRPC客服端${Font_color_suffix}"
		sleep 4s
	start_menu
	fi
}

#检测更新
frpc_upgrade() {
    echo -e "${Info} ${Red_font_prefix}正在检测新版本...${Font_color_suffix}"
    API="https://api.github.com/repos/fatedier/frp/releases/latest"
    VER=`curl -s "${API}" --connect-timeout 10| grep -Eo '\"tag_name\"(.*?)\",' | cut -d\" -f4 | cut -d v -f2`
    if [[ ${VER} == ${FRP_VERSION} ]]; then
        echo -e "${Info} ${Green_font_prefix}未发现新版本${Font_color_suffix}"
        sleep 3s
        start_menu
    else
	echo -e "${Info} ${Green_font_prefix}发现新版本：v${VER}${Font_color_suffix}"
	read -p "$(echo -e ${Info}${Green_font_prefix}) 是否升级[y/n]：$(echo -e ${Font_color_suffix})" answer
    if [[ "${answer,,}" = "y" ]]; then
	    check_upgrade
        echo -e "${Info} ${Green_font_prefix}更新成功${Font_color_suffix}"
		sudo systemctl restart ${FRP_NAME} >/dev/null 2>&1
	else
	start_menu
    fi
	fi
}

check_upgrade() {
echo -e "${Info} ${Red_font_prefix}正在连接服务器...${Font_color_suffix}"
# check network
GOOGLE_HTTP_CODE=$(curl -o /dev/null --connect-timeout 5 --max-time 8 -s --head -w "%{http_code}" "https://www.google.com")
PROXY_HTTP_CODE=$(curl -o /dev/null --connect-timeout 5 --max-time 8 -s --head -w "%{http_code}" "${PROXY_URL}")
FILE_NAMEG=frp_${VER}_linux_${PLATFORM}
# download
if [ $GOOGLE_HTTP_CODE == "200" ]; then
echo -e "${Info} ${Red_font_prefix}开始下载 FRPC客服端...${Font_color_suffix}"
    wget -t 0 -c -q --show-progress ${WORK_PATH} https://github.com/fatedier/frp/releases/download/v${VER}/${FILE_NAMEG}.tar.gz -O ${FILE_NAMEG}.tar.gz
else
    if [ $PROXY_HTTP_CODE == "200" ]; then
	echo -e "${Info} ${Red_font_prefix}正在使用代理下载 FRPC客服端${Font_color_suffix}"
        wget -t 0 -c -q --show-progress ${WORK_PATH} ${PROXY_URL}https://github.com/fatedier/frp/releases/download/v${VER}/${FILE_NAMEG}.tar.gz -O ${FILE_NAMEG}.tar.gz
    else
        echo -e "${Red}检测 GitHub Proxy 代理失效 开始使用官方地址下载${Font}"
        wget -t 0 -c -q --show-progress ${WORK_PATH} https://github.com/fatedier/frp/releases/download/v${VER}/${FILE_NAMEG}.tar.gz -O ${FILE_NAMEG}.tar.gz
    fi
fi
# 显示解压过程 xzvf 不显示解压过程 xzf
echo -e "${Info} ${Red_font_prefix}下载完成...${Font_color_suffix}"
echo -e "${Info} ${Red_font_prefix}正在更新 FRPC客服端...${Font_color_suffix}"
tar -xzf ${FILE_NAMEG}.tar.gz

mkdir -p ${FRP_PATH}
mv ${FILE_NAMEG}/${FRP_NAME} ${FRP_PATH}
chmod -R 755 ${FRP_PATH}/${FRP_NAME}
# 删除没用文件
rm -rf ${WORK_PATH}/${FILE_NAMEG}.tar.gz ${WORK_PATH}/${FILE_NAMEG}
}

#############系统检测组件#############
#check_sys
check_framework
#[[ ${release} != "debian" ]] && [[ ${release} != "ubuntu" ]] && [[ ${release} != "centos" ]] && echo -e "${Error} 本脚本不支持当前系统 ${release} !" && exit 1
start_menu
