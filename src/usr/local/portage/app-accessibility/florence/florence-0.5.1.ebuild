# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

# Based on the ebuild from xmw overlay:
# http://gpo.zugaina.org/app-accessibility/florence

EAPI=4

inherit gnome2

SRC_URI="mirror://sourceforge/${PN}/${P}.tar.bz2"
DESCRIPTION="Extensible scalable virtual keyboard for GNOME"
KEYWORDS="~amd64 ~arm x86"
SLOT="0"
IUSE="accessibility doc gnome +libnotify +xtst"
LICENSE="GPL-2"
HOMEPAGE="http://florence.sourceforge.net/"

RDEPEND="
	dev-libs/glib:2
	dev-libs/libxml2:2
	gnome-base/gconf:2
	gnome-base/libglade:2.0
	gnome-base/librsvg:2
	x11-libs/cairo
	x11-libs/gdk-pixbuf:2
	x11-libs/gtk+:2
	x11-libs/libX11
	accessibility? ( gnome-extra/at-spi:1 )
	gnome? ( gnome-base/gnome-panel )
	libnotify? ( x11-libs/libnotify )
	xtst? ( x11-libs/libXtst )"
DEPEND="${RDEPEND}
	dev-util/pkgconfig
	dev-util/intltool
	app-text/scrollkeeper
	sys-devel/gettext
	doc? ( gnome-base/libgnome )"
DOCS="AUTHORS ChangeLog NEWS README"

src_configure() {
	econf \
		$(use_with accessibility at-spi) \
		$(use_with doc docs) \
		$(use_with gnome panelapplet) \
		$(use_with notify notification) \
		$(use_with xtst)
}
