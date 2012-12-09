# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI=4

inherit gnome2

DESCRIPTION="Extensible scalable virtual keyboard for GNOME"
HOMEPAGE="http://florence.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm ~x86"
IUSE="doc +libnotify"

RDEPEND="app-accessibility/at-spi2-core
	dev-libs/glib:2
	dev-libs/libxml2:2
	x11-libs/cairo
	gnome-base/librsvg:2
	media-libs/gstreamer:0.10
	x11-libs/gdk-pixbuf:2
	x11-libs/gtk+:3
	x11-libs/libX11
	x11-libs/libXext
	x11-libs/libXtst
	libnotify? ( x11-libs/libnotify )
	x11-libs/pango"
DEPEND="${RDEPEND}
	app-text/scrollkeeper
	dev-util/intltool
	sys-devel/gettext
	virtual/pkgconfig
	doc? ( gnome-base/libgnome )"
DOCS="AUTHORS ChangeLog NEWS README"

src_configure() {
	econf \
		$(use_with libnotify notification) \
		$(use_with doc docs)
}
