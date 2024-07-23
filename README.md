# frpc
## 项目简介
好快Frp是一款内网穿透工具、跨平台的、轻量级的内网穿透服务，客户端小，且无需安装，解压即用。支持http(s)域名代理、tcp、udp端口转发功能。可用于远程连接、远程办公开发、游戏联机等等

基于 [fatedier/frp](https://github.com/fatedier/frp) 原版 frp 内网穿透客户端 frpc 的一键安装卸载脚本和 docker 镜像.支持群晖NAS,Linux 服务器和 docker 等多种环境安装部署.

## 使用
以下分为四种部署方法,请根据实际情况自行选择:

1. 群晖 NAS docker 安装 **[支持 docker 的群晖机型首选]**
2. 群晖 NAS 一键脚本安装 **[不支持 docker 的群晖机型]**
3. Linux 服务器 一键脚本安装 **[内网 Linux 服务器或虚拟机]**
4. Linux 服务器 docker 安装 **[内网 Linux 服务器或虚拟机]**

---
## 简易使用方法
1. Linux   一键启动 **/frpc -u 3U8yX5zDrxE -p FUYJQGTI**          / 3U8yX5zDrxE 为token码 FUYJQGTI为隧道名
2. Windows 一键启动 **frpc.exe -u 3U8yX5zDrxE -p FUYJQGTI**       / 3U8yX5zDrxE 为token码 FUYJQGTI为隧道名

### 3. Linux 服务器 一键脚本安装
> *本脚本目前同时支持 Linux X86 和 ARM 架构*

安装
```shell
wget -O hkfrp.sh https://raw.githubusercontent.com/lijund2011/hkfrpc/main/hkfrp.sh  && chmod +x  hkfrp.sh && sudo bash hkfrp.sh
```

## 链接
- 官方 [www.hkfrp.cn](https://www.hkfrp.cn)
