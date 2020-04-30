#
# Copyright (C) 2017 OpenWrt-ssr
# Copyright (C) 2017 yushi studio <ywb94@qq.com>
#
# This is free software, licensed under the GNU General Public License v3.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=openwrt-ssr
PKG_VERSION:=3.3.4
# PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/shadowsocksrr/shadowsocksr-libev
PKG_SOURCE_VERSION:=d4904568c0bd7e0861c0cbfeaa43740f404db214

PKG_SOURCE_PROTO:=git
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)

PKG_LICENSE:=GPLv3
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=Akkariiin

#PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)/$(BUILD_VARIANT)/$(PKG_NAME)-$(PKG_VERSION)

PKG_INSTALL:=1
PKG_FIXUP:=autoreconf
PKG_USE_MIPS16:=0
PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk

define Package/openwrt-ssr/Default
	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:=shadowsocksR-libev LuCI interface
	URL:=https://github.com/MrTheUniverse/openwrt-ssr
	VARIANT:=$(1)
	DEPENDS:=$(3)
endef

Package/luci-app-shadowsocksR = $(call Package/openwrt-ssr/Default,openssl,(OpenSSL),+libopenssl +libpthread +ipset +ip-full +iptables-mod-tproxy +libpcre +zlib +dnsmasq-full +coreutils +coreutils-base64 +pdnsd-alt +wget +bash +bind-dig)
Package/luci-app-shadowsocksRV = $(call Package/openwrt-ssr/Default,openssl,(OpenSSL),+libopenssl +libpthread +ipset +ip-full +iptables-mod-tproxy +libpcre +zlib +dnsmasq-full +coreutils +coreutils-base64 +pdnsd-alt +wget +bash +bind-dig +v2ray)

define Package/openwrt-ssr/description
	LuCI Support for $(1).
endef

Package/luci-app-shadowsocksR/description = $(call Package/openwrt-ssr/description,shadowsocksr-libev Client)
Package/luci-app-shadowsocksRV/description = $(call Package/openwrt-ssr/description,shadowsocksr-libev and v2ray Client)

define Package/openwrt-ssr/prerm
#!/bin/sh
# check if we are on real system
if [ -z "$${IPKG_INSTROOT}" ]; then
  echo "Removing rc.d symlink for shadowsocksr"
  /etc/init.d/shadowsocksr disable
  /etc/init.d/shadowsocksr stop
  echo "Removing firewall rule for shadowsocksr"
	uci -q batch <<-EOF >/dev/null
	delete firewall.shadowsocksr
	commit firewall
EOF
	

	sed -i '/conf-dir/d' /etc/dnsmasq.conf
	rm -f /tmp/openwrt-ssr.log
	/etc/init.d/dnsmasq restart 

fi
exit 0
endef

Package/luci-app-shadowsocksR/prerm = $(call Package/openwrt-ssr/prerm,shadowsocksr)
Package/luci-app-shadowsocksRV/prerm = $(call Package/openwrt-ssr/prerm,shadowsocksr)



define Package/openwrt-ssr/postinst
#!/bin/sh

if [ -z "$${IPKG_INSTROOT}" ]; then
	uci -q batch <<-EOF >/dev/null
		delete firewall.shadowsocksr
		set firewall.shadowsocksr=include
		set firewall.shadowsocksr.type=script
		set firewall.shadowsocksr.path=/var/etc/shadowsocksr.include
		set firewall.shadowsocksr.reload=1
		commit firewall
EOF
fi

if [ -z "$${IPKG_INSTROOT}" ]; then
	( . /etc/uci-defaults/luci-shadowsocksr ) && rm -f /etc/uci-defaults/luci-shadowsocksr
	rm -f /tmp/luci-indexcache
	chmod 755 /etc/init.d/shadowsocksr >/dev/null 2>&1
	/etc/init.d/shadowsocksr enable >/dev/null 2>&1
fi
exit 0
endef


Package/luci-app-shadowsocksR/postinst = $(call Package/openwrt-ssr/postinst,shadowsocksr)
Package/luci-app-shadowsocksRV/postinst = $(call Package/openwrt-ssr/postinst,shadowsocksr)

CONFIGURE_ARGS += --disable-documentation --disable-ssp



define Package/openwrt-ssr/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci
	cp -pR ./luci/* $(1)/usr/lib/lua/luci
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/ss-redir $(1)/usr/bin/ssr-redir
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/ss-local $(1)/usr/bin/ssr-local	
	$(LN) /usr/bin/ssr-local $(1)/usr/bin/ssr-tunnel	
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/ss-check $(1)/usr/bin/ssr-check
	$(INSTALL_DIR) $(1)/
	cp -pR ./root/* $(1)/
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	po2lmo ./po/zh-cn/shadowsocksr.zh-cn.po $(1)/usr/lib/lua/luci/i18n/shadowsocksr.zh-cn.lmo
endef

Package/luci-app-shadowsocksR/install = $(call Package/openwrt-ssr/install,$(1),shadowsocksr)
Package/luci-app-shadowsocksRV/install = $(call Package/openwrt-ssr/install,$(1),shadowsocksr)

$(eval $(call BuildPackage,luci-app-shadowsocksR))
$(eval $(call BuildPackage,luci-app-shadowsocksRV))
