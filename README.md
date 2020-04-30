ShadowsocksR-libev for OpenWrt
===

简介
---

 本项目是 [shadowsocksr-libev][1] 和 V2Ray (可选) 在 OpenWrt 上的移植  

 各平台预编译IPK请在本项目releases页面下载

特性
---

软件包包含 [shadowsocksr-libev][1] 的可执行文件,以及luci控制界面  

支持SSR客户端模式

支持SOCK5代理；支持UDP中继；支持广告屏蔽

支持GFW列表模式（GFWList）

所有进程自动守护，崩溃后自动重启；支持服务器自动切换；

集成[KcpTun加速][4]，此功能对路由器性能要求较高，需下载对应的二进制文件到路由器指定目录，请酌情使用

客户端兼容运行SS或SSR的服务器，使用SS服务器时，传输协议需设置为origin，混淆插件需设置为plain

支持 ssr:// url格式导入和导出服务器配置信息

支持服务器订阅功能

运行模式介绍
---

【GFW列表模式】

- 只有在GFW列表中的网站走代理；其他都不走代理；
- 黑名单模式：缺省都不走代理，列表中网站走代理

优点：目标明确，只有访问列表中网站才会损耗SSR服务器流量

缺点：GFW列表并不能100%涵盖被墙站点，而且有些国外站点直连速度远不如走代理（可通过自定义黑名单添补）

编译
---

- 从 OpenWrt 的 [SDK][S] 编译（编译环境：Ubuntu 64位系统），如果是第一次编译，还需下载OpenWrt所需依赖软件

   ```bash
   sudo apt-get install gawk libncurses5-dev libz-dev zlib1g-dev  git ccache
   ```

- 下载路由器对应平台的SDK

   ```bash
   # 以 ar71xx 平台为例
   tar xjf OpenWrt-SDK-15.05-ar71xx-generic_gcc-4.8-linaro_uClibc-0.9.33.2.Linux-x86_64.tar.bz2
   cd OpenWrt-SDK-*
   # 安装 feeds
   ./scripts/feeds update packages
   ./scripts/feeds install libpcre
   # 获取 Makefile
   git clone https://github.com/MrTheUniverse/openwrt-ssr.git package/openwrt-ssr
   # 选择要编译的包
   #luci ->3. Applications-> luci-app-shadowsocksR         原始版本
   #luci ->3. Applications-> luci-app-shadowsocksRV        V2Ray版本
   #V3.3以后版本取消发布单独的IP路由模式，只发布GFWList版本
   make menuconfig

   # 开始编译
  make package/openwrt-ssr/compile V=99
   ```

- Pandorabox(潘多拉)编译补充

  潘多拉也是Openwrt的另一个定制版本，用18.10版本的SDK编译时无法使用feed获取安装包，需要先将libpcre、zlib、libopenssl等makefile放入SDK的package目录，再make menuconfig

  这三个包的makefile可以从[这里下载][8]

安装
---

本软件包依赖库：libopenssl、libpthread、ipset、ip、iptables-mod-tproxy、libpcre，GFW版本还需依赖dnsmasq-full、coreutils-base64，opkg会自动安装上述库文件

软件编译后可生成两个软件包，分别是luci-app-shadowsocksR（原始版本）、luci-app-shadowsocksRV（兼容V2Ray版本），用户根据需要选择其中一个安装即可

原始版本只支持SSR和老版本的SS，luci-app-shadowsocksRV兼容V2Ray的vmess协议

提醒：如果安装本软件，请停用当前针对域名污染的其他处理软件，不要占用UDP 5353端口

将编译成功的luci-app-shadowsocksR*_*.ipk通过winscp上传到路由器的/tmp目录，执行命令：

   ```bash
   #刷新opkg列表
   opkg update

   #安装软件包
   opkg install /tmp/luci-app-shadowsocksR*_*.ipk
   ```

如要启用KcpTun，需从本项目releases页面或相关网站（[网站1][4]、[网站2][7]）下载路由器平台对应的二进制文件，并将文件名改为ssr-kcptun，放入/usr/bin目录

安装后强烈建议重启路由器，因为luci有缓存机制，在升级或新装IPK后，如不重启有时会出现一些莫名其妙的问题；另GFW版本会安装、修改、调用dnsmasq-full，安装后最好能重启路由器

