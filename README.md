# shadowsocksr-shell-manage
这是一个可以快速管理/控制 [ShadowsocksR][shadowsocksr] 的 Bash Shell 脚本  

它为 ShadowsocksR 提供以下功能：  
* 安装/卸载/更新
* 启动/停止/重启
* 查看日志
* 修改配置 包括：端口、密码、加密、协议、混淆 等等...
* 多用户支持（正在开发中...）

而脚本自身有以下特性：  
* 命令式和交互式界面随意选择
* 方便的二次开发
* 多系统支持 目前支持：CentOS、Debian/Ubuntu 计划支持：openSUSE

如何使用？
---
首先下载脚本，执行以下命令：  

#### CentOS :
```
sudo yum makecache
sudo yum install wget
wget https://raw.githubusercontent.com/Hill-98/shadowsocksr-shell-manage/master/single-user.sh -O ssr-manage.sh
chmod +x ssr-manage.sh
./ssr-manage.sh
```
#### Debian/Ubuntu :  
```
sudo apt-get update
sudo apt-get install wget
wget https://raw.githubusercontent.com/Hill-98/shadowsocksr-shell-manage/master/single-user.sh -O ssr-manage.sh
chmod +x ssr-manage.sh
./ssr-manage.sh
```

选择 `安装/更新 ShadowsocksR`

根据提示进行安装即可

输入`./ssr-manage.sh help` 查看命令式使用帮助

---

### 脚本功能需要改进或者有问题 请直接提交 [issues](https://github.com/Hill-98/shadowsocksr-shell-manage/issues)

[shadowsocksr]: https://github.com/shadowsocksrr/shadowsocksr
