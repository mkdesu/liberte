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

# GitHub URI can refer to a tagged download or the master branch
SRC_URI="https://github.com/mkdesu/cables/tarball/v${PV} -> ${P}.tar.gz
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
	enewuser  cable -1 -1 -1 cable
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
	# no mime types, so no need to inherit fdo-mime
	emake DESTDIR="${D}" install                     || die "make install failed"

	doinitd  "${D}"/usr/share/cable/cabled           || die
	doconfd  "${D}"/usr/share/cable/spawn-fcgi.cable || die
	dosym    spawn-fcgi /etc/init.d/spawn-fcgi.cable || die

	insinto  /etc/nginx
	doins    "${D}"/usr/share/cable/nginx-cable.conf || die
	fperms   600 ${INSDESTTREE}/nginx-cable.conf     || die

	rm -r    "${D}"/usr/share/cable

	# /var/www(/cable)        drwx--x--x root  root
	# /var/www/cable/certs    d-wx--s--T root  nginx
	# /var/www/cable/(r)queue d-wx--s--T cable nginx
	keepdir       /var/www/cable/{certs,{,r}queue}
	fperms  3310  /var/www/cable/{certs,{,r}queue}   || die
	fperms   711  /var/www{,/cable}                  || die
	fowners      :nginx /var/www/cable/certs         || die "failed to change ownership"
	fowners cable:nginx /var/www/cable/{,r}queue     || die "failed to change ownership"
}

pkg_postinst() {
	elog "Remember to add cabled and nginx to the default runlevel"
	elog "    rc-update add cabled           default"
	elog "    rc-update add nginx            default"
	elog "    rc-update add spawn-fcgi.cable default"
	elog ""
	elog "You need to adjust the user-specific paths in:"
	elog "    /usr/libexec/cable/suprofile (CABLE_MOUNT must be mountpoint or /)"
	elog "    /etc/conf.d/spawn-fcgi.cable (CABLE_QUEUES should mirror suprofile)"
	elog "    /etc/nginx/nginx-cable.conf  (root should mirror CABLE_PUB in suprofile)"
	elog "and then set the nginx configuration"
	elog "    ln -snf nginx-cable.conf /etc/nginx/nginx.conf"
	elog "Note that CABLE_INBOX and CABLE_QUEUES/{queue,rqueue} directories"
	elog "must be writable by 'cable' (create them if they don't exist)."
	elog ""
	elog "Generate cables certificates and Tor/I2P keypairs for the user"
	elog "    gen-cable-username"
	elog "        copy CABLE_CERTS/certs/*.pem to CABLE_PUB/cable/certs (group-readable)"
	elog "    gen-tor-hostname"
	elog "        copy CABLE_TOR/hidden_service to /var/lib/tor (readable only by tor)"
	elog "    gen-i2p-hostname"
	elog "        copy CABLE_I2P/eepsite to /var/lib/i2p/router (readable only by i2p)"
	elog ""
	elog "Once a cables username has been generated for the user:"
	elog "    rename CABLE_PUB/cable to CABLE_PUB/<username>"
	elog "        <username> is located in CABLE_CERTS/certs/username"
	elog "    /etc/nginx/nginx-cable.conf"
	elog "        replace each occurrence of CABLE with <username>"
	elog "        uncomment the 'allow' line"
	elog ""
	elog "Configure Tor and I2P to forward HTTP connections to nginx:"
	elog "    /etc/tor/torrc"
	elog "        HiddenServiceDir  /var/lib/tor/hidden_service/"
	elog "        HiddenServicePort 80 127.0.0.1:80"
	elog "    /var/lib/i2p/router/i2ptunnel.config"
	elog "        tunnel.X.privKeyFile=eepsite/eepPriv.dat"
	elog "        tunnel.X.targetHost=127.0.0.1"
	elog "        tunnel.X.targetPort=80"
	elog ""
	elog "Finally, the user should configure the email client to run /usr/bin/cable-send"
	elog "as a pipe for sending messages from addresses shown by"
	elog "    cable-info (or see CABLE_CERTS/certs/username, CABLE_{TOR,I2P}/*/hostname)"
	elog "See comments in /usr/bin/cable-send for /etc/sudoers entry suggestion."
}