配置
---

   软件包通过luci配置， 支持的配置项如下:  

   客户端服务器配置：

   键名           | 数据类型   | 说明
   ---------------|------------|-----------------------------------------------
   auth_enable    | 布尔型     | 一次验证开关[0.关闭 1.开启],需要服务端同时支持
   switch_enable  | 布尔型     | 此服务器是否可以自动切换
   server         | 主机类型   | 服务器地址, 可以是 IP 或者域名，推荐使用IP地址
   server_port    | 数值       | 服务器端口号, 小于 65535
   local_port     | 数值       | 本地绑定的端口号, 小于 65535
   timeout        | 数值       | 超时时间（秒）, 默认 60
   password       | 字符串     | 服务端设置的密码
   encrypt_method | 字符串     | 加密方式, [详情参考][2]
   protocol       | 字符串     | 传输协议，默认"origin"[详情参考][3]
   protocol_param | 字符串     | 传输协议插件参数(可选)
   obfs           | 字符串     | 混淆插件，默认"plain" [详情参考][3]
   obfs_param     | 字符串     | 混淆插件参数 [详情参考][3]
   fast_open      | 布尔型     | TCP快速打开 [详情参考][3]
   kcp_enable     | 布尔型     | KcpTun开启开关
   kcp_port       | 数值       | KcpTun服务器端口号, 小于 65535
   kcp_password   | 字符串     | KcpTun密码，留空表示"it's a secrect"
   kcp_param      | 字符串     | KcpTun参数[详情参考][4]

   客户端其他配置：

   名称                        | 含义
   ----------------------------|-----------------------------------------------------------
   全局服务器                  | 选择要连接的SSR TCP代理服务器
   UDP中继服务器               | 选择要连接的SSR UDP代理服务器
   启用进程监控                | 启用后可对所有进程进行监控，发现崩溃自动重启
   启用自动切换                | 启用后如果缺省代理服务器失效，可以自动切换到其他可用的代理服务器
   自动切换检查周期            | 检查当前代理服务器是否有效的时间周期，默认10分钟（600秒）
   切换检查超时时间            | 检查服务器端口或网络连通性的超时时间，默认3秒钟
   DNS解析方式                 | 用UDP隧道方式还是Pdnsd方式（TCP）来解析域名
   启用隧道（DNS）转发         | 开启DNS隧道
   DNS服务器地址和端口         | DNS请求转发的服务器，一般设置为google的dns地址
   SOCKS5代理-服务器           | 用于SOCKS代理的SSR服务器
   SOCKS5代理-本地端口         | 用于SOCKS代理的本地端口（注意此端口不能和SSR服务器配置中的本地端口相同）
   访问控制-被忽略IP列表       | IP路由模式时有效，用于指定存放国内IP网段的文件，这些网段不经过代理
   访问控制-额外被忽略IP       | IP路由模式时有效，用于添加额外的不经过代理的目的IP地址
   访问控制-强制走代理IP       | 用于添加需要经过代理的目的IP地址
   路由器访问控制              | 用于控制路由器本身是否走代理，适用于路由器挂载BT下载的情况
   内网访问控制                | 可以控制内网中哪些IP能走代理，哪些不能走代理，可以指定下面列表内或列表外IP
   内网主机列表                | 内网IP列表，可以指定多个

   在某些openwrt上的kcptun启用压缩后存在问题，因此在界面上加上了“--nocomp”参数，缺省为非压缩，请在服务端也使用非压缩模式

   如要打开kcptun的日志，可以在kcptun参数栏填入"--nocomp --log /var/log/kcptun.log"，日志会保存在指定文件中

   自动切换说明：在服务器配置中如果某些服务器启用了自动切换开关，这些服务器就组成一个可以自动切换的服务器集合，当这些服务器中的某一个作为全局服务器使用，并打开了全局自动切换开关时，如果全局服务器故障，会自动在集合中寻找可用的服务器进行切换。你可以设置检测周期和超时时间。每次检测时会判断缺省服务器是否恢复正常，如果正常，会自动切换回缺省服务器。注：自动切换功能依赖路由器的检测，因此在“路由器访问控制”中应该设置为“正常代理”

   自动切换和进程监控的日志可以在OpenWRT的“系统日志”中查看

   缺省使用pdnsd以TCP方式解析域名，也可使用DNS隧道转发，但要求SS/SSR服务器支持UDP转发。官方openssl的ipk在编译时去除了camellia和idea加密算法，如果使用官方的libopenssl，将无法使用这两种加密方式，如需使用，请重新编译openssl进行替换

问题和建议反馈
---

请点击本页面上的“Issues”反馈使用问题或建议

截图
---

服务端页面：

![luci000](https://github.com/MrTheUniverse/openwrt-ssr/blob/master/Img/servers.png)

客户端页面：

![luci000](https://github.com/MrTheUniverse/openwrt-ssr/blob/master/Img/client.png)

状态页面：

![luci000](https://github.com/MrTheUniverse/openwrt-ssr/blob/master/Img/status.png)

自定义黑名单页面：

![luci000](https://github.com/MrTheUniverse/openwrt-ssr/blob/master/Img/custom_list.png)

  [1]: https://github.com/breakwa11/shadowsocks-libev
  [2]: https://github.com/shadowsocks/luci-app-shadowsocks/wiki/Encrypt-method
  [3]: https://github.com/breakwa11/shadowsocks-rss/wiki/config.json
  [4]: https://github.com/xtaci/kcptun
  [5]: https://github.com/shadowsocks/openwrt-shadowsocks
  [6]: https://github.com/shadowsocks/luci-app-shadowsocks  
  [7]: https://github.com/bettermanbao/openwrt-kcptun/releases
  [8]: http://iytc.net/tools/pand.rar
  [S]: https://wiki.openwrt.org/doc/howto/obtain.firmware.sdk
