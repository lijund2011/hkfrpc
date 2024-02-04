#!/usr/bin/env bash
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
FRP_NAME=frpc
FRP_VERSION=0.51.3
FRP_PATH=/usr/local/frp
PROXY_URL="https://ghproxy.com/"

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"

#安装BBR内核
installbbr(){
	kernel_version="4.11.8"
	if [[ "${release}" == "centos" ]]; then
		rpm --import http://${github}/bbr/${release}/RPM-GPG-KEY-elrepo.org
		yum install -y http://${github}/bbr/${release}/${version}/${bit}/kernel-ml-${kernel_version}.rpm
		yum remove -y kernel-headers
		yum install -y http://${github}/bbr/${release}/${version}/${bit}/kernel-ml-headers-${kernel_version}.rpm
		yum install -y http://${github}/bbr/${release}/${version}/${bit}/kernel-ml-devel-${kernel_version}.rpm
	elif [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
		mkdir bbr && cd bbr
		wget http://security.debian.org/debian-security/pool/updates/main/o/openssl/libssl1.0.0_1.0.1t-1+deb8u10_amd64.deb
		wget -N --no-check-certificate http://${github}/bbr/debian-ubuntu/linux-headers-${kernel_version}-all.deb
		wget -N --no-check-certificate http://${github}/bbr/debian-ubuntu/${bit}/linux-headers-${kernel_version}.deb
		wget -N --no-check-certificate http://${github}/bbr/debian-ubuntu/${bit}/linux-image-${kernel_version}.deb
	
		dpkg -i libssl1.0.0_1.0.1t-1+deb8u10_amd64.deb
		dpkg -i linux-headers-${kernel_version}-all.deb
		dpkg -i linux-headers-${kernel_version}.deb
		dpkg -i linux-image-${kernel_version}.deb
		cd .. && rm -rf bbr
	fi
	detele_kernel
	BBR_grub
	echo -e "${Tip} 重启VPS后，请重新运行脚本开启${Red_font_prefix}BBR/BBR魔改版${Font_color_suffix}"
	stty erase '^H' && read -p "需要重启VPS后，才能开启BBR/BBR魔改版，是否现在重启 ? [Y/n] :" yn
	[ -z "${yn}" ] && yn="y"
	if [[ $yn == [Yy] ]]; then
		echo -e "${Info} VPS 重启中..."
		reboot
	fi
}

#开始菜单
start_menu(){
clear
echo && echo -e " TCP加速 一键安装管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  -- 就是爱生活 | 94ish.me --
  
  -- Zeruns 's Blog | blog.zeruns.tech --
  
 ${Green_font_prefix}0.${Font_color_suffix} 升级脚本
————————————内核管理————————————
 ${Green_font_prefix}1.${Font_color_suffix} 安装 BBR/BBR魔改版内核
 ${Green_font_prefix}2.${Font_color_suffix} 安装 BBRplus版内核 
 ${Green_font_prefix}3.${Font_color_suffix} 安装 Lotserver(锐速)内核
————————————加速管理————————————
 ${Green_font_prefix}4.${Font_color_suffix} 使用BBR加速
 ${Green_font_prefix}5.${Font_color_suffix} 使用BBR魔改版加速
 ${Green_font_prefix}6.${Font_color_suffix} 使用暴力BBR魔改版加速(不支持部分系统)
 ${Green_font_prefix}7.${Font_color_suffix} 使用BBRplus版加速
 ${Green_font_prefix}8.${Font_color_suffix} 使用Lotserver(锐速)加速
————————————杂项管理————————————
 ${Green_font_prefix}9.${Font_color_suffix} 卸载全部加速
 ${Green_font_prefix}10.${Font_color_suffix} 系统配置优化
 ${Green_font_prefix}11.${Font_color_suffix} 退出脚本
————————————————————————————————" && echo

	check_status
	if [[ ${kernel_status} == "noinstall" ]]; then
		echo -e " 当前状态: ${Green_font_prefix}未安装${Font_color_suffix} 加速内核 ${Red_font_prefix}请先安装内核${Font_color_suffix}"
	else
		echo -e " 当前状态: ${Green_font_prefix}已安装${Font_color_suffix} ${_font_prefix}${kernel_status}${Font_color_suffix} 加速内核 , ${Green_font_prefix}${run_status}${Font_color_suffix}"
		
	fi
echo
read -p " 请输入数字 [0-11]:" num
case "$num" in
	0)
	Update_Shell
	;;
	1)
	check_sys_bbr
	;;
	2)
	check_sys_bbrplus
	;;
	3)
	check_sys_Lotsever
	;;
	4)
	startbbr
	;;
	5)
	startbbrmod
	;;
	6)
	startbbrmod_nanqinlang
	;;
	7)
	startbbrplus
	;;
	8)
	startlotserver
	;;
	9)
	remove_all
	;;
	10)
	optimizing_system
	;;
	11)
	exit 1
	;;
	*)
	clear
	echo -e "${Error}:请输入正确数字 [0-11]"
	sleep 5s
	start_menu
	;;
