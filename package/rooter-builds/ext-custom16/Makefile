#Owned by DairyMan@Whirlpool
#
#Copyright GNU act.
include $(TOPDIR)/rules.mk

PKG_NAME:=ext-custom16
PKG_VERSION:=1.000
PKG_RELEASE:=1

PKG_MAINTAINER:=Created by DM/makefile by Cobia@whirlpool
include $(INCLUDE_DIR)/package.mk

define Package/ext-custom16
  SECTION:=utils
  CATEGORY:=ROOter
  DEPENDS:=+luci +ext-rooter-basic \
		+luci-app-ddns +ddns-scripts +ddns-scripts_no-ip_com \
		+luci-app-rootervpn +ext-wireguard \
		+luci-app-nlbwmon +bwmon \
		+ext-theme +luci-theme-argon +argon-config +ext-login \
		+luci-theme-tomato +ext-material \
		+ca-bundle +ca-certificates +libustream-openssl \
		+luci-app-ksmbd +usb-storage \
		+ext-p910nd +luci-app-sqm +kmod-sched-cake +luci-app-nft-qos \
		+ext-command +ext-speedtest +luci-app-guestwifi \
		+openvpn-easy-rsa +openvpn-openssl \
		+ext-extra +luci-app-hotspot +luci-app-wol \
		+usbmuxd +libusbmuxd-utils +libimobiledevice-utils +kmod-usb-net-ipheth \
		+nano +picocom +wpad +wget +qfirehose 
  TITLE:=Custom ROOter support for 16meg and larger routers w/o MWan3
  PKGARCH:=all
endef

define Package/ext-custom16/description
  Helper scripts to enable Custom ROOter on 16meg and larger routers w/o MWan3
endef


define Build/Compile
endef

define Package/ext-custom16/install
	$(CP) ./files/* $(1)/


endef

$(eval $(call BuildPackage,ext-custom16))
