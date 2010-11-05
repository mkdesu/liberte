# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit font

DESCRIPTION="LKLUG Sinhala Unicode Font"
HOMEPAGE="http://www.lug.lk/fonts/lklug"
SRC_URI="http://sinhala.sourceforge.net/files/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 x86"

# Docs to install
DOCS="CREDITS README.fonts"

# Space delimited list of font suffixes to install
FONT_SUFFIX="ttf"

# Dir containing the fonts
FONT_S="${S}"
