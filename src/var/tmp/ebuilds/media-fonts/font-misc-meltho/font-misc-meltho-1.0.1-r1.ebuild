# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit font

DESCRIPTION="X.Org Syriac fonts"
HOMEPAGE="http://xorg.freedesktop.org/"
SRC_URI="http://xorg.freedesktop.org/releases/individual/font/${P}.tar.bz2"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 x86"

# Docs to install
DOCS="README ChangeLog license.txt"

# Space delimited list of font suffixes to install
FONT_SUFFIX="otf"

# Dir containing the fonts
FONT_S="${S}"
