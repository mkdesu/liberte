# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="4"

inherit eutils

DESCRIPTION="Secure and anonymous serverless email-like communication."
HOMEPAGE="http://dee.su/cables"
LICENSE="GPL-3"

# I2P version is not critical, and need not be updated
MY_P_PF=mkdesu-cables
I2P_PV=0.8.8
I2P_MY_P=i2pupdate_${I2P_PV}

# In the actual ebuild the GitHub URI should be replaced with a tagged download
SRC_URI="https://github.com/mkdesu/cables/tarball/v1.0 -> ${P}.tar.gz
         http://mirror.i2p2.de/${I2P_MY_P}.zip
         http://launchpad.net/i2p/trunk/${I2P_PV}/+download/${I2P_MY_P}.zip"

SLOT="0"
KEYWORDS="x86 amd64"

IUSE=""
DEPEND="app-arch/unzip
	>=virtual/jdk-1.5"
RDEPEND="www-servers/nginx[http,pcre,nginx_modules_http_access,nginx_modules_http_fastcgi,nginx_modules_http_gzip,nginx_modules_http_rewrite]
	www-servers/spawn-fcgi
	www-misc/fcgiwrap
	mail-filter/procmail
	net-misc/curl
	dev-libs/openssl
	>=virtual/jre-1.5
	gnome-extra/zenity"

pkg_setup() {
	enewgroup cable
	enewuser  cable -1 -1 -1 cable -c "Cables Communication"
}

src_unpack() {
	unpack ${P}.tar.gz
	mv ${MY_P_PF}-* ${P}              || die "failed to recognize archive top directory"
	find ${P} -path '*\.git*' -delete || die "failed to remove git files"

	unzip -j -d ${P}/lib ${DISTDIR}/${I2P_MY_P}.zip lib/i2p.jar || die "failed to extract i2p.jar"
}

src_compile() {
	emake || die "make failed"
}

src_install() {
	doinitd  init/cabled

	insinto  /usr/share/${PN}
	doins    conf/nginx.conf conf/spawn-fcgi.cable || die
	fperms   600 ${INSDESTTREE}/nginx.conf         || die

	dobin    bin/*                    || die

	insinto  /usr/libexec
	doins -r cable                    || die

	insinto  /usr/share/applications
	doins    share/cable-info.desktop || die

	keepdir       /var/www/cable/certs /var/www/cable/queue /var/www/cable/rqueue
	fperms  3310  /var/www/cable/certs /var/www/cable/queue /var/www/cable/rqueue || die
	fperms   711  /var/www/cable                                                  || die
	fowners      :nginx /var/www/cable/certs                                      || die "failed to change ownership"
	fowners cable:nginx /var/www/cable/queue /var/www/cable/rqueue                || die "failed to change ownership"
}

pkg_postinst() {
	elog "Remember to add cabled and nginx to the default runlevel"
	elog "    rc-update add cabled default"
	elog "    rc-update add nginx  default"
	elog ""
	elog "You need to adjust the user-specific paths in:"
	elog "    /usr/libexec/cable/suprofile (CABLE_MOUNT must be mountpoint or /)"
	elog "    /etc/conf.d/spawn-fcgi.cable (CABLE_QUEUES should mirror suprofile)"
	elog "    /etc/nginx/nginx.conf        (root should mirror CABLE_PUB in suprofile)"
	elog "    (take spawn-fcgi.cable and nginx.conf from /usr/share/${PN})"
	elog "Note that CABLE_INBOX and CABLE_QUEUES/{queue,rqueue} directories"
	elog "must be writable by 'cable' (create them if they don't exist)."
	elog ""
	elog "Generate cables certificates and Tor/I2P keypairs for the user"
	elog "    /usr/libexec/cable/gen-cable-username (run as normal user)"
	elog "        copy CABLE_CERTS/certs/*.pem to CABLE_PUB/cable/certs (group-readable)"
	elog "    /usr/libexec/cable/gen-tor-hostname   (run as normal user)"
	elog "        copy CABLE_TOR/hidden_service to /var/lib/tor (readable only by tor)"
	elog "    /usr/libexec/cable/gen-i2p-hostname   (run as normal user)"
	elog "        copy CABLE_I2P/eepsite to /var/lib/i2p/router (readable only by i2p)"
	elog ""
	elog "Once a cables username has been generated for the user:"
	elog "    rename CABLE_PUB/cable to CABLE_PUB/<username>"
	elog "        <username> is located in CABLE_CERTS/certs/username"
	elog "    /etc/nginx/nginx.conf"
	elog "        replace each occurrence of CABLE with <username>"
	elog "        uncomment the 'allow' line"
	elog ""
	elog "Finally, the user should configure the email client to run"
	elog "    sudo -nu cable /usr/libexec/cable/send"
	elog "as a pipe for sending messages from addresses shown by"
	elog "    cable-info (or see CABLE_CERTS/certs/username, CABLE_{TOR,I2P}/*/hostname)"
	elog "Edit /etc/sudoers to avoid the password prompt on sudo."
}