esac
}

#检查系统
check_sys(){
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


#检查安装bbr的系统要求
check_sys_bbr(){
	check_version
	if [[ "${release}" == "centos" ]]; then
		if [[ ${version} -ge "6" ]]; then
			installbbr
		else
			echo -e "${Error} BBR内核不支持当前系统 ${release} ${version} ${bit} !" && exit 1
		fi
	elif [[ "${release}" == "debian" ]]; then
		if [[ ${version} -ge "8" ]]; then
			installbbr
		else
			echo -e "${Error} BBR内核不支持当前系统 ${release} ${version} ${bit} !" && exit 1
		fi
	elif [[ "${release}" == "ubuntu" ]]; then
		if [[ ${version} -ge "14" ]]; then
			installbbr
		else
			echo -e "${Error} BBR内核不支持当前系统 ${release} ${version} ${bit} !" && exit 1
		fi
	else
		echo -e "${Error} BBR内核不支持当前系统 ${release} ${version} ${bit} !" && exit 1
	fi
}

check_status(){
	kernel_version=`uname -r | awk -F "-" '{print $1}'`
	kernel_version_full=`uname -r`
	if [[ ${kernel_version_full} = "4.14.129-bbrplus" ]]; then
		kernel_status="BBRplus"
	elif [[ ${kernel_version} = "3.10.0" || ${kernel_version} = "3.16.0" || ${kernel_version} = "3.2.0" || ${kernel_version} = "4.4.0" || ${kernel_version} = "3.13.0"  || ${kernel_version} = "2.6.32" || ${kernel_version} = "4.9.0" ]]; then
		kernel_status="Lotserver"
	elif [[ `echo ${kernel_version} | awk -F'.' '{print $1}'` == "4" ]] && [[ `echo ${kernel_version} | awk -F'.' '{print $2}'` -ge 9 ]] || [[ `echo ${kernel_version} | awk -F'.' '{print $1}'` == "5" ]]; then
		kernel_status="BBR"
	else 
		kernel_status="noinstall"
	fi

	if [[ ${kernel_status} == "Lotserver" ]]; then
		if [[ -e /appex/bin/lotServer.sh ]]; then
			run_status=`bash /appex/bin/lotServer.sh status | grep "LotServer" | awk  '{print $3}'`
			if [[ ${run_status} = "running!" ]]; then
				run_status="启动成功"
			else 
				run_status="启动失败"
			fi
		else 
			run_status="未安装加速模块"
		fi
	elif [[ ${kernel_status} == "BBR" ]]; then
		run_status=`grep "net.ipv4.tcp_congestion_control" /etc/sysctl.conf | awk -F "=" '{print $2}'`
		if [[ ${run_status} == "bbr" ]]; then
			run_status=`lsmod | grep "bbr" | awk '{print $1}'`
			if [[ ${run_status} == "tcp_bbr" ]]; then
				run_status="BBR启动成功"
			else 
				run_status="BBR启动失败"
			fi
		elif [[ ${run_status} == "tsunami" ]]; then
			run_status=`lsmod | grep "tsunami" | awk '{print $1}'`
			if [[ ${run_status} == "tcp_tsunami" ]]; then
				run_status="BBR魔改版启动成功"
			else 
				run_status="BBR魔改版启动失败"
			fi
		elif [[ ${run_status} == "nanqinlang" ]]; then
			run_status=`lsmod | grep "nanqinlang" | awk '{print $1}'`
			if [[ ${run_status} == "tcp_nanqinlang" ]]; then
				run_status="暴力BBR魔改版启动成功"
			else 
				run_status="暴力BBR魔改版启动失败"
			fi
		else 
			run_status="未安装加速模块"
		fi
	elif [[ ${kernel_status} == "BBRplus" ]]; then
		run_status=`grep "net.ipv4.tcp_congestion_control" /etc/sysctl.conf | awk -F "=" '{print $2}'`
		if [[ ${run_status} == "bbrplus" ]]; then
			run_status=`lsmod | grep "bbrplus" | awk '{print $1}'`
			if [[ ${run_status} == "tcp_bbrplus" ]]; then
				run_status="BBRplus启动成功"
			else 
				run_status="BBRplus启动失败"
			fi
		else 
			run_status="未安装加速模块"
		fi
	fi
}

#############系统检测组件#############
check_sys
#check_version
#[[ ${release} != "debian" ]] && [[ ${release} != "ubuntu" ]] && [[ ${release} != "centos" ]] && echo -e "${Error} 本脚本不支持当前系统 ${release} !" && exit 1
start_menu

