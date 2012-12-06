# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="4"

# no mime types, so no need to inherit fdo-mime
inherit eutils

DESCRIPTION="Secure and anonymous serverless email-like communication."
HOMEPAGE="http://dee.su/cables"
LICENSE="GPL-3"

# I2P version is not critical, and need not be updated
MY_P_PF=mkdesu-cables
I2P_PV=0.8.8
I2P_MY_P=i2pupdate_${I2P_PV}

# GitHub URI can refer to a tagged download or the master branch
SRC_URI="https://github.com/mkdesu/cables/tarball/v${PV} -> ${P}.tar.gz
         i2p? (
             http://mirror.i2p2.de/${I2P_MY_P}.zip
             http://launchpad.net/i2p/trunk/${I2P_PV}/+download/${I2P_MY_P}.zip
         )"

SLOT="0"
KEYWORDS="x86 amd64"
IUSE="i2p"

DEPEND="app-arch/unzip
	i2p? ( >=virtual/jdk-1.5 )"
RDEPEND="net-libs/libmicrohttpd
	mail-filter/procmail
	net-misc/curl
	dev-libs/openssl
	i2p? ( >=virtual/jre-1.5 )
	gnome-extra/zenity"

pkg_setup() {
	enewgroup cable
	enewuser  cable -1 -1 -1 cable
}

src_unpack() {
	unpack ${P}.tar.gz
	mv ${MY_P_PF}-* ${P} || die "failed to recognize archive top directory"

	if use i2p; then
		unzip -j -d ${P}/lib ${DISTDIR}/${I2P_MY_P}.zip lib/i2p.jar || die "failed to extract i2p.jar"
	fi
}

src_prepare() {
	if ! use i2p; then
		export MAKEOPTS+=" NOI2P=1"
	fi

	default
}

src_install() {
	default

	doinitd  "${D}"/etc/cable/cabled
	rm       "${D}"/etc/cable/cabled || die
}

pkg_postinst() {
	elog "Remember to add 'cabled' to the default runlevel."
	elog "You need to adjust the user-specific paths in /etc/cable/profile."
	elog "Generate cables certificates and Tor/I2P keypairs for the user:"
	elog "    gen-cable-username"
	elog "    gen-tor-hostname"
	elog "        copy CABLE_TOR/hidden_service to /var/lib/tor (readable only by 'tor')"
	if use i2p; then
		elog "    gen-i2p-hostname"
		elog "        copy CABLE_I2P/eepsite        to /var/lib/i2p (readable only by 'i2p')"
	fi
	elog "Configure Tor to forward HTTP connections to cables daemon:"
	elog "    /etc/tor/torrc"
	elog "        HiddenServiceDir  /var/lib/tor/hidden_service/"
	elog "        HiddenServicePort 80 127.0.0.1:9080"
	if use i2p; then
		elog "Configure I2P similarly:"
		elog "    /var/lib/i2p/i2ptunnel.config"
		elog "        tunnel.X.privKeyFile=eepsite/eepPriv.dat"
		elog "        tunnel.X.targetHost=127.0.0.1"
		elog "        tunnel.X.targetPort=9080"
	fi
	elog "Finally, the user should configure the email client to run cable-send"
	elog "as a pipe for sending messages from addresses shown by cable-info."
	elog "See comments in /usr/bin/cable-send for suggested /etc/sudoers entry."
}
