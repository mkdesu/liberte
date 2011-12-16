# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4

inherit linux-info

FW_NAME="carl9170-1.fw"

DESCRIPTION="Atheros USB AR9170 firmware (kernel <=3.0)"

HOMEPAGE="http://linuxwireless.org/en/users/Drivers/carl9170"
SRC_URI="http://linuxwireless.org/en/users/Drivers/carl9170/fw${PV}?action=AttachFile&do=get&target=${FW_NAME} -> ${P}.fw"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="x86 amd64"

IUSE=""

pkg_setup() {
	if ! kernel_is -le 3 0; then
		ewarn "This firmware is for 2.6.x and 3.0.x kernels only"
	fi

	if linux_config_exists && ! linux_chkconfig_present CARL9170; then
		ewarn "Enable CONFIG_CARL9170 in the kernel to use this firmware"
	fi
}

src_unpack() {
	mkdir -p "${S}"                           || die
	cp "${DISTDIR}"/${P}.fw "${S}"/${FW_NAME} || die
}

src_install() {
	insinto /lib/firmware
	doins   ${FW_NAME}
}
