# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"

inherit font

DESCRIPTION="Maldives MCST Dhivehi fonts"
HOMEPAGE="http://www.mcst.gov.mv/News_and_Events/xpfonts.htm"

base_uri="http://www.mcst.gov.mv/Downloads"
base_uri2="${base_uri}/New/Divehi%20xp%20fonts"
SRC_URI="${base_uri2}/Mv%20Elaaf%20Lite.otf.ttf         -> ${P}-MvElaafLite.ttf
         ${base_uri2}/Mv%20Elaaf%20Normal.otf.ttf       -> ${P}-MvElaafNormal.ttf
         ${base_uri2}/Mv%20GroupX%20Avas.otf.ttf        -> ${P}-MvGroupXAvas.ttf
         ${base_uri2}/Mv%20Iyyu%20Nala.otf.ttf          -> ${P}-MvIyyuNala.ttf
         ${base_uri2}/Mv%20Iyyu%20Normal.otf.ttf        -> ${P}-MvIyyuNormal.ttf
         ${base_uri2}/Mv%20Lady%20Luck.otf.ttf          -> ${P}-MvLadyLuck.ttf
         ${base_uri2}/Mv%20MAG%20Round.otf.ttf          -> ${P}-MvMAGRound.ttf
         ${base_uri2}/Mv%20MAG%20Round%20Hollow.otf.ttf -> ${P}-MvMAGRoundHollow.ttf
         ${base_uri2}/Mv%20MAG%20Round%20XBold.otf.ttf  -> ${P}-MvMAGRoundXBold.ttf
         ${base_uri2}/Mv%20Sehga%20FB.otf.ttf           -> ${P}-MvSehgaFB.ttf
         ${base_uri2}/Mv%20Sehga%20Old.otf.ttf          -> ${P}-MvSehgaOld.ttf
         ${base_uri}/Fonts/Mv%20Galan.ttf               -> ${P}-MvGalan.ttf"

LICENSE="freedist"
SLOT="0"
KEYWORDS="amd64 x86"

# Space delimited list of font suffixes to install
FONT_SUFFIX="ttf"

# Dir containing the fonts
FONT_S="${S}"

# Unpacking unnecessary
src_unpack() {
    mkdir -p "${S}"
    cd "${S}"

    cp "${DISTDIR}"/* .
}
